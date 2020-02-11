#pragma rtGlobals=1		// Use modern global access method.
#include <FITS Loader>

function BatchAnalyzeAllStacks(OnlyOneFolder)
	Variable OnlyOneFolder
	
	variable refnum
	string file, fileFilters = "Fits Images (*.fits):.fits;"		//restricts files to .fits
	open/z=2/r/f=fileFilters refnum	//this open does nothing...it's just for getting the filename info below
	if( v_flag == -1 )
		return v_flag
	endif
	
	String FullPath = ParseFilePath(5, s_filename, "*", 1, 0)//; print "FullPath =", FullPath
	string extension = "."+ParseFilePath(4, FullPath, "\\", 0, 0)//; Print "extension = ", extension
	string filename = parsefilepath(3, FullPath, "\\", 1, 0)//; print "filename = ", filename
//	string prefix
//	Variable inc; sscanf filename, "%[A-Za-z_]%d", prefix, inc // prefix must be 5 total characters
	variable incPOSITION = (itemsinlist(filename, "_") - 1)
	Variable inc = str2num(stringFromList(incPOSITION, filename, "_"))//; print "inc = ", inc
	string Prefix = removelistitem((incPosition), filename, "_")//; print "prefix = ", prefix
		
	String FolderPrefix
	Variable FolderInc; sscanf  ParseFilePath(0, FullPath, "\\", 1, 1),  "%[A-Za-z_]%d", FolderPrefix, FolderInc
	String FolderFolderPath = ParseFilePath(1, FullPath, "\\", 1, 1)//; print "Containing Folder =", folderfolderpath
	string Path = FolderFolderPath+FolderPrefix+num2str(FolderInc)//; print path
//	print prefix, inc, extension
	
		
	for(FolderInc = FolderInc; FolderInc < 100; FolderInc+= 1)
		Path = FolderFolderPath+FolderPrefix+num2str(FolderInc)
		//print path
		newpath/z/o/q TempPath path//; print v_flag
		if(v_flag == 0)
			//Print FolderPrefix + num2str(Folderinc)							
			String ImageFolder = FolderPrefix + num2str(FolderInc)
			NMFolderNew( ImageFolder )
			string NeMFolderName = getdatafolder (1)
			make/n=(0) ImageTimer
			wave ImageTimer
			//print path
			//variable incstart = inc, 
			
			variable NumofFIles = 0
	
		for(inc = 0; inc < 1000; inc += 1)
			Path = FolderFolderPath+FolderPrefix+num2str(FolderInc)
			filename = prefix+num2str(inc)+extension//; print filename
		
			newpath/z/q/o path1, path//;  print path
				if(V_Flag == 1 )
					//print numoffiles
					return 0
				endif
			Open/R/P=path1/z=1 refnum as filename
				if( V_Flag != 0 )
					NumofFiles -= 1
				endif
			NumofFiles += 1
		endfor
			variable TimerStep = 0
			variable err
						string thisTrial = FolderPrefix+num2str(folderinc)
						string ProgOPEN2 = "progresswindow open=progress, text = " + "\""+thisTrial+"\""  
						string ProgClose = "progresswindow close"
						execute ProgOPEN2
			
			for(inc = 0; inc < 1000; inc += 1)
						variable progfrac2 = Inc/NumofFiles 										//more progress window bullshit
						String ProgUpdate2 = "progresswindow frac="+num2str(progFrac2)
						execute ProgUpdate2
			
				filename = prefix+num2str(inc)+extension
				//print filename
				string windowname = prefix+num2str(inc)+"wndo"
				string dataname = prefix+num2str(inc)
				string firstimage = "root:"+dataname
				//print filename
				err  = QuickLoadFITS(Path, filename)
				SVAR SubRect = root:import:primary:SubRect
				Variable xOffset = str2num(stringFromList(0, SubRect,","))
				Variable yOffset =  str2num(stringFromList(3, SubRect,","))
				NVAR xBin = root:import:primary:Hbin
				NVAR yBin = root:import:primary:Vbin
				SetScale/P x, (xoffset*0.507937), Xbin*0.507937, "um", root:import:primary:data  //0.253968254 is for a 63x objective and 16 um pixels
				SetScale/P y, (Yoffset*0.507937), Ybin*0.507937, "um", root:import:primary:data //0.266666667 60X and 16 um
					
				if (err == 0)
					setdatafolder root:import //; print getdatafolder(1)
					wave image = root:import:primary:data
					display; appendimage image; ModifyGraph width={Plan,1,bottom,left}; DoWindow/C $windowname
					
					
					//drawroisHere()
					Newupdate(image)
					TakeMaxandFirstImage(image, inc, NeMFolderName, prefix)	
						
					moveROIanalyses(inc, NeMFolderName)
					redimension/n=(Timerstep + 1) ImageTimer
					ImageTimer[timerstep] = gettime(); timerstep += 1
				
					DoWindow/K $windowname
					//duplicate/r=[][][0] root:import:primary:data $firstimage; display; appendimage $firstimage//; ModifyGraph width={Plan,1,bottom,left}
					//drawroishere()
		
					//redimension/n=(-1,-1, 1)  root:import:primary:data
					//movewave root:import:Primary:data, root:$dataname		// change "root:" to copy elsewhere
					//killdatafolder root:import
			
				elseif (err == -1)
					execute ProgClose
					return 0
				endif
		//	print inc
			endfor
			
			If(OnlyOneFolder == 1)
				break
			endif
		endif
	execute ProgClose
	print folderinc
	endfor
	execute ProgClose
	
end

Function QuickLoadFITS(path, filename)
	String path, filename
	
	newpath/z/q/o path1, path
	if(V_Flag == 1 )
		return 0
	endif
	
	Variable refnum, err
	//pathinfo path1
	Open/R/P=path1/z=1 refnum as filename
	if( V_Flag != 0 )
	//	print "load error = ", err	
		return 1
	endif
	//print refnum, s_filename, filename

	LoadOneFITS(refnum, "root:import", 0,0,0,0,1,1e10,1e10)	// From Igor
	Close/a
	return err
end


 function moveROIanalyses(inc, NeMFolderName)
	variable inc
	string NeMFolderName
	
	svar numrois = root:currentrois:numrois
	wave/t every_roi_list = root:currentrois:every_roi_list; //print numpnts(roi_list)
	wave/t every_broi_list = root:currentrois:every_broi_list; //print numpnts(broi_list)
	//MakeListofROIs()
	variable i
		
		for(i = 0; i <= numpnts(every_roi_list); i+= 1)
			string RAWsourceROIname = "RAW_"+every_roi_list[i]
			string RAWsourceROIpath = "root:currentrois:"+RAWsourceROIname
			string RAWcopiedROI = NeMFolderName+RAWsourceROIname + "__"+num2str(inc) // change "NeMFolderName" to copy elsewhere
			//print RAWsourceROIname, RAWsourceROIpath, RAWcopiedROI
			duplicate/o $RAWsourceROIpath, $RAWcopiedROI
			
			
			
			string SUBsourceROIname = "subtracted_"+every_roi_list[i]
			string SUBsourceROIpath = "root:currentrois:"+SUBsourceROIname
			string SUBcopiedROI = NeMFolderName+SUBsourceROIname + "__"+num2str(inc) // change "NeMFolderName:" to copy elsewhere
			duplicate/o $SUBsourceROIpath, $SUBcopiedROI			

			string DFFsourceROIname = "DFF_"+every_roi_list[i]
			string DFFsourceROIpath = "root:currentrois:"+DFFsourceROIname
			string DFFcopiedROI = NeMFolderName+DFFsourceROIname + "__"+num2str(inc) // change "NeMFolderName" to copy elsewhere
			duplicate/o $DFFsourceROIpath, $DFFcopiedROI			
						
		endfor
		
		for(i = 0; i < numpnts(every_broi_list); i+= 1)
			string BRAWsourceROIname = "BRAW_"+every_broi_list[i]
			string BRAWsourceROIpath = "root:currentrois:"+BRAWsourceROIname
			string BRAWcopiedROI = NeMFolderName+BRAWsourceROIname + "__"+num2str(inc) // change "NeMFolderName" to copy elsewhere
			duplicate/o $BRAWsourceROIpath, $BRAWcopiedROI

						
		endfor

end

static function gettime()

	variable v1,v2,v3, timeX
	
	SVAR timer = root:import:Primary:DATE
	sscanf timer, "%*10sT%d%*[:]%d%*[:]%d", v1, v2, v3
	
	timeX = (v1*60*60+v2*60+v3)
	return timex
end

function GETDFFs()
	
	NMPrefixSelect( "Raw_" )
//	ChanFilter( 0 , "binomial" , 2 )
//	StatsWin( 0 , 0.02 , 0.03 , "Max" )
//	StatsWin( 1 , 0.009 , 0.018 , "Avg" )
//	StatsAllWaves( -1 , 0 , 0 )
	InsertSkippedIMages()
	
	string Trial_num = getdatafolder(0)
	string F_name = "F_"+Trial_num
	String Peak_name = "Max_"+Trial_num
	wave peaks = $peak_name
	wave Fs = $F_name
	string DFFName = Trial_num+"_DFF"
	string NrmlzdDFFName = Trial_num+"_nrmlzd_DFF"
	string NrmlzdFsName = F_name+"_nrmlzd"
	peaks-= 1000
	Fs -=1000
	duplicate peaks dff; dff -= Fs; dff /= Fs
	wave dff
	duplicate dff dff_nrmlzd; wavestats/q/r=(-10,-1) dff_nrmlzd; dff_nrmlzd /= v_avg
	duplicate Fs F_nrmlzd; wavestats/q/r=(-10,-1) F_nrmlzd; F_nrmlzd /= v_avg
	
	rename dff_nrmlzd $NrmlzdDFFName
	rename F_nrmlzd $NrmlzdFsName
	rename dff $dffname
	
	
end

function moveDFFs(start,stop)
	variable start, stop
	
	variable inc
	for(inc = start; inc <= stop; inc += 1)
//		string doit = "duplicate root:trial"+num2str(inc)+":trial"+num2str(inc)+"_nrmlzd_DFF root:trial"+num2str(inc)+"_nrmlzd_DFF"
		string doit = "duplicate root:trial"+num2str(inc)+":trial"+num2str(inc)+"_DFF root:trial"+num2str(inc)+"_DFF"
		execute doit
	endfor
end

function moveBlines(start,stop)
	variable start, stop
	
	variable inc
	for(inc = 1; inc <= 10; inc += 1)
		string doit = "duplicate root:trial"+num2str(inc)+":F_trial"+num2str(inc)+"_nrmlzd root:F_trial"+num2str(inc)+"_nrmlzd"
		execute doit
	endfor
end



static function NumberofFiles(inc, FolderFolderPath, prefix, FolderPrefix, Folderinc, filename, extension, path)
	string FolderFolderPath, prefix, FolderPrefix, filename, extension, path
	variable inc, Folderinc
	
				
	variable NumofFIles = 0
	for(inc = 0; inc < 1000; inc += 1)
//		string Path = FolderFolderPath+FolderPrefix+num2str(FolderInc)
		filename = prefix+num2str(inc)+extension
		
		newpath/z/q/o path1, path
			if(V_Flag == 1 )
				return 0
			endif
		Open/R/P=path1/z=1 refnum as filename
			if( V_Flag != 0 )
				NumofFiles -= 1
			endif
	NumofFiles += 1
	endfor
	return NumofFiles
end


static Function TakeMaxandFirstImage(image, inc, NemFoldername, prefix)
	wave image
	variable inc
	string NemFoldername, prefix
	
//	print NEMFolderName, prefix
	
	string MaxImageName = NemFoldername + prefix+"_"+num2str(inc)
	wavestats/q image
	//duplicate/o/R=[][][0] image firstImage
	duplicate/o/R=[][][v_maxLayerLoc] image $MaxImageName
	
end

