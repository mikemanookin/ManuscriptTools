# ManuscriptTools — what changed (September 2026)

Newest first. Each entry says which file changed, what to do differently,
and where the detail lives.

## 2026-10-05 — polar graphs are built at one physical size (`Igor/PolarPlots.ipf` v1.43)

- **The symptom.** Two polar panels in `OSDSFigure.pxp` drawn by the same
  call showed visibly different line thickness and dot size while every
  setting in Modify Trace Appearance matched. The moving-bar graph carried
  `ModifyGraph expand=-2, height=144`; the grating graph carried neither,
  so its plot area was the full ~280 pt of the window. `expand` scales
  fonts, line widths and markers as well as the plot area, and a larger
  plot area has to be scaled down in the layout, which scales its lines
  with it — neither is visible in the trace settings.
- **`PolarSetSize(graphName, [height, expandValue])`** sets a graph's
  plot-area height (the width follows from the square Plan aspect) and
  clears the expansion. `PolarSetSize("polar_A1_MovingBar_c1")` puts an
  existing graph back to the standard size.
- `MakePolarTuningGraph` and `PolarTuningGraphFromFolder` now take
  `height=` (default `POLAR_HEIGHT`, 144 pt) and apply it on every build,
  so panels agree by construction; `height=0` restores the old behaviour of
  leaving the plot area to the window.
- Detail: `docs/IgorPolarPlots.md`, section "Size: why two polar graphs can
  differ when their settings agree".

## 2026-09-24 — reading the matching CSVs from MATLAB (`Matlab/MatchTools/`)

- `readMatches` reads a `matches_*.csv` from `analysis/mea/ei_matching.py`
  into a typed table, `matchMap` turns it into a reference-id -> target-id
  `containers.Map`, and `isIdentityMatches` says whether the file came from
  a review or from `identity_decisions`.
- It exists because the column set is not fixed: the score terms at the end
  depend on what was scored, and files written before the cell types were
  recorded have no `ref_type` / `target_type`. Both header shapes are in
  circulation and both are read. Rejected rows leave `target_id` empty and
  identity files write `nan` in `margin`, either of which makes `readtable`
  type a numeric column as text.
- `docs/MatchesInMatlab.md` has the details.

## 2026-09-16 — reading the YAML configs from MATLAB (`Matlab/YamlTools/`)

- `readYaml(path)` reads any of the lab's YAML configs into a MATLAB
  struct, using whichever backend is installed — MathWorks' `readyaml`
  (R2022b+, pure MATLAB), `yaml.loadFile` (File Exchange 106765, Java), or
  `py.yaml.safe_load` — and normalizing all three to the same types: map ->
  struct, string -> char, number -> double, null -> [], and lists to a
  plain vector when the elements are all one simple kind, a cell otherwise
  (the backends disagree: `readyaml` gives arrays, the others cells).
- **Works around a `readyaml` bug.** Its comment stripper `strtrim`s the
  text before the `#`, removing the leading indentation too, so every line
  with a trailing comment is promoted to the top level — 9 top-level keys
  in `cross_correlations.yaml` became 26. `readYaml` now removes comments
  itself (right-trim only, `#` only at line start or after whitespace) and
  passes `readyaml` a temp file with the indentation intact. The one-word
  upstream fix (`deblank` for `strtrim`) plus a regression test is applied in
  the local clone; `docs/readyaml-comment-indent-issue.md` is the write-up to
  file against mathworks/matlab-toml-yaml. The pre-pass stays either way — a
  `git pull` drops the local fix and other machines never had it.
- The `matlab` backend converts `matlab.io.config.YAMLData` properly: a
  sequence of mappings is a non-scalar YAMLData array (not a cell) and
  `keys`/`fieldnames` on an array return the *union* of the elements' keys,
  so each element is converted on its own and every key is checked with
  `iskey` before it is read.
- `asList(v)` wraps a one-entry list: `readyaml` cannot tell a one-item
  sequence from a mapping, so such a list arrives as a struct rather than a
  1x1 cell.
- A *clone* of matlab-toml-yaml is enough — no `.mltbx` install needed.
  `readYaml` finds `readyaml.m` under `'ToolboxPath'`, the
  `MATLAB_TOML_YAML` environment variable, or
  `~/Documents/GitRepos/matlab-toml-yaml`, and adds the right folder.
- `readCcgConfig()` returns `cross_correlations.yaml` **as Python resolves
  it** — defaults merged, `data_dir` resolved, paths absolute — by calling
  `load_ccg_config` through MATLAB's Python interface, so the MATLAB and
  Python views cannot drift. Use it whenever a number has to match what the
  analysis used; `readYaml` only gives you what is written in the file.
- `docs/YamlInMatlab.md` covers the backends, the type mapping and what
  `load_ccg_config` adds on top of the file.

## 2026-09-15 — marker sizes follow the panel (`ElectricalImages.ipf` v1.8)

- `EISetHeight` now re-fits the electrode markers after resizing, so
  shrinking a panel no longer merges the circles into blobs. Marker sizes
  are in points and the data is in microns: on a 1890 x 900 um array the
  60 um spacing is 7.2 pt apart at `height=108` but 3.6 pt at `height=54`,
  so a marker size chosen for one panel collides at the other.
- New `EIFitMarkers(graph, [fraction])` sets the largest marker to a
  fraction (default 0.9) of the electrode spacing as drawn, and
  `EIElectrodePitch(graph)` returns that spacing in microns.
- `EISetHeight(graph, height, maxSize=n)` forces a size instead;
  `maxSize=0` leaves the markers untouched.

## 2026-09-15 — mosaic electrodes back to `elec_` (`ElectricalImages.ipf` v1.7)

- A mosaic's per-cell electrodes are `elec_<tag>` sized by `esize_<tag>`
  again, matching the single-cell panel, so one `*elec_*` branch in a
  formatting routine styles both. The fit stays `fit_<tag>`. The
  single-cell panel keeps its whole-EI `elec` / `ei_size` plus the window's
  `dend` / `dsize`.
- `EIDsizeNameFor` maps `elec_<tag>_Y` -> `esize_<tag>_Y` and `dend_Y` ->
  `dsize_Y`; `elec_*_Y` does not match the bare `elec_Y`, so the two
  panels stay distinct.

## 2026-09-15 — EI helpers work on either panel (`ElectricalImages.ipf` v1.6)

- `EISetMaxSize` no longer aborts with "no elec_Y trace in <graph>" when
  called on a dendritic mosaic. It now sizes whatever the graph has — the
  `elec_Y` circles of a single-cell panel, the `dend_<tag>_Y` electrodes of
  a mosaic, or both — and a graph with neither is reported and left alone,
  so it is safe to call from a format routine that runs over every EI
  graph.
- `EIMosaicElectrodes` handles the single-cell `dend_Y` as well as a
  mosaic's `dend_<tag>_Y`, takes `show < 0` to re-apply marker sizes without
  touching visibility, and returns how many traces it styled.
- New `EIDsizeNameFor(traceName)`: the `dsize_*` wave belonging to a
  `dend_*` trace, on either panel.

## 2026-09-15 — one trace-naming scheme for EI fits (`ElectricalImages.ipf` v1.5, `RfMosaics.ipf` v1.6)

- EI exports now name the fit and its data the same way on both panels:
  `fit` for the fitted outline, `dend` / `dsize` for the electrodes it was
  fitted to and their amplitudes in the dendritic window — with a
  `_<role><k>` tag per cell on a mosaic (`fit_source0`, `dend_source0`,
  `dsize_source0`) and bare on a single-cell panel. Replaces the old
  `dendrite` / `cell_*` / `elec_*` / `esize_*` mix.
- `RfMosaics.ipf` v1.6 accepts either outline prefix everywhere through
  `MosaicIsCellTrace` / `MosaicCellTraces`, so RF mosaics keep `cell_*` and
  EI mosaics use `fit_*` while `MosaicFillByColor` (whose `match` now
  defaults to both), `MosaicClean`, `MosaicApplyColors`, `MosaicSetExtent`
  and `MosaicFitExtent` work on both.

## 2026-09-15 — fitted electrodes on EI mosaics (`ElectricalImages.ipf` v1.4)

- `compute_crosscorr.py` now exports, next to every dendritic outline, the
  electrodes it was fitted to (`elec_<tag>_X/_Y`) and their amplitudes in
  the dendritic window (`esize_<tag>_Y`, 0..1). `EIMosaicFromFolder` draws
  them as open circles sized by `esize`, in the outline's colour and behind
  it; `EIMosaicElectrodes(graph, 0 | 1, [maxSize])` hides or restyles them.
- The single-cell panel gained `dend` / `dsize` — the dendritic-window
  electrodes — beside the existing whole-waveform `elec` / `ei_size`.
- `MakeEIMosaicGraph` and `EIMosaicFromFolder` take `maxSize` for those
  markers.
- v1.4 fixes "trace is not on graph" from `ReorderTraces`: its brace list is
  parsed as trace NAMES, so a wave reference variable (`{wy}`) is read as a
  trace literally called "wy". Use `{$name}`, and `_back_` as the anchor
  rather than looking up a trace to sit behind.

## 2026-09-15 — EI dendritic mosaics (`ElectricalImages.ipf` v1.2)

- `MakeEIGraph` now opens either kind of `EI_<label>.h5`: the single-cell
  panel (`elec_X/_Y`) as before, or a **dendritic mosaic** (`cell*_Y`,
  from `compute_crosscorr.py --ei-mosaics`), which it forwards to the new
  `MakeEIMosaicGraph` instead of aborting with "elec_X/_Y not found".
- New `MakeEIMosaicGraph(name, [height, lineSize, showArray])` and
  `EIMosaicFromFolder`: the outlines are drawn by `RfMosaics.ipf`'s
  `MosaicGraphFromFolder`, so colours, the reversed y axis,
  `MosaicSetHeight`, `MosaicSetExtent` and `MosaicFillByColor` all apply,
  with the electrode array appended behind as grey dots.
- The single-cell panel draws a `dendrite_X/_Y` outline when the export
  has one.
- `EILoadH5(name)` factored out of `MakeEIGraph`; both entry points share it.

## 2026-09-14 — fills replace instead of stacking (`RfMosaics.ipf` v1.5)

- `MosaicFillByColor` and `MosaicClean` deleted only the FIRST `rfFills`
  drawing group, but `DrawFilledContour` puts every polygon in its own group
  of that name — so a second fill pass (e.g. `MakeRFGraph`, which fills, then
  a `FormatPopulationContour` that fills again) left the old polygons
  underneath and the shading came out about twice as dark. New
  `MosaicDeleteFills(graph, [group])` deletes them all (both user layers) and
  is called before drawing, so fills are now idempotent. `MosaicFillByColor`
  reports how many old fills it removed.

## 2026-09-12 — `CenterGraph` keeps reversed axes (`ManookinLabIgorProcedures.ipf`)

- `CenterGraph(width, height, [graphName])` / `GetGraphDataCenter` (Mike's
  centring helpers) preserve each axis's direction: `SetAxis left, lo, hi`
  with lo < hi had flipped the mosaics' reversed y axis (y downward) back to
  y upward, which looked like an x/y swap. `GetGraphDataCenter` gains
  optional `xReversed` / `yReversed` outputs (GetAxis returns V_min > V_max
  on a reversed axis); an empty graph name resolves to the top graph.

## 2026-09-11 — coloured mosaics (`RfMosaics.ipf` v1.4, `RfContourFill.ipf`)

- `MakeMosaicGraph` / `MosaicGraphFromFolder` apply a trace's exported
  `*_color` wave when there is one (before: every outline black);
  `MosaicClean` preserves those colours (`MosaicApplyColors`).
- New `MosaicFillByColor(graph, [alpha, match])`: shades every outline in
  its own trace colour — for `compute_crosscorr.py`'s `CcgMosaic_<name>.h5`
  exports, where `cell_source<k>` and `cell_target<k>` traces carry the
  source / target colours chosen in `cross_correlations.yaml`.
- `FormatRfContour(..., match=, group=)`: fill only the traces matching a
  wildcard, into a named drawing group, so two calls with different colours
  coexist on one graph. → `docs/RfMosaics.md`

## 2026-09-09 — RF mosaics

- `RfMosaics.ipf` v1.3: `MosaicSetExtent(graph, spanUm, [ySpanUm, xCenter,
  yCenter])` — separate x and y spans, so a wide array gets a wide panel
  (Plan aspect: width follows) without empty bands; `MosaicFitExtent(graph,
  [padUm])` fits the spans to the data. Same `ySpanUm` + same height =
  same µm/pt across panels.
- `RfMosaics.ipf` v1.1: `MosaicRefresh(graph, [refill, alpha, red, green,
  blue, scheme])` reloads the `.h5` and tidies the mosaic in place;
  `MosaicClean` does the tidy-up alone after `RefreshAllData` (drops stale
  cell traces, styles appended ones like the rest, removes the old
  `FormatRfContour` fills and optionally redraws them, restores the plot
  size and orientation). Formatting is kept. → `docs/RfMosaics.md`

- **New `Igor/RfMosaics.ipf`**: `MakeMosaicGraph(name, [height, lineSize])`,
  `MosaicGraphFromFolder`, `MosaicSetHeight`. Loads a `PopulationRF_<label>.h5`
  mosaic export, draws every `cell*_Y vs cell*_X` on a square (Plan) axis
  system of the given height with the y axis reversed (STA orientation),
  axes hidden. Pairs with `FormatRfContour` (`RfContourFill.ipf`) for fills.
  Add an alias in Igor Procedures. → `docs/RfMosaics.md`
- Python: `rf_figure.py --stage mosaics` (type search, `merges`, `exclude`,
  `min_spikes`; `fit_threshold` = fraction of the peak for contour and
  ellipse alike) writes the `.h5` plus a per-cell CSV.

## 2026-09-08 — electrical images

- **New `Igor/ElectricalImages.ipf`** (v1.1): `MakeEIGraph(name, [maxSize,
  height])`, `EIGraphFromFolder`, `EISetMaxSize`, `EISetHeight`. Draws an
  `EI_<label>.h5` export as circles on the electrode map with
  `zmrkSize` driven by the exported `ei_size_Y` (area ∝ trough depth),
  defaults 108-pt square panel and 6-pt largest circle. Use it instead of
  `MakeFig` for `EI_*` files (`MakeFig` would plot the size waves as
  traces); `EIwave_*` files load with `MakeFig`. → `docs/ElectricalImages.md`
- Python: `rf_figure.py --stage ei`, `src/electrical_image.py`.

## 2026-09-08 — loaders and refresh (`ManookinLabIgorProcedures.ipf`, `DisplayImageFromPython.ipf`, `PolarPlots.ipf`)

- `MakeFig`, `MakeImage`, `MakeImageFig`, `RefreshGraphData`,
  `MakePolarTuningGraph` accept `"Name.h5"` as well as `"Name"` (the
  trailing `.h5` is stripped; before, it made `HDF5LoadGroup` look for a
  group called `Name.h5` → `H5Gget_objinfo` error).
- The loaders now close the HDF5 file when a load fails and abort with a
  message naming the missing group. Before, a failed `MakeFig` left the
  file open and locked, and the next Python export failed with h5py
  `errno 35` ("unable to lock file"). If that still happens (older
  procedures still loaded): `HDF5CloseFile/A 0` in Igor.
- `RefreshGraphData` / `RefreshAllData` reconcile traces with the reloaded
  file (`ReconcileGraphTraces`): `*_Y` waves new to the file are appended
  (with their `*_color`), and a trace whose exported wave has vanished from
  the file (e.g. `hull_Y` after the outline was renamed `contour_Y`) is
  **hidden**, never removed — the printed line gives the `hideTrace(...)=0`
  command to show it again. Traces of waves outside the graph's own data
  folder (ones you appended by hand) are never touched.
- `StripH5Extension(name)` helper for use from Functions.
- Reminder: after a procedure file changes on disk, click **Compile** in a
  procedure window; until then, running a macro from the command line
  reports the first user function it meets as "not a string function".

## 2026-09-07 — polar plots (`PolarPlots.ipf` v1.4x)

- **Shaded tuning hull**: `MakePolarTuningGraph(name, fill=0.2)`,
  `PolarFill(graph, [red, green, blue, alpha])`, `PolarUnfill(graph)`. The
  shading is a polygon drawing object in the UserBack layer, in axis
  coordinates (exact fill of the region the curve encloses; a trace's Fill
  to zero would over-fill notches facing the x axis). It follows
  `PolarSetScale`; rerun `PolarFill` if the curve waves change.
  (v1.41 fixed the polygon origin: `DrawPoly` places the *first vertex* at
  `xOrg, yOrg`, so the hull had been shifted left by the 0° radius.)
- Round-number outer ring (`PolarNiceCeil`), scaling from the means when
  `showErr=0`, `PolarSetScale(graph, rmax, rings)` to rescale an open graph,
  DSI vector rescaled with the rings (`PolarRememberDsi`).
- The procedure now loads the `.h5` itself (`MakeFig` convention) and
  accepts a renamed file (first HDF5 group). One canonical copy:
  `Igor/PolarPlots.ipf`, linked into Igor Procedures. → `docs/IgorPolarPlots.md`
- `Matlab/MatlabToIgorTools/polarWaves.m`: `'Nice'`, `'RmaxFrom'`,
  `'Rmax'`, `'Vector'` options.

## 2026-09-06 — documentation

- `docs/MatlabToIgor.md`, `docs/PythonToIgor.md`, `docs/IgorPolarPlots.md`,
  `docs/Installation.md` (MATLAB / Python sections), README index.
- Known limitations recorded in `PythonToIgor.md`: `axis_to_igor` stores
  colours as matplotlib holds them (pass numeric RGB tuples) and line
  styles as strings; `ax.errorbar` lines export as `_nolegend_*`.
