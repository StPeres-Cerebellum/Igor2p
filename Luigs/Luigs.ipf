#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//Igorized by Brandon M. Stell from Michael Graupner's Python libraries 23/09/2014

Menu "2P"
	Submenu "Devices"
		submenu "Luigs and Neumann"
			"Initialize", /q, LN_Initialize()
		end
	end
end

function LN_initialize()
	if(datafolderexists("root:packages:Luigs")==0)
		newdatafolder root:packages:Luigs
		string/g  root:packages:Luigs:portnum //e.g. "COMX"  look it up (WIndows = Device Manager)
	endif
	string newPort
	SVAR portNum = root:packages:luigs:portnum
	VDTGetPortList2
	prompt newPort, "Available ports", popup, S_VDT
	doPrompt "L & N is connected to which USB port?", newPort
	portnum = newPort
	VDTOPenPort2 $portNum
end


////////////////////////Turn ON/OFF a manipulator (normally used only for testing)/////////////////////////////////////////
function LN_turnOnOffAxis(deviceNumber, axisLetter, ONorOFF)
	variable deviceNumber
	string axisLetter, ONorOFF
	
	variable unitNumber = LN_calculateDevice(deviceNumber,axisLetter)
	make/n=1/o butter = unitNumber
	
	variable crchigh =  LN_calculateCRC(butter,"hi")
	variable crcLow =  LN_calculateCRC(butter,"lo")

	make/o/n=7 VDTsend	
	VDTsend[0]=0x16		//syn
	VDTsend[1]=0			//ID-bit1
	VDTsend[3]=1			//Bits in the butter
	VDTsend[4]=unitNumber	//Axis - Device Combo
	VDTsend[5]=crcLow		//0x10	//CRC low bit
	VDTsend[6]=crcHigh		//0x21	//CRC high bit
	strswitch (ONorOFF)
		case "ON":
			VDTsend[2]=0x35
			break
		case "OFF":
			VDTsend[2]=0x34
			break
	endswitch

	LN_sendData()
	
end

////////////////////////Set the size of a single step (in microns)/////////////////////////////////////////
function LN_setStepSize(deviceNumber, axisLetter, micronStep) 	//ID=0x013a
	variable deviceNumber, micronStep							
	string axisLetter
	
	variable unitNumber = LN_calculateDevice(deviceNumber,axisLetter)
	make/o/n=5 butter
	string stepHex = convertFloat2Hex(micronStep)
	variable firstIEEE=str2num("0x"+stepHex[6,7]), secondIEEE=str2num("0x"+stepHex[4,5]), thirdIEEE=str2num("0x"+stepHex[2,3]), fourthIEEE=str2num("0x"+stepHex[0,1])

	//sorry about this:
	butter[0] = unitNumber 	//unit number
	butter[1] = firstIEEE
	butter[2] = secondIEEE
	butter[3] = thirdIEEE
	butter[4] = fourthIEEE
	
	variable crchigh =  LN_calculateCRC(butter,"hi")
	variable crcLow =  LN_calculateCRC(butter,"lo")
	
	//Syntax: <syn><ID><5>< unit number [ byte ] >< incrementation in µm [ float]><crc >
	make/o/n=11 VDTsend
	VDTsend[0]=0x16		//syn
	VDTsend[1]=0x01		//ID-bit1
	VDTsend[2]=0x3a		//ID-bit2
	VDTsend[3]=5			//bits to follow
	VDTsend[4]=unitNumber	//Axis - Device Combo
	VDTsend[5]=firstIEEE
	VDTsend[6]=secondIEEE
	VDTsend[7]=thirdIEEE
	VDTsend[8]=fourthIEEE
	VDTsend[9]=crcLow		//CRC low bit
	VDTsend[10]=crcHigh		//CRC high bit
	
	LN_sendData()
end

////////////////////////Move manipulator 1 step/////////////////////////////////////////
function LN_moveStep(deviceNumber, axisLetter, fwdBkwd)
	variable deviceNumber
	string axisLetter, fwdBkwd

//<syn><ID><1><unitnumber><crc>		forward = 0x140  backward = 0x0141
	variable unitNumber = LN_calculateDevice(deviceNumber,axisLetter)
	make/o/n=1 butter
	butter[0]=unitNumber
	variable crchigh =  LN_calculateCRC(butter,"hi")
	variable crcLow =  LN_calculateCRC(butter,"lo")

	
	
	make/o/n=7 VDTsend
	VDTsend[0]=0x16		//syn
	VDTsend[1]=0x01		//ID-bit1
	VDTsend[3]=1			//bits in the butter
	VDTsend[4]=unitNumber	//Axis - Device Combo
	VDTsend[5]=crcLow
	VDTsend[6]=crcHigh

	strswitch (fwdBkwd)
		case "fwd":
			VDTsend[2]=0x40
			break
		case "bkwd":
			VDTsend[2]=0x41
			break
	endswitch
	LN_sendData()
end

////////////////////////Set positioning speed/////////////////////////////////////////
function LN_setSpeed(deviceNumber, axisLetter, speed)
	variable deviceNumber, speed	// 0< speed <= 16 a.u.
	string axisLetter
	
	variable unitNumber = LN_calculateDevice(deviceNumber,axisLetter)
	make/n=2/o butter
	butter[0]=unitNumber
	butter[1]=speed
	
	variable crchigh =  LN_calculateCRC(butter,"hi")
	variable crcLow =  LN_calculateCRC(butter,"lo")

	make/o/n=8 VDTsend	
	VDTsend[0]=0x16		//syn
	VDTsend[1]=0x01		//ID-bit1
	VDTsend[2]=0x44		//ID-bit2
	VDTsend[3]=2			//Bits in the butter
	VDTsend[4]=unitNumber	//Axis - Device Combo
	VDTsend[5]=speed
	VDTsend[6]=crcLow		//0x10	//CRC low bit
	VDTsend[7]=crcHigh		//0x21	//CRC high bit

	LN_sendData()
	
end

////////////////////////Move manipulator +/-X microns/////////////////////////////////////////
function LN_moveMicrons(deviceNumber, axisLetter, micronMove) 
	variable deviceNumber, micronMove							
	string axisLetter
	
	////Syntax: <syn><ID><5>< unit number [ byte ] ><goal position in µm [ float]><crc >
	variable unitNumber = LN_calculateDevice(deviceNumber,axisLetter)
	make/o/n=5 butter
	string stepHex = convertFloat2Hex(micronMove)
	variable firstIEEE=str2num("0x"+stepHex[6,7]), secondIEEE=str2num("0x"+stepHex[4,5]), thirdIEEE=str2num("0x"+stepHex[2,3]), fourthIEEE=str2num("0x"+stepHex[0,1])

	//sorry about this:
	butter[0] = unitNumber 	//unit number
	butter[1] = firstIEEE
	butter[2] = secondIEEE
	butter[3] = thirdIEEE
	butter[4] = fourthIEEE
	
	variable crchigh =  LN_calculateCRC(butter,"hi")
	variable crcLow =  LN_calculateCRC(butter,"lo")
	
	//Syntax: <syn><ID><5>< unit number [ byte ] >< incrementation in µm [ float]><crc >
	make/o/n=11 VDTsend
	VDTsend[0]=0x16		//syn
	VDTsend[1]=0x00		//ID-bit1
	VDTsend[2]=0x4a		//ID-bit2
	VDTsend[3]=5			//bits to follow
	VDTsend[4]=unitNumber	//Axis - Device Combo
	VDTsend[5]=firstIEEE
	VDTsend[6]=secondIEEE
	VDTsend[7]=thirdIEEE
	VDTsend[8]=fourthIEEE
	VDTsend[9]=crcLow		//CRC low bit
	VDTsend[10]=crcHigh		//CRC high bit
	
	LN_sendData()
end

////////////////////////Calculate Checksum/////////////////////////////////////////
function LN_calculateCRC(butter, whichBit)		
	wave butter
	string whichBit
	variable length =numpnts(butter)

	variable crcPolynom = 0x1021
	variable crc = 0
	variable n = 0
	variable lll
	for(lll = length; lll > 0; lll -= 1)
		crc = crc %^ butter[n] *(2^8)
//		print "1" , crc
		variable i
		for (i = 0; i<8; i +=1)
			if (crc & 0x8000)
				crc = crc * (2^1) %^ crcPolynom
//				print "if ", crc
			else
				crc = crc * (2^1)
//				print "else", crc
			endif
		endfor
		n+=1
	endfor
//	print "end while ",crc
//	print "after", crc , crc / (2^8) 
	variable crcLow = crc / (2^8) & 0xFF
	variable crcHigh  = crc & 0xFF
	
	string crcLowString, crcHighString
	sprintf crcLowString, "%#x", crcLow
	sprintf crcHighString, "%#x", crcHigh
//	killwaves/z butter
	strswitch (whichBit)
		case "hi":
//			print crcHighString
			
			return (crcHigh)
		case "lo":
//			print crcLowString
			return (crcLow)
	endswitch
end



////////////////////////Write data to USB/////////////////////////////////////////
function LN_sendData()
	wave vdtSend
	SVAR portNum = root:packages:Luigs:portNum
	VDToperationsport2 $portnum
	VDT2 baud=38400, parity=0, databits=8, stopbits=1
//	make/o/n=100 vdtReceive
	variable i, V_VDT
	for(i=0; i<1; i*=1)
		VDTwriteBinary2/O=3 0x16, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 // Send sequence to establish connection to LN
		if(V_VDT > 0)
			break
		endif
		sleep/T 10
	endfor
	sleep/T 10
	VDTWriteBinaryWave2 vdtSend
//	killwaves/z vdtSend
//	VDTReadBinaryWave2 vdtReceive
end

////////////////////////Use Axis Letter and device Number to calculate which manipulator to address/////////////////////////////////////////
function LN_calculateDevice(deviceNumber,axisLetter)
		variable deviceNumber
		string axisLetter
		
		variable unitNumber = deviceNumber
		strswitch (axisLetter)
			case "x":
				unitNumber *= 3
				unitNumber -= 2
				break
			case "y":
				unitNumber *= 3
				unitNumber -= 1
				break
			case "z":
				unitNumber *= 3
				break
			endswitch
		return unitNumber
end

////////////////////////There must be a better way of doing this/////////////////////////////////////////
function/S ConvertFloat2Hex(inFloat)
	variable infloat
	
	make/n=1/o/y=2 floatWave
	floatWave = inFloat
	redimension/e=1/i floatWave
	string outHex
	sprintf outHex, "%x", floatWave[0]
	killwaves/z floatWave
	if(inFloat>0)
		return outHex
	elseif(inFloat<0)
		return outhex[(strlen(outhex)-8),(strlen(outhex))]
	endif
end


