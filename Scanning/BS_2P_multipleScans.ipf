#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function makeMultiPanel()
	newPanel/ext=0/host=kineticWindow as "testWindow"
	
	Button BS_2P_recalcMulti title="Recalc",fColor=(0,0,65535), fstyle=1,proc=BS_2P_createMultiButton, valueColor=(65535,65535,65535)
	
	Button BS_2P_multiKineticSeries title="Kinetic", fColor=(2,39321,1), fstyle=1

	Button BS_2P_multiAbort title="Abort",fColor=(65535,16385,16385), fstyle=1,proc=BS_2P_abortButtonProc_2
	
	Button BS_2P_multiVideo title="Video", fColor=(2,39321,1), fstyle=1, proc=BS_2P_multiVideoButton

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
	updateScanParamsFromMarquee()
	marquee2Box()
//	makeFirstScanWindow()
	make/n=(1,2)/o root:Packages:BS2P:CurrentScanVariables:multiScanOffsets
	wave multiScanOffsets = root:Packages:BS2P:CurrentScanVariables:multiScanOffsets
	NVAR X_offset = root:Packages:BS2P:CurrentScanVariables:X_Offset
	NVAR Y_offset = root:Packages:BS2P:CurrentScanVariables:Y_Offset
	multiScanOffsets[0][0] = X_Offset
	multiScanOffsets[0][1] = Y_Offset 
	cursor /h=1 /I a kineticSeries 0, 0
	setWindow kineticWindow hook(mvCrsr)=multiScansHook
end

function marquee2Box()
	getmarquee/K left, bottom
	SetDrawLayer/W=kineticWindow userfront
	SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65280,65280,0),fillpat= 0
	DrawRect v_left,v_top,v_right,v_bottom
end


function multiScansHook(s)    //This is a hook for the mousewheel movement in MatrixExplorer
	STRUCT WMWinHookStruct &s

	NVAR X_offset = root:Packages:BS2P:CurrentScanVariables:X_Offset
	NVAR Y_offset = root:Packages:BS2P:CurrentScanVariables:Y_Offset
	NVAR scaledX =  root:Packages:BS2P:CurrentScanVariables:scaledX
	NVAR scaledY = root:Packages:BS2P:CurrentScanVariables:scaledY
	
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
					DrawRect X_offset,yImage + (scaledY/2),xImage + (scaledX/2), Y_offset
					dowindow/F kineticWindow				
				break

				case 13:	//r
					cursor/k a
					CreateMultiScan()
				break
			endswitch
		break
	endswitch
end


function CreateMultiScan()
	NVAR scaledX =  root:Packages:BS2P:CurrentScanVariables:scaledX
	NVAR scaledY = root:Packages:BS2P:CurrentScanVariables:scaledY	
	NVAR X_offset = root:Packages:BS2P:CurrentScanVariables:X_Offset
	NVAR Y_offset = root:Packages:BS2P:CurrentScanVariables:Y_Offset
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
	NVAR lineTime = root:Packages:BS2P:CurrentScanVariables:lineTime
	NVAR lineSpacing = root:Packages:BS2P:CurrentScanVariables:lineSpacing
	NVAR frames = root:Packages:BS2P:CurrentScanVariables:frames
	variable Lines = ceil(ScaledY/lineSpacing)
	NVAR dwellTime = root:Packages:BS2P:CurrentScanVariables:dwellTime


	wave multiScanOffsets = root:Packages:BS2P:CurrentScanVariables:multiScanOffsets
	wave dum = root:Packages:BS2P:CurrentScanVariables:dum
	wave runx = root:Packages:BS2P:CurrentScanVariables:runx
	wave runy = root:Packages:BS2P:CurrentScanVariables:runy
	
	variable maxSlopeBetweenRegions =  3000 // Volts / ms

	X_offset = multiScanOffsets[0][0]
	Y_offset = multiScanOffsets[0][1]
	makeUnscaledXRaster(lines, pixelsPerLine, lineTime)
	makeUnscaledYRaster(lines, pixelsPerLine, lineTime)
	scaleRunX()
	scaleRunY()
	duplicate/o runx root:Packages:BS2P:CurrentScanVariables:multiX
	duplicate/o runy root:Packages:BS2P:CurrentScanVariables:multiY
	wave multiX = root:Packages:BS2P:CurrentScanVariables:multiX
	wave multiY = root:Packages:BS2P:CurrentScanVariables:multiY	
	Note/K multiX, "frameTime="+num2str(dimDelta(runx,0) * dimSize(runx,0))+","
	Note/K multiY, "frameTime="+num2str(dimDelta(runy,0) * dimSize(runy,0))+","
	Note/NOCR multiX, "transitionTimes="
	Note/NOCR multiY, "transitionTimes="
	variable i
	for(i=1; i<dimsize(multiScanOffsets,0); i += 1)
		X_offset = multiScanOffsets[i][0]
		Y_offset = multiScanOffsets[i][1]
		makeUnscaledXRaster(lines, pixelsPerLine, lineTime)
		makeUnscaledYRaster(lines, pixelsPerLine, lineTime)
		scaleRunX()
		scaleRunY()
		
		variable lastXPos = multiX[numpnts(multiX)-1]
		variable lastYPos = multiy[numpnts(multiY)-1]
		variable nextXpos = runx[0]
		variable nextYpos = runy[0]
		
		addMultiTransition(lastXPos, lastYPos, nextXpos, nextYpos, maxSlopeBetweenRegions)
		concatenate/NP {runx}, multiX
		concatenate/NP {runy}, multiY
	endfor

	lastXPos = multiX[numpnts(multiX)-1]
	nextXpos = multiX[0]
	lastYPos = multiY[numpnts(multiY)-1]
	nextYpos = multiY[0]
	addMultiTransition(lastXPos, lastYPos, nextXpos, nextYpos, maxSlopeBetweenRegions)
	
	variable totalScanTime = dimDelta(multiX,0) * dimSize(multiX, 0) * frames
	
	redimension/n=( totalScanTime/dwellTime )  dum
//	SetScale/I x 0,totalScanTime,"s", dum
		
end

function displayMultiDums(kineticSeries,multiOffsets, foldedDum, xWidth, yHeight)
	wave multiOffsets, kineticSeries, foldedDum
	variable xWidth, yHeight
	
	variable subWindows = dimsize(multiOffsets,0)//; print "subWIndows = ", subWindows
	variable subRows = dimsize(foldedDum,0)//; print "subRows = ", subRows
	variable subCols = dimsize(foldedDum,1)//;print "subCols = ", subCOls
	variable subFrames = dimsize(foldedDum,2) / subWindows//; print "subFrames = ", subFrames
	
	kineticSeries = nan
	variable i
	for(i=0; i < subWindows; i += 1)
		variable leftPoint = (multiOffsets[i][0] - DimOffset(kineticSeries, 0))/DimDelta(kineticSeries,0)//; print "leftPoint =", leftPoint
		variable bottomPoint = (multiOffsets[i][1] - DimOffset(kineticSeries, 1))/DimDelta(kineticSeries,1)//; print "bottomPoint =", bottomPoint
		
		variable rightPoint = ceil(xWIdth/DimDelta(kineticSeries,0))+leftPoint//; print "rightPoint =", rightPoint
		variable topPoint =  ceil(yHeight/DimDelta(kineticSeries,1))+bottomPoint//; print "topPoint =", topPoint
		make/o/free/n=(subRows,subCols,subFrames) subWindow = foldedDum[p][q][((r*subWIndows)+i)]
		kineticSeries[leftPoint,rightPoint][bottomPoint,topPoint][] = subWIndow[p-leftPoint][q-bottomPoint][r]	
	endfor
end

function addMultiTransition(lastXPos, lastYPos, nextXpos, nextYpos, maxSlopeBetweenRegions)
	variable maxSlopeBetweenRegions
	variable lastXPos,lastYPos, nextXpos, nextYpos
	
	wave multiX = root:Packages:BS2P:CurrentScanVariables:multiX
	wave multiY = root:Packages:BS2P:CurrentScanVariables:multiY
	variable dX = nextXpos- lastXpos
	variable dY = nextYpos- lastYpos
	variable dtX = dimDelta(multiX,0)
	variable dtY = dimDelta(multiY,0)
	
	variable xTransitionTime = abs(dx / maxSlopeBetweenRegions)
	variable yTransitionTime = abs(dy / maxSlopeBetweenRegions)
	variable transitionTime
	
	if(xTransitionTime > yTransitionTime)
		transitionTime = xTransitionTime
	else
		transitionTime = yTransitionTime
	endif
	
	variable numPntsToAddToX = ceil(transitionTime / dtX)
	variable numPntsToAddToY = ceil(transitionTime / dtY)
	
	
	make/o/n=(numPntsToAddToX) xTransition = ( p*dtX*(dX / transitionTime) )+lastXPos
	make/o/n=(numPntsToAddToY) yTransition = ( p*dtY*(dY / transitionTime) )+lastYPos
	copyScales/P multiX, xTransition
	copyScales/P multiY, yTransition

	concatenate/NP {xTransition}, multiX
	concatenate/NP {yTransition}, multiY
	
	Note/NOCR multiX, num2str(dimDelta(xTransition,0) * dimSize(xTransition,0))+";"
	Note/NOCR multiY, num2str(dimDelta(yTransition,0) * dimSize(yTransition,0))+";"

end


function clipTransitionsFromMultiDum(multiDum)
	wave multiDum
	wave multiX = root:Packages:BS2P:CurrentScanVariables:multiX
	wave multiY = root:Packages:BS2P:CurrentScanVariables:multiY
	
	string transitionTimes = stringByKey("transitionTimes",note(multiX), "=", ",")
	variable frameTime = numberByKey("frameTime",note(multiX), "=", ",")
	variable i
	for(i=0; i<itemsInList(transitionTimes); i+=1)
		variable transitionTime = str2num(stringFromList(i, transitionTimes))
		variable transitionStart = x2pnt(multiDum, i * frameTime) + 1
		variable pointsToRemove = ceil(transitionTime / DimDelta(multiDum,0))
		deletePoints transitionStart, pointsToRemove, multiDum
	endfor
end

function clipTransitionsUnfoldedMultiDum(multiDum)
	wave multiDum
	wave multiX = root:Packages:BS2P:CurrentScanVariables:multiX
	wave multiY = root:Packages:BS2P:CurrentScanVariables:multiY
	NVAR frames = root:Packages:BS2P:CurrentScanVariables:frames
	
	
	string transitionTimes = stringByKey("transitionTimes",note(multiX), "=", ",")
	variable totalTransitions = itemsInList(transitionTimes)
	Make/O/N=(totalTransitions) transitionTimesWave = str2num(StringFromList(p,transitionTimes))
	
	variable subWindowTime = numberByKey("frameTime",note(multiX), "=", ",")
	make/o/n=(totalTransitions * frames) frameTimer = transitionTimesWave[(mod(p,totalTransitions))]
	variable cumulateTransitions = 0
	variable i
	for(i=0; i<(numpnts(frametimer)); i+=1)
		variable transitionTime = frameTimer[i] //str2num(stringFromList(i, transitionTimes))
		variable transitionStart = x2pnt(multiDum, ((i+1) * subWindowTime) + cumulateTransitions)// + 1
		variable pointsToRemove = ceil(transitionTime / DimDelta(multiDum,0))
		multiDum[transitionStart, transitionStart+pointsToRemove] = -1; print transitionTime, transitionStart, transitionStart+pointsToRemove
		cumulateTransitions += transitionTime
	endfor
//	wavetransform zapnans multiDum
end






