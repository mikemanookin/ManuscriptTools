function s = readYaml(path, varargin)
%READYAML  Read a YAML file into a MATLAB struct, whichever backend is available.
%   s = readYaml(path)
%   s = readYaml(path, 'Backend', 'auto' | 'matlab' | 'yamlpkg' | 'python')
%   s = readYaml(path, 'ToolboxPath', '<matlab-toml-yaml checkout>')
%
%   The lab's configs (A1_paper/doc/cells/*.yaml, doc/export/*.yaml) are plain YAML.
%   Whichever reader is installed, this returns them the same way:
%
%       map                 -> scalar struct (keys sanitized to valid field names)
%       list of maps        -> 1xN cell array of structs
%       list of numbers     -> 1xN double     (so [-0.3, 0.3] is a plain vector)
%       list of true/false  -> 1xN logical
%       list of strings     -> 1xN cellstr
%       mixed list          -> 1xN cell array
%       string              -> char row vector
%       number              -> double
%       true / false        -> logical
%       null / ~            -> []
%
%   Backends, tried in this order by 'auto':
%     'matlab'   MathWorks' readyaml (MATLAB Toolbox for TOML and YAML, R2022b+, pure
%                MATLAB: github.com/mathworks/matlab-toml-yaml). If it is not on the path,
%                readYaml looks for a checkout and adds it: the 'ToolboxPath' argument, the
%                MATLAB_TOML_YAML environment variable, then ~/Documents/GitRepos/matlab-toml-yaml.
%     'yamlpkg'  MartinKoch123/yaml (File Exchange 106765, R2019b+, SnakeYAML/Java): yaml.loadFile.
%     'python'   MATLAB's Python interface: py.yaml.safe_load. Needs pyenv set to an
%                interpreter with PyYAML (the same env that runs the notebooks does).
%
%   NOTE. This reads the FILE. It does not apply the defaults that
%   notebooks/compute_crosscorr.py's load_ccg_config merges in, resolve data_dir, make
%   out_dir/igor_dir absolute, or default target_ids per list. A key absent from the file is
%   absent here but has a value in Python. For the resolved config, see readCcgConfig.
%
%   ONE-ENTRY LISTS. MathWorks' readyaml returns a YAML sequence of mappings as a YAMLData
%   ARRAY, and a one-item sequence is a scalar - indistinguishable from a plain mapping. So a
%   list with a single entry comes back as a struct, not a 1x1 cell: cfg.ei_mosaics is a
%   struct when the file has one ei_mosaics entry and a 1xN cell when it has several. Wrap it
%   with asList() when you want to loop regardless:
%       for e = asList(cfg.ei_mosaics), disp(e{1}.name), end
%   The 'python' backend does not have this ambiguity.
%
%   Example:
%       cfg = readYaml('~/Documents/Manuscripts/A1_paper/doc/cells/cross_correlations.yaml');
%       cfg.parameters.max_lag                      % 300
%       cfg.options.ei.dendrite.window_ms           % [-0.3 0.3]
%       numel(cfg.datasets)                         % 17
%       cfg.datasets{1}.experiment_name             % '20250924C'

ip = inputParser();
ip.addParameter('Backend', 'auto', @(x) ischar(x) || isstring(x));
ip.addParameter('ToolboxPath', '', @(x) ischar(x) || isstring(x));
ip.parse(varargin{:});
backend = lower(char(ip.Results.Backend));

path = char(path);
if ~isfile(path)
    error('readYaml:notFound', 'no such file: %s', path);
end

order = {backend};
if strcmp(backend, 'auto')
    order = {'matlab', 'yamlpkg', 'python'};
end

tried = {};
for k = 1:numel(order)
    try
        switch order{k}
            case 'matlab'
                ensureTomlYaml(char(ip.Results.ToolboxPath));
                clean = stripCommentsToTempFile(path);
                cleanup = onCleanup(@() delete(clean));   %#ok<NASGU>
                s = normalize(readyaml(clean));
            case 'yamlpkg'
                if isempty(which('yaml.loadFile'))
                    error('readYaml:noBackend', 'yaml.loadFile is not on the path');
                end
                s = normalize(yaml.loadFile(path));
            case 'python'
                s = normalize(py.yaml.safe_load(fileread(path)));
            otherwise
                error('readYaml:backend', 'unknown backend ''%s''', order{k});
        end
        return
    catch err
        tried{end+1} = sprintf('  %-8s %s', order{k}, err.message); %#ok<AGROW>
    end
end
error('readYaml:noBackend', ['no YAML backend could read %s.\n%s\n' ...
      'Install one of:\n' ...
      '  MathWorks TOML/YAML toolbox   github.com/mathworks/matlab-toml-yaml  (R2022b+, pure MATLAB)\n' ...
      '  yaml (File Exchange 106765)   github.com/MartinKoch123/yaml          (R2019b+, Java)\n' ...
      'or point pyenv at an interpreter with PyYAML.'], path, strjoin(tried, sprintf('\n')));
end


% ---------------------------------------------------------------------------------------------
function ensureTomlYaml(explicitPath)
%ENSURETOMLYAML  Put MathWorks' readyaml on the path, from a checkout if it is not installed.
if ~isempty(which('readyaml'))
    return
end
roots = {};
if ~isempty(explicitPath)
    roots{end+1} = char(explicitPath);
end
if ~isempty(getenv('MATLAB_TOML_YAML'))
    roots{end+1} = getenv('MATLAB_TOML_YAML');
end
home = getenv('HOME');
if isempty(home)
    home = getenv('USERPROFILE');        % Windows
end
if ~isempty(home)
    roots{end+1} = fullfile(home, 'Documents', 'GitRepos', 'matlab-toml-yaml');
end
for i = 1:numel(roots)
    if ~isfolder(roots{i})
        continue
    end
    hits = dir(fullfile(roots{i}, '**', 'readyaml.m'));
    if isempty(hits)
        continue
    end
    addpath(packageRoot(hits(1).folder));
    if ~isempty(which('readyaml'))
        return
    end
end
error('readYaml:noBackend', ['readyaml is not on the path. Install the .mltbx, or pass the ' ...
      'checkout: readYaml(path, ''ToolboxPath'', ''~/Documents/GitRepos/matlab-toml-yaml'') ' ...
      '(or set the MATLAB_TOML_YAML environment variable).']);
end


function root = packageRoot(folder)
%PACKAGEROOT  The folder to addpath for a file that may sit inside +package / @class folders:
%   .../toolbox/+matlab/+io/+config  ->  .../toolbox
root = folder;
while true
    [parent, name] = fileparts(root);
    if isempty(name) || isempty(parent) || ~(name(1) == '+' || name(1) == '@')
        break
    end
    root = parent;
end
end


% ---------------------------------------------------------------------------------------------
function tmp = stripCommentsToTempFile(path)
%STRIPCOMMENTSTOTEMPFILE  Work around a bug in MathWorks' readyaml (as of Sep 2026).
%
%   Its removeComments() does  lines{i} = strtrim(line(1:j-1))  - strtrim, which removes the
%   LEADING INDENTATION as well as the trailing comment. In a block-structured format that
%   changes the meaning of the line: every line carrying a trailing comment is promoted to
%   indent 0, so
%       options:
%         include_self: true      # source == target pairs
%   parses as a top-level `include_self`, not as a key of `options`. A block with no comments
%   nests correctly, which is why the damage looks arbitrary.
%
%   So the comments are removed here first, right-trimming only, and readyaml is handed a
%   temporary file with the indentation intact. A '#' starts a comment only at the start of a
%   line or after whitespace (the YAML rule), so '#' inside a scalar survives.
%
%   Known limitation: a literal or folded block scalar (| or >) whose content contains '#'
%   would lose it. The lab's configs do not use those.
text = fileread(path);
lines = splitlines(string(text));
for i = 1:numel(lines)
    lines(i) = string(stripLineComment(char(lines(i))));
end
out = cellstr(lines);
tmp = [tempname, '.yaml'];
fid = fopen(tmp, 'w');
if fid < 0
    error('readYaml:temp', 'could not open a temporary file for %s', path);
end
fprintf(fid, '%s\n', out{:});
fclose(fid);
end


function out = stripLineComment(line)
inQuotes = false;
quoteChar = '';
cut = 0;
for j = 1:length(line)
    c = line(j);
    if ~inQuotes && (c == '"' || c == '''')
        inQuotes = true;
        quoteChar = c;
    elseif inQuotes && c == quoteChar
        inQuotes = false;
    elseif ~inQuotes && c == '#' && (j == 1 || line(j-1) == ' ' || line(j-1) == sprintf('\t'))
        cut = j;
        break
    end
end
if cut > 0
    line = line(1:cut-1);
end
out = deblank(line);            % right-trim ONLY: the indentation is the structure
end


% ---------------------------------------------------------------------------------------------
function v = normalize(v)
%NORMALIZE  Any backend's output -> the types documented above.
if isPyType(v, 'py.dict')
    v = normalize(struct(v));
    return
elseif isPyType(v, 'py.list') || isPyType(v, 'py.tuple')
    v = packList(cellfun(@normalize, cell(v), 'UniformOutput', false));
    return
elseif isPyType(v, 'py.str')
    v = char(v); return
elseif isPyType(v, 'py.bool')
    v = logical(v); return
elseif isPyType(v, 'py.int') || isPyType(v, 'py.float')
    v = double(v); return
elseif isPyType(v, 'py.NoneType')
    v = []; return
end

if isa(v, 'matlab.io.config.ConfigurationData')
    v = configDataToStruct(v);                % readyaml's YAMLData (and readtoml's TOMLData)
    return
end
if isobject(v) && ~isStringArray(v) && ~isa(v, 'dictionary') && ~isa(v, 'datetime') ...
        && ~isa(v, 'duration') && ~isa(v, 'categorical')
    m = objectToMap(v);                       % any other struct-like object
    if ~isempty(m)
        v = m;
        return
    end
end
if isa(v, 'dictionary')
    k = keys(v);
    out = struct();
    for i = 1:numel(k)
        out.(fieldName(k(i))) = normalize(v(k(i)));
    end
    v = out;
elseif isstruct(v) && isscalar(v)
    f = fieldnames(v);
    out = struct();
    for i = 1:numel(f)
        out.(fieldName(f{i})) = normalize(v.(f{i}));
    end
    v = out;
elseif isstruct(v)
    v = packList(arrayfun(@normalize, v, 'UniformOutput', false));
elseif iscell(v)
    v = packList(cellfun(@normalize, v, 'UniformOutput', false));
elseif isStringArray(v)
    if isscalar(v)
        v = char(v);
    else
        v = cellstr(v);
    end
end
end


function v = configDataToStruct(obj)
%CONFIGDATATOSTRUCT  readyaml's YAMLData -> struct (or a cell of them for a sequence).
%
%   Two things about that class matter here (toolbox/+matlab/+io/+config):
%     * a YAML sequence of mappings is a NON-SCALAR YAMLData array, not a cell, and
%       keys() on an array returns the UNION of its elements' keys - so each element has to
%       be converted on its own;
%     * keys() is the node's own key list and fieldnames() is an alias for it, but every key
%       is checked with iskey() before it is read, so a union or a key the node does not
%       carry is skipped rather than erroring.
%   Dot access is dynamic (obj.("build-system") works), which is how each value is read.
if ~isscalar(obj)
    v = packList(arrayfun(@(o) normalize(o), obj, 'UniformOutput', false));
    return
end
k = cellstr(keys(obj));
out = struct();
for i = 1:numel(k)
    if ~hasKey(obj, k{i})
        continue
    end
    try
        out.(fieldName(k{i})) = normalize(obj.(k{i}));
    catch
    end
end
v = out;
end


function tf = hasKey(obj, key)
%HASKEY  iskey() where the class provides it; optimistic otherwise.
tf = true;
try
    tf = all(iskey(obj, key));
catch
end
end


function m = objectToMap(obj)
%OBJECTTOMAP  Any other struct-like object -> struct, without assuming its API.
%   Tries fieldnames, properties, keys, struct. Returns [] if none of them describe it.
m = [];
if ~isscalar(obj)
    m = packList(arrayfun(@(o) normalize(o), obj, 'UniformOutput', false));
    return
end
names = {};
probes = {@() fieldnames(obj), @() properties(obj), @() cellstr(string(keys(obj))), ...
          @() fieldnames(struct(obj))};
for i = 1:numel(probes)
    try
        n = probes{i}();
        if ~isempty(n)
            names = cellstr(n);
            break
        end
    catch
    end
end
if isempty(names)
    return
end
out = struct();
got = false;
for i = 1:numel(names)
    try
        out.(fieldName(names{i})) = normalize(obj.(names{i}));
        got = true;
    catch
    end
end
if got
    m = out;
end
end


function v = packList(c)
%PACKLIST  A cell of normalized values -> the list convention: a numeric / logical / cellstr row
%   where every element is the same simple kind, a cell otherwise.
if isempty(c)
    v = {};
    return
end
c = reshape(c, 1, []);
if all(cellfun(@(x) isnumeric(x) && isscalar(x), c))
    v = cell2mat(c);
elseif all(cellfun(@(x) islogical(x) && isscalar(x), c))
    v = cell2mat(c);
elseif all(cellfun(@(x) ischar(x) && (isrow(x) || isempty(x)), c))
    v = c;                                  % already a cellstr
else
    v = c;
end
end


function tf = isPyType(v, name)
tf = false;
try
    tf = isa(v, name);
catch
end
end


function tf = isStringArray(v)
%ISSTRINGARRAY  isstring() where it exists (MATLAB), false where it does not (Octave).
tf = false;
if exist('isstring', 'builtin') == 5 || exist('isstring', 'file') == 2
    tf = isstring(v);
end
end


function f = fieldName(k)
%FIELDNAME  A YAML key -> a valid MATLAB field name (same rule as symphony_export.sanitize_field).
if isnumeric(k) || islogical(k)
    k = num2str(k);
elseif ~ischar(k)
    k = char(k);                 % MATLAB string, py.str, or a dictionary key
end
f = regexprep(k, '[^0-9A-Za-z_]+', '_');
if isempty(f) || ~isletter(f(1))
    f = ['x', f];
end
end
