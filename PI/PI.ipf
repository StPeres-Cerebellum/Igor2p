#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "2P"
	Submenu "Devices"
		SubMenu "PI"
			"Initialize PI", /q, PI_Initialize()
			"Center Stage", /q, PI_center()
		end
	end
end

function PI_initialize()
	if(datafolderexists("root:packages:P_I")==0)
		newdatafolder root:packages:P_I
		string/g  root:packages:P_I:portnum //e.g. "COMX"  look it up (WIndows = Device Manager)
		variable/g  root:packages:P_I:steps2microns = 100	//look this up for the corresponding PI stage
	endif												
	string newPort
	SVAR portNum = root:packages:P_I:portnum
	VDTGetPortList2
	prompt newPort, "Available ports", popup, S_VDT
	doPrompt "P I is connected to which USB port?", newPort
	portnum = newPort
	VDTOPenPort2 $portNum
	PI_center()
end

function PI_center()
	string piSend
	sprintf piSend, "FE2%c", 13
	PI_sendData(piSend)
end

function/S PI_axis(axisLetter)	//FEDE uses M-126.DG1
	string axisLetter
	string piSend
	strswitch (axisLetter)
		case "x":
			sprintf piSend, "%c%c", 1,48
			break
		case "y":
			sprintf piSend, "%c%c", 1,49
			break
	endswitch
	PI_sendData(piSend)
	return piSend
end

function/S PI_moveMicrons(axisLetter, microns)		//postive numbers move left/towards
	variable microns							//negative numbers move right/away
	string axisLetter
	NVAR steps2microns = root:packages:P_I:steps2microns
	string piSend
	sprintf piSend, "MR%d%c", (microns*steps2microns), 13
	PI_axis(axisLetter)
	PI_sendData(piSend)
	return piSend	
end

function PI_sendData(piSend)	//FEDE uses M-126.DG1
	string piSend
	
	SVAR portNum = root:packages:P_I:portNum
	VDTOperationsPort2 $portNum
	VDT2 baud=9600, parity=0, databits=8, stopBits=1
	VDTWrite2 piSend
end