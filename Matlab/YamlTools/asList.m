function c = asList(v)
%ASLIST  A YAML value that may be one entry or many -> always a 1xN cell array.
%   readYaml maps a YAML sequence of mappings to a cell of structs, but a ONE-entry sequence
%   is indistinguishable from a plain mapping in MathWorks' readyaml (both are a scalar
%   YAMLData), so it comes back as a bare struct. asList removes the difference:
%
%       for e = asList(cfg.ei_mosaics)
%           fprintf('%s\n', e{1}.name);
%       end
%       n = numel(asList(cfg.datasets));
%
%   [] and '' give an empty cell; a cell is returned unchanged; anything else is wrapped.
if isempty(v)
    c = {};
elseif iscell(v)
    c = reshape(v, 1, []);
elseif isstruct(v)
    c = reshape(num2cell(v), 1, []);
else
    c = {v};
end
end
