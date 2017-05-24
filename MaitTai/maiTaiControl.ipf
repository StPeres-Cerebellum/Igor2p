#pragma rtGlobals=3		// Use modern global access method and strict wave access.

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	Functions to control MaiTai laser.
//	Requires python MaiTai controller to be running on the laser computer:
//	https://github.com/mgraupe/MaiTaiControl/blob/master/MaiTaiDevGui.py
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


Menu "2P"
	subMenu "Devices"
		SubMenu "Laser Control"
//			"Connect to Server", /q, connectMaiTaiServer()
			"Show controls", /q, createLaserPanel()
			"Close connection", /q, closeMaiTaiServer()

//			"Print current positions", /q, pythonReadPosition()
		end
	end
end	

Function getMaiTaiData(s)		// This is the function that will be called periodically
	STRUCT WMBackgroundStruct &s
	
	NVAR laserSock = root:Packages:laserControl:laserSock
	NVAR waveLength = root:Packages:laserControl:waveLength
	NVAR power =  root:Packages:laserControl:power
	NVAR shutter = root:Packages:laserControl:shutter
	NVAR pulsing = root:Packages:laserControl:pulsing
	NVAR humidity = root:Packages:laserControl:humidity
	NVAR status = root:Packages:laserControl:status
	SVAR error = root:Packages:laserControl:error
	SVAR pumpError = root:Packages:laserControl:pumpError
	
	SVAR laserMessage = root:Packages:laserControl:laserMessage
	
	string msg
		
	msg = SOCKITsendnrecvF(laserSock, "getRelativeHumidity", 1, 1)
	sscanf msg, "(%*f, %f %*[^\n\t]", humidity
	
	msg = SOCKITsendnrecvF(laserSock, "checkPulsing", 1, 1)
	if(stringMatch(msg, "*true*"))
		pulsing=1
	else
		pulsing=0
	endif
	laserMessage = msg
	
	msg = SOCKITsendnrecvF(laserSock, "getPower", 1, 1)
	sscanf msg, "(%*f, %f %*[^\n\t]", power
	
	msg = SOCKITsendnrecvF(laserSock, "getWavelength", 1, 1)
	sscanf msg, "(%*f, %f %*[^\n\t]", waveLength
	
	msg = SOCKITsendnrecvF(laserSock, "isLaserOn", 1, 1)
	if(stringMatch(msg, "*true*"))
		status=1
//		Button PowerSwitch win=laserControl,fColor=(0,52224,0),title="Switch OFF Laser"
	else
		status=0
//		Button PowerSwitch win=laserControl,fColor=(65280,0,0),title="Switch ON Laser"
	endif
	
	msg = SOCKITsendnrecvF(laserSock, "getShutter", 1, 1)
	if(stringMatch(msg, "*true*"))
		shutter=1
	else
		shutter=0
	endif
	
	error = SOCKITsendnrecvF(laserSock, "getStatus", 1, 1)
	error = replacestring("(1, \'", error, "")
	error = replacestring("\')...getStatus", error, "")
	pumperror = SOCKITsendnrecvF(laserSock, "getStatusPumpLaser", 1, 1)
	pumpError = replacestring("(1, \'", pumpError, "")
	pumpError = replacestring("\')...getStatus", pumpError, "")
	updateMaiTaiPanel()
	
	return 0	// Continue background task
End

Function updateMaiTaiVariables()
	Variable numTicks = 1 * 60		// Run every one second (60 ticks)
	CtrlNamedBackground maiTaiBackground, period=numTicks, proc=getMaiTaiData
	CtrlNamedBackground maiTaiBackground, start
End

Function StopUpdatingMaiTaiVariables()
	CtrlNamedBackground maiTaiBackground, stop
End

Function connectMaiTaiServer()
	string serverIP = "172.20.61.234"
	variable portNum = 6666
	
	if(!(dataFolderExists("root:packages")))
		newDatafolder root:packages
	endif
	if(!(dataFolderExists("root:packages:laserControl")))
		newDataFolder root:Packages:laserControl
		variable/g root:Packages:laserControl:waveLength
		variable/g root:Packages:laserControl:status
		variable/g root:Packages:laserControl:power
		variable/g root:Packages:laserControl:shutter
		variable/g root:Packages:laserControl:pulsing
		variable/g root:Packages:laserControl:humidity
		variable/g root:Packages:laserControl:newWavelength
		string/g root:Packages:laserControl:error; svar error = root:Packages:laserControl:error
		string/g root:Packages:laserControl:pumpError; svar pumpError = root:Packages:laserControl:pumpError
	endif
	
	variable/g root:Packages:laserControl:laserSock; NVAR laserSock = root:Packages:laserControl:laserSock
	if(sockitisitopen(laserSock)!=1)
		prompt serverIP, "What is the IP address of the laser server?"
		prompt portNum, "Which port is listening for connections?"
		DoPrompt "set IP", serverIP, portNum
		laserSock=sockitopenconnectionF(serverIP,portNum,11)
	endif
	if(sockitisitopen(laserSock)!=1)
		doalert 0, "Can't open connection to MaiTai Computer"
		return 0
	else
		string testConnection = SOCKITsendnrecvF(laserSock, "isLaserOn", 1, 1)
		if(strlen(testConnection))
//			updateMaiTaiVariables()
//			createLaserPanel()
			print "Connected to laser at "+serverIP
			return 1
		else
			error = "NO CONNECTION -- Is Mai Tai Server Listening for Connections?"
			pumpError = "NO CONNECTION -- Is Mai Tai Server Listening for Connections?"
			doalert 0, "NO CONNECTION -- Is Mai Tai Server Listening for Connections?"
			return 0
		endif
	endif
end

Function closeMaiTaiServer()
	NVAR laserSock = root:Packages:laserControl:laserSock
	StopUpdatingMaiTaiVariables()
	SOCKITsendmsgF(laserSock, "disconnect")
	SOCKITcloseConnection(laserSock)
	
	if(sockitisitopen(laserSock)!=1)
		print "Disconnected from laser"
	endif
end


Function createLaserPanel()

	NVAR waveLength = root:Packages:laserControl:waveLength
	NVAR newWaveLength = root:Packages:laserControl:newWaveLength
	if(!(dataFolderExists("root:packages")))
		newDatafolder root:packages
	endif
	if(!(dataFolderExists("root:packages:laserControl")))
		newDataFolder root:Packages:laserControl
		variable/g root:Packages:laserControl:waveLength
		variable/g root:Packages:laserControl:status
		variable/g root:Packages:laserControl:power
		variable/g root:Packages:laserControl:shutter
		variable/g root:Packages:laserControl:pulsing
		variable/g root:Packages:laserControl:humidity
		variable/g root:Packages:laserControl:newWavelength
		string/g root:Packages:laserControl:error
		string/g root:Packages:laserControl:pumpError
	endif
	dowindow/F laserControl
	if(!V_Flag)
		if(connectMaiTaiServer())
			updateMaiTaiVariables()
				
			newWavelength = waveLength * 1e9
			execute "laserControl()"
			setWindow laserControl hook(myHook)=LaserPanelHook
		endif
	endif
end

Function LaserPanelHook(s)
	STRUCT WMWinHookStruct &s
	
	Variable hookResult = 0

	switch(s.eventCode)
		case 2:				// Kill WIndow
			StopUpdatingMaiTaiVariables()
			break

	endswitch

	return hookResult
end

function updateMaiTaiPanel()
	NVAR waveLength = root:Packages:laserControl:waveLength
	NVAR power =  root:Packages:laserControl:power
	NVAR shutter = root:Packages:laserControl:shutter
	NVAR pulsing = root:Packages:laserControl:pulsing
	NVAR humidity = root:Packages:laserControl:humidity
	NVAR status = root:Packages:laserControl:status

	if(status == 0)
		Button PowerSwitch win=laserControl,title="Switch ON laser"
		ValDisplay StatusDisplay win=laserControl, title="Laser is OFF"
		dowindow control2p
		if(V_Flag)
			ValDisplay StatusDisplay,win=control2p,pos={674,32},size={80,20},title="Laser is OFF"
			ValDisplay StatusDisplay,win=control2p,limits={0,1,0},barmisc={0,0},mode= 2,lowColor= (21760,21760,21760),zeroColor= (21760,21760,21760)
			ValDisplay StatusDisplay,win=control2p,value= #"root:packages:laserControl:status"
		endif
	elseif(status == 1)
		Button PowerSwitch win=laserControl,title="Switch OFF laser"
		ValDisplay StatusDisplay win=laserControl, title="Laser is ON"
		dowindow control2p
		if(V_Flag)
			ValDisplay StatusDisplay,win=control2p,pos={674,32},size={80,20},title="Laser is ON"
			ValDisplay StatusDisplay,win=control2p,limits={0,1,0},barmisc={0,0},mode= 2,lowColor= (21760,21760,21760),zeroColor= (21760,21760,21760)
			ValDisplay StatusDisplay,win=control2p,value= #"root:packages:laserControl:status"
		endif
	endif
	
	if(shutter == 0)
		Button shutterSwitch win=laserControl,title="OPEN shutter"
		ValDisplay ShutterDisplay win=laserControl, title="Shutter is CLOSED"
		dowindow control2p
		if(V_Flag)
			ValDisplay ShutterDisplay,win=control2p,pos={643,51},size={110,20},title="Shutter is CLOSED"
			ValDisplay ShutterDisplay,win=control2p,limits={0,1,0},barmisc={0,0},mode= 2,highColor= (65280,65280,0),lowColor= (21760,21760,21760),zeroColor= (21760,21760,21760)
			ValDisplay ShutterDisplay,win=control2p,value= #"root:packages:laserControl:shutter"
		endif
	elseif(status == 1)
		Button shutterSwitch win=laserControl,title="CLOSE shutter"
		ValDisplay ShutterDisplay win=laserControl, title="Shutter is OPEN"
		dowindow control2p
		if(V_Flag)
			ValDisplay ShutterDisplay,win=control2p,pos={643,51},size={110,20},title="Shutter is OPEN"
			ValDisplay ShutterDisplay,win=control2p,limits={0,1,0},barmisc={0,0},mode= 2,highColor= (65280,65280,0),lowColor= (21760,21760,21760),zeroColor= (21760,21760,21760)
			ValDisplay ShutterDisplay,win=control2p,value= #"root:packages:laserControl:shutter"
		endif
	endif
	
	if(pulsing == 0)
		ValDisplay pulsingDisplay win=laserControl, fColor=(0,0,0), title="Laser is NOT pulsing"
	elseif(pulsing == 1)
		ValDisplay pulsingDisplay win=laserControl, fColor=(65280,0,0),title="Laser is pulsing     "
	endif
end

Function PowerButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	NVAR status = root:Packages:laserControl:status
	NVAR laserSock = root:Packages:laserControl:laserSock
	switch( ba.eventCode )
		case 2: // mouse up
			if(status == 0)
				SOCKITsendmsgF(laserSock, "switchLaserOn")
			elseif(status == 1)
				SOCKITsendmsgF(laserSock, "switchLaserOff")
			endif
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ShutterButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	NVAR shutter = root:Packages:laserControl:shutter
	NVAR laserSock = root:Packages:laserControl:laserSock
	switch( ba.eventCode )
		case 2: // mouse up
			if(shutter == 0)
				SOCKITsendmsgF(laserSock, "setShutter,True")
			elseif(shutter == 1)
				SOCKITsendmsgF(laserSock, "setShutter,False")
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function SetWavelengthProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	NVAR laserSock = root:Packages:laserControl:laserSock
	NVAR newWavelength = root:Packages:laserControl:newWavelength
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
			variable setwavelength = newWavelength*1e-9
			if(setwavelength > 690e-9 && setwavelength < 1040e-9)
//				string send
//				sprintf send, "%.*f", 3,setwavelength
				print setWavelength
				SOCKITsendmsgF(laserSock, "setWavelength, "+num2str(setWavelength))
			else 
				print setwavelength
			endif
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Window laserControl() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(799,59,1103,284)/k=1
	Button powerSwitch,pos={23,4},size={90,20},proc=PowerButtonProc,title="Switch ON laser"
	Button shutterSwitch,pos={158,3},size={90,20},proc=ShutterButtonProc,title="OPEN shutter"
	ValDisplay humidity,pos={5,126},size={150,14},title="Relative Humidity"
	ValDisplay humidity,format="%.1W1P%"
	ValDisplay humidity,limits={0,5,4},barmisc={0,37},mode= 2,lowColor= (0,26112,13056),zeroColor= (0,26112,13056)
	ValDisplay humidity,value= #"root:packages:laserControl:humidity"
	ValDisplay PulsingDisplay,pos={161,98},size={120,20},title="Laser is NOT pulsing"
	ValDisplay PulsingDisplay,limits={0,1,0},barmisc={0,0},mode= 2,lowColor= (0,0,0)
	ValDisplay PulsingDisplay,value= #"root:packages:laserControl:pulsing"
	ValDisplay StatusDisplay,pos={28,26},size={80,20},title="Laser is OFF"
	ValDisplay StatusDisplay,limits={0,1,0},barmisc={0,0},mode= 2,lowColor= (21760,21760,21760),zeroColor= (21760,21760,21760)
	ValDisplay StatusDisplay,value= #"root:packages:laserControl:status"
	ValDisplay ShutterDisplay,pos={148,26},size={110,20},title="Shutter is CLOSED"
	ValDisplay ShutterDisplay,limits={0,1,0},barmisc={0,0},mode= 2,highColor= (65280,65280,0),lowColor= (21760,21760,21760),zeroColor= (21760,21760,21760)
	ValDisplay ShutterDisplay,value= #"root:packages:laserControl:shutter"
	SetVariable showWaveLength,pos={144,140},size={143,16},title="Actual Wavelength"
	SetVariable showWaveLength,fSize=10,format="%.W1Pm"
	SetVariable showWaveLength,limits={-inf,inf,0},value= root:packages:laserControl:waveLength,noedit= 1
	ValDisplay powerDisplay,pos={5,104},size={130,14},title="Output Power"
	ValDisplay powerDisplay,format="%.0W1PW"
	ValDisplay powerDisplay,limits={0,4,1},barmisc={0,42},mode= 2,lowColor= (0,26112,13056),zeroColor= (65280,65280,0)
	ValDisplay powerDisplay,value= #"root:packages:laserControl:power"
	SetVariable setWaveLength,pos={52,58},size={180,28},proc=SetWavelengthProc,title="Set Wavelength"
	SetVariable setWaveLength,fSize=18,format="%.W1P"
	SetVariable setWaveLength,limits={-inf,inf,0},value= root:packages:laserControl:newWavelength
	TitleBox error,pos={8,165},size={285,20},disable=2
	TitleBox error,variable= root:packages:laserControl:error,fixedSize=1
	TitleBox pumpError,pos={8,190},size={285,20},disable=2
	TitleBox pumpError,variable= root:packages:laserControl:pumpError,fixedSize=1
	SetWindow kwTopWin,hook(myHook)=LaserPanelHook
EndMacro
