# Reading the cluster-matching CSVs from MATLAB

`Matlab/MatchTools/` — `readMatches` for the file, `matchMap` for the
id lookup, `isIdentityMatches` to tell a reviewed file from an exported one.

```matlab
addpath('<ManuscriptTools>/Matlab/MatchTools')

T = readMatches('<A1_paper>/doc/cells/mapping_files/matches_20230228C_chunk1.csv');
[T, map] = readMatches(csvFile, 'AcceptedOnly', true);
targetId = map(195);
```

The files come from `analysis/mea/ei_matching.py` — either from a review
(`MatchReview`) or from `identity_decisions`, when both protocols were
sorted in the same chunk and nothing needed reviewing. One row per
reference cell:

```
ref_id,ref_type,verdict,target_id,target_type,score,margin,rank[,ei_raw,ei_sub,wave,sta]
195,A1,accept,412,A1,0.94,0.31,0,...
218,A1,reject,,,0.61,0.02,0,...
```

`verdict` is `accept`, `reject` or `skip`; only accepted rows carry a
`target_id`.

## Why not a bare readtable

Three things vary between files, and `readtable` guesses differently for
each:

* **the columns are not fixed.** The score-term columns at the end depend
  on what was scored — `sta` is missing when the sort had no STA, and an
  identity file has none of them. Files written before the types were
  recorded have no `ref_type` / `target_type` either, so both header
  shapes are in circulation:

  ```
  ref_id,ref_type,verdict,target_id,target_type,score,margin,rank
  ref_id,verdict,target_id,score,margin,rank,ei_raw,ei_sub,wave
  ```

  `readMatches` reads whatever is there and fills the type columns with
  `''` when the file predates them;
* **empty and `nan` cells.** Rejected rows leave `target_id` empty and
  identity files write `nan` in `margin`. A file where every row was
  rejected has an entirely empty `target_id` column, which `readtable`
  would type as text rather than numeric;
* **ids must stay integers**, or they will not compare equal to Vision
  cell ids read from anywhere else.

## What you get

A table with `ref_id`, `ref_type`, `verdict`, `target_id`, `target_type`,
`score`, `margin`, `rank` and whatever score terms the file has. Text
columns are cellstr (`''` where the row had none), everything else is
double (`NaN` where empty).

```matlab
T = readMatches(csvFile, 'AcceptedOnly', true);   % drop reject / skip rows
T = readMatches(csvFile, 'Type', 'A1');           % one reference type
T = readMatches(csvFile, 'Type', {'A1','RB'});    % or several
```

`'Type'` errors with the types actually present rather than returning an
empty table — a type name that matches nothing is nearly always a typo.
It needs a file that HAS the type columns; on an older one every
`ref_type` is `''`. Backfill those from Python rather than by hand:

```python
em.annotate_types(path, ref, target)     # fills both columns in place
```

## The id lookup

```matlab
[T, map] = readMatches(csvFile, 'AcceptedOnly', true);
if isKey(map, 195)
    targetId = map(195);
end
ids = cell2mat(map.keys);
```

`matchMap` keeps only accepted rows, so `isKey` answers "did this cell
match?". Keys and values are doubles, as Vision ids are everywhere else.

## Reviewed or exported?

```matlab
isIdentityMatches(T)
```

An identity export matches every cell to itself and writes score 1, an
empty margin and rank 0 on every row. Nothing else marks it, so check
before reading the scores as evidence of anything — in such a file they
are constants, not measurements.

## With the YAML

`direction_selective.yaml` names a mapping file per entry, relative to
`mea_mapping_dir`:

```matlab
cfg = readYaml('<A1_paper>/doc/cells/direction_selective.yaml');
for e = asList(cfg.moving_bars)
    T = readMatches(fullfile(cfg.mea_mapping_dir, e{1}.mapping_file), ...
                    'AcceptedOnly', true);
    fprintf('%s: %d matched cell(s)\n', e{1}.data_file, height(T));
end
```

`asList` matters here — both lists in that file have a single entry, which
MathWorks' `readyaml` returns as a struct rather than a 1x1 cell. See
`YamlInMatlab.md`.
