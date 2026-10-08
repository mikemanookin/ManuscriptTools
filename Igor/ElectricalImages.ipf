#pragma rtGlobals=3
#pragma version=1.8
// ElectricalImages.ipf - electrical-image (EI) panels exported by A1_paper/notebooks/rf_figure.py
// (--stage ei) with figure_utils.axis_to_igor. Canonical copy: ManuscriptTools/Igor/ElectricalImages.ipf;
// documentation: ManuscriptTools/docs/PythonToIgor.md (Electrical images).
//
// EI_<label>.h5 holds, in one group:
//     array_X/_Y    every electrode of the array (microns)
//     elec_X/_Y     the electrodes above threshold, drawn as circles sized by the EI amplitude
//     ei_amp_Y      EI amplitude per electrode in elec (same order; ei_amp_X = elec_X, ignore it)
//     ei_size_Y     relative marker size 0..1 per electrode in elec (marker AREA ~ amplitude)
//     peak_X/_Y     the peak electrode
//     dend_X/_Y     the electrodes inside the dendritic window, with dsize_Y as their amplitudes 0..1
//     fit_X/_Y      the outline FITTED to those electrodes (compute_crosscorr.py; absent from rf_figure.py exports)
// EIwave_<label>.h5 holds wave0_e<n>_X/_Y (peak electrode) .. waveN_e<n> (its neighbours): load with MakeFig.
//
// A DENDRITIC MOSAIC (compute_crosscorr.py --ei-mosaics) is also an EI_<label>.h5, but holds one
// dendritic outline per cell instead of one cell's electrodes:
//     fit_source<k>_X/_Y, fit_target<k>_X/_Y     the fitted outlines, microns, with their *_color waves
//     elec_source<k>_X/_Y, elec_target<k>_X/_Y   the electrodes each outline was fitted to
//     esize_source<k>_Y, esize_target<k>_Y       their amplitudes in the window, 0..1, for zmrkSize
//     array_X/_Y                                  every electrode of the array
// `elec` / `esize` are the sized electrode markers and `fit` the fitted outline on BOTH kinds of
// panel - bare on a single cell, tagged _<role><k> per cell on a mosaic. On a mosaic elec_<tag> is
// measured inside the dendritic window; the single-cell panel's bare elec is the whole waveform and
// its window electrodes are the extra dend / dsize pair. (RF mosaics keep cell_<role><k>;
// RfMosaics.ipf v1.6 accepts either.)
// MakeEIGraph opens either: it tells them apart by whether the file has elec_X/_Y (one cell) or
// cell*_Y (a mosaic), and draws the right kind of panel. MakeEIMosaicGraph forces the mosaic one.
//
// USAGE - same convention as MakeFig: the .h5 sits next to the saved .pxp.
//     MakeEIGraph("EI_A1_298")                      // plot area 108 pt high (square), circles up to 6 pt
//     MakeEIGraph("EI_A1_298", height=144, maxSize=9)   // bigger panel, bigger circles
//     EISetMaxSize("EI_A1_298", 4)                  // rescale the circles on an open graph
//     EISetHeight("EI_A1_298", 72)                  // resize the plot area; markers re-fitted to the spacing
//     EISetHeight("EI_A1_298", 72, maxSize=3)       // ... with the marker size forced instead
//     EIFitMarkers("EI_A1_dendrites")               // re-fit the markers after any resize
//     EIFitMarkers("EI_A1_dendrites", fraction=0.6) // ... smaller, more space between circles
//     MakeEIGraph("EI_A1_dendrites")                // a dendritic mosaic: outlines over the array
//     MakeEIMosaicGraph("EI_A1_dendrites", showArray=0)      // ... without the whole-array dots
//     EIMosaicElectrodes("EI_A1_dendrites", 0)               // hide the per-cell elec_ electrodes
//     EIMosaicElectrodes("EI_A1_dendrites", 1, maxSize=5)    // show them again, bigger
//     MosaicFillByColor("EI_A1_dendrites", alpha=16384)      // shade each field in its own colour (RfMosaics.ipf)
// MakeFig("EI_A1_298") would also plot the ei_amp / ei_size data-carrier waves as traces; use MakeEIGraph.

Function MakeEIGraph(h5name, [maxSize, height])
	String h5name
	Variable maxSize, height
	if (ParamIsDefault(maxSize))
		maxSize = 6
	endif
	if (ParamIsDefault(height))
		height = 108
	endif
	if (StringMatch(h5name, "*.h5"))
		h5name = h5name[0, strlen(h5name)-4]
	endif
	if (EILoadH5(h5name))
		return 0
	endif
	EIGraphFromFolder(h5name, maxSize=maxSize, height=height)
	SetDataFolder root:
End

// Same as MakeEIGraph but always draws the dendritic-mosaic panel (outlines over the array).
Function MakeEIMosaicGraph(h5name, [height, lineSize, showArray, maxSize])
	String h5name
	Variable height, lineSize, showArray, maxSize
	if (ParamIsDefault(height))
		height = 108
	endif
	if (ParamIsDefault(lineSize))
		lineSize = 0.5
	endif
	if (ParamIsDefault(showArray))
		showArray = 1
	endif
	if (ParamIsDefault(maxSize))
		maxSize = 4
	endif
	if (EILoadH5(h5name))
		return 0
	endif
	EIMosaicFromFolder(h5name, height=height, lineSize=lineSize, showArray=showArray, maxSize=maxSize)
	SetDataFolder root:
End

// Load EI_<name>.h5 (next to the saved .pxp) into root:<name> and leave that folder current.
// Returns 0 on success; aborts with a readable message otherwise.
Function EILoadH5(h5name)
	String h5name
	if (StringMatch(h5name, "*.h5"))
		h5name = h5name[0, strlen(h5name)-4]
	endif
	PathInfo home
	if (V_flag == 0)
		Abort "Save the experiment first so Igor knows its home folder (the .h5 is looked for next to the .pxp)."
	endif
	String h5path = S_path + h5name + ".h5"
	GetFileFolderInfo/Q/Z h5path
	if (V_flag != 0 || !V_isFile)
		Abort "File not found: " + h5path
	endif
	Variable h5file
	HDF5OpenFile/R/Z h5file as h5path
	if (V_flag != 0)
		Abort "HDF5OpenFile failed on " + h5path
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
		SetDataFolder root:
		Abort "HDF5LoadGroup failed on group " + grp + " in " + h5path
	endif
	return 0
End

// Dendritic mosaic from the cell*_X/_Y waves in the CURRENT data folder, over the electrode array.
Function EIMosaicFromFolder(graphName, [height, lineSize, showArray, maxSize])
	String graphName
	Variable height, lineSize, showArray, maxSize
	if (ParamIsDefault(height))
		height = 108
	endif
	if (ParamIsDefault(lineSize))
		lineSize = 0.5
	endif
	if (ParamIsDefault(showArray))
		showArray = 1
	endif
	if (ParamIsDefault(maxSize))
		maxSize = 4
	endif
	String yList = WaveList("fit*_Y", ";", "") + WaveList("cell*_Y", ";", "")
	if (ItemsInList(yList) == 0)
		Abort "no fit*_Y or cell*_Y waves in " + GetDataFolder(1) + " - is this an EI mosaic export (--ei-mosaics)?"
	endif
	// RfMosaics.ipf already draws exactly this kind of panel (outlines, *_color waves, reversed y)
	if (strlen(FunctionInfo("MosaicGraphFromFolder")) > 0)
		String cmd
		sprintf cmd, "MosaicGraphFromFolder(\"%s\", height=%g, lineSize=%g)", graphName, height, lineSize
		Execute cmd
	else
		Abort "RfMosaics.ipf is not loaded - open it (it draws the outlines and applies their colours)."
	endif
	EIMosaicStyleElectrodes(graphName, maxSize)		// the electrodes each outline was fitted to
	if (showArray)
		WAVE/Z ax = array_X, ay = array_Y
		if (WaveExists(ax) && WaveExists(ay))
			AppendToGraph/W=$graphName ay vs ax
			ModifyGraph/W=$graphName mode(array_Y)=3, marker(array_Y)=19, msize(array_Y)=1
			ModifyGraph/W=$graphName rgb(array_Y)=(52428,52428,52428)
			ReorderTraces/W=$graphName _back_, {array_Y}		// the array behind everything else
		endif
	endif
End

// Style the elec_<tag>_Y traces that compute_crosscorr.py exports alongside each fit_<tag> outline:
// open circles sized by esize_<tag>_Y (the electrode's amplitude in the dendritic window, 0..1) in
// the same colour as the outline they belong to. Called by EIMosaicFromFolder; harmless if absent.
Function EIMosaicStyleElectrodes(graphName, maxSize)
	String graphName
	Variable maxSize
	if (maxSize <= 0)
		maxSize = 4
	endif
	String eList = WaveList("elec_*_Y", ";", "")
	Variable n = ItemsInList(eList), i
	for (i = 0; i < n; i += 1)
		String yName = StringFromList(i, eList)
		String tag = yName[5, strlen(yName)-3]				// elec_<tag>_Y -> <tag>
		WAVE/Z wy = $yName
		WAVE/Z wx = $("elec_" + tag + "_X")
		if (!WaveExists(wy) || !WaveExists(wx))
			continue
		endif
		AppendToGraph/W=$graphName wy vs wx
		ModifyGraph/W=$graphName mode($yName)=3, marker($yName)=8, mrkThick($yName)=0.4
		WAVE/Z sz = $("esize_" + tag + "_Y")
		if (WaveExists(sz))
			ModifyGraph/W=$graphName zmrkSize($yName)={sz, 0, 1, 0, maxSize}
		else
			ModifyGraph/W=$graphName msize($yName)=maxSize / 2
		endif
		WAVE/Z col = $("fit_" + tag + "_color")				// the outline's colour, if it was exported
		if (WaveExists(col) && numpnts(col) >= 3)
			ModifyGraph/W=$graphName rgb($yName)=(col[0]*65535, col[1]*65535, col[2]*65535)
		endif
		// _back_ rather than an anchor trace, and $yName rather than the wave reference: the brace
		// list is parsed as trace NAMES, so {wy} would look for a trace literally called "wy"
		ReorderTraces/W=$graphName _back_, {$yName}			// electrodes behind the outlines
	endfor
End

// The size wave that drives a trace's zmrkSize: dend_Y -> dsize_Y (the single-cell panel's window
// electrodes), elec_<tag>_Y -> esize_<tag>_Y (a mosaic's per-cell electrodes). Empty otherwise -
// the single-cell elec_Y is handled by EISetMaxSize, which knows about ei_size_Y.
Function/S EIDsizeNameFor(traceName)
	String traceName
	if (StringMatch(traceName, "dend_Y"))				// single-cell panel: the window electrodes
		return "dsize_Y"
	endif
	if (StringMatch(traceName, "elec_*_Y"))			// mosaic: one set per cell
		return "esize_" + traceName[5, strlen(traceName)-3] + "_Y"
	endif
	return ""
End

// Show (show=1) or hide (show=0) the dendritic-window electrodes on an open EI graph - the per-cell
// elec_<tag>_Y traces of a mosaic or the single dend_Y of one cell. show < 0 leaves visibility
// alone and only re-applies the marker sizes. Returns how many traces it touched.
Function EIMosaicElectrodes(graphName, show, [maxSize])
	String graphName
	Variable show, maxSize
	if (ParamIsDefault(maxSize))
		maxSize = 4
	endif
	String eList = TraceNameList(graphName, ";", 1), yName, szName
	Variable n = ItemsInList(eList), i, styled = 0
	for (i = 0; i < n; i += 1)
		yName = StringFromList(i, eList)
		szName = EIDsizeNameFor(yName)
		if (strlen(szName) == 0)
			continue
		endif
		if (show >= 0)
			ModifyGraph/W=$graphName hideTrace($yName)=(show == 0)
		endif
		styled += 1
		if (show == 0)
			continue
		endif
		WAVE/Z w = TraceNameToWaveRef(graphName, yName)
		if (!WaveExists(w))
			continue
		endif
		WAVE/Z sz = $(GetWavesDataFolder(w, 1) + szName)
		if (WaveExists(sz))
			ModifyGraph/W=$graphName zmrkSize($yName)={sz, 0, 1, 0, maxSize}
		else
			ModifyGraph/W=$graphName msize($yName)=maxSize / 2
		endif
	endfor
	return styled
End

// Draw the EI graph from the EI_* waves in the CURRENT data folder.
Function EIGraphFromFolder(graphName, [maxSize, height])
	String graphName
	Variable maxSize, height
	if (ParamIsDefault(maxSize))
		maxSize = 6
	endif
	if (ParamIsDefault(height))
		height = 108
	endif
	WAVE/Z ax = array_X, ay = array_Y
	WAVE/Z ex = elec_X, ey = elec_Y
	WAVE/Z sz = ei_size_Y
	WAVE/Z px = peak_X, py = peak_Y
	if (!WaveExists(ex) || !WaveExists(ey))
		// a dendritic mosaic (--ei-mosaics) is also an EI_*.h5, but holds outlines, not electrodes
		if (ItemsInList(WaveList("cell*_Y", ";", "")) + ItemsInList(WaveList("fit*_Y", ";", "")) > 0)
			Print "MakeEIGraph: " + graphName + " is a dendritic mosaic; drawing the outlines (MakeEIMosaicGraph)."
			EIMosaicFromFolder(graphName, height=height)
			return 0
		endif
		Abort "elec_X/_Y not found in " + GetDataFolder(1) + " - is this an EI_*.h5 export?"
	endif

	DoWindow/K $graphName
	Display/N=$graphName/W=(50,50,420,420) ey vs ex
	ModifyGraph mode(elec_Y)=3, marker(elec_Y)=8, rgb(elec_Y)=(0,0,0), mrkThick(elec_Y)=0.5
	if (WaveExists(sz))
		ModifyGraph zmrkSize(elec_Y)={sz, 0, 1, 0, maxSize}		// marker size (pt) from ei_size 0..1
	else
		ModifyGraph msize(elec_Y)=maxSize / 2
	endif
	if (WaveExists(ay))
		AppendToGraph ay vs ax
		ModifyGraph mode(array_Y)=3, marker(array_Y)=19, msize(array_Y)=1, rgb(array_Y)=(48059,48059,48059)
		ReorderTraces elec_Y, {array_Y}					// the array behind the circles
	endif
	if (WaveExists(py))
		AppendToGraph py vs px
		ModifyGraph mode(peak_Y)=3, marker(peak_Y)=19, msize(peak_Y)=3, rgb(peak_Y)=(65535,0,0)
	endif
	WAVE/Z ddx = dend_X, ddy = dend_Y			// the electrodes the dendritic fit used ...
	WAVE/Z dsz = dsize_Y						// ... and their amplitudes INSIDE the window
	if (WaveExists(ddx) && WaveExists(ddy))
		AppendToGraph ddy vs ddx
		ModifyGraph mode(dend_Y)=3, marker(dend_Y)=8, mrkThick(dend_Y)=0.5, rgb(dend_Y)=(35980,16448,17733)
		if (WaveExists(dsz))
			ModifyGraph zmrkSize(dend_Y)={dsz, 0, 1, 0, maxSize}
		endif
	endif
	WAVE/Z dx = fit_X, dy = fit_Y				// the outline fitted to them (compute_crosscorr.py)
	if (WaveExists(dx) && WaveExists(dy))
		AppendToGraph dy vs dx
		ModifyGraph lsize(fit_Y)=1, rgb(fit_Y)=(35980,16448,17733)
	endif
	ModifyGraph width={Plan,1,bottom,left}		// microns are microns in both directions ...
	ModifyGraph height=height					// ... so the plot height (points) fixes the width too
	ModifyGraph noLabel=2, axThick=0, tick=3		// hide the axes; add a scale bar with MakeScaleBars if wanted
	ModifyGraph margin=2
End

// Resize the plot area of an existing EI graph (points); the width follows the Plan aspect.
// Marker sizes are in POINTS and do not follow the plot, so shrinking a panel makes the electrode
// circles overlap into blobs. By default the largest marker is therefore re-fitted to the electrode
// spacing at the new size (EIFitMarkers); pass maxSize to force a value, or maxSize=0 to leave the
// markers alone.
Function EISetHeight(graphName, height, [maxSize])
	String graphName
	Variable height, maxSize
	if (WinType(graphName) != 1)
		Printf "EISetHeight: no graph named %s\r", graphName
		return 0
	endif
	ModifyGraph/W=$graphName width={Plan,1,bottom,left}, height=height
	DoUpdate/W=$graphName							// the plot area is only the new size after this
	if (ParamIsDefault(maxSize))
		return EIFitMarkers(graphName)
	endif
	if (maxSize > 0)
		return EISetMaxSize(graphName, maxSize)
	endif
	return 0
End

// The electrode spacing of an EI graph, in microns: the smallest gap between distinct x positions
// of its array_X (or, failing that, the first elec_* x wave). 0 when it cannot be worked out.
Function EIElectrodePitch(graphName)
	String graphName
	WAVE/Z wx = XWaveRefFromTrace(graphName, "array_Y")
	if (!WaveExists(wx))
		String traces = TraceNameList(graphName, ";", 1), tr
		Variable k, nt = ItemsInList(traces)
		for (k = 0; k < nt; k += 1)
			tr = StringFromList(k, traces)
			if (StringMatch(tr, "elec*_Y") || StringMatch(tr, "dend*_Y"))
				WAVE/Z wx = XWaveRefFromTrace(graphName, tr)
				break
			endif
		endfor
	endif
	if (!WaveExists(wx) || numpnts(wx) < 2)
		return 0
	endif
	Duplicate/FREE/O wx, xs
	Sort xs, xs
	Variable i, d, best = Inf
	for (i = 1; i < numpnts(xs); i += 1)
		d = xs[i] - xs[i-1]
		if (d > 1e-6 && d < best)
			best = d
		endif
	endfor
	return numtype(best) == 0 ? best : 0
End

// Size the largest electrode marker to `fraction` of the electrode spacing AS DRAWN, so the circles
// stay separated whatever the panel size. Returns the size in points it applied (0 if it could not).
Function EIFitMarkers(graphName, [fraction])
	String graphName
	Variable fraction
	if (ParamIsDefault(fraction))
		fraction = 0.9
	endif
	if (WinType(graphName) != 1)
		Printf "EIFitMarkers: no graph named %s\r", graphName
		return 0
	endif
	Variable pitch = EIElectrodePitch(graphName)
	if (pitch <= 0)
		return 0									// no electrode waves: leave the markers alone
	endif
	GetWindow $graphName psizeDC					// the plot area in points
	Variable hPt = V_bottom - V_top
	GetAxis/W=$graphName/Q left
	Variable ySpan = abs(V_max - V_min)
	if (hPt <= 0 || ySpan <= 0)
		return 0
	endif
	Variable maxSize = fraction * pitch * hPt / ySpan	// microns -> points at the current scale
	EISetMaxSize(graphName, maxSize)
	return maxSize
End

// Change the size of the largest circle on an existing EI graph. Works on either kind of panel:
// the elec_Y circles of a single cell, the elec_<tag>_Y electrodes of a mosaic, or both. A graph
// with neither is reported and left alone rather than aborting - it is safe to call from a format
// routine that runs over every EI graph.
Function EISetMaxSize(graphName, maxSize)
	String graphName
	Variable maxSize
	if (maxSize <= 0)
		maxSize = 4
	endif
	if (WinType(graphName) != 1)
		Printf "EISetMaxSize: no graph named %s\r", graphName
		return 0
	endif
	Variable styled = 0
	WAVE/Z w = TraceNameToWaveRef(graphName, "elec_Y")		// the single-cell panel's sized circles
	if (WaveExists(w))
		WAVE/Z sizes = $(GetWavesDataFolder(w, 1) + "ei_size_Y")
		if (WaveExists(sizes))
			ModifyGraph/W=$graphName zmrkSize(elec_Y)={sizes, 0, 1, 0, maxSize}
		else
			ModifyGraph/W=$graphName msize(elec_Y)=maxSize / 2
		endif
		styled += 1
	endif
	styled += EIMosaicElectrodes(graphName, -1, maxSize=maxSize)	// dend_Y / elec_<tag>_Y, visibility untouched
	if (styled == 0)
		Printf "EISetMaxSize: %s has no elec_* or dend_* traces to size\r", graphName
	endif
	return styled
End
