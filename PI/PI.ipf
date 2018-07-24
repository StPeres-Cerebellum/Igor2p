#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "2P"
	Submenu "Devices"
		SubMenu "PI"
			"Initialize PI", /q, PI_Initialize()
			"Center Stage", /q, PI_center()
			subMenu "Go to Position"
				//root:Packages:P_I:posList, /q, PI_moveToSavedPosition()
				dimlabels2List(root:Packages:P_I:stagePositions,0), /q, PI_moveToSavedPosition()
			end
		end
	end
end

Menu "GraphMarquee"
	"-"
	Submenu "Microscope Positions"
		"Record New", /q, PI_addNewPosition()
		subMenu "Go to Position"
			//root:Packages:P_I:posList, /q, PI_moveToSavedPosition()
			dimlabels2List(root:Packages:P_I:stagePositions,0), /q, PI_moveToSavedPosition()
		end
		"Show Positions", /q,  PI_showPositionsTable()
		"Refresh positions", /q, PI_tellAllPositions()
	end
end

function PI_initialize()
	if(datafolderexists("root:packages:P_I")==0)
		newdatafolder root:packages:P_I
		string/g  root:packages:P_I:portnum //e.g. "COMX"  look it up (WIndows = Device Manager)
		variable/g  root:packages:P_I:steps2microns = 100	//look this up for the corresponding PI stage
		variable/g  root:packages:P_I:PI_xPos
		variable/g  root:packages:P_I:PI_yPos
		variable/g  root:packages:P_I:PI_zPos
		variable/g root:packages:P_I:PI_moving
	endif												
	string newPort
	SVAR portNum = root:packages:P_I:portnum
	VDTGetPortList2
	prompt newPort, "Available ports", popup, S_VDT
	doPrompt "P I is connected to which USB port?", newPort
	portnum = newPort
	VDTOPenPort2 $portNum
	PI_makePositionsTable()
//	PI_center()
//	updatePIStatus()
end

function PI_center()
	string piSend
	sprintf piSend, "FE2%c", 13
	PI_axis("x")
	PI_sendData(piSend)

	PI_axis("y")
	PI_sendData(piSend)

	PI_axis("z")
	PI_sendData(piSend)
	
	
	PI_tellPosition("x")
	PI_tellPosition("y")
	PI_tellPosition("z")

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
	NVAR PI_moving =root:packages:P_I:PI_moving
	SVAR portNum = root:packages:P_I:portNum

	NVAR PI_xPos = root:packages:P_I:PI_xPos
	NVAR PI_yPos = root:packages:P_I:PI_yPos
	NVAR PI_zPos = root:packages:P_I:PI_zPos
	
	strswitch (axisLetter)
		case "x":
			if((microns + PI_xPos) > 14000 || (microns + PI_xPos) < -14000)
				doalert 0, "Can't move that far"
				 return ""
			endif
			 break
		case "y":
			if((microns + PI_yPos) > 14000 || (microns + PI_yPos) < -14000)
				doalert 0, "Can't move that far"
				 return ""
			endif
			 break
		case "z":
			if((microns + PI_zPos) > 14000 || (microns + PI_zPos) < -14000)
				doalert 0, "Can't move that far"
				 return ""
			endif
			 break
		endSwitch

		variable piPosition
		string piSend
		sprintf piSend, "MR%d%c", (microns*steps2microns), 13	//MR = "move relative", 13 = ASCII carriage return
//		print piSend
		PI_axis(axisLetter)
		PI_sendData(piSend)
		do	//don't do anything until motor stops moving
			string terminator, PI_movingSTR
			sprintf terminator, "%c %c %c", 13, 10, 03
			VDTOperationsPort2 $portNum
			VDT2 baud=9600, parity=0, databits=8, stopBits=1
			VDTWrite2 "\\"
			VDTRead2/Q/n=15/O=2/T=terminator PI_movingSTR
		
			PI_moving = str2num(PI_movingSTR)
		while(PI_moving)

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
//	string piSend
//	sprintf piSend, "TP%c", 13
	string position = "none"
	string terminator
	sprintf terminator, "%c %c %c", 13, 10, 03
	NVAR steps2microns = root:packages:P_I:steps2microns
	
	PI_axis(axisLetter)
	PI_sendData("\'")
//	PI_sendData(piSend)
	VDTRead2/Q/n=15/O=2/T=terminator position
//	print position
	
	variable positionMicrons = (str2num(ReplaceString("P:", position, "")) / steps2microns)
	
	NVAR PI_xPos = root:packages:P_I:PI_xPos
	NVAR PI_yPos = root:packages:P_I:PI_yPos
	NVAR PI_zPos = root:packages:P_I:PI_zPos
	
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
	
	NVAR PI_xPos = root:packages:P_I:PI_xPos
	NVAR PI_yPos = root:packages:P_I:PI_yPos
	NVAR PI_zPos = root:packages:P_I:PI_zPos
	
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
//	sleep/s 0.02
	PI_tellPosition("y")
//	sleep/s 0.02
	PI_tellPosition("z")
end

function PI_makePositionsTable()
	make/n=(1,3)/o  root:Packages:P_I:stagePositions
	string/g root:Packages:P_I:posList = dimlabels2List(root:Packages:P_I:stagePositions,0)
	wave stagePositions = root:Packages:P_I:stagePositions
	setDimLabel 1, 0, X, stagePositions
	setDimLabel 1, 1, Y, stagePositions
	setDimLabel 1, 2, Z, stagePositions
	setDimLabel 0, 0, Zeros, stagePositions
	string/g root:Packages:P_I:posList = dimlabels2List(root:Packages:P_I:stagePositions,0)
end

function PI_addNewPosition()
	NVAR PI_xPos = root:packages:P_I:PI_xPos
	NVAR PI_yPos = root:packages:P_I:PI_yPos
	NVAR PI_zPos = root:packages:P_I:PI_zPos
		
	if(!waveExists(root:Packages:P_I:stagePositions))
		PI_makePositionsTable()
	endif
	
	wave stagePositions = root:Packages:P_I:stagePositions
	
	insertPoints (dimSize(stagePositions,0)), 1, stagePositions
	string positionName = "__Add New Name__"
	prompt positionName, "Name this position"
	DoPrompt "set name", positionName
	
	PI_tellAllPositions()
	
	variable newPositionIndex = dimSize(stagePositions,0)-1//; print newPositionIndex
	stagePositions[newPositionIndex][0] = PI_xPos
	stagePositions[newPositionIndex][1] = PI_yPos
	stagePositions[newPositionIndex][2] = PI_zPos
	setDimLabel 0, (newPositionIndex), $positionName, stagePositions
	
	SVAR posList = root:Packages:P_I:posList
	posList = dimlabels2List(root:Packages:P_I:stagePositions,0)
	doUpdate
	 PI_showPositionsTable()
end

function PI_moveToSavedPosition()
	
	getlastusermenuinfo
	variable positionNum = v_value-1//; print positionNum
	wave stagePositions = root:Packages:P_I:stagePositions
	
	NVAR PI_xPos = root:packages:P_I:PI_xPos
	NVAR PI_yPos = root:packages:P_I:PI_yPos
	NVAR PI_zPos = root:packages:P_I:PI_zPos
	
//	PI_tellAllPositions()
	
	variable moveX = stagePositions[positionNum][0] - PI_xPos
	variable moveY = stagePositions[positionNum][1] - PI_yPos
	variable moveZ = stagePositions[positionNum][2] - PI_zPos
	
	print moveX, moveY, moveZ
	
	PI_moveMicrons("x", moveX)
	PI_moveMicrons("y", moveY)
	PI_moveMicrons("z", moveZ)
	
end


function PI_showPositionsTable()
	doWindow/F stagePosition
	if(!v_flag)
		edit/k=1/n=stagePosition root:Packages:P_I:stagePositions.ld
	endif
end

Function PI_checkMovingInBackground(s)		// This is the function that will be called periodically
	STRUCT WMBackgroundStruct &s
	
	
	NVAR PI_moving =root:packages:P_I:PI_moving
//	NVAR PI_xPos = root:Packages:P_I:PI_xPos
//	NVAR PI_yPos = root:Packages:P_I:PI_yPos
//	NVAR PI_zPos = root:Packages:P_I:PI_zPos
//	SVAR PI_movingSTR = root:Packages:P_I:
	string terminator,PI_movingSTR,piAxis
	sprintf terminator, "%c %c %c", 13, 10, 03


	SVAR portNum = root:packages:P_I:portNum
	VDTOperationsPort2 $portNum
	VDT2 baud=9600, parity=0, databits=8, stopBits=1
	VDTWrite2 "\\"
	VDTRead2/Q/n=15/O=2/T=terminator PI_movingSTR
	
//	print PI_movingSTR
	
	PI_moving = str2num(PI_movingSTR)
	
	
	PI_tellPosition("x")
	PI_tellPosition("y")
	PI_tellPosition("z")
	
	return 0	// Continue background task
end

Function updatePIStatus()
	Variable numTicks = 10		// Run every 5 60ths of a second (1 ticks)
	CtrlNamedBackground PIMovingBackground, period=numTicks, proc=PI_checkMovingInBackground
	CtrlNamedBackground PIMovingBackground, start
End

Function stopUpdatingPIStatus()
	CtrlNamedBackground PIMovingBackground, stop
end