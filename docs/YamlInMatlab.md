# Reading the lab's YAML configs from MATLAB

`Matlab/YamlTools/` — `readYaml` for the file, `readCcgConfig` for the
resolved config. Add it to the path:

```matlab
addpath('<ManuscriptTools>/Matlab/YamlTools')
cfg = readYaml('~/Documents/Manuscripts/A1_paper/doc/cells/cross_correlations.yaml');
```

MATLAB has no YAML reader of its own, so `readYaml` takes whichever of
three backends is installed and normalizes all of them to the same MATLAB
types.

| Backend | What it is | Needs |
|---|---|---|
| `matlab` | MathWorks' `readyaml` ([matlab-toml-yaml](https://github.com/mathworks/matlab-toml-yaml)) | R2022b+, pure MATLAB, no Java or Python |
| `yamlpkg` | `yaml.loadFile` ([File Exchange 106765](https://www.mathworks.com/matlabcentral/fileexchange/106765-yaml)) | R2019b+, bundles SnakeYAML (Java) |
| `python` | `py.yaml.safe_load` through MATLAB's Python interface | `pyenv` pointing at an interpreter with PyYAML |

`'auto'` (the default) tries them in that order. Force one with
`readYaml(cfgFile, 'Backend', 'python')`.

**A checkout works as well as an install.** If `readyaml` is not already on
the path, `readYaml` looks for a clone of `matlab-toml-yaml` and adds it
itself — the `'ToolboxPath'` argument first, then the `MATLAB_TOML_YAML`
environment variable, then `~/Documents/GitRepos/matlab-toml-yaml`. It
finds `readyaml.m` anywhere under that root and adds the folder above any
`+package` / `@class` directories, so the repo's own layout does not
matter.

```matlab
cfg = readYaml(cfgFile);                                                  % finds the clone
cfg = readYaml(cfgFile, 'ToolboxPath', '~/Documents/GitRepos/matlab-toml-yaml');
setenv('MATLAB_TOML_YAML', '/path/to/matlab-toml-yaml')                % or once per session
```

## What you get

| YAML | MATLAB |
|---|---|
| map | scalar struct (keys sanitized to valid field names) |
| list of maps | 1xN cell array of structs |
| list of numbers | 1xN double |
| list of `true`/`false` | 1xN logical |
| list of strings | 1xN cellstr |
| mixed list | 1xN cell array |
| string | char row vector |
| number | double |
| `true` / `false` | logical |
| `null`, `~` | `[]` |

The backends disagree here — `readyaml` returns sequences as arrays,
`yaml.loadFile` and PyYAML as cells — so `readYaml` packs every list the
same way: a plain vector when the elements are all simple and of one kind,
a cell otherwise. `cfg.options.ei.dendrite.window_ms` is `[-0.3 0.3]`, not
a cell.

### One-entry lists

MathWorks' `readyaml` returns a YAML sequence of mappings as a **YAMLData
array**, and a one-item sequence is a scalar — indistinguishable from a
plain mapping. So a list with a single entry comes back as a struct rather
than a 1x1 cell: with one `ei_mosaics` entry in the file,
`cfg.ei_mosaics` is a struct, while `cfg.datasets` with 17 is a cell.
`asList` removes the difference:

```matlab
for e = asList(cfg.ei_mosaics)
    fprintf('%s\n', e{1}.name);
end
n = numel(asList(cfg.datasets));
```

The `python` backend does not have this ambiguity, and neither does
`readCcgConfig`.

### A bug in `readyaml`, worked around here

MathWorks' `readyaml` (as of September 2026) removes comments with

```matlab
lines{i} = strtrim(line(1:j-1));
```

`strtrim` takes the **leading indentation** off as well as the trailing
comment. In a block-structured format the indentation *is* the structure,
so every line carrying a trailing comment is promoted to indent 0:

```yaml
options:
  include_self: true      # source == target pairs
```

parses as a top-level `include_self`, not as a key of `options`. A block
with no comments nests correctly, which makes the damage look arbitrary —
on `cross_correlations.yaml` it turned 9 top-level keys into 26, so
`cfg.parameters.max_lag` worked while `cfg.options.ei.dendrite.window_ms`
did not.

`readYaml` therefore strips the comments itself first — right-trimming
only, with `#` starting a comment only at the start of a line or after
whitespace, so a `#` inside a scalar survives — and hands `readyaml` a
temporary file with the indentation intact. Verified against
`cross_correlations.yaml`: the stripped text parses to exactly the same
data as the original under PyYAML. The only thing it would break is a `#`
inside a literal or folded block scalar (`|`, `>`), which the lab's configs
do not use.

The one-word upstream fix is `deblank` instead of `strtrim`. It is applied in
the local clone at `~/Documents/GitRepos/matlab-toml-yaml`, together with a
regression test in `tests/yamltest.m` — the existing `testCommentsIgnored`
only covers top-level keys, where the two are indistinguishable. A `git
pull` will drop both, and other machines will not have them, so `readYaml`
keeps its own pre-pass regardless; stripping comments from comment-free text
is a no-op, so the two do not conflict.

The write-up for the upstream issue is
`docs/readyaml-comment-indent-issue.md`.

### How YAMLData is read

Worth knowing if you use `readyaml` directly rather than through
`readYaml`: `keys(obj)` is a node's own key list and `fieldnames(obj)` is
an alias for it, but on a **non-scalar** array both return the *union* of
the elements' keys — which is why `fieldnames` on a whole config can come
back with every key in the document rather than the top-level ones.
`readYaml` converts each array element separately and checks every key with
`iskey` before reading it, so a union never leaks into the struct. Dot
access is dynamic, so `obj.("build-system")` works for keys that are not
valid identifiers; `readYaml` sanitizes those to field names
(`build_system`).

```matlab
cfg.parameters.max_lag              % 300
cfg.options.ei.dendrite.plot_type   % 'contour'
cfg.options.ei.dendrite.window_ms   % [-0.3 0.3]
numel(cfg.datasets)                 % 17
cfg.datasets{1}.experiment_name     % '20250924C'
cellfun(@(d) string(d.name), cfg.datasets)
```

## The file is not the config

This is the part that bites. `readYaml` reads what is written in the file.
`notebooks/compute_crosscorr.py`'s `load_ccg_config` does considerably more
before the tool runs:

- merges `DEFAULT_PARAMETERS`, `DEFAULT_OPTIONS`, `DEFAULT_STIMULUS` and
  `DEFAULT_EI`, so a key absent from the file still has a value;
- splits `options.mosaic` and `options.ei` out of `options`;
- resolves `data_dir` to the first path that exists;
- makes `out_dir` and `igor_dir` absolute against the repo root;
- defaults `target_ids` to `all` on `datasets` and to nothing elsewhere;
- raises when an `ei_mosaics` and an `electrical_images` entry would write
  the same `EI_<name>.h5`.

So `cfg.options.stimulus` read straight from the file may be
`{enabled: false, repeats: null}` while Python is working with eight keys.
Anything you compute in MATLAB from the raw file will disagree with what
the figures were made from.

`readCcgConfig` avoids that by calling `load_ccg_config` itself through the
Python interface and converting the result, so the two cannot drift:

```matlab
pyenv('Version', '<env that runs the notebooks>/bin/python')   % once per MATLAB session
cfg = readCcgConfig();                     % the repo's doc/cells/cross_correlations.yaml
cfg = readCcgConfig(path, 'NeedDataDir', true)
cfg.options.stimulus.repeat_ms
```

It finds the notebooks folder from the `A1_PAPER_NOTEBOOKS` environment
variable, the `'Notebooks'` argument, or
`~/Documents/Manuscripts/A1_paper/notebooks`, and reloads the module each
call so edits to the Python are picked up without restarting MATLAB.

Use `readYaml` when you only need what is written down — a list of
experiment names, the cell ids of an entry — and `readCcgConfig` when a
number has to match what the analysis used.

## Octave

None of the three backends exist in Octave: no toolboxes, no MATLAB Python
interface. The files parse and the type conversion works there, but reading
an actual YAML file does not. For an Octave-side script, either hard-code
the handful of values or have Python write a `.mat` alongside the YAML.
