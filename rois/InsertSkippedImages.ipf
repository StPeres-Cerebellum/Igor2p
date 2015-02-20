#pragma rtGlobals=1		// Use modern global access method.
#include <FITS Loader>
#include <FilterDialog> menus=0


function InsertSkippedImages()
	
	string Trial_num = getdatafolder(0)
	string timername = Trial_num+"_timer"
	string peaks_name = "max_"+Trial_num
	string bline_name = "F_"+Trial_num
	wave ST_MaxY0_RawAll_A0
	wave ST_AvgY1_RawAll_A0
	wave imagetimer
	
	duplicate/o ST_MaxY0_RawAll_A0 temp_peaks
	duplicate/o ST_AvgY1_RawAll_A0 temp_blines
	duplicate/o imagetimer temptimer
	Differentiate temptimer/D=W_DIF
	string DffListstr = wavelist("DFF_ROI_1__*", ";", ""); list2wave(DffListStr, "DffNames")
	wave w_dif, Imagetimer, temptimer, temp_peaks, temp_blines, DffNames
	w_dif -= 1; w_dif *= 2
	variable inc
	for(inc = 0; inc <= (numpnts(W_DIF)); inc+=1  )
	
		if(W_dif[inc] > 0)
			insertpoints inc+1, w_dif[inc], W_DIF, temp_peaks, TempTimer, temp_blines, DffNames
			inc += w_dif[inc] + 1
		endif
	endfor
	TempTimer = Temp_peaks == 0 ? nan : TempTimer
	Temp_blines = Temp_peaks == 0 ? nan : Temp_blines
	Temp_peaks = Temp_peaks == 0 ? nan : Temp_peaks
	imagetimer = imagetimer == 0 ? nan : imagetimer
	SetScale/P x -30,1,"", Temp_peaks,Temp_blines
	wavestats/q temptimer; temptimer -= (v_min + 30)
	duplicate/o temptimer $Timername; killwaves temptimer
	duplicate/o temp_peaks $peaks_name; killwaves temp_peaks
	duplicate/o Temp_blines $bline_name; killwaves Temp_blines
	
end

function temp2()

	make/n=7 peak_avg
	make/n=7 peak_sem
		
	variable step = 0
	variable inc
	for(inc = 0; inc < 70; inc += 10)
		wavestats/q/r=[inc, inc+9] st_maxy0_dffall_a0
		peak_avg[step] = v_avg; peak_sem[step] = v_sdev / sqrt(v_npnts); step += 1
	endfor
end