#pragma rtGlobals=1		// Use modern global access method.

// RfContourFill.ipf
//
// Fill closed contour traces (e.g., RF outlines exported from Python via
// figure_utils) with a solid or colormapped translucent fill, using
// drawing-layer polygons anchored to the graph axes.
//
// Usage:
//   FormatRfContour("PopulationRF_A1")                            // black/gray
//   FormatRfContour("PopulationRF_A1", red=65535, green=0, blue=0)
//   FormatRfContour("PopulationRF_A1", scheme="cubicyf", alpha=32768)
//   FormatRfContour("CcgMosaic_x", match="cell_source*", red=35000, green=16000, blue=17600, group="srcFills")
//   FormatRfContour("CcgMosaic_x", match="cell_target*", group="tgtFills")   // two colours on one graph:
//                                                        // match picks the traces, group keeps the fills apart
//   (for exports that carry their own colours, MosaicFillByColor in RfMosaics.ipf is simpler)
//
// Requires ManookinLabIgorProcedures.ipf for the custom colormap functions
// (CubicYF, CubicL, IsoL, WinterMap, CopperMap) when using scheme.
//
// IMPORTANT: remove any previous copies of FormatRfContour, DrawFilledContour,
// or FillContourTrace from other procedure files before compiling this one.

function FormatRfContour(graphName [, scheme, red, green, blue, alpha, match, group])
	string graphName
	string scheme, match, group
	variable red, green, blue, alpha

	string traces, curTrace
	variable i, items, index, numRows, denominator
	variable r, g, b, count, matchIndex
	variable useMap = !ParamIsDefault(scheme)

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
		alpha = 16384
	endif
	if (ParamIsDefault(match))
		match = "*cell*"			// which traces to fill (wildcards)
	endif
	if (ParamIsDefault(group))
		group = "rfFills"			// drawing group; a second call with the same group replaces its fills
	endif

	DoWindow /F $graphName

	ModifyGraph width=72,height=72

	// Remove fill-branch traces left over from older fill-between attempts.
	traces = TraceNameList("", ";", 1)
	items = ItemsInList(traces)
	for (i = 0; i < items; i += 1)
		curTrace = StringFromList(i, traces)
		if (stringmatch(curTrace, "*_fill*"))
			RemoveFromGraph/Z $curTrace
		endif
	endfor

	// Delete polygons drawn by a previous call with this group name.
	SetDrawLayer UserFront
	do
		DrawAction getgroup=$group, delete
	while (V_flag)

	traces = TraceNameList("", ";", 1)
	items = ItemsInList(traces)

	count = 0
	for (i = 0; i < items; i += 1)
		if (stringmatch(StringFromList(i, traces), match))
			count += 1
		endif
	endfor
	if (count == 0)
		print "FormatRfContour: no traces matching " + match + " on the top graph."
		return 0
	endif
	denominator = max(count - 1, 1)

	// Load the color table if a scheme was passed.
	if (useMap)
		if (stringmatch(LowerStr(scheme), "cubicyf"))
			wave M_colors
			CubicYF(M_colors)
		elseif (stringmatch(LowerStr(scheme), "cubicl"))
			wave M_colors
			CubicL(M_colors)
		elseif (stringmatch(LowerStr(scheme), "isol"))
			wave M_colors
			IsoL(M_colors)
		elseif (stringmatch(LowerStr(scheme), "winter"))
			wave M_colors
			WinterMap(M_colors)
		elseif (stringmatch(LowerStr(scheme), "copper"))
			wave M_colors
			CopperMap(M_colors)
		else
			ColorTab2Wave $scheme
			wave M_colors
		endif
		numRows = DimSize(M_colors, 0)
	endif

	matchIndex = 0
	for (i = 0; i < items; i += 1)
		curTrace = StringFromList(i, traces)
		if (stringmatch(curTrace, match))
			if (useMap)
				index = round(matchIndex/denominator * (numRows - 1))
				r = M_colors[index][0]
				g = M_colors[index][1]
				b = M_colors[index][2]
			else
				r = red
				g = green
				b = blue
			endif

			Wave yW = TraceNameToWaveRef("", curTrace)
			Wave/Z xW = XWaveRefFromTrace("", curTrace)
			if (WaveExists(xW))
				DrawFilledContour(xW, yW, r, g, b, alpha, group=group)
				ModifyGraph rgb($curTrace)=(r,g,b)
			else
				print "FormatRfContour: " + curTrace + " has no X wave; skipped."
			endif

			matchIndex += 1
		endif
	endfor
end

// Draw one filled polygon on the top graph, in axis coordinates, as a
// single DrawPoly command (vertices decimated to fit the command line).
function DrawFilledContour(xW, yW, r, g, b, alpha [, group])
	wave xW, yW
	variable r, g, b, alpha
	string group
	if (ParamIsDefault(group))
		group = "rfFills"
	endif

	variable n = numpnts(yW)
	variable maxPts = 80
	variable step = ceil(n / maxPts)
	if (step < 1)
		step = 1
	endif

	string pts = "", pair
	variable i
	for (i = 0; i < n; i += step)
		sprintf pair, "%.7g,%.7g", xW[i], yW[i]
		if (strlen(pts) > 0)
			pts += ","
		endif
		pts += pair
	endfor

	// Execute each command separately with /Z so a failure reports its
	// error code in V_flag (0 = OK) instead of silently aborting.
	string envStr, polyCmd

	Execute/Z "SetDrawLayer UserFront"
	Execute/Z "SetDrawEnv gstart,gname=" + group

	sprintf envStr, "SetDrawEnv xcoord= bottom, ycoord= left, fillfgc= (%d,%d,%d,%d), fillpat= 1, linefgc= (%d,%d,%d), linethick= 0.5", r, g, b, alpha, r, g, b
	Execute/Z envStr

	// IMPORTANT: DrawPoly places the first vertex at (xOrg, yOrg) and lays
	// the remaining vertices out relative to it, so the origin must be the
	// first vertex itself -- an origin of 0,0 translates the polygon to the
	// graph origin.
	sprintf polyCmd, "DrawPoly %.7g,%.7g,1,1,{%s}", xW[0], yW[0], pts
	Execute/Z polyCmd
	if (V_flag != 0)
		print "DrawFilledContour: DrawPoly failed, V_flag =", V_flag
	endif

	Execute/Z "SetDrawEnv gstop"
end
