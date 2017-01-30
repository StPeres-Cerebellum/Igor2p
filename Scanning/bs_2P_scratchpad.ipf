#pragma rtGlobals=3		// Use modern global access method and strict wave access.





function testCounting()

	make/o/n=10 buffer
//	fDAQmx_CTR_Finished("dev2", 0)
//	fDAQmx_CTR_Finished("dev2", 1)
	DAQmx_CTR_CountEdges/DEV="dev2"/EDGE=1/SRC="/dev2/pfi8"/INIT=0/DIR=1/clk="/Dev2/Ctr2InternalOutput"/wave=buffer/EOSH="DoneCounting(buffer)" 0
	DAQmx_CTR_OutputPulse/DEV="dev2" /sec={1,1} /NPLS=10 2
	
end




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
	
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig 

	string galvoDev = boardConfig[0][0]
	string pmtDev = boardConfig[3][0]
	string startTrigDev = boardConfig[5][0]
	string startTrigChannel = "/"+startTrigDev+"/"+"pfi"+boardConfig[5][2]
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
	

	BS_2P_Pockels("close")
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
		BS_2P_Pockels("open")
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
//	String offsetNote = note(multiScanOffsets)
//	variable multiLines =  numberByKey("lines", offsetNote, "=", ";")
	
	//BS_2P_Pockels("close")
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
//	If(frameAvg == 1)
//		print "pixels, lines=",pixelsPerline,lines
		clipTransitionsUnfoldedMultiDum(lastFrame)//; print "clipped=",numpnts(lastFrame) / (pixelsPerline* lines)
		redimension/n=(pixelsPerline, lines, subFrames) lastFrame
//		duplicate/free lastFrame flipped
//		lastFrame[][1,(lines-1);2][] = flipped[(pixelsPerLine - 1) - p][q][r]
		wave multiKinetic = splitmultiDum(lastFrame)
//	else
//		redimension/n=(pixelsPerline, lines, frameAvg) lastFrame
//		duplicate/o/free lastFrame avgHolder
//		matrixop/o lastFrame = sumBeams(avgHolder)  / frameAvg
//	endif
//	
////	duplicate/free multiKinetic flipped
//	
//	rotateImage(lastFrame)
//	checkXYSwitch(lastFrame,1)
	duplicate/o multiKinetic root:Packages:BS2P:CurrentScanVariables:kineticSeries
//	scaleKineticSeries()

	
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
		print frameCounter
		DAQmx_CTR_CountEdges/DEV=pmtDev/EDGE=1/SRC=pmtSource/INIT=0/DIR=1/clk=pixelCLock/wave=multiDum/EOSH=S_multiVideoHook 0
//		DAQmx_CTR_OutputPulse/dely=(pixelShift)/DEV="dev2" /FREQ={(1/(dimdelta(dum, 0))),0.5}/TRIG={"/dev1/ao/starttrigger"} /NPLS=(numpnts(dum)) 2 ///dely=(pixelShift) 2	
//		DAQmx_WaveformGen/DEV="dev1"/NPRD=1/EOSH=S_videoHook "runx, 0; runy, 1"		/////Start sending volts to scanners (triggers acquistion) trig*2=analog level 5V
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
	sampleDiodeVoltage()
	BS_2P_Pockels("close")
	BS_2P_PMTShutter("close")
	bs_2P_zeroscanners("offset")
	
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
	
	NVAR saveEmAll = root:Packages:BS2P:CurrentScanVariables:saveEmAll
	if(saveemall)
		BS_2P_saveDum()
	endif

	SVAR currentFolder = root:Packages:BS2P:currentScanVariables:currentFolder
	setdatafolder currentFolder
	
	NVAR trigLoop = root:Packages:BS2P:CurrentScanVariables:trigLoop
	if(trigLoop)
		BS_2P_Scan("kinetic")
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

