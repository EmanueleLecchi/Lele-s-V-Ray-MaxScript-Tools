(
	global expoRoll
	try (closedialog expoRoll) catch()	
	--	expect V-Ray as engine.
	local vr = renderers.current
	-- 	setup the message string as empty
	local theMsg = ""

	--	arrays and dumps used throughout the script
	local	theRGB, theA, binsImage				--RENDER CHANNELS BUFFERS
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
	local	activeBin=#("bin1",0.0)
	
	local 	theNormalisedDists=#()		--array of the normalised distances from focus (weights)


	local 	totPixelCount	= 		0

	local	WBMultiplier 	= 		[1.0,1.0,1.0]

	local	theExposureMultiplier 	=  	1.0
	local	prevFrameMultiplier	=		theExposureMultiplier
	local	wholeImageAverage	=		0.0
	local 	wholeImageMultiplier =		0.0
	local	theAnchorW 	= 				0.5
	local	theAnchorUnW 	= 			0.5
	local 	frameNum	=				0.0
	local 	theRatio	=				1.0
	local 	alphaMaskCounter	=		0
	local	prunedImageAverage	=		0.0
	local	prunedImageMultiplier	=	0.0
	local 	theFileStream=""
	local	unweightedMultiplierString=binnedMultString=prevFrameMultiplierString=theRatioString=finalExposureMultiplierString=""
	
	
	--------------------------- bad locals. BAD LOCALS! Heel! --------------------
	local 	minV=maxV=minVLog=maxVLog=rangeV=relRangeV=rangeVLog=relRangeVLog=0
	
	--------------------------- Animation Locals --------------------	
	local	Start=animationRange.start		--declare as either frames (NNf, 12f, 135f and so on), as animationRange.start, or as sliderTime
	local 	End=animationRange.end			--declare as either frames (NNf, 12f, 135f and so on), as animationRange.end, or as sliderTime
	local	theStep=1						--declare as int
	local 	percentExposureMultiplierVariancePerFrame=25.0	--declare as float
	
/*------------------------------------------------------------------------- Functions --------------------------------------------------------------------------------------------------------------------*/	

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
	
	fn getFloatPixelValues doInit=		
	(
		if doInit do
		(
			theRgbPixelsF=#()			--array of the RGB pixels as floats, converted from the above
			theRgbPixelsF=virtualisePixels theRgbPixels
		)
		theValuePixelsF=#()	
		for p=1 to theRgbPixelsF.count do
		(
			theCol = theRgbPixelsF[p][1]
			theRealValue = (length theCol) as double

			if theRealValue > 0.0 do
			(	
				append theValuePixelsF #(theRealValue, theRgbPixelsF[p][2])
			)
		)
	)

	fn calculateImageData =
	(
		wholeImageSum=0.0 as double
		alphaMaskCounter=0
		
		for p=1 to theValuePixelsF.count do
		(
			theRealValue = theValuePixelsF[p][1]

			if theRealValue > 0.0 do
			(	
				alphaMaskCounter+=1				
				if theRealValue < minPixelValueF[1] do minPixelValueF = #(theRealValue,theRgbPixelsF[p][2])
				if theRealValue > maxPixelValueF[1] do maxPixelValueF = #(theRealValue,theRgbPixelsF[p][2])			
				wholeImageSum+=theRealValue as double
			)
		)

		wholeImageAverage=(wholeImageSum/alphaMaskCounter)
		wholeImageMultiplier=theAnchorUnW/wholeImageAverage
		unweightedMultiplierString=(wholeImageMultiplier as float) as string
		minV=minPixelValueF[1]
		maxV=maxPixelValueF[1]
		minVLog=log (1+minPixelValueF[1])
		maxVLog=log (1+maxPixelValueF[1])
		rangeV=(maxV-minV)
		relRangeV=rangeV/maxV
		rangeVLog=(maxVLog-minVLog)
		relRangeVLog=rangeVLog/maxVLog		
	)
	
	fn pruneOverbrights pruneFactor=
	(
		counter=0
		print "clamping overbrights"
		for p=theValuePixelsF.count to 1 by -1 do
		(
			if theValuePixelsF[p][1] > (wholeImageAverage * pruneFactor) do
				(
					theValuePixelsF[p][1] = (wholeImageAverage * pruneFactor)
					counter+=1
				)
		)
		print ("Clamped a total of " + counter as string + " Overbright pixels @" + (wholeImageAverage * (10)) as string + " float.")
		prunedImageAverage=0.0
		for p=1 to theValuePixelsF.count do
		(
			prunedImageAverage+=theValuePixelsF[p][1] as double
		)			
		prunedImageAverage/=theValuePixelsF.count
		prunedImageMultiplier=theAnchorW/prunedImageAverage
	)
	
	fn createHistogram doPruneOverbrights temporalSmoothingType=
	(
		Print "Creating Values Histogram"
		if doPruneOverbrights do pruneOverbrights()
		case of
		(
			( rangeVLog < 6.93147) :
			(
				print "-----------> 2) high dynamic range image"
				binRange1= rangeVLog/1.5
				binRange2= rangeVLog*1.5
			)
			(rangeVLog > 6.93147) :
			(
				print "-----------> 3) Impossible Range Image"
				binRange1= (wholeImageAverage-minV)/rangeVLog
				binRange2= (wholeImageAverage-minV)
			)
		)
		
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
		
		bin1Sum = bin2Sum = bin3Sum = bin1Avg = bin2Avg = bin3Avg = 0
		

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
					bin1Sum+=theV
				)
				(bin2Min <= theValuePixelsF[p][1] and theValuePixelsF[p][1] < bin2Max ) :
				(
					theV=theValuePixelsF[p][1]
					relevantSum+=theV
					append bin2  #(theV,theValuePixelsF[p][2])
					bin2Sum+=theV
				)
				(bin3Min <= theValuePixelsF[p][1] and theValuePixelsF[p][1] <= bin3Max ) :
				(
					append bin3 theValuePixelsF[p]
					bin3Sum+=theValuePixelsF[p][1]
				)
			)
		)

		if bin1.Count!=0 do bin1Avg=bin1Sum/bin1.Count
		if bin2.Count!=0 do bin2Avg=bin2Sum/bin2.Count
		if bin3.Count!=0 do bin3Avg=bin3Sum/bin3.Count
		bin1Perc=(bin1.count as float/totPixelCount)
		bin2Perc=(bin2.count as float/totPixelCount)
		bin3Perc=(bin3.count as float/totPixelCount)
		
		relevantAverage=bin1Avg

		if bin1Perc > activeBin[2] do 
		(
			activeBin[1] = "Low Key"
			activeBin[2] = bin1Perc
			relevantAverage=bin1Avg
		)
		if bin2Perc > activeBin[2] do 
		(
			activeBin[1] = "Low and Mid Key"
			activeBin[2] += bin2Perc
			relevantAverage+=bin1Avg
		)		
		print ("--------************* Using the " + activeBin[1] + " bin to calculate exposure. *************--------")
		
-- 		relevantAverage=relevantSum/(bin1.count+bin2.count)		
		theExposureMultiplier=theAnchorW/relevantAverage
		binnedMultString=(theExposureMultiplier as float ) as string
		
		case of
		(
			(temporalSmoothingType == 0):	--no smoothing
			(
				print ("--------************* Using the Calculated Multiplier: " +theExposureMultiplier as string + " *************--------")	
			)
			(temporalSmoothingType == 1):	-- simple % limit
			(
				if sliderTime != Start then	
				(
					multFactor=(1.0+(percentExposureMultiplierVariancePerFrame/100.0))--+(0.05*theStep))
					if theExposureMultiplier > prevFrameMultiplier*multFactor or theExposureMultiplier < prevFrameMultiplier/multFactor then 
					(
						print ("--------************* Steadying the Exposure Multiplier. The Calculated Multiplier " + theExposureMultiplier as string + " is outside of the allowed " + ((multFactor-1)*100) as string + "% per frame variance. Used Multiplier: " + prevFrameMultiplier as string + " *************--------")
						theExposureMultiplier = prevFrameMultiplier
					)
				)
			)	
			(temporalSmoothingType == 2):	--weighted blend		
			(
				if sliderTime != Start then	
				(
					tempMults=#(prevFrameMultiplier,theExposureMultiplier)
					theRatio=((amax tempMults) - (amin tempMults)) / (amax tempMults)
					theExposureMultiplier = (tempMults[1] * (1.0-theRatio) ) + (tempMults[2] * theRatio)					
					print ("--------************* Steadying the Exposure Multiplier. The Calculated Multiplier " + tempMults[2] as string + " has been blended " + ((theRatio)*100) as string "% with the previous frame one " + tempMults[1] as string + ". the resulting multiplier is : " + theExposureMultiplier as string + " *************--------")
				)						
			)
			(temporalSmoothingType == 3):	--percent-limited weighted blend		
			(
				if sliderTime != Start then	
				(
					multFactor=(1.0+(percentExposureMultiplierVariancePerFrame/100.0))
					tempMults=#(prevFrameMultiplier,theExposureMultiplier)
					case of
					(
						( ( (tempMults[2] > tempMults[1]*(multFactor/10.0)) and (tempMults[2] < tempMults[1]*(multFactor/5.0)) ) or ( (tempMults[2] < tempMults[1]*(1/(multFactor/10.0))) and (tempMults[2] > tempMults[1]*(multFactor/5.0)) ) ) :	--if close to the previous value, keep it.
						(
							theExposureMultiplier=tempMults[1]
						)						
						(tempMults[2] > tempMults[1]*multFactor):	--in case of a big jump, clamp the maximum allowed change (adaptation)
						(
							theRatio=(tempMults[1] - (tempMults[1]*multFactor)) / (tempMults[1]*multFactor)
							theExposureMultiplier = (tempMults[1] * (1.0-theRatio) ) + ((tempMults[1]*multFactor) * theRatio)
						)
						(tempMults[2] < tempMults[1]*(1.0/multFactor)): --in case of a big jump, clamp the maximum allowed change (adaptation)
						(
							theRatio=((tempMults[1]*(1.0/multFactor)) - tempMults[1]) / tempMults[1]
							theExposureMultiplier = (tempMults[1] * (1.0-theRatio) ) + ((tempMults[1]*(1.0/multFactor)) * theRatio)
						)
						default:										-- if normal, blend to smooth out transitions.
						(
							theRatio=((amax tempMults) - (amin tempMults)) / (amax tempMults)
							theExposureMultiplier = (tempMults[1] * (1.0-theRatio) ) + (tempMults[2] * theRatio)
						)
						
					)
				)
			)
		)
		
		theRatioString=(theRatio as float ) as string
		prevFrameMultiplierString=(prevFrameMultiplier as float ) as string
		finalExposureMultiplierString=(theExposureMultiplier as float ) as string
		prevFrameMultiplier	= theExposureMultiplier
		
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
			display binsImage caption:"Bin Zones"
		)
		if saveTheImage do 
		(
			makeDir (maxFilePath + @"exposimeter_renders\")
			theRGB.filename= maxFilePath + @"exposimeter_renders\"+(getfilenamefile maxfilename)+"_Raw." + (frameNum.frame as integer) as string + ".exr"
			exposedImage.filename= maxFilePath + @"exposimeter_renders\"+(getfilenamefile maxfilename)+"_Histogram." + (frameNum.frame as integer) as string + ".exr"
			exposedImage2.filename= maxFilePath + @"exposimeter_renders\"+(getfilenamefile maxfilename)+"_Unweighted." + (frameNum.frame as integer) as string + ".exr"
			binsImage.filename=  maxFilePath + @"exposimeter_renders\"+(getfilenamefile maxfilename)+"_Bins." + (frameNum.frame as integer) as string + ".exr"
			
			save theRGB
			save exposedImage
			save exposedImage2
			save binsImage
			if not displayTheImage do
			(
				free theRGB
				free exposedImage
				free exposedImage2
				free binsImage
			)

			format "%,%,%,%,%,%\n" frameNum unweightedMultiplierString binnedMultString prevFrameMultiplierString theRatioString finalExposureMultiplierString to:theFileStream
		)
	)
	
	fn createStatsFile =
	(
		statsFileName= maxFilePath + @"exposimeter_renders\"+(getfilenamefile maxfilename)+"_Stats.txt"
		theFileStream=createFile statsFileName
		format "Frame, Unweighted Mult., Binned Mult., Prev. Frame Mult., Blend Percent, Used Mult\n" to:theFileStream
	)

	
	-- Start, End and theStep are declared up top under the Animation Locals section.
	-- Use "animationRange.start" / "AnimaitonRange.end" to cover the whole animation range (duh.), or you can set both to "sliderTime" to render just the current frame.
	-- Any numerical Start or End time *needs* to be declared as frame, with the notation 12f, 0f, 22f and so on.
	-- Do not override the values below directly, as the animation exposure balancing depends on the "Start" variable.
	createStatsFile()
	
	for f=Start to End by theStep do
	(
		frameNum=f
		sliderTime=frameNum
		print ("\n\n\nOperating on frame " + (framenum.frame as integer) as string +"\n\n")
		print ("Total image Pixels (MPx): " + (totPixelCount as float / 1000000.0) as string)		
		st=timestamp()		
		renderToBuffers True			-- true : execute render, false: grab the VFB RGB contents (including the CCs)
		collectRenderBuffers()
		getFloatPixelValues true		-- true: initialise arrays, false:refresh the V array from the stored RGB one. Useful after value clamping
		theTimer=timestamp()-st
		print ("pixels (Rendered), gathered and converted in " +  (theTimer/1000.0)as string + " s." )
		print ("Milliseconds per pixel: " + ( theTimer as float/totPixelCount)as string )		
		st=timestamp()
		createHistogram false 3		-- True: prepass the values to clamp the maximum at 10 times the image average (calculated before the clamping.), False: Leave the input data untouched. Useful only for the binning phase's distribution and the non-weighted exposure multiplier, calculated after clamping.
		theTimer=timestamp()-st
		print ("pixels Binned in " +  (theTimer/1000.0)as string + " s." )
		print ("Milliseconds per pixel: " + ( theTimer as float/totPixelCount)as string )	
		st=timestamp()	
		produceFinalImage false true	-- True: display created buffers, False: do not display anything. // True: save buffers to disk in a subfolder of the scene file folder. False: Don't save a thing.
		theTimer=timestamp()-st
		print ("Image Exposed and Output in " + (theTimer/1000.0) as string + " s.")

	)
	close theFileStream
)
