#pragma rtGlobals=1		// Use modern global access method.


// FullPathToHomeFolder()
// Returns colon-separated path to experiment's home folder with trailing colon
// or "" if there is no home folder.
Function/S FullPathToHomeFolder()
	PathInfo home
	if (V_flag == 0)
		// The current experiment was never saved so there is no home folder
		return ""
	endif
 
	String path = S_path
	return path
End

Function SaveAllGraphsAsGraphicsFiles(extension, visibleOnly, format, bitmapRes)
    String extension                // Extension for file name, e.g., ".tif", ".pdf", ".png" . . .
    Variable visibleOnly            // 1 to save only visible graphs, 0 to save visible and hidden graphs.
    Variable format             // For SavePICT /E flag. See SavePICT documentation.
    Variable bitmapRes          // For SavePICT /RES flag (e.g., 288 for 288 dpi).
    
    Variable index = 0
    do
        String graphName = WinName(index, 1, visibleOnly)
        if (strlen(graphName) == 0)
            break                   // All done
        endif
        
        String fileName = graphName + extension
        SavePICT /N=$graphName /O /E=(format) /RES=(bitmapRes) as FullPathToHomeFolder() + fileName
        
        index += 1
    while(1)
End

// Save all of open graphs as EPS files in the current directory.
Function SaveAllGraphsAsEPS(visibleOnly)
    Variable visibleOnly            // 1 to save only visible graphs, 0 to save visible and hidden graphs.
    
    Variable index = 0
    do
        String graphName = WinName(index, 1, visibleOnly)
        if (strlen(graphName) == 0)
            break                   // All done
        endif
        
        String fileName = graphName + ".eps"
        SavePICT /N=$graphName /O /E=-3 as FullPathToHomeFolder() + fileName
        
        index += 1
    while(1)
End

// Save all of open graphs as PDF files in the current directory.
Function SaveAllGraphsAsPDF(visibleOnly)
    Variable visibleOnly            // 1 to save only visible graphs, 0 to save visible and hidden graphs.
    
    // Get the OS.
    String platform = IgorInfo(2)
    
    Variable index = 0
    do
        String graphName = WinName(index, 1, visibleOnly)
        if (strlen(graphName) == 0)
            break                   // All done
        endif
        
        String fileName = graphName + ".pdf"
        
        // Save PDF according to OS.
        StrSwitch (platform)
        		Case "Macintosh":
        			SavePICT /WIN=$graphName /O /E=-2 as FullPathToHomeFolder() + fileName
        		Case "Windows":
        			SavePICT /WIN=$graphName /O /E=-8 as FullPathToHomeFolder() + fileName
        EndSwitch
        
        index += 1
    while(1)
End


Macro MakeFig(h5name)
	string h5name
	variable h5file
	string fullPath = FullPathToHomeFolder()
	string h5path= fullPath +h5name+".h5"
	if (WinType(h5name)==1)
		KillWindow $h5name
	endif
	KillDataFolder/Z root:$h5name
	NewDataFolder/o/s root:$h5name
	HDF5OpenFile h5file as h5path
	HDF5LoadGroup :,h5file , h5name
	HDF5CloseFile h5file
	DisplayFigFromMatlab(h5name,1)
	SetDataFolder root:
	DoWindow/C/R $h5name
	formatgraph()
end

Macro FormatGraph()
	ModifyGraph fSize=7,font="Arial"
	ModifyGraph tick=2,nticks=3,manTick=0
	ModifyGraph axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1}
	ModifyGraph margin(left)=20,margin(bottom)=18,margin(top)=18,margin(right)=7
	ModifyGraph tick=0,axThick=0.5,btLen=2,stLen=2
	ModifyGraph width=54,height=54
	ModifyGraph tlOffset(bottom)=-1.5
	ModifyGraph lsize=0.5
	ModifyGraph expand=2
End

Macro MakeScaleBars(StartX, EndX, StartY, EndY, XLabel, YLabel)
	variable StartX
	variable EndX
	variable StartY
	variable EndY
	string XLabel
	string YLabel
	ModifyGraph noLabel=2,axThick=0
	SetDrawEnv xcoord= bottom,ycoord= left
	DrawLine StartX, StartY, StartX, EndY
	SetDrawEnv xcoord= bottom,ycoord= left
	DrawLine StartX, EndY, EndX, EndY
	SetDrawEnv xcoord= bottom,ycoord= left
	SetDrawEnv fname= "Arial",fsize= 8
	DrawText (StartX+EndX)/2, EndY*1.05, XLabel
	SetDrawEnv xcoord= bottom,ycoord= left
	SetDrawEnv fname= "Arial",fsize= 8
	DrawText StartX*.95, (StartY + EndY)/2, YLabel
end

// Save all of open graphs as EPS files in the current directory.
Macro SaveAllGraphs()
	SaveAllGraphsAsPDF(1)
End

macro SaveAllGizmos()
	SaveGizmosAsPNG(1)
end

function SaveGizmosAsPNG(visibleOnly)
	Variable visibleOnly            // 1 to save only visible graphs, 0 to save visible and hidden graphs.
	
	Variable index = 0
	do
		string graphName = WinName(index,65536,visibleOnly)
		if (strlen(graphName) == 0)
          break                   // All done
      endif
      
      SavePICT /WIN=$graphName /O /E=-5/TRAN=1/B=144 as FullPathToHomeFolder() + graphName + ".png"
      index += 1
	while(1)
end

Function RefreshGraphData(h5name)
	string h5name
	variable h5file
	string fullPath = FullPathToHomeFolder()
	string h5path= fullPath +h5name+".h5"
	// Make sure the file exists.
	GetFileFolderInfo/Q/Z h5path
	if (V_flag == 0)
		SetDataFolder root:$h5name
		Killwaves/A/Z
		HDF5OpenFile h5file as h5path
		HDF5LoadGroup/o :,h5file , h5name
		if (V_Flag == 0)
			HDF5CloseFile h5file
			SetDataFolder root:
		else
			HDF5CloseFile h5file
			printf h5name
			
		endif
	else
		print "File " + h5name + " does not exist in the data folder."
	endif
End

macro RefreshAllData()
	RefreshAllGraphs()
end

Function RefreshAllGraphs()
	Variable index = 0
   do
   	String graphName = WinName(index, 1, 1)
		if (strlen(graphName) == 0)
      	break                   // All done
      endif
        
      RefreshGraphData(graphName)
        
      index += 1
	while(1)
End

// Vector of linearly spaced values.
function linspace(x, y, n, b)
	variable x, y, n
	
	wave/Z b
	
	variable n1 = n - 1
	
	
	
	if( WaveExists(b) )
		redimension/N=(n) b
	else
		Make/N=(n) b
	endif
	
	variable i
	for (i = 0; i < n; i+=1)
		b[i] = x + i*(y - x)/n1;
	endfor
end

// Sum of Sinusoids function.
function SumOfSines(x, y, a1, f1, ph1, a2, f2, ph2)
	wave x, y
	variable a1, f1, ph1, a2, f2, ph2
	
	variable i
	for (i = 0; i < numpnts(x); i += 1)
		y[i] = a1*sin(f1*x[i]+ph1) + a2*sin(f2*x[i]+ph2)
	endfor
end

function CubicYF(M_colors)
	wave M_colors
	if ( WaveExists(M_colors))
		redimension/N=(256, 3) M_colors
	else
		make/N=(256, 3) M_colors
	endif
	
	wave/Z a1, f1, ph1, a2, f2, ph2
	make a1 = {1.743,1.634,0.7465}
	make f1 = {0.01024,0.009399,0.007246}
	make ph1 = {-0.1747,-0.25,0.8044}
	make a2 = {1.457,0.744,0.2877}
	make f2 = {0.01378,0.01229,0.02296}
	make ph2 = {2.544,2.495,0.4715} 
	
	variable i, j
	for (i = 0; i < 256; i += 1)
		for (j = 0; j < 3; j += 1)
			M_colors[i][j] = round(65535*(a1[j]*sin(f1[j]*i+ph1[j]) + a2[j]*sin(f2[j]*i+ph2[j])))
		endfor
	endfor
	
	killwaves a1, f1, ph1, a2, f2, ph2
end

function CubicL(M_colors)
	wave M_colors
	if ( WaveExists(M_colors))
		redimension/N=(256, 3) M_colors
	else
		make/N=(256, 3) M_colors
	endif
	
	wave/Z a1, f1, ph1, a2, f2, ph2
	make a1 = {1.611,1.438,0.7312}
	make f1 = {0.0013,0.01261,0.009361}
	make ph1 = {0.1509,-0.2706,0.6894}
	make a2 = {0.236,0.5803,0.2923}
	make f2 = {0.02723,0.01706,0.02948}
	make ph2 = {1.374,2.519,0.1615} 
	
	variable i, j
	for (i = 0; i < 256; i += 1)
		for (j = 0; j < 3; j += 1)
			M_colors[i][j] = round(65535*(a1[j]*sin(f1[j]*i+ph1[j]) + a2[j]*sin(f2[j]*i+ph2[j])))
		endfor
	endfor
	
	killwaves a1, f1, ph1, a2, f2, ph2
end

function IsoL(M_colors)
	wave M_colors
	if ( WaveExists(M_colors))
		redimension/N=(256, 3) M_colors
	else
		make/N=(256, 3) M_colors
	endif
	
	wave/Z a1, f1, ph1, a2, f2, ph2
	make a1 = {1.446,0.6769,2.702}
	make f1 = {0.01034,0.004303,0.001513}
	make ph1 = {0.2706,2.146,2.795}
	make a2 = {1.472,0.4639,0.2922}
	make f2 = {0.01559,0.01291,0.02961}
	make ph2 = {2.78,5.431,-0.0927} 
	
	variable i, j
	for (i = 0; i < 256; i += 1)
		for (j = 0; j < 3; j += 1)
			M_colors[i][j] = round(65535*(a1[j]*sin(f1[j]*i+ph1[j]) + a2[j]*sin(f2[j]*i+ph2[j])))
		endfor
	endfor
	
	killwaves a1, f1, ph1, a2, f2, ph2
end

// Matlab's winter colormap
function WinterMap(M_colors)
	wave M_colors
	if ( WaveExists(M_colors))
		redimension/N=(256, 3) M_colors
	else
		make/N=(256, 3) M_colors
	endif
	
	variable i
	for (i = 0; i < 256; i += 1)
		M_colors[i][0] = 0;
		M_colors[i][1] = round(65535*(i/255))
		M_colors[i][2] = round(65535*((255-i)/255))
	endfor
end

// Matlab's copper colormap
function CopperMap(M_colors)
	wave M_colors
	if ( WaveExists(M_colors))
		redimension/N=(256, 3) M_colors
	else
		make/N=(256, 3) M_colors
	endif
	
	variable i, xval
	for (i = 0; i < 256; i += 1)
		xval = i/204
		if (xval > 1)
			xval = 1
		endif
		M_colors[i][0] = round(65535*xval)
		M_colors[i][1] = round(65535*(i/255*0.7812))
		M_colors[i][2] = round(65535*(i/255*0.4975))
	endfor
end

// PMKMP
function pmkmp(n, scheme, out)
	variable n
	string scheme
	wave out
	
	
	wave/Z baseMap, idx1, idx2
	if ( WaveExists(out))
		redimension/N=(n, 3) out
	else
		make/N=(n, 3) out
	endif
	
	if ( WaveExists(idx1) )
		redimension/N=(n) idx1
	else
		make/N=(n) idx1
	endif
	
	if ( WaveExists(idx2) )
		redimension/N=(n) idx2
	else
		make/N=(n) idx2
	endif
	
	
	if (stringmatch(scheme, "IsoL"))
		baseMap = {{0.9102,0.2236,0.8997},{0.4027,0.3711,1},{0.0422,0.5904,0.5899},{0.0386,0.6206,0.0201},{0.5441,0.5428,0.011},{1,0.2288,0.1631}}
	elseif (stringmatch(scheme, "CubicYF"))
		baseMap = {{0.5151,0.0482,0.6697},{0.5199,0.1762,0.8083},{0.4884,0.2912,0.9234},{0.4297,0.3855,0.9921},{0.3893,0.4792,0.9775},{0.3337,0.5650,0.9056},{0.2795,0.6419,0.8287},{0.2210,0.7123,0.7258},{0.2468,0.7612,0.6248},{0.2833,0.8125,0.5069},{0.3198,0.8492,0.3956},{0.3602,0.8896,0.2919},{0.4568,0.9136,0.3018},{0.6033,0.9255,0.3295},{0.7066,0.9255,0.3414},{0.8000,0.9255,0.3529}}
	elseif (stringmatch(scheme, "Edge"))
		baseMap = {{0,0,0},{0,0,1},{0,1,1},{1,1,0},{1,0,0},{0,0,0}}
	else // CubicL is default
		baseMap = {{0.4706,0,0.5216},{0.5137,0.0527,0.7096},{0.4942,0.2507,0.8781},{0.4296,0.3858,0.9922},{0.3691,0.5172,0.9495},{0.2963,0.6191,0.8515},{0.2199,0.7134,0.7225},{0.2643,0.7836,0.5756},{0.3094,0.8388,0.4248},{0.3623,0.8917,0.2858},{0.5200,0.9210,0.3137},{0.6800,0.9255,0.3386},{0.8000,0.9255,0.3529},{0.8706,0.8549,0.3608},{0.9514,0.7466,0.3686},{0.9765,0.5887,0.3569}}
	endif
	
	linspace(1, n, numpnts(baseMap)/3, idx1)
	linspace(1, n, n, idx2)
	
	
	wave temp, temp2
	if ( WaveExists(temp))
		redimension/N=(dimsize(baseMap,1)) temp
	else
		make/o/n=(dimsize(baseMap,1)) temp
	endif
	if ( WaveExists(temp2))
		redimension/N=(dimsize(baseMap,1)) temp2
	else
		make/o/n=(dimsize(baseMap,1)) temp2
	endif
	
	
	variable i, j
	for (i=0; i < 3; i+=1)
		temp = baseMap[i][p]
		//temp2 = interp(idx2, idx1, temp)
		interpolate2/T=2/N=(n)/Y=temp2 temp
		//interpolate2/T=2/N=(n)/Y=temp2 idx1, temp
		print idx1
		for (j=0; j < n; j+=1)
			out[j][i] = round(temp2[j]*65535)
		endfor
	endfor
end

function SetColorOfGraphTraces(graphName, scheme)
	string graphName, scheme
	DoWindow /F $graphName
	
	string traces = TraceNameList("",";",1)
	traces = RemoveFromList("zeroline_Y", traces)
	traces = RemoveFromList("shade_Y", traces)
	variable items = ItemsInList(traces)
	variable denominator = items - 1
	
	if (denominator < 1)
		denominator = 1
	endif
	
	traces = SortTraceNamesByNumber(traces)
	
	// Get the color table.
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
		ColorTab2Wave $scheme //SpectrumBlack//Spectrum //BlueBlackRed //YellowHot //BlueGreenOrange
		wave M_colors
	endif
	variable numRows = DimSize(M_colors, 0)
	variable red, green, blue
	variable i, index
	for (i = 0; i < items; i += 1)
		// Spread entire color range over all traces.
		index = round(i/denominator * (numRows - 1))
		ModifyGraph rgb($StringFromList(i, traces)) = (M_colors[index][0], M_colors[index][1], M_colors[index][2])
	endfor
	
//	wave out
//	pmkmp(items, scheme, out)
//	
//	variable i, index
//	for (i = 0; i < items; i += 1)
//		ModifyGraph rgb($StringFromList(i,traces))=(out[0][i],out[1][i],out[2][i])
//		//ModifyGraph rgb($StringFromList(i,traces))=(out[i][0],out[i][1],out[i][0])
//	endfor
	
end

function/S SortTraceNamesByNumber(traces)
	string traces
	variable items = ItemsInList(traces)
	
	// Create a text wave to hold the sorted trace names.
	Make/T/N=(items) traceNames
	traceNames = StringFromList(p, traces, ";")
	
	string prefix, suffix
	string regex = "[neg|pos](\d+)[\_|\w+]"
	
	wave traceVals, traceIndex
	if ( WaveExists(traceVals))
		redimension/N=(items) traceVals
	else
		make/N=(items) traceVals
	endif
	
	if ( WaveExists(traceIndex))
		redimension/N=(items) traceIndex
	else
		make/N=(items) traceIndex
	endif
	
	variable i
	for (i = 0; i < items; i += 1)
		SplitString/E=regex StringFromList(i,traces), prefix, suffix
		if (GrepString(StringFromList(i,traces),"zero"))
			prefix = "0"
		elseif (GrepString(StringFromList(i,traces),"neg"))
			prefix = "-" + prefix
		endif
		traceVals[i] = str2num(prefix)
	endfor
	
	MakeIndex traceVals, traceIndex
	// Sort the trace names by increasing contrast (or other numerical value).
	IndexSort traceIndex, traceNames
	
	// Read the sorted trace names back into the traces.
	traces = ""
	traces = traces + traceNames[0]
	for (i = 1; i < items; i += 1)
		traces = traces + ";" + traceNames[i];
	endfor
	
	// Clear the trace names from memory.
	killwaves traceNames
	
	return traces
end