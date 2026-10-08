#pragma rtGlobals=3
#pragma version=1.43
// PolarPlots.ipf - polar tuning plots with radial error bars, drawn as ordinary XY graphs.
// Canonical copy: ManuscriptTools/Igor/PolarPlots.ipf; documentation: ManuscriptTools/docs/IgorPolarPlots.md.
//
// MATLAB (polarWaves.m + makeAxisStruct) exports an HDF5 file, e.g. polar_<cell>_<protocol>.h5,
// whose waves are already Cartesian:
//     polar_curve_X/_Y  mean tuning curve, closed ring
//     polar_err_X/_Y    radial SEM bars, NaN-separated segments
//     polar_pts_X/_Y    the mean points (markers)
//     polar_grid_X/_Y   reference rings (50 %, 100 % of the outer radius) + axis cross
//     polar_vec_X/_Y    preferred-direction vector, length = DSI x outer radius
//
// USAGE - same convention as MakeFig() in ManookinLabIgorProcedures.ipf: the .h5 file
// sits in the experiment's home folder (next to the .pxp) and is named by its base name.
// Optional arguments and the scale controls are described in docs/IgorPolarPlots.md.
//
//     MakePolarTuningGraph("polar_A1_GratingDSOS_c1")
//     MakePolarTuningGraph("polar_A1_GratingDSOS_c1", rmax=25)                    // outer ring at 25 sp/s
//     MakePolarTuningGraph("polar_A1_GratingDSOS_c1", rmax=30, rings="0.5;1;")    // rings at 15 and 30
//     MakePolarTuningGraph("polar_A1_GratingDSOS_c1", showErr=0)                   // no SEM bars; scale from the means
//     PolarSetScale("polar_A1_GratingDSOS_c1", 40, "0.25;0.5;0.75;1;")             // rescale an existing graph
//     MakePolarTuningGraph("polar_A1_GratingDSOS_c1", fill=0.2)                    // shade the tuning hull, 20 % black
//     PolarFill("polar_A1_GratingDSOS_c1", red=0, green=0, blue=65535, alpha=0.15) // (re)shade an existing graph
//     PolarUnfill("polar_A1_GratingDSOS_c1")                                       // remove the shading
//     PolarSetSize("polar_A1_MovingBar_c1")                                       // same physical size as every other polar graph
//     PolarSetSize("polar_A1_MovingBar_c1", height=108)                           // ... at a different size
//
// Size: every polar graph is built with the SAME plot-area height (POLAR_HEIGHT, 144 pt) and
// with the graph expansion set to 0, so that two polar graphs placed side by side in a figure
// carry the same line thickness and marker size. Those are set in POINTS and do not follow the
// data, so a graph drawn in a larger plot area, or at a different expansion, has to be scaled in
// the page layout and its lines then come out thinner or thicker than its neighbour's even
// though msize and lsize are identical. ModifyGraph expand is the worse trap of the two: it
// scales fonts, line widths and markers as well as the plot area, it is one keystroke away
// (Cmd +/-), and it carries into the exported PDF. PolarSetSize puts an existing graph back.
// Scale: with rmax omitted the outer ring is the largest mean (+ SEM when showErr=1)
// rounded UP to a round number (1, 1.5, 2, 2.5, 3, 4, 5, 6, 8 x 10^k). The grid waves are
// rebuilt in Igor, and the DSI vector (length = DSI x rmax) is rescaled with the grid, so
// the exported polar_grid_* waves are only a starting point.
//
// This LOADS the file (Igor never reads .h5 files just because they are next to the
// .pxp) into the data folder root:<name>, then draws the graph <name>. The file's one
// HDF5 group is loaded whatever it is called, so a renamed .h5 file works too.
// To redraw from waves that are already loaded, use PolarTuningGraphFromFolder(name)
// with the current data folder set to the one holding the polar_* waves.
//
// The graph is an ordinary XY graph with a square (Plan) aspect and hidden axes, so every
// standard Igor tool (Modify Trace Appearance, layouts, PDF export) works.
//
// Shading: fill=<opacity 0..1> shades the area enclosed by the mean tuning curve (the hull)
// with a polygon drawing object in the UserBack layer, in axis coordinates, so it sits
// behind the traces and follows PolarSetScale. PolarFill / PolarUnfill manage it afterwards.

// Plot-area height, in points, shared by every polar graph (see PolarSetSize).
Static Constant POLAR_HEIGHT = 144

Function MakePolarTuningGraph(h5name, [rmax, rings, showErr, fill, height])
	String h5name
	Variable rmax
	String rings
	Variable showErr, fill, height
	if (ParamIsDefault(height))
		height = POLAR_HEIGHT
	endif
	if (ParamIsDefault(rmax))
		rmax = NaN
	endif
	if (ParamIsDefault(rings))
		rings = "0.5;1;"
	endif
	if (ParamIsDefault(showErr))
		showErr = 1
	endif
	if (ParamIsDefault(fill))
		fill = 0
	endif

	// accept "name.h5" as well as "name"
	if (strlen(h5name) > 3 && StringMatch(h5name[strlen(h5name)-3, strlen(h5name)-1], ".h5"))
		h5name = h5name[0, strlen(h5name)-4]
	endif

	// locate the file next to the experiment
	PathInfo home
	if (V_flag == 0)
		Abort "Save the experiment first so Igor knows its home folder (the .h5 is looked for next to the .pxp)."
	endif
	String h5path = S_path + h5name + ".h5"
	GetFileFolderInfo/Q/Z h5path
	if (V_flag != 0 || !V_isFile)
		Abort "File not found: " + h5path
	endif

	// load its (single) group into root:<h5name>
	Variable h5file
	HDF5OpenFile/R/Z h5file as h5path
	if (V_flag != 0)
		Abort "HDF5OpenFile failed on " + h5path + " (is the HDF5 XOP loaded? Igor 8: activate HDF5.xop; Igor 9+: built in)"
	endif
	HDF5ListGroup/TYPE=1 h5file, "/"
	String groups = S_HDF5ListGroup
	if (ItemsInList(groups) == 0)
		HDF5CloseFile h5file
		Abort "No group in " + h5path
	endif
	String grp = StringFromList(0, groups)
	if (WinType(h5name) == 1)
		KillWindow $h5name
	endif
	KillDataFolder/Z root:$h5name
	NewDataFolder/O/S root:$h5name
	HDF5LoadGroup/O/Z :, h5file, grp
	HDF5CloseFile h5file				// always close, or the file stays locked for other programs
	if (V_flag != 0)
		Abort "HDF5LoadGroup failed on group " + grp + " in " + h5path
	endif

	PolarTuningGraphFromFolder(h5name, rmax=rmax, rings=rings, showErr=showErr, fill=fill, height=height)
	SetDataFolder root:
End

// Build the polar graph from polar_* waves in the CURRENT data folder.
Function PolarTuningGraphFromFolder(graphName, [rmax, rings, showErr, fill, height])
	String graphName
	Variable rmax
	String rings
	Variable showErr, fill, height
	if (ParamIsDefault(height))
		height = POLAR_HEIGHT
	endif
	if (ParamIsDefault(rmax))
		rmax = NaN
	endif
	if (ParamIsDefault(rings))
		rings = "0.5;1;"
	endif
	if (ParamIsDefault(showErr))
		showErr = 1
	endif
	if (ParamIsDefault(fill))
		fill = 0
	endif

	WAVE/Z gridX = polar_grid_X, gridY = polar_grid_Y
	WAVE/Z errX = polar_err_X, errY = polar_err_Y
	WAVE/Z curveX = polar_curve_X, curveY = polar_curve_Y
	WAVE/Z ptsX = polar_pts_X, ptsY = polar_pts_Y
	WAVE/Z vecX = polar_vec_X, vecY = polar_vec_Y
	if (!WaveExists(curveY) || !WaveExists(curveX))
		Abort "polar_curve_X/_Y not found in " + GetDataFolder(1) + " - is this a polar_*.h5 export (not example_* or psth_*)?"
	endif

	DoWindow/K $graphName
	Display/N=$graphName/W=(50,50,350,350) curveY vs curveX
	ModifyGraph rgb(polar_curve_Y)=(0,0,0)
	if (WaveExists(gridY))
		AppendToGraph gridY vs gridX
		ModifyGraph rgb(polar_grid_Y)=(48059,48059,48059), lstyle(polar_grid_Y)=2
		ReorderTraces polar_curve_Y, {polar_grid_Y}		// grid behind everything
	endif
	if (showErr && WaveExists(errY))
		AppendToGraph errY vs errX
		ModifyGraph rgb(polar_err_Y)=(0,0,0)
	endif
	if (WaveExists(ptsY))
		AppendToGraph ptsY vs ptsX
		ModifyGraph mode(polar_pts_Y)=3, marker(polar_pts_Y)=19, msize(polar_pts_Y)=2, rgb(polar_pts_Y)=(0,0,0)
	endif
	if (WaveExists(vecY))
		AppendToGraph vecY vs vecX
		ModifyGraph rgb(polar_vec_Y)=(65535,0,0), lsize(polar_vec_Y)=1.5
	endif

	ModifyGraph width={Plan,1,bottom,left}		// square: 1 unit in x = 1 unit in y
	ModifyGraph noLabel=2, axThick=0, tick=3		// hide the Cartesian axes
	ModifyGraph margin=10
	PolarSetSize(graphName, height=height)		// one physical size for every polar graph

	// scale: explicit rmax, else a round number above the data (means, + SEM when shown)
	PolarRememberDsi()
	if (numtype(rmax) != 0 || rmax <= 0)
		rmax = PolarNiceCeil(PolarDataMax(showErr))
	endif
	PolarSetScale(graphName, rmax, rings)
	if (fill > 0)
		PolarFill(graphName, alpha=fill)
	endif
End

// Shade the hull enclosed by the mean tuning curve: a filled polygon drawing object with
// the vertices of polar_curve_X/_Y, drawn in the UserBack layer in axis coordinates, so it
// lies behind the grid, error bars and traces and follows any later PolarSetScale.
// Colour components are 0..65535 (default black); alpha is the opacity, 0..1 (default 0.2).
// The polygon is a copy of the curve at the time of the call: rerun after changing the
// curve waves. A previous fill on the graph is replaced.
Function PolarFill(graphName, [red, green, blue, alpha])
	String graphName
	Variable red, green, blue, alpha
	if (ParamIsDefault(red))
		red = 0
	endif
	if (ParamIsDefault(green))
		green = 0
	endif
	if (ParamIsDefault(blue))
		blue = 0
	endif
	if (ParamIsDefault(alpha))
		alpha = 0.2
	endif
	alpha = min(max(alpha, 0), 1)

	WAVE/Z cy = TraceNameToWaveRef(graphName, "polar_curve_Y")
	WAVE/Z cx = XWaveRefFromTrace(graphName, "polar_curve_Y")
	if (!WaveExists(cy) || !WaveExists(cx))
		Abort "no polar_curve_Y trace in " + graphName
	endif
	PolarUnfill(graphName)
	SetDrawLayer/W=$graphName UserBack
	SetDrawEnv/W=$graphName gname=polarFill, gstart
	SetDrawEnv/W=$graphName xcoord=bottom, ycoord=left, linethick=0, fillpat=1, fillfgc=(red,green,blue,round(alpha * 65535))
	// DrawPoly places the FIRST vertex at (xOrg, yOrg) and the rest relative to it, so the
	// origin must be the curve's first point (0,0 would shift the hull by that point).
	DrawPoly/W=$graphName cx[0], cy[0], 1, 1, cx, cy
	SetDrawEnv/W=$graphName gstop
	SetDrawLayer/W=$graphName UserFront
End

// Remove the shading added by PolarFill (no-op when there is none).
Function PolarUnfill(graphName)
	String graphName
	DrawAction/W=$graphName/L=UserBack getgroup=polarFill, delete
End

// Store DSI and preferred direction in polar_vec_X's note: the exported vector has length
// DSI x (exported outer radius), and the exported outer radius is the largest grid radius.
// Must run before PolarSetScale replaces polar_grid_*; a second call is a no-op.
Function PolarRememberDsi()
	Variable rmax0, len
	WAVE/Z vx = polar_vec_X, vy = polar_vec_Y
	WAVE/Z gx = polar_grid_X, gy = polar_grid_Y
	if (!WaveExists(vx) || numpnts(vx) < 2)
		return 0
	endif
	if (numtype(NumberByKey("DSI", note(vx), "=", ";")) == 0)
		return 0								// already stored
	endif
	if (!WaveExists(gx))
		return 0
	endif
	Duplicate/FREE gx, rg
	rg = sqrt(gx^2 + gy^2)
	WaveStats/Q/M=1 rg
	rmax0 = V_max
	len = sqrt(vx[1]^2 + vy[1]^2)
	if (rmax0 > 0)
		Note/K vx, "DSI=" + num2str(len / rmax0) + ";ANGLE=" + num2str(atan2(vy[1], vx[1])) + ";RMAX0=" + num2str(rmax0) + ";"
	endif
	return 1
End

// Largest radius in the current folder's polar data: the means, plus the SEM bars if shown.
Function PolarDataMax(showErr)
	Variable showErr
	Variable m = 0
	WAVE/Z curveX = polar_curve_X, curveY = polar_curve_Y
	WAVE/Z errX = polar_err_X, errY = polar_err_Y
	if (WaveExists(curveX))
		Duplicate/FREE curveX, rr
		rr = sqrt(curveX^2 + curveY^2)
		m = WaveMax(rr)
	endif
	if (showErr && WaveExists(errX))
		Duplicate/FREE errX, re
		re = sqrt(errX^2 + errY^2)
		WaveStats/Q/M=1 re				// ignores the NaN separators
		m = max(m, V_max)
	endif
	return m
End

// Smallest of {1,1.5,2,2.5,3,4,5,6,8,10} x 10^k that is >= x (24.8 -> 25, 36.6 -> 40, 12 -> 15).
Function PolarNiceCeil(x)
	Variable x
	Variable e, i
	if (!(x > 0))
		return 1
	endif
	e = 10^floor(log(x))
	Make/FREE steps = {1, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10}
	for (i = 0; i < numpnts(steps); i += 1)
		if (steps[i] * e >= x * (1 - 1e-9))
			return steps[i] * e
		endif
	endfor
	return 10 * e
End

// Rebuild the reference rings at rings x rmax (semicolon list of fractions) in the graph's
// data folder, rescale the DSI vector to the new rmax, and relabel the outer ring. Works on
// a graph made by PolarTuningGraphFromFolder / MakePolarTuningGraph.
// Give a polar graph the standard physical size: a fixed plot-area height (the width follows
// from the square Plan aspect) and no graph expansion.
//
// This is what keeps line thickness and marker size consistent ACROSS polar graphs. Both are
// specified in points, so they are unaffected by rmax or by the data -- but they are affected by
// how large the plot area is, because a graph that has to be scaled in the page layout carries
// its line widths along with it, and by ModifyGraph expand, which scales everything the graph
// draws. Two graphs built by this file but given different sizes afterwards will therefore look
// different in the figure while every setting in Modify Trace Appearance reads the same.
//
//     PolarSetSize("polar_A1_MovingBar_c1")              // back to the standard size
//     PolarSetSize("polar_A1_MovingBar_c1", height=108)  // a smaller panel, still square
//     PolarSetSize("polar_A1_MovingBar_c1", height=0)    // leave the plot area free, only fix expand
Function PolarSetSize(graphName, [height, expandValue])
	String graphName
	Variable height, expandValue
	if (ParamIsDefault(height))
		height = POLAR_HEIGHT
	endif
	if (ParamIsDefault(expandValue))
		expandValue = 0
	endif
	if (WinType(graphName) != 1)
		Printf "PolarSetSize: no graph named %s\r", graphName
		return 0
	endif
	ModifyGraph/W=$graphName expand=expandValue
	if (height > 0)
		ModifyGraph/W=$graphName width={Plan,1,bottom,left}, height=height
	else
		ModifyGraph/W=$graphName width={Plan,1,bottom,left}, height=0
	endif
	return 0
End

Function PolarSetScale(graphName, rmax, rings)
	String graphName, rings
	Variable rmax
	Variable nRings, nPhi = 181, i, k, p = 0, f, dsi, ang
	String saveDF = GetDataFolder(1)
	// the graph's waves live in one folder: find it from the curve trace
	WAVE/Z curveY = TraceNameToWaveRef(graphName, "polar_curve_Y")
	if (!WaveExists(curveY))
		Abort "no polar_curve_Y trace in " + graphName
	endif
	SetDataFolder GetWavesDataFolder(curveY, 1)

	// rings + axis cross, NaN-separated
	nRings = ItemsInList(rings)
	Make/O/N=((nPhi + 1) * nRings + 6) polar_grid_X, polar_grid_Y
	WAVE gx = polar_grid_X, gy = polar_grid_Y
	for (i = 0; i < nRings; i += 1)
		f = str2num(StringFromList(i, rings))
		for (k = 0; k < nPhi; k += 1)
			gx[p] = f * rmax * cos(2 * pi * k / (nPhi - 1)); gy[p] = f * rmax * sin(2 * pi * k / (nPhi - 1)); p += 1
		endfor
		gx[p] = NaN; gy[p] = NaN; p += 1
	endfor
	gx[p] = -rmax; gy[p] = 0; p += 1
	gx[p] = rmax; gy[p] = 0; p += 1
	gx[p] = NaN; gy[p] = NaN; p += 1
	gx[p] = 0; gy[p] = -rmax; p += 1
	gx[p] = 0; gy[p] = rmax; p += 1
	Redimension/N=(p) gx, gy

	// DSI vector: its length is DSI x rmax, so rescale it with the grid. The DSI itself is
	// stored in the wave note by PolarRememberDsi (called once, before the exported grid is
	// replaced); without it the vector is left as exported.
	WAVE/Z vx = polar_vec_X, vy = polar_vec_Y
	if (WaveExists(vx) && numpnts(vx) == 2)
		dsi = NumberByKey("DSI", note(vx), "=", ";")
		ang = NumberByKey("ANGLE", note(vx), "=", ";")		// radians
		if (numtype(dsi) == 0 && numtype(ang) == 0)
			vx[1] = dsi * rmax * cos(ang)
			vy[1] = dsi * rmax * sin(ang)
		endif
	endif

	// grid trace must exist on the graph (added on first call)
	if (WhichListItem("polar_grid_Y", TraceNameList(graphName, ";", 1)) < 0)
		AppendToGraph/W=$graphName gy vs gx
		ModifyGraph/W=$graphName rgb(polar_grid_Y)=(48059,48059,48059), lstyle(polar_grid_Y)=2
		ReorderTraces/W=$graphName polar_curve_Y, {polar_grid_Y}
	endif
	SetAxis/W=$graphName left -rmax * 1.05, rmax * 1.05
	SetAxis/W=$graphName bottom -rmax * 1.05, rmax * 1.05
	TextBox/W=$graphName/C/N=rmaxLabel/F=0/A=RT/X=2/Y=2 num2str(rmax) + " sp/s"
	SetDataFolder saveDF
End

// Polar Graphs package alternative: mean +/- SEM as three radial traces on true polar
// axes, from the companion example_<type>_<protocol>_c<k>.h5 export (tuning_M_X/_Y and
// tuning_E_Y), loaded with MakeFig() or equivalent so the waves are in the current data
// folder. Requires "#include <New Polar Graphs>"; the package has no radial error bars,
// so the +/- SEM curves are appended as traces.
Function MakePolarTuningGraphWM(graphName)
	String graphName

	WAVE/Z angleDeg = tuning_M_X, meanY = tuning_M_Y, semY = tuning_E_Y
	if (!WaveExists(meanY) || !WaveExists(angleDeg))
		Abort "tuning_M_X/_Y not found in the current data folder"
	endif
	Duplicate/O meanY, tuning_hi_Y, tuning_lo_Y
	WAVE hiY = tuning_hi_Y, loY = tuning_lo_Y
	if (WaveExists(semY))
		hiY = meanY + semY
		loY = max(meanY - semY, 0)
	endif
	Execute "WMNewPolarGraph(\"\", \"" + graphName + "\")"
	Execute "WMPolarAppendTrace(\"" + graphName + "\", tuning_M_Y, tuning_M_X, 360)"
	Execute "WMPolarAppendTrace(\"" + graphName + "\", tuning_hi_Y, tuning_M_X, 360)"
	Execute "WMPolarAppendTrace(\"" + graphName + "\", tuning_lo_Y, tuning_M_X, 360)"
End
