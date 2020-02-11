#pragma rtGlobals=3		// Use modern global access method and strict wave access.




function BS_2P_Pockels(openOrClose)
	string openOrClose
	NVAR pockelValue = root:Packages:BS2P:CurrentScanVariables:pockelValue
	
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	string pockelDevNum = boardConfig[2][0]
	variable pockelChannel = str2num(boardConfig[2][2])
	

	NVAR minPockels = root:Packages:BS2P:CalibrationVariables:minPockels
	NVAR maxPockels = root:Packages:BS2P:CalibrationVariables:maxPockels
	

	variable pockelVoltage	// convert percent to volts -- 0.5V is max
	if(stringmatch(openOrCLose, "open"))
		pockelVoltage = pockelValue//(100/(maxPockels-minPockels))+minPockels
	elseif(stringmatch(openOrCLose, "close"))
		pockelVoltage = 0 //minPockels
	endif
	fDAQmx_WriteChan(pockelDevNum, pockelChannel, pockelVoltage, 0,2 )
	return pockelVoltage
end

function checkMirrors()
	BS_2P_UpdateVariables()
	BS_2P_CreateScan()
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

function BS_2P_NiDAQ_2(runx, runy, dum, frames, trigger, imageMode)
	wave runx, runy, dum
	variable frames, trigger
	string imageMode
	
	wave multiScanOffsets = root:Packages:BS2P:CurrentScanVariables:multiScanOffsets
	wave multiX = root:Packages:BS2P:CurrentScanVariables:multiX
	wave multiY = root:Packages:BS2P:CurrentScanVariables:multiY
	string offsetNote = note(multiScanOffsets)
	variable multiLines =  numberByKey("lines", offsetNote, "=", ";")
	variable multiPixels =  numberByKey("Pixels", offsetNote, "=", ";")
	variable drawPause = 50e-3 //seconds to draw the frame  --try to make this as short as possible
	variable userPause = 0	//seconds to wait between frames
	
	wave ePhysDum = root:Packages:BS2P:CurrentScanVariables:ePhysDum
	NVAR ePhysRec = root:Packages:BS2P:CurrentScanVariables:ePhysRec
	
	wave kineticSeries = root:Packages:BS2P:CurrentScanVariables:KineticSeries
	NVAR pixelShift = root:Packages:BS2P:CalibrationVariables:pixelShift
	redimension/n=(-1,-1,1) kineticSeries
	string/g root:Packages:BS2P:currentScanVariables:currentFolder = getdatafolder(1)
	setdatafolder root:Packages:BS2P:CurrentScanVariables
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
	NVAR totalLines = root:Packages:BS2P:CurrentScanVariables:totalLines
	NVAR dwellTime = root:Packages:BS2P:CurrentScanVariables:dwellTime
	
	variable frameDuration = dimsize(runy,0) * dimdelta(runy,0)
	
	NVAR stackDepth = root:Packages:BS2P:CurrentScanVariables:stackDepth
	NVAR stackResolution = root:Packages:BS2P:CurrentScanVariables:stackResolution
	variable stackSlices = ceil(stackDepth / stackResolution)
	
	NVAR frameAvg = root:Packages:BS2P:CurrentScanVariables:frameAvg
	
	NVAR acquireWheelData = root:Packages:BS2P:CurrentScanVariables:acquireWheelData
	
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig 

	string galvoDev = boardConfig[0][0]
	string pmtDev = boardConfig[3][0]
	string startTrigDev = boardConfig[5][0]
//	string startTrigChannel = "/"+startTrigDev+"/port"+boardConfig[5][1]+ "/line" + boardConfig[5][2]
	string startTrigChannel = "/"+startTrigDev+"/"+"pfi"+boardConfig[5][2]
//	string pfiString = "/"+devNum+"/port"+port+ "/line" + line
	string xGalvoChannel = boardConfig[0][2]
	string yGalvoChannel = boardConfig[1][2]
	
	string pmtSource = "/"+pmtDev+"/pfi"+boardConfig[3][2]
	string pixelCLock = "/"+pmtDev+"/Ctr2InternalOutput"
	string scanClock = "/"+pmtDev+"/Ctr3InternalOutput"
	string frameClock = "/"+pmtDev+"/Ctr1InternalOutput"
	string scanOutTrigger = "/"+galvoDev+"/ao/starttrigger"
	string galvoChannels = "runx, "+ xGalvoChannel+"; runy, "+yGalvoChannel
	
	string ePhysDev =  boardConfig[23][0]
	string ePhysChan = boardConfig[23][2]
	string ePhysConfig = "ePhysDum,"+ePhysChan+"/DIFF, -10, 10"
	
	variable/g frameCounter = 0
//	string S_kineticHook = "kineticHook("+num2str(frameCounter)+","+num2str(frames)+","+num2str(totalLines)+","+num2str(pixelsPerLine)+","+nameofWave(runx)+","+nameofWave(runy)+","+nameofWave(dum)+")"
	string S_kineticHook2 = "kineticHook2("+nameofWave(dum)+","+num2str(frames)+")"
	string S_videoHook = "videoHook("+num2str(frameCounter)+","+num2str(10000)+","+num2str(totalLines)+","+num2str(pixelsPerLine)+","+nameofWave(runx)+","+nameofWave(runy)+","+nameofWave(dum)+")"
	string S_stackHook = "stackHook("+num2str(frameCounter)+","+num2str(stackSlices)+","+num2str(totalLines)+","+num2str(pixelsPerLine)+","+nameofWave(runx)+","+nameofWave(runy)+","+nameofWave(dum)+")"
	string S_kineticTest = "kineticTest("+num2str(frameCounter)+","+num2str(frames)+","+num2str(totalLines)+","+num2str(pixelsPerLine)+","+nameofWave(runx)+","+nameofWave(runy)+","+nameofWave(dum)+")"
	string S_scanString = nameofwave(runx)+", 0; "+nameofwave(runy)+", 1"
	string S_multiVideoHook = "multiVideoHook("+num2str(frameCounter)+","+num2str(10000)+","+num2str(multiLines)+","+num2str(multiPixels)+","+nameofWave(multiX)+","+nameofWave(multiY)+","+nameofWave(dum)+")"
//	
	string S_multiKineticHook2 = "multiKineticHook2("+nameofWave(Dum)+","+num2str(frames)+")"

//	print S_kineticHook2
	
	BS_2P_PMTShutter("open")
	BS_2P_Pockels("open")
	
	if(stringmatch(imageMode, "video"))
		redimension/n=((pixelsPerLine * totalLines * frameAvg) + 0) dum
		DAQmx_CTR_CountEdges/DEV=pmtDev/EDGE=1/SRC=pmtSource/INIT=0/DIR=1/clk=pixelClock/wave=dum/EOSH=S_videoHook 0
		DAQmx_WaveformGen/clk=scanClock/DEV=galvoDev/NPRD=(frameAvg) galvoChannels
		DAQmx_CTR_OutputPulse/dely=(pixelShift)/DEV=pmtDev/TRIG={scanClock}/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 2 ///PIXEL CLOCK
		DAQmx_CTR_OutputPulse/DEV=pmtDev/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 3 ///Scanning CLOCK
	elseif(stringmatch(imageMode, "snapshot"))
		DAQmx_CTR_CountEdges/DEV=pmtDev/EDGE=1/SRC=pmtSource/INIT=0/DIR=1/clk=pixelCLock/wave=dum/EOSH=S_kineticHook2 0
		DAQmx_CTR_OutputPulse/dely=(pixelShift)/DEV=pmtDev /FREQ={(1/(dimdelta(dum, 0))),0.5}/TRIG={scanOutTrigger} /NPLS=(numpnts(dum)) 2 ///dely=(pixelShift) 2	
		DAQmx_WaveformGen/DEV=galvoDev/NPRD=(frames) galvoChannels		/////Start sending volts to scanners (triggers acquistion) trig*2=analog level 5V
	elseif(stringmatch(imageMode, "kinetic"))
		redimension/n=((pixelsPerLine * totalLines * frames) + 1) dum
		if(acquireWheelData)
			readEncoder()
		endif
		BS_2P_StartSignal()
		//try scaling dum to 40 Mz to make sure it catches all pulses (hamamatsu photon counter = 25 ns pulse pair resolution) 
		if(ePhysRec)
			DAQmx_Scan/BKG/DEV=ePhysDev/TRIG={scanClock}Waves=ePhysConfig
		endif
		DAQmx_CTR_CountEdges/DEV=pmtDev/EDGE=1/SRC=pmtSource/INIT=0/DIR=1/clk=pixelCLock/wave=dum/eosh = s_kineticHook2 0
		DAQmx_WaveformGen/clk=scanClock/DEV=galvoDev/NPRD=(frames) galvoChannels
		DAQmx_CTR_OutputPulse/dely=(pixelShift)/DEV=pmtDev/TRIG={scanClock}/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 2 ///PIXEL CLOCK
		DAQmx_CTR_OutputPulse/trig={startTrigChannel, trigger}/DEV=pmtDev/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 3 ///Scanning CLOCK
	elseif(stringmatch(imageMode, "stack"))
//		readLaserPower()
		redimension/n=((pixelsPerLine * totalLines * frameAvg) + 0) dum
		DAQmx_CTR_CountEdges/DEV=pmtDev/EDGE=1/SRC=pmtSource/INIT=0/DIR=1/clk=pixelClock/wave=dum/EOSH=S_stackHook 0
		DAQmx_WaveformGen/clk=scanClock/DEV=galvoDev/NPRD=(frameAvg) galvoChannels
		DAQmx_CTR_OutputPulse/dely=(pixelShift)/DEV=pmtDev/TRIG={scanClock}/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 2 ///PIXEL CLOCK
		DAQmx_CTR_OutputPulse/DEV=pmtDev/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 3 ///Scanning CLOCK
	elseif(stringmatch(imageMode, "test"))		//used for testing shit
		DAQmx_CTR_CountEdges/DEV=pmtDev/EDGE=1/SRC=pmtSource/INIT=0/DIR=1/clk=pixelCLock/wave=dum/eosh = s_kineticTest 0//;frameCounter += 1;concatenate/np=1 {dum}, kineticDum;" 0//+s_kinetictest 0
		DAQmx_WaveformGen/clk=scanClock/DEV=galvoDev/NPRD=(1) galvoChannels
		DAQmx_CTR_OutputPulse/dely=(pixelShift)/DEV=pmtDev/TRIG={scanClock}/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 2 ///PIXEL CLOCK
		DAQmx_CTR_OutputPulse/trig={frameClock}/DEV=pmtDev/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 3 ///Scanning CLOCK
		DAQmx_CTR_OutputPulse/trig={startTrigChannel, trigger}/DEV=pmtDev/SEC={10e-6, (frameDuration+drawPause+userPause)}/NPLS=(frames) 1 ///FRAME CLOCK
	elseif(stringmatch(imageMode, "multiVideo"))
		galvoChannels = "multiX, "+ xGalvoChannel+"; multiY, "+yGalvoChannel
		duplicate/o multiX dum; dum = nan
		DAQmx_CTR_CountEdges/DEV=pmtDev/EDGE=1/SRC=pmtSource/INIT=0/DIR=1/clk=pixelClock/wave=dum/EOSH=S_multiVideoHook 0
		DAQmx_WaveformGen/clk=scanClock/DEV=galvoDev/NPRD=(1) galvoChannels
		DAQmx_CTR_OutputPulse/dely=(pixelShift)/DEV=pmtDev/TRIG={scanClock}/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 2 ///PIXEL CLOCK
		DAQmx_CTR_OutputPulse/DEV=pmtDev/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 3 ///Scanning CLOCK
	elseif(stringmatch(imageMode, "multiKinetic"))
		BS_2P_StartSignal()
		galvoChannels = "multiX, "+ xGalvoChannel+"; multiY, "+yGalvoChannel
		duplicate/o multiX dum
		redimension/n=((numpnts(multiX) * frames) + 1) dum; dum = nan
		//try scaling dum to 40 Mz to make sure it catches all pulses (hamamatsu photon counter = 25 ns pulse pair resolution) 
		if(ePhysRec)
			DAQmx_Scan/BKG/DEV=ePhysDev/TRIG={scanClock}Waves=ePhysConfig
		endif
		DAQmx_CTR_CountEdges/DEV=pmtDev/EDGE=1/SRC=pmtSource/INIT=0/DIR=1/clk=pixelCLock/wave=dum/eosh = s_multiKineticHook2 0
		DAQmx_WaveformGen/clk=scanClock/DEV=galvoDev/NPRD=(frames) galvoChannels
		DAQmx_CTR_OutputPulse/dely=(pixelShift)/DEV=pmtDev/TRIG={scanClock}/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 2 ///PIXEL CLOCK
		DAQmx_CTR_OutputPulse/trig={startTrigChannel, trigger}/DEV=pmtDev/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 3 ///Scanning CLOCK
	endif
	

end

function stackHook(frame, frames, lines, pixelsPerLine runx, runy, dum)//, imageMode)
	variable frame, frames, lines, pixelsPerLine
	wave runx, runy, dum
	
	NVAR stackDepth = root:Packages:BS2P:CurrentScanVariables:stackDepth
	NVAR stackResolution = root:Packages:BS2P:CurrentScanVariables:stackResolution
	NVAR saveEmAll = root:Packages:BS2P:CurrentScanVariables:saveEmAll
	variable stackSlices = ceil(stackDepth / stackResolution)
	BS_2P_Pockels("close")
	NVAR frameCounter
	NVAR pixelShift = root:Packages:BS2P:CalibrationVariables:pixelShift
	SVAR currentFolder = root:Packages:BS2P:currentScanVariables:currentFolder
	frameCounter += 1
	variable pixelsPerFrame = pixelsPerLine * lines
	wave kineticSeries = root:Packages:BS2P:CurrentScanVariables:KineticSeries
	string S_stackHook = "stackHook("+num2str(frameCounter)+","+num2str(stackSlices)+","+num2str(Lines)+","+num2str(pixelsPerLine)+","+nameofWave(runx)+","+nameofWave(runy)+","+nameofWave(dum)+")"

	duplicate/o/free dum lastFrame
	dum = nan
	differentiate/meth=2/ep=1/p lastFrame
	
	NVAR frameAvg = root:Packages:BS2P:CurrentScanVariables:frameAvg
		If(frameAvg == 1)
		redimension/n=(pixelsPerline, lines) lastFrame
	else
		redimension/n=(pixelsPerline, lines, frameAvg) lastFrame
		duplicate/o/free lastFrame avgHolder
		matrixop/o lastFrame = sumBeams(avgHolder)  / frameAvg
	endif
	
	
//	redimension/n=(pixelsPerline, lines) lastFrame
	duplicate/free lastFrame flipped
	lastFrame[][1,(lines-1);2][] = flipped[(pixelsPerLine - 1) - p][q][r]
	duplicate/o lastFrame root:Packages:BS2P:CurrentScanVariables:kineticSeries
	scaleKineticSeries()

	// make these into variables in the init and config procedures
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig 
	string galvoDev = boardConfig[0][0]
	string pmtDev = boardConfig[3][0]
	string startTrigDev = boardConfig[5][0]
	string startTrigChannel = "/"+startTrigDev+"/"+"pfi"+boardConfig[5][2]
	string xGalvoChannel = boardConfig[0][2]
	string yGalvoChannel = boardConfig[1][2]
	
	string pmtSource = "/"+pmtDev+"/pfi8"
	string pixelCLock = "/"+pmtDev+"/Ctr2InternalOutput"
	string scanClock = "/"+pmtDev+"/Ctr3InternalOutput"
	string scanOutTrigger = "/"+galvoDev+"/ao/starttrigger"
	string galvoChannels = "runx, "+ xGalvoChannel+"; runy, "+yGalvoChannel
	NVAR luigsFocusDevice = root:Packages:BS2P:CalibrationVariables:luigsFocusDevice
	SVAR luigsFocusAxis = root:Packages:BS2P:CalibrationVariables:luigsFocusAxis
	

	if(frameCounter < frames)	//otherwise set up another one
		string sliceName = "slice_"+num2str(frameCounter)
		redimension/n=(-1,-1) kineticSeries
		duplicate/o kineticSeries $sliceName
		if(stringMatch((boardConfig[15][2]), "YES")) //Luigs
			LN_moveMicrons(luigsFocusDevice, luigsFocusAxis, -stackResolution)
			sleep/s 0.100
		elseif(stringMatch((boardConfig[24][2]), "YES"))	//Python
			pythonMoveRelative(stackResolution, "z")
			sleep/s 0.100
		elseif(stringMatch((boardConfig[25][2]), "YES"))	//PI_Focus
			PI_moveMicrons("z",  stackResolution)
			sleep/s 0.500
			PI_tellPosition("z")
		endif
		BS_2P_Pockels("open")
		DAQmx_CTR_CountEdges/DEV=pmtDev/EDGE=1/SRC=pmtSource/INIT=0/DIR=1/clk=pixelCLock/wave=dum/EOSH=S_stackHook 0
		DAQmx_WaveformGen/clk=scanClock/DEV=galvoDev/NPRD=(frameAvg) galvoChannels
		DAQmx_CTR_OutputPulse/dely=(pixelShift)/DEV=pmtDev/TRIG={scanClock}/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 2 ///PIXEL CLOCK
		DAQmx_CTR_OutputPulse/DEV=pmtDev/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 3 ///Scanning CLOCK
	elseif(frameCounter == frames)	//shut it down
		wave newStack = root:Packages:BS2P:CurrentScanVariables:newStack
		wave slice_1
		sliceName = "slice_"+num2str(frameCounter)
		redimension/n=(-1,-1) kineticSeries
		duplicate/o kineticSeries $sliceName
		BS_2P_PMTShutter("close")
		bs_2P_zeroscanners("offset")
		sampleDiodeVoltage()
		

		imageTransform/k stackImages slice_1; wave m_stack
//		rotateImage(m_stack)
		duplicate/o m_stack kineticSeries
		killwaves/z m_stack
		checkXYSwitch(kineticSeries,frames)
		scaleKineticSeries()
		setScale/p z, 0, (stackResolution * 1e-6), kineticSeries
		BS_2P_Append3DImageSlider()
		makeProjections(kineticSeries)
		BS_2P_writeScanParamsInWave(kineticSeries)
		NVAR saveEmAll = root:Packages:BS2P:CurrentScanVariables:saveEmAll
		if(saveemall)
			BS_2P_saveDum()
		endif
		
		if(stringMatch((boardConfig[15][2]), "YES")) //Luigs
			LN_moveMicrons(luigsFocusDevice, luigsFocusAxis, stackDepth)
		elseif(stringMatch((boardConfig[24][2]), "YES"))	//Python
			pythonMoveRelative(-stackDepth, "z")
		 elseif(stringMatch((boardConfig[25][2]), "YES"))	//PI_Focus
			PI_moveMicrons("z",  -stackDepth)
			sleep/s 0.500
			PI_tellAllPositions()
		endif
		
		setdatafolder currentFolder
	endif

end

function videoHook(frame, frames, lines, pixelsPerLine runx, runy, dum)//, imageMode)
	variable frame, frames, lines, pixelsPerLine
	wave runx, runy, dum
	

//	BS_2P_Pockels("close")
	NVAR frameCounter
	NVAR pixelShift = root:Packages:BS2P:CalibrationVariables:pixelShift
	NVAR frameAvg = root:Packages:BS2P:CurrentScanVariables:frameAvg
	SVAR currentFolder = root:Packages:BS2P:currentScanVariables:currentFolder
	frameCounter += 1
	variable pixelsPerFrame = pixelsPerLine * lines
	wave kineticSeries = root:Packages:BS2P:CurrentScanVariables:KineticSeries
	string S_videoHook = "videoHook("+num2str(frameCounter)+","+num2str(frames)+","+num2str(lines)+","+num2str(pixelsPerLine)+","+nameofWave(runx)+","+nameofWave(runy)+","+nameofWave(dum)+")"

	duplicate/o/free dum lastFrame
	dum = nan
	
	differentiate/meth=2/ep=1/p lastFrame
	If(frameAvg == 1)
		redimension/n=(pixelsPerline, lines) lastFrame
	else
		redimension/n=(pixelsPerline, lines, frameAvg) lastFrame
		duplicate/o/free lastFrame avgHolder
		matrixop/o lastFrame = sumBeams(avgHolder)  / frameAvg
	endif
	
	duplicate/free lastFrame flipped
	lastFrame[][1,(lines-1);2][] = flipped[(pixelsPerLine - 1) - p][q][r]
//	rotateImage(lastFrame)
	checkXYSwitch(lastFrame,1)
	duplicate/o lastFrame root:Packages:BS2P:CurrentScanVariables:kineticSeries
	scaleKineticSeries()
//	sampleDiodeVoltage()
	
	// make these into variables in the init and config procedures
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig 
	string galvoDev = boardConfig[0][0]
	string pmtDev = boardConfig[3][0]
	string startTrigDev = boardConfig[5][0]
	string startTrigChannel = "/"+startTrigDev+"/"+"pfi"+boardConfig[5][2]
	string xGalvoChannel = boardConfig[0][2]
	string yGalvoChannel = boardConfig[1][2]
	
	string pmtSource = "/"+pmtDev+"/pfi8"
	string pixelCLock = "/"+pmtDev+"/Ctr2InternalOutput"
	string scanClock = "/"+pmtDev+"/Ctr3InternalOutput"
	string scanOutTrigger = "/"+galvoDev+"/ao/starttrigger"
	string galvoChannels = "runx, "+ xGalvoChannel+"; runy, "+yGalvoChannel
	
	
	if(frameCounter == frames)	//shut it down
		BS_2P_writeScanParamsInWave(kineticSeries)
		sampleDiodeVoltage()
		BS_2P_PMTShutter("close")
		bs_2P_zeroscanners("offset")
		setdatafolder currentFolder
	elseif(frameCounter < frames)	//otherwise set up another one
//		BS_2P_Pockels("open")
		DAQmx_CTR_CountEdges/DEV=pmtDev/EDGE=1/SRC=pmtSource/INIT=0/DIR=1/clk=pixelCLock/wave=dum/EOSH=S_videoHook 0
//		DAQmx_CTR_OutputPulse/dely=(pixelShift)/DEV="dev2" /FREQ={(1/(dimdelta(dum, 0))),0.5}/TRIG={"/dev1/ao/starttrigger"} /NPLS=(numpnts(dum)) 2 ///dely=(pixelShift) 2	
//		DAQmx_WaveformGen/DEV="dev1"/NPRD=1/EOSH=S_videoHook "runx, 0; runy, 1"		/////Start sending volts to scanners (triggers acquistion) trig*2=analog level 5V
		DAQmx_WaveformGen/clk=scanClock/DEV=galvoDev/NPRD=(frameAvg) galvoChannels
		DAQmx_CTR_OutputPulse/dely=(pixelShift)/DEV=pmtDev/TRIG={scanClock}/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 2 ///PIXEL CLOCK
		DAQmx_CTR_OutputPulse/DEV=pmtDev/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 3 ///Scanning CLOCK
	endif

end

function multiVideoHook(frame, frames, lines, pixelsPerLine multiX, multiY, multiDum)//, imageMode)
	variable frame, frames, lines, pixelsPerLine
	wave multiX, multiY, multiDum
	
	wave multiScanOffsets = root:Packages:BS2P:CurrentScanVariables:multiScanOffsets
	variable subFrames = dimSize(multiScanOffsets,0)
	
	NVAR testShift = root:testShift
	NVAR frameCounter
	NVAR pixelShift = root:Packages:BS2P:CalibrationVariables:pixelShift
	NVAR frameAvg = root:Packages:BS2P:CurrentScanVariables:frameAvg
	SVAR currentFolder = root:Packages:BS2P:currentScanVariables:currentFolder
	frameCounter += 1
	variable pixelsPerFrame = pixelsPerLine * lines
	wave kineticSeries = root:Packages:BS2P:CurrentScanVariables:KineticSeries
	string S_multiVideoHook = "multiVideoHook("+num2str(frameCounter)+","+num2str(frames)+","+num2str(lines)+","+num2str(pixelsPerLine)+","+nameofWave(multiX)+","+nameofWave(multiY)+","+nameofWave(multiDum)+")"

	
	duplicate/o multiDum lastFrame//; print "multiDum Pnts=",numpnts(multiDum)

	multiDum = 0
	differentiate/meth=2/ep=1/p lastFrame//; print "differentiated Pnts=",numpnts(lastFrame)	
	BS_2P_writeScanParamsInWave(lastFrame)
	clipTransitionsUnfoldedMultiDum(lastFrame)//; print "clipped=",numpnts(lastFrame) / (pixelsPerline* lines)

	wave multiKinetic = splitmultiDum(lastFrame)
	duplicate/o multiKinetic root:Packages:BS2P:CurrentScanVariables:kineticSeries

	
	// make these into variables in the init and config procedures
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig 
	string galvoDev = boardConfig[0][0]
	string pmtDev = boardConfig[3][0]
	string startTrigDev = boardConfig[5][0]
	string startTrigChannel = "/"+startTrigDev+"/"+"pfi"+boardConfig[5][2]
	string xGalvoChannel = boardConfig[0][2]
	string yGalvoChannel = boardConfig[1][2]
	
	string pmtSource = "/"+pmtDev+"/"+"pfi"+boardConfig[3][2]
	string pixelCLock = "/"+pmtDev+"/Ctr2InternalOutput"
	string scanClock = "/"+pmtDev+"/Ctr3InternalOutput"
	string scanOutTrigger = "/"+galvoDev+"/ao/starttrigger"
	string galvoChannels = "multiX, "+ xGalvoChannel+"; multiY, "+yGalvoChannel
	
	
	if(frameCounter == frames)	//shut it down
		BS_2P_writeScanParamsInWave(kineticSeries)
		sampleDiodeVoltage()
		BS_2P_PMTShutter("close")
		bs_2P_zeroscanners("offset")
		setdatafolder currentFolder
	elseif(frameCounter < frames)	//otherwise set up another one
//		print frameCounter
		DAQmx_CTR_CountEdges/DEV=pmtDev/EDGE=1/SRC=pmtSource/INIT=0/DIR=1/clk=pixelCLock/wave=multiDum/EOSH=S_multiVideoHook 0
		DAQmx_WaveformGen/clk=scanClock/DEV=galvoDev/NPRD=(1) galvoChannels
		DAQmx_CTR_OutputPulse/dely=(pixelShift)/DEV=pmtDev/TRIG={scanClock}/FREQ={(1/(dimdelta(multiDum, 0))),0.5}/NPLS=(numpnts(multiDum)+1) 2 ///PIXEL CLOCK
		DAQmx_CTR_OutputPulse/DEV=pmtDev/FREQ={(1/(dimdelta(multiDum, 0))),0.5}/NPLS=(numpnts(multiDum)+1) 3 ///Scanning CLOCK
	endif

end

function kineticHook2(dum, frames)
	wave dum
	variable frames
		
	wave ePhysDum = root:Packages:BS2P:CurrentScanVariables:ePhysDum
	NVAR ePhysRec = root:Packages:BS2P:CurrentScanVariables:ePhysRec
	NVAR trigLoop = root:Packages:BS2P:CurrentScanVariables:trigLoop
	sampleDiodeVoltage()
	BS_2P_Pockels("close")
	if(!trigLoop)
		BS_2P_PMTShutter("close")
	endif
	bs_2P_zeroscanners("offset")
//	stopReadingArduino()
	
//	duplicate/o dum dum_bkp
	differentiate/meth=2/ep=1/p dum
//	dum = abs(dum)	//we do this because we switch the direction of the counting for each frame
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
	NVAR totalLines = root:Packages:BS2P:CurrentScanVariables:totalLines
//	NVAR frames = root:Packages:BS2P:CurrentScanVariables:frames
	variable pixelsPerFrame = pixelsPerLine * Totallines
	
	redimension/n=(pixelsPerline, totalLines, frames) dum
	
	duplicate/free dum flipped
	//flip every other row for bidirectional scanning
	dum[][1,(totalLines-1);2][] = flipped[(pixelsPerLine - 1) - p][q][r]
	
	//rotate image
	checkXYSwitch(dum,frames)
//	rotateImage(dum)
	duplicate/o dum root:Packages:BS2P:CurrentScanVariables:kineticSeries
	wave kineticSeries =  root:Packages:BS2P:CurrentScanVariables:kineticSeries
	scaleKineticSeries()
	
	BS_2P_Append3DImageSlider()
	BS_2P_writeScanParamsInWave(kineticSeries)
//	readLaserPower()
//	BS_2P_writeScanParamsInWave(dum)
	if(datafolderexists ("root:currentrois") == 1)
		NewUpdate(kineticSeries)
	endif

	if(ePhysRec)
		dowindow ePhysWIn
		if(!v_flag)
			display/k=1/n=ephysWin ePhysDum
		endif
	endif
	
	NVAR saveWheelData = root:Packages:BS2P:CurrentScanVariables:saveWheelData
	if(saveWheelData)
		 BS_2P_saveWheel()
	endif
	
	NVAR saveEmAll = root:Packages:BS2P:CurrentScanVariables:saveEmAll
	if(saveemall)
		BS_2P_saveDum()
	endif
	

	
	NVAR acquireWheelData = root:Packages:BS2P:CurrentScanVariables:acquireWheelData
	if(acquireWheelData)
		calculateEncodersBinary(root:encoderbinary, 0)
	endif
	
	SVAR currentFolder = root:Packages:BS2P:currentScanVariables:currentFolder
	setdatafolder currentFolder
	
	if(trigLoop)
		BS_2P_Scan("kinetic")
	endif
end

function multiKineticHook2(multidum, frames)
	wave multidum
	variable frames
		
	wave ePhysDum = root:Packages:BS2P:CurrentScanVariables:ePhysDum
	NVAR ePhysRec = root:Packages:BS2P:CurrentScanVariables:ePhysRec
	sampleDiodeVoltage()
	BS_2P_Pockels("close")
	BS_2P_PMTShutter("close")
	bs_2P_zeroscanners("offset")
	

	wave multiScanOffsets = root:Packages:BS2P:CurrentScanVariables:multiScanOffsets
	variable subFrames = dimSize(multiScanOffsets,0)
	variable lines = numberByKey("lines",note(multiScanOffsets), "=", ";")
	variable pixelsPerLine = numberByKey("pixels",note(multiScanOffsets), "=", ";")
	
	NVAR pixelShift = root:Packages:BS2P:CalibrationVariables:pixelShift
	NVAR frameAvg = root:Packages:BS2P:CurrentScanVariables:frameAvg
	SVAR currentFolder = root:Packages:BS2P:currentScanVariables:currentFolder
//	NVAR pixelsPerLine = root:Packages:BS2P:currentScanVariables:

	variable pixelsPerFrame = pixelsPerLine * lines

	duplicate/o multiDum lastFrame//; print "multiDum Pnts=",numpnts(multiDum)
	multiDum = 0
	BS_2P_writeScanParamsInWave(lastFrame)
	differentiate/meth=2/ep=1/p lastFrame//; print "differentiated Pnts=",numpnts(lastFrame)
	clipTransitionsUnfoldedMultiDum(lastFrame)//; print "clipped=",numpnts(lastFrame) / (pixelsPerline* lines)
//	redimension/n=(pixelsPerline, lines, (subFrames*frames)) lastFrame
	wave multiKinetic = splitmultiDum(lastFrame)
	duplicate/o multiKinetic root:Packages:BS2P:CurrentScanVariables:kineticSeries
	
	//rotate image
	checkXYSwitch(multiDum,frames)
//	rotateImage(dum)
//	duplicate/o multiDum root:Packages:BS2P:CurrentScanVariables:kineticSeries
	wave kineticSeries =  root:Packages:BS2P:CurrentScanVariables:kineticSeries
//	scaleKineticSeries()
	
	BS_2P_Append3DImageSlider()
	BS_2P_writeScanParamsInWave(kineticSeries)
//	readLaserPower()
//	BS_2P_writeScanParamsInWave(dum)
	if(datafolderexists ("root:currentrois") == 1)
		NewUpdate(kineticSeries)
	endif

	if(ePhysRec)
		dowindow ePhysWIn
		if(!v_flag)
			display/k=1/n=ephysWin ePhysDum
		endif
	endif
	
	NVAR saveEmAll = root:Packages:BS2P:CurrentScanVariables:saveEmAll
	if(saveemall)
		BS_2P_saveDum()
	endif

	SVAR currentFolder = root:Packages:BS2P:currentScanVariables:currentFolder
	setdatafolder currentFolder
	
	NVAR trigLoop = root:Packages:BS2P:CurrentScanVariables:trigLoop
	if(trigLoop)
		BS_2P_Scan("multiKinetic")
	endif
end

function kineticTest(frame, frames, lines, pixelsPerLine runx, runy, dum)//, imageMode)
	variable frame, frames, lines, pixelsPerLine
	wave runx, runy, dum
	
	NVAR frameCounter
	NVAR pixelShift = root:Packages:BS2P:CalibrationVariables:pixelShift
	SVAR currentFolder = root:Packages:BS2P:currentScanVariables:currentFolder

	frameCounter += 1
	variable pixelsPerFrame = pixelsPerLine * lines
	wave kineticSeries = root:Packages:BS2P:CurrentScanVariables:KineticSeries
	string S_kineticTest = "kineticTest("+num2str(frameCounter)+","+num2str(frames)+","+num2str(lines)+","+num2str(pixelsPerLine)+","+nameofWave(runx)+","+nameofWave(runy)+","+nameofWave(dum)+")"

//	duplicate/o/free dum lastFrame
//	dum = nan
	
//	differentiate/meth=2/ep=1/p lastFrame
//	redimension/n=(pixelsPerline, lines) lastFrame
//	duplicate/free lastFrame flipped
//	lastFrame[][1,(lines-1);2][] = flipped[(pixelsPerLine - 1) - p][q][r]
//	if(frameCounter == 1)
//		make/o/free/n=(pixelsPerFrame) buffer
//		scaleKineticSeries()
//	endif
	wave buffer = root:Packages:BS2P:CurrentScanVariables:buffer
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig 
	string galvoDev = boardConfig[0][0]
	string pmtDev = boardConfig[3][0]
	string startTrigDev = boardConfig[5][0]
	string startTrigChannel = "/"+startTrigDev+"/"+"pfi"+boardConfig[5][2]
	string xGalvoChannel = boardConfig[0][2]
	string yGalvoChannel = boardConfig[1][2]
	
	string pmtSource = "/"+pmtDev+"/pfi"+boardConfig[3][2]
	string frameClock = "/"+pmtDev+"/Ctr1InternalOutput"
	string pixelCLock = "/"+pmtDev+"/Ctr2InternalOutput"
	string scanClock = "/"+pmtDev+"/Ctr3InternalOutput"
	string scanOutTrigger = "/"+galvoDev+"/ao/starttrigger"
	string galvoChannels = "runx, "+ xGalvoChannel+"; runy, "+yGalvoChannel
	

	if(frameCounter == frames)	//shut it down
//		concatenate/np=2 {lastFrame} , buffer
		BS_2P_PMTShutter("close")
		bs_2P_zeroscanners("offset")
		BS_2P_Append3DImageSlider()
//		BS_2P_writeScanParamsInWave(kineticSeries)
		setdatafolder currentFolder
	elseif(frameCounter < frames)	//otherwise set up another one
//		concatenate/np=2 {lastFrame} , buffer
		DAQmx_CTR_CountEdges/DEV=pmtDev/EDGE=1/SRC=pmtSource/INIT=0/DIR=1/clk=pixelCLock/wave=dum/EOSH=S_kineticTest 0
		DAQmx_WaveformGen/clk=scanClock/DEV=galvoDev/NPRD=(1) galvoChannels
		DAQmx_CTR_OutputPulse/dely=(pixelShift)/DEV=pmtDev/TRIG={scanClock}/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 2 ///PIXEL CLOCK
		DAQmx_CTR_OutputPulse/trig={frameClock}/DEV=pmtDev/FREQ={(1/(dimdelta(dum, 0))),0.5}/NPLS=(numpnts(dum)+1) 3 ///Scanning CLOCK
	endif

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
	variable i = 0, frames = 3, pixelClock = (1/(dimdelta(inputCounter, 0))), pixelsPerFrame = (numpnts(inputCOunter))
	variable/g frameCounter = 0
	string imageMode = "kinetic"
	string countHookString ="countHook("+num2str(frameCounter)+","+num2str(frames)+","+num2str(50)+","+num2str(50)+","+nameofWave(runx)+","+nameofWave(runy)+","+nameofWave(inputCounter)+","+"\""+imageMode+"\""+")"
	DAQmx_CTR_CountEdges/RPT=1/DEV="dev2"/EDGE=1/SRC="/dev2/pfi8"/INIT=0/DIR=1/clk="/Dev2/Ctr2InternalOutput"/wave=inputCounter/RPTH=countHookString 0
	DAQmx_CTR_OutputPulse/DEV="dev2" /FREQ={pixelClock,0.5} /NPLS=(pixelsPerFrame) 2

end

function stopCounter()
	fDAQmx_CTR_Finished("dev2", 0)
end

function readEncoder()
	
	NVAR dwellTIme = root:Packages:BS2P:CurrentScanVariables:dwellTime
	NVAR lineTIme = root:Packages:BS2P:CurrentScanVariables:lineTIme
	NVAR totalLines = root:Packages:BS2P:CurrentScanVariables:totalLines
	NVAR Frames = root:Packages:BS2P:CurrentScanVariables:Frames
//	string openOrClose
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	string devNum = boardConfig[3][0]
	string port = "0"//boardConfig[26][1]
	string line = "0:6"//boardConfig[26][2]
	string pixelCLock = "/"+devNum+"/Ctr2InternalOutput"
	
	NVAR encoderIOtaskNumber = root:Packages:BS2P:CurrentScanVariables:encoderIOtaskNumber
	if(NVAR_exists(encoderIOtaskNumber))
		fDAQmx_DIO_Finished(devNum, encoderIOtaskNumber)
	endif
	
	NVAR wheelGainIOtaskNumber = root:Packages:BS2P:CurrentScanVariables:wheelGainIOtaskNumber
	if(NVAR_exists(wheelGainIOtaskNumber))
		fDAQmx_DIO_Finished(devNum, wheelGainIOtaskNumber)
	endif
	
	make/w/u/n=((lineTime*totalLines*frames)/dwelltime)/o root:EncoderBinary = 0
	wave EncoderBinary = root:EncoderBinary
	
	setScale/p x, 0, (dwellTime), "s" EncoderBinary
	
	string pfiString = "/"+devNum+"/port"+port+ "/line" + line
	string EndOfScanHookStr = "encoderRecordingDone()"
	daqmx_dio_config/dir=0/LGRP=0/dev=devNum/wave={EncoderBinary}/CLK={pixelCLock,1} pfiString // /EOSH=EndOfScanHookStr pfiString
	variable/g  root:Packages:BS2P:CurrentScanVariables:encoderIOtaskNumber = V_DAQmx_DIO_TaskNumber
end

function readIOs()
	
	NVAR dwellTIme = root:Packages:BS2P:CurrentScanVariables:dwellTime
	NVAR lineTIme = root:Packages:BS2P:CurrentScanVariables:lineTIme
	NVAR totalLines = root:Packages:BS2P:CurrentScanVariables:totalLines
	NVAR Frames = root:Packages:BS2P:CurrentScanVariables:Frames
//	string openOrClose
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	string devNum = boardConfig[3][0]
	string port = "0"//boardConfig[26][1]
	string line = "17"//boardConfig[26][2]
	string pixelCLock = "/"+devNum+"/Ctr2InternalOutput"
	
	NVAR IOtaskNumber = root:Packages:BS2P:CurrentScanVariables:IOtaskNumber
	if(NVAR_exists(IOtaskNumber))
		fDAQmx_DIO_Finished(devNum, IOtaskNumber)
	endif
	
	make/w/u/n=((lineTime*totalLines*frames)/dwelltime)/o root:IOsBinary = 0
	wave IOsBinary = root:IOsBinary
	
	setScale/p x, 0, (dwellTime), "s" IOsBinary
	
	string pfiString = "/"+devNum+"/port"+port+ "/line" + line
	daqmx_dio_config/dir=0/LGRP=0/dev=devNum/wave={IOsBinary}/CLK={pixelCLock,1} pfiString
	variable/g  root:Packages:BS2P:CurrentScanVariables:IOtaskNumber = V_DAQmx_DIO_TaskNumber
end


function encoderRecordingDone()

	wave EncoderBinary = root:EncoderBinary
	calculateEncodersBINARY(EncoderBinary,0)
end

function calculateEncoders(encoderData)
	wave encoderData
	
	variable wheelDiameter = 20 	//in cm
	variable encoderTicks = 2^12
	variable wheelCircumference = pi*wheelDiameter
	variable subSampleBin = 20e-3	// secs to bin speeds for downsampling
	
	 
	
	duplicate/o/r=[][0] encoderData encoderDistance
	redimension/n=(-1,3) encoderDistance
	setDimLabel 1, 0, Encoder1, encoderDistance
	setDimLabel 1, 1, Encoder2, encoderDistance
	setDimLabel 1, 2, Encoder3, encoderDistance
// bitwise magic to convert encodersignals to binary steps forward and backward
	encoderDistance[][0] = (encoderData[p][0] ^ encoderData[p][1] ) | encoderData[p][1] << 1
	encoderDistance[][1] = (encoderData[p][2] ^ encoderData[p][3] ) | encoderData[p][3] << 1
	encoderDistance[][2] = (encoderData[p][4] ^ encoderData[p][5] ) | encoderData[p][5] << 1
	differentiate/dim=0/meth=2/p root:Packages:BS2P:CurrentScanVariables:encoderDistance
	encoderDistance = mod(encoderDistance,2)
		
//distance calculation	

	encoderDistance *= (wheelCircumference / encoderTicks)	// wheel circumference = 20 cm; 2^12 ticks per encoder turn
	integrate/P encoderDistance
	
//speed calculation (requires downsampling data)
	duplicate/o encoderDistance wheelSpeed
	variable subSamplefactor = subSampleBin / dimdelta(encoderDistance,0)
	make/free/o/n=((dimsize(encoderDistance,0) / subSamplefactor),3) subSample
	copyscales/i encoderDistance, subsample
	subsample = sum(encoderDistance,((pnt2x(encoderDistance,p))*subSamplefactor),((pnt2x(encoderDistance,(p*subSamplefactor)+subSamplefactor))))
	subsample /= subSamplefactor
	differentiate/dim=0/meth=2 subsample /d=root:Packages:BS2P:CurrentScanVariables:encoderSpeed
	
//	killwaves Encoder1A, Encoder1B, Encoder2A, Encoder2B, Encoder3A, Encoder3B
end

function calculateEncodersBinary(encoderBinary, getBinary)
	wave encoderBinary
	variable getBinary
	variable encoderTicks, wheelDiameter, speedbinning, gearRatio
	
	gearRatio = 2.0
	wheelDiameter = 20 	//in cm
	encoderTicks = 1600
	variable wheelCircumference = pi*wheelDiameter
	variable subSampleBin = 5e-3	// secs to bin speeds for downsampling
	
//																									//encoder signal comes in as single binary wave for all channels
//																									//eg. 35 = 100011 (3 are high and 3 are low)
//	//determine how many channels/encoders were recorded
//	string allDIOChannels
//	sprintf allDIOChannels, "%b", wavemax(EncoderBinary)
//	variable totalDIOChannels = strlen(allDIOChannels)
	
	//make a new matrix to hold distances from all encoders
	duplicate/o encoderBinary root:encoderDistances
	wave encoderDistances = root:encoderDistances
	redimension/n=(-1,3) encoderdistances
	
	//process channels in pairs of two
	variable i = 0
	for(i=0; i< (3); i+=1 )
		string encoderNames = "Encoder_"+num2str(i)
		setDimLabel 1, i, $encoderNames, encoderDistances
		
		variable encoderAbit = 2^(i*2)						//using the example above for 35 if when i = 1 encoderAbit is 100[0]11
		variable encoderBbit = 2^((i*2)+1)					//and encoderBbit is 10[0]011
		
		// (encoderAbit %^ encoderBbit) | encoderBbit << 1 is bitwise to turn all the 3s to 2s and 2s to 3s (converts encoder digital signals to 4 states) 
		encoderDistances[][i] = (((encoderBinary[p] & encoderAbit) && 1) %^ ((encoderBinary[p] & encoderBbit) && 1) ) | ((encoderBinary[p] & encoderBbit) && 1) << 1
	endfor
	if(getBinary)
		duplicate/o encoderDistances root:encoderBinary
		wave encoderBinary = root:encoderBinary
	endif
	
	//now that the encoder signals are converted to states they can be differentiated to get steps in forward backward directions
	differentiate/dim=0/p/meth=2 encoderDistances
	//but we are left with the steps of 3 which we need to convert into single steps
	encoderDistances = encoderDistances == -3 ? -1 : encoderDistances
	encoderDistances = encoderDistances == 3 ? 1 : encoderDistances


	//Distance calculation
	encoderDistances *= (wheelCircumference / encoderTicks / 2)	// wheel circumference = 20 cm; 1600 ticks per encoder turn
																				// not sure why it needs to be divided by 2 !!!
	encoderDistances[][1,2] /= gearRatio
	integrate/dim=0/P encoderDistances
	SetScale d 0,0,"cm", encoderDistances
	
	//speed calculation (requires downsampling data)
	variable subSamplefactor = subSampleBin / dimdelta(encoderDistances,0)
	make/o/n=((dimsize(encoderDistances,0) / subSamplefactor),3)  root:encoderSpeeds
	wave encoderSpeeds = root:encoderSpeeds
	
	for(i=0; i< (3); i+=1 )
		duplicate/o/free/r=[][i] encoderDistances encoderDistance 
		make/free/o/n=((dimsize(encoderDistance,0) / subSamplefactor),3) subSample
		copyscales/i encoderDistance, subsample
		subsample = sum(encoderDistance,((pnt2x(encoderDistance,p))*subSamplefactor),((pnt2x(encoderDistance,(p*subSamplefactor)+subSamplefactor))))
		subsample /= subSamplefactor
		differentiate/dim=0/meth=2 subsample
		encoderSpeeds[][i] = subsample[p]
	endfor
	copyscales/i encoderDistance, encoderSpeeds
	SetScale d 0,0,"cm/s", encoderSpeeds
	
	make/o/n=(dimsize(encoderDistances,0))  root:gainReporter
	wave gainReporter = root:gainReporter
	gainReporter = (encoderBinary[p] & 2^6) && 1	//assumes gain is reporter in 7th channel
	copyscales/i encoderDistance, gainReporter
	SetScale d 0,0,"On | Off", gainReporter
	
	dowindow/f wheeldistanceWindow
	if(!v_flag)
		display/k=1/n=wheeldistanceWindow encoderDistances[][0] encoderDistances[][1] encoderDistances[][2]
		ModifyGraph rgb(encoderDistances#1)=(0,0,65535),rgb(encoderDistances#2)=(1,39321,19939)
	endif
	
	dowindow/f wheelspeedWindow
	if(!v_flag)
		display/k=1/n=wheelSPEEDWindow encoderSpeeds[][0] encoderSpeeds[][1] encoderSpeeds[][2]
		ModifyGraph rgb(encoderSpeeds#1)=(0,0,65535),rgb(encoderSpeeds#2)=(1,39321,19939)
		TextBox/C/N=text0/X=40.00/Y=-28.00/F=0/A=MC "\\s(encoderSpeeds)wheel\r\\s(encoderSpeeds#1)right\r\\s(encoderSpeeds#2)left"
	endif
	
	dowindow/f gainWindow
	if(!v_flag)
		display/k=1/n=gainWindow gainReporter
	endif
	
	if(getBinary)
		dowindow/f wheelbinaryWindow
		if(!v_flag)
			display/k=1/n=wheelbinaryWindow encoderBinary[][0] encoderBinary[][1] encoderBinary[][2]
			ModifyGraph rgb(encoderBinary#1)=(0,0,65535),rgb(encoderBinary#2)=(1,39321,19939)
//			TextBox/C/N=text0/X=40.00/Y=-28.00/F=0/A=MC "\\s(encoderSpeeds)wheel\r\\s(encoderSpeeds#1)left\r\\s(encoderSpeeds#2)right"
		endif
	endif
end

function testcalculateEncodersBinary()
	variable encoderTicks, wheelDiameter, speedbinning
	
	wheelDiameter = 19.8 	//in cm
	encoderTicks = 2^13
	variable wheelCircumference = pi*wheelDiameter
	variable subSampleBin = 20e-3	// secs to bin speeds for downsampling
	
	wave EncoderBinary = root:Packages:BS2P:CurrentScanVariables:EncoderBinary		//encoder signal comes in as aingle binary wave for all channels
																									//eg. 35 = 100011 (3 are high and 3 are low)
	//determine how many channels/encoders were recorded
	string allDIOChannels
	sprintf allDIOChannels, "%b", wavemax(EncoderBinary)
	variable totalDIOChannels = strlen(allDIOChannels)
	
	//make a new matrix to hold distances from all encoders
	duplicate/o encoderBinary encoderDistances
	redimension/n=(-1,(totalDIOChannels/2)) encoderdistances
	
	//process channels in pairs of two
	variable i = 0
	for(i=0; i< (totalDIOChannels/2); i+=1 )
		string encoderNames = "Encoder_"+num2str(i)
		setDimLabel 1, i, $encoderNames, encoderDistances
	endfor
	
	encoderdistances = (encoderBinary[p][q] & (2^(q*2) + 2^((2*q)+1))) >> (q*2)
	encoderDistances = encoderDistances == 3 ? 5 : encoderDistances
	encoderDistances = encoderDistances == 2 ? 3 : encoderDistances
	encoderDistances = encoderDistances == 5 ? 2 : encoderDistances
end

function testDIOWrite(devNum, port, line, Logic)
	string devNum, port, line
	variable logic
	
	NVAR IOTestTaskNumber = root:IOTestTaskNumber
	if(NVAR_exists(IOTestTaskNumber))
		fDAQmx_DIO_Finished(devNum, IOTestTaskNumber)
	endif
	
	string pfiString = "/"+devNum+"/port"+port+ "/line" + line
	print pfiString
	daqmx_dio_config/dir=1/LGRP=1/dev=devNum pfiString
	variable/g  root:IOTestTaskNumber = V_DAQmx_DIO_TaskNumber
	print fDAQmx_DIO_Write(devNum, IOTestTaskNumber, Logic)

end