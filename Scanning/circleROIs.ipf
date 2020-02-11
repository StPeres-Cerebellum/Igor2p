#pragma TextEncoding = "Windows-1252"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <ImageSlider>


Menu "GraphMarquee"
	"Draw Circle" , /q, addCursor()
end

function circleMasks(s_marqueewin,Image)
	string s_marqueeWin
	wave Image
	string ImageFolder = GetWavesDataFolder(Image, 1 )
	variable radius = 10 // radius in microns

	variable Imagex = Dimsize(Image, 0); variable Imagey = Dimsize(Image, 1)
	
	
	string cursorInfo = csrInfo(A)
	wave imageName = CsrWaveRef(A)
	variable xpoint = numberByKey("POINT", cursorInfo)
	variable ypoint = numberByKey("YPOINT", cursorInfo)
	variable xImage = (xPoint * DimDelta(imageName, 0)  +  DimOffset(imageName, 0))
	
end

function addCursor()
	getmarquee
	string ImageName=ImageNameList(S_MarqueeWin, ";"); print imageName
	Imagename = Replacestring(";", Imagename,""); print imageName
	wave Image = $ImageName
	
//	variable radius = 10 // radius in microns
//	
//	print s_marqueewin
	cursor /h=1 /I J $ImageName 0, 0
end

function drawCircle(radius)
	variable radius	// radius in microns
	variable Xcoordinate = hcsr(J)
	variable Ycoordinate = vcsr (J)
//	print Xcoordinate, Ycoordinate

	wave Image = $stringbykey("TNAME", csrInfo(J))
	
	radius *= 1e-6
	
	SetDrawEnv xcoord= top,ycoord= left,linefgc= (65535,0,0),fillpat= 0,linethick= 3.00
	DrawOval xcoordinate - radius,ycoordinate - radius,xcoordinate + radius,ycoordinate + radius
	
	createCircleMask(radius, Xcoordinate, Ycoordinate, Image)
	
end

function createCircleMask(radius, xCoordinate, yCoordinate, Image)
	variable radius, xCoordinate, yCoordinate
	wave image
	
	duplicate/o image m_roimask
	m_roiMask = (xCoordinate-x)^2 + (yCoordinate-y)^2 < radius^2 ? 0 : 1
	
	

end