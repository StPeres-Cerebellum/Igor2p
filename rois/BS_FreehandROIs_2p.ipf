#pragma rtGlobals=1		// Use modern global access method.



Menu "GraphMarquee"
	"-"
	Submenu "ROIs"

		end
	end
end



function/s GenerateFreehandMask(s_marqueewin,Image)
	string s_marqueeWin
	wave Image
	string ImageFolder = GetWavesDataFolder(Image, 1 )

	variable Imagex = Dimsize(Image, 0); variable Imagey = Dimsize(Image, 1)

	//------------Draw the ROI on the image and convert it to pixels------------
	SetDrawLayer/W=$s_marqueewin userfront
	FreeROIPanel(s_marqueewin)
	GraphWaveDraw/f=3/o/w=$s_marqueewin
	wave W_xPoly0, W_yPoly0
	pauseforuser FreeROIwin, $s_marqueewin
	GraphNormal/w=$s_marqueewin
	W_xPoly0 /= dimdelta(Image,0)
	W_yPoly0 /= dimdelta(Image,1)
	W_xPoly0 = trunc(w_xPoly0)
	W_xpoly0 += 0.5
	W_yPoly0 = round(w_yPoly0)
	W_xPoly0 *= dimdelta(Image,0)
	W_yPoly0 *= dimdelta(Image,1)
	
	//------------Create Mask and fill it------------
	ImageBoundaryToMask width=Imagex, height=Imagey, xwave=W_xPoly0, ywave=W_ypoly0, scalingwave=image
	Wave M_RoiMAsk		
	ImageSeedFill seedP=0, seedQ=0, min=0, max=0, target=1, srcWave=M_ROIMask
	ImageSeedFill/B=0 seedP=0, seedQ=0, min=1, max=255, target=1, srcWave=M_seedFill
	removefromgraph/w=$s_marqueewin W_yPoly0
	
	NVAR/Z numrois=Root:CurrentROIs:numrois	
	if( NVAR_Exists(numrois) )
		numrois += 1
	else 
		variable/g Root:CurrentROIs:numrois = 1
		NVAR/Z numrois=Root:CurrentROIs:numrois
	endif
	string/g Root:CurrentROIs:CurrentROI = "ROI_"+num2str(numrois)
	return s_marqueewin
end

FUnction NameFreehand(s_marqueewin,numrois, RoiorBroi)
	string s_marqueewin, roiorbroi
	variable numrois
	
	
	string roi = "Root:CurrentROIs:"+RoiorBroi+"_"+num2str(numrois)
	string/g Root:CurrentROIs:CurrentROI = "ROI_"+num2str(numrois)
	String MaskName = "fMask_"+RoiorBroi+"_"+num2str(numrois)
	String xROIname = "Freehand_"+RoiorBroi+"_"+num2str(numrois)+"_x"
	String yROIname = "Freehand_"+RoiorBroi+"_"+num2str(numrois)+"_y"
	Wave M_ROIMask
	Duplicate/o M_SeedFill $MaskName 
	Duplicate/o W_xPoly0 $xROIname
	Duplicate/o W_yPoly0 $yROIname
	
	Duplicate/o W_yPoly0 $yROIname
	Duplicate/o W_yPoly0 $yROIname
	killwaves W_xPoly0 W_yPoly0
	
	
end

Function AddFreehand2Window(ROInum,WindowTarget, ROIorBROI)
	string WindowTarget, ROIorBROI
	variable ROInum
	
	SVAR/Z sigcolor = root:CurrentROIs:sigcolor
//	Wave/t All_ROI_List = root:currentROIs:All_ROI_List
//	variable NumROIs = numpnts(All_ROI_List)
	wave roicolors
	
	wave/t FreeROIs
	String ywave = "Root:CurrentROIs:Freehand_"+ROIorBROI+"_"+num2str(ROInum)+"_y"
	String xwave = "Root:CurrentROIs:Freehand_"+ROIorBROI+"_"+num2str(ROInum)+"_x"
	wave yROIWave = $ywave
	wave xROIWave = $xwave
		
	variable RoiBottom = Wavemin(yROIWave)
	variable ROITop = Wavemax(yROIWave)
	variable ycenter = round((ROITop + RoiBottom)/2)
	variable RoiLeft = Wavemin(xROIWave)
	variable RoiRight = Wavemax(xROIWave)
	variable xcenter = round((ROIRight + RoiLeft)/2)
	SetDrawLayer/W=$WindowTarget/K ProgFront
	SetDrawLayer/W=$WindowTarget userfront
	
	strswitch(ROIorBROI)
		case "ROI":	
			SVAR sigcolor = root:currentrois:sigcolor
			sigcolor =  "("+num2str(roicolors[(ROInum-1)*15][0])+", "+num2str(roicolors[(ROInum-1)*15][1])+", "+num2str(roicolors[(ROInum-1)*15][2])+")"
			String Figor1 = "SetDrawEnv/w="+WindowTarget+" xcoord= bottom,ycoord= left,linefgc="+SigColor+",fillpat= 0, linethick= 2.00"
			Execute Figor1
			drawpoly/ABS/w=$WindowTarget 0,0,1,1,xROIWave, yROIWave
			String Figor2 = "SetDrawEnv xcoord= bottom,ycoord= left, textrgb="+sigcolor+" ; drawtext "+num2str(xcenter)+","+num2str(ycenter)+", "+"\""+num2str(roinum)+"\""
			Execute Figor2
		break
		case "BROI":
			SetDrawEnv/w=$WindowTarget xcoord= bottom,ycoord= left,linefgc=(0,0,65280),fillpat= 0, linethick= 2.00
			drawpoly/ABS/w=$WindowTarget 0,0,1,1,xROIWave, yROIWave
			SetDrawEnv xcoord= bottom,ycoord= left, textrgb=(0,0,65280) 
			drawtext/w=$WindowTarget xcenter, ycenter,num2str(roinum)
		break
	endswitch
end


Function FreeROIPanel(ImageWinName)
	string ImageWinName
//	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1291,603,1555,644) /N=FreeROIwin
	Button done,pos={0,0},size={50,20},proc=FreeButton,title="done"
	Button done,fSize=11
	AutoPositionWindow/E/M=1/R=$ImageWinName
End


Function FreeButton( ctrlname ) : ButtonControl
	String ctrlName
	
	Killwindow FreeROIwin
	return 0
End // MainTabButton


function FreeRaw(CurrentROI,Image,ROIorBROI)
	variable CurrentROI
	string ROIorBROI
	wave Image
	
	
	NVAR KCT = root:currentrois:KCT	
	string ROIavg = "root:CurrentROIs:RAW_" + ROIorBROI+"_"+num2str(CurrentROI)
	string MaskName = "Mask_"+RoiorBroi+"_"+num2str(CurrentROI)
	wave mask = $MaskName
	imagestats/M=1/BEAM/R=Mask Image
	wave W_ISBeamAvg
	duplicate/o W_ISBeamAvg $ROIavg
	SetScale/P x 0,KCT,"", $ROIavg
	SVAR RAWWaves = root:currentrois:RAWWaves
	RAWWaves = wavelist("RAW_*",";","")
end

function AverageBackgrounds(Image)
	wave image
	
	Make/o/n=(dimsize(image,2)) BackgroundAverage = 0  //1000 if using brandon's camera !!!
	NVAR KCT = root:currentrois:KCT
	wave/t ALLbmasks = Every_broi_list
	variable i
	for(i=0;i<numpnts(ALLBMasks); i+=1)
		string bmaskNAME = wavelist("*mask*"+ALLbMasks[i], "", "")
		wave bmask = $bmaskNAME
		imagestats/M=1/BEAM/R=bmask Image
		wave W_ISBeamAvg
		BackgroundAverage +=  W_ISBeamAvg
	endfor
//	BackgroundAverage /= i
	BackgroundAverage = BackgroundAverage != 0 ? BackgroundAverage / i : BackgroundAverage  //1000 if brandon's camera !!!
	BackgroundAverage = BackgroundAverage == 0 ? 0 : BackgroundAverage  //1000 if brandon's camera !!!
	SetScale/P x 0,KCT,"", ::CurrentROIs:BackgroundAverage
end



function WhereIsThisImage()
	getmarquee/K
	string ImageName=ImageNameList(S_MarqueeWin, ";")
	Imagename = Replacestring(";", Imagename,"") 
	wave Image = ImageNameToWaveRef(S_MarqueeWin,ImageName)
	string/g Root:CurrentROIs:ImageName = GetWavesDataFolder(Image, 4)
	SVAR ImageName2 = RooT:CurrentRois:ImageName
	print ImageName2
end

function CheckROIs()
	string crntfldr = getdatafolder(1)
	setdatafolder Root:CurrentROIs
	SVAR ImageName = Root:CurrentROIs:ImageName
	display/k=1; ModifyGraph width={Aspect,1}
	appendimage $ImageName
	Wave/t Masks = BSwaveofwavenames("*Mask_*ROI*")
	variable i
	for(i=0; i<(numpnts(Masks)); i+=1)
		string maskwave = Masks[i]
		appendimage $MaskWave
		ModifyImage $MaskWave minRGB=(65280,65280,16384),maxRGB=NaN
		ModifyImage $MaskWave ctab= {1,1,Grays,0}
	endfor
	killwaves w
	setdatafolder $CrntFldr
end
