#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// requires SOCKIT http://www.igorexchange.com/project/SOCKIT
// 172.20.61.89
// 5555

Menu "2P"
	subMenu "Devices"
		SubMenu "Python Postions"
			"Connect to Server", /q, connectPythonPositionServer()
			"Close connection", /q, closePythonServer()
			"________"
			"Print current positions", /q, pythonReadPosition()
		end
	end
end	



Function connectPythonPositionServer()
	string serverIP = "172.20.61.89"
	variable portNum = 5555
	
	if(!(dataFolderExists("root:packages")))
		newDatafolder root:packages
	endif
	if(!(dataFolderExists("root:packages:pythonPositions")))
		newDataFolder root:Packages:pythonPositions
		variable/g root:Packages:pythonPositions:xPos
		variable/g root:Packages:pythonPositions:yPos
		variable/g root:Packages:pythonPositions:zPos
	endif
		
	variable/g root:Packages:pythonPositions:acq4Sock; NVAR acq4Sock = root:Packages:pythonPositions:acq4Sock
	make/o/t/n=1 root:Packages:pythonPositions:bufferwave; wave bufferWave = root:Packages:pythonPositions:bufferWave
	sockitopenconnection/q/proc=pythonGetPosition acq4Sock,serverIP,portNum,bufferwave
end

Function pythonGetPosition(textWave,entry)
	wave/t textWave
	variable entry
	NVAR xPos = root:Packages:pythonPositions:xPos
	NVAR yPos = root:Packages:pythonPositions:yPos
	NVAR zPos = root:Packages:pythonPositions:zPos
	sscanf textWave[entry][0], "(%*f, %f, %f, %f %*[^\n\t]", xpos, yPos, zPos
end

function pythonMoveRelative(microns, axis)
	variable microns
	string axis
	string send = "relativeMoveTo,"+axis+","+num2str(microns)
	NVAR acq4Sock = root:Packages:pythonPositions:acq4Sock
	sockitsendmsg/time=30 acq4Sock, send
end

function pythonReadPosition()
	NVAR acq4Sock = root:Packages:pythonPositions:acq4Sock		
	sockitsendmsg/time=30 acq4Sock, "getPos"
	
	NVAR xPos = root:Packages:pythonPositions:xPos
	NVAR yPos = root:Packages:pythonPositions:yPos
	NVAR zPos = root:Packages:pythonPositions:zPos
	
	print "xPos = ", xPos, "|  yPos = ", yPos, "|  zPos = ", zPos
end

Function closePythonServer()
	NVAR acq4Sock = root:Packages:pythonPositions:acq4Sock
	SOCKITcloseCOnnection(acq4Sock)
end