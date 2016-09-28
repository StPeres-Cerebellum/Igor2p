#pragma rtGlobals=3		// Use modern global access method and strict wave access.



function multipleScans()
	getmarquee left, bottom
	SetDrawLayer/W=$S_MarqueeWin/K userfront
	marquee2Box()
	makeFirstScanWindow()
end

function marquee2Box()
	getmarquee/K left, bottom
	SetDrawLayer/W=$s_marqueewin userfront
	SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65280,65280,0),fillpat= 0
	DrawRect v_left,v_top,v_right,v_bottom
	
//	variable/g root:Packages:BS2P:CurrentScanVariables:multipleScanWidth = abs(v_right - v_left)
//	variable/g root:Packages:BS2P:CurrentScanVariables:multipleScanHeight = abs(v_top - v_bottom)
	
end

function makeFirstScanWindow()
	updateScanParamsFromMarquee()
	BS_2P_updateVariables()
	NVAR scaledY = root:Packages:BS2P:CurrentScanVariables:scaledY
	NVAR scaledX = root:Packages:BS2P:CurrentScanVariables:scaledX
	NVAR lineSpacing = root:Packages:BS2P:CurrentScanVariables:lineSpacing
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
	NVAR lineTime = root:Packages:BS2P:CurrentScanVariables:lineTime
	variable Lines = ceil(ScaledY/lineSpacing)
	wave runx = makeUnscaledXRaster(lines, pixelsPerLine, lineTime)
	wave runy = makeUnscaledYRaster(lines, pixelsPerLine, lineTime)
	scaleRunX()
	scaleRunY()
	
	duplicate/o runx root:Packages:BS2P:CurrentScanVariables:multiX
	duplicate/o runy root:Packages:BS2P:CurrentScanVariables:multiY
	makeAnotherScanWIndow()
end

function makeAnotherScanWIndow()
	cursor /h=1 /I a kineticSeries 0, 0
	setWindow kineticWindow hook(mvCrsr)=moreScansHook
end

function moreScansHook(s)    //This is a hook for the mousewheel movement in MatrixExplorer
	STRUCT WMWinHookStruct &s
	NVAR scaledX =  root:Packages:BS2P:CurrentScanVariables:scaledX
	NVAR scaledY = root:Packages:BS2P:CurrentScanVariables:scaledY	
	NVAR X_offset = root:Packages:BS2P:CurrentScanVariables:X_Offset
	NVAR Y_offset = root:Packages:BS2P:CurrentScanVariables:Y_Offset
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
	NVAR lineTime = root:Packages:BS2P:CurrentScanVariables:lineTime
	NVAR lineSpacing = root:Packages:BS2P:CurrentScanVariables:lineSpacing
	
	variable Lines = ceil(ScaledY/lineSpacing)
	wave multiX = root:Packages:BS2P:CurrentScanVariables:multiX
	wave multiY = root:Packages:BS2P:CurrentScanVariables:multiY

	
	switch(s.eventCode)
		case 5:

			string cursorInfo = csrInfo(A)
			wave imageName = CsrWaveRef(A)

			variable maxSlopeBetweenRegions =  5  //      um / sec
			
			variable xpoint = numberByKey("POINT", cursorInfo)
			variable ypoint = numberByKey("YPOINT", cursorInfo)
			variable xImage = (xPoint * DimDelta(imageName, 0)  +  DimOffset(imageName, 0))
			variable yImage = (yPoint * DimDelta(imageName, 1)  +  DimOffset(imageName, 1))
			//variable/g root:Packages:BS2P:CurrentScanVariables:
			X_Offset = xImage - (scaledX/2)//; print x_offset
			Y_offset = yImage - (scaledY/2)
			SetDrawLayer userfront
			SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65280,65280,0),fillpat= 0
			DrawRect X_offset,yImage + (scaledY/2),xImage + (scaledX/2), Y_offset
			wave runy = makeUnscaledXRaster(lines, pixelsPerLine, lineTime)
			wave runx = makeUnscaledYRaster(lines, pixelsPerLine, lineTime)
			scaleRunX()
			scaleRunY()
			variable lastXPos = multiX[numpnts(multiX)-1]
			variable lastYPos = multiy[numpnts(multiY)-1]
			variable nextXpos = runx[0]
			variable nextYpos = runy[0]
			
			variable dY = nextXpos - lastXpos
			variable dX = nextYpos - lastYpos
			variable dtX = dimDelta(multiX,0)
			variable dtY = dimDelta(multiX,0)
			
			variable numPntsToAddToX = abs(dx / (maxSlopeBetweenRegions * dtX))
			variable numPntsToAddToY = dy / (maxSlopeBetweenRegions * dtY)
			if(dx < 0)
				maxSlopeBetweenRegions *= -1
			endif
			make/free/o/n=(numPntsToAddToX) xTransition = (p*dtX*maxSlopeBetweenRegions)+lastXPos
			concatenate/NP {xTransition}, multiX
			concatenate/NP {runx}, multiX
			
//			print xImage, yImage
//			print "-----------------"
		break
		case 11:
			print s.keycode
			switch(s.keycode)
				case 13:	//r
					stopAddingWindows()
				break
			endswitch
	endswitch
end

function stopAddingWindows()
	setWindow kineticWindow hook(mvCrsr)=$""
	cursor /k a
end



