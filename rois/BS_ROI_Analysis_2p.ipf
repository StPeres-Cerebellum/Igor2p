#pragma rtGlobals=1		// Use modern global access method.
				//

#include <all ip procedures>


Menu "ROIs"

	"Set the Frame Rate" , /q, SETKCT()
	"Set DFF Baseline for data in this folder" , /q, ManualSetDFFs()
	"-"

	"-"
	"Display the areas used for ROIs",/q,CheckROIs()
	"Display the Images Analyzed in current Folder", /q, displayMaxImages()
	
End



Menu "GraphMarquee"
	
	"-"
		Submenu "ROIs"
			"Freehand Signal", /q, CalcROI("Freehand Signal")
			"Freehand Background", /q, CalcROI("Freehand Background")
			"-"
			Submenu "Remove ROI"
				wave3list("Root:CurrentROIs:All_ROI_list"), /q, RemovetheROI()
			end
			"Clear All ROIs", /q,  ClearROIsFromHere()
			"Draw ROIs Here", /q, DrawROIsHere()
			"Read ROIs from this Image", /q, ReadROIsHERE()
			Submenu "Change color of ROI "
				wave3list("Root:CurrentROIs:All_ROI_list"), /q, ROICOLOR()
			End
		End
		SubMenu "Image"
		"Autoscale", /q, NewAutoscale()
		"-"
		"DFF the Image", /q, ImageDFF()
		"Where is this Image?", /q, WhereIsThisImage()
		"Bin Pixels in Image", /q, binPixels()
		"Make Projections", /q,  imageSubProjections()
		"Average stack", /q, averageStack()
		"Max Stack", /q, projectStack()
		"Print Image Notes", /q, printImageNotes()

		SubMenu "Colors"
				ChoosePalette(), /q, ChangeColors()
		End
		"Invert Colors", /q, Invert()
		End
	
	"-"
	"SET BASELINE DFF", Marquee2Bline()

	
End

function printImageNotes()
	getmarquee/K
	string ImageName=ImageNameList(S_MarqueeWin, ";")
	Imagename = Replacestring(";", Imagename,"") 
	wave Image = ImageNameToWaveRef(S_MarqueeWin,ImageName)

	string waveNotes = note(Image)
	
	variable i
	for(i=0 ; i< itemsinList(waveNotes); i += 1)
		print stringFromList(i, waveNotes)
	endfor
end

function imageProjection()
	
	String info,vaxis,haxis
	String list= ImageNameList("",";")
	String imagePlot = StringFromList(0,list, ";")
	info=ImageInfo("",imagePlot,0)
	info = replacestring(" ", info, "")
	vaxis=StringByKey("YAXIS",info)
	haxis=StringByKey("XAXIS",info)
	variable plane=str2num(StringByKey("plane",info, "="))

	getmarquee $haxis, $vaxis
	string ImageName=ImageNameList("","")
	Imagename = Replacestring(";", Imagename,"") 
	wave ImageStack = ImageNameToWaveRef("",ImageName)

	
	variable xScale = dimdelta(imageStack,0)
	variable yScale = dimdelta(ImageStack,1)
	variable zScale = dimdelta(ImageStack,2)
	imageTransform zProjection imageStack 
	imageTransform xProjection imageStack 
	imageTransform yProjection imageStack 
	
	wave m_zprojection
	wave m_xprojection
	wave m_yprojection
	
//	imagetransform flipcols m_xprojection 
	matrixop/o/free xProj = m_xprojection ^ t
	duplicate/o xProj m_xprojection
//	imagetransform flipcols m_yprojection
	
	SetScale/P x 0,(-zScale),"m", m_xprojection;SetScale/P y 0,(xScale),"m", m_xprojection
	SetScale/P x 0,(yscale),"m", m_yprojection;SetScale/P y 0,(-zScale),"m", m_yProjection
	SetScale/P x 0,(xScale),"m", m_zprojection;SetScale/P y 0,(yScale),"m", m_zProjection
	
	dowindow/k projectionBrowser
	
	display/k=1/n=projectionBrowser
	appendimage/w=projectionBrowser m_zprojection
	appendimage/w=projectionBrowser m_xprojection
	appendimage/w=projectionBrowser m_yprojection
	ModifyGraph width={Plan,1,bottom,left}
	SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (52224,52224,52224),dash= 8
	DrawLine ((dimdelta(m_xProjection,0) * dimsize(m_xProjection,0))),0,(dimdelta(m_yProjection,0) * dimsize(m_yProjection,0)),0
	SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (52224,52224,52224),dash= 8
	DrawLine 0,((dimdelta(m_xProjection,0) * dimsize(m_xProjection,0))),0,(dimdelta(m_yProjection,0) * dimsize(m_yProjection,0))

	
end

function imageSubProjections()
	String info,vaxis,haxis
	String list= ImageNameList("",";")
	String imagePlot = StringFromList(0,list, ";")
	info=ImageInfo("",imagePlot,0)
	info = replacestring(" ", info, "")
	vaxis=StringByKey("YAXIS",info)
	haxis=StringByKey("XAXIS",info)
	variable plane=str2num(StringByKey("plane",info, "="))

	getmarquee $haxis, $vaxis
	string ImageName=ImageNameList("","")
	Imagename = Replacestring(";", Imagename,"") 
	wave ImageStack = ImageNameToWaveRef("",ImageName)
	
//	variable xScale = dimdelta(imageStack,0)
//	variable yScale = dimdelta(ImageStack,1)
//	variable zScale = dimdelta(ImageStack,2)
	
	duplicate/o/r=(v_left,v_right)(v_top,v_bottom) ImageStack subSection
	
	imageTransform zProjection subSection; copyScales subSection, m_zprojection
	imageTransform yProjection subSection
	imageTransform/g=1 transposeVol subsection; copyScales m_volumeTranspose, m_yprojection
	imageTransform xProjection subSection
	imageTransform/g=3 transposeVol subsection
	
	wave m_zprojection
	wave m_xprojection
	wave m_yprojection
	
	matrixop/o/free xProj = m_xprojection ^ t
	duplicate/o xProj m_xprojection
	copyScales m_volumeTranspose, m_xprojection
	
	
	variable depth = dimOffset(subSection, 2) + (dimdelta(subsection, 2) * plane) // For Igor 7.0  -> indexToScale(subsection, plane, 2)
	
	
	dowindow/F viewABove
	if(!v_flag)
		newImage/k=1/n=viewAbove/F subSection
		ModifyGraph width={Plan,1,bottom,left}
		ModifyImage/W=viewAbove subSection plane=(plane)
		SetWindow viewAbove, hook(MyHook) = scrollImagePlanesHook
	endif
	
	getAxis/q/W=viewAbove $vAxis
	variable minHeight = v_min, maxHeight = v_max
	getAxis/q/W=viewAbove $hAxis
	variable minWidth = v_min, maxWidth = v_max
	
	dowindow/F bottomEdge
	if(!v_flag)
		newImage/k=1/n=bottomEdge m_yprojection
		ModifyGraph width={Plan,1,top,left}
		SetDrawEnv/w=bottomEdge xcoord= top,ycoord= left,linefgc= (65535,65533,32768),dash= 3
		SetDrawEnv/w=bottomEdge linethick= 2.00
		drawLine/w=bottomEdge minWidth,depth, maxWidth, depth
	endif
	
	dowindow/F rightEdge
	if(!v_flag)
		newImage/F/k=1/n=rightEdge m_xprojection;
		ModifyGraph width={Plan,1,bottom,left}	
	endif
	
end

Function scrollImagePlanesHook(s)	//This is a hook for the mousewheel movement in MatrixExplorer
	STRUCT WMWinHookStruct &s
	
	String info,vaxis,haxis
	string ImageName=ImageNameList("","")
	Imagename = Replacestring(";", Imagename,"") 
	wave Image = ImageNameToWaveRef("",ImageName)
	info=ImageInfo("",nameofwave(Image),0)
	info = replacestring(" ", info, "")
	vaxis=StringByKey("YAXIS",info)
	haxis=StringByKey("XAXIS",info)
	variable plane=str2num(StringByKey("plane",info, "="))
	variable depth = pnt2x(Image, plane)
	getAxis/q/W=viewAbove $vAxis
	variable minHeight = v_min, maxHeight = v_max
	getAxis/q/W=viewAbove $hAxis
	variable minWidth = v_min, maxWidth = v_max
	

	Variable hookResult = 0
	switch(s.eventCode)
		case 22:					// mouseWheel event
			switch (s.wheelDy)	//wheel movement
				case 3:	//mouse wheel down
					if(plane >= 0 && plane < dimsize(Image,2))
						plane += 1
						print plane
						ModifyImage $ImageName plane=(plane)
						depth = dimOffset(subSection, 2) + (dimdelta(subsection, 2) * plane) // For Igor 7.0  -> indexToScale(subsection, plane, 2)
						
						dowindow bottomEdge
						if(v_flag)
							
							setDrawLayer/w=bottomEdge/k userFront
							SetDrawEnv/w=bottomEdge xcoord= top,ycoord= left,linefgc= (65535,65533,32768),dash= 3
							SetDrawEnv/w=bottomEdge linethick= 2.00
							drawLine/w=bottomEdge minWidth,depth, maxWidth, depth
							
						endif
						
//						print plane, depth
					
						dowindow rightEdge
						if(v_flag)
							
							setDrawLayer/w=rightEdge/k userFront
							SetDrawEnv/w=rightEdge xcoord= bottom,ycoord= left,linefgc= (65535,65533,32768),dash= 3
							SetDrawEnv/w=rightEdge linethick= 2.00
							drawLine/w=rightEdge depth,minHeight, depth, maxHeight
								
						endif
						
	//					Print "up"
					endif
	
					break
				case -3:	//mouse wheel up
					if(plane > 0 && plane <= dimsize(Image,2))
	//					Print "down"
						plane -= 1
						ModifyImage $ImageName plane=(plane)
						depth = dimOffset(subSection, 2) + (dimdelta(subsection, 2) * plane) // For Igor 7.0  -> indexToScale(subsection, plane, 2)
						
						dowindow bottomEdge
						if(v_flag)
						
							setDrawLayer/w=bottomEdge/k userFront
							SetDrawEnv/w=bottomEdge xcoord= top,ycoord= left,linefgc= (65535,65533,32768),dash= 3
							SetDrawEnv/w=bottomEdge linethick= 2.00
							drawLine/w=bottomEdge minWidth,depth, maxWidth, depth
							
						endif
		
						dowindow rightEdge
						if(v_flag)
								
							setDrawLayer/w=rightEdge/k userFront
							SetDrawEnv/w=rightEdge xcoord= bottom,ycoord= left,linefgc= (65535,65533,32768),dash= 3
							SetDrawEnv/w=rightEdge linethick= 2.00
							drawLine/w=rightEdge depth,minHeight, depth, maxHeight
							
						endif
//						print plane
	//					Print "up"
					endif
					break
			endswitch
		break

		case 2:	//close window
		break
//			print "dead"
	endswitch

		return hookResult	// If non-zero, we handled event and Igor will ignore it.
	
end

function averageStack()
	getmarquee/K left, bottom
	string ImageName=ImageNameList("","")
	Imagename = Replacestring(";", Imagename,"") 
	wave ImageStack = ImageNameToWaveRef("",ImageName)

	variable xScale = dimdelta(imageStack,0)
	variable yScale = dimdelta(ImageStack,1)
	
	imageTransform averageImage imageStack; wave m_aveImage
	copyscales imageStack, m_aveImage
//	SetScale/P x 0,(xScale),"m", m_aveImage;SetScale/P y 0,(yScale),"m", m_aveImage
	
	newImage/f M_AveImage
	ModifyGraph width={Plan,1,bottom,left}
	
//	dowindow/F averagedStack
//	if(!v_flag)
//		display/k=1/n=averagedStack
//		appendimage/w=averagedStack M_AveImage
//	endif
end

function projectStack()
	getmarquee/K left, bottom
	string ImageName=ImageNameList("","")
	Imagename = Replacestring(";", Imagename,"") 
	wave ImageStack = ImageNameToWaveRef("",ImageName)

	imageTransform zProjection imageStack; wave m_zProjection
	copyscales imageStack, m_zProjection
//	SetScale/P x 0,(xScale),"m", m_aveImage;SetScale/P y 0,(yScale),"m", m_aveImage
	
	newImage/f m_zprojection
	ModifyGraph width={Plan,1,bottom,left}
	
end

Function CalcROI(ROItype)

	String ROItype// = s_value
	
	//------------Housekeeping for names-----------	
	getmarquee/K
	string ImageName=ImageNameList(S_MarqueeWin, ";")
	Imagename = Replacestring(";", Imagename,"") 
	wave Image = ImageNameToWaveRef(S_MarqueeWin,ImageName)
	string crntfldr = getdatafolder(1)
	
	if(datafolderexists ("root:currentrois") == 0)
		newdatafolder/s root:CurrentROIs
		variable/g root:CurrentROIs:bline_start = nan
		variable/g root:CurrentROIs:bline_end = nan
		variable/g root:CurrentROIs:numbacks = nan
		variable/g root:saveit = 1
		variable/g root:CurrentROIs:exposure = nan
		variable/g root:CurrentROIs:KCT = 1
		variable/g root:currentrois:inverse = 0
		string/g root:CurrentROIs:ListAllROIs
		string/g root:CurrentROIs:RawWaves
		string/g root:CurrentROIs:CurrentWindow
		colortab2wave spectrum; wave m_colors; duplicate/o m_colors root:currentrois:RoiColors; wave roicolors
		string/g root:CurrentROIs:sigcolor = "("+num2str(roicolors[0][0])+", "+num2str(roicolors[0][1])+", "+num2str(roicolors[0][1])+")"
		string/g root:CurrentROIs:backcolor = "(0,0,65280)"
		string/g Root:CurrentROIs:ImageName = GetWavesDataFolder(Image, 2)
//		setkct()
	endif
	setdatafolder root:currentrois
	
	strswitch(ROItype)
		case "Freehand Signal":
			
			GenerateFreehandMask(s_marqueewin, Image)
			NVAR/Z numrois=Root:CurrentROIs:numrois	//makes a global counter containing the total number of ROIs for later use
			NameFreehand(s_marqueewin,numrois,"ROI")
			SVAR CurrentROI = Root:currentROIs:CurrentROI
			variable CurrentNum = str2num(replacestring("ROI_", CurrentROI, ""))
			AddFreehand2Window(CurrentNum,s_marqueewin, "ROI")
			break

		case "Freehand Background":
			
			GenerateFreehandMask(s_marqueewin, Image)
			NVAR/Z numrois=Root:CurrentROIs:numrois	//makes a global counter containing the total number of ROIs for later use
			NameFreehand(s_marqueewin,numrois,"BROI")
			SVAR CurrentROI = Root:currentROIs:CurrentROI
			CurrentNum = str2num(replacestring("ROI_", CurrentROI, ""))
			AddFreehand2Window(CurrentNum,s_marqueewin, "BROI")
			break
			
		case "SIGNAL":
			
			ROI(Image, "ROI")
			SVAR CurrentROI = Root:currentROIs:CurrentROI
			
			break
		
		case "BACKGROUND":
			
			ROI(Image, "BROI")
			SVAR CurrentROI = Root:currentROIs:CurrentROI

			
			break
	endswitch


	NewUpdate(Image)
	DisplayRaw(CurrentROI)
	if(waveexists(BackgroundAverage))
		if(strsearch(TraceNameList("Raw_Window", ";", 0 ), "BackgroundAverage", 0,2) == -1)
			appendtograph/w=Raw_window BackgroundAverage
			ModifyGraph/w=Raw_Window rgb(BackgroundAverage)=(0,0,65280)
		endif
	endif
	DisplaySub(CurrentROI)  	//waveexists braw
	DisplayDFF(CurrentROI)	//waveexists braw
	
	setdatafolder $crntfldr
	string/g Root:CurrentROIs:ImageName = GetWavesDataFolder(Image, 2)

end

Function RemoveTheROI()

	GetLastUserMenuInfo
	
	getmarquee/K
	string ImageName=ImageNameList(S_MarqueeWin, ";")
	Imagename = Replacestring(";", Imagename,"") 
	wave Image = ImageNameToWaveRef(S_MarqueeWin,ImageName)
	
	Remove1ROI(s_value,  S_Marqueewin, Image)
end
function ClearROIsFromHere()

	getmarquee/K	
	SetDrawLayer/W=$S_MarqueeWin/K userfront
	string ImageName=ImageNameList(S_MarqueeWin, ";")
	Imagename = Replacestring(";", Imagename,"") 
	wave Image = ImageNameToWaveRef(S_MarqueeWin,ImageName)

	removeall(s_marqueeWin, Image)
	SetDrawEnv/W=kineticWindow xcoord= bottom,ycoord= left,linefgc= (65280,0,0),dash= 2;DelayUpdate

	DrawLine/W=kineticWindow  (-39e-6), (-23.9e-6),  (-19e-6),  (-23.9e-6)
	SetDrawEnv/W=kineticWindow xcoord= bottom,ycoord= left,linefgc= (65280,0,0),dash= 2;DelayUpdate

	DrawLine/W=kineticWindow  (-29e-6), (-34e-6),  (-29e-6),  (-14e-6)
end

function ImageDFF()
	
	string ImageName=ImageNameList("","")
	Imagename = Replacestring(";", Imagename,"") 
	wave Image = ImageNameToWaveRef("",ImageName)
	
	make/o/n=(dimsize(image,0),dimsize(image,1)) Fzero
	variable i
	for(i=0;i<=12;i+=1)
		Fzero += image[p][q][i]
	endfor
	Fzero/=13
	duplicate/o image root:CurrentROIs:DFFimage
	wave dffimage = root:currentrois:dffimage
	for(i=0;i<dimsize(DFFimage,2);i+=1)
		Dffimage[][][i] -= Fzero[p][q][0]
		Dffimage[][][i] /= Fzero[p][q][0]
	endfor
	//dffimage *= -dffimage		
	dowindow/z DFFofImage
	if(v_flag == 0)
		display/k=1
		DoWindow/Z/C/T DFFofImage,"DFF Of Image"
		appendimage DFFImage
		ModifyGraph width={Plan,1,bottom,left}
		//addaslider()
	endif
	Killwaves Fzero
	WMAppend3DImageSlider()
end

Function/S ChoosePalette()
	string color	
	sprintf color, "*COLORTABLEPOP*"
	return color
end

Function/S ChooseColors()
	string color
	sprintf color, "*COLORPOP*"
	return color
end

Function DrawROIsHere()

	getmarquee/K
	string ImageName=ImageNameList(S_MarqueeWin, ";")
	Imagename = Replacestring(";", Imagename,"") 
	wave Image = ImageNameToWaveRef(S_MarqueeWin,ImageName)
	SVAR CurrentWindow = root:currentRois:CurrentWindow
	
	string crntfldr = getdatafolder(1)
	setdatafolder root:currentrois
	
	CurrentWindow = S_MarqueeWin; //print s_value
	DrawAllROIs(S_MarqueeWin,Image)
	DrawROIs()
	DrawBROIs()
	setdatafolder $crntfldr
end

function ReadROIsHERE()
	getmarquee/K
	string ImageName=ImageNameList(S_MarqueeWin, ";")
	Imagename = Replacestring(";", Imagename,"") 
	wave Image = ImageNameToWaveRef(S_MarqueeWin,ImageName)
	SVAR CurrentWindow = root:currentRois:CurrentWindow
	CurrentWindow = s_MarqueeWin; print "ROIs read from",s_MarqueeWin
	NewUpdate(Image)
end


function ROICOLOR()
	
	getmarquee
	string CurrentWindow = s_marqueewin
	getlastusermenuinfo
	variable incPOSITION = (itemsinlist(s_value, "_") - 1)
	variable numROIs = str2num(stringFromList(incPOSITION, s_value, "_")); print numROIs
	string raw = "raw_"+s_value
	string sub = "subtracted_"+s_value
	string dff = "DFF_"+s_value
	choosecolor
	
	wave roicolors = root:currentrois:roicolors
	roicolors[(numrois-1)*15][0] = V_red
	roicolors[(numrois-1)*15][1] = V_Green
	roicolors[(numrois-1)*15][2] = V_Blue 
	//print V_Red, V_green, V_BLUE
	SetDrawLayer/W=$CurrentWindow/K userfront
	drawrois()
	//ModifyGraph rgb(RAW_ROI_8)=(0,0,0)
	//root:CurrentROIs:RAW_ROI_7
	
	ModifyGraph/w=Raw_Window rgb($raw)=(V_red,V_green,V_blue)
	ModifyGraph/w=BackgroundSubtracted rgb($sub)=(V_red,V_green,V_blue)
	ModifyGraph/w=DeltaFOverF rgb($dff)=(V_red,V_green,V_blue)
	DrawROIsHere()
	
end

Function SETKCT()
	wave kineticSeries = root:Packages:BS2P:CurrentScanVariables:kineticSeries
	NVAR KCT = root:currentROIs:KCT
	if(NVAR_exists(KCT) == 0 )
		variable/g root:currentrois:KCT
	endif
	if(waveexists(kineticSeries))
		string scanParameters = note(kineticSeries)
		KCT = numberbykey("KCT", scanParameters)
	else	
		variable tempkct
		prompt tempKCT, "Time between frames (s)."  
		DoPrompt "KCT", TempKCT
		if (V_Flag)
			return -1								// User canceled
		endif
		KCT = TempKCT
	endif
//	update()
end


function invert()
	
	string ImageName=ImageNameList("","")
	Imagename = Replacestring(";", Imagename,"")// print imagename
	wave Image = ImageNameToWaveRef("",ImageName)
	NVAR/Z inversion = root:currentROIs:inversion
	If(NVAR_exists(inversion) == 0)
		variable/g root:CurrentROIs:Inversion = 1
		NVAR/Z inversion = root:currentROIs:inversion
	endif
	modifyimage $ImageName ctab={,,,inversion}
	inversion-=1
	inversion*= inversion
end

function ChangeColors()
	
	GetLastUserMenuInfo
	print s_value
	
	string ImageName=ImageNameList("","")
	Imagename = Replacestring(";", Imagename,"") 
	wave Image = ImageNameToWaveRef("",ImageName)
	
	ModifyImage $ImageName ctab= {,,$S_Value}
end	
	
End


function Autoscale()
	
	string ImageName=ImageNameList("","")
	Imagename = Replacestring(";", Imagename,"") 
	wave Image = ImageNameToWaveRef("",ImageName)

	getmarquee/k left, bottom
	
	make/b/u/o/n=(dimsize(Image,0), Dimsize(Image,1)) mask = 1
	setscale/P x,  dimoffset(Image,0), dimdelta(Image,0), mask
		
	variable leftpoint =  (V_left - DimOffset(Image, 0))/DimDelta(Image,0)	
	variable rightpoint = (V_right - DimOffset(Image, 0))/DimDelta(Image,0)
	variable bottompoint = (V_bottom - DimOffset(Image, 1))/DimDelta(Image, 1)
	variable toppoint = (V_top - DimOffset(Image, 1))/DimDelta(Image, 1)
	
	mask[LeftPoint,RightPoint][BottomPoint,TopPoint] = 0

//	make/b/u/o/N=(Dimsize(Image,0), Dimsize(Image, 1)) mask = 1
//	mask[V_left,V_right][V_bottom,V_top] = 0
	
	imagestats/M=1/R=mask Image
	ModifyImage $ImageName ctab= {V_min,V_max,}
	killwaves mask
end



function Marquee2Bline()
	
	string crntfldr = getdatafolder(1)
	setdatafolder root:CurrentROIs
	
	NVAR bline_start = root:currentROIs:bline_start
	if(NVAR_exists(bline_start) ==0 )
		variable/g root:currentROIs:bline_start = 0
	endif
	
	NVAR bline_end = root:currentROIs:bline_end
	if(NVAR_exists(bline_end) == 0 )
		variable/g root:currentROIs:bline_end = 0
	endif
	
	getmarquee/k left, bottom
	bline_start = v_left
	bline_end = v_right
	
	SVAR ImageName = Root:CurrentROIs:ImageName
	wave Image = $ImageName
	NewUpdate(Image)
	
	setdatafolder $crntfldr
	if(itemsinlist(wavelist("subtracted_*",";","")))
		ChangeDFFs(bline_start,bline_end)
	endif
end



 function ROI(Image, ROIorBROI)
 	wave Image
 	string ROIorBROI
	SetDrawLayer UserFront
	getwindow kwtopwin, activesw
	string/g root:currentROIs:CurrentWindow = s_value
	string ROIFolder = "Root:CurrentROIs"
	variable counter = 1

	
	dowindow/z Summary_Window
	if(v_flag == 0)
		edit/k=1
		DoWindow/Z/C/T Summary_Window,"Summary"
	endif
	
	NVAR/Z numrois=Root:CurrentROIs:numrois	//makes a global counter containing the total number of ROIs for later use
		if( NVAR_Exists(numrois) )
			numrois += 1
		else 
			variable/g Root:CurrentROIs:numrois = 1
			NVAR/Z numrois=Root:CurrentROIs:numrois
		endif
	
	getmarquee/k left, bottom
	
	//creates strings for ROI names and coordinates
	string roi = "Root:CurrentROIs:ROI_"+num2str(numrois)
	string/g Root:CurrentROIs:CurrentROI = "ROI_"+num2str(numrois)
	string broi = "Root:CurrentROIs:BROI_"+num2str(numrois)
	string roi_left = "Root:CurrentROIs:Left_ROI_"+num2str(numrois)
	string roi_top = "Root:CurrentROIs:top_ROI_"+num2str(numrois)
	string roi_right = "Root:CurrentROIs:right_ROI_"+num2str(numrois)
	string roi_bottom = "Root:CurrentROIs:bottom_ROI_"+num2str(numrois)
	wave ROIcolors= root:Currentrois:roicolors
	string maskname = "Mask_"+ROIorBROI+"_"+num2str(numrois)
		
	variable/g $roi_left = V_left// * 0.253968254
	variable/g $roi_top = V_top// * 0.253968254
	variable/g $roi_right = V_right// * 0.253968254
	variable/g $roi_bottom = V_bottom// * 0.253968254
	NVAR nbacks = root:CurrentROIs:numbacks
		
	make/b/u/o/n=(dimsize(Image,0), Dimsize(Image,1)) mask = 1
	setscale/P x,  dimoffset(Image,0), dimdelta(Image,0), mask

	
	variable leftpoint =  (v_left - DimOffset(Image, 0))/DimDelta(Image,0)	
	variable rightpoint = (v_right - DimOffset(Image, 0))/DimDelta(Image,0)
	variable bottompoint = (v_bottom - DimOffset(Image, 1))/DimDelta(Image, 1)
	variable toppoint = (v_top - DimOffset(Image, 1))/DimDelta(Image, 1)
	
	
	mask[LeftPoint,RightPoint][BottomPoint,TopPoint] = 0
	duplicate/o mask $maskname
	
	StrSwitch(ROIorBROI)
		Case "ROI" :
			SVAR sigcolor = root:currentrois:sigcolor
			sigcolor =  "("+num2str(roicolors[(numrois-1)*15][0])+", "+num2str(roicolors[(numrois-1)*15][1])+", "+num2str(roicolors[(numrois-1)*15][2])+")"
			String Figor1 = "SetDrawEnv xcoord= bottom,ycoord= left,linefgc="+sigcolor+",fillpat= 0, linethick= 2.00; DrawRect "+num2str(V_left)+","+num2str(V_top)+","+num2str(V_right)+","+num2str(V_bottom)
			String Figor2 = "SetDrawEnv xcoord= bottom,ycoord= left, textrgb="+sigcolor+" ; drawtext "+num2str(V_right-1)+","+num2str(V_bottom-5)+", "+"\""+num2str(numrois)+"\""
			Execute Figor1
			Execute Figor2
			break
		Case "BROI" :
			SVAR BackColor = root:currentrois:BackColor
			Figor1 = "SetDrawEnv xcoord= bottom,ycoord= left,linefgc="+backColor+",fillpat= 0, linethick= 2.00; DrawRect "+num2str(V_left)+","+num2str(V_top)+","+num2str(V_right)+","+num2str(V_bottom)
			Figor2 = "SetDrawEnv xcoord= bottom,ycoord= left, textrgb="+backColor+" ; drawtext "+num2str(V_right-1)+","+num2str(V_bottom-5)+", "+"\""+num2str(numrois)+"\""
			Execute Figor1
			Execute Figor2
			nbacks += 1
			break
	endSwitch
		
		string/g $roi
end




Function Raw(ROI,Image)  //READ from variables associated with "ROI"
	string ROI
	wave Image
//			***************
//			Get datafolder folder containing the image on the top graph and put the selected ROI on the top graph
	NVAR numROIs = root:currentrois:numrois

	
	
	string ROIavg = "root:CurrentROIs:RAW_" + ROI
	string bROIavg = "root:CurrentROIs:BRAW_" + ROI
		
	string left_string = "Root:currentrois:Left_"+ ROI
	string right_string = "Root:currentrois:right_"+ ROI
	string top_string = "Root:currentrois:top_"+ ROI
	string bottom_string = "Root:currentrois:bottom_"+ ROI
	
	NVAR left = $left_string
	NVAR right = $right_string
	NVAR top = $top_string
	NVAR bottom =$bottom_string
	NVAR KCT = root:currentrois:KCT
	string scanParameters = note(Image)
	KCT = numberbykey("KCT", scanParameters)
//			****************
//			process ROI
	
//	make/b/u/o/N=(Dimsize(Image,0), Dimsize(Image, 1)) mask = 1
//	duplicate/o/R=[][][0] image mask
	string Mask = "Mask_"+ROI
	string bMask = "Mask_B"+ROI
	string fMask = "fMask_"+ROI
	string fbMask = "fMask_B"+ROI
	
	if(waveexists($Mask))
		imagestats/M=1/BEAM/R=$Mask Image
		wave W_ISBeamAvg
		duplicate/o W_ISBeamAvg $ROIavg
		SetScale/P x 0,KCT,"", $ROIavg
		SVAR RAWWaves = root:currentrois:RAWWaves
		RAWWaves = wavelist("RAW_*",";","")
	elseif(waveexists($fMask))
		imagestats/M=1/BEAM/R=$fMask Image
		wave W_ISBeamAvg
		duplicate/o W_ISBeamAvg $ROIavg
		SetScale/P x 0,KCT,"", $ROIavg
		SVAR RAWWaves = root:currentrois:RAWWaves
		RAWWaves = wavelist("RAW_*",";","")
	elseif(waveexists($bMask))
		imagestats/M=1/BEAM/R=$bMask Image
		wave W_ISBeamAvg
		duplicate/o W_ISBeamAvg $bROIavg
		SetScale/P x 0,KCT,"", $bROIavg
		SVAR bRAWWaves = root:currentrois:bRAWWaves
		bRAWWaves = wavelist("BRAW_*",";","")
	elseif(waveexists($fbMask))
		imagestats/M=1/BEAM/R=$fbMask Image
		wave W_ISBeamAvg
		duplicate/o W_ISBeamAvg $bROIavg
		SetScale/P x 0,KCT,"", $bROIavg
		SVAR bRAWWaves = root:currentrois:bRAWWaves
		bRAWWaves = wavelist("BRAW_*",";","")
	endif

//	killwaves w_isbeamavg w_isbeammax w_isbeammin //mask
	
end

function DisplayRaw(CurrentROI)
	string CurrentROI
	string RawData = "root:CurrentROIs:RAW_"+ CurrentROI
	wave RawDataWave = $RawData; string tracename = nameofwave(RawDataWave)//; print tracename
	string BrawData = "root:CurrentROIs:BRAW_"+ CurrentROI;
	string BrawDataShort = "Braw_"+CurrentROI
	
	SVAR sigcolor = root:currentrois:sigcolor
	dowindow/z Raw_WINDOW
		If(V_Flag == 0)
			display/k=1 /W=(853.5,41.75,1053.75,174.5)
			DoWindow/Z/C/T Raw_Window,"Raw Measurements"
		endif
		dowindow/z summary_WINDOW
		If(V_Flag == 0)
			edit/k=1
			DoWindow/Z/C/T Summary_WINDOW,"summary"
		endif
	//modifygraph/w=raw_window gbRGB = (56576,56576,56576)
	if(waveexists($RawData))
		appendtograph/w=raw_window $RawData
		string figor = "ModifyGraph/w=raw_window rgb("+tracename+")="+SigColor
		execute figor
		appendtotable/w=Summary_window $RawData
		ModifyTable/w=Summary_window rgb($RawData)=(65280,0,0)
	endif
	if(waveexists($BRawData))
		appendtograph/w=Raw_window $BrawData
		appendtotable/w=Summary_window $BrawData
		ModifyTable/w=Summary_window rgb($BrawDataShort)=(0,0,39168)
		ModifyGraph/w=Raw_Window lstyle($BrawDataShort)=1,rgb($BrawDataShort)=(48896,49152,65280)
	endif
end



function SubtractBackground(CurrentROI)
	string CurrentROI
	
	string subname = "root:currentrois:SUBTRACTED_"+CurrentROI //Raw data
	string RawData = "root:CurrentROIs:RAW_"+ CurrentROI
	wave raw = $RawData
	wave BackgroundAverage
	NVAR KCT = root:currentrois:KCT
	make/o/n=(numpnts(raw)) $subname = raw - BackgroundAverage
	SetScale/P x 0,KCT,"", $subname
end

function displaysub(CurrentROI)
	string currentROI
	string subname = "root:currentrois:SUBTRACTED_"+CurrentROI
	wave SubDataWave = $subname; string tracename = nameofwave(SubDataWave)
	SVAR sigcolor = root:currentrois:sigcolor
	Dowindow/z BackgroundSubtracted
		If(V_Flag == 0)
			display/k=1 /W=(854.25,203,1056,356.75)
			DoWindow/Z/C/T BackgroundSubtracted,"Background Subtracted"
		endif
	If(waveexists($subName))
		appendtograph/w=BackgroundSubtracted $SubName
		string figor = "ModifyGraph/w=BackgroundSubtracted rgb("+tracename+")="+SigColor
		execute figor
		//modifygraph/w=BackgroundSubtracted gbRGB = (56576,56576,56576)
		appendtotable/w=Summary_window $SubName
		ModifyTable/w=Summary_window rgb($SubName)=(65280,0,0)
	endif
end

function displayDFF(CurrentROI)
	string CurrentROI
	string DFF_name = "DFF_"+CurrentROI
	wave DFFDataWave = $DFF_Name; string tracename = nameofwave(DFFDataWave)
	SVAR sigColor = root:currentrois:sigcolor
	Dowindow/z DeltaFOverF
	If(V_Flag == 0)
		display/k=1 /W=(854.25,384.5,1056.75,734.75) 
		DoWindow/Z/C/T DeltaFOverF,"DF/F"
		Legend/F=0/N=text0/J/A=LT/X=0.00/Y=0.00
	endif
	If(WaveExists($DFF_Name))
		appendtograph/w=DeltaFOverF $DFF_Name
		string figor = "ModifyGraph/w=DeltaFOverF rgb("+DFF_Name+")="+SigColor
		execute figor
		//modifygraph/w=DeltaFOverF gbRGB = (56576,56576,56576)
		appendtotable/w=Summary_window $DFF_Name
		ModifyTable/w=Summary_window rgb($DFF_Name)=(65280,0,0)
	EndIf
end

function MakeDFF(CurrentROI)
	string CurrentROI
	
	NVAR bline_start = Root:CurrentROIs:bline_start 	//variables containing baseline START 
		if(NVAR_exists(bline_start) == 0)
			variable/g Root:CurrentROIs:bline_start = 0
		endif
	
	NVAR bline_end = Root:CurrentROIs:bline_end		//and END (both are set in the DF/F graph of the panel)
		if(NVAR_exists(bline_end) == 0)
			variable/g Root:CurrentROIs:bline_end = 5
		endif
		
	string DFF_name = "DFF_"+CurrentROI
	string subname = "root:currentrois:SUBTRACTED_"+CurrentROI
	duplicate/o $subname temp
	wavestats/q/r=(bline_start, bline_end) temp
	temp -= v_avg
	temp /= v_avg
	duplicate/o temp $DFF_Name
	killwaves temp
end



function Remove1ROI(ROI, S_Marqueewin, Image)
	string ROI, S_marqueewin
	wave Image
	
//	SVAR CurrentWindow = root:CurrentROis:CurrentWindow
//	SVAR ImageName = 	Root:CurrentROIs:ImageName 
//	wave Image = $ImageName
	SetDrawLayer/W=$s_marqueeWin/K userfront
	string crntfldr = getdatafolder(1)
	setdatafolder root:currentrois
	
	string raw = "RAW_" + ROI
	string braw = "BRAW_" + ROI
	string sub = "SUBTRACTED_"+ ROI
	string dff = "DFF_"+ ROI

	string FreehandROIy = "Freehand_"+ ROI+"_y"
	string FreehandROIx = "Freehand_"+ ROI+"_x"
	String Mask = wavelist("*mask*"+ROI, "", "")
	string FreehandbROIy = "Freehand_B"+ ROI+"_y"
	string FreehandbROIx = "Freehand_B"+ ROI+"_x"
	
	string tableping = wavelist(raw,";","WIN:Summary_window")
	if( strlen(tableping) >0)
		removefromtable/z/w=Summary_window $raw
	endif
	RemoveFromGraph/z/w=Raw_window $raw; killwaves/z $raw 
	
	tableping = wavelist(braw,";","WIN:Summary_window")
	if( strlen(tableping) >0)
		removefromtable/z/w=Summary_window $braw
	endif
	RemoveFromGraph/z/w=Raw_window $braw; killwaves/z $braw 
	
	tableping = wavelist(sub,";","WIN:Summary_window")
	if( strlen(tableping) >0)
		removefromtable/z/w=Summary_window $sub
	endif
	RemoveFromGraph/z/w=BackgroundSubtracted $sub; killwaves/z $sub
	
	tableping = wavelist(dff,";","WIN:Summary_window")
	if( strlen(tableping) >0)
		removefromtable/z/w=Summary_window $DFF
	endif
	RemoveFromGraph/z/w=DeltaFoverF $DFF; killwaves/z $dff 
	
	wave BackgroundAverage = root:currentRois:backgroundaverage
	tableping = wavelist("BackgroundAverage",";","WIN:Summary_window")
	if( strlen(tableping) >0)
		removefromtable/z/w=Summary_window BackgroundAverage
	endif
	RemoveFromGraph/z/w=Raw_window BackgroundAverage; killwaves/z BackgroundAverage
	
	string left = "left_"+roi; killvariables/z $left
	string right = "right_" + roi; killvariables/z $right
	string bottom = "bottom_" + roi; killvariables/z $bottom
	string top = "top_" + roi; killvariables/z $top
	string marker = "B"+roi; killstrings/z $marker
	string marker2 = roi; killstrings/z $marker2
	string rawroimarker = "Raw_"+roi
	
	SVAR Rawwaves = root:currentrois:rawwaves
	rawwaves = ReplaceString(rawroimarker, rawwaves, "")
	

	Killwaves/Z $FreehandROIx
	Killwaves/Z $FreehandROIy
	Killwaves/Z $FreehandbROIx
	Killwaves/Z $FreehandbROIy
	Killwaves/Z $Mask
	
	MakeListofROIs()
	DrawAllROIs(S_MarqueeWin, Image)
	NewUpdate(Image)

	setdatafolder $crntfldr
	
end

function removeall(S_marqueeWin, Image)
	string S_marqueeWin
	Wave Image
	string crntfldr = getdatafolder(1)
	setdatafolder root:currentrois
	
	MakeListofROIs()
	variable stop = numpnts(all_roi_list)
	wave/t all_roi_list = root:currentrois:all_roi_list
	duplicate/o/t all_roi_list temp_roi_list
	wave/t temp_roi_list
		variable i
		for(i = 0; i < numpnts(temp_roi_list) ; i += 1)
			string roi = temp_roi_list[i]
			Remove1ROI(ROI, S_marqueeWin,Image)
		endfor
	killwaves temp_roi_list
	wave BackgroundAverage = root:currentRois:backgroundaverage
	string tableping = wavelist("BackgroundAverage",";","WIN:Summary_window"); //print strlen(tableping)
		if( strlen(tableping) >0)
			removefromtable/z/w=Summary_window BackgroundAverage
		endif
	RemoveFromGraph/z/w=Raw_Window BackgroundAverage; killwaves/z BackgroundAverage
	killwaves/a
	killdatafolder root:currentrois
	if(stringmatch(crntfldr, "root:currentrois:") == 0)
		setdatafolder $crntfldr
	endif
end

function DrawROIs()
	
	string crntfldr = getdatafolder(1)
	setdatafolder root:currentrois
	MakeListofROIs()
	wave/t roi_list = root:currentrois:roi_list
//	wave/t FreeROIs = root:currentrois:FreeROIs
	wave roicolors = root:currentrois:roicolors
	SVAR sigcolor = root:currentrois:sigcolor
	SVAR CurrentWindow = root:CurrentRois:CurrentWindow
	
	Dowindow/Z/F $CurrentWindow
	SetDrawLayer/W=$CurrentWindow userfront
	variable i
	if(numpnts(roi_list)> 0)	
		for(i=0; i<numpnts(roi_list); i += 1)
			string ROI = roi_list[i]
			variable incPOSITION = (itemsinlist(ROI, "_") - 1)
			variable numrois = str2num(stringFromList(incPOSITION, ROI, "_"))//; print numrois
			string hbrROIleft = "root:currentrois:left_" + ROI
			string hbrROItop = "root:currentrois:top_" + ROI
			string hbrROIright = "root:currentrois:right_" + ROI
			string hbrROIbottom = "root:currentrois:bottom_" + ROI
					
			NVAR left1 = $hbrROIleft	
			NVAR top1 = $hbrROItop
			NVAR right1 = $hbrROIright
			NVAR bottom1 = $hbrROIbottom
			sigcolor =  "("+num2str(roicolors[(numrois-1)*15][0])+", "+num2str(roicolors[(numrois-1)*15][1])+", "+num2str(roicolors[(numrois-1)*15][2])+")"
			//print sigcolor
			string Figor1 = "SetDrawEnv/w="+CurrentWindow+" xcoord= bottom,ycoord= left,linefgc= "+SigColor+",fillpat= 0, linethick= 2.00"
			string Figor2 = "SetDrawEnv/w="+CurrentWindow+" xcoord= bottom,ycoord= left, textrgb="+SigColor
			
		//	String Figor2 = "SetDrawEnv/w="+CurrentWindow+" xcoord= bottom,ycoord= left, textrgb="+SigColor+" ; drawtext "+num2str(V_right-5)+","+num2str(V_bottom-15)+", "+"\""+num2str(numrois)+"\""
			
			execute Figor1;  DrawRect left1,top1,right1,bottom1
			execute Figor2; Drawtext right1 - 5, bottom1 - 15, num2str(numrois)
		endfor
	endif
	setdatafolder $crntfldr

end

function DrawBROIs()

	string crntfldr = getdatafolder(1)
	setdatafolder root:currentrois
	MakeListofROIs()
	wave/t broi_list = root:currentrois:broi_list
	SVAR backcolor = root:currentrois:backcolor
		if(svar_exists(backcolor) == 0 )
			string/g root:CurrentROIs:backcolor = "(0,0,65280)"
		endif
			
	
	SVAR CurrentWindow = root:CurrentRois:CurrentWindow
	
	Dowindow/Z/F $CurrentWindow
	
	string Figor1 = "SetDrawEnv/w="+CurrentWindow+" xcoord= bottom,ycoord= left,linefgc= "+backcolor+",fillpat= 0, linethick= 2.00"
	string Figor2 = "SetDrawEnv/w="+CurrentWindow+" xcoord= bottom,ycoord= left, textrgb="+backcolor
	if(numpnts(broi_list)> 0)	
		variable i
		for(i=0; i<=numpnts(broi_list); i += 1)
			string ROI = broi_list[i]
			string hbrROIleft = "root:currentrois:left_" + ROI
			string hbrROItop = "root:currentrois:top_" + ROI
			string hbrROIright = "root:currentrois:right_" + ROI
			string hbrROIbottom = "root:currentrois:bottom_" + ROI
					
			NVAR left1 = $hbrROIleft	
			NVAR top1 = $hbrROItop
			NVAR right1 = $hbrROIright
			NVAR bottom1 = $hbrROIbottom
						
			execute Figor1;  DrawRect left1,top1,right1,bottom1
			execute Figor2; Drawtext left1,top1+.01, ROI
		endfor
	endif
	setdatafolder $crntfldr
end



//////////////////////////////////////////////////////////////////////--utilities
Function AddASlider()
	String grfName= "ImgsA"
	Wave w = stim_7	// get the wave associated with the top image.	
	if(DimSize(w,2)<=0)
		DoAlert 0,"Need a 3D image"
		return 0
	endif
	
	ControlInfo/w=ImgsA WM3DAxis
	if( V_Flag != 0 )
		return 0			// already installed, do nothing
	endif
	
	String dfSav= GetDataFolder(1)
	NewDataFolder/S/O root:Packages
	NewDataFolder/S/O WM3DImageSlider
	NewDataFolder/S/O $grfName
	
	Variable/G gLeftLim=0,gRightLim=DimSize(w,2)-1,gLayer=0
	String/G imageName=nameOfWave(w)
	Variable/G gOriginalHeight= V_Height		// we append below original controls (if any)

	GetWindow ImgsA,gsize
	
	Slider WM3DAxis,pos={26,30},size={315,12},proc=ROIsSliderProc
	Slider WM3DAxis,limits={0,gRightLim,1},value= 0,vert= 0,ticks=0,side=0,variable=gLayer	
	
	SetVariable WM3DVal,pos={345,30},size={60,20}
	SetVariable WM3DVal,limits={0,INF,1},title=" ",proc=WM3DImageSliderSetVarProc
	
	String cmd
	sprintf cmd,"SetVariable WM3DVal,value=%s",GetDataFolder(1)+"gLayer"
	Execute cmd

	ModifyImage/w=ImgsA $imageName plane=0
	// 
	WaveStats/Q w
	NVAR inverse = root:currentrois:inverse
	ModifyImage/w=ImgsA $imageName ctab= {V_min,V_max,,inverse}	// missing ctb to leave it unchanced.
	
	SetDataFolder dfSav
End

Function ROIsSliderProc(ctrlName,sliderValue,event) : SliderControl
	String ctrlName
	Variable sliderValue
	Variable event	// bit field: bit 0: value set, 1: mouse down, 2: mouse up, 3: mouse moved

	String dfSav= GetDataFolder(1)
	String grfName= "ImgsA"
	SetDataFolder root:Packages:WM3DImageSlider:$(grfName)

	NVAR gLayer
	SVAR imageName

	ModifyImage/w=ImgsA  $imageName plane=(gLayer)	
	SetDataFolder dfSav

	// 08JAN03 Tell us if there is an active LineProfile
	SVAR/Z imageGraphName=root:Packages:WMImProcess:LineProfile:imageGraphName
	if(SVAR_EXISTS(imageGraphName))
		if(cmpstr(imageGraphName,grfName)==0)
			ModifyGraph/W=$imageGraphName offset(lineProfileY)={0,0}			// This will fire the S_TraceOffsetInfo dependency
		endif
	endif	
		
	SVAR/Z imageGraphName=root:Packages:WMImProcess:ImageThreshold:ImGrfName
	if(SVAR_EXISTS(imageGraphName))
		if(cmpstr(imageGraphName,grfName)==0)
			WMImageThreshUpdate()
		endif
	endif
	
	return 0	
	
	
	
	if(event %& 0x1)	// bit 0, value set

	endif

	return 0
End

Static Function List2Wave(strList, wName) //from neuromatic
	String strList
	String wName // wave name
	
	Variable icnt
	String item
	
	Variable items = ItemsInList(strList)
	
	if (items == 0)
		return -1 // nothing to do
	endif
	
	if (WaveExists($wName) == 1)
		DoAlert 0, "Abort List2Wave: wave " + wName + " already exists."
		return -1
	endif
	
	Make /T/N=(items) $wName
	
	Wave /T wtemp = $wName
	
	for (icnt = 0; icnt < items; icnt += 1)
		wtemp[icnt] = StringFromList(icnt, strList)
	endfor
	
	return 0

End // List2Wave

function MakeListofROIs()
	string crntfldr = getdatafolder(1)
	setdatafolder root:currentrois
	
	SVAR ListallROIs = root:currentROIs:listallrois
	if(SVAR_exists(listallrois) == 0 )
		variable/g root:currentrois:ListAllROIs
	endif
	string raws = wavelist("Mask_ROI_*",";","")
	string braws = wavelist("Mask_BROI_*",";","")
	string fraws = wavelist("fMask_ROI_*",";","")
	string fbraws = wavelist("fMask_BROI_*",";","")
	string alls = wavelist("*RAW_*",";","")
	string allraws = raws+fraws
	string allbraws = braws+fbraws
	
	raws = replacestring("Mask_", raws, "")
	braws = replacestring("Mask_B", braws, "")
	fraws = replacestring("fMask_", fraws, "")
	fbraws = replacestring("fMask_B", fbraws, "")
	alls = replacestring("RAW_", alls, ""); alls = replacestring("B", alls, "")
	allraws = replacestring("Mask_", allraws, ""); allraws = replacestring("f", allraws, "")
	allbraws = replacestring("Mask_B", allbraws, ""); allbraws = replacestring("f", allbraws, "")

	
	listallrois = alls
	
		if(strlen(raws) > 0)	//This is a list of all MARQUEE SIGNAL
			killwaves/z roi_list
			list2wave(raws, "ROI_List")
		else
			make/t/o/n=0 ROI_List
		endif
	
		if(strlen(braws) > 0)	//This is a list of MARQUEE BKGRND
			killwaves/z broi_list
			list2wave(braws, "BROI_List")
		else
			make/t/o/n=0 BROI_List
		endif
		
		if(strlen(fraws) > 0)	//This is a list of FREEHAND SIGNAL rois
			killwaves/z froi_list
			list2wave(fraws, "fROI_List")
		else
			make/t/o/n=0 fROI_List
		endif
	
		if(strlen(fbraws) > 0)	//This is a list of FREEHAND BKGRND rois
			killwaves/z fbroi_list
			list2wave(fbraws, "fBROI_List")
		else
			make/t/o/n=0 fBROI_List
		endif
		
		if(strlen(alls) > 0)		//This is a list of ALL rois
			killwaves/z all_roi_list
			list2wave(alls, "All_ROI_List")
		else
			make/t/o/n=0 All_ROI_List
		endif
		
		if(strlen(allraws) > 0)	//This is a list of ALL SIGNAL rois
			killwaves/z every_roi_list
			list2wave(allraws, "every_ROI_List")
		else
			make/t/o/n=0 every_ROI_List
		endif
		
		if(strlen(allbraws) > 0)	//This is a list of ALL BKGRND rois
			killwaves/z every_broi_list
			list2wave(allbraws, "every_bROI_List")
		else
			make/t/o/n=0 every_bROI_List
		endif
	setdatafolder $crntfldr
	
end


Function /S Wave3List( wName )
	String wName // wave name
	
	Variable icnt, text, npnts, numObj
	String strObj, wList = ""
	
//	if ( WaveExists( $wName ) == 0 )
//		return ""
//	endif
	
	if ( WaveType( $wName ) == 0 )
		Wave /T wtext = $wName
		npnts = numpnts( wtext )
		text = 1
	else
		Wave wtemp = $wName
		npnts = numpnts( wtemp )
	endif
	
	for ( icnt = 0; icnt < npnts; icnt += 1 )
		if ( text == 1 )
			strObj = wtext[icnt]
			if ( strlen( strObj ) > 0 )
				wList = AddListItem( strObj, wList, ";", inf )
			endif
		else
			wList = AddListItem( num2str( wtemp[icnt] ), wList, ";", inf )
		endif 
	endfor
	
	return wList

End // Wave3List


//function Show1FITS()
//	variable refnum
//	string file, fileFilters = "Fits Images (*.fits):.fits;"		//restricts files to .fits
//	open/z=2/r/f=fileFilters refnum	//this open does nothing...it's just for getting the filename info below
//	if( v_flag == -1 )
//		return v_flag
//	endif
//	string extension = ParseFilePath(4, s_filename, ":", 0, 0)
//	string filename = parsefilepath(0, s_filename, ":", 1, 0)//; print filename
//	//string prefix
//	//Variable inc; sscanf filename, "%[A-Za-z_]%d", prefix, inc // prefix must be 5 total characters
//	string fileNoEXT = ParseFilePath(3, s_filename, ":", 0, 0)
//	variable incPOSITION = (itemsinlist(fileNoEXT, "_") - 1)
//	Variable inc = str2num(stringFromList(incPOSITION, fileNoEXT, "_"))
//	string Prefix = removelistitem((incPosition), fileNoEXT, "_")
//		
//	String FolderPrefix
//	Variable FolderInc; sscanf  ParseFilePath(0, s_filename, ":", 1, 1),  "%[A-Za-z_]%d", FolderPrefix, FolderInc
//	String FolderFolderPath = ParseFilePath(1, s_filename, ":", 1, 1)
//	string Path = ParseFilePath(1, s_filename, ":", 1, 0)// string Path = FolderFolderPath+FolderPrefix+num2str(FolderInc)//; print path
//	
//	//print "SLOW ?"
//	variable err = QuickLoadFITS(Path, filename)
//	//	if(err == 1)
//	//		KillPath/a/z
//	//		Abort "The folder name that contains the image must end with a number."
//	//	endif
//	SVAR SubRect = root:import:primary:SubRect
//	Variable xOffset = str2num(stringFromList(0, SubRect,","))
//	Variable yOffset = str2num(stringFromList(3, SubRect,","))
//	NVAR xBin = root:import:primary:Hbin
//	NVAR yBin = root:import:primary:Vbin
//	
//	SetScale/P x, (xoffset*0.507937), Xbin*0.507937, "um", root:import:primary:data  //0.253968254 is for a 63x objective and 16 um pixels
//	SetScale/P y, (Yoffset*0.507937), Ybin*0.507937, "um", root:import:primary:data //0.266666667 60X and 16 um
//	
//	display/k=1; appendimage root:import:primary:data; ModifyGraph width={Plan,1,bottom,left}
//	WMAppend3DImageSlider()
//	
//end

function displayMaxImages()

	string allImages = wavelist("*", ";", "MINCOLS:2")
	list2wave(allimages, "MaxImageList")
	wave/t MaxImageList
	//make/o/t/n=(numpnts(MaxImageList)) wndoNames
	variable inc
	for(inc = 0; inc <= numpnts(MaxImageList); inc += 1)
		string temp = MaximageList[inc]//; print temp
		string wndoName = temp+"wndo"//; print wndoname
		display/k=1; appendimage $temp
		ModifyGraph width={Plan,1,bottom,left}
		drawroishere()
	//	DoWindow/C $wndoName
	//	wndoNames[inc] = wndoname
	endfor
	killwaves MaxImageList
end

function NewUpdate(Image)
	wave Image

	
	string crntfldr = getdatafolder(0,Image)
	setdatafolder root:currentrois
		
	MakeListofROIs()
	wave/t every_ROI_list = Root:CurrentROIs:every_ROI_list
	wave/t every_bROI_list = Root:CurrentROIs:every_bROI_list	

	variable i	
	for(i=0; i<numpnts(every_bROI_list); i+=1)
		string CurrentROI = every_bROI_list[i]
		Raw(CurrentROI,Image)
	endfor
	
	AverageBackgrounds(Image)

	for(i=0; i<numpnts(every_ROI_list); i+=1)
		CurrentROI = every_ROI_list[i]
		Raw(CurrentROI,Image)
		SubtractBackground(CurrentROI)
		MakeDFF(CurrentROI)
	endfor

	
	MakeListofROIs()
	setdatafolder $crntfldr
//	legend/w=DeltaFOverF/C/N=text0/F=0
end

function DrawAllROIs(WindowTarget,Image)
	String WindowTarget
	wave image
	
	wave/t roi_list = root:CurrentROIs:ROI_List
	wave/t broi_list = root:CurrentROIs:bROI_List
	wave/t froi_list = root:CurrentROIs:fROI_List
	wave/t fbroi_list = root:CurrentROIs:fBROI_List
		
	variable i
	for(i=0; i<numpnts(froi_list); i+=1)
		string ROI = froi_list[i]
		variable ROInum = str2num(replacestring("ROI_", ROI, ""))
		AddFreehand2Window(ROInum,WindowTarget, "ROI")
//		print "HELLO!"
	endfor
	for(i=0; i<numpnts(fbroi_list); i+=1)
		ROI = fbroi_list[i]
		ROInum = str2num(replacestring("ROI_", ROI, ""))
		AddFreehand2Window(ROInum,WindowTarget, "BROI")
	endfor
	if(numpnts(roi_list) >0)
		DrawROIs()
	endif
	if(numpnts(broi_list) >0)
		DrawbROIs()
	endif	
end


function ManualSetDFFs()
	variable Bline_beg, Bline_stop
	prompt Bline_beg, "Delta F / F0 Baseline Start (sec)"
	prompt Bline_stop, "Delta F / F0 Baseline End (sec)"
	DoPrompt "DF/F0 Baseline", Bline_beg, Bline_stop
	
	if (V_Flag)
		return -1								// User canceled
	endif
	
	NVAR bline_start = root:currentROIs:bline_start
	NVAR bline_end = root:currentROIs:bline_end
	if(NVAR_exists(bline_start) ==0 )
		variable/g root:currentROIs:bline_start = 0
	endif
	if(NVAR_exists(bline_end) == 0 )
		variable/g root:currentROIs:bline_end = 0
	endif
	
	bline_start = Bline_beg
	bline_end = Bline_stop
	
	SVAR ImageName = Root:CurrentROIs:ImageName
	wave Image = $ImageName
	NewUpdate(Image)
	
	if(itemsinlist(wavelist("subtracted_*",";","")))
		ChangeDFFs(bline_start,bline_end)
	endif
end


function ChangeDFFs(bline0,bline1)
	variable bline0, bline1	//Time in sec
	
	if(itemsinlist(wavelist("subtracted_*",";","")) == 0)
		abort "No data.  Wrong Folder?"
	endif
	
	variable i
	for(i=0; i<itemsinlist(wavelist("subtracted_*",";","")); i+=1)
		string sub_target = stringfromlist(i,wavelist("subtracted_*",";",""))
		string dff_target = replacestring("subtracted", sub_target, "DFF")
		duplicate/o $sub_target w
		variable baseline = mean(w,bline0,bline1)	//mean(w,x2pnt(w,bline0),x2pnt(w,bline1))
		w-=baseline
		w/=baseline
		duplicate/o w $DFF_target
	endfor
end

Override Function/S MyCleanupFitsFolderName(nameIn)
	String nameIn
	
	return nameIn
End

function badAutoscale_2()

	print "new autoscale"
	getmarquee/z/K left, bottom//, top, right
//	print V_Left, V_Right, V_Bottom, V_Top
	string ImageName=ImageNameList("","")
	Imagename = Replacestring(";", Imagename,"") 
	wave Image = ImageNameToWaveRef("",ImageName)
	
	
	variable glayer = str2num(stringByKey("plane", imageInfo(S_marqueeWin, nameOfWave(Image), 0),"= "))
	imagestats/GS={V_Left, V_Right, V_Bottom, V_Top}/P=(glayer) Image
	ModifyImage $ImageName ctab= {V_min,V_max,}

end

function NewAutoscale()
	
	String info,vaxis,haxis
	String list= ImageNameList("",";")
	String imagePlot = StringFromList(0,list, ";")
	info=ImageInfo("",imagePlot,0)
	info = replacestring(" ", info, "")
	vaxis=StringByKey("YAXIS",info)
	haxis=StringByKey("XAXIS",info)
	variable plane=str2num(StringByKey("plane",info, "="))

	string ImageName=ImageNameList("","")
	Imagename = Replacestring(";", Imagename,"") 
	wave Image = ImageNameToWaveRef("",ImageName)
	
	getmarquee $haxis, $vaxis
	variable leftRow, rightRow, topColumn, bottomColumn
	leftrow = x2pnt(image, v_left)
	rightRow = x2pnt(image, v_right)
	topColumn = (v_top - DimOffset(image, 1))/DimDelta(image,1)
	bottomColumn = (v_bottom - DimOffset(image, 1))/DimDelta(image,1)

	//make sure right is bigger than left and bottom is bigger than bottom
	if( bottomColumn > topColumn)
		variable temp_bottom = v_bottom
		v_bottom = v_top
		v_top = temp_bottom
	endif
	if(leftRow > rightRow)
		variable temp_right = v_right
		v_right = v_left
		v_left = temp_right
	endif
	

	if(dimsize(image,2) >= 2)
		imagestats/m=1/GS={V_Left, V_Right, V_Bottom, V_Top}/P=(plane) Image
	else
		imagestats/m=1/GS={V_Left, V_Right, V_Bottom, V_Top} Image
	endif
	
	ModifyImage $ImageName ctab= {V_min,V_max,}

end