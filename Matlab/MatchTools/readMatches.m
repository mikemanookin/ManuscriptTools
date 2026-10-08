function [T, map] = readMatches(path, varargin)
%READMATCHES  Read a matches_*.csv written by analysis/mea/ei_matching.py.
%   T = readMatches(csvFile)
%   T = readMatches(csvFile, 'AcceptedOnly', true)   % drop rejected / skipped rows
%   T = readMatches(csvFile, 'Type', 'A1')           % keep one reference type (or {'A1','RB'})
%   [T, map] = readMatches(...)                      % map: containers.Map ref_id -> target_id
%
%   The file has one row per reference cell:
%
%       ref_id,ref_type,verdict,target_id,target_type,score,margin,rank[,ei_raw,ei_sub,wave,sta]
%       195,A1,accept,412,A1,0.94,0.31,0,...
%       218,A1,reject,,,0.61,0.02,0,...
%
%   verdict is 'accept', 'reject' or 'skip'. Only accepted rows have a target_id; the others
%   leave it (and target_type) empty, which comes back as NaN and ''.
%
%   Three things this handles that a bare readtable does not:
%
%     * the trailing score-term columns VARY between files - 'sta' is absent when the sort had
%       no STA, and an identity file (em.identity_decisions) has none of them - so nothing may
%       assume a fixed column count;
%     * an identity file writes 'nan' in the margin column, and a file whose rows were ALL
%       rejected has an entirely empty target_id column, which readtable would otherwise type
%       as text rather than numeric;
%     * ref_id and target_id must stay integers, not the doubles readtable infers, or they
%       will not compare equal to Vision cell ids read from elsewhere.
%
%   Identity files (every cell matched to itself, no review) have score 1, empty margin and
%   rank 0 on every row - isIdentityMatches(T) below says so.
%
%   Example:
%       T = readMatches(fullfile(cfg.mea_mapping_dir, e{1}.mapping_file), 'AcceptedOnly', true);
%       [~, map] = readMatches(csvFile, 'AcceptedOnly', true);
%       targetId = map(195);
%
%   NOTE. Do not call the variable `path`: that is a MATLAB built-in returning the search
%   path, so readMatches(path) passes the search path as a filename.
%
%   See also READYAML, ASLIST, ISIDENTITYMATCHES, MATCHMAP.

p = inputParser;
p.addParameter('AcceptedOnly', false, @(x) islogical(x) || isnumeric(x));
p.addParameter('Type', '', @(x) ischar(x) || isstring(x) || iscell(x));
p.parse(varargin{:});
acceptedOnly = logical(p.Results.AcceptedOnly);
wantType     = p.Results.Type;

if ~isfile(path)
    % `path` is a MATLAB BUILT-IN that returns the whole search path. Calling
    % readMatches(path) without having assigned a variable of that name hands this function
    % the search path as a filename, which is otherwise a baffling error to read.
    if (ischar(path) || isstring(path)) && numel(char(path)) > 500 ...
            && contains(char(path), pathsep)
        error('readMatches:pathIsBuiltin', ...
              ['the file argument looks like MATLAB''s search path, not a file. `path` is a ' ...
               'built-in function - name the variable something else (csvFile, matchFile) ' ...
               'and pass that. If you already assigned `path`, `clear path` restores the ' ...
               'built-in.']);
    end
    error('readMatches:missingFile', 'no such file: %s', char(path));
end

opts = detectImportOptions(path, 'Delimiter', ',');
opts = setvartype(opts, opts.VariableNames, 'char');     % read everything as text, convert below
opts.ExtraColumnsRule = 'ignore';
opts = setvaropts(opts, opts.VariableNames, 'WhitespaceRule', 'trim');
raw = readtable(path, opts);

required = {'ref_id', 'verdict'};
missing  = required(~ismember(required, raw.Properties.VariableNames));
if ~isempty(missing)
    error('readMatches:badHeader', ...
          '%s has no %s column; is it a matches_*.csv?', path, strjoin(missing, ', '));
end

T = table();
names = raw.Properties.VariableNames;
textCols = {'verdict', 'ref_type', 'target_type'};
intCols  = {'ref_id', 'target_id', 'rank'};
for k = 1:numel(names)
    name = names{k};
    col  = raw.(name);
    if ~iscell(col), col = cellstr(string(col)); end
    if ismember(name, textCols)
        T.(name) = col;                                   % cellstr; '' where the row had none
    else
        v = str2double(col);                              % '' and 'nan' both give NaN
        if ismember(name, intCols)
            % keep ids exact: str2double is fine for ids in the int range, but round away any
            % text-formatting noise so they compare equal to ids read from a Vision table
            v(~isnan(v)) = round(v(~isnan(v)));
        end
        T.(name) = v;
    end
end
for name = textCols
    if ~ismember(name{1}, T.Properties.VariableNames)     % older file without the type columns
        T.(name{1}) = repmat({''}, height(T), 1);
    end
end

if acceptedOnly
    T = T(strcmp(T.verdict, 'accept') & ~isnan(T.target_id), :);
end
if ~isempty(wantType)
    wanted = cellstr(string(wantType));
    keep = false(height(T), 1);
    for w = 1:numel(wanted)
        keep = keep | strcmpi(T.ref_type, wanted{w});
    end
    if ~any(keep)
        present = unique(T.ref_type(~cellfun(@isempty, T.ref_type)));
        error('readMatches:noSuchType', ...
              'no row of reference type %s in %s. Types present: %s', ...
              strjoin(wanted, ', '), path, strjoin(present', ', '));
    end
    T = T(keep, :);
end

T.Properties.UserData = struct('file', char(path));
if nargout > 1
    map = matchMap(T);
end
end
