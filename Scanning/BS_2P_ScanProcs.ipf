#pragma rtGlobals=3		// Use modern global access method and strict wave access.


function testSCAN(runx, runy, repeats, acqu1,acqu2)
	wave runx, runy
	variable repeats, acqu1, acqu2
	NVAR trig
	
	
	if(trig)				/////////////////////////Sets the channel to wait for trigger/////////////////////////////
		string TrigSource = "/dev1/pfi0\, 2"
	else
		TrigSource = "/dev1/pfi0, 0"
	endif
						/////////////////////////Make Dum and Simult waves (assumes runx is made for acquisition frequency of 10 us)/////////////////////////////
	make/o/n=(numpnts(runx)*repeats) dum
	make/o/n=(numpnts(runx)*repeats) simult
	SetScale/p x, 0, 10e-6, "s", dum, simult, runx, runy 	//isabel was sampling with 10us sampling interval set by "ITC18StimandSample FIFOout, FIFOin, 4, "+acqStatus+", 0"
	
	string WhichChannels	/////////////////////////Checks if it should acquire on both dum and simult/////////////////////////////
	if(acqu2==0)
		WhichChannels ="dum,0"
	else
		WhichChannels = "dum,0; simult,1"
	endif
	
	fDAQmx_WriteChan("DEV1", 0, runx[0], -10, 10 )		/////////Moves laser to first point of X//////////
	fDAQmx_WriteChan("DEV1", 1, runy[0], -10, 10 )		/////////Moves laser to first point of Y/////////
	DAQmx_Scan/BKG/DEV="DEV1"/TRIG={"/dev1/ao/starttrigger"}Waves=WhichChannels	///////Setup acquisition and wait for trigger from scanning start/////////
	
	//Open Pockels cell to a given value set by slider
	DAQmx_WaveformGen/DEV="dev1"/NPRD=(repeats)/TRIG={"/dev1/pfi0", (trig*2), 1,5} "runx, 0; runy, 1"		/////Start sending volts to scanners (triggers acquistion) trig*2=analog level 5V
	fDAQmx_WF_WaitUntilFinished("Dev1", -1)
	fDAQmx_WaveformStop("dev1")
	fDAQmx_ScanStop("dev1")
	//close Pockels
//	fDAQmx_WriteChan("DEV1", 0, 0, -10, 10 )		///////Move laser back to 0V X
//	fDAQmx_WriteChan("DEV1", 1, 0, -10, 10 )		///////Move laser bact to 0V Y

	//write scan parameters to dum wave note  use the note/K waveName, str
	//make sure to include enough to recreate the scan.
end

function PockelsControlScan(runx, runy, frames, externalTrigger, pockelValue, AcquisitionFrequency)
	wave runx, runy
	variable frames, externalTrigger, pockelValue, AcquisitionFrequency	//Frequency is in kHz
	NVAR saveEmAll = root:Packages:BS2P:CurrentScanVariables:saveEmAll
	NVAR  prefixIncrement = root:Packages:BS2P:CurrentScanVariables:prefixIncrement
	SVAR currentPath = root:Packages:BS2P:CurrentScanVariables:currentPath
	SVAR SaveAsPrefix = root:Packages:BS2P:CurrentScanVariables:SaveAsPrefix
	SVAR fileName2bWritten = root:Packages:BS2P:CurrentScanVariables:fileName2bWritten
	pathInfo $currentPath
	string currentPathDetails = s_path
	
	if(externalTrigger)				/////////////////////////Sets the channel to wait for trigger/////////////////////////////
		string TrigSource = "/dev1/pfi0\, 2"
	else
		TrigSource = "/dev1/pfi0, 0"
	endif
	
	if(frames>1)
		frames/=2
	endif
	
/////////////////////////Make Dum and Simult waves (assumes runx is made for acquisition frequency of 10 us)/////////////////////////////

	variable dumLength = (dimsize(root:Packages:BS2P:CurrentScanVariables:runy, 0) * dimdelta(root:Packages:BS2P:CurrentScanVariables:runy, 0))	//in ms
	dumLength *= AcquisitionFrequency
	
	variable min_V, max_V	// sets a range for the PMT digitization
	
	make/o/n=(dumLength) root:Packages:BS2P:CurrentScanVariables:dum
	wave dum  = root:Packages:BS2P:CurrentScanVariables:dum
//	WriteScanParamsInWave(dum)
	
	SetScale/p x, 0, AcquisitionFrequency, "ms", dum 	//isabel was sampling with 10us sampling interval set by "ITC18StimandSample FIFOout, FIFOin, 4, "+acqStatus+", 0"
	fDAQmx_WriteChan("DEV1", 0, runx[0], -10, 10 )		/////////Moves laser to first point of X//////////
	fDAQmx_WriteChan("DEV1", 1, runy[0], -10, 10 )		/////////Moves laser to first point of Y/////////
	DAQmx_Scan/BKG/DEV="DEV1"/TRIG={"/dev1/ao/starttrigger"}Waves="dum, 0/pdiff, v_min, v_max"	///////Setup acquisition and wait for trigger from scanning start/////////
	
	DAQmx_WaveformGen/DEV="dev1"/NPRD=(frames)/TRIG={"/dev1/pfi0", (externalTrigger*2), 1,5} "runx, 0; runy, 1"		/////Start sending volts to scanners (triggers acquistion) trig*2=analog level 5V
	fDAQmx_WF_WaitUntilFinished("Dev1", -1)
	fDAQmx_WaveformStop("dev1")
	fDAQmx_WriteChan("DEV1", 0, 0, -10, 10 )		///////Move laser back to 0V X
	fDAQmx_WriteChan("DEV1", 1, 0, -10, 10 )		///////Move laser bact to 0V Y
	
	string filename2Write = saveAsPrefix+num2str(prefixIncrement)+".ibw"
	BS_2P_writeScanParamsInWave(dum)
	if(saveEmAll == 1)
		save/c/o/p=$currentPath dum as filename2Write
		prefixIncrement += 1
		fileName2bWritten = currentPathDetails + SaveAsPrefix + num2str(prefixIncrement)
	endif
end

function BS_2P_NiDAQ(runx, runy, dum, frames, trigger)
	wave runx, runy, dum
	variable frames, trigger
	frames = 1
	
	NVAR pixelShift = root:Packages:BS2P:CalibrationVariables:pixelShift
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
	variable lines = round(numpnts(dum)/pixelsPerLine)
	
	if(trigger)				/////////////////////////Sets the channel to wait for trigger/////////////////////////////
		string TrigSource = "/dev1/pfi0\, 2"
	else
		TrigSource = "/dev1/pfi0, 0"
	endif
//	variable dwellTime = 
	
//	make/o/n=(numpnts(runx)*frames) dum
//	SetScale/p x, 0, 10e-6, "s", dum, runx, runy 	//isabel was sampling with 10us sampling interval set by "ITC18StimandSample FIFOout, FIFOin, 4, "+acqStatus+", 0"
	
	/// DEBUGGING/////////////////////////////////////////////////////////////////////////
//	duplicate/o dum xpos, ypos
//	insertpoints 0, 100000, xpos, ypos
	fDAQmx_CTR_Finished("dev2", 0)
	
	variable pixelsPerFrame = pixelsPerLine * lines
	string endHook = "CreateImageFromBuffer("+ nameofwave(dum) +"," + num2str(pixelsPerLine) +","+ num2str(lines) +")"
	DAQmx_CTR_CountEdges/RPT=1/DEV="dev2"/EDGE=1/SRC="/dev2/pfi8"/INIT=0/DIR=1/clk="/Dev2/Ctr2InternalOutput"/wave=dum/RPTH=endHook 0
	
//	for(i=0; i<scanRepeats; i+= 1)
		BS_2P_Pockels("open")
		
	//	string WhichChannels	= GetWavesDataFolder(dum, 2 ) + ",0/pdiff"; print whichChannels
//		fDAQmx_WriteChan("DEV1", 0, runx[0], -10, 10 )		/////////Moves laser to first point of X//////////
//		fDAQmx_WriteChan("DEV1", 1, runy[0], -10, 10 )		/////////Moves laser to first point of Y/////////
			
	//	DAQmx_CTR_OutputPulse/DEV="dev1" /FREQ={10,0.5} /NPLS=10 0
	//	DAQmx_Scan/BKG/DEV="DEV1"/TRIG={"/dev1/ao/starttrigger"}/EOSH="testNewDraw(dum, runx, runy)"  Waves=WhichChannels	///////Setup acquisition and wait for trigger from scanning start/////////
	//	DAQmx_Scan/BKG/DEV="DEV1"/TRIG={"/dev1/ao/starttrigger"}  Waves="dum, 0/pdif"
		DAQmx_CTR_OutputPulse/DEV="dev2" /FREQ={(1/(dimdelta(dum, 0))),0.5}/TRIG={"/dev1/ao/starttrigger"} /NPLS=(frames * pixelsPerFrame) 2 ///dely=(pixelShift) 2	////////////////add a trigger!
		
		/// DEBUGGING/////////////////////////////////////////////////////////////////////////
	//	DAQmx_Scan/BKG/DEV="DEV1"/TRIG={"/dev1/ao/starttrigger"}Waves="xpos,0/PDIFF, -4, 4; ypos,1/PDIFF, -4, 4"
		
		DAQmx_WaveformGen/DEV="dev1"/NPRD=(frames) "runx, 0; runy, 1"		/////Start sending volts to scanners (triggers acquistion) trig*2=analog level 5V
//		sleep/s (dimsize(dum,0)*dimdelta(dum,0)) + 0.005
		
//		print "sleep ", (dimsize(dum,0)*dimdelta(dum,0)) + 0.005
//		print i, "\r--------------------------------"
		
//	endfor
	BS_2P_writeScanParamsInWave(dum)

//	DAQmx_WaveformGen/DEV="dev1"/NPRD=(scanRepeats)/TRIG={"/Dev2/Ctr2InternalOutput"} "runx, 0; runy, 1"		/////Start sending volts to scanners (triggers acquistion) trig*2=analog level 5V
//	DAQmx_CTR_OutputPulse/DEV="dev2" /FREQ={(1/dwellTime),0.5} /NPLS=(dimsize(dum,0))/dely=100e-6 2	////////////////add a trigger!

//	fDAQmx_WF_WaitUntilFinished("Dev1", -1)
//	fDAQmx_WaveformStop("dev1")
//	fDAQmx_ScanStop("dev1")

	//write scan parameters to dum wave note  use the note/K waveName, str
	
	//make sure to include enough to recreate the scan.
//	
end

function BS_2P_WriteScanParamsInWave(w)
	wave w
	
	string variableNote = ""
	
	NVAR scaledX = root:Packages:BS2P:CurrentScanVariables:scaledX;  variableNote +=  "scaledX:"+num2str(scaledX)+";"
	NVAR scaledY = root:Packages:BS2P:CurrentScanVariables:scaledY; variableNote += "scaledY:"+num2str(scaledY)+";"
	NVAR frames = root:Packages:BS2P:CurrentScanVariables:frames; variableNote +=  "frames:"+num2str(frames)+";"
	NVAR KCT = root:Packages:BS2P:CurrentScanVariables:KCT; variableNote +=  "KCT:"+num2str(KCT)+";"
	NVAR acquisitionFrequency = root:Packages:BS2P:CurrentScanVariables:acquisitionFrequency; variableNote +=  "acquisitionFrequency:"+num2str(acquisitionFrequency)+";"
	NVAR dwellTime = root:Packages:BS2P:CurrentScanVariables:dwellTime; variableNote +=  "dwellTime:"+num2str(dwellTime)+";"
	NVAR lineSpacing = root:Packages:BS2P:CurrentScanVariables:lineSpacing; variableNote +=  "lineSpacing:"+num2str(lineSpacing)+";"
	NVAR scaleFactor = root:Packages:BS2P:CalibrationVariables:scaleFactor; variableNote +=  "scaleFactor:"+num2str(scaleFactor)+";"
	NVAR X_Offset = root:Packages:BS2P:CurrentScanVariables:X_Offset; variableNote +=  "X_Offset:"+num2str(X_Offset)+";"
	NVAR Y_Offset = root:Packages:BS2P:CurrentScanVariables:Y_Offset; variableNote +=  "Y_Offset:"+num2str(Y_Offset)+";"
	NVAR scanOutFreq = root:Packages:BS2P:CurrentScanVariables:scanOutFreq; variableNote +=  "scanOutFreq:"+num2str(scanOutFreq)+";"
	NVAR scanFrameTime = root:Packages:BS2P:CurrentScanVariables:scanFrameTime; variableNote +=  "scanFrameTime:"+num2str(scanFrameTime)+";"
	NVAR lineTime = root:Packages:BS2P:CurrentScanVariables:lineTime; variableNote +=  "lineTime:"+num2str(lineTime)+";"
	NVAR pixelShift =  root:Packages:BS2P:CalibrationVariables:pixelShift; variableNote +=  "pixelShift:"+num2str(pixelShift)+";"
	NVAR scanLimit = root:Packages:BS2P:CalibrationVariables:scanLimit; variableNote +=  "scanLimit:"+num2str(scanLimit)+";"
	NVAR displayPixelSize = root:Packages:BS2P:CurrentScanVariables:displayPixelSize; variableNote +=  "displayPixelSize:"+num2str(displayPixelSize)+";"
	NVAR totalLines = root:Packages:BS2P:CurrentScanVariables:totalLines; variableNote +=  "totalLines:"+num2str(totalLines)+";"
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine; variableNote +=  "pixelsPerLine:"+num2str(pixelsPerLine)+";"
	NVAR pockelValue = root:Packages:BS2P:CurrentScanVariables:pockelValue; variableNote +=  "pockelValue:"+num2str(pockelValue)+";" 
	NVAR laserPower = root:Packages:BS2P:CurrentScanVariables:laserPower; variableNote +=  "laserPower:"+num2str(laserPower)+";" 
	NVAR xPos = root:Packages:pythonPositions:xPos; variableNote +=  "pythoPosX:"+num2str(xPos)+";" 
	NVAR yPos = root:Packages:pythonPositions:yPos; variableNote +=  "pythoPosY:"+num2str(yPos)+";" 
	NVAR zPos = root:Packages:pythonPositions:zPos; variableNote +=  "pythoPosZ:"+num2str(zPos)+";" 
	note/K w, variableNote

end

function BS_2P_Scan(imageMode, [frameSize, setscan])
	string imageMode, frameSize
	variable setScan
	wave runx = root:Packages:BS2P:CurrentScanVariables:runX
	wave runy = root:Packages:BS2P:CurrentScanVariables:runY
	wave dum = root:Packages:BS2P:CurrentScanVariables:dum
	NVAR acquisitionFrequency = root:Packages:BS2P:CurrentScanVariables:acquisitionFrequency
	NVAR scanOutFreq = root:Packages:BS2P:CurrentScanVariables:scanOutFreq
	NVAR dwellTime = root:Packages:BS2P:CurrentScanVariables:dwellTime
	NVAR pockelValue = root:Packages:BS2P:CurrentScanVariables:pockelValue
	NVAR lineSpacing = root:Packages:BS2P:CurrentScanVariables:lineSpacing
	NVAR externalTrigger = root:Packages:BS2P:CurrentScanVariables:externalTrigger
	
	NVAR displayPixelSize = root:Packages:BS2P:CurrentScanVariables:displayPixelSize
	NVAR saveEmAll = root:Packages:BS2P:CurrentScanVariables:saveEmAll
	NVAR frames = root:Packages:BS2P:CurrentScanVariables:frames
	if(stringmatch(imageMode, "snapshot"))
		BS_2P_NiDAQ_2(runx, runy,  dum, 1, 0, imageMode)
	elseif(stringmatch(imageMode, "kinetic"))
		BS_2P_NiDAQ_2(runx, runy,  dum, frames, externaltrigger, imageMode)
	elseif(stringmatch(imageMode, "video"))
		BS_2P_NiDAQ_2(runx, runy,  dum, 10000, 0, imageMode)
	elseif(stringmatch(imageMode, "stack"))
		BS_2P_NiDAQ_2(runx, runy,  dum, 1, 0, imageMode)
	elseif(stringmatch(imageMode, "test"))
		BS_2P_NiDAQ_2(runx, runy,  dum, frames, externaltrigger, imageMode)
	endif

	
end

function BS_2P_updateKineticWindow(scaledX, displayPixelSize, scaledY, frames, X_offset, Y_offset)
	variable scaledX, displayPixelSize, scaledY, frames, X_offset, Y_offset

//	make/o/n=((scaledX/displayPixelSize),(scaledY/displayPixelSize),frames) root:Packages:BS2P:CurrentScanVariables:kineticSeries = 0
	wave kineticSeries =  root:Packages:BS2P:CurrentScanVariables:kineticSeries
	SetScale/P x (X_offset),displayPixelSize,"m", kineticSeries
	SetScale/P y (Y_offset),displayPixelSize,"m", kineticSeries
	DoWindow/F kineticWindow
	if(V_flag == 0)
		BS_2P_makeKineticWindow()
	endif
	BS_2P_Append3DImageSlider()
	
end

function BS_2P_saveDum()
	NVAR  prefixIncrement = root:Packages:BS2P:CurrentScanVariables:prefixIncrement
	SVAR currentPath = root:Packages:BS2P:CurrentScanVariables:currentPath
	SVAR SaveAsPrefix = root:Packages:BS2P:CurrentScanVariables:SaveAsPrefix
	wave dum  = root:Packages:BS2P:CurrentScanVariables:dum
	wave ePhysDum  = root:Packages:BS2P:CurrentScanVariables:ePhysDum
	wave kineticSeries = root:Packages:BS2P:CurrentScanVariables:kineticSeries
	SVAR fileName2bWritten = root:Packages:BS2P:CurrentScanVariables:fileName2bWritten
	SVAR currentPathDetails = root:Packages:BS2P:CurrentScanVariables:currentPathDetails
	string filename2Write = saveAsPrefix+num2str(prefixIncrement)+".ibw"
	string ePhysName2Write = saveAsPrefix+num2str(prefixIncrement)+"_ephys"+".ibw"
	
	save/c/o/p=$currentPath kineticSeries as filename2Write
	save/c/o/p=$currentPath ePhysDum as ePhysName2Write
	pathInfo $currentPath
	currentPathDetails = s_path
	prefixIncrement += 1
	fileName2bWritten = currentPathDetails + SaveAsPrefix + num2str(prefixIncrement)
	
	
//	string filename2Write = saveAsPrefix+num2str(prefixIncrement)+".ibw"
//	BS_2P_writeScanParamsInWave(dum)
//	if(saveEmAll == 1)
//		save/c/o/p=$currentPath dum as filename2Write
//		prefixIncrement += 1
//		fileName2bWritten = currentPathDetails + SaveAsPrefix + num2str(prefixIncrement)
//	endif

end