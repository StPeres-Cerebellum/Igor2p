#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function pmtPeltierPower(onOff)
	string onOff

	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	string devNum = boardConfig[28][0]
	string port = boardConfig[28][1]
	string line = boardConfig[28][2]

	NVAR pmtPeltierTaskNumber = root:Packages:BS2P:CurrentScanVariables:pmtPeltiertaskNumber
	if(!NVAR_exists(pmtPeltierTaskNumber))
		string pfiString = "/"+devNum+"/port"+port+ "/line" + line
		daqmx_dio_config/dir=1/dev=devNum/LGRP=1 pfiString
		variable/g  root:Packages:BS2P:CurrentScanVariables:pmtPeltierTaskNumber = V_DAQmx_DIO_TaskNumber
		NVAR pmtPeltierTaskNumber = root:Packages:BS2P:CurrentScanVariables:pmtPeltierTaskNumber
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

	NVAR pmtPowerTaskNumber = root:Packages:BS2P:CurrentScanVariables:pmtPowerTaskNumber
	if(!NVAR_exists(pmtPowerTaskNumber))
		string pfiString = "/"+devNum+"/port"+port+ "/line" + line
		daqmx_dio_config/dir=1/dev=devNum/LGRP=1 pfiString
		variable/g  root:Packages:BS2P:CurrentScanVariables:pmtPowerTaskNumber = V_DAQmx_DIO_TaskNumber
		NVAR pmtPowerTaskNumber = root:Packages:BS2P:CurrentScanVariables:pmtPowerTaskNumber
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

function readPMTStatus(s)
	STRUCT WMBackgroundStruct &s
	
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	string devNum = boardConfig[29][0]
	string port = boardConfig[29][1]
	string line = boardConfig[29][2]
	
	NVAR pmtStatus = root:Packages:BS2P:CurrentScanVariables:pmtStatus
	NVAR pmtPowerTaskNumber = root:Packages:BS2P:CurrentScanVariables:pmtPowerTaskNumber
	if(!NVAR_exists(pmtPowerTaskNumber))
		string pfiString = "/"+devNum+"/port"+port+ "/line" + line
		daqmx_dio_config/dir=1/dev=devNum/LGRP=1 pfiString
		variable/g  root:Packages:BS2P:CurrentScanVariables:pmtPowerTaskNumber = V_DAQmx_DIO_TaskNumber
		NVAR pmtPowerTaskNumber = root:Packages:BS2P:CurrentScanVariables:pmtPowerTaskNumber
		variable/g root:Packages:BS2P:CurrentScanVariables:pmtStatus
		NVAR pmtStatus = root:Packages:BS2P:CurrentScanVariables:pmtStatus
	endif
	pmtStatus = fDAQmx_DIO_Read(devNum, pmtPowerTaskNumber)
	updatePMTButton()
	
	return 0	// Continue background task
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
	

	NVAR pmtStatus = root:Packages:BS2P:CurrentScanVariables:pmtStatus
	strswitch(onOff)
		case "on":
			pmtPeltierPower("on")
			sleep/S 5
			pmtPower("on")
			pmtStatus = 1
			break
		case "off":
			pmtPower("off")
			sleep/S 5
			pmtPeltierPower("off")
			pmtStatus = 0
			break
	endswitch
	
end

function updatePMTButton()

	NVAR pmtStatus = root:Packages:BS2P:CurrentScanVariables:pmtStatus
	
	if(pmtStatus == 0)
		Button PMTSwtich,win=control2p,pos={648,10},size={49,21},proc=ButtonProcPMTON,title="start pmt"
		Button PMTSwtich,win=control2p,help={"pmt is off"},fSize=11,fColor=(65535,65535,65535)
	elseif(pmtStatus == 1)
		Button PMTSwtich,win=control2p,pos={648,10},size={49,21},proc=ButtonProcPMTOFF,title="stop pmt"
		Button PMTSwtich,win=control2p,help={"pmt is on"},fSize=11,fColor=(65280,48896,48896)
	endif	

end

Function ButtonProcPMTOFF(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			pmtControl("off")
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
			pmtControl("on")
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End