# Electrical-image (EI) panels

How an MEA cell's electrical image gets from Vision's `.ei` file to an Igor
panel: the Python export (`A1_paper/notebooks/rf_figure.py --stage ei`,
`A1_paper/src/electrical_image.py`), the file it writes, and the Igor
procedures that draw it (`Igor/ElectricalImages.ipf`).

```
Vision .ei + electrode map  --rf_figure.py --stage ei-->  EI_<label>.h5, EIwave_<label>.h5
                                                              │
                                        MakeEIGraph("EI_<label>")  /  MakeFig("EIwave_<label>")
```

## What an electrical image is, and what the panel shows

The EI is Vision's spike-triggered average of the raw recording on every
electrode: an `[n_electrodes, n_samples]` array, computed during sorting
and stored in the `.ei` file. The panel puts one circle on every electrode
where the cell leaves a footprint, with the circle's **area** proportional
to the depth of the negative trough on that electrode (the classic EI
measure), so the soma and the axon show up as a cluster of large circles
and a trail of small ones. The companion waveform panel shows the EI on the
electrode with the deepest trough and on its nearest neighbours.

## Python side

### Config (`doc/cells/rf_mea.yaml`)

```yaml
electrical_images:
  - type: A1                    # label in the file names (or set `label`)
    experiment_name: 20230228C
    chunk: chunk1
    sort_algorithm: kilosort2
    cell_id: 1015               # or a list: one cell the sorter split; EIs averaged by spike count
ei:                             # optional; defaults shown
  metric: negative_peak         # per-electrode amplitude: trough depth | p2p (peak-to-peak)
  threshold: 0.05               # electrodes below threshold x max are not drawn as circles
  n_neighbors: 6                # waveform panel: peak electrode + n nearest
  waveform_window_ms: [-1.0, 3.0]   # around the trough on the peak electrode
```

```bash
python notebooks/rf_figure.py --stage ei --dry-run          # what will be written
python notebooks/rf_figure.py --stage ei --show             # matplotlib preview
python notebooks/rf_figure.py --stage ei --output-igor      # write the .h5 files to igor_dir
```

### How it is computed (`src/electrical_image.py`)

1. `load_ei` reads the EI with `visionloader.EIReader(dir, name,
   long_ei=True).get_ei_for_cell_id(id).ei`; `electrode_positions` takes
   the electrode map (x, y in µm) from the same Vision container
   (`get_electrode_map()`). The EI is **not** recomputed from the raw
   binary; the torch route in
   `analysis/spike_sorting/notebooks/electrical_image_example.ipynb` agrees
   with Vision on the peak electrode, which is what that notebook checks.
   If the EI has one more channel than the map has electrodes, the leading
   (TTL) channel is dropped. A `cell_id` list is one split cell: the EIs are
   averaged weighted by spike count.
2. `ei_amplitudes` gives one number per electrode: `negative_peak`
   (|min| over time, clipped at 0) or `p2p`.
3. `marker_sizes` maps amplitude to a relative size in 0–1 as
   `(amp / max)^0.5`, so the marker *area* is proportional to amplitude;
   electrodes below `threshold × max` get size 0 and are not drawn as
   circles.
4. `nearest_electrodes` picks the peak electrode and its `n_neighbors`
   nearest electrodes; their EI traces are cut to `waveform_window_ms`
   around the trough on the peak electrode, with t = 0 at the trough.

The run log prints, per cell: ids, spike counts, electrodes × samples,
the peak electrode and its amplitude, and how many electrodes passed the
threshold.

### Files written

`EI_<label>.h5` (via `axis_to_igor`; every line is a wave pair):

| Wave | Content |
|---|---|
| `array_X/_Y` | every electrode of the array, µm |
| `elec_X/_Y` | the electrodes above threshold — the circles |
| `ei_amp_Y` | amplitude per electrode in `elec`, same order (`ei_amp_X` is just the electrode x; ignore it) |
| `ei_size_Y` | relative marker size 0–1 per electrode in `elec`, same order |
| `peak_X/_Y` | the peak electrode |

`EIwave_<label>.h5`: `wave0_e<n>_X/_Y` (peak electrode `n`), `wave1_e<n>`
… `wave6_e<n>` (neighbours in order of distance); X in ms from the trough.

## Igor side (`Igor/ElectricalImages.ipf`)

Add an alias to `ElectricalImages.ipf` in Igor Procedures (it is
self-contained). With the `.h5` next to the saved `.pxp`:

```
MakeEIGraph("EI_A1")                          // 108-pt square plot area, circles up to 6 pt, peak electrode red
MakeEIGraph("EI_A1", height=144, maxSize=9)   // bigger panel, bigger circles
EISetMaxSize("EI_A1", 4)                      // rescale the circles on an open graph
EISetHeight("EI_A1", 72)                      // resize the plot area; the width follows (1 um = 1 um)
MakeFig("EIwave_A1")                          // the waveform panel is an ordinary line export
```

**Why not `MakeFig` for `EI_*`.** `ei_amp_Y` and `ei_size_Y` are data
carriers, not things to draw; `MakeFig` would plot them as traces.
`MakeEIGraph` loads the file (first HDF5 group, into `root:<name>`), draws
`elec_Y vs elec_X` as open circles with `ModifyGraph
zmrkSize(elec_Y)={ei_size_Y,0,1,0,maxSize}` (size 0 → 0 pt, size 1 →
`maxSize` pt, so the area mapping from Python is kept), the whole array as
1-pt grey dots behind, the peak electrode as a 3-pt red dot, and sets
`width={Plan,1,bottom,left}` with `height=<height>` so microns are equal
in both directions and the plot height fixes the width. Axes are hidden;
add a scale bar with `MakeScaleBars`.

**Sizes are in points, the data is in microns.** Marker sizes do not follow
the plot, so shrinking a panel makes the circles overlap into blobs while
the electrodes move closer together. On a 512-electrode array spanning
1890 x 900 um, the 60 um spacing is 7.2 pt apart at `height=108` but only
3.6 pt at `height=54` — so a 4-pt marker that looked right at 108 collides
with its neighbours at 54.

From v1.8 `EISetHeight` handles this: after resizing it calls
`EIFitMarkers`, which sets the largest marker to 90% of the electrode
spacing **as drawn**, so the circles stay separated at any panel size.
`EISetHeight(graph, 54, maxSize=3)` forces a size instead, and
`maxSize=0` leaves the markers alone. `EIFitMarkers(graph,
fraction=0.6)` re-fits them smaller after any other resize (`expand`, a
manual drag, `MosaicSetExtent`), and `EIElectrodePitch(graph)` returns the
spacing it measured. `EISetMaxSize` still applies an absolute size in
points.

**Everything is an ordinary trace** (`elec_Y`, `array_Y`, `peak_Y`), so
`ModifyGraph` and Modify Trace work: e.g. `ModifyGraph rgb(elec_Y)=(0,0,65535)`
or `ModifyGraph hideTrace(array_Y)=1`. `RefreshAllData` reloads the folder
after a re-export (the `ei_size_Y` wave is updated in place, so the sizes
follow).

**Drawing from waves already loaded**: `EIGraphFromFolder(graphName,
[maxSize, height])` with the current data folder set to the one holding
the `EI_*` waves.

## Dendritic mosaics

`A1_paper/notebooks/compute_crosscorr.py --ei-mosaics` writes a second
kind of `EI_<label>.h5`: instead of one cell's electrodes it holds one
**dendritic-field outline per cell**, `cell_source<k>_X/_Y` and
`cell_target<k>_X/_Y` in microns with their `*_color` waves, plus
`array_X/_Y`. The outline comes from the early part of each EI — the
amplitude of every electrode measured only inside a short window around
the somatic trough, so the axon, which arrives later on electrodes further
from the soma, is excluded (`A1_paper/src/electrical_image.py`:
`dendritic_amplitudes`, `dendritic_outline`). The single-cell panel from
the same tool carries that outline too, as a `dendrite_X/_Y` trace.

**One naming scheme on both panels.** `elec` / `esize` are the electrodes
drawn as sized markers and `fit` the outline fitted to them — bare on a
single-cell panel, tagged per cell on a mosaic (`elec_source<k>`,
`esize_source<k>`, `fit_source<k>`). On a mosaic `elec_<tag>` is measured
inside the dendritic window; the single-cell panel's bare `elec` is the
whole waveform, and its window electrodes are the extra `dend` / `dsize`
pair, so the two can be compared.

**Marker sizes.** `esize` / `dsize` run 0..1 and drive
`zmrkSize={sz, 0, 1, 0, maxSize}`. How much they spread is set by
`options.ei.dendrite.size_power` in `cross_correlations.yaml`: 0.5
(default) puts the marker *area* in proportion to the amplitude, so an
electrode at the 0.15 threshold still draws at 39% of the largest; 1.0 puts
the *diameter* in proportion, so the same electrode draws at 15% and weak
electrodes read as weak. Lowering `threshold` widens the range either way. The electrodes are drawn in
their outline's own colour and behind it, which makes it obvious when an
outline is enclosing three markers and so reporting the interpolation
kernel rather than a dendritic field. On the single-cell panel `dend` sits
alongside the whole-waveform `elec` / `ei_size`, so the difference between
them is what the dendritic window removed.

RF mosaics keep `cell_<role><k>` — that is what `rf_figure.py` writes and
what `RfMosaics.ipf` matched. From v1.6 every `Mosaic*` function accepts
either prefix (`MosaicIsCellTrace`, `MosaicCellTraces`), so
`MosaicFillByColor`, `MosaicClean`, `MosaicSetExtent` and the rest work on
EI mosaics unchanged.

```
MakeEIGraph("EI_A1_dendrites")                    // recognises the mosaic and draws the outlines
MakeEIMosaicGraph("EI_A1_dendrites", showArray=0) // force it; without the whole-array dots
MakeEIMosaicGraph("EI_A1_dendrites", maxSize=6)   // bigger per-cell electrode markers
EIMosaicElectrodes("EI_A1_dendrites", 0)          // hide the elec_ electrodes
EIMosaicElectrodes("EI_A1_dendrites", 1, maxSize=5)
MosaicFillByColor("EI_A1_dendrites", alpha=16384) // shade each field in its own colour
```

`MakeEIGraph` tells the two apart by their waves: `elec_X/_Y` means one
cell's electrodes, `cell*_Y` means a mosaic, and it forwards to
`MakeEIMosaicGraph` (printing a line saying so) rather than aborting. The
mosaic drawing itself is `RfMosaics.ipf`'s `MosaicGraphFromFolder` — same
outlines, same `*_color` handling, same reversed y axis — with the array
appended behind as grey dots, so `MosaicSetHeight`, `MosaicSetExtent`,
`MosaicFillByColor` and `MosaicClean` all work on it. `ElectricalImages.ipf`
therefore needs `RfMosaics.ipf` loaded for mosaics (it says so if not);
single-cell panels stay self-contained.

### Troubleshooting

*"elec_X/_Y not found"* — the file is not a single-cell `EI_*` export (an
`EIwave_*` file loads with `MakeFig`). A dendritic mosaic is no longer an
error: `MakeEIGraph` detects it and draws the outlines.
*"RfMosaics.ipf is not loaded"* — a mosaic needs it; open it in Igor
Procedures alongside `ElectricalImages.ipf`.
*"no elec_Y trace in <graph>"* — fixed in v1.6: `EISetMaxSize` used to
assume a single-cell panel. It now sizes `elec_Y` and/or `dend_*_Y`,
whichever the graph has, and only prints when there is nothing to size.
*"trace is not on graph" from `ReorderTraces`* — fixed in v1.4. Its brace
list is parsed as trace **names**, so passing a wave reference variable
(`{wy}`) makes Igor look for a trace called "wy"; write `{$name}` and use
`_back_` as the anchor. *Circles all the same size* — `ei_size_Y` is
missing; the graph falls back to `msize = maxSize/2`; re-export.
*Circles too big/small after resizing the panel* — `EISetMaxSize`.
*Python: "unable to lock file"* — Igor holds the `.h5` open; `HDF5CloseFile/A 0`.

## Files

| File | Role |
|---|---|
| `A1_paper/src/electrical_image.py` | `ei_amplitudes`, `marker_sizes`, `nearest_electrodes`, `ei_panel_data`, and for the dendritic field `electrode_pitch`, `somatic_trough`, `window_samples`, `dendritic_amplitudes`, `amplitude_map`, `convex_hull`, `dendritic_outline` (pure numpy) |
| `A1_paper/notebooks/rf_figure.py` | `load_ei`, `electrode_positions`, `load_electrical_image`, `ei_panels`, `--stage ei` |
| `A1_paper/notebooks/compute_crosscorr.py` | `electrical_images` / `ei_mosaics` in `doc/cells/cross_correlations.yaml`: `--ei`, `--ei-mosaics` |
| `A1_paper/tests/test_electrical_image.py` | synthetic-array tests, fake Vision loaders |
| `A1_paper/tests/test_electrical_image_dendrite.py` | dendritic window and outline, synthetic EI with a propagating axon |
| `Igor/ElectricalImages.ipf` | `MakeEIGraph`, `EIGraphFromFolder`, `MakeEIMosaicGraph`, `EIMosaicFromFolder`, `EIMosaicStyleElectrodes`, `EIMosaicElectrodes`, `EILoadH5`, `EISetMaxSize`, `EISetHeight` |
