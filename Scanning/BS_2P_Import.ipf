#pragma rtGlobals=3		// Use modern global access method and strict wave access.


function BS_2P_Import1()
	GBLoadWave/N=import/O
	wave import0
	duplicate/o import0 root:Packages:BS2P:CurrentScanVariables:dum
	wave dum = root:Packages:BS2P:CurrentScanVariables:dum
	drawImportedDum(dum)
	DoWindow/F kineticWindow
	if(V_flag==0)
		BS_2P_makeKineticWindow()
	endif
	duplicate/o  root:Packages:BS2P:CurrentScanVariables:drawnImage root:Packages:BS2P:CurrentScanVariables:kineticSeries
	killwaves root:Packages:BS2P:CurrentScanVariables:drawnImage
end

function drawImportedDum(dum)
	wave dum
	
	////////////////// Get variables out of dum  --can use these to recreate the scan if need be  ////////////////////////////
	string scanParameters = note(dum)
	variable scaledX = numberbykey("scaledX", scanParameters)
	variable scaledY = numberbykey("scaledY", scanParameters)
	variable frames = numberbykey("frames", scanParameters)
	variable KCT = numberbykey("KCT", scanParameters)
	variable acquisitionFrequency = numberbykey("AcquisitionFrequency", scanParameters)
	variable dwellTime = numberbykey("dwellTime", scanParameters)
	variable lineSpacing = numberbykey("lineSpacing", scanParameters)
	variable scaleFactor = numberbykey("scaleFactor", scanParameters)	//  µm / Volt
	variable X_Offset = numberbykey("X_Offset", scanParameters)
	variable Y_Offset = numberbykey("Y_Offset", scanParameters)
	variable scanOutFreq = numberbykey("scanOutFreq", scanParameters)
	variable scanFrameTime = numberbykey("scanFrameTime", scanParameters)	//ms
	variable lineTime = numberbykey("lineTime", scanParameters)
	variable pixelShift = numberbykey("pixelShift", scanParameters)
	variable displayPixelSize	=  lineSpacing// in µm
	
	make/o/n=((scaledX/displayPixelSize),(scaledY/displayPixelSize),frames) root:Packages:BS2P:CurrentScanVariables:drawnImage = 0
	wave drawnImage = root:Packages:BS2P:CurrentScanVariables:drawnImage
	SetScale/P x X_offset,displayPixelSize,"µm", drawnImage
	SetScale/P y Y_offset,displayPixelSize,"µm", drawnImage
	
	variable scanPointsPerFrame = scanOutFreq*scanFrameTime //
	variable totalDumTime = dimsize(dum, 0) * dimdelta(dum, 0)
	variable pointsInDum = numpnts(dum)
	
	
	////////////////some sort of sanity checking by comparing frames to (totalDumTime / frameTime) ///////////
	if(frames == totalDumTime / scanFrameTime)
		
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//////////////Walk through the dum wave and add "photons" to appropriate pixels of the image////////////
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//		pnt2x(dum, p)	//--dum time values
//		x2pnt(runx, x-value)	//Point number in runx where time = x-value	--rounds to nearest point (nearest voltage)
//		runx[x2pnt(runx, x-value)]	//Voltage of runx when the time is x-value
//		runx[x2pnt(runx,(pnt2x(dum,p))-pixelShift)] * scaleFactor	//X-Galvo position in microns of the focal plane for each value in dum  (subtract out the lag between sending control voltage and the actual position -- measured offline with o-scope)
//		runy[x2pnt(runy,(pnt2x(dum,p))-pixelShift)] * scaleFactor	//Y-Galvo position in microns of the focal plane for each value in dum (subtract out the lag between sending control voltage and the actual position -- measured offline with o-scope)
//		floor(frames*p/pointsInDum)	//FrameNumber (plane) for each point in dum
//
//		altogether we get:
//		currentDisplay((runx[x2pnt(runx,(pnt2x(dum,p))-pixelShift)] * scaleFactor), (runy[x2pnt(runy,(pnt2x(dum,p))-pixelShift)] * scaleFactor), (floor(frames*p/pointsInDum))) += dum[p]
//
//		but igor doesn't like the xscaling so have to convert it to points:
//		x2pnt(currentDisplay, (runx[x2pnt(runx,(pnt2x(dum,p))-pixelShift)] * scaleFactor))
//		x2pnt(currentDisplay, (runy[x2pnt(runy,(pnt2x(dum,p))-pixelShift)] * scaleFactor))

		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////HERE CAN CREATE RUNX AND RUNY FROM VARIABLES STORED IN DUM WAVE IF NEED BE///////////
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		BS_rasterByDwellTime(ScaledX,ScaledY,X_Offset,Y_Offset, scanOutFreq,dwellTime, lineSpacing,frames)
		wave runx = root:Packages:BS2P:CurrentScanVariables:runx
		wave runy = root:Packages:BS2P:CurrentScanVariables:runy
		variable i
		for(i=0; i<numpnts(dum); i+=1)
			drawnImage[x2pnt(drawnImage, (runx[x2pnt(runx,(pnt2x(dum,i))-pixelShift)] * scaleFactor))][x2pnt(drawnImage, (runy[x2pnt(runy,(pnt2x(dum,i))-pixelShift)] * scaleFactor))][floor(frames*i/pointsInDum)] += dum[i]
		endfor
	else
		abort "Should be = " + num2str(frames) + "frames but I calculate " +num2str(totalDumTime / scanFrameTime) + "in dum"
		
	endif

end