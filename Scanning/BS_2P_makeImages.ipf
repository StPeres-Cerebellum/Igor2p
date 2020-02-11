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
	Display /W=(8.25,123.5,582.75,719)/K=1  as "Kinetic Window"
	AppendImage :Packages:BS2P:CurrentScanVariables:kineticSeries
	ModifyImage kineticSeries ctab= {*,*,Grays,0}
	ModifyGraph height={Plan,1,left,bottom}
	ModifyGraph mirror=2
	ModifyGraph minor=1
	SetAxis/A/R bottom
	ControlBar 80
	SetVariable BS_2P_pixelShifter,pos={5.00,33.00},size={115.00,18.00},title="Pixel Shift"
	SetVariable BS_2P_pixelShifter,frame=0,valueBackColor=(60928,60928,60928)
	SetVariable BS_2P_pixelShifter,limits={0,0.0002,5e-07},value= root:Packages:BS2P:CalibrationVariables:pixelShift
	Slider WM3DAxis,pos={10.00,82.00},size={314.00,10.00},proc=WM3DImageSliderProc
	Slider WM3DAxis,limits={0,0,1},variable= root:Packages:WM3DImageSlider:kineticWindow:gLayer,side= 0,vert= 0,ticks= 0
	Button SaveThisStack,pos={460.00,2.00},size={107.00,21.00},proc=saveStackProc_2,title="Save this movie as:"
	Button BS_2P_kineticSeries,pos={120.00,2.00},size={76.00,20.00},proc=BS_2P_KineticSeriesButton,title="Kinetic Series"
	Button BS_2P_kineticSeries,fSize=11,fColor=(0,13056,0)
	Button BS_2P_AbortImaging,pos={119.00,23.00},size={76.00,20.00},proc=BS_2P_abortButtonProc_2,title="Abort"
	Button BS_2P_AbortImaging,fSize=11,fColor=(39168,0,0)
	Button BS_2P_videoSeries,pos={119.00,44.00},size={76.00,20.00},proc=BS_2P_VideoButton,title="Video"
	Button BS_2P_videoSeries,fSize=11,fColor=(0,13056,0)
	CheckBox AxesConstrain,pos={8.00,3.00},size={94.00,15.00},proc=BS_2P_constrainAxes,title="Constrain Axes"
	CheckBox AxesConstrain,value= 1
	SetVariable setFrames,pos={197.00,3.00},size={66.00,18.00},proc=BS_2P_SetFramesProc,title="Frames"
	SetVariable setFrames,frame=0,valueBackColor=(65535,65535,65535)
	SetVariable setFrames,limits={-inf,inf,0},value= root:Packages:BS2P:CurrentScanVariables:frames
	SetVariable setAvg,pos={197.00,20.00},size={41.00,18.00},title="Avg",frame=0
	SetVariable setAvg,valueBackColor=(65535,65535,65535)
	SetVariable setAvg,limits={-inf,inf,0},value= root:Packages:BS2P:CurrentScanVariables:frameAvg
	CheckBox BS_2P_ExternalTrigger,pos={269.00,4.00},size={98.00,15.00},title="External Trigger"
	CheckBox BS_2P_ExternalTrigger,variable= root:Packages:BS2P:CurrentScanVariables:externalTrigger
	ValDisplay FrameTime,pos={197.00,37.00},size={117.00,14.00},title="1 Frame:"
	ValDisplay FrameTime,fSize=10,format="%.2W1Ps",frame=0,fColor=(65280,0,0)
	ValDisplay FrameTime,valueColor=(65280,0,0),valueBackColor=(60928,60928,60928)
	ValDisplay FrameTime,limits={0,0,0},barmisc={0,1000}
	ValDisplay FrameTime,value= #"root:Packages:BS2P:CurrentScanVariables:scanFrameTime *root:Packages:BS2P:CurrentScanVariables:frameAvg"
	ValDisplay FrameTime1,pos={198.00,51.00},size={90.00,14.00},title="freq:"
	ValDisplay FrameTime1,fSize=10,format="%.1f Hz",frame=0,fColor=(65280,0,0)
	ValDisplay FrameTime1,valueColor=(65280,0,0),valueBackColor=(60928,60928,60928)
	ValDisplay FrameTime1,limits={0,0,0},barmisc={0,1000}
	ValDisplay FrameTime1,value= #"root:Packages:BS2P:CurrentScanVariables:displayFrameHz"
	ValDisplay TotalTime,pos={197.00,64.00},size={106.00,14.00},title="Total time:"
	ValDisplay TotalTime,fSize=10,format="%.1W1Ps",frame=0,fColor=(65280,0,0)
	ValDisplay TotalTime,valueColor=(65280,0,0),valueBackColor=(60928,60928,60928)
	ValDisplay TotalTime,limits={0,0,0},barmisc={0,1000}
	ValDisplay TotalTime,value= #"root:Packages:BS2P:CurrentScanVariables:displayTotalTime *root:Packages:BS2P:CurrentScanVariables:frameAvg"
	SetVariable SaveAs,pos={538.00,22.00},size={219.00,18.00},title=" ",frame=0
	SetVariable SaveAs,value= root:Packages:BS2P:CurrentScanVariables:fileName2bWritten
	PopupMenu BS_2P_SaveWhere,pos={571.00,2.00},size={46.00,19.00},bodyWidth=46,proc=BS_2P_pathSelectionPopMenuProc,title="Path"
	PopupMenu BS_2P_SaveWhere,mode=0,value= #"root:Packages:BS2P:CurrentScanVariables:pathDetailsListing"
	SetVariable BS_2P_SavePrefix,pos={620.00,4.00},size={90.00,18.00},bodyWidth=57,proc=BS_2P_ChangeSavePrefix,title="Prefix"
	SetVariable BS_2P_SavePrefix,value= root:Packages:BS2P:CurrentScanVariables:SaveAsPrefix
	SetVariable Increment,pos={714.00,4.00},size={47.00,18.00},bodyWidth=24,proc=SetPrefixIncrementProc,title="Inc:"
	SetVariable Increment,limits={-inf,inf,0},value= root:Packages:BS2P:CurrentScanVariables:prefixIncrement
	CheckBox BS_2P_SaveEverything,pos={644.00,41.00},size={81.00,15.00},proc=saveALLCheckProc,title="Save images"
	CheckBox BS_2P_SaveEverything,variable= root:Packages:BS2P:CurrentScanVariables:saveEmAll
	CheckBox BS_2P_SaveEphys,pos={644.00,57.00},size={74.00,15.00},title="Save ePhys"
	CheckBox BS_2P_SaveEphys,variable= root:Packages:BS2P:CurrentScanVariables:saveEphys
	SetVariable setZoom,pos={545.00,43.00},size={82.00,18.00},proc=BS_2P_SetFramesProc,title="Zoom (µm)"
	SetVariable setZoom,frame=0,valueBackColor=(65535,65535,65535)
	SetVariable setZoom,limits={-inf,inf,0},value= root:Packages:BS2P:CurrentScanVariables:zoomFactor
	Button zoomout,pos={543.00,58.00},size={34.00,20.00},proc=ZoomOutProc_2,title="out"
	Button zoomout,fSize=8
	Button zoomIn,pos={589.00,58.00},size={34.00,20.00},proc=ZoomInProc_2,title="in"
	Button zoomIn,fSize=8
	Button moveU,pos={500.00,31.00},size={14.00,16.00},proc=MoveUProc,title="^"
	Button moveU,fSize=8
	Button moveR,pos={519.00,48.00},size={14.00,16.00},proc=MoveRProc,title=">"
	Button moveR,fSize=8
	Button moveD,pos={500.00,63.00},size={14.00,16.00},proc=MoveDProc,title="v"
	Button moveD,fSize=8
	Button moveL,pos={480.00,48.00},size={14.00,16.00},proc=MoveLProc,title="<"
	Button moveL,fSize=8
	SetVariable setMoveStep,pos={496.00,46.00},size={22.00,18.00},title=" ",frame=0
	SetVariable setMoveStep,valueBackColor=(65535,65535,65535)
	SetVariable setMoveStep,limits={-inf,inf,0},value= root:Packages:BS2P:CurrentScanVariables:moveStep
	ValDisplay stageX,pos={107.00,100.00},size={70.00,17.00},title="X:"
	ValDisplay stageX,labelBack=(65280,65280,32768),format="%.1f µm",frame=0
	ValDisplay stageX,valueBackColor=(65280,65280,32768)
	ValDisplay stageX,limits={0,0,0},barmisc={0,1000}
	ValDisplay stageX,value= #"root:Packages:P_I:PI_xPos"
	ValDisplay stageX,barBackColor= (65280,65280,32768)
	ValDisplay stageY,pos={172.00,100.00},size={68.00,17.00},bodyWidth=54,title="Y:"
	ValDisplay stageY,labelBack=(65280,65280,32768),format="%.1f µm",frame=0
	ValDisplay stageY,valueBackColor=(65280,65280,32768)
	ValDisplay stageY,limits={0,0,0},barmisc={0,1000}
	ValDisplay stageY,value= #"root:Packages:P_I:PI_yPos"
	ValDisplay stageY,barBackColor= (65280,65280,32768)
	Button FocusUP,pos={313.00,22.00},size={34.00,20.00},proc=BS_2P_focusUpButtonProc,title="up"
	Button FocusUP,fSize=8
	Button FocusDown,pos={314.00,57.00},size={33.00,18.00},proc=BS_2P_focusDownButtonProc,title="down"
	Button FocusDown,fSize=8
	SetVariable focusStep,pos={310.00,41.00},size={50.00,18.00},title="µm",frame=0
	SetVariable focusStep,valueBackColor=(60928,60928,60928)
	SetVariable focusStep,limits={0,2000,0},value= root:Packages:BS2P:CurrentScanVariables:focusStep
	GroupBox stackBox,pos={370.00,24.00},size={108.00,56.00}
	Button doStack,pos={373.00,27.00},size={34.00,20.00},proc=doStack,title="stack"
	Button doStack,fSize=8,fColor=(61440,61440,61440)
	SetVariable stackDepth,pos={381.00,46.00},size={86.00,18.00},title="depth (µm)"
	SetVariable stackDepth,frame=0
	SetVariable stackDepth,limits={0,2000,0},value= root:Packages:BS2P:CurrentScanVariables:stackDepth
	SetVariable stackResolution,pos={375.00,61.00},size={96.00,18.00},title="resolution (µm)"
	SetVariable stackResolution,frame=0
	SetVariable stackResolution,limits={0,20,0},value= root:Packages:BS2P:CurrentScanVariables:stackResolution
	ValDisplay stageZ,pos={239.00,100.00},size={65.00,17.00},title="Z:"
	ValDisplay stageZ,labelBack=(65280,65280,32768),format="%.1f µm",frame=0
	ValDisplay stageZ,valueBackColor=(65280,65280,32768)
	ValDisplay stageZ,limits={0,0,0},barmisc={0,1000}
	ValDisplay stageZ,value= #"root:Packages:P_I:PI_zPos"
	ValDisplay stageZ,barBackColor= (65280,65280,32768)
	ValDisplay pixSize,pos={5.00,18.00},size={90.00,17.00},title="Pixel Size"
	ValDisplay pixSize,labelBack=(60928,60928,60928),format="%.W1Pm",frame=0
	ValDisplay pixSize,valueBackColor=(60928,60928,60928)
	ValDisplay pixSize,limits={0,0,0},barmisc={0,1000}
	ValDisplay pixSize,value= #"root:packages:bs2p:currentScanVariables:displayPixelSize"
	CheckBox BS_2P_TrigLoop,pos={370.00,4.00},size={81.00,15.00},title="LoopTrigger"
	CheckBox BS_2P_TrigLoop,variable= root:Packages:BS2P:CurrentScanVariables:trigLoop
	SetDrawLayer UserFront
	SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65280,0,0),dash= 2
	DrawLine -3.9e-05,-2.39e-05,-1.9e-05,-2.39e-05
	SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65280,0,0),dash= 2
	DrawLine -2.9e-05,-3.4e-05,-2.9e-05,-1.4e-05
	ModifyGraph swapXY=1
	SetWindow kwTopWin,hook(myHook)=kineticWIndowHook
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
	
//	imagetransform flipcols m_xprojection 
	matrixop/o/free xProj = m_xprojection ^ t
	duplicate/o xProj m_xprojection
//	imagetransform flipcols m_yprojection
	
	SetScale/P x 0,(-zScale),"m", m_xprojection;SetScale/P y 0,(xScale),"m", m_xprojection
	SetScale/P x 0,(yscale),"m", m_yprojection;SetScale/P y 0,(-zScale),"m", m_yProjection
	SetScale/P x 0,(xScale),"m", m_zprojection;SetScale/P y 0,(yScale),"m", m_zProjection
	
	
	doWindow/k projectionBrowser
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

function importStack(zStep, images)
	variable images, zStep //meters
	variable i
	string target, newName
	for(i=0; i < images; i += 1)
		target = "F:Desktop:stack:bs150318:granule1:stack_"+num2str(i)+".ibw"
		newName = "stack_"+num2str(i)
		LoadWave/H/O/q target
		wave kineticSeries
		redimension/n=(-1,-1) kineticSeries
		duplicate/o kineticSeries $newName
	endfor
	wave stack_0
	variable pixelSize = dimdelta(stack_0,0)
	
	imageTransform/k stackImages stack_0
	wave m_stack
	setScale/p x, 0, pixelSize, m_stack; setScale/p y, 0, pixelSize, m_stack; setScale/p z, 0, (zStep), m_stack
	makeProjections(m_stack)
end

function rotateImage(inputImage)
	wave inputImage
	wave/t boardCOnfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	variable hReflect = str2num(boardConfig[19][2])
	variable XYswitch = str2num(boardConfig[21][2])
	variable vReflect = str2num(boardConfig[20][2])
	
	variable frames = dimsize(inputImage,2), frame

	if(XYswitch == 1)
		if(frames > 1)
			imagetransform/o/g=(5) transposeVol inputImage; wave m_volumeTranspose
			duplicate/o m_volumeTranspose inputImage
			killwaves m_volumeTranspose
		else
			matrixOP/o/free switched = inputImage ^t
			duplicate/o switched inputImage
		endif
	endif
	
	if(hReflect == 1)
		if(frames > 1)
			for(frame=0; frame<frames; frame +=1)
				imagetransform/p=(frame) flipRows inputImage
			endfor
		else
			imagetransform flipRows inputImage
		endif
	endif

	if(vReflect == 1)
		if(frames > 1)
			for(frame=0; frame<frames; frame +=1)
				imagetransform/p=(frame) flipCols inputImage
			endfor
		else
			imagetransform flipCols inputImage
		endif
	endif

end

function rotatekineticWin()
	wave/t boardCOnfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	variable hReflect = str2num(boardConfig[19][2])
	variable XYswitch = str2num(boardConfig[21][2])
	variable vReflect = str2num(boardConfig[20][2])

	if(XYswitch == 1)
		ModifyGraph/w=kineticWindow swapXY=1
	else
		ModifyGraph/w=kineticWindow swapXY=0
	endif
	
	if(hReflect == 1)
		SetAxis/a/R/w=kineticWindow bottom
	else
		SetAxis/a/w=kineticWindow bottom
	endif

	if(vReflect == 1)
		SetAxis/a/R/w=kineticWindow left
	else
		SetAxis/a/w=kineticWindow left
	endif

end

function checkXYSwitch(inputWave,frames)
	wave inputWave
	variable frames
	NVAR XYswapped = root:Packages:BS2P:CurrentScanVariables:XYswapped
	if(XYswapped == 1)
		if(frames > 1)
			imagetransform/o/g=(5) transposeVol inputWave; wave m_volumeTranspose
			duplicate/o m_volumeTranspose inputWave
			killwaves m_volumeTranspose
		else
			matrixOP/o/free switched = inputWave ^t
			duplicate/o switched inputWave
		endif
	endif
end