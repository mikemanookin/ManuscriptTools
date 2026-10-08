#pragma rtGlobals=1		// Use modern global access method.

// Displays RGB image(s) exported from Python/matplotlib with
// figure_utils.image_to_igor(). Companion to DisplayFigFromMatlab.
//
// Conventions (per image label, e.g. "image"):
//   <label>_img    : (nx, ny, 3) unsigned-byte wave -> direct-color RGB image
//   <label>_scale  : [x0, x1, y0, y1] pixel-center coordinates for SetScale/I
//   Xlabel, Ylabel : text waves with the axis labels
//   XReversed, YReversed : 1 if that matplotlib axis was inverted
//                          (imshow normally inverts the y axis)
//   <label>_X/_Y/_color/_linestyle : optional overlaid line traces,
//                          same conventions as DisplayFigFromMatlab
//
// Usage (mirrors MakeFig):
//   MakeImageFig("TestImage")
Function DisplayImageFromPython(dataFolder)
	String dataFolder

	String img_waves, line_waves, curWave, curPrefix, scaleName, X, color
	Variable i, r, g, b
	Variable str_pos

	// Display the image(s).
	img_waves = WaveList("*_img", ";", "")
	i = 0
	do
		curWave = StringFromList(i, img_waves)
		if (strlen(curWave) == 0)
			break
		endif
		str_pos = strsearch(curWave, "_img", 0)
		curPrefix = curWave[0, str_pos-1]

		// Apply the matplotlib axis scaling (pixel-center coordinates).
		sprintf scaleName, "%s_scale", curPrefix
		if (WaveExists($scaleName))
			Wave scaleWave = $scaleName
			SetScale/I x scaleWave[0], scaleWave[1], "", $curWave
			SetScale/I y scaleWave[2], scaleWave[3], "", $curWave
		endif

		if (i == 0)
			Display
		endif
		AppendImage $curWave

		i += 1
	while (1)

	// Set axis labels.
	if (WaveExists(Xlabel))
		Wave/T Xlabel_wv = Xlabel
		Label bottom Xlabel_wv[0]
	endif
	if (WaveExists(Ylabel))
		Wave/T Ylabel_wv = Ylabel
		Label left Ylabel_wv[0]
	endif

	// Match matplotlib's axis directions (imshow puts row 0 at the top).
	if (WaveExists(YReversed))
		Wave yRev = YReversed
		if (yRev[0] == 1)
			SetAxis/A/R left
		endif
	endif
	if (WaveExists(XReversed))
		Wave xRev = XReversed
		if (xRev[0] == 1)
			SetAxis/A/R bottom
		endif
	endif

	// Append any overlaid line traces (same conventions as DisplayFigFromMatlab).
	line_waves = WaveList("*_Y", ";", "")
	i = 0
	do
		curWave = StringFromList(i, line_waves)
		if (strlen(curWave) == 0)
			break
		endif
		str_pos = strsearch(curWave, "_Y", 0)
		curPrefix = curWave[0, str_pos-1]

		// Get X data.
		sprintf X, "%s_X", curPrefix
		if (WaveExists($X))
			AppendToGraph $curWave vs $X
		else
			AppendToGraph $curWave
		endif

		// Set color.
		sprintf color, "%s_color", curPrefix
		if (WaveExists($color))
			Wave colorWave = $color
			r = round(colorWave[0]*(2^16-1))
			g = round(colorWave[1]*(2^16-1))
			b = round(colorWave[2]*(2^16-1))
			ModifyGraph rgb($curWave) = (r,g,b)
		endif

		i += 1
	while (1)

	// Name the window after the data folder.
	DoWindow $dataFolder
	if (V_flag == 1)	// window exists
		DoWindow/K $dataFolder
	endif
	DoWindow/C/T $dataFolder, dataFolder
End

Macro MakeImageFig(h5name)
	string h5name
	variable h5file
	if (StringMatch(h5name, "*.h5"))		// accept "Name.h5" as well as "Name"
		h5name = h5name[0, strlen(h5name)-4]
	endif
	string fullPath = FullPathToHomeFolder()
	string h5path = fullPath + h5name + ".h5"
	if (WinType(h5name) == 1)
		KillWindow $h5name
	endif
	KillDataFolder/Z root:$h5name
	NewDataFolder/o/s root:$h5name
	HDF5OpenFile/R/Z h5file as h5path
	if (V_flag != 0)
		Abort "MakeImageFig: cannot open " + h5path
	endif
	HDF5LoadGroup/Z :, h5file, h5name
	if (V_flag != 0)
		HDF5CloseFile h5file		// close before aborting, or the file stays locked (h5py errno 35)
		Abort "MakeImageFig: no group '" + h5name + "' in " + h5path + " - pass the file's base name"
	endif
	HDF5CloseFile h5file
	DisplayImageFromPython(h5name)
	SetDataFolder root:
	DoWindow/C/R $h5name
End
