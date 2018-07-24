#pragma rtGlobals=3		// Use modern global access method and strict wave access.
SetIgorHook  IgorQuitHook  = shutdown2PHook
SetIgorHook  IgorBeforeNewHook  = shutdown2PHook
	
function pmtPeltierPower(onOff)
	string onOff

	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	string devNum = boardConfig[28][0]
	string port = boardConfig[28][1]
	string line = boardConfig[28][2]

	NVAR pmtPeltierTaskNumber = root:Packages:PMTControl:pmtPeltiertaskNumber
	if(!NVAR_exists(pmtPeltierTaskNumber))
		string pfiString = "/"+devNum+"/port"+port+ "/line" + line
		daqmx_dio_config/dir=1/dev=devNum/LGRP=1 pfiString
		variable/g  root:Packages:PMTControl:pmtPeltierTaskNumber = V_DAQmx_DIO_TaskNumber
		NVAR pmtPeltierTaskNumber = root:Packages:PMTControl:pmtPeltierTaskNumber
	endif
	
	strswitch(onOff)
		case "on":
//			print "dev="+devNum, "line="+line, "port="+port, "task="+num2str(pmtPeltiertaskNumber), "state="+"1"
			fDAQmx_DIO_Write(devNum, pmtPeltiertaskNumber, 1)
			break
		case "off":
//			print "dev="+devNum, "line="+line, "port="+port, "task="+num2str(pmtPeltiertaskNumber), "state="+"0"
			fDAQmx_DIO_Write(devNum, pmtPeltiertaskNumber, 0)
			break
	endswitch
end

function pmtPower(onOff)
	string onOff

	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	string devNum = boardConfig[29][0]
	string port = boardConfig[29][1]
	string line = boardConfig[29][2]

	NVAR pmtPowerTaskNumber = root:Packages:PMTControl:pmtPowerTaskNumber
	if(!NVAR_exists(pmtPowerTaskNumber))
		string pfiString = "/"+devNum+"/port"+port+ "/line" + line
		daqmx_dio_config/dir=1/dev=devNum/LGRP=1 pfiString
		variable/g  root:Packages:PMTControl:pmtPowerTaskNumber = V_DAQmx_DIO_TaskNumber
		NVAR pmtPowerTaskNumber = root:Packages:PMTControl:pmtPowerTaskNumber
	endif
	
	strswitch(onOff)
		case "on":
//			print "dev="+devNum, "line="+line, "port="+port, "task="+num2str(pmtPowerTaskNumber), "state="+"1"
			fDAQmx_DIO_Write(devNum, pmtPowerTaskNumber, 1)
			break
		case "off":
//			print "dev="+devNum, "line="+line, "port="+port, "task="+num2str(pmtPowerTaskNumber), "state="+"0"
			fDAQmx_DIO_Write(devNum, pmtPowerTaskNumber, 0)
			break
	endswitch
end

function readPMTStatus()
	
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	string devNum = boardConfig[29][0]
	string port = boardConfig[29][1]
	string line = boardConfig[29][2]
	
	NVAR pmtStatus = root:Packages:BS2P:PMTControl:pmtStatus
	NVAR pmtPowerTaskNumber = root:Packages:BS2P:PMTControl:pmtPowerTaskNumber
	if(!NVAR_exists(pmtPowerTaskNumber))
		string pfiString = "/"+devNum+"/port"+port+ "/line" + line
		daqmx_dio_config/dir=1/dev=devNum/LGRP=1 pfiString
		variable/g  root:Packages:BS2P:PMTControl:pmtPowerTaskNumber = V_DAQmx_DIO_TaskNumber
		NVAR pmtPowerTaskNumber = root:Packages:BS2P:PMTControl:pmtPowerTaskNumber
		variable/g root:Packages:BS2P:PMTControl:pmtStatus
		NVAR pmtStatus = root:Packages:BS2P:PMTControl:pmtStatus
	endif
	pmtStatus = fDAQmx_DIO_Read(devNum, pmtPowerTaskNumber)
//	updatePMTButton()
	
//	return 0	// Continue background task
end

Function updatePMTStatus()
	Variable numTicks = 2 * 60		// Run every two seconds
	CtrlNamedBackground pmtStatusBackground, period=numTicks, proc=readPMTStatus
	CtrlNamedBackground pmtStatusBackground, start
End

Function StopUpdatingPMTStatus()
	CtrlNamedBackground pmtStatusBackground, stop
End

function pmtControl(onOff)
	string onOff
	

//	NVAR pmtStatus = root:Packages:BS2P:PMTControl:pmtStatus
	strswitch(onOff)
		case "on":
			pmtPeltierPower("on")
			sleep/S 5
			pmtPower("on")
//			pmtStatus = 1
//			Button PMTpowerSwitch,pos={23.00,4.00},size={100.00,40.00},proc=ButtonProcPMTOFF,title="Switch OFF PMT"
//			Button PMTpowerSwitch,fColor=(65535,49151,49151)

			break
		case "off":
			pmtPower("off")
			sleep/S 5
			pmtPeltierPower("off")
//			pmtStatus = 0
//			Button PMTpowerSwitch,pos={23.00,4.00},size={100.00,40.00},proc=ButtonProcPMTON,title="Switch ON PMT"
//			Button PMTpowerSwitch,fColor=(1,52428,26586)
			break
	endswitch
	
end

function updatePMTButton()

	NVAR pmtStatus = root:Packages:BS2P:PMTControl:pmtStatus
	
	if(pmtStatus == 0)
		Button PMTpowerSwitch,win=PMTControlPanel,pos={23,4},size={90,20},proc=ButtonProcPMTON,title="Switch ON PMT"

	elseif(pmtStatus == 1)
		Button PMTpowerSwitch,win=PMTControlPanel,pos={23,4},size={90,20},proc=ButtonProcPMTOFF,title="Switch OFF PMT"
	endif	

end

Function ButtonProcPMTOFF(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			pmtPower("off")
			Button PMTPower win=Control2P,pos={649.00,10.00},size={54.00,21.00},proc=ButtonProcPMTON,title="PMT (is off)"
			Button PMTPower win=Control2P,fColor=(65535,49151,49151)

			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProcPMTON(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			pmtPower("on")
			Button PMTPower win=Control2P,pos={649.00,10.00},size={54.00,21.00},proc=ButtonProcPMTOFF,title="PMT (is on)"
			Button PMTPower win=Control2P,fColor=(1,39321,19939)
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProcPMTreset(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			pmtPower("off")
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function samplePMTVoltage()

//	string crntfldr = getdatafolder(1)
//	setdatafolder root:Packages:PMTControl
	
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	string DevNum = boardConfig[31][0]
	variable Channel = str2num(boardConfig[31][2])

	make/d/n=2000/o PMTVoltageWave
	wave PMTVoltageWave //= root:packages:PMTControl:PMTVoltageWave
	setscale/p x, 0, 0.0001, PMTVoltageWave
	
	string waveDescription = "PMTVoltageWave, "+ boardConfig[31][2]
	fDAQmx_ScanStop(DevNum)
	string PMTVoltageHookString = "PMTVoltageHook(PMTVoltageWave)"
	DAQmx_Scan/DEV=DevNum/bkg/EOSH=PMTVoltageHookString waves=waveDescription

//	setdatafolder $crntfldr

end

function PMTVoltageHook(PMTVoltageWave)
	wave PMTVoltageWave
	
	NVAR pmtVoltage = root:Packages:PMTControl:pmtVoltage
	if(!NVAR_exists(pmtVoltage))
		variable/g root:Packages:PMTControl:pmtVoltage
		NVAR pmtVoltage = root:Packages:PMTControl:pmtVoltage
	endif
	
	pmtVoltage = mean(PMTVoltageWave)
	
end

Function initializePMTControl()

//	NVAR pmtVoltage = root:Packages:BS2P:PMTControl:pmtVoltage

	if(!(dataFolderExists("root:packages")))
		newDatafolder root:packages
	endif
	if(!(dataFolderExists("root:packages:PMTControl")))
		newDataFolder root:Packages:PMTControl
		variable/g root:Packages:BS2P:PMTControl:pmtStatus
		variable/g root:Packages:BS2P:PMTControl:pmtVoltage
	endif
	pmtPeltierPower("on")
	pmtPower("off")
//	SetIgorHook  IgorQuitHook  = shutdown2PHook
//	SetIgorHook  IgorBeforeNewHook  = shutdown2PHook
//	samplePMTVoltage()
//	dowindow/F PMTControlPanel
//	if(!V_Flag)
//		execute "PMTControlPanel()"
//		setWindow PMTControlPanel hook(myHook)=PMTPanelHook
//	endif
end

Window PMTControlPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(799,59,1103,284)/k=1

//	NVAR pmtStatus = root:Packages:BS2P:PMTControl:pmtStatus
//	if(pmtStatus)
		Button PMTpowerSwitch win=PMTControlPanel,pos={23,4},size={100,40},fColor=(65535,49151,49151),proc=ButtonProcPMTOFF,title="Switch OFF PMT"
//	else
//		Button PMTpowerSwitch,pos={23,4},size={90,20},proc=ButtonProcPMTON,title="Switch ON PMT"
//	endif
//	samplePMTVoltage()
	ValDisplay voltage,pos={5,126},size={150,14},title="Voltage"
	ValDisplay voltage,format="%.1W1P%"
	ValDisplay voltage,limits={0,5,4},barmisc={0,37},mode= 2,lowColor= (0,26112,13056),zeroColor= (0,26112,13056)
	ValDisplay voltage,value= #"root:packages:PMTControl:PMTVoltage"
	
	Button PMTReset,pos={156.00,26.00},size={91.00,20.00},proc=ButtonProcPMTReset,title="Reset PMT"
	Button PMTReset,fColor=(65535,65535,65535)


//	SetWindow kwTopWin,hook(myHook)=PMTPanelHook
EndMacro

Function PMTPanelHook(s)
	STRUCT WMWinHookStruct &s
	
	Variable hookResult = 0

	switch(s.eventCode)
		case 2:				// Kill WIndow
			pmtControl("off")
			StopUpdatingPMTStatus()
			break

	endswitch

	return hookResult
end

Function IgorBeforeQuitHook(unsavedExp, unsavedNotebooks, unsavedProcedures )
	Variable unsavedExp, unsavedNotebooks, unsavedProcedures
	
	pmtControl("off")

End
