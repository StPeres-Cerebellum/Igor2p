#pragma rtGlobals=3		// Use modern global access method and strict wave acce

function test()
	wave config_2p
	edit/k=1/n=Config config_2p config_2p.l
	setwindow config hook(myhook)=confighook
end

function configSaveHook(s)    //This is a hook for the mousewheel movement in MatrixExplorer
	STRUCT WMWinHookStruct &s
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig 
	NVAR scanLimit = root:Packages:BS2P:CalibrationVariables:scanLimit	// limit of voltage sent to the scanners	
	NVAR scaleFactor = root:Packages:BS2P:CalibrationVariables:scaleFactor //  (m in focal plane / Volt). Same for X and Y
	NVAR mWperVolt = root:Packages:BS2P:CalibrationVariables:mWperVolt
	NVAR mWperVolt_offset = root:Packages:BS2P:CalibrationVariables:mWperVolt_offset
	NVAR luigsFocusDevice = root:Packages:BS2P:CalibrationVariables:luigsFocusDevice
	SVAR luigsFocusAxis = root:Packages:BS2P:CalibrationVariables:luigsFocusAxis
	NVAR minPockels = root:Packages:BS2P:CalibrationVariables:minPockels
	NVAR maxPockels = root:Packages:BS2P:CalibrationVariables:maxPockels
	// add max min pockels
	switch(s.eventCode)
		case 2:
//			newpath/o configPath, "C:Users:2P:Documents"
			save/o/p=configPath boardConfig
			scanLimit = str2num(boardConfig[8][2])
			scaleFactor = str2num(boardConfig[9][2])
	 		mWperVolt = str2num(boardConfig[10][2])
	 		mWperVolt_offset = str2num(boardConfig[10][3])
	 		luigsFocusDevice = str2num(boardConfig[13][2])
	 		luigsFocusAxis = boardConfig[14][2]
	 		minPockels =  str2num(boardConfig[11][2])
	 		maxPockels = str2num(boardConfig[12][2])
	 		rotatekineticWin()
//			add max/min pockels
			break
		case 1:
			scanLimit = str2num(boardConfig[8][2])
			scaleFactor = str2num(boardConfig[9][2])
			mWperVolt = str2num(boardConfig[10][2])
			mWperVolt_offset = str2num(boardConfig[10][3])
			luigsFocusDevice = str2num(boardConfig[13][2])
			luigsFocusAxis = boardConfig[14][2]
			minPockels =  str2num(boardConfig[11][2])
	 		maxPockels = str2num(boardConfig[12][2])
			rotatekineticWin()
      			// add max/min pockles
      		break
      endswitch
end

function/wave bs_2P_getConfig()
	newpath/o/z configPath, "C:Users:2P:Documents"
	if(v_flag)
		newPath/c/m="Which folder should contain the configuration file?" configPath
	endif
	variable refnum
	open/r/z/p=configPath refnum as "boardConfig.ibw"
	if(v_flag == 0)
		print "found a config", refnum, s_filename
		close refNum
		LoadWave/H/O/P=configPath "boardConfig.ibw"
		wave/t boardConfig
		killwaves/z root:Packages:BS2P:CalibrationVariables:boardConfig
		movewave boardConfig root:Packages:BS2P:CalibrationVariables:boardConfig
		updateConfig()
	else
		make/o/t/n=(30,10) root:Packages:BS2P:CalibrationVariables:boardConfig
//		wave boardConfig root:Packages:BS2P:CalibrationVariables:boardConfig
		updateConfig()
		edit/k=1/n=Config boardConfig boardConfig.l
		setwindow config hook(myhook)=configSaveHook
	endif
	return boardConfig
end

function bs_2P_editConfig()
	wave/t boardCOnfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	if(!waveexists(boardCOnfig))
		bs_2P_getConfig()
	endif
	edit/k=1/n=Config boardConfig boardConfig.l
	setwindow config hook(myhook)=configSaveHook
end


function updateCOnfig()
	wave/t boardCOnfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	
														//sets defaults unless already set
	if(!(stringMatch(getdimlabel(boardConfig,0,0),"xGalvo")))
		setdimlabel 0,0,xGalvo,boardConfig
		boardConfig[0][0] = "dev1"
		boardConfig[0][1] = "DA"
		boardConfig[0][2] = "2"
	endif

	if(!(stringMatch(getdimlabel(boardConfig,0,1),"yGalvo")))
		setdimlabel 0,1,yGalvo,boardCOnfig
		boardConfig[1][0] = "dev1"
		boardConfig[1][1] = "DA"
		boardConfig[1][2] = "3"
	endif

	if(!(stringMatch(getdimlabel(boardConfig,0,2),"Pockels")))
		setdimlabel 0,2,Pockels,boardCOnfig		
		boardConfig[2][0] = "dev1"
		boardConfig[2][1] = "DA"
		boardConfig[2][2] = "0"
	endif
	
	if(!(stringMatch(getdimlabel(boardConfig,0,3),"PMT")))
		setdimlabel 0,3,PMT,boardCOnfig
		boardConfig[3][0] = "dev1"
		boardConfig[3][1] = "PFI"
		boardConfig[3][2] = "8"		
	endif
	
	if(!(stringMatch(getdimlabel(boardConfig,0,4),"PMTshutter")))
		setdimlabel 0,4,PMTshutter,boardCOnfig
		boardConfig[4][0] = "dev1"
		boardConfig[4][1] = "0"
		boardConfig[4][2] = "0"
		boardConfig[4][3] = "<---Port number, line number"
	endif
	
	if(!(stringMatch(getdimlabel(boardConfig,0,5),"startTrig")))
		setdimlabel 0,5,startTrig,boardCOnfig
		boardConfig[5][0] = "dev1"
		boardConfig[5][1] = "PFI"
		boardConfig[5][2] = "0"
	endif	
	
	if(!(stringMatch(getdimlabel(boardConfig,0,6),"laserPhotoDiode")))	
		setdimlabel 0,6,laserPhotoDiode,boardCOnfig	
		boardConfig[6][0] = "dev1"
		boardConfig[6][1] = "AD"
		boardConfig[6][2] = "0"
	endif
	
	if(!(stringMatch(getdimlabel(boardConfig,0,8),"maxGalvoVolts")))
		setdimlabel 0,8,maxGalvoVolts,boardCOnfig
		boardConfig[8][1] = "Constant"
		boardConfig[8][2] = "4"
	endif
	
	if(!(stringMatch(getdimlabel(boardConfig,0,9),"metersPerVolt")))	
		setdimlabel 0,9,metersPerVolt,boardCOnfig		
		boardConfig[9][1] = "Constant"
		boardConfig[9][2] = "  4.32468e-05"
	endif
		
	if(!(stringMatch(getdimlabel(boardConfig,0,10),"mWPerVolt")))	
		setdimlabel 0,10,mWPerVolt,boardCOnfig		
		boardConfig[10][1] = "Constant"
		boardConfig[10][2] = "31.3"	//slope
		boardConfig[10][3] = "-7.8"	//offset
	endif
	
	if(!(stringMatch(getdimlabel(boardConfig,0,11),"minPockels")))	
		setdimlabel 0,11,minPockels,boardCOnfig		
		boardConfig[11][1] = "Constant"
		boardConfig[11][2] = "0.25833"
	endif

	if(!(stringMatch(getdimlabel(boardConfig,0,12),"maxPockels")))	
		setdimlabel 0,12,maxPockels,boardCOnfig		
		boardConfig[12][1] = "Constant"
		boardConfig[12][2] = "1.105"
	endif
	
	if(!(stringMatch(getdimlabel(boardConfig,0,13),"LuigsFocusDevice")))		
		setDimLabel 0, 13, LuigsFocusDevice,boardCOnfig
		boardConfig[13][1] = "Constant"
		boardConfig[13][2] = "3"
	endif
	
	if(!(stringMatch(getdimlabel(boardConfig,0,14),"LuigsFocusAxis")))
		setDimLabel 0, 14, LuigsFocusAxis,boardCOnfig
		boardConfig[14][1] = "Constant"
		boardConfig[14][2] = "Z"
	endif
	
	if(!(stringMatch(getdimlabel(boardConfig,0,15),"UseLuigs")))	
		setDimLabel 0, 15, UseLuigs,boardCOnfig
		boardConfig[15][1] = "Constant"
		boardConfig[15][2] = "NO"
	endif
	
	if(!(stringMatch(getdimlabel(boardConfig,0,16),"UsePI")))	
		setDimLabel 0, 16, UsePI,boardCOnfig
		boardConfig[16][1] = "Constant"
		boardConfig[16][2] = "NO"
	endif
	
	if(!(stringMatch(getdimlabel(boardConfig,0,17),"pockelsPolynomial")))
		setDimLabel 0, 17, pockelsPolynomial,boardCOnfig
		boardConfig[17][1] = "calibrationVariable"
		boardConfig[17][2] = "8.72516"
		boardConfig[17][3] = "-107.568"
		boardConfig[17][4] = "294.209"
	endif
	
	if(!(stringMatch(getdimlabel(boardConfig,0,18),"galvosParkVoltage")))	
		setDimLabel 0, 18, galvosParkVoltage,boardCOnfig
		boardConfig[18][1] = "Constant"
		boardConfig[18][2] = "6"
	endif
	
	if(!(stringMatch(getdimlabel(boardConfig,0,19),"horizontalReflect")))
		setDimLabel 0, 19, horizontalReflect,boardCOnfig
		boardConfig[19][1] = "Flip image on vertical axis"
		boardConfig[19][2] = "0"
	endif
	
	if(!(stringMatch(getdimlabel(boardConfig,0,20),"verticalReflect")))
		setDimLabel 0, 20, verticalReflect,boardCOnfig
		boardConfig[20][1] = "Flip image on horizontal axis"
		boardConfig[20][2] = "0"
	endif
	
	if(!(stringMatch(getdimlabel(boardConfig,0,21),"transposeImage")))
		setDimLabel 0, 21, transposeImage,boardCOnfig
		boardConfig[21][1] = "swap X and Y"
		boardConfig[21][2] = "0"
	endif
	
	if(!(stringMatch(getdimlabel(boardConfig,0,22),"scanXYSwitch")))
		setDimLabel 0, 22, scanXYSwitch,boardCOnfig
		boardConfig[22][1] = "Allow interchanging XY scanners"		//	If this is enabled then program will always scan with the minimum number of lines to
		boardConfig[22][2] = "NO"									//	in order to maximize the scanning speed by switching the fast axis between X and Y
	endif
	
	if(!(stringMatch(getdimlabel(boardConfig,0,23),"ePHYS1")))
		setDimLabel 0, 23, ePHYS,boardCOnfig
		boardConfig[23][0] = "dev1"
		boardConfig[23][1] = "AD"
		boardConfig[23][2] = "2"
	endif															
end
