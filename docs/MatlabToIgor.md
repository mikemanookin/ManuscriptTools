# MATLAB → HDF5 → Igor Pro

How a MATLAB axis becomes an Igor graph, using `Matlab/MatlabToIgorTools/`
on the MATLAB side and `Igor/ManookinLabIgorProcedures.ipf` +
`Igor/DisplayFigFromMatlab.ipf` on the Igor side.

```
MATLAB axis  --makeAxisStruct-->  <name>.h5  --MakeFig("<name>")-->  Igor graph <name>
              (one dataset per                 (waves in root:<name>,
               line property)                   traces styled from them)
```

The design is deliberately simple: MATLAB writes **waves named after each
line's `DisplayName`**, plus a few axis datasets, into one HDF5 group; Igor
loads the group into a data folder and rebuilds the plot from the wave
names. Everything that looks like a figure in Igor — fonts, sizes, axes,
final colours — is done in Igor, where it can be redone without touching
the data. Re-running the MATLAB export and `RefreshAllData` in Igor updates
the numbers under a finished figure.

Setup: add `Matlab/MatlabToIgorTools` to the MATLAB path; put aliases to
`ManookinLabIgorProcedures.ipf` and `DisplayFigFromMatlab.ipf` in Igor's
"Igor Procedures" folder (`docs/Installation.md`); Igor needs the HDF5 XOP
(Igor 8: activate `HDF5.xop`; Igor 9 and later: built in).

---

## 1. MATLAB: drawing an exportable axis

Draw with `line` (or `errorbar`) and give **every object a `DisplayName`**;
that name becomes the wave name in Igor.

```matlab
figure(1); clf; hold on
line(contrast, mean(r), 'DisplayName', 'ctrlM', 'Color', 'k', 'Marker', 'o');
line(contrast, sem(r),  'DisplayName', 'ctrlE', 'Color', 'k', 'Marker', 'none');
line(contrast, mean(d), 'DisplayName', 'drugM', 'Color', 'r', 'LineStyle', '--');
line(contrast, sem(d),  'DisplayName', 'drugE', 'Color', 'r');
hold off
xlabel('contrast'); ylabel('spikes/s');
makeAxisStruct(gca, 'CRF_A1', 'basedir', igor_dir);      % -> <igor_dir>/CRF_A1.h5
```

`addLineToAxis(x, y, name, ax, color, lineStyle, marker)` is a one-line
shorthand for `line(...)` + `set(..., 'DisplayName', name)`.
`makeIgorExportFigureScratch.m` is a runnable version of this section, and
`Tutorials/matlab_tutorial.m` a slightly longer one.

### What `makeAxisStruct(ax, fname, 'basedir', dir)` exports

The function walks the children of `ax` in drawing order (first drawn
first), skips `text` objects, and writes one struct field per property to
`fname.h5` under the HDF5 group `/fname`. The group name **must** equal
the file base name — that is what `MakeFig` loads.

| Dataset | Source | Notes |
|---|---|---|
| `Xlabel`, `Ylabel` | axis labels | text; `MakeFig` applies them |
| `Xlim`, `Ylim` | axis limits | exported, currently not applied in Igor |
| `Xscale`, `Yscale` | 1 for log, 0 for linear | exported, currently not applied |
| `<name>_X`, `<name>_Y` | `XData`, `YData` | the trace; `_Y` is the trace name in Igor |
| `<name>_linestyle` | `LineStyle` | `-` → 0 (solid), `--` → 3 (dashed); other styles are not exported |
| `<name>_color` | `Color` | RGB in 0–1 |
| `<name>_marker` | `Marker` | `o` → 8, `+` → 0, `.` → 19, `^` → 17, `x` → 1, `*` → 2 (Igor marker codes); `'none'` → no dataset |
| `<name>_markercolor` | `MarkerFaceColor`, else `MarkerEdgeColor`, else `Color` | only when a marker is set |
| `<name>_markerSize` | `MarkerSize` | |
| `<name>_Yerr` | `UData` of an `errorbar` object | symmetric error bars |
| `<name>_Xerr` | `UserData.semX` (or numeric `UserData`) of that object | X error bars |

**Name sanitising.** The Igor wave name is the `DisplayName` with `.` →
`pt`, `-` → `m`, `+` → `p`, space → `_`, `/` → `_`, and an `n` prefixed
when the name starts with a digit (`'0.5'` → `n0pt5`, `'-90 deg'` →
`m90_deg`). A line with no `DisplayName` is named `L001`, `L002`, … by its
position. Keep names to letters, digits and underscores, starting with a
letter, and under 32 characters: anything else needs quoting in Igor.

**Where the file goes.** The `.h5` is written in the current MATLAB
folder and then moved to `basedir`; the default `basedir` is a Windows
path, so always pass `'basedir'`. An empty `fname` prompts for one.

**Only lines.** Objects other than `line`/`errorbar` (patches, images, bar
series) have no `DisplayName`/`XData` pairing the exporter understands;
draw the exportable version with lines, or keep shading for Igor (see
`PolarFill` in `IgorPolarPlots.md` and `FormatRfContour` in
`RfContourFill.ipf` for two examples of shading done on the Igor side).

### Naming conventions Igor relies on

| Suffix pair | Igor helper | Effect |
|---|---|---|
| `<x>M_Y` + `<x>E_Y` | `SetYError(graph)` | `<x>E_Y` becomes the error bars of `<x>M_Y` and is hidden |
| `<x>Mean_Y` + `<x>Err_Y` | `SetYError(graph)` | same |
| … + `<x>E_X` / `<x>Err_X` | `SetXYError(graph)` | X and Y error bars |
| `<x>_Yerr`, `<x>_Xerr` | `MakeFig` (automatic) | error bars from an `errorbar` object |
| names containing a number (`neg50_Y`, `pos25_Y`, `zero…`) | `SetColorOfGraphTraces(graph, scheme)` | traces sorted by that number and coloured along a colour table |
| `polar_curve_Y`, `polar_err_Y`, … | `MakePolarTuningGraph` | see `IgorPolarPlots.md` |

So a mean ± SEM pair should be drawn as **two lines** named `<x>M` and
`<x>E` (or `<x>Mean` / `<x>Err`), not as an `errorbar` object, if you
want to toggle the bars in Igor with `SetYError`; the `errorbar` route
(`_Yerr`) also works and attaches the bars on load.

### Lower-level pieces

`exportStructToHDF5(s, fileName, dataRoot, options)` writes every field of
a scalar struct as a dataset `/<dataRoot>/<field>` (`options.overwrite`,
`options.prefix`); `makeAxisStruct` is a thin layer over it, so anything
that is not a plot — a table of fitted parameters, say — can be exported
the same way and loaded with `MakeFig`'s loading part (`HDF5LoadGroup`) or
`RefreshGraphData`. `mergeStruct(A, B)` merges option structs.
`polarWaves(theta, mean, sem, …)` turns a tuning curve into the Cartesian
`polar_*` waves for `PolarPlots.ipf`.

---

## 2. Igor: loading and formatting

All of these expect the `.h5` **next to the saved `.pxp`** (the
experiment's home folder — save the experiment once before the first
`MakeFig`) and take the file's base name.

| Command | What it does |
|---|---|
| `MakeFig("CRF_A1")` | kills any graph/folder of that name, loads `CRF_A1.h5` into `root:CRF_A1`, draws every `*_Y` wave (vs its `*_X` when present) with the exported colour, line style, markers and `_Yerr`/`_Xerr` error bars (`DisplayFigFromMatlab`), applies `FormatGraph`, names the window `CRF_A1` |
| `FormatGraph()` | the lab's panel style: Helvetica 7 pt, 72 × 72 pt plot area, thin axes, 3 ticks, `expand=2` |
| `SetYError("CRF_A1")` / `SetXYError("CRF_A1")` | attach `*E_Y` (`*Err_Y`) waves as error bars to their `*M_Y` (`*Mean_Y`) traces and hide the error traces |
| `SetColorOfGraphTraces("CRF_A1", "cubicyf")` | colour traces along a colour table in the order of the number in their names (`cubicyf`, `cubicl`, `isol`, `winter`, `copper`, or any Igor colour table such as `BlueBlackRed`) |
| `RefreshGraphData("CRF_A1")`, `RefreshAllData()` | reload the `.h5` into the existing folder(s), so an open, formatted graph picks up re-exported numbers; new `*_Y` waves in the file are appended and a trace whose exported wave has vanished from the file is hidden (never removed; the printed line says how to show it again), so a renamed or added line shows up while traces you appended by hand are untouched (`ReconcileGraphTraces`) — formatting of existing traces is kept |
| `MakeScaleBars(x0, x1, y0, y1, "50 ms", "10 pA")` | hide the axes and draw scale bars with labels |
| `SaveAllGraphs()` | every visible graph to `<graph>.pdf` in the home folder (`SaveAllGraphsAsPDF`, `…AsEPS`, `…AsGraphicsFiles` for other formats); `SaveAllGizmos()` for 3-D plots |
| `MergeSelectedtoCurrent()` | merge other `.pxp` files into this one |

`DisplayFigFromMatlab(folder, decimateBy)` can also be called directly on
waves that are already loaded; `decimateBy > 1` averages every N points of
long traces before plotting. A `*_Y` wave with no `*_X` partner is plotted
against `<name>_start`/`<name>_delta` variables if they exist.

### Typical session

```
MakeFig("CRF_A1")                 // load + draw + FormatGraph
SetYError("CRF_A1")               // ctrlE_Y / drugE_Y -> error bars on ctrlM_Y / drugM_Y
ModifyGraph rgb(drugM_Y)=(65535,0,0)
Label left "spikes/s"
// ... re-export from MATLAB after fixing an analysis ...
RefreshAllData()                  // numbers update, formatting stays
SaveAllGraphs()                   // CRF_A1.pdf next to the .pxp -> Illustrator
```

### Troubleshooting

*"File not found" / HDF5OpenFile error* — the experiment is unsaved (no
home folder), the `.h5` is elsewhere, or the HDF5 XOP is not loaded.
*"no group '…' in …"* — the name passed is not the file's base name (e.g.
it still has `.h5`, which the loaders now strip, or the file was renamed
after export: the group inside keeps the export name). *Python cannot
overwrite an `.h5` (h5py `errno 35`, "unable to lock file")* — Igor still
has the file open, usually after a failed load; run `HDF5CloseFile/A 0`
in Igor (the loaders now close the file when a load fails). *Functions
"not a string function" when running a macro* — the procedures need
compiling: click Compile in a procedure window.
*Graph is empty* — no dataset ends in `_Y`: check the `DisplayName`s (a
line drawn with `plot` inside `hold on` and no name still exports as
`L00n_Y`, so an empty graph usually means the wrong axis handle was
passed). *Wave names need quotes (`'my-line_Y'`)* — the name contained
characters the sanitiser does not map; rename in MATLAB. *Error bars
missing* — `SetYError` only pairs `M_Y`/`E_Y` and `Mean_Y`/`Err_Y`; other
names need `ErrorBars` by hand. *Line style or marker not applied* — only
`-`/`--` and the six markers in the table are mapped; set the rest in Igor.
*`MakeFig` on a `polar_*` export* — use `MakePolarTuningGraph` instead
(`IgorPolarPlots.md`).

---

## Files

| File | Role |
|---|---|
| `Matlab/MatlabToIgorTools/makeAxisStruct.m` | axis → struct → `.h5` |
| `Matlab/MatlabToIgorTools/exportStructToHDF5.m` | struct → HDF5 datasets |
| `Matlab/MatlabToIgorTools/addLineToAxis.m` | `line` + `DisplayName` shorthand |
| `Matlab/MatlabToIgorTools/mergeStruct.m` | option-struct merge |
| `Matlab/MatlabToIgorTools/polarWaves.m` | tuning curve → `polar_*` waves |
| `Matlab/MatlabToIgorTools/makeIgorExportFigureScratch.m`, `Tutorials/matlab_tutorial.m` | worked examples |
| `Igor/ManookinLabIgorProcedures.ipf` | `MakeFig`, `MakeImage`, `FormatGraph`, `SetYError`, `SetXYError`, `SetColorOfGraphTraces`, `RefreshGraphData`, `RefreshAllData`, `MakeScaleBars`, `SaveAllGraphs*`, colour tables |
| `Igor/DisplayFigFromMatlab.ipf` | draws the traces from the loaded waves (the copy under `Matlab/MatlabToIgorTools/` is an older version; use the one in `Igor/`) |
| `Igor/PolarPlots.ipf` | polar tuning plots (`IgorPolarPlots.md`) |
