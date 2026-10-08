function m = matchMap(T)
%MATCHMAP  reference id -> target id, for the accepted rows of a matches table.
%   m = matchMap(readMatches(path))
%   targetId = m(195);
%   ids = cell2mat(m.keys);
%
%   Rejected and skipped rows are left out, so isKey(m, id) answers "did this cell match?".
%   Keys and values are doubles, as Vision cell ids are everywhere else in MATLAB.
if ~istable(T)
    error('matchMap:notATable', 'expected the table from readMatches');
end
ok = strcmp(T.verdict, 'accept') & ~isnan(T.target_id);
ids = T.ref_id(ok);
tgt = T.target_id(ok);
if isempty(ids)
    m = containers.Map('KeyType', 'double', 'ValueType', 'double');
else
    m = containers.Map(num2cell(ids), num2cell(tgt));
end
end
