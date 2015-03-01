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
	// add max min pockels
	switch(s.eventCode)
		case 2:
			newpath/o configPath, "C:Users:fede:Documents"
			save/o/p=configPath boardConfig
			scanLimit = str2num(boardConfig[8][2])
			scaleFactor = str2num(boardConfig[9][2])
	 		mWperVolt = str2num(boardConfig[10][2])
//			add max/min pockels
			break
		case 1:
			scanLimit = str2num(boardConfig[8][2])
			scaleFactor = str2num(boardConfig[9][2])
			mWperVolt = str2num(boardConfig[10][2])
      			// add max/min pockles
      		break
      endswitch
end

//function/wave bs_2P_getConfigs(Device)
//	string device	//xgalvo, ygalvo, PMT, Pockels, PMTshutter, startTrig
//	make/free/t/o/n=2 devOut
//	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig
//	
//	devOut[0] = boardconfig[(findDimLabel(boardConfig,0,Device))][1]
//	devOut[1] = boardconfig[(findDimLabel(boardConfig,0,Device))][3]
//	
//	return devOut
//end

function bs_2P_getConfig()
	newpath/o configPath, "C:Users:bs:Documents"
	variable refnum
	open/r/z/p=configPath refnum as "boardConfig.ibw"
	if(v_flag == 0)
		print "found a config", refnum, s_filename
		close refNum
		LoadWave/H/O "C:Users:bs:Documents:boardConfig.ibw"
		wave/t boardConfig
		killwaves/z root:Packages:BS2P:CalibrationVariables:boardConfig
		movewave boardConfig root:Packages:BS2P:CalibrationVariables:boardConfig
	else
		make/o/t/n=(11,3) root:Packages:BS2P:CalibrationVariables:boardConfig
		wave/t boardCOnfig = root:Packages:BS2P:CalibrationVariables:boardConfig

		setdimlabel 1,0,Board,boardCOnfig
		setdimlabel 1,1,Type,boardCOnfig
		setdimlabel 1,2,Channel,boardCOnfig
		
		setdimlabel 0,0,xGalvo,boardConfig
		boardConfig[0][0] = "dev1"
		boardConfig[0][1] = "DA"
		boardConfig[0][2] = "0"
		
		setdimlabel 0,1,yGalvo,boardCOnfig
		boardConfig[1][0] = "dev1"
		boardConfig[1][1] = "DA"
		boardConfig[1][2] = "1"

		setdimlabel 0,2,Pockels,boardCOnfig		
		boardConfig[2][0] = "dev2"
		boardConfig[2][1] = "DA"
		boardConfig[2][2] = "0"

		setdimlabel 0,3,PMT,boardCOnfig
		boardConfig[3][0] = "dev2"
		boardConfig[3][1] = "PFI"
		boardConfig[3][2] = "8"		
		
		setdimlabel 0,4,PMTshutter,boardCOnfig
		boardConfig[4][0] = "dev2"
		boardConfig[4][1] = "PFI"
		boardConfig[4][2] = "2"
		
		setdimlabel 0,5,startTrig,boardCOnfig
		boardConfig[5][0] = "dev1"
		boardConfig[5][1] = "PFI"
		boardConfig[5][2] = "1"	
		
		setdimlabel 0,6,laserPhotoDiode,boardCOnfig	
		boardConfig[6][0] = "dev2"
		boardConfig[6][1] = "AD"
		boardConfig[6][2] = "0"	
	
		setdimlabel 0,8,maxGalvoVolts,boardCOnfig
		boardConfig[8][1] = "Constant"
		boardConfig[8][2] = "4"
		
		setdimlabel 0,9,metersPerVolt,boardCOnfig		
		boardConfig[9][1] = "Constant"
		boardConfig[9][2] = "33.3E-6"
		
		setdimlabel 0,10,mWPerVolt,boardCOnfig		
		boardConfig[10][1] = "Constant"
		boardConfig[10][2] = "1"
					
		edit/k=1/n=Config boardConfig boardConfig.l
		setwindow config hook(myhook)=configSaveHook
	endif
end

function bs_2P_editConfig()
	wave/t boardCOnfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	if(!waveexists(boardCOnfig))
		bs_2P_getConfig()
	endif
	edit/k=1/n=Config boardConfig boardConfig.l
	setwindow config hook(myhook)=configSaveHook
end

