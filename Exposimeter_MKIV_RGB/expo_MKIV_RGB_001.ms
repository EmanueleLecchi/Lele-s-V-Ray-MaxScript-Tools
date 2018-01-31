(
	global expoRoll
	try (closedialog expoRoll) catch()	
	--	expect V-Ray as engine.
	local vr = renderers.current
	-- 	setup the message string as empty
	local theMsg = ""

	--	arrays and dumps used throughout the script
	local	theRGB, theA 				--RENDER CHANNELS BUFFERS
	local 	imageWidth=imageHeight=0
	local	theRgbPixels=#()			--array of the RGB pixels captured by line, 0-255 based
	local	theRgbPixelsF=#()			--array of the RGB pixels as floats, converted from the above
	local	theValuePixelsF=#()			--array of the Value of pixels as floats, derived from the above
	local	theAPixels=#()			--array of the RGB pixels captured by line, 0-255 based
	local	theAPixelsF=#()			--array of the RGB pixels as floats, converted from the above
	local 	theAPixelsFValue=#()
	local 	maxPixelValueF=#()
	local 	minPixelValueF=#()	
	
	local 	bin1=#()
	local 	bin2=#()
	local 	bin3=#()
	local	activeBin3=#()
	
	local 	theNormalisedDists=#()		--array of the normalised distances from focus (weights)


	local 	totPixelCount	= 		0

	local	WBMultiplier 	= 		[1.0,1.0,1.0]

	local	theExposureMultiplier 	=  	1.0
	local	wholeImageAverage	=		0.0
	local 	wholeImageMultiplier =		0.0
	local	theAnchorW 	= 				0.5
	local	theAnchorUnW 	= 			0.5
	local 	frameNum	=				0.0
	local 	alphaMaskCounter	=		0
	local	prunedImageAverage	=		0.0
	local	prunedImageMultiplier	=	0.0
	
	--------------------------- bad locals. BAD LOCALS! Heel! --------------------
	local minV=maxV=minVLog=maxVLog=rangeV=relRangeV=rangeVLog=relRangeVLog=0
	
	
/*------------------------------------------------------------------------- NEW CODE -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/	

	fn renderToBuffers doTheRender =
	(
		if doTheRender do max quick render
		theRGB = vrayVFBGetChannelBitmap 1
		theA =	 vrayVFBGetChannelBitmap 2
		imageWidth=theRGB.width
		imageHeight=theRGB.Height
		totPixelCount=imageWidth*imageHeight
	)

	fn collectRenderBuffers =
	(
		Print "Collecting Pixels From Render Buffer"
		theRgbPixels=#()
		for y=1 to imageHeight do
		(
			for x=1 to imageWidth do
			(
				coords= [x-1,y-1]
				append theRgbPixels #((getPixels theRgb coords 1 linear:true)[1],(coords))
			)
		)
	)
	
	fn virtualisePixels inputBuffer=
	(
		thePixel=[0.0,0.0,0.0]
		pixelsBuffer=#()
		for p=1 to totPixelCount do
		(
			thePixel=(inputBuffer[p][1] as point4) as point3
			if (length thePixel) > 0.0 do
			(
				append pixelsBuffer #(thePixel, inputBuffer[p][2])
			)
		)
		return pixelsBuffer
	)
	

	
	fn getFloatPixelValues xS yS xE yE =		
	(
		theRgbPixelsF=#()			--array of the RGB pixels as floats, converted from the above
		theValuePixelsF=#()			--array of the Value of pixels as floats, derived from the above

		print "Virtualising Render Pixels."		
		theRgbPixelsF=virtualisePixels theRgbPixels
		maxPixelValueF=#(0.0,[0,0])
		minPixelValueF=#(10000000.0,[0,0])
		print "Calculating Pixels' Values."
		wholeImageSum=0.0 as double
		alphaMaskCounter=0
		
		for p=1 to theRgbPixelsF.count do
		(
			theCol = theRgbPixelsF[p][1]
-- 			theNormalisedCol= normalize theCol
-- 			theNormalFactor = theCol/TheNormalisedCol
-- 			theNormalValue = (theNormalisedCol as color).v 
-- 			theRealValue = theNormalValue * theNormalFactor[1] 
			theRealValue = length theCol

			if theRealValue > 0.0 do
			(	
				alphaMaskCounter+=1				
				append theValuePixelsF #(theRealValue, theRgbPixelsF[p][2])
				if theRealValue < minPixelValueF[1] do minPixelValueF = #(theRealValue,theRgbPixelsF[p][2])
				if theRealValue > maxPixelValueF[1] do maxPixelValueF = #(theRealValue,theRgbPixelsF[p][2])			
				wholeImageSum+=theRealValue as double
			)
		)
		wholeImageAverage=(wholeImageSum/alphaMaskCounter)
		wholeImageMultiplier=theAnchorUnW/wholeImageAverage
		print "wholeImageAverage (before Pruning)"
		print wholeImageAverage

		minV=minPixelValueF[1]
		maxV=maxPixelValueF[1]
		minVLog=log (1+minPixelValueF[1])
		maxVLog=log (1+maxPixelValueF[1])
		rangeV=(maxV-minV)
		relRangeV=rangeV/maxV
		rangeVLog=(maxVLog-minVLog)
		relRangeVLog=rangeVLog/maxVLog
		print "minV  (before Pruning)"
		print minV
		print "maxV  (before Pruning)"
		print maxV
-- 		print "minVLog"
-- 		print minVLog
-- 		print "maxVLog"
-- 		print maxVLog
-- 		print "rangeV"
-- 		print rangeV
-- 		print "relRangeV"
-- 		print relRangeV
		print "rangeVLog  (before Pruning)"
		print rangeVLog
-- 		print "relRangeVLog"
-- 		print relRangeVLog

		
-- 		free theRGB 
	)

	fn pruneOverbrights =
	(
		counter=0
		print "clamping overbrights"
		for p=theValuePixelsF.count to 1 by -1 do
		(
			if theValuePixelsF[p][1] > (wholeImageAverage * (2^16)) do
				(
					theValuePixelsF[p][1] = (wholeImageAverage * (2^16))
					counter+=1
-- 					deleteItem theRgbPixelsF p
				)
		)
		print ("Clamped a total of " + counter as string + " Overbright pixels")
		prunedImageAverage=0.0
		for p=1 to theValuePixelsF.count do
		(
			prunedImageAverage+=theValuePixelsF[p][1]
		)			
		prunedImageAverage/=theValuePixelsF.count
		prunedImageMultiplier=theAnchorW/prunedImageAverage
		
		print "-----------------------------"
		print "prunedImageAverage"
		print prunedImageAverage
		print "prunedImageMultiplier"
		print prunedImageMultiplier
		print "-----------------------------"	
		
		wholeImageAverage=prunedImageAverage
		wholeImageMultiplier=prunedImageMultiplier
	)
	
	fn createHistogram doPruneOverbrights =
	(
		Print "Creating Values Histogram"
		numBins=3

		if doPruneOverbrights do pruneOverbrights()
			
		case of
		(
			(rangeVLog < 1.0) :
			(
				print "-----------> 1) low Dynamic Range Image"
				binRange1= rangeV/3
				binRange2= rangeV/1.5	
			)
			(rangeVLog >=1.0 and rangeVLog < 6.93147) :
			(
				print "-----------> 2) high dynamic range image"
				binRange1= rangeVLog/1.5
				binRange2= rangeVLog*1.5
			)
			(rangeVLog > 6.93147) :
			(
				print "-----------> 3) Impossible Range Image"
				binRange1= (wholeImageAverage-minV)/2
				binRange2= (wholeImageAverage-minV)
			)
		)
	
		print "binRange1"
		print binRange1
		print "binRange2"
		print binRange2	


		/* Log Ranges */

		bin1=#()		
		bin1Min=minV
		bin1Max=binRange1
		bin1Count=0
		
		bin2=#()
		bin2Min=binRange1
		bin2Max=binRange2
		bin2Count=0
		
		bin3=#()
		bin3Min=binRange2
		bin3Max=maxV		
		bin3Count=0

-- 		denominator=(amax #((log10 maxV),1.0))*1.25
		
		/* Linear Ranges
		bin1=#()		
		bin1Min=minV
		bin1Max=wholeImageAverage/denominator
		bin1Count=0
		
		bin2=#()
		bin2Min=wholeImageAverage/denominator
		bin2Max=wholeImageAverage*denominator
		bin2Count=0
		
		bin3=#()
		bin3Min=wholeImageAverage*denominator
		bin3Max=maxV		
		bin3Count=0
		*/
-- 		print "bin1Min"
-- 		print bin1Min
-- 		print "bin1Max"
-- 		print bin1Max
-- 		print "bin2Min"
-- 		print bin2Min
-- 		print "bin2Max"
-- 		print bin2Max
-- 		print "bin3Min"
-- 		print bin3Min
-- 		print "bin3Max"
-- 		print bin3Max		
		
		relevantSum=0.0
		relevantAverage=0.0		
		
		for p=1 to theValuePixelsF.count do
		(
			case of
			(
				(bin1Min <= theValuePixelsF[p][1] and theValuePixelsF[p][1] < bin1Max ) :
				(
					theV=theValuePixelsF[p][1]
					relevantSum+=theV
					append bin1 #(theV,theValuePixelsF[p][2])
				)
				(bin2Min <= theValuePixelsF[p][1] and theValuePixelsF[p][1] < bin2Max ) :
				(
					theV=theValuePixelsF[p][1]
					relevantSum+=theV
					append bin2  #(theV,theValuePixelsF[p][2])
				)
				(bin3Min <= theValuePixelsF[p][1] and theValuePixelsF[p][1] <= bin3Max ) :
				(
					append bin3 theValuePixelsF[p]
				)
			)
		)
		relevantAverage=relevantSum/(bin1.count+bin2.count)		
		
-- 		theAnchor= 0.5 + 
		theExposureMultiplier=theAnchorW/relevantAverage
		
		print bin1.count
		print ( ((bin1.count as float/totPixelCount)*100.0) as string)
		print bin2.count
		print ( ((bin2.count as float/totPixelCount)*100.0) as string)
		print bin3.count
		print ( ((bin3.count as float/totPixelCount)*100.0) as string)
		
		binsImage = bitmap imageWidth imageHeight hdr:true

		for p=1 to bin1.count do
		(
			thePixel=([bin1[p][1],0,0,1]) as color
			setPixels binsImage [bin1[p][2][1],bin1[p][2][2]] #(thePixel)
		)
		for p=1 to bin2.count do
		(
			thePixel=([0,bin2[p][1],0,1]) as color
			setPixels binsImage [bin2[p][2][1],bin2[p][2][2]] #(thePixel)
		)
		for p=1 to bin3.count do
		(
			thePixel=([0,0,bin3[p][1],1]) as color
			setPixels binsImage [bin3[p][2][1],bin3[p][2][2]] #(thePixel)
		)


		display binsImage caption:"Bin Zones"
	)
	
	fn findProximalPatches =
	(
		print "looking for bright patches"
		basePos=[0,0]
		valuesArray=#()
		positionsArray=#()
		kernelPositions=#()
		for p=1 to bin3.count do
		(
			append valuesArray bin3[p][1]
			append positionsArray bin3[p][2]
		)
		
		for p=positionsArray.count to 1 by -1 do
		(
			foundPosA=#(0,0,0,0,0,0,0,0)
			foundPos=0
			basePos=positionsArray[p]
			kernelPositions=#(	[basePos[1]-1,basePos[2]-1],[basePos[1],basePos[2]-1],[basePos[1]+1,basePos[2]-1], [basePos[1]-1,basePos[2]],[basePos[1]+1,basePos[2]], [basePos[1]-1,basePos[2]+1],[basePos[1],basePos[2]+1],[basePos[1]+1,basePos[2]+1])		
				
			for kp=1 to kernelPositions.count do
			(
				foundPos=findItem positionsArray kernelPositions[kp]

				if foundPos==0 do 
				(
					foundPosA[kp]=1
				)
			)
			if foundPosA==#(1,1,1,1,1,1,1,1) do 	--pixel wholly surrounded, delete.
				(
					print "surrounded!"
					try
					(
						deleteItem positionsArray p
						deleteItem valuesArray p
					)
					catch()
				)
		)
		print bin3.count
		print valuesArray.count
		
	)

	
	fn produceFinalImage displayTheImage saveTheImage=
	(
		
		exposedImage = bitmap imageWidth imageHeight hdr:true
		exposedImage2 = bitmap imageWidth imageHeight hdr:true

		for p=1 to theRgbPixelsF.count do
		(
			thePixel=#( ((theRgbPixelsF[p][1]*theExposureMultiplier) as point4) as color, theRgbPixelsF[p][2] )
			setPixels exposedImage thePixel[2] #(thePixel[1])
			thePixel=#( ((theRgbPixelsF[p][1]*wholeImageMultiplier) as point4) as color, theRgbPixelsF[p][2] )
			setPixels exposedImage2 thePixel[2] #(thePixel[1])
			
		)

		if displayTheImage do 
		(
			display theRGB caption:"Original Render"
			display exposedImage caption:"Histogram-Based Exposure"
			display exposedImage2 caption:"Non-Weighted Exposure"
		)
		if saveTheImage do 
		(
			makeDir (maxFilePath + @"exposimeter_renders\")
			exposedImage.filename= maxFilePath + @"exposimeter_renders\"+(getfilenamefile maxfilename)+"_off_off_" + (frameNum.frame as integer) as string + ".exr"
			save exposedImage
		)
-- 		display WBdTotRef caption:"White-Balanced Total Raw Reflection"
-- 		display WBdTotDiffuse caption:"White-Balanced Diffuse * RTL"
		
	)
	
	St=animationRange.start
	End=animationRange.end
	theStep=1
	
	for f=sliderTime to sliderTime by theStep do
		
	(
		frameNum=f
		sliderTime=frameNum
		
		renderToBuffers false
		print ("Total image Pixels (MPx): " + (totPixelCount as float / 1000000.0) as string)
		st=timestamp()
		collectRenderBuffers()
		getFloatPixelValues 0 0 imageWidth imageHeight
		createHistogram true
-- 		findProximalPatches()
		theTimer=timestamp()-st
		print ("pixels gathered and converted in " +  (theTimer/1000.0)as string + " s." )
		print ("Milliseconds per pixel: " + ( theTimer as float/totPixelCount)as string )
			

-- 		st=timestamp()	
-- 		calculateExposedValues false false false												-- options: consider BG -> use BG weights -> invert BG weights
-- 		theTimer=timestamp()-st
-- 		print ("Exposure Multiplier calculated in " + (theTimer/1000.0) as string + " s.")
-- 		print ("Milliseconds per pixel: " + ( theTimer as float/totPixelCount) as string )
-- 		
		st=timestamp()	
		produceFinalImage true false
		theTimer=timestamp()-st
		print ("White-Balanced the RawLighting in " + (theTimer/1000.0) as string + " s.")
		print ("Milliseconds per pixel: " + ( theTimer as float/totPixelCount) as string )	
	)
)
