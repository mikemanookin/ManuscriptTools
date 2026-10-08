# Polar plots in Igor Pro

Two ways to draw direction-tuning (polar) plots from lab data, and when to
use which.

| | WaveMetrics **Polar Graphs** package | **PolarPlots.ipf** (this repo) |
|---|---|---|
| What it is | Igor's built-in polar graph package (`#include <New Polar Graphs>`) | An ordinary XY graph drawn on a square axis system; the rings, error bars and vector are plain traces |
| Angle labels around the rim, radius tick labels | yes, configurable | no (add text boxes if needed) |
| Radial error bars (SEM) | no — append ±SEM as extra traces | yes |
| Preferred-direction / DSI vector | draw by hand | yes, rescales with the rings |
| Round-number outer ring, shared scale across cells | via package settings | `rmax=`, `PolarSetScale` |
| Shaded tuning hull | by hand (Fill to zero on the trace, see below) | `fill=`, `PolarFill` |
| Works with the standard Igor tools (Modify Trace, layouts, PDF export) | partly — the axes are package objects | fully |
| Data | radius wave + angle wave | `polar_*` waves from `makeAxisStruct` (MATLAB `polarWaves.m`) |

Use the package when you want labelled polar axes and have no error bars;
use `PolarPlots.ipf` when the figure needs mean ± SEM per direction, a DSI
vector, or the same scale on several cells.

---

## 1. WaveMetrics Polar Graphs package

### Making one

```
#include <New Polar Graphs>          // in the procedure window, then compile

WMNewPolarGraph("", "polarWin")                              // empty polar graph named polarWin
WMPolarAppendTrace("polarWin", tuning_M_Y, tuning_M_X, 360)  // radius wave, angle wave, angle units
```

The last argument is the angle unit of the angle wave: `360` for degrees,
`2*pi` for radians, `400` for grads. The radius wave holds the response at
each angle (e.g. `tuning_M_Y` from an `example_*.h5` export, with
`tuning_M_X` the direction in degrees). Append a closed ring by repeating
the first point at the end of both waves.

There are no radial error bars in the package. To show ± SEM, append the
upper and lower curves as two more traces:

```
Duplicate/O tuning_M_Y, tuning_hi_Y, tuning_lo_Y
tuning_hi_Y = tuning_M_Y + tuning_E_Y
tuning_lo_Y = max(tuning_M_Y - tuning_E_Y, 0)
WMPolarAppendTrace("polarWin", tuning_hi_Y, tuning_M_X, 360)
WMPolarAppendTrace("polarWin", tuning_lo_Y, tuning_M_X, 360)
```

(`MakePolarTuningGraphWM` in `PolarPlots.ipf` does exactly this.)

To shade the inside of the curve, the package offers nothing specific; the
appended trace is an ordinary XY trace, so `ModifyGraph
mode(tuning_M_Y)=7, hbFill(tuning_M_Y)=2` (Fill to zero) fills between
each segment and the (hidden) horizontal axis. That covers a convex curve
correctly but over-fills a curve with a notch facing the horizontal axis;
for an exact fill draw a polygon of the curve's Cartesian points in the
UserBack layer, as `PolarFill` in `PolarPlots.ipf` does.

### Adjusting the polar axes — why Modify Axis does nothing

The circular radius axis and the angle labels are **not Igor axes**. The
package draws them itself inside a normal graph whose real left and bottom
axes are hidden, so `ModifyGraph` and the Modify Axis dialog only reach
those hidden outer axes. Everything about the polar axes lives in a set of
per-graph variables that the package reads when it redraws.

**Interactively**: with the polar graph in front, open the package's
control panel (Graph menu → Packages → Polar Graphs, or the panel that
opens with a new polar graph; in recent versions "Modify Polar Graph…").
Its tabs cover the radius axis (inner/outer radius, major increment,
minor ticks, tick labels and their font, size and position around the
circle), the angle axis (where 0° points, clockwise or counter-clockwise,
angle range, major/minor angle increments, label format) and the grid
lines. Changes apply on Redraw.

**Programmatically**: set the same variables by name and redraw.

```
WMPolarGraphSetVar("polarWin", "majorRadiusInc", 10)     // radius ticks every 10
WMPolarGraphSetVar("polarWin", "minorRadiusTicks", 1)    // minor ticks between majors
WMPolarGraphSetVar("polarWin", "innerRadius", 0)
WMPolarGraphSetVar("polarWin", "outerRadius", 25)        // radius range 0–25
WMPolarGraphSetVar("polarWin", "majorAngleInc", 90)      // angle labels every 90°
WMPolarGraphSetVar("polarWin", "minorAngleTicks", 2)
WMPolarGraphSetVar("polarWin", "zeroAngleWhere", 0)      // where 0° points, degrees
WMPolarAxesRedrawGraphNow("polarWin")
```

String settings (fonts, label formats) go through `WMPolarGraphSetStr`.
Key names have changed slightly between Igor versions, so treat the ones
above as the usual names rather than gospel: the authoritative list for
your installation is the graph's package folder in the Data Browser,
`root:Packages:WMPolarGraphs:<graphName>:` — every variable and string in
it is one settable key, showing its current value. Change one, call
`WMPolarAxesRedrawGraphNow`, and see what moves. The procedure file itself
(`DisplayProcedure "WMPolarGraphSetVar"`) documents them at the top.

### Limits worth knowing

The package's objects are redrawn from its variables, so styling applied
directly to them can be lost on the next redraw; make changes through the
panel or `WMPolarGraphSetVar`. Traces appended with `WMPolarAppendTrace`
are ordinary traces and can be styled with `ModifyGraph`.

---

## 2. `PolarPlots.ipf` — XY polar plots with error bars

`Igor/PolarPlots.ipf` draws a tuning curve with radial SEM bars, reference
rings and a preferred-direction vector as a plain XY graph. The conversion
from (angle, radius) to (x, y) is done on the MATLAB side by
`Matlab/MatlabToIgorTools/polarWaves.m`, and the waves are exported with
`makeAxisStruct` like any other panel.

### MATLAB export

```matlab
W = polarWaves(theta_deg, mean_rate, sem_rate, 'Vector', [dsi, pref_dir]);
figure; hold on
line(W.grid_x,  W.grid_y,  'DisplayName', 'polar_grid',  'Color', [0.7 0.7 0.7], 'LineStyle', ':');
line(W.err_x,   W.err_y,   'DisplayName', 'polar_err',   'Color', 'k');
line(W.curve_x, W.curve_y, 'DisplayName', 'polar_curve', 'Color', 'k');
line(W.pts_x,   W.pts_y,   'DisplayName', 'polar_pts',   'Color', 'k', 'LineStyle', 'none', 'Marker', 'o');
line(W.vec_x,   W.vec_y,   'DisplayName', 'polar_vec',   'Color', 'r', 'LineWidth', 1.5);
axis equal off
makeAxisStruct(gca, 'polar_A1_GratingDSOS_c1', 'basedir', igor_dir);
```

For a shaded hull in the MATLAB preview, `patch(W.curve_x, W.curve_y, 'k',
'FaceAlpha', 0.2, 'EdgeColor', 'none')` before the lines; `makeAxisStruct`
exports lines only, so the shading in Igor comes from `fill=` /
`PolarFill`, which use the same closed curve.

`polarWaves` returns, all in Cartesian coordinates with the angle measured
counter-clockwise from +x: `curve_x/y` (the mean curve as a closed ring),
`err_x/y` (for each direction the segment from mean − SEM to mean + SEM,
segments separated by NaN so they draw as separate bars), `pts_x/y` (the
means, for markers), `grid_x/y` (rings at `'Rings'` × `rmax`, default 50 %
and 100 %, plus the axis cross) and, with `'Vector', [dsi pref]`,
`vec_x/y` (a segment from the origin of length dsi × rmax at the preferred
direction). Negative means are clipped to zero.

The outer ring radius `W.rmax` is the largest mean + SEM (`'RmaxFrom'
'sem'`, default) or the largest mean (`'RmaxFrom' 'mean'`), rounded **up**
to a round number — the nearest of 1, 1.5, 2, 2.5, 3, 4, 5, 6, 8 × 10ᵏ, so
24.8 → 25, 36.6 → 40, 12 → 15 (`'Nice'` true). Pass `'Rmax', 30` to fix it,
e.g. to give several cells the same scale.

The `.h5` written by `makeAxisStruct` holds `polar_curve_X/_Y`,
`polar_err_X/_Y`, `polar_pts_X/_Y`, `polar_grid_X/_Y` and `polar_vec_X/_Y`.

### Drawing in Igor

Add `PolarPlots.ipf` to the procedures (an alias in Igor Procedures, like
`ManookinLabIgorProcedures.ipf`, or `#include`). With the `.h5` next to the
saved `.pxp` — the same convention as `MakeFig` — run:

```
MakePolarTuningGraph("polar_A1_GratingDSOS_c1")                           // auto scale
MakePolarTuningGraph("polar_A1_GratingDSOS_c1", rmax=25)                  // outer ring at 25 sp/s
MakePolarTuningGraph("polar_A1_GratingDSOS_c1", rmax=30, rings="0.5;1;")  // rings at 15 and 30
MakePolarTuningGraph("polar_A1_GratingDSOS_c1", showErr=0)                // no SEM bars; scale from the means
MakePolarTuningGraph("polar_A1_GratingDSOS_c1", fill=0.2)                 // shade the hull, 20 % black
PolarSetScale("polar_A1_GratingDSOS_c1", 40, "0.25;0.5;0.75;1;")          // rescale an open graph
PolarFill("polar_A1_GratingDSOS_c1", red=0, green=0, blue=65535, alpha=0.15)   // (re)shade, blue
PolarUnfill("polar_A1_GratingDSOS_c1")                                    // remove the shading
```

`MakePolarTuningGraph(name, [rmax, rings, showErr, fill])` loads `<name>.h5`
from the experiment's home folder into `root:<name>` (Igor does not read
an `.h5` just because it sits beside the `.pxp`; the file's single HDF5
group is loaded whatever it is called), then builds the graph `<name>`:
curve, SEM bars (unless `showErr=0`), mean points, rings and vector on a
square axis system (`ModifyGraph width={Plan,1,bottom,left}`) with the
Cartesian axes hidden, and a text box giving the outer ring's radius in
spikes/s.

**Scale.** With `rmax` omitted, the outer ring is the largest mean (plus
SEM when the bars are shown) rounded up to a round number as above. `rings`
is a semicolon list of fractions of `rmax`. The grid waves are rebuilt in
Igor by `PolarSetScale(graphName, rmax, rings)`, so any scale can be set
after the fact without re-exporting. Because the DSI vector's length is
DSI × rmax, it is rescaled with the rings: on the first draw the DSI and
preferred angle are recovered from the exported vector and grid and stored
in the note of `polar_vec_X`, and every rescale redraws the vector from
them.

**Shading the hull.** `fill=<opacity>` (0–1) shades the area enclosed by
the mean curve; `PolarFill(graphName, [red, green, blue, alpha])` does the
same on an open graph (colour components 0–65535, default black, `alpha`
default 0.2) and `PolarUnfill(graphName)` removes it. The shading is a
polygon *drawing object* with the vertices of `polar_curve_X/_Y`, placed in
the graph's UserBack layer in axis coordinates: it lies behind the grid,
error bars and traces, follows `PolarSetScale`, and exports with the graph.
Because it is a drawing object rather than a trace it does not track the
waves — rerun `PolarFill` if the curve changes — and Modify Trace does not
reach it (edit it with the drawing tools, or `PolarFill` again). A polygon
fills exactly the region the curve encloses, which is why it is used
instead of the trace's own Fill to zero mode: that fills between each
segment and the horizontal axis, so a notch in the curve facing the axis
(a two-lobed orientation-selective cell, say) is filled over.

**Existing waves.** `PolarTuningGraphFromFolder(graphName, [rmax, rings,
showErr, fill])` draws from `polar_*` waves in the current data folder, for
waves loaded some other way.

**Helpers.** `PolarNiceCeil(x)` is the round-number rule;
`PolarDataMax(showErr)` the largest radius in the current folder's data;
`PolarRememberDsi()` stores the DSI in the vector's note (a no-op once
stored); `PolarFill` / `PolarUnfill` add and remove the hull shading.

### Styling

Everything on the graph is a normal trace named after its Y wave:
`polar_curve_Y`, `polar_err_Y`, `polar_pts_Y`, `polar_grid_Y`,
`polar_vec_Y`. Use `ModifyGraph` or Modify Trace Appearance as usual, e.g.
`ModifyGraph lsize(polar_curve_Y)=1.5, rgb(polar_vec_Y)=(0,0,65535)`. The
graph has no angle labels; add them with `TextBox` or in Illustrator. To
overlay two conditions (bright and dark bars, say), draw the second with
`PolarTuningGraphFromFolder` into the same window by appending its waves
with `AppendToGraph ... vs ...` after giving them a common `rmax`.

### Size: why two polar graphs can differ when their settings agree

Line thickness and marker size are specified in **points**. They do not
follow the data, so `rmax` has no effect on them and two graphs built by
this file start out identical. What changes them afterwards is the
geometry of the graph itself, in two ways:

- **`ModifyGraph expand`** scales everything the graph draws — plot area,
  fonts, line widths and markers — and it carries into the exported PDF.
  It is one keystroke away (Cmd + and Cmd −), so a graph can pick it up by
  accident. A graph at `expand=-2` draws its 1-pt lines at half a point.
- **Plot-area size.** A graph drawn in a 280-pt plot area and one drawn in
  a 144-pt plot area carry the same 1-pt lines, but placing both at the
  same width in a page layout or in Illustrator scales one of them, and
  its lines scale with it.

Every graph made by `MakePolarTuningGraph` is therefore built at a fixed
plot-area height (144 pt, `POLAR_HEIGHT`) with `expand=0`, so that two
polar panels placed side by side need no scaling and agree by
construction. To put an existing graph back:

```
PolarSetSize("polar_A1_MovingBar_c1")                 // the standard size
PolarSetSize("polar_A1_MovingBar_c1", height=108)     // a smaller panel, still square
PolarSetSize("polar_A1_MovingBar_c1", height=0)       // free plot area, expand still 0
MakePolarTuningGraph("polar_A1_MovingBar_c1", height=108)   // at build time
```

If a panel still looks wrong next to its neighbour, compare the two
recreation macros (Windows → Procedure Windows, or the graph's
`ModifyGraph` lines) for `expand` and `height` before looking at the trace
settings — those are the two that do not show up in Modify Trace
Appearance.

### Troubleshooting

*"expected wave name, variable name, or operation"* on compile — Igor 7+
(`rtGlobals=3`) needs explicit `WAVE` references inside functions; the
shipped file has them, so this means an older copy. *"File not found"* —
the experiment has not been saved (no home folder) or the name passed is
not the `.h5` base name. *"polar_curve_X/_Y not found"* — the file loaded
is an `example_*` or `psth_*` export rather than a `polar_*` one, or the
current data folder is wrong when calling `PolarTuningGraphFromFolder`.
*`HDF5OpenFile` failed* — the HDF5 XOP is not active (Igor 8: activate
`HDF5.xop`; Igor 9 and later have it built in); `MakeFig` needs the same
XOP, so if that works this will. *"Function … already defined"* — a second
copy of the procedure (an old `PolarTuning.ipf`, or `PolarPlots.ipf` both
aliased in Igor Procedures and `#include`d in the experiment) is loaded;
keep only the alias to this repo's `Igor/PolarPlots.ipf`.

---

## Recent changes (PolarPlots.ipf v1.3 → v1.43)

| Version | Change |
|---|---|
| 1.43 | `PolarSetSize`; every graph built at a fixed plot-area height (144 pt) with `expand=0`, so panels agree without scaling. |
| 1.3 | `MakePolarTuningGraph` loads the `.h5` itself (MakeFig convention, first HDF5 group); round-number outer ring (`PolarNiceCeil`); `showErr=0` scales from the means; `PolarSetScale` rebuilds rings, rescales the DSI vector (`PolarRememberDsi`) and relabels |
| 1.4 | `fill=` option, `PolarFill` / `PolarUnfill`: hull shading as a UserBack polygon in axis coordinates |
| 1.41 | fill placed correctly — `DrawPoly`'s origin is the first vertex, not (0, 0) |
| 1.42 | accepts `"name.h5"`; closes the HDF5 file when a load fails (no lingering lock) |

Full history across all procedure files: `docs/CHANGELOG.md`.

## Files

| File | Role |
|---|---|
| `Igor/PolarPlots.ipf` | `MakePolarTuningGraph`, `PolarTuningGraphFromFolder`, `PolarSetScale`, `PolarFill`, `PolarUnfill`, `PolarNiceCeil`, `PolarDataMax`, `PolarRememberDsi`, `MakePolarTuningGraphWM` |
| `Matlab/MatlabToIgorTools/polarWaves.m` | (angle, mean, SEM) → Cartesian `polar_*` waves, round-number outer ring |
| `Matlab/MatlabToIgorTools/makeAxisStruct.m` | exports the axis to the `.h5` Igor reads |

`Igor/PolarPlots.ipf` is the only copy of the procedure: it is linked into
the Igor user procedures folder rather than copied into projects, so edits
go here. The A1 manuscript keeps its own copy of the MATLAB function as
`motion.polarWaves` (`A1_paper/src/+motion/polarWaves.m`), which mirrors
the one here.
