# Python (matplotlib) → HDF5 → Igor Pro

How a matplotlib axis becomes an Igor graph, using the `figure_utils`
package in `Python/` and the Igor procedures in `Igor/`. The file format
is the one `makeAxisStruct` writes from MATLAB (`MatlabToIgor.md`), so the
same Igor commands load both.

```
matplotlib axis  --axis_to_igor-->   <name>.h5  --MakeFig("<name>")-->       Igor XY graph
matplotlib axis  --image_to_igor-->  <name>.h5  --MakeImageFig("<name>")-->  Igor image (+ overlays)
```

## Install

```bash
pip install -e /Users/<you>/Documents/GitRepos/Manookin-Lab/ManuscriptTools/Python
```

(`-e` so edits to the repo take effect without reinstalling.) It needs
`h5py`, `numpy`, `matplotlib` and `seaborn` (imported at load). Then:

```python
from figure_utils import axis_to_igor, image_to_igor
```

## 1. `axis_to_igor(ax, filename, out_dir)` — XY plots

Give **every line a `label`**; the label becomes the wave name in Igor.

```python
fig, ax = plt.subplots(1, 2, figsize=(8, 4))
ax[0].plot(contrast, r.mean(0), color=(0, 0, 0), label='ctrlM')
ax[0].plot(contrast, r.std(0) / np.sqrt(len(r)), color=(0, 0, 0), label='ctrlE')
ax[0].plot(contrast, d.mean(0), color=(1, 0, 0), label='drugM')
ax[0].plot(contrast, d.std(0) / np.sqrt(len(d)), color=(1, 0, 0), label='drugE')
ax[0].set_xlabel('contrast'); ax[0].set_ylabel('spikes / s')
axis_to_igor(ax[0], filename='CRF_A1', out_dir=igor_dir)      # -> <igor_dir>/CRF_A1.h5
```

One call per axis: with subplots, pass each `Axes` separately with its
own file name (`Tutorials/python_tutorial.py`, and the examples in
`README.md`). `out_dir` is required.

### What is written

`<out_dir>/<filename>.h5` with one HDF5 group named `filename` (the name
`MakeFig` loads — do not rename the file without renaming the group) and,
for every `Line2D` on the axis (`ax.lines`: `plot`, `errorbar` centre
lines, `axhline`, …; not scatter collections, patches, bars or images):

| Dataset | Source | Notes |
|---|---|---|
| `Xlabel`, `Ylabel` | axis labels | applied by `MakeFig` |
| `<label>_X`, `<label>_Y` | `xdata`, `ydata` | the trace; `_Y` is the trace name in Igor |
| `<label>_color` | `color` **as given to matplotlib** | see below |
| `<label>_linestyle` | `linestyle` string (`'-'`, `'--'`) | see below |
| `<label>_markerSize` | `markersize` | |

**Labels.** Duplicate labels get a numeric suffix (`rf`, `rf1`, `rf2`, …),
which is what happens when a 2-D array is plotted in one call. Lines with
no label are exported under matplotlib's automatic `_childN`/`_lineN`
names — set `label=` on everything you want to keep. Nothing is
sanitised on the Python side: use letters, digits and underscores,
starting with a letter, under 32 characters, so the wave names are legal
in Igor without quoting.

**Colour and line style.** `DisplayFigFromMatlab` reads `_color` as a
numeric RGB wave in 0–1 and `_linestyle` as an Igor line-style code (0
solid, 3 dashed). `axis_to_igor` writes the colour exactly as matplotlib
holds it, so a numeric tuple (`color=(0, 0, 0)`) comes across while the
default cycle colours (`'#1f77b4'`) and letter names (`'k'`) are stored as
strings Igor cannot use; `_linestyle` is always the matplotlib string. In
practice: give numeric RGB tuples when the colour matters, and set line
styles in Igor. (`image_to_igor` already converts colours with
`matplotlib.colors.to_rgb`; `axis_to_igor` can be made to do the same.)

**Not exported:** markers, error bars, axis limits and log scales, fills.
`ax.errorbar` is a trap: its bars are a `LineCollection` (skipped) and its
centre line and caps are `Line2D`s labelled `_nolegend_` — the label you
pass goes to the container — so they export as `_nolegend__Y`,
`_nolegend_1_Y`, … with no bars. Export mean and SEM as two labelled
`plot` lines (`<x>M`, `<x>E`) and use `SetYError` in Igor for the bars,
exactly as from MATLAB.

### In Igor

```
MakeFig("CRF_A1")           // load CRF_A1.h5 into root:CRF_A1, draw, FormatGraph
SetYError("CRF_A1")         // ctrlE_Y -> error bars on ctrlM_Y, then hidden
SaveAllGraphs()             // CRF_A1.pdf next to the .pxp
```

`MakeFig`, `SetYError`/`SetXYError`, `SetColorOfGraphTraces`,
`RefreshAllData`, `FormatGraph` and the save commands are described in
`MatlabToIgor.md` §2; they do not care which language wrote the file.

## 2. `image_to_igor(ax, filename, out_dir)` — images with overlays

For `ax.imshow` panels: spatial receptive fields, spatiotemporal filters,
any heat map.

```python
fig, ax = plt.subplots()
ax.imshow(rf, cmap='RdBu_r', extent=(0, 400, 0, 300), origin='lower', label='rf')
ax.plot(cx, cy, color='w', label='rfContour')          # overlay, exported as a line
ax.set_xlabel('x (µm)'); ax.set_ylabel('y (µm)')
image_to_igor(ax, filename='RF_A1_c3', out_dir=igor_dir)
```

`Tutorials/python_image_tutorial.py` has an RGB and a colour-mapped
example.

### What is written

| Dataset | Content |
|---|---|
| `Xlabel`, `Ylabel` | axis labels |
| `XReversed`, `YReversed` | 1 if that matplotlib axis is inverted (`imshow` inverts y by default) — Igor reverses the same axis |
| `<img>_img` | the image **as rendered**: RGB after colormap and normalisation, `uint8`, shaped (x, y, 3) for Igor's direct-colour image waves |
| `<img>_scale` | `[x0, x1, y0, y1]` pixel-centre coordinates from the `extent`, applied with `SetScale/I` |
| `<label>_X/_Y/_color/_linestyle/_markerSize` | every line on the axis, as in `axis_to_igor` but with the colour converted to numeric RGB |

Exporting rendered RGB means Igor shows exactly what matplotlib showed
(colour map, `vmin`/`vmax`, alpha compositing) at the cost of the raw
values — export those separately with `axis_to_igor` or `h5py` if Igor
needs them. An image with no label, or a `_`-prefixed one, is named
`image` (or `image0`, `image1`, … when there are several).

### In Igor

```
MakeImageFig("RF_A1_c3")     // load, AppendImage with the scale, reverse axes, overlay lines
FormatRfContour("RF_A1_c3", scheme="cubicyf", alpha=32768)   // optional: fill closed contours
```

`MakeImageFig` (in `DisplayImageFromPython.ipf`; `MakeImage` in
`ManookinLabIgorProcedures.ipf` is the same with `FormatGraph` applied)
loads the file into `root:<name>` and calls `DisplayImageFromPython`,
which appends every `*_img` wave with its `*_scale`, sets the labels and
axis directions, and appends every `*_Y` line with its colour.
`FormatRfContour` (`RfContourFill.ipf`) fills closed contour traces with
translucent polygons — solid colour or spread along a colour table — the
same drawing-layer technique `PolarFill` uses for tuning curves.

## 3. Electrical images (`ElectricalImages.ipf`)

Full description — file format, how the amplitudes and sizes are computed,
every Igor option — in `docs/ElectricalImages.md`; RF mosaics
(`PopulationRF_<label>.h5`, `RfMosaics.ipf`) in `docs/RfMosaics.md`. In brief:

`A1_paper/notebooks/rf_figure.py --stage ei` exports an MEA cell's
electrical image with `axis_to_igor` as `EI_<label>.h5`: `array_X/_Y`
(every electrode, µm), `elec_X/_Y` (the electrodes above threshold),
`ei_amp_Y` and `ei_size_Y` (amplitude and relative marker size 0–1 per
shown electrode, in the same order — their `_X` partners are just the
electrode x again) and `peak_X/_Y`. Because two of those lines are data
carriers rather than things to draw, load the file with

```
MakeEIGraph("EI_A1")                          // 108-pt square plot area, circles up to 6 pt (area ~ amplitude), peak red
MakeEIGraph("EI_A1", height=144, maxSize=9)   // bigger panel, bigger circles
EISetMaxSize("EI_A1", 4)                      // rescale the circles on an open graph
EISetHeight("EI_A1", 72)                      // resize the plot area; the width follows (1 um = 1 um)
```

rather than `MakeFig`, which would plot `ei_amp_Y`/`ei_size_Y` as traces.
`MakeEIGraph` sets `ModifyGraph zmrkSize(elec_Y)={ei_size_Y,0,1,0,maxSize}`
on a square (Plan) axis system of the given `height` (points; the width
follows so microns are equal in both directions) with hidden axes; add a
scale bar with `MakeScaleBars`. Circle sizes are in points and do not scale
with the plot, so pick `maxSize` for the panel size you use (about 6 pt
for a 108-pt panel). The companion `EIwave_<label>.h5` (waveforms on the peak
electrode and its neighbours) is an ordinary line export for `MakeFig`.

## Conventions shared with MATLAB

The two exporters produce the same layout on purpose: one group per file,
named after the file; `_X`/`_Y` pairs define traces; suffixes carry style;
`<x>M`/`<x>E` (or `Mean`/`Err`) pairs become error bars with `SetYError`;
figure formatting happens in Igor; re-exporting and `RefreshAllData`
updates a finished graph. `MatlabToIgor.md` lists the suffixes and the
Igor commands in full; `IgorPolarPlots.md` covers polar tuning plots
(MATLAB-side `polarWaves` today; a Python equivalent would write the same
`polar_*` waves).

## Troubleshooting

*`TypeError` in `os.path.join`* — `out_dir` was not given. *Graph empty
in Igor* — no `_Y` datasets: the axis passed had no `Line2D`s (a scatter
or bar plot), or the wrong `Axes` of a subplot grid was passed. *Colours
or line styles not applied (or a text-wave error while drawing)* — string
colours or styles, see above. *Waves named `_nolegend_*`* — `errorbar`
was used, see above.
*Waves need quoting in Igor* — the label had spaces, dots or hyphens.
*`MakeFig` fails on an image file* — use `MakeImageFig`.

## Files

| File | Role |
|---|---|
| `Python/figure_utils/figure_utils.py` | `axis_to_igor`, `image_to_igor`, `_unique_label` |
| `Python/setup.py` | package install (`pip install -e Python`) |
| `Tutorials/python_tutorial.py`, `Tutorials/python_image_tutorial.py` | worked examples |
| `Igor/ManookinLabIgorProcedures.ipf` | `MakeFig`, `MakeImage`, formatting and save helpers |
| `Igor/DisplayFigFromMatlab.ipf` | draws XY traces from the loaded waves |
| `Igor/DisplayImageFromPython.ipf` | `MakeImageFig`, `DisplayImageFromPython` |
| `Igor/RfContourFill.ipf` | `FormatRfContour` for filled contour overlays |
| `Igor/ElectricalImages.ipf` | `MakeEIGraph`, `EIGraphFromFolder`, `EISetMaxSize`, `EISetHeight` for electrical images |
| `Igor/RfMosaics.ipf` | `MakeMosaicGraph`, `MosaicGraphFromFolder`, `MosaicSetHeight` for RF mosaics |
