function tf = isIdentityMatches(T)
%ISIDENTITYMATCHES  Was this file an identity export rather than a reviewed one?
%   tf = isIdentityMatches(readMatches(path))
%
%   ei_matching.identity_decisions writes every cell matched to ITSELF - for protocols sorted in
%   the same chunk, where there is nothing to review. Those rows carry score 1, an empty margin
%   and rank 0, and ref_id == target_id throughout. Nothing else distinguishes them from a
%   hand-reviewed file, so check before treating the scores as evidence of anything.
if ~istable(T) || isempty(T)
    tf = false;
    return
end
ok = strcmp(T.verdict, 'accept') & ~isnan(T.target_id);
if ~any(ok)
    tf = false;
    return
end
tf = all(T.ref_id(ok) == T.target_id(ok)) ...
     && (~ismember('score', T.Properties.VariableNames) || all(T.score(ok) == 1)) ...
     && (~ismember('margin', T.Properties.VariableNames) || all(isnan(T.margin(ok))));
end
