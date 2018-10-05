#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function Spirals(spiralx, spiraly)
	wave spiralx, spiraly
	spiralx = p/numpnts(spiralx)*sin(10*log(p)); 
	spiraly = p/numpnts(spiraly)*cos(10*log(p))
end

function BS_rasterByDwellTime(ScaledX,ScaledY,X_Offset,Y_Offset, scanOutFreq,dwellTime, lineSpacing,frames)
	variable ScaledX,ScaledY,X_Offset,Y_Offset 	//these should all be microns or milliseconds from "Full-Frame" image
	variable scanOutFreq	// kHz resolution of the scan output voltage
	variable dwellTime	//how long to stay on each pixel
	variable lineSpacing 		// determines distance between lines
	variable frames	//for movies

///////////////////  STORED IN CalibrationVariables ///////////////
	NVAR scaleFactor = root:Packages:BS2P:CalibrationVariables:scaleFactor	//Need a scale factor from Bruno (�m / volt)	---Is the same for X and Y  *********CalibrationVariables************
	NVAR spotSize = root:Packages:BS2P:CalibrationVariables:spotSize	//this is silly?
	
/////////////////// Calculate Frames ///////////////
	NVAR lineTime = root:Packages:BS2P:CurrentScanVariables:lineTime
//	variable lineTime	= (ScaledX/spotSize)*DwellTime //ms per line
	variable totalLines = ceil(ScaledY/lineSpacing)
	variable scanFrameTime = totalLines*lineTime	//sec
	
	
/////////////////// These might be implemented in v2.0 but for now all scans are symmetrical forward and backward ///////////////	
	variable FlybackFraction = 1/2		// How much of the total X_Scan is Flyback? (lower numbers = faster scans)
	variable ScanBack = 1 //Scan on the way back or not?
	if(scanBack==0)
		scanFrameTime *= (1/FlybackFraction)	//ms
	endif

/////////////////// If it's a movie then scan there and back	/////////////////////////////////////
	variable comeBack 
	if(frames>1)
		comeBack = 2
	else
		comeback = 1
	endif

	make/o/n=(scanOutFreq*scanFrameTime*comeBack)  root:Packages:BS2P:CurrentScanVariables:runx, root:Packages:BS2P:CurrentScanVariables:runy	//ms
	wave runx = root:Packages:BS2P:CurrentScanVariables:runx
	wave runy = root:Packages:BS2P:CurrentScanVariables:runy
	variable linePeriod = pi/numpnts(runx)*totalLines
	if(frames>1)
		lineperiod *= 2
	endif
//	SetScale/I x 0,(scanFrameTime*comeBack/1000),"s", runx
//	SetScale/I x 0,(scanFrameTime/1000),"s", runy
	SetScale/p x 0,(1/scanOutFreq),"s", runx
	SetScale/p x 0,(1/scanOutFreq),"s", runy

//	print Scaledx, "X", ScaledY, "�m  -->", ScaledY/lineSpacing, "lines with pixel size of", lineSpacing, "�m"
//	print "in", scanTotalTime, "ms"
//	print "with ", lineTime,"ms/line"
		
	if(ScanBack)	
		variable scanShape = 0.5
	else
		scanShape = (1-FlybackFraction)
		lineperiod *= 2
	endif		
	

	
	/////////////////////Make an unscaled runx and a runy
	runx = sawtooth(p*linePeriod) * ((scanShape - sawtooth(p*linePeriod))>=0) / scanShape  +  sawtooth(-p*linePeriod) * ((1-scanShape) - (sawtooth(-p*linePeriod)) >=0) / (1-scanShape)
			//above is an overly complicated version of (2/pi)*asin(sin(2*pi/Period*p)) to eventually allow for different flyback timings in 2.0
	runy = floor(p/(numpnts(runy))*(totalLines))
	if(frames > 1)
		duplicate/o runy root:Packages:BS2P:CurrentScanVariables:runy_back; wave runy_back = root:Packages:BS2P:CurrentScanVariables:runy_back
		runy_back *= (-1)
		runy_back += totalLines-1
		concatenate/np {runy_back}, runy
		killwaves runy_back
	endif
	/////////////////////Scale it to Microns 
	runx *= ScaledX; runx += x_offset
	runy *= lineSpacing; runy += y_offset
	/////////////////////Scale it to Volts
//	runx /= ScaleFactor
	runy /= ScaleFactor

	
end

Function/wave BS_2P_UpdateVariables()

		NVAR dwellTime =root:Packages:BS2P:CurrentScanVariables:dwellTime
		NVAR displaySpeed = root:Packages:BS2P:CurrentScanVariables:displaySpeed
		NVAR scaledX = root:Packages:BS2P:CurrentScanVariables:scaledX
		NVAR scaledY = root:Packages:BS2P:CurrentScanVariables:scaledY
		NVAR X_Offset = root:Packages:BS2P:CurrentScanVariables:X_Offset
		NVAR Y_Offset = root:Packages:BS2P:CurrentScanVariables:Y_Offset
		NVAR scanOutFreq = root:Packages:BS2P:CurrentScanVariables:scanOutFreq
		NVAR AcquisitionFrequency = root:Packages:BS2P:CurrentScanVariables:AcquisitionFrequency
		NVAR lineTime = root:Packages:BS2P:CurrentScanVariables:lineTime
		NVAR frames = root:Packages:BS2P:CurrentScanVariables:Frames
		NVAR displayFrameHz = root:Packages:BS2P:CurrentScanVariables:displayFrameHz
		NVAR displayFrameTime = root:Packages:BS2P:CurrentScanVariables:displayFrameTime
		NVAR displayTotalTime = root:Packages:BS2P:CurrentScanVariables:displayTotalTime
		NVAR KCT = root:Packages:BS2P:CurrentScanVariables:KCT
		NVAR frames = root:Packages:BS2P:CurrentScanVariables:frames
		NVAR lineSpacing = root:Packages:BS2P:CurrentScanVariables:lineSpacing
		NVAR scanFrameTime = root:Packages:BS2P:CurrentScanVariables:scanFrameTime
		NVAR spotSize = root:Packages:BS2P:CalibrationVariables:spotSize
		NVAR freqLimit =  root:Packages:BS2P:CalibrationVariables:freqLimit
		NVAR scanLimit = root:Packages:BS2P:CalibrationVariables:scanLimit
		NVAR scaleFactor = root:Packages:BS2P:CalibrationVariables:scaleFactor
		NVAR displayPixelSize = root:Packages:BS2P:CurrentScanVariables:displayPixelSize
		NVAR samplesPerPixel = root:Packages:BS2P:CurrentScanVariables:samplesPerPixel
		NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
		NVAR pixelShift = root:Packages:BS2P:CalibrationVariables:pixelShift
		NVAR totalLines = root:Packages:BS2P:CurrentScanVariables:totalLines
		NVAR ePhysRec = root:Packages:BS2P:CurrentScanVariables:ePhysRec
		NVAR ePhysFreq = root:Packages:BS2P:CurrentScanVariables:ePhysFreq
		NVAR fixedDwell = root:Packages:BS2P:CurrentScanVariables:fixedDwell
		
		displayPixelSize = scaledX / pixelsPerLine
		totalLines = ceil(ScaledY / displayPixelSize)
	
//		print pixelSHift
		
//		samplesPerPixel /= 100	//convert samples per pixel to kHz
		
		displaypixelSize = scaledX / pixelsPerLine
		displaypixelSize = displaypixelSize < 0.25e-6 ? 0.25e-6 : displayPixelSize
//		displaypixelSize = 0.25	//start with smallest pixel size and later increase it (if needed) to reduce digitization to 200 kHz
		


		variable X_VoltageOffset = X_offset / scaleFactor
//		print x_voltageOffset
		variable Y_VoltageOffset = Y_offset / scaleFactor
		
//		BS_2P_saneScanCheck(scaledX, scaledY, X_VoltageOffset, Y_VoltageOffset)
		
		if(fixedDwell)
			lineTime = pixelsPerLine * dwellTime
			print lineTime
		endif
/////////////	Removed this in order to fix scanning frequency  (bs 141118)	///////////////////////
//		lineTime = (ScaledX/spotSize)*DwellTime		//limit the scan frequency		///
//		if(lineTime < (1/(2*freqLimit)))												///
//			dwellTIme = 1/(2*freqLimit)/(scaledX/spotSize)							///
//			lineTime = (ScaledX/spotSize)*DwellTime								///
//		endif																	///
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		if((lineTime / pixelsPerLine) < 5e-9)
			abort "Can't digitize this fast.  Decrease line speed or pixels per line"
		endif
//		if((((scaledX / displayPixelSize) / lineTime ) * samplesPerPixel) > 190000)	//samples per pixel in kHz
//			do
//				displayPixelSize += 0.01
//			while((((scaledX / displayPixelSize) / lineTime ) * samplesPerPixel) > 190000)
//		endif
//		acquisitionFrequency = (((scaledX / displayPixelSize) / lineTime ) * samplesPerPixel)	//10 points points per pixel?
		
		acquisitionFrequency = (pixelsPerLine) / lineTime
//		print acquisitionFrequency
		displayPixelSize = scaledX / pixelsPerLine
		lineSpacing = displayPixelSize
		
/////////////	Added this in order to fix scanning frequency  (bs 141118)	///////////////////////
		dwelltime = lineTime/pixelsPerLine		//seconds						///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		scanFrameTime = totalLines*lineTime
		KCT = scanFrameTime	//update this if you put in a pause between frames
		
		displayFrameHz = 1 / (scanFrameTime)
		displayTotalTime = (((scanFrameTime) ) * frames)
		
	
		variable xPixels = ceil(scaledX/displayPixelSize)
end		

function/wave BS_2P_CreateScan()
		NVAR lineTime = root:Packages:BS2P:CurrentScanVariables:lineTime
		NVAR frames = root:Packages:BS2P:CurrentScanVariables:frames
		NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
		NVAR totalLines = root:Packages:BS2P:CurrentScanVariables:totalLines
		NVAR ePhysRec = root:Packages:BS2P:CurrentScanVariables:ePhysRec
		NVAR ePhysFreq = root:Packages:BS2P:CurrentScanVariables:ePhysFreq
		NVAR displayTotalTime = root:Packages:BS2P:CurrentScanVariables:displayTotalTime
		
		makeRasters(lineTime,frames)//, pixelShift)
		
//		BS_2P_saneScanCheck(scaledX, scaledY, X_Offset, Y_Offset)
//		BS_rasterByDwellTime(ScaledX,ScaledY,X_VoltageOffset,Y_VoltageOffset, scanOutFreq,dwellTime, lineSpacing,frames)

		make/o/n=((((pixelsPerLine) * totalLines)+1))/y=4 root:Packages:BS2P:CurrentScanVariables:dum = nan	//add one because we're going to take the first derivative
		wave dum = root:Packages:BS2P:CurrentScanVariables:dum
		
		if(ePhysRec)
			make/o/n=(ePhysFreq * 1000 * displayTotalTime) root:Packages:BS2P:CurrentScanVariables:ePhysDum
			wave ePhysDum = root:Packages:BS2P:CurrentScanVariables:ePhysDum
			setScale/p x, 0, (1/(1000 *  ePhysFreq)), "s", ePhysDum
		endif
		
		variable dumDelta =  (lineTime) / (pixelsPerLine)
		SetScale/p x, 0, dumDelta , "s", dum
		BS_2P_writeScanParamsInWave(dum)
		return dum
end

Function arbitraryScan()
	updateScanParamsFromMarquee()
	BS_2P_updateVariables()
	BS_2P_CreateScan()
	BS_2P_Scan("snapshot")
	
end

Function updateScanParamsFromMarquee()
	getmarquee/k left, bottom
	wave/t boardCOnfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	variable hReflect = str2num(boardConfig[19][2])
	variable XYswitch = str2num(boardConfig[21][2])
	variable vReflect = str2num(boardConfig[20][2])
	NVAR scaledX = root:Packages:BS2P:CurrentScanVariables:scaledX
	NVAR scaledY = root:Packages:BS2P:CurrentScanVariables:scaledY
	NVAR displayPixelSize = root:Packages:BS2P:CurrentScanVariables:displayPixelSize
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
	NVAR totalLines = root:Packages:BS2P:CurrentScanVariables:totalLines
	NVAR X_Offset = root:Packages:BS2P:CurrentScanVariables:X_Offset
	NVAR Y_Offset = root:Packages:BS2P:CurrentScanVariables:Y_Offset
	

	variable scannerLeft = v_left, scannerRight = v_right, scannertop = v_top, scannerBottom = v_bottom
	
	if(XYswitch == 1)
		scannerLeft = v_bottom
		scannerRight = v_top
		scannerTop = v_right
		scannerBottom = v_left
	endif
	if(hreflect == 1 && XYswitch == 0)
		scannerLeft = v_right
		scannerRight = v_left
	elseif(hreflect == 1 && XYswitch == 1)
		scannerLeft = v_top
		scannerRight = v_bottom
	endif
	if(vreflect == 1  && XYswitch == 0)
		scannerTop = v_bottom
		scannerBottom = v_top
	elseif(vreflect == 1 && XYswitch == 1)
		scannerTop = v_left
		scannerBottom = v_right
	endif	

	X_Offset = scannerLeft
	Y_offset = scannerBottom
	scaledX = scannerRight - scannerLeft
	scaledY = scannerTop - scannerBottom

	displayPixelSize = scaledX / pixelsPerLine
	totalLines = ceil(ScaledY / displayPixelSize)	
//	print scannerLeft, scannerBottom, scannerRight, scannerTop
//	print scaledX, scaledY
	
	
end


function BS_2P_saneScanCheck(scaledX, scaledY, X_offset, y_offset)
	variable scaledX, scaledY, X_offset, y_offset
	nvar scaleFactor = root:Packages:BS2P:CalibrationVariables:scaleFactor
	nvar scanLimit = root:Packages:BS2P:CalibrationVariables:scanLimit
	
	if((scaledX + x_offset) /scaleFactor > scanLimit)
		abort "This scan goes off the RIGHT side of the objective and COULD DAMAGE THE SCANNERS!  X = "+ num2str((scaledX + x_offset) /scaleFactor)+" Volts\r Limit = "+num2str(scanLimit)+ " Volts"
	elseif((x_offset / scaleFactor) < -1*scanLimit)
		abort "This scan goes off the LEFT side of the objective and COULD DAMAGE THE SCANNERS! X = "+ num2str((x_offset / scaleFactor))+" Volts\r Limit = "+num2str(scanLimit)+ " Volts"
	elseif((scaledY + y_offset) /scaleFactor > scanLimit)
		abort "This scan goes off the TOP of the objective and COULD DAMAGE THE SCANNERS!  Y = "+ num2str((scaledY + Y_offset) /scaleFactor)+" Volts\r Limit = "+num2str(scanLimit)+ " Volts"
	elseif((Y_offset / scaleFactor) < -1*scanLimit)
		abort "This scan goes off the BOTTOM of the objective and COULD DAMAGE THE SCANNERS! Y = "+ num2str((y_offset / scaleFactor))+" Volts\r Limit = "+num2str(scanLimit)+ " Volts"
	endif
end

function BS_2P_saneScanCheck2()
	wave runx = root:Packages:BS2P:CurrentScanVariables:runx
	wave runy = root:Packages:BS2P:CurrentScanVariables:runy
	nvar scanLimit = root:Packages:BS2P:CalibrationVariables:scanLimit
	
	if(wavemax(runx) > scanLimit)
		abort "This scan goes off the RIGHT side of the objective and COULD DAMAGE THE SCANNERS!  X = "+ num2str(wavemax(runx))+" Volts\r Limit = "+num2str(scanLimit)+ " Volts"
	elseif(wavemin(runx) < -1*scanLimit)
		abort "This scan goes off the LEFT side of the objective and COULD DAMAGE THE SCANNERS! X =  "+ num2str(wavemin(runx))+" Volts\r Limit = "+num2str(scanLimit)+ " Volts"
	elseif(wavemax(runy) > scanLimit)
		abort "This scan goes off the TOP of the objective and COULD DAMAGE THE SCANNERS!  Y = "+ num2str(wavemax(runy))+" Volts\r Limit = "+num2str(scanLimit)+ " Volts"
	elseif(wavemin(runy) > scanLimit)
		abort "This scan goes off the BOTTOM of the objective and COULD DAMAGE THE SCANNERS! Y ="+ num2str(wavemin(runy))+" Volts\r Limit = "+num2str(scanLimit)+ " Volts"
	endif
end

function BS_GENERATESimpleRasterScan(ScaledX,ScaledY,pixelSize,DwellTime,ScanBack,X_Offset,Y_Offset, scanFreq)
	variable ScaledX,ScaledY,pixelSize,DwellTime,X_Offset,Y_Offset 	//these should all be microns or milliseconds
	variable ScanBack //Scan on the way back or not?
	variable scanFreq	// kHz Number of points per pixel (2000 with 0.001 DwellTime = 2 MHz output)
	variable ScaleFactor = 16.7	//Need a scale factor from Bruno (�m / volt)	---Is the same for X and Y
//	variable scanResolution = (scanFreq*1000)	//Nyquest! MHz resolution of scanWaves NiDAQ S-Series Max = ?
	variable FlybackFraction = 1/2		// How much of the total X_Scan is Flyback? (lower numbers = faster scans)
	
	variable scanTotalTime = (ScaledX/pixelSize)*(ScaledY/pixelSize)*DwellTime	//ms
	if(scanBack==0)
		scanTotalTime *= (1/FlybackFraction)	//ms
	endif
	
	make/o/n=(scanFreq*1000*scanTotalTime)  runx, runy	//ms
	variable period = pi/numpnts(runx)*ScaledY/pixelSize
	
	SetScale/I x 0,scanTotalTime,"ms", runx,runy
	print Scaledx, "X", ScaledY, "�m  -->", ScaledY/pixelSize, "lines with pixel size of", pixelSize, "�m"
	print "in", scanTotalTime, "ms"
		
	if(ScanBack)	
		variable scanShape = 0.5
	else
		scanShape = (1-FlybackFraction)
		period *= 2
	endif		
	
	/////////////////////Make an unscaled runx and a runy
	runx = sawtooth(p*Period) * ((scanShape - sawtooth(p*Period))>=0) / scanShape  +  sawtooth(-p*Period) * ((1-scanShape) - (sawtooth(-p*Period)) >=0) / (1-scanShape)
			//above is an overly complicated version of (2/pi)*asin(sin(2*pi/Period*p)) to allow for different flyback timings
	runy = floor(p/(numpnts(runy))*(ScaledY/pixelSize))
//	runy /= wavemax(runy)
	/////////////////////Scale it to Microns 
	runx *= ScaledX; runx += x_offset
	runy *= pixelSize; runy += y_offset
	/////////////////////Scale it to Volts
	runx /= ScaleFactor
	runy /= ScaleFactor
end

function makeRasters(lineTime,frames)//, pixelShift)
	variable lineTime, frames//, pixelShift		//seconds
	
	wave/t boardCOnfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
	NVAR scaleFactor = root:Packages:BS2P:CalibrationVariables:scaleFactor
	NVAR X_offset = root:Packages:BS2P:CurrentScanVariables:X_offset
	NVAR Y_offset = root:Packages:BS2P:CurrentScanVariables:Y_offset
	NVAR scaledX = root:Packages:BS2P:CurrentScanVariables:scaledX
	NVAR scaledY = root:Packages:BS2P:CurrentScanVariables:scaledY
	NVAR lineSpacing = root:Packages:BS2P:CurrentScanVariables:lineSpacing
	NVAR scanLimit = root:Packages:BS2P:CalibrationVariables:scanLimit
	NVAR XYswapped = root:Packages:BS2P:CurrentScanVariables:XYswapped
	NVAR totalLines =  root:Packages:BS2P:CurrentScanVariables:totalLines
	
//	wave runy_temp = root:Packages:BS2P:CurrentScanVariables:runy_temp

	
	if((scaledX < scaledY) && (StringMatch(boardConfig[22][2], "YES")== 1) )
//		variable Lines = ceil(ScaledY/lineSpacing)
		wave runy = makeUnscaledXRaster(totalLines, pixelsPerLine, lineTime)
		wave runx = makeUnscaledYRaster(totalLines, pixelsPerLine, lineTime)
		makeRunXReturnHome()
		makeRunYReturnHome()
		
		/////////////////////Scale it to Microns 
		runy *= Scaledy; runy += y_offset
		runx *= lineSpacing; runx += x_offset
	
		/////////////////////Scale it to Volts
		runx /= ScaleFactor
		runy /= ScaleFactor
	
		XYswapped = 1
	else
//		Lines = ceil(ScaledY/lineSpacing)
		wave runx = makeUnscaledXRaster(totalLines, pixelsPerLine, lineTime)
		wave runy = makeUnscaledYRaster(totalLines, pixelsPerLine, lineTime)
		makeRunXReturnHome()
		makeRunYReturnHome()
		
		scaleRunX(runx, x_offset, scaledX)
		scaleRunY(runy, y_offset, scaledY, lineSpacing)
		
		XYswapped = 0
	endif
	
	limitVoltage(runX)
	limitVoltage(runY)
	BS_2P_saneScanCheck2()
	
//	NVAR totalLines = root:Packages:BS2P:CurrentScanVariables:totalLines
//	totalLines = lines
end

function/wave scaleRunX(runx, x_offset, scaledX)
	wave runx
	variable x_offset, scaledX

//	NVAR X_offset = root:Packages:BS2P:CurrentScanVariables:X_offset
//	NVAR scaledX = root:Packages:BS2P:CurrentScanVariables:scaledX
	NVAR scaleFactor = root:Packages:BS2P:CalibrationVariables:scaleFactor
//	wave runx =   root:Packages:BS2P:CurrentScanVariables:runx

	/////////////////////Scale it to Microns 
	runx *= ScaledX; runx += x_offset
	/////////////////////Scale it to Volts
	runx /= ScaleFactor
	
	return runx
end

function/wave scaleRunY(runy, y_offset, scaledY, lineSpacing)
	wave runy
	variable y_offset, scaledY, lineSpacing
//	NVAR Y_offset = root:Packages:BS2P:CurrentScanVariables:Y_offset
//	NVAR scaledY = root:Packages:BS2P:CurrentScanVariables:scaledY
	NVAR scaleFactor = root:Packages:BS2P:CalibrationVariables:scaleFactor
//	NVAR lineSpacing = root:Packages:BS2P:CurrentScanVariables:lineSpacing
//	wave runy =   root:Packages:BS2P:CurrentScanVariables:runy
	/////////////////////Scale it to Microns 
	runy *= lineSpacing; runy += y_offset
	
	/////////////////////Scale it to Volts
	runy /= ScaleFactor
	
	return runy
end

function/wave makeUnscaledYRaster(lines, pixelsPerLine, lineTime)	//creates steps of Voltage -- amplitdue from 0 to 1
	variable lines, pixelsPerLine, lineTime
	NVAR dwellTime = root:Packages:BS2P:CurrentScanVariables:dwellTime
	make/d/n=(lines*(pixelsPerLine))/o root:Packages:BS2P:CurrentScanVariables:runy = floor(p/(lines*(pixelsPerLine))*(lines))
	wave runy = root:Packages:BS2P:CurrentScanVariables:runy
	SetScale/P x 0,dwellTime,"s", runy
	return runy
end

function/wave makeUnscaledXRaster(lines, pixelsPerLine, lineTime)		//creates a sawtooth of Voltage -- amplitude 0 to 1
	variable lines, pixelsPerLine, lineTime
	NVAR dwellTime = root:Packages:BS2P:CurrentScanVariables:dwellTime
	make/d/n=(lines*(pixelsPerLine))/o root:Packages:BS2P:CurrentScanVariables:runx = abs(sawtooth(p/(pixelsPerLine)*pi)-0.5)*(-2)+1
	wave runx = root:Packages:BS2P:CurrentScanVariables:runx
	SetScale/P x 0,dwellTime,"s", runx
	return runx
end

function/wave makeRunXReturnHome()			//Sacrifices last line to make sure x Galvo returns to starting point
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
	wave runx =  root:Packages:BS2P:CurrentScanVariables:runx
	runx[numpnts(runx)-(pixelsPerLine),] = runx[numpnts(runx)-1] > 0.5 ? 0 : runx
	return runX
end

function/wave makerunYReturnHome()			//Sacrifices last line to make sure y Galvo returns to starting point
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
	wave runy =  root:Packages:BS2P:CurrentScanVariables:runy
	runy[numpnts(runy)-(pixelsPerLine),] =  runy[numpnts(runy)-(pixelsPerLine+1)] -  ((runy[numpnts(runy)-(pixelsPerLine+1)] / pixelsPerLine) * (p - (numpnts(runy)-(pixelsPerLine))))
	return runY
end

function limitVoltage(inputWave)
	wave inputWave
	
	variable maxX = wavemax(inputWave), minX = wavemin(inputWave)
	NVAR scanLimit = root:Packages:BS2P:CalibrationVariables:scanLimit
	
	variable limited
	if(maxX > scanLimit)
		inputWave -= minX
		variable newMax = waveMax(inputWave)
		inputWave /= newMax
		inputWave *= (scanLimit -minX)
		inputWave += minX
		maxX = wavemax(inputWave)
		limited = 1
	endif
	
	if(minX < -scanLimit)
		inputWave -= minX
		newMax = waveMax(inputWave)
		inputWave /= newMax
		inputWave *= (maxX + scanLimit)
		inputWave -= scanLimit
		limited = 1
	endif	
	
	return limited
end	