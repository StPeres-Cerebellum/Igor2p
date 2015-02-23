#pragma rtGlobals=3		// Use modern global access method and strict wave access.



function testNewDraw_old(dum, runx, runy)
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

	variable imageOffset = scanLimit * scaleFactor
	variable xPixels = ceil(scaledX/displayPixelSize), yLines = ceil(scaledY/displayPixelSize)
	
	make/o/n=(xPixels,yLines,frames) root:Packages:BS2P:CurrentScanVariables:drawnImage = 0
	wave drawnImage = root:Packages:BS2P:CurrentScanVariables:drawnImage
	SetScale/P x X_offset,displayPixelSize,"µm", drawnImage
	SetScale/P y Y_offset,displayPixelSize,"µm", drawnImage
	
	
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////HERE CAN CREATE RUNX AND RUNY FROM VARIABLES STORED IN DUM WAVE IF NEED BE///////////
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////This function could be optimized by combining everything below into one (huge) line to avoid creating more waves
	duplicate/o runx runx_microns;duplicate/o runy runy_microns;;duplicate/o dum frameNums
	runx_microns *= scaleFactor; runy_microns *= scaleFactor
	runx_microns -= x_offset; 	runy_microns -= y_offset
	runx_microns += imageOffset; 	runy_microns += imageOffset
	
	frameNums = floor(frames*p/numpnts(dum))
	variable i, frameNum, dumTime, xMicronsAtDumTime, yMicronsAtDumTime, DumPnt2ScanPnt, scanTime
	duplicate/o dum dum2GalvoPoint, dum2GalvoTime, dumXMicrons, DumYMicrons
	dum2GalvoPoint =p-(framenums[p]*frames)	///these are points numbers
	dum2Galvotime = (pnt2x(dum2GalvoPoint, p) - pixelShift)	//convert points to times
	dum2galvotime = dum2galvotime < 0 ? 0 : dum2galvotime	//remove negative times
	dumXMicrons = runx_microns(dum2galvotime[p])
	dumYMicrons = runy_microns(dum2galvotime[p])
		
//	drawnImage[x2pnt(drawnImage, dumXMicrons[p])][x2pnt(drawnImage, dumYMicrons[p])][frameNums[p]] += dum[p]
	variable pixelX
	variable pixelY
	for(i=0; i<numpnts(dum); i+=1)
		pixelX = x2pnt(drawnImage, dumXMicrons[i]) > (dimsize(drawnImage, 0)-1) ? (dimsize(drawnImage, 0)-1) :  x2pnt(drawnImage, dumXMicrons[i])
		pixelY = x2pnt(drawnImage, dumyMicrons[i]) > (dimsize(drawnImage, 1)-1) ? (dimsize(drawnImage, 1)-1) :  x2pnt(drawnImage, dumyMicrons[i])
		drawnImage[pixelX][pixelY][frameNums[i]] += dum[i]
	endfor
	
//	killwaves  dum2GalvoPoint, dum2GalvoTime, dumXMicrons, DumYMicrons, runx_microns, runy_microns
		
end

function testCounting()

	make/o/n=10 buffer
//	fDAQmx_CTR_Finished("dev2", 0)
//	fDAQmx_CTR_Finished("dev2", 1)
	DAQmx_CTR_CountEdges/DEV="dev2"/EDGE=1/SRC="/dev2/pfi8"/INIT=0/DIR=1/clk="/Dev2/Ctr2InternalOutput"/wave=buffer/EOSH="DoneCounting(buffer)" 0
	DAQmx_CTR_OutputPulse/DEV="dev2" /sec={1,1} /NPLS=10 2
	
end

function bs_2P_reset2P()
	fDAQmx_CTR_Finished("dev2", 0)
	fDAQmx_CTR_Finished("dev2", 1)
	fDAQmx_CTR_Finished("dev2", 2)
	fDAQmx_CTR_Finished("dev2", 3)
	fDAQmx_CTR_Finished("dev1", 0)
	fDAQmx_CTR_Finished("dev1", 1)
	fDAQmx_WaveformStop("dev1")
	fDAQmx_ScanStop("dev1")
end

function DoneCounting(buffer)//, runx, runy, frames, trigger)
	wave buffer //, runx, runy, frames, trigger
//	variable skip = 840
//	wave runx =  root:Packages:BS2P:CurrentScanVariables:runx
//	wave runy =  root:Packages:BS2P:CurrentScanVariables:runy
	NVAR scaledY = root:Packages:BS2P:CurrentScanVariables:scaledY
	NVAR lineSpacing = root:Packages:BS2P:CurrentScanVariables:lineSpacing
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
	NVAR saveEmALl = root:Packages:BS2P:CurrentScanVariables:saveEmAll
	differentiate/meth=2/ep=1/p buffer
	if(saveEmAll)
		BS_2P_saveDum()
	endif
	wave drawnImage = createImageFromBuffer(buffer, pixelsPerLine, (scaledY/lineSpacing))
//	wave drawnImage = anotherDrawMethod(buffer,pixelsPerLine,(scaledY/lineSpacing) )
//	testNewDraw(buffer, runx=runx, runy=runy, pixelShift=0)
	BS_2P_Pockels("close")
//	DrawDumFromScanVoltages(dum, runx, runy)
//	duplicate/o  root:Packages:BS2P:CurrentScanVariables:drawnImage root:Packages:BS2P:CurrentScanVariables:kineticseries
	duplicate/o  drawnImage root:Packages:BS2P:CurrentScanVariables:kineticseries
//	print "did it"
	doupdate/w=kineticWindow
	
//	BS_2P_NiDAQ(runx, runy, buffer, frames, trigger)
end

function testNewDraw(dum, [recreateScan, pixelShift, runx, runy])
	wave dum, runx, runy
	variable recreateScan, pixelShift
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
	variable scanLimit = numberbykey("scanLimit", scanParameters)
	variable displayPixelSize = numberbykey("displayPixelSize", scanParameters)
	
	if(pixelShift)
		//Don't do anything because we provide the shift, otherwise it takes the value saved in the dum wave
	else
		pixelShift = numberbykey("pixelShift", scanParameters)
	endif
	
	variable imageOffset = scanLimit * scaleFactor
	variable xPixels = ceil(scaledX/displayPixelSize), yLines = ceil(scaledY/displayPixelSize)
	
	make/o/n=(xPixels,yLines,frames) root:Packages:BS2P:CurrentScanVariables:drawnImage = 0
	wave drawnImage = root:Packages:BS2P:CurrentScanVariables:drawnImage
	SetScale/P x X_offset,displayPixelSize,"µm", drawnImage
	SetScale/P y Y_offset,displayPixelSize,"µm", drawnImage
	
	variable X_VoltageOffset = X_offset - (scanLimit * scaleFactor)
	variable Y_VoltageOffset = Y_offset - (scanLimit * scaleFactor)
	if(recreateScan)
		BS_rasterByDwellTime(ScaledX,ScaledY,X_VoltageOffset,Y_VoltageOffset, scanOutFreq,dwellTime, lineSpacing,frames)
		wave runx = root:Packages:BS2P:CurrentScanVariables:runx
		wave runy = root:Packages:BS2P:CurrentScanVariables:runx
	endif

////////This function could be optimized by combining everything below into one (huge) line to avoid creating more waves
	duplicate/o runx runx_real;duplicate/o runy runy_real;duplicate/o dum frameNums
	SetScale/P x pixelShift, (dimdelta(runx_real,0)),"", runx_real	//take into account the pixel Shift
//	SetScale/P x pixelShift, (dimdelta(runy,0)),"", runy
//	runx_microns *= scaleFactor; runy_microns *= scaleFactor
//	runx_microns -= x_offset; 	runy_microns -= y_offset
//	runx_microns += imageOffset; 	runy_microns += imageOffset

	frameNums = floor(frames*p/numpnts(dum))
	variable i, frameNum, dumTime, xMicronsAtDumTime, yMicronsAtDumTime, DumPnt2ScanPnt, scanTime
//	duplicate/o dum dum2GalvoPoint, dum2GalvoTime, dumXMicrons, DumYMicrons
	duplicate/o dum pointInTheFrame, timeInTheFrame, dumXMicrons, DumYMicrons
	
//	pointInTheFrame = p-(framenums[p]*frames)		//If more than one frame then get point relative to 1 frame  (xth point in the frame) 
//	timeInTheFrame =  (pnt2x(pointInTheFrame, p))	//That point corresponeds to what time in the frame
	timeInTheFrame = pnt2x(dum,p) - (ScanFrameTime * framenums[p])  < dimoffset(runx_real,0) ? dimoffset(runx_real,0) : pnt2x(dum,p) - ((dimsize(runx,0)) * framenums[p])
	dumxMicrons =  runx_real[x2pnt(runx_real,timeInTheFrame[p])]
	dumYMicrons = runy_real[x2pnt(runy_real,timeInTheFrame[p])]
	
//	dum2GalvoPoint =p-(framenums[p]*frames)	///these are points numbers
//	dum2Galvotime = (pnt2x(dum2GalvoPoint, p))// - pixelShift)	//convert points to times
//	dum2galvotime = dum2galvotime > scanFrameTime ? scanFrameTime : dum2galvotime	//remove negative times
//	dumXMicrons = runx_real(dum2galvotime[p])
//	dumYMicrons = runy_real(dum2galvotime[p])
	
	dumxmicrons *= scaleFactor; dumymicrons *= scaleFactor
	dumxmicrons -= x_offset; 	dumymicrons -= y_offset
	dumxmicrons += imageOffset; 	dumymicrons += imageOffset
			
//	drawnImage[x2pnt(drawnImage, dumXMicrons[p])][x2pnt(drawnImage, dumYMicrons[p])][frameNums[p]] += dum[p]
	variable pixelX
	variable pixelY
	for(i=0; i<numpnts(dum); i+=1)
		pixelX = x2pnt(drawnImage, dumXMicrons[i])// > (dimsize(drawnImage, 0)-1) ? (dimsize(drawnImage, 0)-1) :  x2pnt(drawnImage, dumXMicrons[i])
		pixelY = x2pnt(drawnImage, dumyMicrons[i])// > (dimsize(drawnImage, 1)-1) ? (dimsize(drawnImage, 1)-1) :  x2pnt(drawnImage, dumyMicrons[i])
		drawnImage[pixelX][pixelY][frameNums[i]] += dum[i]
	endfor
	
//	killwaves  dum2GalvoPoint, dum2GalvoTime, dumXMicrons, DumYMicrons, runx_microns, runy_microns
		
end

function BS_2P_Pockels(openOrClose)
	string openOrClose
	NVAR pockelValue = root:Packages:BS2P:CurrentScanVariables:pockelValue
	
	variable pockelVoltage = pockelValue/100*2
	if(stringmatch(openOrCLose, "open"))
		fDAQmx_WriteChan("DEV2", 0, pockelVoltage, -1, 3 )
	elseif(stringmatch(openOrCLose, "close"))
		fDAQmx_WriteChan("DEV2", 0, 0, -1, 3 )
	endif
end

function BS_2P_PMTShutter(openOrClose)
	string openOrClose
	NVAR shutterIOtaskNumber =  root:Packages:BS2P:CurrentScanVariables:shutterIOtaskNumber
	
	if(stringmatch(openOrCLose, "open"))
		fdaqmx_dio_write("dev2", shutterIOtaskNumber, 0)
//		fDAQmx_WriteChan("DEV2", 1, 5, -5, 5 )	//open external shutter before PMT
	elseif(stringmatch(openOrCLose, "close"))
		fdaqmx_dio_write("dev2", shutterIOtaskNumber, 5)
//		fDAQmx_WriteChan("DEV2", 1, 0, -5, 5 )	//close external shutter before PMT
	endif
	
end


function/wave anotherDrawMethod(buffer,pixelsPerLine,linesPerFrame)
	wave buffer
	variable pixelsPerLine, linesPerFrame
	
	variable pixelShift = 0, pixelsPerShift = ceil(pixelShift / dimdelta(buffer,0))
//	variable usablePixels = fillFraction * pixelsPerLine
	variable pixelsPerFrame = linesPerFrame * pixelsPerLine, frameNum, lineNum, pixelNum
//	variable pixelsPerFrame = linesPerFrame * pixelsPerLine, frameNum, lineNum, pixelNum
	make/o/n=(pixelsPerLine, linesPerFrame, (ceil(numpnts(buffer)/pixelsPerFrame))) drawnImage = 0
//	make/o/n=(pixelsPerLine, linesPerFrame, (ceil(numpnts(buffer)/pixelsPerFrame))) drawnImage = 0
	
//		frameNum	= (floor(i/pntsPerFrame))

//		lineNum 		= (floor(i/pixelsPerLine)-(frameNum) * linesPerFrame))
//		lineNum 		= (floor(i/pixelsPerLine)-((floor(i/pntsPerFrame)) * linesPerFrame))

//		pixelNum	= (((i-(lineNum * pixelsPerLine) + (frameNum * pixelsPerFrame))		
//		pixelNum	= ((i-(lineNum * pixelsPerLine) + (frameNum * pixelsPerFrame)) - (mod((lineNum * linesPerFrame),2)*pixelsPerLine)))	****invert every other line for forward/backward scanning
//		pixelNum 	= ((i-((floor(i/pixelsPerLine)-((floor(i/pntsPerFrame)) * linesPerFrame)) * pixelsPerLine) + ((floor(i/pntsPerFrame)) * pixelsPerFrame)) - (mod((floor(i/pixelsPerLine)-((floor(i/pntsPerFrame)) * linesPerFrame)) * linesPerFrame)),2)*pixelsPerLine)))	****pixel number in terms of lines and frames
	variable i
//	for(i = 0; i < numpnts(buffer); i += pixelsPerLine)
//		deletepoints i, pixelsPerShift, buffer
//	endfor
	for(i = 0; i < numpnts(buffer); i += 1)
		frameNum	= floor(i/pixelsPerFrame)
		lineNum		= floor(i/pixelsPerLine)-((frameNum) * linesPerFrame)
		pixelNum	= abs((i-(lineNum * pixelsPerLine) - (frameNum * pixelsPerFrame)) - (mod(lineNum,2)*(pixelsPerLine-1)))
		
//		print i, "--->", pixelNum, lineNum, frameNum
		
		drawnImage[pixelNum][lineNum][frameNum] += buffer[i]
	endfor
//	print pixelsPershift
	return drawnImage
	
end

Function PixPerLinePopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
				String popStr = pa.popStr
				pixelsPerLine = str2num(popStr)
				BS_2P_UpdateVariablesCreateScan()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function testPixelSorter(buffer,pixelsPerLine,linesPerFrame,fillFraction)
	variable buffer, pixelsPerLine, linesPerFrame,fillFraction
	variable usablePixels = fillFraction * pixelsPerLine
	variable pixelsPerFrame = linesPerFrame * usablePixels, frameNum, lineNum, pixelNum, i
	for(i = 0; i <buffer; i += 1)
		frameNum	= floor(i/pixelsPerFrame)
		lineNum		= floor(i/pixelsPerLine)-((frameNum) * linesPerFrame)
		pixelNum	= abs((i-(lineNum * pixelsPerLine) - (frameNum * pixelsPerFrame)) - (mod(lineNum,2)*(pixelsPerLine-1)))
		
		print i, "--->", pixelNum, lineNum, frameNum
		
//		drawnImage[pixelNum][lineNum][frameNum] += buffer[i+skip]
	endfor

end



function checkMirrors()
	BS_2P_UpdateVariablesCreateScan()
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
	NVAR pixelShift = root:Packages:BS2P:CalibrationVariables:pixelShift
	variable correction 
	make/o/n = 10 rnxMaxes, inptMaxes
//	for(i=0; i< 9; i+= 1)
		wave runx = root:Packages:BS2P:CurrentScanVariables:runx
		wave runy = root:Packages:BS2P:CurrentScanVariables:runy
		wave dum = root:Packages:BS2P:CurrentScanVariables:dum
	
//		string endHook = "print wavemax(runx), wavemax(input), wavemax(runx)/wavemax(input)  "
		
//		make/o/n=(numpnts(runx)*10) xpos, ypos
		duplicate/o dum xpos, ypos
		print "dimdelta(xpos, 0) before acquire =", dimdelta(xpos, 0)
//		insertpoints 0, 100000, xpos, ypos
//		SetScale/I x 0,(dimsize(runx,0)*dimdelta(runx,0)),"s", xpos, ypos
//		print dimsize(runx,0) * dimdelta(runx,0); print dimsize(xpos,0) * dimdelta(xpos,0); print dimsize(dum,0) * dimdelta(dum,0)
		
		fDAQmx_WriteChan("DEV1", 0, runx[0], -10, 10 )		/////////Moves laser to first point of X//////////
		fDAQmx_WriteChan("DEV1", 1, runy[0], -10, 10 )
		DAQmx_Scan/BKG/DEV="DEV1"/TRIG={"/dev1/ao/starttrigger"}Waves="xpos,0/PDIFF, -4, 4; ypos,1/PDIFF, -4, 4"
		DAQmx_WaveformGen/DEV="dev1"/NPRD=(1) "runx, 0; runy, 1"
		
//		sleep/s 1
//		print dimsize(runx,0) * dimdelta(runx,0); print dimsize(xpos,0) * dimdelta(xpos,0); print dimsize(dum,0) * dimdelta(dum,0)
//	endfor
	duplicate/o xpos xposMarkers
	xposMarkers = 0
	variable shiftInPixs = round(pixelShift/(dimdelta(xpos,0))); print shiftInPixs
	xposMarkers[shiftInPixs,;pixelsPerLine+1] = 1
//	sleep/s 1
	print "dimdelta(xpos, 0) after acquire =", dimdelta(xpos, 0)
//	FFT/OUT=3/DEST=runx_FFT runx
//	FFT/OUT=3/DEST=xpos_FFT xpos
	
end

function/wave createImageFromBuffer(buffer, pixels, lines)
	wave buffer
	variable pixels, lines
	BS_2P_Pockels("close")

//	print "pixels * lines =", pixels*lines
//	print "numpnts(buffer) = ", numpnts(buffer)
	duplicate/o buffer lastFrame
//	print pixels, lines
//	duplicate/o buffer buffer; 
	differentiate/meth=2/ep=1/p lastFrame
	make/o/n=(pixels,lines) tempImage
	wave kineticSeries
	
	imagetransform/meth=2/D=lastFrame fillImage tempImage
	duplicate/o tempImage root:Packages:BS2P:CurrentScanVariables:KineticSeries
	print "...\r", "1--------------------------"
	DoUpdate/W=kineticWindow
//	redimension/n=(pixels*lines) buffer
//	buffer = nan
	return tempImage
end

function BS_2P_NiDAQ_2(runx, runy, dum, frames, trigger, imageMode)
	wave runx, runy, dum
	variable frames, trigger
	string imageMode
	wave kineticSeries = root:Packages:BS2P:CurrentScanVariables:KineticSeries
	NVAR pixelShift = root:Packages:BS2P:CalibrationVariables:pixelShift
	redimension/n=(-1,-1,1) kineticSeries
	string/g root:Packages:BS2P:currentScanVariables:currentFolder = getdatafolder(1)
	setdatafolder root:Packages:BS2P:CurrentScanVariables
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
	NVAR totalLines = root:Packages:BS2P:CurrentScanVariables:totalLines
	
	variable/g frameCounter = 0
//	string S_kineticHook = "kineticHook("+num2str(frameCounter)+","+num2str(frames)+","+num2str(totalLines)+","+num2str(pixelsPerLine)+","+nameofWave(runx)+","+nameofWave(runy)+","+nameofWave(dum)+")"
	string S_kineticHook2 = "kineticHook2("+nameofWave(dum)+")"
	string S_videoHook = "videoHook("+num2str(frameCounter)+","+num2str(10000)+","+num2str(totalLines)+","+num2str(pixelsPerLine)+","+nameofWave(runx)+","+nameofWave(runy)+","+nameofWave(dum)+")"
//	string S_kineticTest = "kineticTest("+num2str(frameCounter)+","+num2str(frames)+","+num2str(totalLines)+","+num2str(pixelsPerLine)+","+nameofWave(runx)+","+nameofWave(runy)+")"//","+nameofWave(dum)+")"
	string S_scanString = nameofwave(runx)+", 0; "+nameofwave(runy)+", 1"
//	print S_kineticHook2
	
	BS_2P_PMTShutter("open")
	BS_2P_Pockels("open")
	
	if(stringmatch(imageMode, "video"))
		DAQmx_CTR_CountEdges/DEV="dev2"/EDGE=1/SRC="/dev2/pfi8"/INIT=0/DIR=1/clk="/Dev2/Ctr2InternalOutput"/wave=dum/EOSH=S_videoHook 0
		//DAQmx_CTR_OutputPulse/dely=(pixelShift)/DEV="dev2" /FREQ={(1/(dimdelta(dum, 0))),0.5}/TRIG={"/dev1/ao/starttrigger"} /NPLS=(numpnts(dum)) 2 ///dely=(pixelShift) 2	
		//DAQmx_WaveformGen/DEV="dev1"/NPRD=(1) "runx, 0; runy, 1"		/////Start sending volts to scanners (triggers acquistion) trig*2=analog level 5V
		DAQmx_WaveformGen/clk="/Dev2/Ctr3InternalOutput"/DEV="dev1"/NPRD=(1) "runx, 0; runy, 1"
		DAQmx_CTR_OutputPulse/dely=(pixelShift)/DEV="dev2"/TRIG={"/Dev2/Ctr3InternalOutput"}/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 2 ///PIXEL CLOCK
		DAQmx_CTR_OutputPulse/DEV="dev2"/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 3 ///Scanning CLOCK
	elseif(stringmatch(imageMode, "snapshot"))
		DAQmx_CTR_CountEdges/DEV="dev2"/EDGE=1/SRC="/dev2/pfi8"/INIT=0/DIR=1/clk="/Dev2/Ctr2InternalOutput"/wave=dum/EOSH=S_kineticHook2 0
		DAQmx_CTR_OutputPulse/dely=(pixelShift)/DEV="dev2" /FREQ={(1/(dimdelta(dum, 0))),0.5}/TRIG={"/dev1/ao/starttrigger"} /NPLS=(numpnts(dum)) 2 ///dely=(pixelShift) 2	
		DAQmx_WaveformGen/DEV="dev1"/NPRD=(frames) "runx, 0; runy, 1"		/////Start sending volts to scanners (triggers acquistion) trig*2=analog level 5V
	elseif(stringmatch(imageMode, "kinetic"))
		redimension/n=((pixelsPerLine * totalLines * frames) + 1) dum
		DAQmx_CTR_CountEdges/DEV="dev2"/EDGE=1/SRC="/dev2/pfi8"/INIT=0/DIR=1/clk="/Dev2/Ctr2InternalOutput"/wave=dum/eosh = s_kineticHook2 0//;frameCounter += 1;concatenate/np=1 {dum}, kineticDum;" 0//+s_kinetictest 0
		DAQmx_WaveformGen/clk="/Dev1/Ctr3InternalOutput"/DEV="dev2"/NPRD=(frames) "runx, 0; runy, 1"
		DAQmx_CTR_OutputPulse/dely=(pixelShift)/DEV="dev2"/TRIG={"/Dev2/Ctr3InternalOutput"}/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 2 ///PIXEL CLOCK
		DAQmx_CTR_OutputPulse/trig={"/dev1/PFi1", trigger}/DEV="dev2"/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 3 ///Scanning CLOCK
	endif
	

end

function videoHook(frame, frames, lines, pixelsPerLine runx, runy, dum)//, imageMode)
	variable frame, frames, lines, pixelsPerLine
	wave runx, runy, dum
	

	BS_2P_Pockels("close")
	NVAR frameCounter
	NVAR pixelShift = root:Packages:BS2P:CalibrationVariables:pixelShift
	SVAR currentFolder = root:Packages:BS2P:currentScanVariables:currentFolder
	frameCounter += 1
	variable pixelsPerFrame = pixelsPerLine * lines
	wave kineticSeries = root:Packages:BS2P:CurrentScanVariables:KineticSeries
	string S_videoHook = "videoHook("+num2str(frameCounter)+","+num2str(frames)+","+num2str(lines)+","+num2str(pixelsPerLine)+","+nameofWave(runx)+","+nameofWave(runy)+","+nameofWave(dum)+")"

	duplicate/o/free dum lastFrame
	dum = nan
	
	differentiate/meth=2/ep=1/p lastFrame
	redimension/n=(pixelsPerline, lines) lastFrame
	duplicate/free lastFrame flipped
	lastFrame[][1,(lines-1);2][] = flipped[(pixelsPerLine - 1) - p][q][r]
	duplicate/o lastFrame root:Packages:BS2P:CurrentScanVariables:kineticSeries
	scaleKineticSeries()

	
	if(frameCounter == frames)	//shut it down
		BS_2P_writeScanParamsInWave(kineticSeries)
		BS_2P_PMTShutter("close")
		setdatafolder currentFolder
	elseif(frameCounter < frames)	//otherwise set up another one
		BS_2P_Pockels("open")
		DAQmx_CTR_CountEdges/DEV="dev2"/EDGE=1/SRC="/dev2/pfi8"/INIT=0/DIR=1/clk="/Dev2/Ctr2InternalOutput"/wave=dum 0
//		DAQmx_CTR_OutputPulse/dely=(pixelShift)/DEV="dev2" /FREQ={(1/(dimdelta(dum, 0))),0.5}/TRIG={"/dev1/ao/starttrigger"} /NPLS=(numpnts(dum)) 2 ///dely=(pixelShift) 2	
//		DAQmx_WaveformGen/DEV="dev1"/NPRD=1/EOSH=S_videoHook "runx, 0; runy, 1"		/////Start sending volts to scanners (triggers acquistion) trig*2=analog level 5V
		DAQmx_WaveformGen/clk="/Dev2/Ctr3InternalOutput"/DEV="dev1"/NPRD=(1)/EOSH=S_videoHook "runx, 0; runy, 1"
		DAQmx_CTR_OutputPulse/dely=(pixelShift)/DEV="dev2"/TRIG={"/Dev2/Ctr3InternalOutput"}/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 2 ///PIXEL CLOCK
		DAQmx_CTR_OutputPulse/DEV="dev2"/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 3 ///Scanning CLOCK

	endif
end

function kineticHook2(dum)
	wave dum
	
	BS_2P_Pockels("close")
	BS_2P_PMTShutter("close")
	
	differentiate/meth=2/ep=1/p dum
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
	NVAR totalLines = root:Packages:BS2P:CurrentScanVariables:totalLines
	NVAR frames = root:Packages:BS2P:CurrentScanVariables:frames
	variable pixelsPerFrame = pixelsPerLine * Totallines
	
	redimension/n=(pixelsPerline, totalLines, frames) dum
	
	duplicate/free dum flipped
	dum[][1,(totalLines-1);2][] = flipped[(pixelsPerLine - 1) - p][q][r]
	duplicate/o dum root:Packages:BS2P:CurrentScanVariables:kineticSeries
	wave kineticSeries =  root:Packages:BS2P:CurrentScanVariables:kineticSeries
	scaleKineticSeries()
	BS_2P_Append3DImageSlider()
	BS_2P_writeScanParamsInWave(kineticSeries)
	BS_2P_writeScanParamsInWave(dum)
	if(datafolderexists ("root:currentrois") == 1)
		NewUpdate(kineticSeries)
	endif
	SVAR currentFolder = root:Packages:BS2P:currentScanVariables:currentFolder
	setdatafolder currentFolder
end


function 	scaleKineticSeries()
	
	NVAR scaledX = root:Packages:BS2P:CurrentScanVariables:scaledX
	NVAR scaledY = root:Packages:BS2P:CurrentScanVariables:scaledY
	NVAR X_Offset = root:Packages:BS2P:CurrentScanVariables:X_Offset
	NVAR Y_Offset = root:Packages:BS2P:CurrentScanVariables:Y_Offset

	wave kineticSeries = root:Packages:BS2P:CurrentScanVariables:KineticSeries
	
	SetScale x X_Offset, (X_offset + scaledX),"m", kineticSeries
	SetScale y y_Offset, (y_offset + scaledy),"m", kineticSeries
	
	
//	SetScale x (-1 * scanLimit * scaleFactor),(scanLimit * scaleFactor),"m", kineticSeries
//	SetScale y (-1 * scanLimit * scaleFactor),(scanLimit * scaleFactor),"m", kineticSeries

end

function testCounter()
	make/o/n=10 inputCounter = 10
	wave runx, runy
	SetScale/P x 0,0.01,"", inputCounter
	variable i = 0, frames = 3, pixelClock = (1/(dimdelta(inputCounter, 0))), pixelsPerFrame = (numpnts(inputCOunter)
	variable/g frameCounter = 0
	string imageMode = "kinetic"
	string countHookString ="countHook("+num2str(frameCounter)+","+num2str(frames)+","+num2str(50)+","+num2str(50)+","+nameofWave(runx)+","+nameofWave(runy)+","+nameofWave(inputCounter)+","+"\""+imageMode+"\""+")"
	DAQmx_CTR_CountEdges/RPT=1/DEV="dev2"/EDGE=1/SRC="/dev2/pfi8"/INIT=0/DIR=1/clk="/Dev2/Ctr2InternalOutput"/wave=inputCounter/RPTH=countHookString 0
	DAQmx_CTR_OutputPulse/DEV="dev2" /FREQ={pixelClock,0.5} /NPLS=(pixelsPerFrame) 2

end

function stopCounter()
	fDAQmx_CTR_Finished("dev2", 0)
end

Function BS_2P_VideoButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			BS_2P_updateVariablesCreateScan()
			BS_2P_Scan("video")

		case -1: // control being killed
			break
	endswitch

	return 0
End

function bs_2p_initShutter(devNum, pfiLine)
	string devNum // e.g. "dev1"
	string pfiLine // e.g. "pfi2"
	
	string pfiString = "/"+devNum+"/"+pfiLine
	NVAR/z shutterIOtaskNumber =  root:Packages:BS2P:CurrentScanVariables:shutterIOtaskNumber
	if(NVAR_exists(shutterIOtaskNumber))
		 fdaqmx_dio_finished(devNum,shutterIOtaskNumber)
	endif
	daqmx_dio_config/dir=1/dev=devNum pfiString
	variable/g root:Packages:BS2P:CurrentScanVariables:shutterIOtaskNumber = V_DAQmx_DIO_TaskNumber
	fdaqmx_dio_write(devNum, shutterIOtaskNumber, 0)	//close shutter if open
	return shutterIOtaskNumber
end

function/wave bs_2P_getConfigs(Device)
	string device	//xgalvo, ygalvo, PMT, Pockels, PMTshutter, startTrig
	make/free/t/o/n=2 devOut
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	
	devOut[0] = boardconfig[(findDimLabel(boardConfig,0,Device))][1]
	devOut[1] = boardconfig[(findDimLabel(boardConfig,0,Device))][3]
	
	return devOut
end

function bs_2P_makeNewDefaultConfig()
	make/o/t/n=(7,3) root:Packages:BS2P:CalibrationVariables:boardConfig
	wave/t boardCOnfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	setdimlabel 0,0,xGalvo,boardCOnfig
	setdimlabel 0,1,yGalvo,boardCOnfig
	setdimlabel 0,2,PMT,boardCOnfig
	setdimlabel 0,3,Pockels,boardCOnfig
	setdimlabel 0,4,PMTshutter,boardCOnfig
	setdimlabel 0,5,startTrig,boardCOnfig
	setdimlabel 0,6,laserPhotoDiode,boardCOnfig
	setdimlabel 1,0,Board,boardCOnfig
	setdimlabel 1,1,Type,boardCOnfig
	setdimlabel 1,2,Channel,boardCOnfig
	
	boardConfig[][0] = "dev1"
	boardConfig[][1] = "analog OUT channel ----->"
	boardConfig[2][1] = "PFI ----->"
	boardConfig[4][1] = "PFI ----->"
	boardConfig[5][1] = "PFI ----->"
	boardConfig[6][1] = "analog IN channel ----->"
	boardConfig[][2] = "0"
	boardConfig[1][2] = "1"
	boardConfig[2][2] = "8"
	boardConfig[4][2] = "2"
	boardConfig[5][2] = "1"
	boardConfig[6][2] = "0"
	
	edit boardConfig.l, boardConfig
end
