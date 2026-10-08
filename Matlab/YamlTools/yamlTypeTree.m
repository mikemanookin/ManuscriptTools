function yamlTypeTree(v, varargin)
%YAMLTYPETREE  Print the class and size of every node of a YAML value, for debugging.
%   yamlTypeTree(cfg)                       % a struct from readYaml
%   yamlTypeTree(readyaml(path))            % the raw YAMLData from MathWorks' reader
%   yamlTypeTree(cfg, 'MaxDepth', 3, 'Path', 'cfg')
%
%   Never errors on a node it cannot read: anything unexpected is printed as <unreadable>,
%   so it always gets to the end and shows where a branch stops being a struct.

ip = inputParser();
ip.addParameter('MaxDepth', 4, @isnumeric);
ip.addParameter('Path', 'cfg', @(x) ischar(x) || isstring(x));
ip.addParameter('Depth', 0, @isnumeric);
ip.parse(varargin{:});
walk(v, char(ip.Results.Path), ip.Results.Depth, ip.Results.MaxDepth);
end


function walk(v, path, depth, maxDepth)
pad = repmat('  ', 1, depth);
fprintf('%s%-34s %-34s %s\n', pad, path, classOf(v), sizeOf(v));
if depth >= maxDepth
    return
end
names = {};
kind = '';
try
    if isa(v, 'matlab.io.config.ConfigurationData')
        if isscalar(v)
            names = cellstr(keys(v));
            kind = 'yamldata';
        else
            for i = 1:min(numel(v), 3)
                walk(v(i), sprintf('%s(%d)', path, i), depth + 1, maxDepth);
            end
            return
        end
    elseif isstruct(v) && isscalar(v)
        names = fieldnames(v);
        kind = 'struct';
    elseif isstruct(v)
        for i = 1:min(numel(v), 3)
            walk(v(i), sprintf('%s(%d)', path, i), depth + 1, maxDepth);
        end
        return
    elseif iscell(v)
        for i = 1:min(numel(v), 3)
            walk(v{i}, sprintf('%s{%d}', path, i), depth + 1, maxDepth);
        end
        return
    end
catch err
    fprintf('%s  <could not list: %s>\n', pad, err.message);
    return
end
for i = 1:numel(names)
    child = [];
    ok = false;
    try
        if strcmp(kind, 'yamldata')
            child = v.(names{i});
        else
            child = v.(names{i});
        end
        ok = true;
    catch err
        fprintf('%s  %-32s <unreadable: %s>\n', pad, names{i}, err.message);
    end
    if ok
        walk(child, [path '.' names{i}], depth + 1, maxDepth);
    end
end
end


function c = classOf(v)
try
    c = class(v);
catch
    c = '<unknown>';
end
end


function s = sizeOf(v)
try
    d = size(v);
    s = ['[' strjoin(arrayfun(@(x) sprintf('%d', x), d, 'UniformOutput', false), 'x') ']'];
    if ischar(v) && isrow(v)
        s = [s ' ''' v ''''];
    elseif isnumeric(v) && numel(v) <= 4
        s = [s ' ' mat2str(v)];
    elseif islogical(v) && isscalar(v)
        s = [s ' ' mat2str(v)];
    end
catch
    s = '';
end
end
