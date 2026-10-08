#pragma rtGlobals=3
#pragma version=1.6
// RfMosaics.ipf - receptive-field mosaic panels exported by A1_paper/notebooks/rf_figure.py
// (--stage mosaics) with figure_utils.axis_to_igor. Canonical copy: ManuscriptTools/Igor/RfMosaics.ipf;
// documentation: ManuscriptTools/docs/RfMosaics.md.
//
// PopulationRF_<label>.h5 holds one closed outline per cell, cell0_X/_Y .. cellN_X/_Y, in microns
// on the stimulus/STA coordinate system (y increases downward, as in the STA image).
//
// USAGE - same convention as MakeFig: the .h5 sits next to the saved .pxp.
//     MakeMosaicGraph("PopulationRF_A1")                 // 108-pt square plot area, thin black outlines, y reversed
//     MakeMosaicGraph("PopulationRF_A1", height=144)
//     FormatRfContour("PopulationRF_A1", alpha=16384)    // optional translucent fill (RfContourFill.ipf);
//                                                        // it sets width/height=72 - rerun MosaicSetHeight after it
//     MosaicSetHeight("PopulationRF_A1", 108)
//     MosaicRefresh("PopulationRF_A1")                   // after a re-export: reload + MosaicClean, formatting kept
//     MosaicRefresh("PopulationRF_A1", refill=1, alpha=16384)   // ... and redo the FormatRfContour fill
//     MosaicClean("PopulationRF_A1")                     // after a plain RefreshAllData: drop stale cells, style new ones, remove old fills
//     MosaicSetExtent("PopulationRF_A1", 1500)           // both axes span 1500 um, centred on the data -> same um/pt on every
//     MosaicSetExtent("PopulationRF_RB", 1500)           //   panel of the same height; outlines comparable between panels
//     MosaicSetExtent("PopulationRF_A1", 1500, xCenter=800, yCenter=600)   // centre it where you like
//     MosaicSetExtent("PopulationRF_A1", 2000, ySpanUm=1000)   // 2:1 array: 2000 um wide, 1000 um high, same um/pt
//     MosaicFitExtent("PopulationRF_A1", padUm=50)             // spans = data extent + 50 um each side (panel takes the array's aspect)
//     MosaicFillByColor("CcgMosaic_A1_A1_gap", alpha=16384)   // fill every outline with ITS OWN colour (the *_color
//                                                              //   waves); repeatable - each call REPLACES the last fill
//                                                              //   waves of the export, e.g. source vs target cells)
// MakeFig("PopulationRF_A1") also works (it is a plain line export); MakeMosaicGraph only adds the
// square aspect, the reversed y axis, uniform styling and the hidden axes.
// Exports that carry a <trace>_color wave (numeric RGB 0..1, as figure_utils writes for lines drawn
// with a colour - compute_crosscorr.py's CcgMosaic_* files: cell_source*, cell_target*) keep that
// colour: MakeMosaicGraph applies it, MosaicClean preserves it, MosaicFillByColor fills with it.

// An outline trace of a mosaic. RF mosaics name them cell_<role><k> (rf_figure.py); the EI
// dendritic mosaics name them fit_<role><k> (compute_crosscorr.py --ei-mosaics), because there the
// fit sits alongside the dend_/dsize_ electrodes it was fitted to. Every function here accepts
// both, so one set of mosaic tools serves both kinds of panel.
Function MosaicIsCellTrace(tr)
	String tr
	return StringMatch(tr, "cell*_Y") || StringMatch(tr, "fit*_Y")
End

// The outline waves of the current data folder, cell*_Y then fit*_Y.
Function/S MosaicCellTraces()
	String a = WaveList("cell*_Y", ";", ""), b = WaveList("fit*_Y", ";", "")
	if (strlen(b) == 0)
		return a
	endif
	if (strlen(a) == 0)
		return b
	endif
	return a + b
End

Function MakeMosaicGraph(h5name, [height, lineSize])
	String h5name
	Variable height, lineSize
	if (ParamIsDefault(height))
		height = 108
	endif
	if (ParamIsDefault(lineSize))
		lineSize = 0.5
	endif
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

	MosaicGraphFromFolder(h5name, height=height, lineSize=lineSize)
	SetDataFolder root:
End

// Draw the mosaic from the cell*_X/_Y waves in the CURRENT data folder.
Function MosaicGraphFromFolder(graphName, [height, lineSize])
	String graphName
	Variable height, lineSize
	if (ParamIsDefault(height))
		height = 108
	endif
	if (ParamIsDefault(lineSize))
		lineSize = 0.5
	endif
	String yList = MosaicCellTraces()
	Variable n = ItemsInList(yList), i
	if (n == 0)
		Abort "no cell*_Y or fit*_Y waves in " + GetDataFolder(1) + " - is this a mosaic export?"
	endif
	DoWindow/K $graphName
	Display/N=$graphName/W=(50,50,420,420)
	for (i = 0; i < n; i += 1)
		String yName = StringFromList(i, yList)
		String xName = yName[0, strlen(yName)-3] + "_X"
		WAVE/Z wy = $yName
		WAVE/Z wx = $xName
		if (WaveExists(wx))
			AppendToGraph/W=$graphName wy vs wx
		else
			AppendToGraph/W=$graphName wy
		endif
	endfor
	ModifyGraph/W=$graphName rgb=(0,0,0), lsize=lineSize
	MosaicApplyColors(graphName)							// exported *_color waves win over black
	ModifyGraph/W=$graphName width={Plan,1,bottom,left}	// microns equal in both directions ...
	ModifyGraph/W=$graphName height=height				// ... so the height fixes the width
	SetAxis/W=$graphName/A/R left							// y increases downward, as in the STA image
	ModifyGraph/W=$graphName noLabel=2, axThick=0, tick=3	// hide the axes; add a scale bar with MakeScaleBars
	ModifyGraph/W=$graphName margin=2
End

// Resize the plot area (points); the width follows the Plan aspect. Use after FormatRfContour,
// which sets a fixed 72 x 72 pt size.
Function MosaicSetHeight(graphName, height)
	String graphName
	Variable height
	ModifyGraph/W=$graphName width={Plan,1,bottom,left}, height=height
End


// MosaicRefresh(graphName, [refill, alpha, red, green, blue, scheme])
// Reload the graph's .h5 (RefreshGraphData, ManookinLabIgorProcedures.ipf) and tidy the mosaic
// without rebuilding it: see MosaicClean. refill=1 redraws the FormatRfContour fill afterwards
// with the given colour/alpha (or scheme), then restores the plot size.
Function MosaicRefresh(graphName, [refill, alpha, red, green, blue, scheme])
	String graphName, scheme
	Variable refill, alpha, red, green, blue
	if (ParamIsDefault(refill))
		refill = 0
	endif
	if (ParamIsDefault(alpha))
		alpha = 16384
	endif
	if (ParamIsDefault(red))			// FormatRfContour's own defaults (black)
		red = 0
	endif
	if (ParamIsDefault(green))
		green = 0
	endif
	if (ParamIsDefault(blue))
		blue = 0
	endif
	if (StringMatch(graphName, "*.h5"))
		graphName = graphName[0, strlen(graphName)-4]
	endif
	if (WinType(graphName) != 1)
		Abort "no graph named " + graphName + " - use MakeMosaicGraph first"
	endif
	RefreshGraphData(graphName)
	if (ParamIsDefault(scheme))
		MosaicClean(graphName, refill=refill, alpha=alpha, red=red, green=green, blue=blue)
	else
		MosaicClean(graphName, refill=refill, alpha=alpha, red=red, green=green, blue=blue, scheme=scheme)
	endif
End

// MosaicClean(graphName, [refill, alpha, red, green, blue, scheme])
// Tidy a mosaic graph after its data folder was reloaded (RefreshAllData / RefreshGraphData):
//   1. cell*_Y traces that are hidden (RefreshGraphData hides traces whose wave left the file)
//      or whose wave is gone are removed and their waves killed - on a mosaic every cell trace
//      is generated, so nothing hand-made is lost; other traces (scale bars, hand-added
//      outlines) are untouched;
//   2. every cell*_Y trace gets the line size and colour of the first cell trace, so cells the
//      refresh appended match the rest;
//   3. the FormatRfContour fill polygons (drawing group rfFills) are deleted, since they still
//      show the OLD outlines; with refill=1 FormatRfContour is run again (RfContourFill.ipf must
//      be loaded) and the plot size is restored afterwards;
//   4. the Plan aspect, the reversed y axis and the hidden axes are re-asserted.
// Formatting of the graph itself (size, margins, text boxes, any other trace) is kept.
Function MosaicClean(graphName, [refill, alpha, red, green, blue, scheme])
	String graphName, scheme
	Variable refill, alpha, red, green, blue
	if (ParamIsDefault(refill))
		refill = 0
	endif
	if (ParamIsDefault(alpha))
		alpha = 16384
	endif
	if (WinType(graphName) != 1)
		Abort "no graph named " + graphName
	endif

	// remember the plot size (points) so a refill (FormatRfContour forces 72 x 72) can restore it
	GetWindow $graphName psize
	Variable plotHeight = V_bottom - V_top

	// 1. stale cell traces
	String traces = TraceNameList(graphName, ";", 1), tr, info
	Variable i, n = ItemsInList(traces), removed = 0, hidden, styled = 0
	for (i = n - 1; i >= 0; i -= 1)
		tr = StringFromList(i, traces)
		if (!MosaicIsCellTrace(tr))
			continue
		endif
		WAVE/Z w = TraceNameToWaveRef(graphName, tr)
		info = TraceInfo(graphName, tr, 0)
		hidden = NumberByKey("hideTrace(x)", info, "=", ";")
		if (!WaveExists(w) || hidden == 1)
			WAVE/Z wx = XWaveRefFromTrace(graphName, tr)
			RemoveFromGraph/W=$graphName/Z $tr
			KillWaves/Z w
			if (WaveExists(wx))
				KillWaves/Z wx
			endif
			removed += 1
		endif
	endfor

	// 2. uniform cell style, copied from the first remaining cell trace
	traces = TraceNameList(graphName, ";", 1)
	n = ItemsInList(traces)
	String first = ""
	for (i = 0; i < n; i += 1)
		tr = StringFromList(i, traces)
		if (MosaicIsCellTrace(tr))
			first = tr
			break
		endif
	endfor
	if (strlen(first) > 0)
		info = TraceInfo(graphName, first, 0)
		Variable ls = NumberByKey("lsize(x)", info, "=", ";")
		String rgbStr = StringByKey("rgb(x)", info, "=", ";")
		Variable r = 0, g = 0, b = 0
		sscanf rgbStr, "(%d,%d,%d)", r, g, b
		if (numtype(ls) != 0)
			ls = 0.5
		endif
		for (i = 0; i < n; i += 1)
			tr = StringFromList(i, traces)
			if (MosaicIsCellTrace(tr))
				ModifyGraph/W=$graphName lsize($tr)=ls, rgb($tr)=(r, g, b), mode($tr)=0, hideTrace($tr)=0
				styled += 1
			endif
		endfor
		MosaicApplyColors(graphName)		// traces with their own exported colour get it back
	endif

	// 3. old fills
	MosaicDeleteFills(graphName)			// every group, not just the first (see MosaicDeleteFills)
	if (refill)
		String cmd
		if (ParamIsDefault(scheme))
			if (ParamIsDefault(red) && ParamIsDefault(green) && ParamIsDefault(blue))
				sprintf cmd, "FormatRfContour(\"%s\", alpha=%g)", graphName, alpha
			else
				sprintf cmd, "FormatRfContour(\"%s\", red=%g, green=%g, blue=%g, alpha=%g)", graphName, red, green, blue, alpha
			endif
		else
			sprintf cmd, "FormatRfContour(\"%s\", scheme=\"%s\", alpha=%g)", graphName, scheme, alpha
		endif
		Execute/Q/Z cmd				// RfContourFill.ipf; Execute avoids a compile-time dependency
		if (V_flag != 0)
			print "MosaicClean: FormatRfContour failed (is RfContourFill.ipf loaded?)"
		endif
	endif

	// 4. geometry: Plan aspect, y downward, hidden axes; restore the plot height
	ModifyGraph/W=$graphName width={Plan,1,bottom,left}
	if (plotHeight > 0)
		ModifyGraph/W=$graphName height=plotHeight
	endif
	SetAxis/W=$graphName/A/R left
	ModifyGraph/W=$graphName noLabel=2, axThick=0, tick=3
	printf "MosaicClean: %s - %d stale cell traces removed, %d cell traces styled like %s, fills %s\r", graphName, removed, styled, first, SelectString(refill, "removed", "redrawn")
End


// MosaicDeleteFills(graphName, [group])
// Delete EVERY fill polygon of a previous FormatRfContour / MosaicFillByColor pass. Each polygon is
// its own drawing group (DrawFilledContour brackets each DrawPoly with gstart/gstop), so several
// groups share the name and one DrawAction delete removes only the first - which left the older
// fills underneath the new ones and made the shading darker with every pass. Returns the number of
// groups deleted.
Function MosaicDeleteFills(graphName, [group])
	String graphName, group
	if (ParamIsDefault(group))
		group = "rfFills"
	endif
	Variable n = 0, guard = 0
	do									// UserFront: where DrawFilledContour draws
		DrawAction/W=$graphName/L=UserFront getgroup=$group, delete
		if (V_flag == 0)
			break
		endif
		n += 1; guard += 1
	while (guard < 10000)
	guard = 0
	do									// UserBack: fills drawn by older versions / PolarFill-style code
		DrawAction/W=$graphName/L=UserBack getgroup=$group, delete
		if (V_flag == 0)
			break
		endif
		n += 1; guard += 1
	while (guard < 10000)
	return n
End

// MosaicApplyColors(graphName)
// Give every cell*_Y trace whose wave has a sibling <name>_color wave (numeric RGB in 0..1, the
// figure_utils convention) that colour. Traces without one are left as they are. Returns the
// number of traces coloured.
Function MosaicApplyColors(graphName)
	String graphName
	String traces = TraceNameList(graphName, ";", 1), tr, cname
	Variable i, n = ItemsInList(traces), done = 0
	for (i = 0; i < n; i += 1)
		tr = StringFromList(i, traces)
		if (!MosaicIsCellTrace(tr))
			continue
		endif
		WAVE/Z wy = TraceNameToWaveRef(graphName, tr)
		if (!WaveExists(wy))
			continue
		endif
		String df = GetWavesDataFolder(wy, 1), base = NameOfWave(wy)
		cname = df + base[0, strlen(base) - 3] + "_color"
		WAVE/Z wc = $cname
		if (WaveExists(wc) && WaveType(wc) != 0 && numpnts(wc) >= 3)
			ModifyGraph/W=$graphName rgb($tr) = (round(wc[0]*65535), round(wc[1]*65535), round(wc[2]*65535))
			done += 1
		endif
	endfor
	return done
End

// MosaicFillByColor(graphName, [alpha, match])
// Translucent fill of every outline in ITS OWN trace colour - the colour the export gave it
// (source cells one colour, target cells another, in compute_crosscorr.py's CcgMosaic_* files) or
// whatever you set with ModifyGraph rgb(...). Polygons go into the rfFills drawing group, so
// MosaicClean / a second call replace them. alpha 0..65535 (default 16384 = 25 %); match selects
// the traces (default: every outline trace, cell*_Y or fit*_Y). Unlike FormatRfContour the plot
// size is not touched.
Function MosaicFillByColor(graphName, [alpha, match])
	String graphName, match
	Variable alpha
	if (ParamIsDefault(alpha))
		alpha = 16384
	endif
	if (ParamIsDefault(match))
		match = ""						// empty: every outline trace, cell*_Y or fit*_Y
	endif
	if (WinType(graphName) != 1)
		Abort "no graph named " + graphName
	endif
	DoWindow/F $graphName
	Variable dropped = MosaicDeleteFills(graphName)	// replace any earlier fill, do not stack on it
	String traces = TraceNameList(graphName, ";", 1), tr, info, rgbStr
	Variable i, n = ItemsInList(traces), r, g, b, done = 0
	for (i = 0; i < n; i += 1)
		tr = StringFromList(i, traces)
		if (strlen(match) > 0)
			if (!StringMatch(tr, match))
				continue
			endif
		elseif (!MosaicIsCellTrace(tr))
			continue
		endif
		WAVE/Z wy = TraceNameToWaveRef(graphName, tr)
		WAVE/Z wx = XWaveRefFromTrace(graphName, tr)
		if (!WaveExists(wy) || !WaveExists(wx))
			continue
		endif
		info = TraceInfo(graphName, tr, 0)
		rgbStr = StringByKey("rgb(x)", info, "=", ";")
		r = 0; g = 0; b = 0
		sscanf rgbStr, "(%d,%d,%d)", r, g, b
		String cmd
		sprintf cmd, "DrawFilledContour(%s, %s, %g, %g, %g, %g)", GetWavesDataFolder(wx, 2), GetWavesDataFolder(wy, 2), r, g, b, alpha
		Execute/Q/Z cmd								// RfContourFill.ipf, on the top graph; Execute avoids a compile-time dependency
		if (V_flag != 0)
			print "MosaicFillByColor: DrawFilledContour failed (is RfContourFill.ipf loaded?)"
			return done
		endif
		done += 1
	endfor
	printf "MosaicFillByColor: %s - %d outlines filled in their trace colours (alpha %g; %d old fill(s) removed)\r", graphName, done, alpha, dropped
	return done
End


// MosaicSetExtent(graphName, spanUm, [ySpanUm, xCenter, yCenter])
// Set the axis spans in microns - spanUm for x and, if given, ySpanUm for y (else the same) -
// centred on the data unless xCenter/yCenter are given, keeping the Plan aspect and the
// reversed y axis. With the plot height fixed (MosaicSetHeight) the width follows the ratio of
// the spans, so a 2:1 array gets a 2:1 panel with no empty bands, and every panel with the same
// ySpanUm and height has the same microns per point: receptive-field sizes compare between
// panels by eye. Add one scale bar with MakeScaleBars. Returns the microns per point.
Function MosaicSetExtent(graphName, spanUm, [ySpanUm, xCenter, yCenter])
	String graphName
	Variable spanUm, ySpanUm, xCenter, yCenter
	if (WinType(graphName) != 1)
		Abort "no graph named " + graphName
	endif
	if (ParamIsDefault(ySpanUm))
		ySpanUm = spanUm
	endif
	// data extent from the cell traces
	String traces = TraceNameList(graphName, ";", 1), tr
	Variable i, n = ItemsInList(traces), xmin = Inf, xmax = -Inf, ymin = Inf, ymax = -Inf
	for (i = 0; i < n; i += 1)
		tr = StringFromList(i, traces)
		if (!MosaicIsCellTrace(tr))
			continue
		endif
		WAVE/Z wy = TraceNameToWaveRef(graphName, tr)
		WAVE/Z wx = XWaveRefFromTrace(graphName, tr)
		if (!WaveExists(wy) || !WaveExists(wx))
			continue
		endif
		xmin = min(xmin, WaveMin(wx)); xmax = max(xmax, WaveMax(wx))
		ymin = min(ymin, WaveMin(wy)); ymax = max(ymax, WaveMax(wy))
	endfor
	if (numtype(xmin) != 0)
		Abort "no cell*_Y or fit*_Y traces on " + graphName
	endif
	if (ParamIsDefault(xCenter))
		xCenter = (xmin + xmax) / 2
	endif
	if (ParamIsDefault(yCenter))
		yCenter = (ymin + ymax) / 2
	endif
	if (spanUm < xmax - xmin || ySpanUm < ymax - ymin)
		printf "MosaicSetExtent: %s - the data span %.0f x %.0f um, more than the requested %.0f x %.0f; outer cells will be clipped\r", graphName, xmax - xmin, ymax - ymin, spanUm, ySpanUm
	endif
	SetAxis/W=$graphName bottom xCenter - spanUm / 2, xCenter + spanUm / 2
	SetAxis/W=$graphName/R left yCenter + ySpanUm / 2, yCenter - ySpanUm / 2		// y downward, as in the STA
	ModifyGraph/W=$graphName width={Plan,1,bottom,left}
	GetWindow $graphName psize
	Variable umPerPt = ySpanUm / (V_bottom - V_top)
	printf "MosaicSetExtent: %s - %g x %g um on %.0f x %.0f pt = %.2f um/pt\r", graphName, spanUm, ySpanUm, V_right - V_left, V_bottom - V_top, umPerPt
	return umPerPt
End

// MosaicFitExtent(graphName, [padUm])
// Spans = the data extent in each direction plus padUm on every side (default 50 um), so the
// panel takes the array's own aspect ratio (a 2:1 array -> a 2:1 panel) with no empty bands.
// Same um/pt between panels is NOT guaranteed by this one - use MosaicSetExtent with a common
// ySpanUm for that.
Function MosaicFitExtent(graphName, [padUm])
	String graphName
	Variable padUm
	if (ParamIsDefault(padUm))
		padUm = 50
	endif
	String traces = TraceNameList(graphName, ";", 1), tr
	Variable i, n = ItemsInList(traces), xmin = Inf, xmax = -Inf, ymin = Inf, ymax = -Inf
	for (i = 0; i < n; i += 1)
		tr = StringFromList(i, traces)
		if (!MosaicIsCellTrace(tr))
			continue
		endif
		WAVE/Z wy = TraceNameToWaveRef(graphName, tr)
		WAVE/Z wx = XWaveRefFromTrace(graphName, tr)
		if (!WaveExists(wy) || !WaveExists(wx))
			continue
		endif
		xmin = min(xmin, WaveMin(wx)); xmax = max(xmax, WaveMax(wx))
		ymin = min(ymin, WaveMin(wy)); ymax = max(ymax, WaveMax(wy))
	endfor
	if (numtype(xmin) != 0)
		Abort "no cell*_Y or fit*_Y traces on " + graphName
	endif
	return MosaicSetExtent(graphName, xmax - xmin + 2 * padUm, ySpanUm=ymax - ymin + 2 * padUm)
End
