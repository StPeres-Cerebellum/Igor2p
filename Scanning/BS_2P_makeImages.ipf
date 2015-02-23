#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function dum2Image(ScaledX,ScaledY,X_Offset,Y_Offset, lineTime, scanFreq, pixelsPerLine, KCT, frames)
	variable ScaledX,ScaledY,X_Offset,Y_Offset, lineTime, scanFreq, KCT, frames	//retrieve these from dum waveNote
	variable pixelsPerLine //ImageDisplayVariable

	variable pixelSize = ScaledX / pixelsPerLine
	variable scaleFactor = 16.7	//store this in a folder for CalibrationVariables
	variable xScanShift = 0.1		//time difference between input and outputof galvos (ms) store in UserVariables
	make/o/n=((ScaledX/pixelSize),(ScaledY/pixelSize)) dumDisplay = 0
	SetScale/P x 0,pixelSize,"µm", dumDisplay	
	SetScale/P y 0,pixelSize,"µm", dumDisplay
	
end

function DrawDumFromScanVoltages(dum, runx, runy)
	wave dum, runx, runy

	
	////////////////// Get variables out of dum  --can use these to recreate the scan if need be  ////////////////////////////
	string scanParameters = note(dum)
	variable scaledX = numberbykey("scaledX", scanParameters)
	variable scaledY = numberbykey("scaledY", scanParameters)
	variable frames = numberbykey("frames", scanParameters)
	variable KCT = numberbykey("KCT", scanParameters)
	variable acquisitionFrequency = numberbykey("AcquisitionFrequency", scanParameters)
	variable dwellTime = numberbykey("dwellTime", scanParameters)
	variable lineSpacing = numberbykey("lineSpacing", scanParameters)
	variable scaleFactor = numberbykey("scaleFactor", scanParameters)	//  µm / Volt
	variable X_Offset = numberbykey("X_Offset", scanParameters)
	variable Y_Offset = numberbykey("Y_Offset", scanParameters)
	variable scanOutFreq = numberbykey("scanOutFreq", scanParameters)
	variable scanFrameTime = numberbykey("scanFrameTime", scanParameters)	//ms
	variable lineTime = numberbykey("lineTime", scanParameters)
	variable pixelShift = numberbykey("pixelShift", scanParameters)
	variable scanLimit = numberbykey("scanLimit", scanParameters)
	variable displayPixelSize = numberbykey("displayPixelSize", scanParameters)

	pixelShift /= 1000

	variable imageOffset = scanLimit * scaleFactor
	variable xPixels = ceil(scaledX/displayPixelSize), yLines = ceil(scaledY/displayPixelSize)
	
	make/o/n=(xPixels,yLines,frames) root:Packages:BS2P:CurrentScanVariables:drawnImage = nan
	wave drawnImage = root:Packages:BS2P:CurrentScanVariables:drawnImage

	
//	make/o/n=((scaledX/displayPixelSize),(scaledY/displayPixelSize),frames) nrmlzImage = nan

	variable scanPointsPerFrame = scanOutFreq*scanFrameTime //
	variable totalDumTime = dimsize(dum, 0) * dimdelta(dum, 0)	//seconds!
	variable pointsInDum = numpnts(dum)
	
	
	////////////////some sort of sanity checking by comparing frames to (totalDumTime / frameTime) ///////////
//	print "frames = ", frames, "totalDumTime = ", totalDumTime, "scanFrameTime =", scanFrameTime
//	if(frames == totalDumTime / scanFrameTime)
		
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//////////////Walk through the dum wave and add "photons" to appropriate pixels of the image////////////
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//		pnt2x(dum, p)	//--dum time values
//		x2pnt(runx, x-value)	//Point number in runx where time = x-value	--rounds to nearest point (nearest voltage)
//		runx[x2pnt(runx, x-value)]	//Voltage of runx when the time is x-value
//		runx[x2pnt(runx,(pnt2x(dum,p))-pixelShift)] * scaleFactor	//X-Galvo position in microns of the focal plane for each value in dum  (subtract out the lag between sending control voltage and the actual position -- measured offline with o-scope)
//		runy[x2pnt(runy,(pnt2x(dum,p))-pixelShift)] * scaleFactor	//Y-Galvo position in microns of the focal plane for each value in dum (subtract out the lag between sending control voltage and the actual position -- measured offline with o-scope)
//		floor(frames*p/pointsInDum)	//FrameNumber (plane) for each point in dum
//
//		altogether we get:
//		currentDisplay((runx[x2pnt(runx,(pnt2x(dum,p))-pixelShift)] * scaleFactor), (runy[x2pnt(runy,(pnt2x(dum,p))-pixelShift)] * scaleFactor), (floor(frames*p/pointsInDum))) += dum[p]
//
//		but igor doesn't like the xscaling so have to convert it to points:
//		x2pnt(currentDisplay, (runx[x2pnt(runx,(pnt2x(dum,p))-pixelShift)] * scaleFactor))
//		x2pnt(currentDisplay, (runy[x2pnt(runy,(pnt2x(dum,p))-pixelShift)] * scaleFactor))

		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////HERE CAN CREATE RUNX AND RUNY FROM VARIABLES STORED IN DUM WAVE IF NEED BE///////////
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		variable i, frameNum, dumTime, xMicronsAtDumTime, yMicronsAtDumTime, DumPnt2ScanPnt, scanTime
		duplicate/o dum xcord, ycord, zcord
		for(i=0; i<numpnts(dum); i+=1)
			frameNum = floor(frames*i/pointsInDum)
			DumPnt2ScanPnt = i-(framenum*frames)	///this is a dum value and we want scan point number
			scanTime = pnt2x(runx, DumPnt2ScanPnt) - pixelShift	//seconds
			scanTime = scanTime < 0 ? 0 : scanTime
//			dumTime = pnt2x(dum,i)
//			print "scanTime = ", scanTime
			xMicronsAtDumTime = ((runx[x2pnt(runx,scanTime)] * scaleFactor)-x_offset) + imageOffset
			yMicronsAtDumTime = ((runy[x2pnt(runx,scanTime)] * scaleFactor)-y_offset) + imageOffset
//			xcord[i] = xMicronsAtDumTime
//			ycord[i] = yMicronsAtDumTime
//			zcord[i] = frameNum
			drawnImage[x2pnt(drawnImage, xMicronsAtDumTime)][x2pnt(drawnImage, yMicronsAtDumTime)][frameNum] += dum[i]
//			nrmlzImage[x2pnt(drawnImage, xMicronsAtDumTime)][x2pnt(drawnImage, yMicronsAtDumTime)][frameNum] += 1
			
//			matrixop/o nrmlz = drawnImage / nrmlzImage
//			drawnImage[x2pnt(drawnImage, (runx[x2pnt(runx,(pnt2x(dum,i))-pixelShift)] * scaleFactor))][x2pnt(drawnImage, (runy[x2pnt(runy,(pnt2x(dum,i))-pixelShift)] * scaleFactor))][frameNum] += dum[i]
		endfor
//		SetScale/P x X_offset,displayPixelSize,"µm", drawnImage
//		SetScale/P y Y_offset,displayPixelSize,"µm", drawnImage
//	else
//		abort "Should be " + num2str(frames) + " frames but I calculate " +num2str(totalDumTime / scanFrameTime) + " in dum"
		
//	endif

end

Window kineticWindow() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(13.5,128.75,588,718.25)/K=1  as "Kinetic Window"
	AppendImage :Packages:BS2P:CurrentScanVariables:kineticSeries
	ModifyImage kineticSeries ctab= {*,*,Grays,0}
	ModifyGraph height={Plan,1,left,bottom}
	ModifyGraph mirror=2
	ModifyGraph minor=1
	Cursor/P/I A kineticSeries 105,138
	ShowInfo
	ControlBar 72
	SetVariable BS_2P_pixelShifter,pos={5,47},size={103,16},proc=BS_2P_set_pixelShiftProc,title="Pixel Shift"
	SetVariable BS_2P_pixelShifter,frame=0,valueBackColor=(60928,60928,60928)
	SetVariable BS_2P_pixelShifter,limits={0,0.0002,5e-07},value= root:Packages:BS2P:CalibrationVariables:pixelShift
	SetVariable SetPixelSize,pos={4,31},size={90,16},proc=BS_2P_setPixelSizeProc,title="Binning (µm):"
	SetVariable SetPixelSize,frame=0,valueColor=(65280,0,0)
	SetVariable SetPixelSize,valueBackColor=(60928,60928,60928)
	SetVariable SetPixelSize,limits={0.025,inf,0},value= root:Packages:BS2P:CurrentScanVariables:displayPixelSize
	Slider WM3DAxis,pos={10,76},size={314,6},proc=WM3DImageSliderProc
	Slider WM3DAxis,limits={0,0,1},variable= root:Packages:WM3DImageSlider:kineticWindow:gLayer,side= 0,vert= 0,ticks= 0
	Button SaveThisStack,pos={460,2},size={107,21},proc=saveStackProc_2,title="Save this movie as:"
	Button BS_2P_kineticSeries,pos={120,2},size={71,20},proc=BS_2P_KineticSeriesButton,title="Kinetic Series"
	Button BS_2P_kineticSeries,fSize=11,fColor=(0,13056,0)
	Button BS_2P_AbortImaging,pos={119,23},size={71,20},proc=BS_2P_abortButtonProc_2,title="Abort"
	Button BS_2P_AbortImaging,fSize=11,fColor=(39168,0,0)
	Button BS_2P_videoSeries,pos={119,44},size={71,20},proc=BS_2P_VideoButton,title="Video"
	Button BS_2P_videoSeries,fSize=11,fColor=(0,13056,0)
	CheckBox AxesConstrain,pos={8,3},size={88,14},proc=BS_2P_constrainAxes,title="Constrain Axes"
	CheckBox AxesConstrain,value= 1
	Button FocusDown,pos={381,2},size={34,20},proc=BS_2P_focusUpButtonProc,title="up"
	Button FocusDown,fSize=8
	Button FocusDown1,pos={382,38},size={33,18},proc=BS_2P_focusDownButtonProc,title="down"
	Button FocusDown1,fSize=8
	SetVariable FocusStep,pos={372,21},size={85,18},title="\\F'Symbol'D\\F'MS Sans Serif'Focus (µm)"
	SetVariable FocusStep,frame=0
	SetVariable FocusStep,limits={-inf,inf,0},value= root:Packages:BS2P:CurrentScanVariables:focusStep
	SetVariable setFrames,pos={197,3},size={66,16},proc=BS_2P_SetFramesProc,title="Frames"
	SetVariable setFrames,frame=0,valueBackColor=(65535,65535,65535)
	SetVariable setFrames,limits={-inf,inf,0},value= root:Packages:BS2P:CurrentScanVariables:frames
	CheckBox BS_2P_ExternalTrigger,pos={269,4},size={92,14},title="External Trigger"
	CheckBox BS_2P_ExternalTrigger,variable= root:Packages:BS2P:CurrentScanVariables:externalTrigger
	ValDisplay FrameTime,pos={197,21},size={141,14},title="1 Frame (s):",fSize=10
	ValDisplay FrameTime,frame=0,fColor=(65280,0,0),valueColor=(65280,0,0)
	ValDisplay FrameTime,valueBackColor=(60928,60928,60928)
	ValDisplay FrameTime,limits={0,0,0},barmisc={0,1000}
	ValDisplay FrameTime,value= #"root:Packages:BS2P:CurrentScanVariables:scanFrameTime"
	ValDisplay FrameTime1,pos={198,35},size={63,14},title="(Hz):",fSize=10
	ValDisplay FrameTime1,format="%.1f",frame=0,fColor=(65280,0,0)
	ValDisplay FrameTime1,valueColor=(65280,0,0),valueBackColor=(60928,60928,60928)
	ValDisplay FrameTime1,limits={0,0,0},barmisc={0,1000}
	ValDisplay FrameTime1,value= #"root:Packages:BS2P:CurrentScanVariables:displayFrameHz"
	ValDisplay TotalTime,pos={197,48},size={145,14},title="Total scan time (s):"
	ValDisplay TotalTime,fSize=10,format="%.1f",frame=0,fColor=(65280,0,0)
	ValDisplay TotalTime,valueColor=(65280,0,0),valueBackColor=(60928,60928,60928)
	ValDisplay TotalTime,limits={0,0,0},barmisc={0,1000}
	ValDisplay TotalTime,value= #"root:Packages:BS2P:CurrentScanVariables:displayTotalTime"
	SetVariable SaveAs,pos={483,22},size={219,16},title=" ",frame=0
	SetVariable SaveAs,value= root:Packages:BS2P:CurrentScanVariables:fileName2bWritten
	PopupMenu BS_2P_SaveWhere,pos={571,2},size={43,21},bodyWidth=43,proc=BS_2P_pathSelectionPopMenuProc,title="Path"
	PopupMenu BS_2P_SaveWhere,mode=0,value= #"root:Packages:BS2P:CurrentScanVariables:pathDetailsListing"
	SetVariable BS_2P_SavePrefix,pos={618,7},size={87,16},bodyWidth=57,proc=BS_2P_ChangeSavePrefix,title="Prefix"
	SetVariable BS_2P_SavePrefix,value= root:Packages:BS2P:CurrentScanVariables:SaveAsPrefix
	SetVariable Increment,pos={710,7},size={46,16},bodyWidth=24,proc=SetPrefixIncrementProc,title="Inc:"
	SetVariable Increment,limits={-inf,inf,0},value= root:Packages:BS2P:CurrentScanVariables:prefixIncrement
	CheckBox BS_2P_SaveEverything,pos={702,41},size={57,14},proc=CheckProcSaveAll,title="Save All"
	CheckBox BS_2P_SaveEverything,value= 0,side= 1
	Button zoomout,pos={566,48},size={34,20},proc=ZoomOutProc_2,title="out",fSize=8
	Button zoomIn,pos={612,48},size={34,20},proc=ZoomInProc_2,title="in",fSize=8
	SetVariable setZoom,pos={568,33},size={82,16},proc=BS_2P_SetFramesProc,title="Zoom (µm)"
	SetVariable setZoom,frame=0,valueBackColor=(65535,65535,65535)
	SetVariable setZoom,limits={-inf,inf,0},value= root:Packages:BS2P:CurrentScanVariables:zoomFactor
	SetDrawLayer UserFront
	SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65280,0,0),dash= 2
	DrawLine -1e-05,0,1e-05,0
	SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65280,0,0),dash= 2
	DrawLine 0,-1e-05,0,1e-05
EndMacro

Function BS_2P_Append3DImageSlider()
	NVAR frames =  root:Packages:BS2P:CurrentScanVariables:frames
	String grfName= "kineticWindow"
	DoWindow/F $grfName
	if( V_Flag==0 )
		return 0			// no top graph, exit
	endif


	String iName= WMTopImageGraph()		// find one top image in the top graph window
	if( strlen(iName) == 0 )
		DoAlert 0,"No image plot found"
		return 0
	endif
	
	Wave w= $WMGetImageWave(iName)	// get the wave associated with the top image.	
//	if(DimSize(w,2)<=0)
//		DoAlert 0,"Need a 3D image"
//		return 0
//	endif
	String dfSav= GetDataFolder(1)	
	ControlInfo WM3DAxis
	NewDataFolder/S/O root:Packages
	NewDataFolder/S/O WM3DImageSlider
	NewDataFolder/S/O $grfName			// already installed, do nothing
	
	// 09JUN10 Variable/G gLeftLim=0,gRightLim=DimSize(w,2)-1,gLayer=0
	Variable/G gLeftLim=0,gRightLim=frames-1,gLayer=0
	String/G imageName=nameOfWave(w)
	ControlInfo kwControlBar
//	Variable/G gOriginalHeight= V_Height		// we append below original controls (if any)
//	ControlBar gOriginalHeight+30

	GetWindow kwTopWin,gsize
	
	Slider WM3DAxis,pos={10,82},size={314,6},proc=WM3DImageSliderProc
	// uncomment the following line if you want do disable live updates when the slider moves.
	// Slider WM3DAxis live=0	
	Slider WM3DAxis,limits={0,gRightLim,1},value= 0,vert= 0,ticks=0,side=0,variable=gLayer	
	
//	SetVariable WM3DVal,pos={V_right-kImageSliderLMargin+15,gOriginalHeight+9},size={60,14}
//	SetVariable WM3DVal,limits={0,INF,1},title=" ",proc=WM3DImageSliderSetVarProc
	
//	String cmd
//	sprintf cmd,"SetVariable WM3DVal,value=%s",GetDataFolder(1)+"gLayer"
//	Execute cmd

	ModifyImage $imageName plane=0
	// 
	WaveStats/Q w
//	ModifyImage $imageName ctab= {V_min,V_max,,0}	// missing ctb to leave it unchanced.
	
	SetDataFolder dfSav
End

function makeProjections(imageStack)
	wave imageStack
	
	variable xScale = dimdelta(imageStack,0)
	variable yScale = dimdelta(ImageStack,1)
	variable zScale = dimdelta(ImageStack,2)
	imageTransform zProjection imageStack 
	imageTransform xProjection imageStack 
	imageTransform yProjection imageStack 
	
	wave m_zprojection
	wave m_xprojection
	wave m_yprojection
	
//	imagetransform fliprows m_xprojection 
	matrixop/o/free xProj = m_xprojection ^ t
	duplicate/o xProj m_xprojection
	imagetransform flipcols m_yprojection
	
	SetScale/P x 0,(-1 * zScale),"m", m_xprojection;SetScale/P y 0,(xScale),"m", m_xprojection
	SetScale/P x 0,(yscale),"m", m_yprojection;SetScale/P y 0,(-1 * zScale),"m", m_yProjection
	SetScale/P x 0,(xScale),"m", m_zprojection;SetScale/P y 0,(yScale),"m", m_zProjection
	
	
	
	display/k=1/n=projectionBrowser
	appendimage/w=projectionBrowser m_zprojection
	appendimage/w=projectionBrowser m_xprojection
	appendimage/w=projectionBrowser m_yprojection
	ModifyGraph width={Plan,1,bottom,left}
	SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (52224,52224,52224),dash= 8
	DrawLine ((dimdelta(m_xProjection,0) * dimsize(m_xProjection,0))),0,(dimdelta(m_yProjection,0) * dimsize(m_yProjection,0)),0
	SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (52224,52224,52224),dash= 8
	DrawLine 0,((dimdelta(m_xProjection,0) * dimsize(m_xProjection,0))),0,(dimdelta(m_yProjection,0) * dimsize(m_yProjection,0))

	
end