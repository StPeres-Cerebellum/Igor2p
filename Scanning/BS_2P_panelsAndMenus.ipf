#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "Luigs"
#include "PI"
#include "BS_2P_Import"
#include "BS_2P_makeImages"
#include "BS_2P_makescans"
#include "BS_2P_scanProcs"
#include "bs_2p_scratchpad"
#include "bs_freehandrois_2p"
#include "BS_ROI_Analysis_2p"
#include "bs_2P_config"
#include "bs_python_pi_position"
#include "BS_Utilities"
#include "BS_2P_multipleScans"
#include "maiTaiControl"
#include "BS_2P_PMTPowerControl"
#include <all ip procedures>

Menu "2P"
//	Submenu "Panels"
		"Turn ON 2P", /q, MakeControl2PPanel()
	"-----"
//	end
//	SubMenu "Import"
//		"1 wave", /q, BS_2P_Import1()
//	end
	subMenu "Devices"
		SubMenu "PMT shutter"
			"Open", /q, BS_2P_PMTShutter("open")
			"Close", /q, BS_2P_PMTShutter("close")
		end
		SubMenu "Pockels"
			"Open", /q, BS_2P_Pockels("open")
			"Close", /q, BS_2P_Pockels("close")
			"-----"
//			"Set Max Power", /q, calibratePockels()
			"Calibrate With Power Meter", /q, calibratePower()

		end
		subMenu "Galvos"
			"Center", /q, bs_2P_zeroscanners("center")
			"Offset", /q, bs_2P_zeroscanners("offset")
		end
	//	subMenu "Configure BNCs"
			"Edit Configuration", /q, bs_2P_editConfig()
	//	end
		
		"Multi Scan", /q, makeMultiPanel()
	End
	"-"
	"Measure laser Power", /q, readLaserPower()
	"-"
	"Reset", /q, bs_2P_reset2P()

end

Menu "GraphMarquee"
	"-"
	Submenu "2P Scan"
		"Scan here", /q, arbitraryScan()
		"Multiple scans", /q, multipleScans()
	end
	SubMenu "Image Tools"
		"Measure distances", /q, BS_2P_measure()
	end
end


Function MakeControl2PPanel()
	Dowindow/F Control2p
	If(V_flag == 0)
		execute "Control2P()"
	endif
end

Window Control2P() : Panel
	Init2PVariables()
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(11,57,775,132)
	ModifyPanel cbRGB=(65534,65534,65534)
	SetDrawLayer UserBack
	SetDrawEnv linefgc= (48896,49152,65280),fillfgc= (60928,60928,60928),fillbgc= (48896,49152,65280)
	DrawRect 5,1,759,71
	DrawText 414,21,"Pockels"
	SetDrawEnv fsize= 14,fstyle= 1,textrgb= (0,0,65280)
	DrawText 12,23,"Current field of view: "
	SetDrawEnv fsize= 10
	DrawText 22.263356125897,38.189810026163,"Line Spacing:"
	SetDrawEnv fsize= 10
	DrawText 307.263356125897,22.189810026163,"Digitization:"
	DrawText 308,37,"in:"
	SetDrawEnv fsize= 10
	DrawText 151.263356125897,38.189810026163,"Lines:"
	
	Button BS_FullFrame,pos={705.00,10.00},size={54.00,21.00},proc=BS_2P_FullFieldProc,title="Full-field"
	Button BS_FullFrame,help={")ne fram of the entire field of view"},fSize=11
	Button BS_FullFrame,fColor=(0,12800,52224)

	
	SetVariable BS_2P_framerate,pos={21,156},size={167,16},bodyWidth=48,proc=SetKCTProc,title="Time between frames (s)"
	SetVariable BS_2P_framerate,fSize=11,format="%.3f"
	SetVariable BS_2P_framerate,limits={0,inf,0},value= root:Packages:BS2P:CurrentScanVariables:KCT,noedit= 1
	SetVariable DisplayScaledX,pos={165,7},size={49,16},title=" "
	SetVariable DisplayScaledX,labelBack=(60928,60928,60928),format="%.1W1Pm"
	SetVariable DisplayScaledX,frame=0,valueBackColor=(60928,60928,60928)
	SetVariable DisplayScaledX,limits={-inf,inf,0},value= root:Packages:BS2P:CurrentScanVariables:scaledX,noedit= 1
	SetVariable DisplayScaledY,pos={215,7},size={67,16},bodyWidth=53,title=" X"
	SetVariable DisplayScaledY,labelBack=(60928,60928,60928),format="%.1W1Pm"
	SetVariable DisplayScaledY,frame=0,valueBackColor=(60928,60928,60928)
	SetVariable DisplayScaledY,limits={-inf,inf,0},value= root:Packages:BS2P:CurrentScanVariables:scaledY,noedit= 1
	SetVariable DisplayInDigitization,pos={320,21},size={64,16},proc=BS_2P_SetScanVarProc,title=" "
	SetVariable DisplayInDigitization,labelBack=(60928,60928,60928),fSize=10
	SetVariable DisplayInDigitization,format="%.1W1PHz",frame=0,fStyle=1
	SetVariable DisplayInDigitization,valueBackColor=(60928,60928,60928)
	SetVariable DisplayInDigitization,limits={-inf,inf,0},value= root:Packages:BS2P:CurrentScanVariables:AcquisitionFrequency,noedit= 1
	SetVariable DisplayPockelsPercent,pos={404,19},size={92,30},title=" "
	SetVariable DisplayPockelsPercent,labelBack=(60928,60928,60928),font="Arial"
	SetVariable DisplayPockelsPercent,fSize=22,format="%.2f V",frame=0,fStyle=1
	SetVariable DisplayPockelsPercent,valueBackColor=(60928,60928,60928)
	SetVariable DisplayPockelsPercent,limits={0,2,0.01},value= root:Packages:BS2P:CurrentScanVariables:pockelValue
	PopupMenu galvoFreq,pos={9,49},size={133,21},proc=BS2P_setFreqPopMenuProc,title="Line Speed (KHz):"
	PopupMenu galvoFreq,mode=3,popvalue="0.25",value= #"\"0.25;0.5;1.0;1.5;2.0;2.5;3.0\""
	SetVariable lineSpacing,pos={85,22},size={65,16},proc=BS_2P_SetScanVarProc,title=" "
	SetVariable lineSpacing,labelBack=(60928,60928,60928),fSize=10,format="%.1W1Pm"
	SetVariable lineSpacing,frame=0,fStyle=1,valueColor=(0,0,52224)
	SetVariable lineSpacing,valueBackColor=(60928,60928,60928)
	SetVariable lineSpacing,limits={0.2,500,0},value= root:Packages:BS2P:CurrentScanVariables:lineSpacing
	PopupMenu pixelsPerLine,pos={150,49},size={102,21},proc=PixPerLinePopMenuProc,title="Pixels/Line"
	PopupMenu pixelsPerLine,mode=8,popvalue="256",value= #"\"8;16;32;64;128;256;512;1024\""
	SetVariable lineDisplay,pos={182,22},size={31,16},proc=BS_2P_SetScanVarProc,title=" "
	SetVariable lineDisplay,labelBack=(60928,60928,60928),fSize=10,frame=0,fStyle=1
	SetVariable lineDisplay,valueColor=(0,0,52224)
	SetVariable lineDisplay,valueBackColor=(60928,60928,60928)
	SetVariable lineDisplay,limits={0.2,500,0},value= root:Packages:BS2P:CurrentScanVariables:totalLines
	ValDisplay measuredPower,pos={392,50},size={120,14},title="Last reading:"
	ValDisplay measuredPower,labelBack=(60928,60928,60928),format="%.1W1PmW",frame=0
	ValDisplay measuredPower,valueColor=(52224,0,0)
	ValDisplay measuredPower,valueBackColor=(60928,60928,60928)
	ValDisplay measuredPower,limits={0,0,0},barmisc={0,1000}
	ValDisplay measuredPower,value= #"root:Packages:BS2P:CurrentScanVariables:laserPower"
	GroupBox ephysBox,pos={520,5},size={119,65},title="ePhys"
	CheckBox ePhysRec,pos={539,24},size={82,14},title="Collect ePhys"
	CheckBox ePhysRec,variable= root:Packages:BS2P:CurrentScanVariables:ePhysREC
	SetVariable EphysFreq,pos={527,39},size={104,16},title="Dig. Freq (kHz)"
	SetVariable EphysFreq,limits={-inf,inf,0},value= root:Packages:BS2P:CurrentScanVariables:ePhysFreq
	CheckBox fixedDwell,pos={293,54},size={80,14},proc=fixDwellTime,title="Fix dwell time"
	CheckBox fixedDwell,variable= root:Packages:BS2P:CurrentScanVariables:fixedDwell
	SetVariable dwellTime,pos={297,36},size={92,16},proc=SetDwellProc,title="Dwell time"
	SetVariable dwellTime,format="%.0W1Ps"
	SetVariable dwellTime,limits={-inf,inf,0},value= root:Packages:BS2P:CurrentScanVariables:dwellTime
	
	initializePMTControl()
	Button PMTPower,pos={649.00,10.00},size={54.00,21.00},proc=ButtonProcPMTON,title="PMT (is off)"
	Button PMTPower,help={"switch on PMT"},fSize=9
	Button PMTPower,fColor=(65535,49151,49151)

	
//	updatePMTStatus()
	setWindow Control2P hook(myHook)=ShutdownHook

EndMacro


Function Init2PVariables()
	
	if(datafolderexists("root:Packages:BS2P") == 0)
		newdatafolder/o root:Packages
		newdatafolder/o root:Packages:BS2P
		newdatafolder/o root:Packages:BS2P:CalibrationVariables
		newdatafolder/o root:Packages:BS2P:CurrentScanVariables
		newdatafolder/o root:Packages:BS2P:ImageDisplayVariables
		
		wave/t boardConfig = bs_2P_getConfig()
		if(stringMatch((boardConfig[15][2]), "YES"))
			LN_initialize()
			LN_setSpeed((str2num(boardConfig[13][2])), boardConfig[14][2], 16)
		endif
		if(stringMatch((boardConfig[16][2]), "YES"))
			PI_Initialize()
		endif
		if(stringMatch((boardConfig[24][2]), "YES"))
			connectPythonPositionServer()
		endif
		
		
////////////////	Stored Calibration Variables	////////////////////	
		variable/g root:Packages:BS2P:CalibrationVariables:scanLimit = str2num(boardConfig[8][2])	// limit of voltage sent to the scanners	
		variable/g root:Packages:BS2P:CalibrationVariables:scaleFactor = 	str2num(boardConfig[9][2]) //  (m in focal plane / Volt). Same for X and Y
		variable/g root:Packages:BS2P:CalibrationVariables:mWperVolt = str2num(boardConfig[10][2])
		variable/g root:Packages:BS2P:CalibrationVariables:mWperVolt_offset = str2num(boardConfig[10][3])
		
		variable/g root:Packages:BS2P:CalibrationVariables:minPockels = str2num(boardConfig[11][2])
		variable/g root:Packages:BS2P:CalibrationVariables:maxPockels = str2num(boardConfig[12][2])
//		variable/g root:Packages:BS2P:CalibrationVariables:freqLimit = 100e3	// upper bound of scan freq in Hz
//		variable/g root:Packages:BS2P:CalibrationVariables:Correction4percent = 2 // (volts/percent open) hopefully this is linear!		
		variable/g root:Packages:BS2P:CalibrationVariables:luigsFocusDevice = str2num(boardConfig[13][2])
		string/g root:Packages:BS2P:CalibrationVariables:luigsFocusAxis = boardConfig[14][2]
		
////////////////	Stored Current Scan Variables	////////////////////
		variable/g root:Packages:BS2P:CurrentScanVariables:lineSpacing = 0.6e-6		 //--- determines distance between lines initializes to a minimum
		variable/g root:Packages:BS2P:CurrentScanVariables:scaledX = 0	//Distance of X-axis scan in m
		variable/g root:Packages:BS2P:CurrentScanVariables:scaledY = 0	//Distance of Y-axis scan in m
		variable/g root:Packages:BS2P:CurrentScanVariables:X_Offset = 0	//Where to start the X-axis scan in µm from center
		variable/g root:Packages:BS2P:CurrentScanVariables:Y_Offset = 0	//Where to start the Y-axis scan in µm from center
		variable/g root:Packages:BS2P:CurrentScanVariables:lineTime = 2e-3	//ms / line
		variable/g root:Packages:BS2P:CurrentScanVariables:scanOutFreq = 100e3	//kHz resolution to send to galcos
		variable/g root:Packages:BS2P:CurrentScanVariables:KCT = 100e-3	//Time between frames of a kinetic series
		variable/g root:Packages:BS2P:CurrentScanVariables:frames = 1	//Number of frames in a kinetic series
		variable/g root:Packages:BS2P:CurrentScanVariables:externalTrigger =  0	//Trigger externally?
		variable/g root:Packages:BS2P:CurrentScanVariables:pockelTest = 0	//Keep pockel's cell open for testing
		variable/g root:Packages:BS2P:CurrentScanVariables:AcquisitionFrequency = 2e6	//Digitization of PMT in kHz
		variable/g root:Packages:BS2P:CurrentScanVariables:LaserDisplay = 0	//Number to display for Laser (depends on mW or %)
		variable/g root:Packages:BS2P:CurrentScanVariables:pixelsPerLine = 256
		variable/g root:Packages:BS2P:CurrentScanVariables:totalLines = 256
		variable/g root:Packages:BS2P:CurrentScanVariables:zoomFactor = 20	// in microns
		variable/g root:Packages:BS2P:CurrentScanVariables:stackDepth = 100 //microns
		variable/g root:Packages:BS2P:CurrentScanVariables:stackResolution = 1 //microns
		
		string/g root:Packages:BS2P:CurrentScanVariables:SaveAsPrefix = "prefix"	//Prefix to add to saved data
		string/g root:Packages:BS2P:CurrentScanVariables:currentPathDetails = "no path set"
		string/g root:Packages:BS2P:CurrentScanVariables:pathsListing = ""
		string/g root:Packages:BS2P:CurrentScanVariables:pathDetailsListing = "__NEW__"
		string/g root:Packages:BS2P:CurrentScanVariables:currentPath= ""
		string/g root:Packages:BS2P:CurrentScanVariables:fileName2bWritten= ""
		variable/g root:Packages:BS2P:CurrentScanVariables:prefixIncrement = 0
		variable/g root:Packages:BS2P:CurrentScanVariables:saveEmAll = 0
		variable/g root:Packages:BS2P:CurrentScanVariables:saveEphys = 0
		variable/g root:Packages:BS2P:CurrentScanVariables:fixedDwell = 0
		
		
		variable/g root:Packages:BS2P:CurrentScanVariables:powermW = 0 //Display mW for the power
		variable/g root:Packages:BS2P:CurrentScanVariables:powerPercent = 1 //Display % for the power
		variable/g root:Packages:BS2P:CurrentScanVariables:pockelValue = 0
		
		variable/g root:Packages:BS2P:CurrentScanVariables:dwellTime = 0.5e-3	// (s) default to medium
		variable/g root:Packages:BS2P:CurrentScanVariables:lineSpacing = 0.6e-6	// (meters)
		variable/g root:Packages:BS2P:CurrentScanVariables:scanFrameTime = 0	//ms
		variable/g  root:Packages:BS2P:CalibrationVariables:spotSize = 0.6e-6	//smallest theoretical spot from Bruno (m)
		variable/g  root:Packages:BS2P:CalibrationVariables:pixelShift = 87.5e-6	// s  ---measure this by giving voltages to scanners
		variable/g  root:Packages:BS2P:CurrentScanVariables:focusStep = 20		// µm
		variable/g root:Packages:BS2P:CurrentScanVariables:fullField = 250e-6	//m to scan for a full field
		variable/g root:Packages:BS2P:CurrentScanVariables:objectiveMag = 60
		variable/g root:Packages:BS2P:CurrentScanVariables:samplesPerPixel = 1
		variable/g root:Packages:BS2P:CurrentScanVariables:moveStep = 20 //microns
		variable/g root:Packages:BS2P:CurrentScanVariables:laserPower
		variable/g root:Packages:BS2P:CurrentScanVariables:XYswapped = 0

		variable/g root:Packages:BS2P:CurrentScanVariables:frameAvg = 1

		variable/g root:Packages:BS2P:CurrentScanVariables:trigLoop = 0

		
////////////////	ePHYS	////////////////////		
		variable/g root:Packages:BS2P:CurrentScanVariables:ePhysFreq = 10 	//kHz
		variable/g root:Packages:BS2P:CurrentScanVariables:ePhysREC = 0
		
////////////////	Used For Display Only	////////////////////
		variable/g root:Packages:BS2P:CurrentScanVariables:displayFrameTime = 0
		variable/g root:Packages:BS2P:CurrentScanVariables:displayFrameHz = 0
		variable/g root:Packages:BS2P:CurrentScanVariables:displayTotalTime = 0
		Variable/g root:Packages:BS2P:CurrentScanVariables:displaySpeed = 1	//display speed
		variable/g root:Packages:BS2P:CurrentScanVariables:displayPixelSize
		make/n=0/o root:Packages:BS2P:CurrentScanVariables:multiScanOffsets
		make/n=3/o root:Packages:BS2P:CalibrationVariables:pockelsPolynomial = {(str2num(boardConfig[17][2])),(str2num(boardConfig[17][3])),(str2num(boardConfig[17][4]))}
		variable/g root:Packages:BS2P:CurrentScanVariables:pmtStatus = 0
	endif
	NVAR luigsFocusDevice = root:Packages:BS2P:CalibrationVariables:luigsFocusDevice
	SVAR luigsFocusAxis = root:Packages:BS2P:CalibrationVariables:luigsFocusAxis
	
End

function BS_2P_makeKineticWindow()
	NVAR frames =  root:Packages:BS2P:CurrentScanVariables:frames
	NVAR scanLimit = root:Packages:BS2P:CalibrationVariables:scanLimit 		//volts
	NVAR scaleFactor = root:Packages:BS2P:CalibrationVariables:scaleFactor		//meters per volt
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
	wave/t boardCOnfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	
	make/o/n=(pixelsPerline,pixelsPerLine) root:Packages:BS2P:CurrentScanVariables:kineticSeries
	wave kineticSeries = root:Packages:BS2P:CurrentScanVariables:kineticSeries
	print  (-1 * scanLimit * scaleFactor),(scanLimit * scaleFactor),"m"
	SetScale x (-1 * scanLimit * scaleFactor),(scanLimit * scaleFactor),"m", kineticSeries
	SetScale y (-1 * scanLimit * scaleFactor),(scanLimit * scaleFactor),"m", kineticSeries
	
	PauseUpdate; Silent 1		// building window...
	Display /W=(9,133.25,582.75,463.25)/K=1  as "Kinetic Window"
	DoWindow/C kineticWindow
	setWindow kineticWindow hook(myHook)=kineticWIndowHook

	appendimage root:Packages:BS2P:CurrentScanVariables:kineticSeries
	DoWindow/C kineticWindow
	SetDrawEnv/W=kineticWindow xcoord= bottom,ycoord= left,linefgc= (65280,0,0),dash= 2;DelayUpdate

	DrawLine/W=kineticWindow  (-39e-6), (-23.9e-6),  (-19e-6),  (-23.9e-6)
	SetDrawEnv/W=kineticWindow xcoord= bottom,ycoord= left,linefgc= (65280,0,0),dash= 2;DelayUpdate

	DrawLine/W=kineticWindow  (-29e-6), (-34e-6),  (-29e-6),  (-14e-6)
	ModifyGraph width=0,height={Plan,1,left,bottom}
	ModifyGraph mirror=2
	ModifyGraph minor=1

	ControlBar 80

	SetVariable BS_2P_pixelShifter,pos={5,33},size={115,16},title="Pixel Shift"
	SetVariable BS_2P_pixelShifter,frame=0,valueBackColor=(60928,60928,60928)
	SetVariable BS_2P_pixelShifter,limits={0,0.0002,5e-07},value= root:Packages:BS2P:CalibrationVariables:pixelShift

//	SetVariable SetPixelSize,pos={4,31},size={90,16},proc=BS_2P_setPixelSizeProc,title="Binning (µm):"
//	SetVariable SetPixelSize,frame=0,valueColor=(65280,0,0)
//	SetVariable SetPixelSize,valueBackColor=(60928,60928,60928)
//	SetVariable SetPixelSize,limits={0.025,inf,0},value= root:Packages:BS2P:CurrentScanVariables:displayPixelSize
	if(datafolderexists("root:Packages:WM3DImageSlider:kineticWindow")==0)
		NewDataFolder/O root:Packages:WM3DImageSlider
		NewDataFolder/O root:Packages:WM3DImageSlider:kineticWindow
		variable/g root:Packages:WM3DImageSlider:kineticWindow:gLayer=0
	endif	
	Slider WM3DAxis,pos={10,84},size={314,6},proc=WM3DImageSliderProc
	Slider WM3DAxis,limits={0,49,1},variable= root:Packages:WM3DImageSlider:kineticWindow:gLayer,side= 0,vert= 0,ticks= 0
	
	Button SaveThisStack,pos={460,2},size={107,21},proc=saveStackProc_2,title="Save this movie as:"
	
	Button BS_2P_kineticSeries,pos={120.00,2.00},size={76.00,20.00},proc=BS_2P_KineticSeriesButton,title="Kinetic Series"
	Button BS_2P_kineticSeries,fSize=11,fColor=(0,13056,0)

	Button BS_2P_AbortImaging,pos={119,23},size={76,20},proc=BS_2P_abortButtonProc_2,title="Abort"
	Button BS_2P_AbortImaging,fSize=11,fColor=(39168,0,0)
	Button BS_2P_videoSeries,pos={119,44},size={76,20},proc=BS_2P_VideoButton,title="Video"
	Button BS_2P_videoSeries,fSize=11,fColor=(0,13056,0)

	CheckBox AxesConstrain,pos={8,3},size={88,14},proc=BS_2P_constrainAxes,title="Constrain Axes"
	CheckBox AxesConstrain,value= 1
	
	SetVariable setFrames,pos={197,3},size={66,16},proc=BS_2P_SetFramesProc,title="Frames"
	SetVariable setFrames,frame=0,valueBackColor=(65535,65535,65535)
	SetVariable setFrames,limits={-inf,inf,0},value= root:Packages:BS2P:CurrentScanVariables:frames
	
	SetVariable setAvg,pos={197,20},size={41,16},title="Avg",frame=0
	SetVariable setAvg,valueBackColor=(65535,65535,65535)
	SetVariable setAvg,limits={-inf,inf,0},value= root:Packages:BS2P:CurrentScanVariables:frameAvg
		
	CheckBox BS_2P_ExternalTrigger,pos={269,4},size={92,14},title="External Trigger"
	CheckBox BS_2P_ExternalTrigger,variable= root:Packages:BS2P:CurrentScanVariables:externalTrigger
	
	ValDisplay FrameTime,pos={197,37},size={117,14},title="1 Frame:",fSize=10
	ValDisplay FrameTime,format="%.2W1Ps",frame=0,fColor=(65280,0,0)
	ValDisplay FrameTime,valueColor=(65280,0,0),valueBackColor=(60928,60928,60928)
	ValDisplay FrameTime,limits={0,0,0},barmisc={0,1000}
	ValDisplay FrameTime,value= #"root:Packages:BS2P:CurrentScanVariables:scanFrameTime *root:Packages:BS2P:CurrentScanVariables:frameAvg"
	
	ValDisplay FrameTime1,pos={198,51},size={90,14},title="freq:",fSize=10
	ValDisplay FrameTime1,format="%.1f Hz",frame=0,fColor=(65280,0,0)
	ValDisplay FrameTime1,valueColor=(65280,0,0)
	ValDisplay FrameTime1,valueBackColor=(60928,60928,60928)
	ValDisplay FrameTime1,limits={0,0,0},barmisc={0,1000}
	ValDisplay FrameTime1,value= #"root:Packages:BS2P:CurrentScanVariables:displayFrameHz"


	ValDisplay TotalTime,pos={197,64},size={106,14},title="Total time:",fSize=10
	ValDisplay TotalTime,format="%.1W1Ps",frame=0,fColor=(65280,0,0)
	ValDisplay TotalTime,valueColor=(65280,0,0),valueBackColor=(60928,60928,60928)
	ValDisplay TotalTime,limits={0,0,0},barmisc={0,1000}
	ValDisplay TotalTime,value= #"root:Packages:BS2P:CurrentScanVariables:displayTotalTime *root:Packages:BS2P:CurrentScanVariables:frameAvg"


	SetVariable SaveAs,pos={538,22},size={219,16},title=" ",frame=0
	SetVariable SaveAs,value= root:Packages:BS2P:CurrentScanVariables:fileName2bWritten

	
	PopupMenu BS_2P_SaveWhere,pos={571,2},size={46,21},bodyWidth=46,proc=BS_2P_pathSelectionPopMenuProc,title="Path"
	PopupMenu BS_2P_SaveWhere,mode=0,value= #"root:Packages:BS2P:CurrentScanVariables:pathDetailsListing"
	
	SetVariable BS_2P_SavePrefix,pos={620,4},size={90,18},bodyWidth=57,proc=BS_2P_ChangeSavePrefix,title="Prefix"
	SetVariable BS_2P_SavePrefix,value= root:Packages:BS2P:CurrentScanVariables:SaveAsPrefix

	SetVariable Increment,pos={714,4},size={47,18},bodyWidth=24,proc=SetPrefixIncrementProc,title="Inc:"
	SetVariable Increment,limits={-inf,inf,0},value= root:Packages:BS2P:CurrentScanVariables:prefixIncrement

//	CheckBox BS_2P_SaveEverything,pos={702,41},size={57,14},proc=CheckProcSaveAll,title="Save All"
//	CheckBox BS_2P_SaveEverything,value= 0,side= 1
	
	CheckBox BS_2P_SaveEverything,pos={644,41},size={79,14},proc=saveALLCheckProc,title="Save images"
	CheckBox BS_2P_SaveEverything,variable= root:Packages:BS2P:CurrentScanVariables:saveEmAll
	
	CheckBox BS_2P_SaveEphys,pos={644,57},size={75,14},title="Save ePhys"
	CheckBox BS_2P_SaveEphys,variable= root:Packages:BS2P:CurrentScanVariables:saveEphys


	
	SetVariable setZoom,pos={545,43},size={82,16},proc=BS_2P_SetFramesProc,title="Zoom (µm)"
	SetVariable setZoom,frame=0,valueBackColor=(65535,65535,65535)
	SetVariable setZoom,limits={-inf,inf,0},value= root:Packages:BS2P:CurrentScanVariables:zoomFactor

	
	Button zoomout,pos={543,58},size={34,20},proc=ZoomOutProc_2,title="out"
	Button zoomout,fSize=8


	Button zoomIn,pos={589,58},size={34,20},proc=ZoomInProc_2,title="in",fSize=8

	


	//Stage Control ----------------------------------------------------------------
	if((stringMatch((boardConfig[16][2]), "YES")) || (stringMatch((boardConfig[24][2]), "YES")))
			
		Button moveU,pos={500,31},size={14,16},proc=MoveUProc,title="^",fSize=8
		Button moveR,pos={519,48},size={14,16},proc=MoveRProc,title=">",fSize=8
		Button moveD,pos={500,63},size={14,16},proc=MoveDProc,title="v",fSize=8
		Button moveL,pos={480,48},size={14,16},proc=MoveLProc,title="<",fSize=8
		
		SetVariable setMoveStep,pos={496,46},size={22,16},title=" ",frame=0
		SetVariable setMoveStep,valueBackColor=(65535,65535,65535)
		SetVariable setMoveStep,limits={-inf,inf,0},value= root:Packages:BS2P:CurrentScanVariables:moveStep

		ValDisplay stageX,pos={107,100},size={70,14},title="X:"
		ValDisplay stageX,labelBack=(65280,65280,32768),format="%.1f µm",frame=0
		ValDisplay stageX,valueBackColor=(65280,65280,32768)
		ValDisplay stageX,limits={0,0,0},barmisc={0,1000}
		ValDisplay stageX,value= #"root:Packages:P_I:PI_xPos"
		ValDisplay stageX,barBackColor= (65280,65280,32768)
		
		ValDisplay stageY,pos={172,100},size={68,14},bodyWidth=54,title="Y:"
		ValDisplay stageY,labelBack=(65280,65280,32768),format="%.1f µm",frame=0
		ValDisplay stageY,valueBackColor=(65280,65280,32768)
		ValDisplay stageY,limits={0,0,0},barmisc={0,1000}
		ValDisplay stageY,value= #"root:Packages:P_I:PI_yPos"
		ValDisplay stageY,barBackColor= (65280,65280,32768)

		PI_tellAllPositions()

	
	endif
	//----------------------------------------------------------------------------------------
	
	//Z Control ----------------------------------------------------------------
	if((stringMatch((boardConfig[15][2]), "YES")) || (stringMatch((boardConfig[24][2]), "YES")) || (stringMatch((boardConfig[25][2]), "YES")))
		Button FocusUP,pos={313,22},size={34,20},proc=BS_2P_focusUpButtonProc,title="up"
		Button FocusUP,fSize=8
//		Button FocusDown,pos={381,2},size={34,20},proc=BS_2P_focusUpButtonProc,title="up"
//		Button FocusDown,fSize=8
		Button FocusDown,pos={314,57},size={33,18},proc=BS_2P_focusDownButtonProc,title="down"
		Button FocusDown,fSize=8
		SetVariable focusStep,pos={310,41},size={50,16},title="µm",frame=0
		SetVariable focusStep,valueBackColor=(60928,60928,60928)
		SetVariable focusStep,limits={0,2000,0},value= root:Packages:BS2P:CurrentScanVariables:focusStep
		GroupBox stackBox,pos={370,24},size={108.00,56.00}

		Button doStack,pos={373,27},size={34,20},proc=doStack,title="stack",fSize=8
		Button doStack,fColor=(61440,61440,61440)

		SetVariable stackDepth,pos={381,46},size={86,16},title="depth (µm)",frame=0
		SetVariable stackDepth,limits={0,2000,0},value= root:Packages:BS2P:CurrentScanVariables:stackDepth

		SetVariable stackResolution,pos={375,61},size={95,16},title="resolution (µm)"
		SetVariable stackResolution,frame=0
		SetVariable stackResolution,limits={0,20,0},value= root:Packages:BS2P:CurrentScanVariables:stackResolution
		
		ValDisplay stageZ,pos={239,100},size={65,14},title="Z:"
		ValDisplay stageZ,labelBack=(65280,65280,32768),format="%.1f µm",frame=0
		ValDisplay stageZ,valueBackColor=(65280,65280,32768)
		ValDisplay stageZ,limits={0,0,0},barmisc={0,1000}
		ValDisplay stageZ,value= #"root:Packages:P_I:PI_zPos"
		ValDisplay stageZ,barBackColor= (65280,65280,32768)



	endif
	//----------------------------------------------------------------------------------------
	
	

	ValDisplay pixSize,pos={5,18},size={90,14},title="Pixel Size"
	ValDisplay pixSize,labelBack=(60928,60928,60928),format="%.W1Pm",frame=0
	ValDisplay pixSize,valueBackColor=(60928,60928,60928)
	ValDisplay pixSize,limits={0,0,0},barmisc={0,1000}
	ValDisplay pixSize,value= #"root:packages:bs2p:currentScanVariables:displayPixelSize"
	
	CheckBox BS_2P_TrigLoop,pos={370,4},size={81,15},title="LoopTrigger"
	CheckBox BS_2P_TrigLoop,variable= root:Packages:BS2P:CurrentScanVariables:trigLoop

//	GroupBox stackBox1,pos={265,1},size={179,20}

	
	rotatekineticWin()
	

end


function kineticWindowHook(s)    //This is a hook for the mousewheel movement in MatrixExplorer
	STRUCT WMWinHookStruct &s
	
	NVAR moveStep =  root:Packages:BS2P:CurrentScanVariables:moveStep
	NVAR focusStep = root:Packages:BS2P:CurrentScanVariables:focusStep
		NVAR luigsFocusDevice = root:Packages:BS2P:CalibrationVariables:luigsFocusDevice
	SVAR luigsFocusAxis = root:Packages:BS2P:CalibrationVariables:luigsFocusAxis
	wave kineticSeries =  root:Packages:BS2P:CurrentScanVariables:kineticSeries
	switch(s.eventCode)
		case 11:
			switch(s.keycode)
				case 114:	//r
					calcroi("SIGNAL")
				break
				
				case 8: //backspace
					ClearROIsFromHere()
				break
				
				case 98:		// b
					calcroi("BACKGROUND")
				break
				
				case 102:	// f
					calcROI("Freehand Background")
				break
				
				 case 29:	// right arrow
				 	PI_moveMicrons("x", -moveStep)
				 break
				 
				 case 28:	// left arrow
					PI_moveMicrons("x", moveStep)
				 break
				 	
				 case 30:	// up arrow
				 	PI_moveMicrons("y", moveStep)
				 break
				 
				 case 31:	// down arrow
				 	PI_moveMicrons("y", -moveStep)
				 break
				 
				 case 115:	// s
				 	arbitraryScan()
				 break
				 
				  case 109:	// m
				 	multipleScans()
				 break
				 
				 case 11: // page Up
				 	PI_moveMicrons("z", -focusStep)
				 break
				 
				 case 12: // page Down
				 	PI_moveMicrons("z", focusStep)
				 break
				 				
			endswitch
		break
	endswitch
	dowindow kineticWindow
end


Function BS_2P_constrainAxes(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			break
		case -1: // control being killed
			break
	endswitch
	if(checked==0)
		ModifyGraph/w=kineticWindow width=0,height=0
	elseif(checked==1)
		ModifyGraph/w=kineticWindow width=0,height={Plan,1,left,bottom}
	endif
	return 0
End

Function PixPerLinePopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
				String popStr = pa.popStr
				pixelsPerLine = str2num(popStr)
				BS_2P_UpdateVariables()
				BS_2P_CreateScan()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function bs_2P_reset2P()

	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig 
	string pmtDev = boardConfig[3][0]
	string galvoDev = boardConfig[0][0]

	fDAQmx_CTR_Finished(pmtDev, 0)
	fDAQmx_CTR_Finished(pmtDev, 1)
	fDAQmx_CTR_Finished(pmtDev, 2)
	fDAQmx_CTR_Finished(pmtDev, 3)
	fDAQmx_CTR_Finished(pmtDev, 0)
	fDAQmx_CTR_Finished(pmtDev, 1)
	fDAQmx_WaveformStop(galvoDev)
	fDAQmx_ScanStop(galvoDev)
	
//	if((stringMatch((boardConfig[24][2]), "YES")))
//		closePythonServer()
//	endif
end

Function BS_2P_KineticSeriesButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
		SVAR SaveAsPrefix = root:Packages:BS2P:CurrentScanVariables:SaveAsPrefix
	wave dum  = root:Packages:BS2P:CurrentScanVariables:dum
	switch( ba.eventCode )
		case 2: // mouse up
			BS_2P_updateVariables()
			BS_2P_CreateScan()
			BS_2P_Scan("kinetic")
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function BS_2P_focusUpButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	NVAR focusStep = root:packages:BS2P:CurrentScanVariables:focusStep
	NVAR luigsFocusDevice = root:Packages:BS2P:CalibrationVariables:luigsFocusDevice
	SVAR luigsFocusAxis = root:Packages:BS2P:CalibrationVariables:luigsFocusAxis
	wave/t boardCOnfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			// click code here
			if(stringMatch((boardConfig[15][2]), "YES")) //Luigs
				LN_moveMicrons(luigsFocusDevice, luigsFocusAxis, focusStep)
			elseif(stringMatch((boardConfig[24][2]), "YES"))	//Python
				pythonMoveRelative(-1* focusStep, "z")
			elseif(stringMatch((boardConfig[25][2]), "YES"))	//PI_Focus
				PI_moveMicrons("z", -focusStep)
			endif
			//	scan ONE frame using current settings
			//	draw image from dum
			//	copy image over kineticSeries
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function BS_2P_focusDownButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	NVAR focusStep = root:packages:BS2P:CurrentScanVariables:focusStep
	NVAR luigsFocusDevice = root:Packages:BS2P:CalibrationVariables:luigsFocusDevice
	SVAR luigsFocusAxis = root:Packages:BS2P:CalibrationVariables:luigsFocusAxis
	wave/t boardCOnfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			//	Decrease voltage to the z-stepper output (decrease voltage?)
			//	scan one frame using current settings
			//	draw image from dum
			//	copy image over kineticSeries
			if(stringMatch((boardConfig[15][2]), "YES")) //Luigs
				LN_moveMicrons(luigsFocusDevice, luigsFocusAxis, -focusStep)
			elseif(stringMatch((boardConfig[24][2]), "YES"))	//Python
				pythonMoveRelative(focusStep, "z")
			elseif(stringMatch((boardConfig[25][2]), "YES"))	//PI_Focus
				PI_moveMicrons("z", 1* focusStep)
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End




Function SetPrefixIncrementProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	SVAR currentPathDetails = root:Packages:BS2P:CurrentScanVariables:currentPathDetails
	SVAR SaveAsPrefix = root:Packages:BS2P:CurrentScanVariables:SaveAsPrefix
	SVAR fileName2bWritten = root:Packages:BS2P:CurrentScanVariables:fileName2bWritten
	
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			//set NEW FILENAME
			
			fileName2bWritten = currentPathDetails + SaveAsPrefix + num2str(dval)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function BS_2P_SetFramesProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			BS_2P_UpdateVariables()
			BS_2P_CreateScan()
			break
		case -1: // control being killed
			break
	endswitch
	
	return 0
End


Function BS_2P_ChangeSavePrefix(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	SVAR currentPathDetails = root:Packages:BS2P:CurrentScanVariables:currentPathDetails
	SVAR fileName2bWritten = root:Packages:BS2P:CurrentScanVariables:fileName2bWritten
	NVAR prefixIncrement = root:Packages:BS2P:CurrentScanVariables:prefixIncrement
		
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			prefixIncrement = 0
			fileName2bWritten = currentPathDetails + sval + num2str(prefixIncrement)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function SetDwellProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			break
		case -1: // control being killed
			break
	endswitch
	BS_2P_UpdateVariables()
	BS_2P_CreateScan()
	return 0
End

Function BS_2P_pathSelectionPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	SVAR pathDetailsListing =  root:Packages:BS2P:CurrentScanVariables:pathDetailsListing
	SVAR pathsListing =  root:Packages:BS2P:CurrentScanVariables:pathsListing
	SVAR currentPath =  root:Packages:BS2P:CurrentScanVariables:currentPath
	SVAR currentPathDetails = root:Packages:BS2P:CurrentScanVariables:currentPathDetails
	SVAR fileName2bWritten = root:Packages:BS2P:CurrentScanVariables:fileName2bWritten
	SVAR SaveAsPrefix = root:Packages:BS2P:CurrentScanVariables:SaveAsPrefix
	NVAR prefixIncrement = root:Packages:BS2P:CurrentScanVariables:prefixIncrement
	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
	
			break
		case -1: // control being killed
			break
	endswitch
	if(popNum == 1)
		string newPathName = "BS_2P_SavePath_"+num2str(itemsinlist(pathDetailsListing))
		newpath/Q $newPathName
		pathsListing += ";"+newPathName
		pathInfo $newPathName
		pathDetailsListing += ";"+s_path
		currentPathDetails = s_path
		currentPath = newPathName
		fileName2bWritten = currentPathDetails + SaveAsPrefix + num2str(prefixIncrement)
	else
		currentPath = stringfromlist(popnum-1, pathsListing)
		pathInfo $currentPath
		currentPathDetails = s_path
		fileName2bWritten = currentPathDetails + SaveAsPrefix + num2str(prefixIncrement)
		currentPathDetails = s_path
	endif
	
	
	
	return 0
End

Function BS_2P_FullFieldProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	NVAR scanLimit = root:Packages:BS2P:CalibrationVariables:scanLimit
	NVAR scaledX = root:Packages:BS2P:CurrentScanVariables:scaledX
	NVAR scaledY = root:Packages:BS2P:CurrentScanVariables:scaledY
	NVAR X_offset = root:Packages:BS2P:CurrentScanVariables:X_offset
	NVAR Y_offset = root:Packages:BS2P:CurrentScanVariables:Y_offset
	NVAR scaleFactor = root:Packages:BS2P:CalibrationVariables:scaleFactor
	switch( ba.eventCode )
		case 1: // mouse up
			// click code here
			DoWindow/F kineticWindow
			if(V_flag == 0)
				BS_2P_makeKineticWindow()
			endif
			scaledX = scanLimit * scaleFactor * 2//; print "scaledX",scaledX
			scaledY = scanLimit * scaleFactor * 2//; print "scaled Y", scaledY
			X_offset = 0 - (scanLimit * scaleFactor) //; print "X_offset",X_offset
			Y_offset = 0  - (scanLimit * scaleFactor)//; print "Y_offset",Y_offset; print "---------------------------"
			BS_2P_updateVariables()
			BS_2P_CreateScan()
			BS_2P_Scan("snapshot")
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function saveStackProc_2(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			BS_2P_saveDum()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function SetfocusStepProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	NVAR focusStep = root:packages:BS2P:currentScanVariables:focusStep
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			focusStep = dval
			LN_setStepSize(1, "z", focusStep)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function BS_2P_measure()
	getmarquee/K left, bottom
	print "X = ", V_right - V_left, "µm"
	print "Y = ", V_top - V_bottom, "µm"
	print "diaganol = ", sqrt(( V_right - V_left)^2 + (V_top - V_bottom)^2), "µm"
	
end

Function SetobjectiveMagProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	NVAR ScaleFactor = root:Packages:BS2P:CalibrationVariables:scaleFactor
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			scaleFactor = (2220 * (180/dval) * (1/200))	//f scanlens * tg (2/0,785) = 50 * tg (2/0,785) = 2,22 mm / V
			BS_2P_UpdateVariables()
			BS_2P_CreateScan()		//pour 1 V, déplacement du faisceau de 2,22 * f objectif / f tubelens = 2220 (µm) * 180/60 * 1/200
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function fixDwellTime(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	NVAR fixedDwell =  root:Packages:BS2P:CurrentScanVariables:fixedDwell
	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			if(checked)
				PopupMenu galvoFreq disable=2
			else
				PopupMenu galvoFreq disable=0
			endif
			break
		case -1: // control being killed
			break
	endswitch
	BS_2P_UpdateVariables()
	BS_2P_CreateScan()
	return 0
End

Function BS_2P_abortButtonProc_2(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			sampleDiodeVoltage()
			bs_2P_reset2p()
			BS_2P_Pockels("close")
			BS_2P_PMTShutter("close")
			bs_2p_zeroscanners("offset")
			PI_abortSmoothly()
			///////////////////// Don't forget to add this ---->  close Pockels
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function ZoomOutProc_2(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	NVAR scaledX = root:Packages:BS2P:CurrentScanVariables:scaledX
	NVAR scaledY =  root:Packages:BS2P:CurrentScanVariables:scaledY	//Distance of Y-axis scan in m
	NVAR X_Offset =  root:Packages:BS2P:CurrentScanVariables:X_Offset	//Where to start the X-axis scan in µm from center
	NVAR Y_Offset =  root:Packages:BS2P:CurrentScanVariables:Y_Offset
	NVAR zoomfactor = root:Packages:BS2P:CurrentScanVariables:zoomFactor
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			X_Offset -= ((zoomFactor * 1e-6) / 2)
			Y_Offset -= ((zoomFactor * 1e-6) / 2)
			scaledX += (zoomFactor * 1e-6)
			scaledY += (zoomFactor * 1e-6)
			BS_2P_updateVariables()
			BS_2P_CreateScan()
			BS_2P_Scan("snapshot")
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ZoomInProc_2(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	NVAR scaledX = root:Packages:BS2P:CurrentScanVariables:scaledX
	NVAR scaledY =  root:Packages:BS2P:CurrentScanVariables:scaledY	//Distance of Y-axis scan in m
	NVAR X_Offset =  root:Packages:BS2P:CurrentScanVariables:X_Offset	//Where to start the X-axis scan in µm from center
	NVAR Y_Offset =  root:Packages:BS2P:CurrentScanVariables:Y_Offset
	NVAR zoomfactor = root:Packages:BS2P:CurrentScanVariables:zoomFactor
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			X_Offset += ((zoomFactor * 1e-6) / 2)
			Y_Offset += ((zoomFactor * 1e-6) / 2)
			scaledX -= (zoomFactor * 1e-6)
			scaledY -= (zoomFactor * 1e-6)
			BS_2P_updateVariables()
			BS_2P_CreateScan()
			BS_2P_Scan("snapshot")
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



Function MoveLProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	NVAR moveStep =  root:Packages:BS2P:CurrentScanVariables:moveStep
	wave/t boardCOnfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			if(stringMatch((boardConfig[16][2]), "YES")) //PI
				PI_moveMicrons("x", moveStep)
			elseif(stringMatch((boardConfig[24][2]), "YES"))
				pythonMoveRelative(moveStep, "x")
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function MoveRProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	NVAR moveStep =  root:Packages:BS2P:CurrentScanVariables:moveStep
	wave/t boardCOnfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			if(stringMatch((boardConfig[16][2]), "YES")) //PI
				PI_moveMicrons("x", -1* moveStep)
			elseif(stringMatch((boardConfig[24][2]), "YES"))
				pythonMoveRelative(-1* moveStep, "x")
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function MoveUProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	NVAR moveStep =  root:Packages:BS2P:CurrentScanVariables:moveStep
	wave/t boardCOnfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			if(stringMatch((boardConfig[16][2]), "YES")) //PI
				PI_moveMicrons("y", 1* moveStep)
			elseif(stringMatch((boardConfig[24][2]), "YES"))
				pythonMoveRelative(-1* moveStep, "y")
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function MoveDProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	NVAR moveStep =  root:Packages:BS2P:CurrentScanVariables:moveStep
	wave/t boardCOnfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			if(stringMatch((boardConfig[16][2]), "YES")) //PI
				PI_moveMicrons("y", -1* moveStep)
			elseif(stringMatch((boardConfig[24][2]), "YES"))
				pythonMoveRelative(moveStep, "y")
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function bs_2P_zeroscanners(position)
	string position
	variable offset
	variable offsetx, offsety
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig 
	string galvoDev = boardConfig[0][0]
	variable xGalvoChannel = str2num(boardConfig[0][2])
	variable yGalvoChannel = str2num(boardConfig[1][2])
	variable parkVoltage =  str2num(boardConfig[18][2])
	if (stringmatch(position, "center"))
		offsetx = 0; offsety = 0
	elseif (stringmatch(position,"offset"))
		offsety = parkVoltage; offsetx = parkVoltage
	endif
		fDAQmx_WriteChan(galvoDev, xGalvoChannel, offsetx, -10, 10 )
		fDAQmx_WriteChan(galvoDev, yGalvoChannel, offsety, -10, 10 )
end

function BS_2P_PMTShutter(openOrClose)
	string openOrClose
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	string devNum = boardConfig[4][0]
	string port = boardConfig[4][1]
	string line = boardConfig[4][2]
	NVAR/Z shutterIOtaskNumber =  root:Packages:BS2P:CurrentScanVariables:shutterIOtaskNumber
	if(!NVAR_exists(shutterIOtaskNumber))
		variable/g root:Packages:BS2P:CurrentScanVariables:shutterIOtaskNumber = bs_2P_initDIO(devNum, port, line)
		NVAR/Z shutterIOtaskNumber =  root:Packages:BS2P:CurrentScanVariables:shutterIOtaskNumber
	endif
			
	if(stringmatch(openOrCLose, "open"))
		fdaqmx_dio_write(devNum, shutterIOtaskNumber, 5)
//		fDAQmx_WriteChan("DEV2", 1, 5, -5, 5 )	//open external shutter before PMT
	elseif(stringmatch(openOrCLose, "close"))
		fdaqmx_dio_write(devNum, shutterIOtaskNumber, 0)
//		fDAQmx_WriteChan("DEV2", 1, 0, -5, 5 )	//close external shutter before PMT
	endif
	
end

function BS_2P_StartSignal()
	
	NVAR dwellTIme = root:Packages:BS2P:CurrentScanVariables:dwellTime
	string openOrClose
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	string devNum = boardConfig[26][0]
	string port = boardConfig[26][1]
	string line = boardConfig[26][2]
	string pmtDev = boardConfig[3][0]
	string pixelCLock = "/"+pmtDev+"/Ctr2InternalOutput"
	
	NVAR startIOtaskNumber = root:Packages:BS2P:CurrentScanVariables:startIOtaskNumber
	if(NVAR_exists(startIOtaskNumber))
		fDAQmx_DIO_Finished(devNum, startIOtaskNumber)
	endif
	make/n=(50e-3/dwellTime)/o root:Packages:BS2P:CurrentScanVariables:startSig = 0;
	wave startSig = root:Packages:BS2P:CurrentScanVariables:startSig
	startSig = p < ((50e-3/dwellTime)/2) ? 5 : 0
	setScale/p x, 0, (dwellTime*100), "s" startSig
	string pfiString = "/"+devNum+"/port"+port+ "/line" + line
	daqmx_dio_config/dir=1/dev=devNum/wave={startSig}/CLK={pixelCLock,1} pfiString ///CLK={pixelCLock,1}
	variable/g  root:Packages:BS2P:CurrentScanVariables:startIOtaskNumber = V_DAQmx_DIO_TaskNumber
end



function bs_2P_initDIO(devNum, port, line)
	string devNum, port, line
	
	string pfiString = "/"+devNum+"/port"+port+ "/line" + line
	daqmx_dio_config/dir=1/dev=devNum pfiString
	variable DIOTaskNumber = V_DAQmx_DIO_TaskNumber
//	fdaqmx_dio_write(devNum, DIOTaskNumber, 0)
	return DIOTaskNumber
end

function readLaserPower()
	bs_2P_zeroscanners("offset")
	BS_2P_Pockels("open")
	sampleDiodeVoltage()
	BS_2P_Pockels("close")
//	NVAR laserPower = root:Packages:BS2P:CurrentScanVariables:laserPower
	
//	print "."
//	print "."
//	printf "%.2g mW (after objective) currently sent to galvos\r", laserPower
//	print "."
end

function sampleDiodeVoltage()
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	string diodeDevNum = boardConfig[6][0]
	variable diodeChannel = str2num(boardConfig[6][2])
	variable mWPerVolt = str2num(boardConfig[10][2])
	variable mWPerVolt_offset = str2num(boardConfig[10][3])
	string diodeWaves = "sampleDiode, "+ boardConfig[6][2]
	make/d/n=200/o sampleDiode
	setscale/p x, 0, 0.0001, sampleDiode
	
	NVAR laserPower = root:Packages:BS2P:CurrentScanVariables:laserPower
	variable voltage 
	fDAQmx_ScanStop(diodeDevNum)
	DAQmx_Scan/DEV=diodeDevNum/bkg waves=diodeWaves
	voltage = mean(sampleDiode)
	laserPower = (voltage * mWPerVolt) + mWPerVolt_offset
	

//	showLaserPower()
//	return laserPower / mWPerVolt	//comes out in volts

//	showLaserPower()
	return voltage	//comes out in volts

end

function measureLaserPower()
	BS_2P_Pockels("open")
	sampleDiodeVoltage()
	NVAR laserPower = root:Packages:BS2P:CurrentScanVariables:laserPower
	print "Laser power at focal plane =", laserPower, "mW"
	
end


function calibratePockels()
	variable targetPower	// desired max power in mW
	prompt targetPower, "Desired maximum power (mW)"
	doPrompt "Desired Maximum power (mW)?", targetPower
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	string diodeDevNum = boardConfig[6][0]
	variable diodeChannel = str2num(boardConfig[6][2])
	string pockelDevNum = boardConfig[2][0]
	variable pockelChannel = str2num(boardConfig[2][2])
	variable mWPerVolt = str2num(boardConfig[10][2])
	variable mWPerVolt_offset = str2num(boardConfig[10][3])

	bs_2P_zeroscanners("offset")
		
	NVAR pockelValue = root:Packages:BS2P:CurrentScanVariables:pockelValue
	NVAR minPockels = root:Packages:BS2P:CalibrationVariables:minPockels
	NVAR maxPockels = root:Packages:BS2P:CalibrationVariables:maxPockels
//	bs_2P_zeroScanners("center")
	minPockels = 0//.2
	maxPockels = 1
	make/n=20/o w_diodeReadings
	setscale x, minPockels , maxPockels, w_diodeReadings
	variable i
	for(i=0; i < (numpnts(w_diodeReadings)) ; i += 1)
		variable pockelsVolts = (((maxPockels - minPockels) / numpnts(w_diodeReadings))*i) + minPockels
//		print pockelsVolts
		fDAQmx_WriteChan(pockelDevNum, pockelChannel, pockelsVolts, minPockels,maxPockels )
		sleep/s 1
		w_diodeReadings[i] = sampleDiodeVoltage()
	endfor
	setScale/p x, minPockels, ((maxPockels - minPockels) / numpnts(w_diodeReadings)), w_diodeReadings
	BS_2P_Pockels("close")
//	CurveFit/NTHR=0/q line  w_pockelsCalibration /D
//	wave fit_w_pockelsCalibration
	dowindow/k/f pockelsCalib
//	if(!V_flag)
		display/k=1/n=pockelsCalib w_diodeReadings
//		appendToGraph fit_w_pockelsCalibration
		ModifyGraph rgb(w_diodeReadings)=(0,0,0)//,lstyle(fit_w_pockelsCalibration)=2
		Label left "Diode (V)"
		Label bottom "Pockels (V)"
//	endif

//	w_diodeReadings *= mWPerVolt
//	w_diodeReadings += mWPerVolt_offset
//	findLevel/edge=1/q  w_diodeReadings, (wavemin(w_diodeReadings)+0.01)
//	minPockels = v_levelx
//	boardConfig[11][2] = num2str(minPockels)
//	findLevel/edge=1/q  w_diodeReadings, targetPower
//	maxPockels = v_levelx
//	boardConfig[12][2] = num2str(maxPockels)
//	CurveFit/X=1/NTHR=0/q poly 3,  w_diodeReadings(0.2, 0.3) /D
//	wave w_coef
//	duplicate/o w_coef root:Packages:BS2P:CalibrationVariables:pockelsPolynomial
	
//	SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65280,0,0),dash= 2,fillpat= 0
//	DrawRect minPockels, (wavemin(w_diodeReadings)),maxPockels,targetPower
//	bs_2P_getConfig()
//	print "Min Power = ", wavemin(w_diodeReadings), "mW"
//	print "Max power set to", targetPower, "mW"
//	wave w_coef
//	print "diodeVoltsPerPockels =", w_coef[1]
//	return w_coef[1]
end

function laserPowerCalibrationSample(pockelOpen)
	variable pockelOpen
	wave powerReadings
	wave pockelsPercent
	NVAR pockelValue = root:Packages:BS2P:CurrentScanVariables:pockelValue
	pockelValue = pockelOpen
	redimension/n=(numpnts(powerReadings)+1) powerReadings
	BS_2P_Pockels("open")
	sleep/s 1
	powerReadings[numpnts(powerReadings)-1] = sampleDiodeVoltage()
	
	redimension/n=(numpnts(pockelsPercent)+1) pockelsPercent
	pockelsPercent[numpnts(pockelsPercent)-1] = pockelValue
end

function calibratePower()
	make/o/n=20 w_diodeReadings, mW
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig

	string pockelDevNum = boardConfig[2][0]
	variable pockelChannel = str2num(boardConfig[2][2])
	bs_2P_zeroscanners("center")
	
	variable minPockels = 0.15
	variable maxPockels = 1.2
	variable meterReading
	setScale/p x, minPockels, ((maxPockels - minPockels) / numpnts(w_diodeReadings)), w_diodeReadings
	setScale/p x, minPockels, ((maxPockels - minPockels) / numpnts(w_diodeReadings)), mW

	variable i
	for(i=0; i < (numpnts(w_diodeReadings)) ; i += 1)
		variable pockelsVolts = (((maxPockels - minPockels) / numpnts(w_diodeReadings))*i) + minPockels
//		print pockelsVolts
		fDAQmx_WriteChan(pockelDevNum, pockelChannel, pockelsVolts, minPockels,maxPockels )
		sleep/s 1
		w_diodeReadings[i] = sampleDiodeVoltage()
		
		prompt meterReading, "Power Meter (mW)"
		doPrompt "Read the meter", meterReading 

		mW[i] = meterReading
	endfor

	BS_2P_Pockels("close")
	bs_2P_zeroscanners("offset")
	
	display/k=1 mW vs w_diodeReadings
	Label left "Power Meter (mW)"
	Label bottom "Diode (V)"
	CurveFit/X=1/NTHR=0 line  mW /X=w_diodeReadings /D
	ModifyGraph mode(mW)=3,marker(mW)=19,rgb(mW)=(0,0,0)
	
	wave w_coef
	boardConfig[10][3] =  num2str(w_coef[0])
	boardConfig[10][2] = num2str(w_coef[1])
	NVAR mWPerVolt = root:Packages:BS2P:CurrentScanVariables:mWPerVolt
	NVAR mWPerVolt_offset = root:Packages:BS2P:CurrentScanVariables:mWPerVolt_offset
	mWPerVolt_offset = (w_coef[0])///w_coef[1]
	mWPerVolt = w_coef[1]
	bs_2P_editConfig()
	
//	display/k=1 mW
//	CurveFit/X=1/NTHR=0/q poly 3,  mW(0.2,0.5) /D
//	wave w_coef
//	duplicate/o w_coef root:Packages:BS2P:CalibrationVariables:pockelsPolynomial
//	boardConfig[17][2] = num2str(w_coef[0])
//	boardConfig[17][3] = num2str(w_coef[1])
//	boardConfig[17][4] = num2str(w_coef[2])
	
	display/k=1 w_diodeReadings
	Label left "Diode (V)"
	Label bottom "Pockels (V)"
	
	display/k=1 mW
	Label left "PowerMeter (mW)"
	Label bottom "Pockels (V)"
	ModifyGraph grid=1,minor(left)=1,sep(bottom)=2
end


function moveGalvos(offsetx, offsety)
	variable offsetx, offsety
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig 
	string galvoDev = boardConfig[0][0]
	variable xGalvoChannel = str2num(boardConfig[0][2])
	variable yGalvoChannel = str2num(boardConfig[1][2])
	fDAQmx_WriteChan(galvoDev, xGalvoChannel, offsetx, -10, 10 )
	fDAQmx_WriteChan(galvoDev, yGalvoChannel, offsety, -10, 10 )
end

function showLaserPower()
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	string diodeDevNum = boardConfig[6][0]
	variable diodeChannel = str2num(boardConfig[6][2])
	variable mWPerVolt = str2num(boardConfig[10][2])
	variable mWPerVolt_offset = str2num(boardConfig[10][3])
	make/n=1000/o sampleDiode
//	wave sampleDiode = root:Packages:BS2P:CalibrationVariables:sampleDiode
	setscale/p x, 0, 0.0001, sampleDiode	
	
	string diodeHook = "calcLaserHook(mWPerVolt,mWPerVolt_offset,sampleDiode)"
	string diodeWaves = "sampleDiode, "+ boardConfig[6][2]

	DAQmx_Scan/bkg/DEV=diodeDevNum/eosh=diodeHook waves=diodeWaves
	
end

function calcLaserHook(mWPerVolt, mWPerVolt_offset,sampleDiode)
	variable mWPerVolt, mWPerVolt_offset
	wave sampleDiode// = root:Packages:BS2P:CalibrationVariables:sampleDiode
	
	NVAR laserPower = root:Packages:BS2P:CurrentScanVariables:laserPower
	laserPower = (mean(sampleDiode) * mWPerVolt) + mWPerVolt_offset
end

Function BS_2P_saveAll_Proc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	
	SVAR pathDetailsListing =  root:Packages:BS2P:CurrentScanVariables:pathDetailsListing
	SVAR pathsListing =  root:Packages:BS2P:CurrentScanVariables:pathsListing
	SVAR currentPath =  root:Packages:BS2P:CurrentScanVariables:currentPath
	SVAR currentPathDetails = root:Packages:BS2P:CurrentScanVariables:currentPathDetails
	SVAR fileName2bWritten = root:Packages:BS2P:CurrentScanVariables:fileName2bWritten
	SVAR SaveAsPrefix = root:Packages:BS2P:CurrentScanVariables:SaveAsPrefix
	NVAR prefixIncrement = root:Packages:BS2P:CurrentScanVariables:prefixIncrement
	
	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			if(checked)
				string newPathName = "BS_2P_SavePath_"+num2str(itemsinlist(pathDetailsListing))
				newpath/Q $newPathName
				pathsListing += ";"+newPathName
				pathInfo $newPathName
				pathDetailsListing += ";"+s_path
				currentPathDetails = s_path
				currentPath = newPathName
				fileName2bWritten = currentPathDetails + SaveAsPrefix + num2str(prefixIncrement)
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function BS2P_setFreqPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	NVAR lineTime =  root:Packages:BS2P:CurrentScanVariables:lineTime
	NVAR pixelsPerLine = root:Packages:BS2P:CurrentScanVariables:pixelsPerLine
	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr

			
			variable digFreq = (1/((str2num(popstr))*1000*2))/(pixelsPerLine)
//
//			tune line time so acquisition is multiple of 5e-8
			digFreq = 5e-8 * (round(digFreq/5e-8))

			lineTime = (pixelsPerLine)*digFreq 	//seconds
			BS_2P_UpdateVariables()
			BS_2P_CreateScan()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function doStack(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	NVAR stackDepth =  root:Packages:BS2P:CurrentScanVariables:stackDepth
	NVAR stackResolution =  root:Packages:BS2P:CurrentScanVariables:stackResolution
	NVAR frames =  root:Packages:BS2P:CurrentScanVariables:frames
	
	NVAR  prefixIncrement = root:Packages:BS2P:CurrentScanVariables:prefixIncrement
	NVAR saveEmAll = root:Packages:BS2P:CurrentScanVariables:saveEmAll
	SVAR currentPath = root:Packages:BS2P:CurrentScanVariables:currentPath
	SVAR SaveAsPrefix = root:Packages:BS2P:CurrentScanVariables:SaveAsPrefix
	SVAR fileName2bWritten = root:Packages:BS2P:CurrentScanVariables:fileName2bWritten
	SVAR currentPathDetails = root:Packages:BS2P:CurrentScanVariables:currentPathDetails
	string filename2Write = saveAsPrefix+num2str(prefixIncrement)+".ibw"
	
	frames = ceil(stackDepth / stackResolution)
	switch( ba.eventCode )
		case 2: // mouse up
			BS_2P_updateVariables()
			BS_2P_CreateScan()
			BS_2P_Scan("stack")
			if(saveemall)
				BS_2P_saveDum()
				pathInfo $currentPath
				currentPathDetails = s_path
				prefixIncrement += 1
				fileName2bWritten = currentPathDetails + SaveAsPrefix + num2str(prefixIncrement)
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function BS_2P_VideoButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			BS_2P_updateVariables()
			BS_2P_CreateScan()
			BS_2P_Scan("video")

		case -1: // control being killed
			break
	endswitch

	return 0
End

Function saveALLCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	SVAR pathDetailsListing =  root:Packages:BS2P:CurrentScanVariables:pathDetailsListing
	SVAR pathsListing =  root:Packages:BS2P:CurrentScanVariables:pathsListing
	SVAR currentPath =  root:Packages:BS2P:CurrentScanVariables:currentPath
	SVAR currentPathDetails = root:Packages:BS2P:CurrentScanVariables:currentPathDetails
	SVAR fileName2bWritten = root:Packages:BS2P:CurrentScanVariables:fileName2bWritten
	SVAR SaveAsPrefix = root:Packages:BS2P:CurrentScanVariables:SaveAsPrefix
	NVAR prefixIncrement = root:Packages:BS2P:CurrentScanVariables:prefixIncrement
	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			if(checked == 1)
				if(strlen(currentPathDetails) == 0)
					string newPathName = "BS_2P_SavePath_"+num2str(itemsinlist(pathDetailsListing))
					newpath/Q $newPathName
					pathsListing += ";"+newPathName
					pathInfo $newPathName
					pathDetailsListing += ";"+s_path
					currentPathDetails = s_path
					currentPath = newPathName
					fileName2bWritten = currentPathDetails + SaveAsPrefix + num2str(prefixIncrement)
				endif
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function BS_2P_LickSolenoid(start, width, trigger)
	variable start, width // in ms
	string trigger
	if(datafolderexists("root:Packages") == 0)
		newdatafolder/o root:Packages
		newdatafolder/o root:Packages:Licking
	endif
	if(datafolderexists("root:Packages:licking") == 0)
		newdatafolder/o root:Packages:Licking
	endif
	NVAR dwellTIme = root:Packages:BS2P:CurrentScanVariables:dwellTime
	start /= 1000; start /= dwellTime
	width /= 1000; width /= dwellTime
	variable ending = 0.01 / dwellTime
	make/n=(50e-3/dwellTime)/o root:Packages:BS2P:CurrentScanVariables:startSig = 0;
	make/o/n=(start+width+ending) lickSchedule = 0
	lickSchedule[start,start+width] =1
	setscale/P x, 0, dwellTime, "s", lickSchedule
	
	wave/t boardConfig = root:Packages:BS2P:CalibrationVariables:boardConfig
	string pmtDev = boardConfig[3][0]
	string devNum = boardConfig[27][0]
	string port = boardConfig[27][1]
	string line = boardConfig[27][2]
	string pfiString = "/"+devNum+"/port"+port+ "/line" + line
	NVAR/Z lickIOtaskNumber =  root:Packages:Licking:lickIOtaskNumber:shutterIOtaskNumber
	if(NVAR_exists(lickIOtaskNumber))
		fDAQmx_DIO_Finished(devNum, lickIOtaskNumber)
	endif
	
	string pixelCLock = "/"+pmtDev+"/Ctr2InternalOutput"
	
	strSwitch(trigger)
		case "none":
			daqmx_dio_config/dir=1/dev=devNum/lgrp=1/wave={lickSchedule} pfiString
			break
		case "scanning":
			
			daqmx_dio_config/dir=1/dev=devNum/lgrp=1/wave={lickSchedule}/CLK={pixelCLock,1} pfiString
			break
	endSwitch
	variable/g root:Packages:Licking:lickIOtaskNumber = V_DAQmx_DIO_TaskNumber
end

Function shutdownHook(s)
	STRUCT WMWinHookStruct &s
	
	Variable hookResult = 0

	switch(s.eventCode)
		case 2:				// Kill WIndow
			StopUpdatingMaiTaiVariables()
			pmtControl("off")
			StopUpdatingPMTStatus()
			
			break

	endswitch

	return hookResult
end

	

	
	wave startSig = root:Packages:BS2P:CurrentScanVariables:startSig
	startSig = p < ((50e-3/dwellTime)/2) ? 5 : 0
	setScale/p x, 0, (dwellTime*100), "s" startSig