#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function makeMultiPanel()
	doWindow/k multiPanel
	newPanel/n=multiPanel/ext=0/host=kineticWindow as "multiPanel"
	
	Button BS_2P_recalcMulti title="Recalc",fColor=(0,0,65535), fstyle=1,proc=BS_2P_createMultiButton, valueColor=(65535,65535,65535)
	
	Button BS_2P_multiKineticSeries title="Kinetic", fColor=(2,39321,1), fstyle=1

	Button BS_2P_multiAbort title="Abort",fColor=(65535,16385,16385), fstyle=1,proc=BS_2P_abortButtonProc_2
	
	Button BS_2P_multiVideo title="Video", fColor=(2,39321,1), fstyle=1, proc=BS_2P_multiVideoButton
	wave multiScanOffsets = root:Packages:BS2P:CurrentScanVariables:multiScanOffsets
		if (!waveExists(multiScanOffsets))
			make/n=0/o root:Packages:BS2P:CurrentScanVariables:multiScanOffsets
		endif
	variable/g root:Packages:BS2P:currentScanVariables:multiPixelSize
	variable/g root:Packages:BS2P:currentScanVariables:multiPixelDwell
	variable/g root:Packages:BS2P:currentScanVariables:multiPixelFrameRate
	variable/g root:Packages:BS2P:currentScanVariables:multiPixelSubRate

	DrawText 1, 132, "Pixel"
	ValDisplay multiPixelDisplay,pos={1,133},size={50,14},format="%.W1Pm",frame=0,limits={0,0,0},barmisc={0,1000}
	ValDisplay multiPixelDisplay, value= #"root:Packages:BS2P:currentScanVariables:multiPixelSize"
	
	DrawText 1, 172, "Dwell"
	ValDisplay multiDwellDisplay,pos={1,173},size={50,14},format="%.W1Ps",frame=0,limits={0,0,0},barmisc={0,1000}
	ValDisplay multiDwellDisplay, value= #"root:Packages:BS2P:currentScanVariables:multiPixelDwell"
	
	DrawText 1, 212, "Rate"
	ValDisplay multiRateDisplay,pos={1,213},size={50,14},format="%.W1Ps",frame=0,limits={0,0,0},barmisc={0,1000}
	ValDisplay multiRateDisplay, value= #"root:Packages:BS2P:currentScanVariables:multiPixelFrameRate"
	
	DrawText 1, 252, "Sub Rate"
	ValDisplay multiSubRateDisplay,pos={1,253},size={50,14},format="%.W1Ps",frame=0,limits={0,0,0},barmisc={0,1000}
	ValDisplay multiSubRateDisplay, value= #"root:Packages:BS2P:currentScanVariables:multiPixelSubRate"

//	Button BS_2P_multiVideo title="Hide", fColor=(52224,52224,52224), fstyle=1, proc=BS_2P_hideMultiPanelButton

end



Function BS_2P_multiVideoButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up

			BS_2P_Scan("multiVideo")

		case -1: // control being killed
			break
	endswitch

	return 0
End

Function BS_2P_createMultiButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			createMultiScan()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function BS_2P_multiKinetic(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			BS_2P_Scan("multiKinetic")
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


function multipleScans()
	getmarquee left, bottom
	SetDrawLayer/W=$S_MarqueeWin/K userfront
	variable/g root:Packages:BS2P:CurrentScanVariables:multiScaledX
	variable/g root:Packages:BS2P:CurrentScanVariables:multiScaledY
	variable/g root:Packages:BS2P:CurrentScanVariables:multiX_Offset
	variable/g root:Packages:BS2P:CurrentScanVariables:multiY_Offset
	updateMultiScanFromMarquee()
	BS_2P_updateVariables()
	marquee2Box()
//	makeFirstScanWindow()
	make/n=(1,2)/o root:Packages:BS2P:CurrentScanVariables:multiScanOffsets
	wave multiScanOffsets = root:Packages:BS2P:CurrentScanVariables:multiScanOffsets
	NVAR X_offset = root:Packages:BS2P:CurrentScanVariables:multiX_Offset
	NVAR Y_offset = root:Packages:BS2P:CurrentScanVariables:multiY_Offset
	multiScanOffsets[0][0] = X_Offset
	multiScanOffsets[0][1] = Y_Offset 
	cursor /h=1 /I a kineticSeries 0, 0
	makeMultiPanel()
	setWindow kineticWindow hook(mvCrsr)=multiScansHook
end


Function updateMultiScanFromMarquee()
	getmarquee/K left, bottom
	wave/t boardCOnfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	variable hReflect = str2num(boardConfig[19][2])
	variable XYswitch = str2num(boardConfig[21][2])
	variable vReflect = str2num(boardConfig[20][2])
	NVAR scaledX = root:Packages:BS2P:CurrentScanVariables:multiScaledX
	NVAR scaledY = root:Packages:BS2P:CurrentScanVariables:multiScaledY
	NVAR displayPixelSize = root:Packages:BS2P:CurrentScanVariables:displayPixelSize
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
	NVAR totalLines = root:Packages:BS2P:CurrentScanVariables:totalLines
	NVAR X_Offset = root:Packages:BS2P:CurrentScanVariables:multiX_Offset
	NVAR Y_Offset = root:Packages:BS2P:CurrentScanVariables:multiY_Offset
	
	displayPixelSize = scaledX / pixelsPerLine
	totalLines = ceil(ScaledY / displayPixelSize)
	variable scannerLeft = v_left, scannerRight = v_right, scannertop = v_top, scannerBottom = v_bottom
	
	if(XYswitch == 1)
		scannerLeft = v_bottom
		scannerRight = v_top
		scannerTop = v_right
		scannerBottom = v_left
	endif
	if(hreflect == 1)
		scannerLeft = v_right
		scannerRight = v_left
	endif
	if(vreflect == 1)
		scannerTop = v_bottom
		scannerBottom = v_top
	endif	
	X_Offset = scannerLeft
	Y_offset = scannerBottom
	scaledX = scannerRight - scannerLeft
	scaledY = scannerTop - scannerBottom
	
//	print scaledX, scaledY
	
	
end


function marquee2Box()
	getmarquee/K left, bottom
	SetDrawLayer/W=kineticWindow userfront
	SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65280,65280,0),fillpat= 0
	DrawRect v_left,v_top,v_right,v_bottom
end


function multiScansHook(s)    //This is a hook for the mousewheel movement in MatrixExplorer
	STRUCT WMWinHookStruct &s

	variable X_offset //= root:Packages:BS2P:CurrentScanVariables:X_Offset
	variable Y_offset //= root:Packages:BS2P:CurrentScanVariables:Y_Offset
	NVAR scaledX =  root:Packages:BS2P:CurrentScanVariables:multiScaledX
	NVAR scaledY = root:Packages:BS2P:CurrentScanVariables:multiScaledY
//	NVAR totalLines = root:Packages:BS2P:CurrentScanVariables:totalLines
	
	wave multiScanOffsets = root:Packages:BS2P:CurrentScanVariables:multiScanOffsets
	switch(s.eventCode)
		case 11:
			switch(s.keycode)
				case 32:	//spacebar
					redimension/n=((dimsize(multiScanOffsets,0)+1),2) multiScanOffsets
					string cursorInfo = csrInfo(A)
					wave imageName = CsrWaveRef(A)
					variable xpoint = numberByKey("POINT", cursorInfo)
					variable ypoint = numberByKey("YPOINT", cursorInfo)
					variable xImage = (xPoint * DimDelta(imageName, 0)  +  DimOffset(imageName, 0))
					variable yImage = (yPoint * DimDelta(imageName, 1)  +  DimOffset(imageName, 1))
					//variable/g root:Packages:BS2P:CurrentScanVariables:
					X_Offset = xImage - (scaledX/2)//; print x_offset
					Y_offset = yImage - (scaledY/2)
					multiScanOffsets[(dimsize(multiScanOffsets,0)-1)][0] = X_Offset
					multiScanOffsets[(dimsize(multiScanOffsets,0)-1)][1] = Y_Offset
					SetDrawLayer userfront
					SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65280,65280,0),fillpat= 0
					DrawRect X_offset,Y_offset + scaledY,X_offset + scaledX, Y_offset
					dowindow/F kineticWindow				
				break

				case 13:	//	Enter
					cursor/k a
					Note/NOCR multiScanOffsets, "scaledX="+num2str(scaledX)+";scaledY="+num2str(scaledY)+";"
//					Note/NOCR multiScanOffsets, "lines="+num2str(totalLines)+";"
					CreateMultiScan()
				break
			endswitch
		break
	endswitch
end


function CreateMultiScan()
//	NVAR scaledX =  root:Packages:BS2P:CurrentScanVariables:scaledX
//	NVAR scaledY = root:Packages:BS2P:CurrentScanVariables:scaledY	
	variable X_offset //= root:Packages:BS2P:CurrentScanVariables:X_Offset
	variable Y_offset //= root:Packages:BS2P:CurrentScanVariables:Y_Offset
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
	NVAR lineTime = root:Packages:BS2P:CurrentScanVariables:lineTime
//	NVAR lineSpacing = root:Packages:BS2P:CurrentScanVariables:lineSpacing
	NVAR frames = root:Packages:BS2P:CurrentScanVariables:frames
	
//	NVAR Lines = ceil(ScaledY/lineSpacing)
	NVAR dwellTime = root:Packages:BS2P:CurrentScanVariables:dwellTime
	wave dum = root:Packages:BS2P:CurrentScanVariables:dum
	wave runx = root:Packages:BS2P:CurrentScanVariables:runx
	wave runy = root:Packages:BS2P:CurrentScanVariables:runy
	
	wave multiScanOffsets = root:Packages:BS2P:CurrentScanVariables:multiScanOffsets
	string offsetNote = note(multiScanOffsets)
//	variable totalLines =  numberByKey("lines", offsetNote, "=", ";")
	variable subFrames = dimsize(multiScanOffsets,0)
	NVAR multiPixelSize = root:Packages:BS2P:currentScanVariables:multiPixelSize
	NVAR multiPixelDwell = root:Packages:BS2P:currentScanVariables:multiPixelDwell
	NVAR multiPixelFrameRate = root:Packages:BS2P:currentScanVariables:multiPixelFrameRate
	NVAR multiPixelSubRate = root:Packages:BS2P:currentScanVariables:multiPixelSubRate
	
	variable scaledX = numberByKey("scaledX", offsetNote, "=", ";")
	variable scaledY = numberByKey("scaledY", offsetNote, "=", ";") 
	variable maxSlopeBetweenRegions =  3000	// Volts / ms
	
	multiPixelSize = scaledX / pixelsPerLine
	variable multiLines =  ceil(scaledY / multiPixelSize)
	
	X_offset = multiScanOffsets[0][0]
	Y_offset = multiScanOffsets[0][1]
	makeUnscaledXRaster(multiLines, pixelsPerLine, lineTime)
	makeUnscaledYRaster(multiLines, pixelsPerLine, lineTime)
	wave tempRunX = scaleRunX(runx, x_offset, scaledX)
	wave tempRunY = scaleRunY(runy, y_offset, scaledY, multiPixelSize)
	
	SetDrawLayer/W=kineticWindow/K userfront
	SetDrawEnv/W=kineticWindow xcoord= bottom,ycoord= left,linefgc= (65280,65280,0),fillpat= 0
	DrawRect/W=kineticWindow X_offset,Y_offset + scaledY,X_offset + scaledX, Y_offset
	
	duplicate/o tempRunX root:Packages:BS2P:CurrentScanVariables:multiX
	duplicate/o tempRunY root:Packages:BS2P:CurrentScanVariables:multiY
	wave multiX = root:Packages:BS2P:CurrentScanVariables:multiX
	wave multiY = root:Packages:BS2P:CurrentScanVariables:multiY	
	Note/K multiX, "frameTime="+num2str(dimDelta(runx,0) * dimSize(runx,0))+";"
	Note/K multiY, "frameTime="+num2str(dimDelta(runy,0) * dimSize(runy,0))+";"
	Note/NOCR multiX, "framePixels="+num2str(multiLines*pixelsPerLine)+";"
	Note/NOCR multiY, "framePixels="+num2str(multiLines*pixelsPerLine)+";"
//	Note/NOCR multiX, "transitionTimes="
//	Note/NOCR multiY, "transitionTimes="
	variable i
	for(i=1; i<subFrames; i += 1)
		X_offset = multiScanOffsets[i][0]
		Y_offset = multiScanOffsets[i][1]
		makeUnscaledXRaster(multiLines, pixelsPerLine, lineTime)
		makeUnscaledYRaster(multiLines, pixelsPerLine, lineTime)
		wave nextRunX = scaleRunX(runx, x_offset, scaledX)
		wave nextRunY = scaleRunY(runy, y_offset, scaledY, multiPixelSize)
		
		SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65280,65280,0),fillpat= 0
		DrawRect X_offset,Y_offset + scaledY,X_offset + scaledX, Y_offset
		
		variable lastXPos = multiX[numpnts(multiX)-1]
		variable lastYPos = multiy[numpnts(multiY)-1]
		variable nextXpos = nextRunX[0]
		variable nextYpos = nextRunY[0]
		
		addMultiTransition(i,lastXPos, lastYPos, nextXpos, nextYpos, maxSlopeBetweenRegions)
		concatenate/NP {nextRunX}, multiX
		concatenate/NP {nextRunY}, multiY
	endfor

	lastXPos = multiX[numpnts(multiX)-1]
	nextXpos = multiX[0]
	lastYPos = multiY[numpnts(multiY)-1]
	nextYpos = multiY[0]
	addMultiTransition(i,lastXPos, lastYPos, nextXpos, nextYpos, maxSlopeBetweenRegions)
	
	variable totalScanTime = dimDelta(multiX,0) * dimSize(multiX, 0) * frames
	Note/NOCR multiX, "subFrames="+num2str(i)+";"
	Note/NOCR multiY, "subFrames="+num2str(i)+";"
	Note/K multiScanOffsets, "pixels="+num2str(pixelsPerLine)+";"
	Note/NOCR multiScanOffsets, "lines="+num2str(multiLines)+";"
	Note/NOCR multiScanOffsets, "scaledX="+num2str(scaledX)+";"
	Note/NOCR multiScanOffsets, "scaledY="+num2str(scaledY)+";"
	
	multiPixelDwell = dwellTIme
	multiPixelFrameRate = dimdelta(multiX,0) * dimsize(multiX,0)
	multiPixelSubRate = multiPixelFrameRate / i
		
end

function displayMultiDums(kineticSeries,multiOffsets, foldedDum)
	wave multiOffsets, kineticSeries, foldedDum
	NVAR scaledX = root:Packages:BS2P:CurrentScanVariables:scaledX
	NVAR scaledY = root:Packages:BS2P:CurrentScanVariables:scaledY
	
	variable subWindows = dimsize(multiOffsets,0)//; print "subWIndows = ", subWindows
	variable subRows = dimsize(foldedDum,0)//; print "subRows = ", subRows
	variable subCols = dimsize(foldedDum,1)//;print "subCols = ", subCOls
	variable subFrames = dimsize(foldedDum,2) / subWindows//; print "subFrames = ", subFrames
	
	kineticSeries = nan
	variable i
	for(i=0; i < subWindows; i += 1)
		variable leftPoint = (multiOffsets[i][0] - DimOffset(kineticSeries, 0))/DimDelta(kineticSeries,0)//; print "leftPoint =", leftPoint
		variable bottomPoint = (multiOffsets[i][1] - DimOffset(kineticSeries, 1))/DimDelta(kineticSeries,1)//; print "bottomPoint =", bottomPoint
		
		variable rightPoint = ceil(scaledX/DimDelta(kineticSeries,0))+leftPoint//; print "rightPoint =", rightPoint
		variable topPoint =  ceil(scaledY/DimDelta(kineticSeries,1))+bottomPoint//; print "topPoint =", topPoint
		make/o/free/n=(subRows,subCols,subFrames) subWindow = foldedDum[p][q][((r*subWIndows)+i)]
		kineticSeries[leftPoint,rightPoint][bottomPoint,topPoint][] = subWIndow[p-leftPoint][q-bottomPoint][r]	
	endfor
end

function addMultiTransition(transNumber,lastXPos, lastYPos, nextXpos, nextYpos, maxSlopeBetweenRegions)
	variable transNumber, maxSlopeBetweenRegions
	variable lastXPos,lastYPos, nextXpos, nextYpos
	NVAR dwellTime = root:Packages:BS2P:CurrentScanVariables:dwellTime
	
	wave multiX = root:Packages:BS2P:CurrentScanVariables:multiX
	wave multiY = root:Packages:BS2P:CurrentScanVariables:multiY
	variable dX = nextXpos- lastXpos
	variable dY = nextYpos- lastYpos
	variable dtX = dimDelta(multiX,0)
	variable dtY = dimDelta(multiY,0)
	
	variable xTransitionTime = abs(dx / maxSlopeBetweenRegions)	//make transition time constant (0.5 ms)
	variable yTransitionTime = abs(dy / maxSlopeBetweenRegions)	//in order to simplify image construction?
	variable transitionTime
	
	if(xTransitionTime > yTransitionTime)
		transitionTime = xTransitionTime
	else
		transitionTime = yTransitionTime
	endif
	
//	print "dwellTime =",dwellTime
	
	transitionTime = ceil(transitionTime / dwellTime) * dwellTime
	
	variable numPntsToAddToX = transitionTime / dtX		// ceil(transitionTime / dtX)
	variable numPntsToAddToY = transitionTime / dtY	// ceil(transitionTime / dtY)
	
//	print numPntsToAddToX, numPntsToAddToY
	
	make/o/free/n=(numPntsToAddToX) xTransition = ( p*dtX*(dX / transitionTime) )+lastXPos
	make/o/free/n=(numPntsToAddToY) yTransition = ( p*dtY*(dY / transitionTime) )+lastYPos
	copyScales/P multiX, xTransition
	copyScales/P multiY, yTransition

	concatenate/NP {xTransition}, multiX
	concatenate/NP {yTransition}, multiY
	
	Note/NOCR multiX, "transTime"+num2str(transNumber)+":"+num2str(dimDelta(xTransition,0) * dimSize(xTransition,0))+";"
	Note/NOCR multiY, "transTime"+num2str(transNumber)+":"+num2str(dimDelta(yTransition,0) * dimSize(yTransition,0))+";"
	
	Note/NOCR multiX, "transPixels"+num2str(transNumber)+"="+num2str(numPntsToAddToX)+";"
	Note/NOCR multiY, "transPixels"+num2str(transNumber)+"="+num2str(numPntsToAddToY)+";"
end


function clipTransitionsFromMultiDum(multiDum)
	wave multiDum
	wave multiX = root:Packages:BS2P:CurrentScanVariables:multiX
	wave multiY = root:Packages:BS2P:CurrentScanVariables:multiY
	
	variable framePixels = numberByKey("framePixels",note(multiX), "=", ";")
	variable subFrames = numberByKey("subFrames",note(multiX), "=", ";")
	variable i
	for(i=1; i<=subFrames; i+=1)
		variable transPixels = numberByKey("transPixels"+num2str(i),note(multiX), "=", ";")
		deletePoints (i*framePixels), transPixels, multiDum
	endfor
end

function clipTransitionsUnfoldedMultiDum(multiDum)//, testCutter)
	wave multiDum//, testCutter
	wave multiX = root:Packages:BS2P:CurrentScanVariables:multiX
	wave multiY = root:Packages:BS2P:CurrentScanVariables:multiY
	NVAR frames = root:Packages:BS2P:CurrentScanVariables:frames
	
	
	variable framePixels = numberByKey("framePixels",note(multiX), "=", ";")
	variable subFrames = numberByKey("subFrames",note(multiX), "=", ";")
	Make/O/N=(subFrames) transitionPixelsWave = nan
	variable i
	for(i=1; i<=subFrames; i+=1)
		transitionPixelsWave[i-1] = numberByKey("transPixels"+num2str(i),note(multiX), "=", ";")
	endfor
	
	make/o/n=(subFrames * frames) frameTimer = transitionPixelsWave[(mod(p,subFrames))]

	for(i=0; i<(numpnts(frametimer)); i+=1)
		variable pointsToRemove = frameTimer[i] //str2num(stringFromList(i, transitionTimes))
		variable subFrame = ((mod(i,subFrames))+1)
		variable frame = floor(i/subFrames)
		variable transitionStart = (((frame * subFrames) + subFrame) * framePixels)//+1
		deletePoints transitionStart, pointsToRemove, multiDum 
//		multiDum[transitionStart, transitionStart+pointsToRemove] = -1//; print pointsToRemove, transitionStart, transitionStart+pointsToRemove
//		print Frame, subFrame, transitionStart, pointsToRemove
	endfor
//	print "clipTransitions:", numpnts(multiDum)/framePixels
end

function/wave splitmultiDum(foldedDum)
	wave foldedDum
	
	wave multiScanOffsets = root:Packages:BS2P:CurrentScanVariables:multiScanOffsets
	string offsetNote = note(multiScanOffsets)
	
	variable scaledX = numberByKey("scaledX", offsetNote, "=", ";")
	variable scaledY = numberByKey("scaledY", offsetNote, "=", ";")
	variable pixelsPerLine = numberByKey("pixels", offsetNote, "=", ";")
	variable lines = numberByKey("lines", offsetNote, "=", ";")
//	NVAR scaledX = root:Packages:BS2P:CurrentScanVariables:scaledX
//	NVAR scaledY = root:Packages:BS2P:CurrentScanVariables:scaledY
//	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
//	NVAR totalLines =  root:Packages:BS2P:CurrentScanVariables:totalLines 
//	NVAR displayPixelSize = root:packages:bs2p:currentScanVariables:displayPixelSize
	
	variable displayPixelSize = scaledX / pixelsPerLine

	variable subWindows = dimsize(multiScanOffsets,0)//; print "subWIndows = ", subWindows
	variable subRows = dimsize(foldedDum,0)//; print "subRows = ", subRows
	variable subCols = dimsize(foldedDum,1)//;print "subCols = ", subCOls
	variable subFrames = dimsize(foldedDum,2) / subWindows//; print "subFrames = ", subFrames
	
	imagestats/g={0,(subWindows-1),0,0}/m=1 multiScanOffsets
	
	variable kineticMinX = v_min
	variable kineticMaxX = v_max
	imagestats/g={0,(subWindows-1),1,1}/m=1 multiScanOffsets
	variable kineticMinY = v_min
	variable kineticMaxY = v_max
	
	variable kineticWidth = ((kineticMaxX+scaledX) - kineticMinX)
	variable kineticHeight = ((kineticMaxY+scaledY) - kineticMinY)
	variable kineticPixelWidth = ceil(kineticWidth / displayPixelSize)
	variable kineticPixelHeight = ceil(kineticHeight / displayPixelSize)
	
	make/free/o/n=(kineticPixelWidth, kineticPixelHeight) multiKinetic = 0
	
	setScale/P x, kineticMinX, displayPixelSize, "m", multiKinetic
	setScale/P y, kineticMinY, displayPixelSize, "m", multiKinetic
	
	variable i
	for(i=0; i < subWindows; i += 1)
		variable leftPoint = (multiScanOffsets[i][0] - DimOffset(multiKinetic, 0))/DimDelta(multiKinetic,0)//; print "leftPoint =", leftPoint
		variable bottomPoint = (multiScanOffsets[i][1] - DimOffset(multiKinetic, 1))/DimDelta(multiKinetic,1)//; print "bottomPoint =", bottomPoint
		
		variable rightPoint = leftPoint + (pixelsPerLine-1) //; print "rightPoint =", rightPoint
		variable topPoint =  bottomPoint + (lines-1) // ceil(scaledY/DimDelta(multiKinetic,1))+bottomPoint//; print "topPoint =", topPoint
		make/o/n=(subRows,subCols,subFrames) subWindow = foldedDum[p][q][((r*subWIndows)+i)]
		multiKinetic[leftPoint,rightPoint][bottomPoint,topPoint][] = subWIndow[p-leftPoint][q-bottomPoint][r]	
	endfor
	
	return multiKinetic
end





