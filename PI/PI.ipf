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
		variable/g  root:packages:PI_xPos
		variable/g  root:packages:PI_yPos
		variable/g  root:packages:PI_zPos
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
			sprintf piSend, "%c%c", 1,48	// DIP SWITCH SETTINGS = ON | ON | ON | ON
			break
		case "y":
			sprintf piSend, "%c%c", 1,49	// DIP SWITCH SETTINGS = ON | ON | ON | OFF
			break
		case "z":
			sprintf piSend, "%c%c", 1,50	// DIP SWITCH SETTINGS = ON | ON | OFF | ON
			break
	endswitch
	PI_sendData(piSend)
	return piSend
end

function/S PI_moveMicrons(axisLetter, microns)		//postive numbers move left/towards
	variable microns							//negative numbers move right/away
	string axisLetter
	NVAR steps2microns = root:packages:P_I:steps2microns
	variable piPosition
	string piSend
	sprintf piSend, "MR%d%c", (microns*steps2microns), 13	//MR = "move relative", 13 = ASCII carriage return
	PI_axis(axisLetter)
	PI_sendData(piSend)
	PI_tellTarget(axisLetter)
	return piSend	
end

function PI_sendData(piSend)	//FEDE uses M-126.DG1
	string piSend
	
	SVAR portNum = root:packages:P_I:portNum
	VDTOperationsPort2 $portNum
	VDT2 baud=9600, parity=0, databits=8, stopBits=1
	VDTWrite2 piSend
end

function PI_abortSmoothly()
	string piSend
	sprintf piSend, "AB1%c", 13
	PI_sendData(piSend)
end

function PI_tellPosition(axisLetter)
	string axisLetter
	string piSend
	sprintf piSend, "TP%c", 13
	string position = "none"
	string terminator
	sprintf terminator, "%c %c %c", 13, 10, 03
	NVAR steps2microns = root:packages:P_I:steps2microns
	
	PI_axis(axisLetter)
	PI_sendData(piSend)
	VDTRead2/Q/n=15/O=2/T=terminator position
	
	variable positionMicrons = (str2num(ReplaceString("P:", position, "")) / steps2microns)
	
	NVAR PI_xPos = root:packages:PI_xPos
	NVAR PI_yPos = root:packages:PI_yPos
	NVAR PI_zPos = root:packages:PI_zPos
	
	strswitch (axisLetter)
		case "x":
			PI_xPos = positionMicrons//; print PI_xPos
			break
		case "y":
			PI_yPos = positionMicrons
			break
		case "z":
			PI_zPos = positionMicrons
			break
	endswitch
	
	return positionMicrons
end

function PI_tellTarget(axisLetter)
	string axisLetter
	string piSend
	sprintf piSend, "TT%c", 13
	string position = "none"
	string terminator
	sprintf terminator, "%c %c %c", 13, 10, 03
	NVAR steps2microns = root:packages:P_I:steps2microns
	
	PI_axis(axisLetter)
	PI_sendData(piSend)
	VDTRead2/Q/n=15/O=2/T=terminator position
	
	variable positionMicrons = (str2num(ReplaceString("T:", position, "")) / steps2microns)
	
	NVAR PI_xPos = root:packages:PI_xPos
	NVAR PI_yPos = root:packages:PI_yPos
	NVAR PI_zPos = root:packages:PI_zPos
	
	strswitch (axisLetter)
		case "x":
			PI_xPos = positionMicrons//; print PI_xPos
			break
		case "y":
			PI_yPos = positionMicrons
			break
		case "z":
			PI_zPos = positionMicrons
			break
	endswitch
	
	return positionMicrons
end

function PI_tellAllPositions()
	PI_tellPosition("x")
	sleep/s 0.02
	PI_tellPosition("y")
	sleep/s 0.02
	PI_tellPosition("z")
end
