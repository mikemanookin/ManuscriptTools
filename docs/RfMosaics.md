# Receptive-field mosaic panels

How a whole population's receptive-field outlines get from Vision STAs to
an Igor panel: the Python export (`A1_paper/notebooks/rf_figure.py --stage
mosaics`, outlines from `A1_paper/src/rf_contours.py`), the file it writes,
and the Igor procedures that draw and fill it (`Igor/RfMosaics.ipf`,
`Igor/RfContourFill.ipf`).

```
Vision STAs of one type  --rf_figure.py --stage mosaics-->  PopulationRF_<label>.h5  +  data/rf_mosaics/<label>_<exp>_<chunk>.csv
                                                                     │
                                       MakeMosaicGraph("PopulationRF_<label>")  [+ FormatRfContour(...)]
```

## Python side

### Config (`doc/cells/rf_mea.yaml`)

```yaml
rf_mosaics:
  plot_type: contour        # contour | ellipse
  fit_threshold: 0.5        # fraction of the RF peak at which the outline is drawn (both types)
  min_spikes: 0             # skip cells (after merging) with fewer spikes
  cell_types:
    - type: A1
      search_term: A1       # Vision cell-type search (get_all_cells_similar_to_type)
      experiment_name: 20250924C
      chunk: chunk1
      sort_algorithm: kilosort4
      merges:               # optional: each list is ONE cell the sorter split
        - merge: [237, 241, 349]
      exclude: [88]         # optional: ids to drop
```

```bash
python notebooks/rf_figure.py --stage mosaics --dry-run     # search terms, merges, output names
python notebooks/rf_figure.py --stage mosaics --show        # preview
python notebooks/rf_figure.py --stage mosaics --output-igor # .h5 + CSV
```

### How it is computed

1. **Cells.** `cells_of_type(vision_data, search_term)` returns the ids
   whose Vision class matches. `mosaic_groups` turns them into cells: every
   `merges` list is one cell (its ids leave the singles; an id the search
   missed is still used and logged), `exclude` ids are dropped, the rest
   are single cells in search order.
2. **STA.** `weighted_sta` averages a split cell's STAs weighted by spike
   count, exactly as for the example cells; `min_spikes` drops sparse
   cells after merging.
3. **Outline** (`mosaic_outline`), on the **full** spatial map from
   `lnp.compute_spatiotemporal_maps` (rank-1 map, normalized, colour
   channels averaged), converted to microns with `micronsPerStixelX`:
   - `contour`: the iso-level contour of the lightly smoothed,
     spline-upsampled map at `fit_threshold × peak` (`rf_contours.iso_contour`;
     the `contour` block's `smooth_px` and `upsample` apply);
   - `ellipse`: an elliptical 2-D Gaussian is fitted to the map
     (`rf_contours.fit_gaussian_2d`) and its level set at the same fraction
     is drawn, i.e. the n-SD ellipse with n = √(−2 ln f).

   `fit_threshold` therefore means the same thing for both: 0.5 is the
   half-maximum outline (1.18 SD of a Gaussian); 0.607 (= e^−½) is the
   1-SD ellipse used by most primate mosaic papers. Below ≈ 0.4 contours on
   coarse STAs start to break up or merge with the surround.
4. A cell whose STA cannot be outlined (no contour at the level, a fit
   that fails) is logged and skipped; the mosaic is never aborted by one
   cell.

The log reports the number of cells found, the number after merging, the
outlines drawn, the median equivalent diameter, and every skipped cell
with its reason.

### Files written

`PopulationRF_<label>.h5`: `cell0_X/_Y` … `cellN_X/_Y`, closed outlines in
µm on the stimulus/STA coordinate system (x right, **y increasing
downward**, as in the STA image).

`data/rf_mosaics/<label>_<experiment>_<chunk>.csv`: one row per outline —
`trace` (the wave name), `cell_ids`, `n_spikes`, centre `x_um`, `y_um`,
`diameter_um` (equivalent circle), `area_um2`, `method`, `level`, `r2`
(Gaussian fits only). This is the source for RF-size statistics and for
matching a trace back to its Vision ids.

## Igor side

### `Igor/RfMosaics.ipf`

```
MakeMosaicGraph("PopulationRF_A1")                 // 108-pt square plot area, 0.5-pt black outlines, y reversed, axes hidden
MakeMosaicGraph("PopulationRF_A1", height=144, lineSize=0.75)
MosaicSetHeight("PopulationRF_A1", 108)            // resize an open graph (width follows, 1 um = 1 um)
```

`MakeMosaicGraph` loads the file (first HDF5 group, into `root:<name>`),
appends every `cell*_Y vs cell*_X`, sets `width={Plan,1,bottom,left}` with
`height=<height>`, reverses the left axis (`SetAxis/A/R left`) so the
mosaic is oriented like the STA, hides the axes and draws thin black
outlines. `MosaicGraphFromFolder(graphName, [height, lineSize])` does the
same from waves already loaded. `MakeFig` also works on these files (they
are plain line exports); it just leaves the aspect, orientation and styling
to you.

### Refreshing after a re-export — without rebuilding

`RefreshAllData` alone is not enough for a mosaic: the fill polygons from
`FormatRfContour` are drawing objects, so the **old** fills stay under the
new outlines, and cells the refresh appends arrive with default styling.
Use the mosaic-specific refresh, which keeps the graph's size, margins,
text boxes and every non-cell trace:

```
MosaicRefresh("PopulationRF_A1")                        // reload the .h5 + MosaicClean
MosaicRefresh("PopulationRF_A1", refill=1, alpha=16384) // ... and redraw the fill (RfContourFill.ipf)
MosaicRefresh("PopulationRF_A1", refill=1, scheme="cubicyf", alpha=32768)
MosaicClean("PopulationRF_A1")                          // the tidy-up alone, e.g. after a plain RefreshAllData
```

`MosaicClean` (1) removes `cell*_Y` traces that the reload hid (their
wave left the file) or whose wave is gone and kills those waves — on a
mosaic every cell trace is generated, so nothing hand-made is lost, and
traces not named `cell*_Y` (scale bars, outlines you added) are untouched;
(2) gives every `cell*_Y` trace the line size and colour of the first cell
trace, so appended cells match; (3) deletes the `rfFills` drawing group
(the stale fills) and, with `refill=1`, runs `FormatRfContour` again with
the colour/alpha or scheme you pass, then restores the plot height that
`FormatRfContour` resets to 72 pt; (4) re-asserts the Plan aspect, the
reversed y axis and the hidden axes. It prints what it did.

### Filling the outlines (`Igor/RfContourFill.ipf`)

```
FormatRfContour("PopulationRF_A1")                              // translucent black fill
FormatRfContour("PopulationRF_A1", red=65535, green=0, blue=0)  // one colour
FormatRfContour("PopulationRF_A1", scheme="cubicyf", alpha=32768)   // colours along a table, 50 % opacity
MosaicSetHeight("PopulationRF_A1", 108)                         // FormatRfContour fixes the size at 72 x 72 pt; restore
```

`FormatRfContour` fills each closed trace with a polygon drawing object in
axis coordinates (the same technique as `PolarFill`), grouped as `rfFills`
so a second call replaces the first; `alpha` is 0–65535. `scheme` needs
`ManookinLabIgorProcedures.ipf` for the colour tables (`cubicyf`, `cubicl`,
`isol`, `winter`, `copper`). Because the fills are drawing objects, rerun
`FormatRfContour` after `RefreshAllData` changes the outlines.

### Getting the scale right — within a panel and between panels

Within one panel the outlines are proportional to the real RF sizes as
long as one micron is the same length in x and y: `MakeMosaicGraph` sets
`ModifyGraph width={Plan,1,bottom,left}` for exactly that, so the axis
*ranges* can be anything. `MakeFig` does not set it, and `FormatRfContour`
overrides it (it forces a 72 × 72 pt plot, which squashes the panel to a
square whatever the data ranges), so after a fill run `MosaicSetHeight`
(or `MosaicClean`), which restore Plan.

Between panels, Plan is not enough: each mosaic is autoscaled to its own
extent, so two preps at the same panel size sit at different
magnifications. Give every mosaic the same axis span at the same height:

```
MosaicSetExtent("PopulationRF_A1", 1500)      // both axes 1500 um, centred on the data
MosaicSetExtent("PopulationRF_RB", 1500)      // same span + same height = same um/pt
MosaicSetExtent("PopulationRF_A1", 1500, xCenter=800, yCenter=600)
```

`MosaicSetExtent` reads the data extent from the `cell*` traces, sets the
axes to the requested spans (y reversed), re-asserts Plan, warns if the
data are wider than the span (outer cells clipped), and prints the panel
size and the resulting µm/pt. Pick a span at least as large as the biggest
mosaic's extent so nothing is cut off, then put one `MakeScaleBars` bar
(e.g. 100 µm) on one panel — it is valid for all of them.

**Wide arrays.** A single `spanUm` gives both axes the same span, hence a
square panel; on an array twice as wide as it is high that leaves empty
bands above and below. Give the y span separately — with Plan the width
follows, so the panel takes the array's aspect while the µm/pt stays the
same for every panel that shares `ySpanUm` and the height:

```
MosaicSetExtent("PopulationRF_A1", 2000, ySpanUm=1000)   // 2:1 array: 2000 x 1000 um -> 216 x 108 pt at height 108
MosaicSetExtent("PopulationRF_RB", 1200, ySpanUm=1000)   // narrower array, same ySpanUm -> same um/pt, narrower panel
MosaicFitExtent("PopulationRF_A1", padUm=50)             // spans = data extent + 50 um each side (panel = array's aspect;
                                                         //   um/pt then depends on the data, so use SetExtent for comparability)
```

The same logic applies to the EI panels (`EISetHeight` keeps Plan, and the
array's aspect sets the width) and to any other Plan-aspect graph: fix the
height and the y span, and let the x span decide the width.

### Coloured exports: source and target cells (`compute_crosscorr.py`)

`A1_paper/notebooks/compute_crosscorr.py --mosaics` writes
`CcgMosaic_<name>.h5` files in which the source cell(s) of a
cross-correlation dataset are `cell_source<k>` traces in one colour and the
target cells `cell_target<k>` traces in another (the colours come from
`options.mosaic.source_color` / `target_color` in
`doc/cells/cross_correlations.yaml` and travel in the `*_color` waves of the
export). `MakeMosaicGraph` applies those colours instead of black,
`MosaicClean` / `MosaicRefresh` keep them, and

```
MakeMosaicGraph("CcgMosaic_A1_A1_gap")
MosaicFillByColor("CcgMosaic_A1_A1_gap", alpha=16384)      // each outline shaded in its own trace colour
MosaicFillByColor("CcgMosaic_A1_A1_gap", alpha=32768, match="cell_target*")   // only the targets
```

fills every outline with its own trace colour (polygons in the `rfFills`
group, so `MosaicClean` removes them; the plot size is left alone). Every
call first deletes the previous fill (`MosaicDeleteFills`), so filling twice
— e.g. `MakeRFGraph`, which fills already, followed by a `FormatPopulationContour`
that fills again — gives one layer of shading, not two stacked ones. Each
polygon is its own drawing group, so removing them by hand needs the loop
`do ; DrawAction/L=UserFront getgroup=rfFills, delete ; while (V_flag)`, not a
single `DrawAction`. Recolour
a trace with `ModifyGraph rgb(cell_source0_Y)=(…)` and call
`MosaicFillByColor` again to change a fill. `FormatRfContour` also learned
`match` and `group` for the same purpose with explicit colours:
`FormatRfContour(g, match="cell_source*", red=…, group="srcFills")` then
`FormatRfContour(g, match="cell_target*", group="tgtFills")` — two groups, so
the second call does not delete the first fill. The companion
`CcgMosaic_<name>.csv` says which Vision id and type each trace is.

### Styling and scale bar

Outlines are ordinary traces (`cell0_Y`, …): `ModifyGraph lsize=0.75`,
`ModifyGraph rgb(cell3_Y)=(65535,0,0)` to highlight one cell (the CSV
tells you which ids `cell3` is), `MakeScaleBars` for a 100-µm bar. Two
types on one panel: `MakeMosaicGraph` one, then `AppendToGraph` the other
type's waves from its folder (`root:PopulationRF_RB:cell0_Y vs …`).

## Files

| File | Role |
|---|---|
| `A1_paper/src/rf_contours.py` | `iso_contour`, `fit_gaussian_2d`, `gaussian_ellipse`, `rf_contour` |
| `A1_paper/notebooks/rf_figure.py` | `cells_of_type`, `mosaic_groups`, `level_to_sigma`, `weighted_sta`, `mosaic_outline`, `load_mosaic_cells`, `mosaic_panels`, `--stage mosaics` |
| `A1_paper/tests/test_rf_figure.py`, `test_rf_contours.py` | merge/exclude logic, contour-vs-ellipse equivalence, fit recovery |
| `Igor/RfMosaics.ipf` | `MakeMosaicGraph`, `MosaicGraphFromFolder`, `MosaicSetHeight`, `MosaicSetExtent`, `MosaicFitExtent`, `MosaicRefresh`, `MosaicClean`, `MosaicApplyColors`, `MosaicFillByColor` |
| `Igor/RfContourFill.ipf` | `FormatRfContour` (fills; `match`, `group` options), `DrawFilledContour` |
| `A1_paper/notebooks/compute_crosscorr.py` | `--mosaics`: `CcgMosaic_<name>.h5` source/target mosaics + CSV |
