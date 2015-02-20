#pragma rtGlobals=1		// Use modern global access method.

function DisplayList(List)
	wave/t list
	
	string target = list[0]
	display $target	

	variable i
	for(i=1; i<numpnts(list); i+=1)
		target = list[i]
		appendtograph $target
	endfor
end


function/WAVE AvgListOfWaves(w)
	wave/t w

	string newname = NameOfWave(w) + "_avg"	
	If(numpnts(w)>0)
		string WaveID = w[0]
		wave firstwave = $WaveID
		duplicate/o firstwave avg; avg = 0
		variable i
		for(i = 0; i < numpnts(w); i += 1)
			WaveID = w[i]
			Wave PlusWave = $WaveID
			Avg += PlusWave
		endfor
		Avg /= (i)
	ElseIf(numpnts(w)==0)
		make/n=0 avg
	Endif
	duplicate/o avg $newname; killwaves avg
	newname = GetWavesDataFolder($newname, 2)
	Return $newname
end

function/WAVE SDevListOfWaves(w)
	wave/t w
	
	string newname = NameOfWave(w) + "_sdev"
	If(numpnts(w)>0)
		wave avg = AvgListOfWaves(w)
		string WaveID = w[0]
		wave firstwave = $WaveID
		duplicate/o avg SDEV
		SDEV = 0
		variable i
			for(i = 0; i < numpnts(w); i += 1)
				WaveID = w[i]
				Wave PlusWave = $WaveID//; print waveid
				SDEV += (PlusWave - Avg)^2
			endfor
		SDEV /= (i-1)//; print i-1
		SDEV = sqrt(SDEV)
	ElseIf(numpnts(w)==0)
		make/n=0 SDEV
	EndIf
	duplicate/o sdev $newname; killwaves sdev
	newname = GetWavesDataFolder($newname, 2)
	Return $newname
end

Function/S BSWave2List(w)
	wave/t w
	
	variable i; string NameList =""
	for( i = 0; i <= numpnts(w); i += 1)
		NameList = AddListItem(w[i], NameList, " ", 0)
	endfor
//	 execute "edit "+NameList
	 return NameList
end

Function/Wave BSList2Wave(BSlist)  //returns BSWaveFromList
	String BSList
	variable n = ItemsinList(BSlist)
	Make/O/T/N=(n) BSWaveFromList = StringFromList(p,BSList)
	Return BSWaveFromList
end

Function/Wave BSWaveOfWaveNames(Matchstr)
	string MatchStr
	string list = wavelist(MatchStr, ";", "")

	wave/t BSWaveFromList = BSList2Wave(List)
	Duplicate/O BSWaveFromList w
	Killwaves BSWaveFromList
	sort/a w, w
	string NewName = "waves_"+MatchStr
	killwaves/z $NewName
	duplicate/o w $NewName
	Return  $NewName
end


function/ WAVE binPixels()
	variable hbin, vbin
	
	prompt hbin, "Horizontal Binning (#pixels)"
	prompt vbin, "Vertical Binning (#pixels)"  
	DoPrompt "bins", hbin, vbin
	wave none
	if (V_Flag)
		return none								// User canceled
	endif
	
	getmarquee/K
	string ImageName=ImageNameList(S_MarqueeWin, ";")
	Imagename = Replacestring(";", Imagename,"") 
	wave Image = ImageNameToWaveRef(S_MarqueeWin,ImageName)	
	
	make/o/n=((dimsize(image,0)/hbin), (dimsize(image,1)/vbin),(dimsize(image, 2))) binned_image
	SetScale/P x (dimoffset(image,0)),(dimdelta(image,0)*hbin),"", binned_image;DelayUpdate
	SetScale/P y (dimoffset(image,1)),(dimdelta(image,1)*hbin),"", binned_image
	
	variable BinImgColumn, BinImgFrame, BinImgRow
	
	variable yPixelOfImg = 0
	variable xPixelOfImg = 0
	for(BinImgRow = 0; BinImgRow < dimsize(binned_image,1); BinImgRow += 1)
		
		for(BinImgColumn = 0; BinImgColumn < dimsize(binned_image,0) ; BinImgColumn += 1)
			imagestats/BEAM/G={xPixelOfImg,(xPixelOfImg + hbin-1), yPixelOfImg, (yPixelOfImg+ vbin-1)} image
			wave W_ISBeamAvg
			
				for(BinImgFrame = 0 ; BinImgFrame < dimsize(binned_image,2); BinImgFrame += 1)
					binned_image[BinImgColumn][BinImgRow][BinImgFrame] = W_ISBeamAvg[BinImgFrame]
				endfor
			
			xPixelOfImg += (hbin)
		endfor
		xPixelOfImg = 0
		yPixelOfImg += (vbin)
	
	endfor 
	print xPixelOfImg, yPixelOfImg
	display/k=1; appendimage binned_image
	ModifyGraph width={Aspect,1}
	string newname = (nameofwave(image))+"_binned" + num2str(hbin)+"X"+num2str(vbin)
	rename binned_image $newname
	return $newname
end

function CutNMRasters(rasterx, rastery,newname)
	wave rasterx, rastery
	string newname
	
	variable i, start = 0
	for(i=wavemin(rastery); i <= wavemax(rastery); i+=1)
		findlevel/p/q rastery, i+1
		if(i==wavemax(rastery))
			wavestats/q rastery
			v_levelx = V_endRow
		endif
		string sweepnum = newname+"_"+num2str(i)
		string sweepnumy = newname+"y_"+num2str(i)
		print sweepnum, start, v_levelx-2
		duplicate/o/r=[start, (v_levelX-2)] rasterx $sweepnum
		duplicate/o $sweepnum temp; temp = 0
		duplicate/o temp $sweepnumy
		killwaves temp
		start= v_levelx
	endfor
end

function BetterCutNMRasters(rasterx, rastery,newname)
	wave rasterx, rastery
	string newname
	
	duplicate/o rasterx tempRaster
	tempRaster = rastery >= 0 ? tempRaster : 123456

	variable i
	for(i=0; i< numpnts(rasterx); i+=1)
		variable rasterNum = rastery[i]
		string sweepnum = newname+"_"+num2str(rasterNum)
		string sweepnumy = newname+"y_"+num2str(rasterNum)
		findvalue/s=(i+1) /v=123456 tempraster
		print sweepnum, i,v_value-1
		duplicate/o/r=[i, (v_value-1)] rasterx $sweepnum
		duplicate/o $sweepnum $sweepnumy
		wave yraster = $sweepnumy
		yraster = 1
		
		i = v_value

		if(i>numpnts(tempraster))
			break
		endif
	endfor

end

function/wave TakeEveryX(Input, EveryX, start)
	wave Input
	Variable EveryX, start
	string Name = Nameofwave(input)+"_"+num2str(EveryX)+"at"+num2str(start)
	
	duplicate/o Input OutputWave
	outputwave = Input[(p*EveryX)+((EveryX-1)*start)]
	redimension/n=((numpnts(Input))/EveryX) outputwave
	duplicate/o outputwave $Name
	Killwaves/z outputwave
	print name
	return $Name
end

function/wave TakeEveryXTEXT(Input, EveryX, start)
	wave/t Input
	Variable EveryX, start
	string Name = Nameofwave(input)+"_"+num2str(EveryX)+"at"+num2str(start)

	make/n=(numpnts(input))/t OutputWave = Input[(p*EveryX)+((EveryX-1)*start)]
	redimension/n=((numpnts(Input))/EveryX) outputwave
	duplicate/o outputwave $Name
	Killwaves/z outputwave
	print name
	return $Name
end

function/WAVE OrganizeWaveNames(prefix)
	string prefix
//	NVAR numofROIS = root:CurrentROIs:numrois
	string tempprefix = prefix+num2str(1)+"_*"//; print tempprefix
	variable numofSWEEPS = itemsinlist(wavelist(tempprefix,";",""))//; print numofsweeps
	make/t/o/n=((NumofSweeps),(10)) Organized
	tempprefix = prefix+num2str(10)+"_*"
	wave/t WaveNames = BSList2wave((wavelist(tempprefix,";","")))
	sort/a wavenames, wavenames
	Organized[][10]=WaveNames[p]
	variable i
		for(i=(9); i>0; i-=1)
			 tempprefix = prefix+num2str(i)+"_*"
			 wave/t WaveNames2 = BSList2wave((wavelist(tempprefix,";","")))
			 sort/a wavenames2, wavenames2
			Organized[][i-1] = WaveNames2[p]
		endfor
//	string NewName = prefix+"Names"
//	rename allwaves
	return Organized  //wave where wavenames are organized
end


function DisplayROIs(WhichROIs,Organized)
	String WhichROIs //"list of rois to display seperated by and ending with a ";"
	wave/t Organized //wave where wavenames are organized
		variable i, j
		for(j=dimsize(Organized,0);j>0;j-=1)
			display $organized[j-1][(str2num(stringfromlist((itemsinlist(WhichROIs)-1),WhichROIs)))-1]
//			print j-1
			for(i=(itemsinlist(WhichROIs))-1; i>0; i-=1)
				variable roinum = (str2num(stringfromlist(i-1,WhichROIs)))-1//; print "           ", roinum
				appendtograph $Organized[j-1][roinum]
				ModifyGraph mode=7,hbFill=4,rgb($Organized[j-1][roinum])=(0,0,52224)
				wave target = $Organized[j-1][roinum]
			endfor
		endfor
end

function OffsetIdeals(WhichRois,Organized)
	String WhichROIs //"list of rois to display seperated by and ending with a ";"
	wave/t Organized  //wave where wavenames are organized
	variable i, j
	for(i=(itemsinlist(WhichROIs)); i>0; i-=1)
		variable roinum = (str2num(stringfromlist(i-1,WhichROIs)))-1//; print "   ", roinum
		for(j=dimsize(Organized,0);j>0;j-=1)
//			print j
			wave target = $organized[j-1][roinum]
			target *= (roinum+1)
		endfor
	endfor
end

function CorrelateIdeals(ROIA,ROIB,Organized)
	Variable ROIA, ROIB //two rois to correlate
	wave/t Organized  //wave where wavenames are organized
	variable i, j
	for(j=dimsize(Organized,0);j>0;j-=1)
//			print j
		wave TargetA = $organized[j-1][ROIA-1]
		wave TargetB = $organized[j-1][ROIB-1]
		Print "Correlation between ", nameofwave(TargetA), " and ", nameofwave(TargetB)
		string CorrWaveName = "Corr"+nameofwave(Organized)+"_"+num2str(ROIA)+"_and_"+num2str(ROIB)+"_sweep_"+num2str(j)
//		print CorrWaveName
		Duplicate/O TargetA,$CorrWaveName
		Correlate/NODC TargetB, $CorrWaveName
		Display $CorrWaveName
	endfor
end

function TransitsOnly(input, plusminus)
	wave input
	variable plusminus
	
//	string transitname = "transits_"+nameofwave(input)
//	wave transitswave = $transitname
	duplicate/o ideal_DFF_ROI_1__1 newtransit
	newtransit = 0
	
	variable i
	for(i=0; i < (numpnts(input)); i +=1)
		variable transit = input[i]
		NewTransit[(transit-plusminus),(transit+plusminus)] = 1
	endfor
	string newname = "transVt_"+nameofwave(input)
	killwaves/z $newname
	rename newtransit $newname
end

function LotsofTransitsOnly(WhichROIs,organized, PlusMinus)
	wave/t organized
	string WhichROIs
	variable PlusMinus
	
	variable i,j
	for(i=(itemsinlist(WhichROIs)); i>0; i-=1)
		variable roinum = (str2num(stringfromlist(i-1,WhichROIs)))-1//; print "   ", roinum
		for(j=dimsize(Organized,0);j>0;j-=1)
//			print j
			wave target = $organized[j-1][roinum]
			TransitsOnly(target, plusminus)
		endfor
	endfor

end

function/Wave AverageEveryOther(prefix, EvenOrOdd)
	string prefix // make sure to add wildcards "*"
	variable EvenOrOdd // 1 for odd 2 for even
	
	evenorodd -= 1
	wave w = BSWaveOfWaveNames(prefix)
	wave w2 =TakeEveryXTEXT(w, 2, EvenOrOdd)
	wave output = AvgListOfWaves(w2)
	
	display output
	if(EvenorOdd == 0)
		string name = "odd_"+prefix
	elseif(EvenorOdd == 1)
		name = "even_"+prefix
	endif
	duplicate/o output $name
	killwaves w, output
	edit w2
end

function DoSomethingToPrefixWaves(prefix)
	string prefix // use wildcards *
	string list = wavelist(prefix,";","")
	wave/t listwave = BSList2wave(list)
	
	variable i
	for(i=0; i <numpnts(listwave); i+=1)
		string target = listwave[i]
		wave targetwave = $target
		string newname = replacestring("sweep", nameofwave(targetwave), "freq")
		rename targetwave $newname
//		string newname = "root:states:"+nameofwave(targetwave)//  Put what you want to do here.  (e.g. display targetwave)
//		duplicate targetwave $newname//  Put what you want to do here.  (e.g. display targetwave)

	endfor
end

function/wave FirstImages2Stack(prefix)
	string prefix
	
	wave/t FirstImageNames = BSWaveOfWaveNames(prefix)
	string NewName = "FirstImageStack_"+Prefix
	
	duplicate/o $FirstImageNames[0] FirstImageStack
	redimension/n=(-1,-1,(numpnts(FirstImageNames))) FirstImageStack
	
	variable i
	for(i=1; i<(numpnts(FirstImageNames)); i+=1)
		wave target = $FirstImageNames[i]
		FirstImageStack[][][i] = target[p][q][0]
	endfor
	
	killwaves FirstImageNames
	rename FirstImageStack $NewName	
	return $NewName

end

function/wave WF_Waves(prefix)
	string prefix //add wildcards
	wave/t NamesWave = BSWaveOfWaveNames(prefix)
	wave Target = $Nameswave[0]
	String NewName = "WF_"+prefix
	
	make/o/n=((numpnts(Target)),(numpnts(NamesWave))) WF
	
	variable i
	for(i=0;i<numpnts(NamesWave);i+=1)
		Wave Target = $NamesWave[i]
		wf[][i] = Target[p]
	endfor
	Killwaves $NewName
	rename wf $NewName
	return $NewName
end

function/wave removeartifacts(target)
	wave target
	
	duplicate/o target w
	
	variable i
	for(i=1500; i<3405;i+=100)
		w[i,(i+5)] = nan
	endfor
	
	return w
end


function/wave SEMofMatrixRows(matrix,plane)
	wave Matrix
	variable plane
	
	matrixop/o w_avg = (sumrows(Matrix[][][plane]) / numcols(Matrix[][][plane]))
	
	duplicate/o/r=[][][plane] Matrix var	//pain in the ass for making SEMs -- consider using imagestats in a For...
	var[][] -= w_avg[p]
	var = var^2
	matrixop/o sem = (sumrows(var) / (numcols(var)-1))
	sem = sqrt(sem)/(sqrt(dimsize(matrix,1)))

	return sem

end


function/wave RemoveStimArtifacts(input, stimStart, StimFreq,TrainDuration,StimWidth)
	wave input
	variable stimStart, StimFreq,TrainDuration, StimWidth	//stimwidth is usually 0.001 sec
	duplicate/o input cleaned
	
	variable i
	for(i=stimstart;i<(stimstart+TrainDuration);i+=(1/stimFreq))
		cleaned[(x2pnt(cleaned,i)),(x2pnt(cleaned,(i+stimwidth)))] = nan
	endfor
	
	return cleaned
	
end

function TempofWave(input)
	wave input
	string temp = note(input)[strsearch(note(input),"Temperature:", 0), 600]
	
	variable v1
	sscanf temp, "Temperature: %f", v1
	
	return v1
end

function GetAllTemps(Prefix)
	string Prefix
	Prefix += "*"
	
	wave/t NameW = BSWaveOfWaveNames(Prefix)
	variable i
	
	Make/o/n=(numpnts(NameW)) Temps
	
	for(i=0;i<(numpnts(NameW));i+=1)
		String inputS = NameW[i]
		wave input = $inputS
		variable temp = TempofWave(input)//; print temp
		Temps[i] = temp
		setdimlabel 0,i,$inputS,temps
	endfor
	edit/k=1 temps.l temps
	wavestats/q temps; print v_avg, "+-", v_sem 
end

Function DisplayPlaneAsTraces(Plane, Matrix)
	variable Plane
	wave Matrix
	
	display Matrix[][0][plane]
	variable i
	for(i=1; i<=(dimsize(Matrix,1)); i+=1)
		appendtograph Matrix[][i][plane]
	endfor

end

function RenameEveryX(OldPrefix, NewPrefix, EveryX, start)	//changes the prefix in a list of wavenames
	string OldPrefix, NewPrefix
	variable everyX, start
	
	make/o/t/n=(ItemsInList(WaveList(OldPrefix+"*",";",""))) input = stringfromlist(p, WaveList(OldPrefix+"*",";",""))
	wave/t WavesToChange = TakeEveryXTEXT(Input, EveryX, start)
	
	variable i
	for(i=0; i<numpnts(WavesToChange);i+=1)
		wave target = $WavesToChange[i]
		string NewName = replacestring(OldPrefix, nameofwave(target), NewPrefix)
		rename target $NewName
	endfor
	
end

function SplitHEKAChannels(Prefix)
	string Prefix
	string ImonOrVmon = "imon"
	make/o/t/n=(ItemsInList(WaveList(Prefix+"*",";",""))) input = stringfromlist(p, WaveList(Prefix+"*",";",""))
	
	String Look4A = "*_1_*-1";	String Look4B = "*_2_*-2";	String Look4C = "*_3_*-3";	String Look4D = "*_4_*-4"
	
	variable i
	for(i=0; i<numpnts(input);i+=1)
		string oldname = input[i]
		
		if(StringMatch(oldname, Look4A))
			string NewName = replacestring("_1_"+ImonOrVmon+"-1", oldname, "")
			NewName = replacestring(Prefix, NewName, Prefix+"A")
		elseif(StringMatch(oldname, Look4B))
			NewName = replacestring("_2_"+ImonOrVmon+"-2", oldname, "")
			NewName = replacestring(Prefix, NewName, Prefix+"B")		
		elseif(StringMatch(oldname, Look4C))
			NewName = replacestring("_3_"+ImonOrVmon+"-3", oldname, "")
			NewName = replacestring(Prefix, NewName, Prefix+"C")			
		elseif(StringMatch(oldname, Look4D))
			NewName = replacestring("_4_"+ImonOrVmon+"-4", oldname, "")
			NewName = replacestring(Prefix, NewName, Prefix+"D")	
		endif
		
	rename $oldname $NewName
	endfor
		
end

function/wave CountTransitions(matrix)
	wave matrix
	
	wave matrix
	make/o/n=(dimsize(matrix,1)) output = nan
	variable i
	for(i=0; i<dimsize(matrix,1); i+=1)
//		duplicate/o/r=[][i][cellnum+2] smoothedmatrix levelcounter
		duplicate/o/r=[][i] matrix levelcounter
		findlevels/q levelcounter, 0.5
		output[i] = round(v_levelsfound)
	endfor
	
	
	return output
end

function/wave waves2Matrix(prefix)	//make sure all waves with the prefix are same length
	string prefix
	
	string PrefixList = (wavelist(prefix+"*", ";", ""))
	make/o/n=(dimsize($StringFromList(0,PrefixList),0),(itemsInList(PrefixList))) matrix
	
	variable i
	for(i=0; i<itemsInList(PrefixList); i+=1)
		wave target = $StringFromList(i,PrefixList)
		matrix[][i] = target[p]
		setdimlabel 1, i, $StringFromList(i,PrefixList), matrix
	endfor
	
	return matrix
end

function DisplayStatesAndRasters(raster_prefix, states_prefix)
	string raster_prefix, states_prefix	//remember to include underscores
	
	print itemsinlist(wavelist(raster_prefix+"*",";","")), itemsinlist(wavelist(states_prefix+"*",";",""))
	if(itemsinlist(wavelist(raster_prefix+"*",";","")) != itemsinlist(wavelist(states_prefix+"*",";","")))
		print "Different Numbr of Rasters and States"
		return 0
	endif
	
	variable i
	for(i=0; i<itemsinlist(wavelist(raster_prefix+"*",";",""));i+=1)
		wave raster = $StringFromList(i, wavelist(raster_prefix+"*",";",""))
		wave rastery = $StringFromList(i, wavelist("rastery_*",";",""))
		wave state = $StringFromList(i, wavelist(states_prefix+"*",";",""))
		display/k=1 rastery vs raster; appendtograph state
		ModifyGraph mode($StringFromList(i, wavelist("rastery_*",";","")))=3,marker($StringFromList(i, wavelist("rastery_*",";","")))=10,rgb($StringFromList(i, wavelist("rastery_*",";","")))=(0,0,0)
	endfor
end

function/wave FindTransitionsFromStates(states_prefix)
	string states_prefix
	
	make/n=(itemsinlist(wavelist(states_prefix+"*",";",""))) StateTransitions
	variable i

	for(i=0; i<itemsinlist(wavelist(states_prefix+"*",";",""));i+=1)
		wave state = $StringFromList(i, wavelist(states_prefix+"*",";",""))
		Findlevels/Q state, 0.5
		StateTransitions[i] = V_LevelsFound
		setdimlabel 0, i, $stringfromlist(i, wavelist(states_prefix+"*",";","")), StateTransitions
	endfor

	wavestats/q StateTransitions; print "AVERAGE", v_avg, "+-", v_sem, "Transitions"
	edit StateTransitions.l, StateTransitions
	return StateTransitions
end

Function BSMatrixExplorer(InputMatrix, plane1, [plane2, plane3])	//show data from columns for up to 3 planes
	wave InputMatrix
	variable plane1, plane2, plane3
	
	if(datafolderexists("root:packages:BSMatrixExplorer:") == 0)
		newdatafolder root:packages:BSMatrixExplorer
	endif
	
	variable/g root:packages:BSMatrixExplorer:colNUM = 0; nvar colNum = root:packages:BSMatrixExplorer:colNUM
	string/g root:packages:BSMatrixExplorer:MatrixReference = GetWavesDataFolder(InputMatrix, 4)
	variable/g root:packages:BSMatrixExplorer:plane1 =  plane1
	variable/g root:packages:BSMatrixExplorer:plane2 =  plane2
	variable/g root:packages:BSMatrixExplorer:plane3 =  plane3
		
	duplicate/o/r=[][colnum][plane1] InputMatrix Plane1Data
	display/K=1 Plane1Data; DoWindow/C ExploreMatrixColumns
	ModifyGraph axisEnab(left)={0,0.9}
	textBox/w=ExploreMatrixColumns/C/N=text0/F=0/B=1/A=MC/X=35.00/Y=48.00 "Column " + num2str(colNUM)
	
	if(plane2)
		duplicate/o/r=[][colnum][plane2] InputMatrix Plane2Data
		appendtograph Plane2Data
		ModifyGraph rgb(Plane2Data)=(0,0,0)

		if(plane3)
			duplicate/o/r=[][colnum][plane3] InputMatrix Plane3Data
			appendtograph Plane3Data
			ModifyGraph rgb(Plane3Data)=(0,0,65280)
		endif
	endif
	
	SetWindow ExploreMatrixColumns, hook(MyHook) = MoveAlongColumns
	
end

Function MoveAlongColumns(s)	//This is a hook for the mousewheel movement in MatrixExplorer
	STRUCT WMWinHookStruct &s
	wave Inputmatrix
	
	SVAR DataName = root:packages:BSMatrixExplorer:MatrixReference
	NVAR ColNum = root:packages:BSMatrixExplorer:colNUM
	NVAR plane1 = root:packages:BSMatrixExplorer:plane1
	NVAR plane2 = root:packages:BSMatrixExplorer:plane2
	NVAR plane3 = root:packages:BSMatrixExplorer:plane3
	
	Variable hookResult = 0	// 0 if we do not handle event, 1 if we handle it.
	Wave InputMatrix = $DataName
	
		switch(s.eventCode)
		case 22:					// mouseWheel event
			switch (s.wheelDy)	//wheel movement
				case -1:	//mouse wheel down
//					Print "up"
					ColNum -= 1; ColNum = ColNum < 0 ? 0 : ColNum // stop at first column 
					duplicate/o/r=[][colNum][plane1] InputMatrix Plane1Data

					if(FindListItem("Plane2Data",tracenamelist("ExploreMatrixColumns",";",2)))
						duplicate/o/r=[][colNum][plane2] InputMatrix Plane2Data
					endif
					
					if(FindListItem("Plane3Data",tracenamelist("ExploreMatrixColumns",";",2)))
						duplicate/o/r=[][colNum][plane3] InputMatrix Plane3Data
					endif
					TextBox/C/N=text0  "Column " + num2str(colNUM)
					break
				case 1:	//mouse wheel up
//					Print "down"
					ColNum += 1
								// stop at last column 
					ColNum = ColNum > (Dimsize(InputMatrix,1)-1) ? (Dimsize(InputMatrix,1)-1) : ColNum
					duplicate/o/r=[][colNum][plane1] InputMatrix Plane1Data
					
					if(FindListItem("Plane2Data",tracenamelist("ExploreMatrixColumns",";",2)))
						duplicate/o/r=[][colNum][plane2] InputMatrix Plane2Data
					endif
					
					if(FindListItem("Plane3Data",tracenamelist("ExploreMatrixColumns",";",2)))
						duplicate/o/r=[][colNum][plane3] InputMatrix Plane3Data
					endif
					
					TextBox/C/N=text0  "Column " + num2str(colNUM)
					break
			endswitch
				break
		case 2:	//close window
			killdatafolder/Z root:packages:BSMatrixExplorer
//			print "dead"
		endswitch

		return hookResult	// If non-zero, we handled event and Igor will ignore it.
	
end

function QuickStates(InputMatrix,smoothing)	//destroys all data except 1s plane
										//Takes 2d wave, smooths it (in plane 2)
										//second deriv in plane 3
										
	wave InputMatrix	//contains all of the ROI sweeps (1 sweep / column)
	variable smoothing
	
	Redimension/n=(-1,-1,3) InputMatrix
	variable i
	for(i=0; i<dimsize(InputMatrix,1); i+=1)
		duplicate/o/r=[][i][0] InputMatrix temp; smooth smoothing, temp; InputMatrix[][i][1] = temp[p]
	endfor
	
	duplicate/o/r=[][][1] InputMatrix tempDeriv
	
	differentiate/DIM=0 tempDeriv; differentiate/DIM=0 tempDeriv
	InputMatrix[][][2] = tempDeriv[p][q][0]
//	killwaves temp, tempDeriv
end

function/wave SdvDimension(inputMatrix,Dimension)	//"Rows", "Columns", or "Beams"
	WAVE inputMatrix
	string Dimension
	
	strswitch(Dimension)
		case "Rows":
			matrixop/o w_out=sqrt(varcols(inputMatrix))
		break
		case "Columns":
			matrixop/o w_sdv_beams=sqrt(varcols(transposeVol(inputMatrix,5)))
			matrixop/o w_out=transposeVol(w_sdv_beams,5)
		break
		case "Beams":
			matrixop/o w_sdv_beams=sqrt(varcols(transposeVol(inputMatrix,3)))
			matrixop/o w_out=transposeVol(w_sdv_beams,3)
		break
	endswitch
	
	string newname = nameofwave(inputMatrix)+"_"+Dimension+"_sdv"
	duplicate/o w_out $NewName; killwaves/z w_out
	return $NewName
	
end

function/wave MeanDimension(inputMatrix,Dimension)	//"Rows", "Columns", or "Beams"
	WAVE inputMatrix
	string Dimension
	
	strswitch(Dimension)
		case "Rows":
			variable Rows = Dimsize(inputMatrix,0)
			matrixop/o w_out = sumCols(inputMatrix)/Rows
		break
		case "Columns":
			variable Columns = Dimsize(inputMatrix,1)//; print rows
			matrixop/o w_out = (sumRows(inputMatrix))/Columns
		break
		case "Beams":
			variable Layers = Dimsize(inputMatrix,2)
			matrixop/o w_out = sumBeams(inputMatrix)/Layers
		break
	endswitch
	
	string newname = nameofwave(inputMatrix)+"_"+Dimension+"_avg"
	duplicate/o w_out $NewName; killwaves/z w_out
	return $NewName
	
end

Function displayRastersWdff(ROInum)
	variable ROInum
	String DFFprefix = "DFF_roi_"+num2str(ROInum)+"_*"
	variable i
	for(i=0;i<itemsinlist(wavelist("raster_21y*",";",""));i+=1)
		wave rastery = $stringfromlist(i,wavelist("raster_21y*",";",""))
		wave rasterx = $stringfromlist(i,wavelist("raster_21_*",";",""))
		wave DFFwave = $stringfromlist(i,wavelist(DFFprefix,";",""))
		display/k=1 rastery vs rasterx
		ModifyGraph mode=3,marker=10,rgb=(0,0,0)
		AppendToGraph/R DFFwave
		String DFFwaveName = nameofwave(dffwave)
		ModifyGraph rgb($DFFwaveName)=(0,39168,0)
	endfor
end

function DisplayPrefix(Prefix1,[prefix2, prefix3])
	string prefix1, prefix2, prefix3
	
	if(datafolderexists("root:packages:BSPrefixExplorer:") == 0)
		newdatafolder root:packages:BSPrefixExplorer
	endif
	string/g root:packages:BSPrefixExplorer:prefix1list = wavelist(prefix1+"*",";","");svar prefix1list = root:packages:BSPrefixExplorer:prefix1list
	variable/g root:packages:BSPrefixExplorer:prefixNUM = 0; nvar prefixNum = root:packages:BSPrefixExplorer:prefixNUM
	prefixNUM = 0
	
	duplicate/o $stringfromlist(0,prefix1list) Prefix1Wave
	display/k=1 Prefix1Wave; DoWindow/C ExplorePrefixes
	ModifyGraph axisEnab(left)={0,0.9}
	textBox/w=ExplorePrefixes/C/N=text0/F=0/B=1/A=MC/X=35.00/Y=48.00 stringfromlist(0,prefix1list)
	
	if(strlen(prefix2))
		string/g root:packages:BSPrefixExplorer:prefix2list = wavelist(prefix2+"*",";",""); svar prefix2list = root:packages:BSPrefixExplorer:prefix2list
		duplicate/o $stringfromlist(0,prefix2list) Prefix2Wave
		appendtograph Prefix2Wave	
	endif
	if(strlen(prefix3))
		string/g root:packages:BSPrefixExplorer:prefix3list = wavelist(prefix3+"*",";",""); svar prefix3list = root:packages:BSPrefixExplorer:prefix3list
		duplicate/o $stringfromlist(0,prefix3list) Prefix3Wave
		appendtograph Prefix3Wave		
	endif
	SetWindow ExplorePrefixes, hook(MyHook) = MoveThroughPrefixes
	print prefixNUM
end

Function MoveThroughPrefixes(s)	//This is a hook for the mousewheel movement in PrefixExplorer
	STRUCT WMWinHookStruct &s
	
	nvar prefixNum = root:packages:BSPrefixExplorer:prefixNUM
	svar prefix1list = root:packages:BSPrefixExplorer:prefix1list
	svar/z prefix2list = root:packages:BSPrefixExplorer:prefix2list
	svar/z prefix3list = root:packages:BSPrefixExplorer:prefix3list
	Variable hookResult = 0	// 0 if we do not handle event, 1 if we handle it
	
	switch(s.eventCode)
		case 22:					// mouseWheel event
			switch (s.wheelDy)	//wheel movement
				case -1:	//mouse wheel down
					prefixNUM -= 1; prefixNum = prefixNum < 0 ? 0 : prefixNum // don't go below 0
//					Print "down", prefixNUM
					duplicate/o $stringfromlist(prefixNUM,prefix1list) Prefix1Wave

					if(FindListItem("Prefix2Wave",tracenamelist("ExplorePrefixes",";",1)) != -1)
//						print "entered prefix2"
						duplicate/o $stringfromlist(prefixNUM,prefix2list) Prefix2Wave
					endif
					
					if(FindListItem("Prefix3Wave",tracenamelist("ExplorePrefixes",";",1)) != -1)
//						print "entered prefix 3"
						duplicate/o $stringfromlist(prefixNUM,prefix2list) Prefix2Wave
					endif
					TextBox/C/N=text0  stringfromlist(prefixNUM,prefix1list)
					break
				case 1:	//mouse wheel up
					prefixNUM += 1
					prefixNUM = prefixNUM > (itemsinlist(prefix1list) -1) ?  (itemsinlist(prefix1list) -1) : prefixNUM
//					Print "up", prefixNUM
					duplicate/o $stringfromlist(prefixNUM,prefix1list) Prefix1Wave

					if(FindListItem("Prefix2Wave",tracenamelist("ExplorePrefixes",";",1)) != -1)
						duplicate/o $stringfromlist(prefixNUM,prefix2list) Prefix2Wave
					endif
					
					if(FindListItem("Prefix3Wave",tracenamelist("ExplorePrefixes",";",1)) != -1)
						duplicate/o $stringfromlist(prefixNUM,prefix2list) Prefix2Wave
					endif
					TextBox/C/N=text0  stringfromlist(prefixNUM,prefix1list)
					break			
			endswitch
				break
		case 2:	//close window
			killdatafolder/Z root:packages:BSPrefixExplorer
//			print "dead"
		endswitch

		return hookResult	// If non-zero, we handled event and Igor will ignore it.
end