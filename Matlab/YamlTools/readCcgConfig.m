function cfg = readCcgConfig(path, varargin)
%READCCGCONFIG  cross_correlations.yaml AS PYTHON SEES IT: defaults merged, paths resolved.
%   cfg = readCcgConfig()                          % the repo's doc/cells/cross_correlations.yaml
%   cfg = readCcgConfig(path)
%   cfg = readCcgConfig(path, 'NeedDataDir', true) % also resolve data_dir to the first existing
%
%   readYaml gives you the file. This gives you what notebooks/compute_crosscorr.py actually
%   runs with: DEFAULT_PARAMETERS / DEFAULT_OPTIONS / DEFAULT_STIMULUS / DEFAULT_EI merged in,
%   out_dir and igor_dir made absolute, target_ids defaulted per list, and the name-collision
%   check applied - by calling load_ccg_config itself through MATLAB's Python interface, so the
%   two can never drift apart.
%
%   Needs pyenv pointing at the interpreter that runs the notebooks:
%       pyenv('Version', '/Users/michaelmanookin/miniconda3/envs/obsidian/bin/python')
%   Check with pyenv. On a machine without that environment use readYaml and remember that
%   anything the file leaves out is a Python-side default, not an empty value.
%
%   Example:
%       cfg = readCcgConfig();
%       cfg.options.stimulus.repeat_ms
%       d = cfg.datasets{1};  d.name, d.source_id
%       cellfun(@(e) string(e.name), cfg.ei_mosaics)

ip = inputParser();
ip.addParameter('NeedDataDir', false, @(x) islogical(x) || isnumeric(x));
ip.addParameter('Notebooks', '', @(x) ischar(x) || isstring(x));
ip.parse(varargin{:});

here = fileparts(mfilename('fullpath'));
notebooks = char(ip.Results.Notebooks);
if isempty(notebooks)
    notebooks = getenv('A1_PAPER_NOTEBOOKS');
end
if isempty(notebooks)
    notebooks = fullfile(getenv('HOME'), 'Documents', 'Manuscripts', 'A1_paper', 'notebooks');
end
if ~isfolder(notebooks)
    error('readCcgConfig:notebooks', ['cannot find the notebooks folder (tried %s).\n' ...
          'Pass it as ''Notebooks'', or set the A1_PAPER_NOTEBOOKS environment variable.'], notebooks);
end

try
    py.sys.path();
catch
    error('readCcgConfig:python', ['MATLAB has no Python interpreter configured. Run\n' ...
          '  pyenv(''Version'', ''<path to the env that runs the notebooks>/bin/python'')\n' ...
          'or use readYaml for a plain read of the file.']);
end
if count(py.sys.path(), notebooks) == 0
    insert(py.sys.path(), int32(0), notebooks);
end

cc = py.importlib.import_module('compute_crosscorr');
py.importlib.reload(cc);                    % pick up edits without restarting MATLAB
if nargin < 1 || isempty(path)
    raw = cc.load_ccg_config(pyargs('need_data_dir', logical(ip.Results.NeedDataDir)));
else
    raw = cc.load_ccg_config(char(path), pyargs('need_data_dir', logical(ip.Results.NeedDataDir)));
end
cfg = localNormalize(raw);
end


function v = localNormalize(v)
% The same conversion readYaml uses, applied to what load_ccg_config returns (which also holds
% pathlib.Path objects for out_dir / igor_dir).
if isa(v, 'py.dict')
    f = cell(py.list(keys(v)));
    out = struct();
    for i = 1:numel(f)
        k = char(f{i});
        out.(regexprep(k, '[^0-9A-Za-z_]+', '_')) = localNormalize(v{f{i}});
    end
    v = out;
elseif isa(v, 'py.list') || isa(v, 'py.tuple')
    v = cellfun(@localNormalize, cell(v), 'UniformOutput', false);
elseif isa(v, 'py.str')
    v = char(v);
elseif isa(v, 'py.bool')
    v = logical(v);
elseif isa(v, 'py.int') || isa(v, 'py.float')
    v = double(v);
elseif isa(v, 'py.NoneType')
    v = [];
elseif isa(v, 'py.pathlib.PosixPath') || isa(v, 'py.pathlib.WindowsPath') || isa(v, 'py.pathlib.Path')
    v = char(py.str(v));
end
end
