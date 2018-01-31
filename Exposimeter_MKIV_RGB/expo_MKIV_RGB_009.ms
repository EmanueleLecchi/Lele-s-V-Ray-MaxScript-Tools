(
	local 	theMultType="Previous"
	local 	outputDir = ""
	--	arrays and dumps used throughout the script
	local	theRGB, binsImage				--RENDER CHANNELS BUFFERS
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
	local	theBinnedExposureMultiplier = 1.0
	local	prevFrameMultiplier	=		1.0
	local	wholeImageAverage	=		0.0
	local 	wholeImageMultiplier =		0.0
	local	theAnchorW 	= 				0.5
	local	theAnchorUnW 	= 			0.5
	local	relevantAverage =			0.0d0
	local 	frameNum	=				0f
	local 	theRatio	=				1.0
	local 	alphaMaskCounter	=		0
	local	prunedImageAverage	=		0.0
	local	prunedImageMultiplier	=	0.0
	local	minPixelValueF=#(100000000.0,[0,0])
	local 	maxPixelValueF=#(0.0,[0,0])

	local 	minV=maxV=minVLog=maxVLog=rangeV=relRangeV=rangeVLog=relRangeVLog=1.0
	
	local 	theFileStream=""
	local	unweightedMultiplierString=binnedMultString=prevFrameMultiplierString=theRatioString=finalExposureMultiplierString=""
	
	---------------------------  Temporal Smoothing Locals --------------------
	local 	percentExposureMultiplierVariancePerFrame=1.5	--declare as float
	local	mcPastFactualHistoryValues=#()
	local	mcPastFactualHistoryDerivates=#()
	local 	mcPastFactualHistoryValuesAvg=1.0
	local	mcPastFactualHistoryDerivatesAvg=0.0
	local 	mcHistoryLenght = 5
	local 	mcHistoryCutCounter=0

	--------------------------- bad locals. BAD LOCALS! Heel! --------------------
	local 	minV=maxV=minVLog=maxVLog=rangeV=relRangeV=rangeVLog=relRangeVLog=0
	
	--------------------------- Animation Locals --------------------	
	local 	currFrame=0			--declare as int
	local	Start= animationRange.start			--declare as either frames (NNf, 12f, 135f and so on), as animationRange.start, or as sliderTime
	local 	End=animationRange.end 			--declare as either frames (NNf, 12f, 135f and so on), as animationRange.end, or as sliderTime
	local	theStep=1			--declare as int

	
/*------------------------------------------------------------------------- Functions --------------------------------------------------------------------------------------------------------------------*/	

	fn renderToBuffers doTheRender =
	(
		windows.processpostedmessages()
		if keyboard.EscPressed do 
		(
			exit with (close theFileStream)
		)
		if doTheRender do max quick render
		theRGB = vrayVFBGetChannelBitmap 1
		imageWidth=theRGB.width
		imageHeight=theRGB.Height
		totPixelCount=imageWidth*imageHeight
	)

	fn collectRenderBuffers =
	(
		windows.processpostedmessages()
		if keyboard.EscPressed do 
		(
			exit with (close theFileStream)
		)
		Print "Collecting Pixels From Render Buffer"
		theRgbPixels=#()
		for y=1 to imageHeight do
		(
			for x=1 to imageWidth do
			(
				windows.processpostedmessages()
				if keyboard.EscPressed do 
				(
					exit with (close theFileStream)
				)
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
			windows.processpostedmessages()
			if keyboard.EscPressed do 
			(
				exit with (close theFileStream)
			)
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
		windows.processpostedmessages()
		if keyboard.EscPressed do 
		(
			exit with (close theFileStream)
		)
		if doInit do
		(
			theValuePixelsF=#()	
			theRgbPixelsF=#()			
			theRgbPixelsF=virtualisePixels theRgbPixels
		)

		theValuePixelsF=#()	
		for p=1 to theRgbPixelsF.count do
		(
			windows.processpostedmessages()
			if keyboard.EscPressed do 
			(
				exit with (close theFileStream)
			)
			
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
		windows.processpostedmessages()
		if keyboard.EscPressed do 
		(
			exit with (close theFileStream)
		)
		print "Calculating Factors from Image Data"
		wholeImageSum=0.0 as double
		wholeImageAverage=0.0
		alphaMaskCounter=0
		minPixelValueF=#(100000000.0,[0,0])
		maxPixelValueF=#(0.0,[0,0])
		
		for p=1 to theValuePixelsF.count do
		(
			windows.processpostedmessages()
			if keyboard.EscPressed do 
			(
				exit with (close theFileStream)
			)
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
-- 		minVLog=log (1+minPixelValueF[1])
-- 		maxVLog=log (1+maxPixelValueF[1])
		rangeV=(maxV-minV)
		relRangeV=rangeV/maxV
-- 		rangeVLog=(maxVLog-minVLog)
-- 		relRangeVLog=rangeVLog/maxVLog	

-- 		print "-------------------------------"
-- 		print "wholeImageAverage"
-- 		print wholeImageAverage
-- 		print "-------------------------------"
-- 		print "minV"
-- 		print minV
-- 		print "-------------------------------"
-- 		print "maxV"
-- 		print maxV
		print "\n-------------------------------"
		print "rangeV"
		print rangeV
		print "-------------------------------\n"
	)
	
	fn pruneOverbrights pruneFactor=
	(
		windows.processpostedmessages()
		if keyboard.EscPressed do 
		(
			exit with (close theFileStream)
		)
		counter=0
		print "clamping overbrights"
		for p=theValuePixelsF.count to 1 by -1 do
		(
			windows.processpostedmessages()
			if keyboard.EscPressed do 
			(
				exit with (close theFileStream)
			)
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
			windows.processpostedmessages()
			if keyboard.EscPressed do 
			(
				exit with (close theFileStream)
			)
			prunedImageAverage+=theValuePixelsF[p][1] as double
		)			
		prunedImageAverage/=theValuePixelsF.count
		prunedImageMultiplier=theAnchorW/prunedImageAverage
	)
	
	fn createHistogram doPruneOverbrights =
	(
		windows.processpostedmessages()
		if keyboard.EscPressed do 
		(
			exit with (close theFileStream)
		)
		Print "Creating Values Histogram"
		if doPruneOverbrights do pruneOverbrights 10.0

		case of
		(
			( relRangeV <= 1024.0) :
			(
				print "-----------> 2) high dynamic range image"
				binRange1= (wholeImageAverage+minV)/1.5
				binRange2= (wholeImageAverage+minV)*1.5
			)
			( relRangeV > 1024.0) :
			(
				print "-----------> 3) Impossible Range Image"
				print "-----------> *) Forcing Adaptive Value Clamping"
				pruneOverbrights 10
				getFloatPixelValues false
				calculateImageData()
				binRange1= (wholeImageAverage+minV)/1.5
				binRange2= (wholeImageAverage+minV)*1.5
			)
		)


-- 		print "binRange1"
-- 		print binRange1
-- 		print "binRange2"
-- 		print binRange2
		
		
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
		
		bin1Sum = bin2Sum = bin3Sum = bin1Avg = bin2Avg = bin3Avg = 0.0
		

		relevantSum=0.0d0
		for p=1 to theValuePixelsF.count do
		(
			windows.processpostedmessages()
			if keyboard.EscPressed do 
			(
				exit with (close theFileStream)
			)
			case of
			(
				(theValuePixelsF[p][1] >= bin1Min and theValuePixelsF[p][1] < bin1Max ) :
				(
					theV=theValuePixelsF[p][1]
					relevantSum+=theV
					append bin1 #(theV,theValuePixelsF[p][2])
					bin1Sum+=theV
				)
				(theValuePixelsF[p][1] >= bin2Min and theValuePixelsF[p][1] < bin2Max ) :
				(
					theV=theValuePixelsF[p][1]
					relevantSum+=theV
					append bin2  #(theV,theValuePixelsF[p][2])
					bin2Sum+=theV
				)
				(theValuePixelsF[p][1] >= bin3Min) :
				(
					append bin3 theValuePixelsF[p]
					bin3Sum+=theValuePixelsF[p][1]
				)
			)
		)

-- 		print "Bin1Count"
-- 		print bin1.Count
-- 		print "Bin2Count"
-- 		print bin2.Count
-- 		print "Bin3Count"
-- 		print bin3.Count
		
		if bin1.Count!=0 do bin1Avg=bin1Sum/bin1.Count
		if bin2.Count!=0 do bin2Avg=bin2Sum/bin2.Count
		if bin3.Count!=0 do bin3Avg=bin3Sum/bin3.Count
		bin1Perc=(bin1.count as float/totPixelCount)
		bin2Perc=(bin2.count as float/totPixelCount)
		bin3Perc=(bin3.count as float/totPixelCount)
		
-- 		print "Bin1Average"
-- 		print bin1Avg
-- 		print "Bin2Average"
-- 		print bin2Avg
		
		relevantAverage=0.0d0

		activeBin[1] = "Low and Mid Key"
		activeBin[2] = bin1Perc+bin2Perc
		relevantAverage = bin1Avg+bin2Avg

		print ("--------************* Using the " + activeBin[1] + " bin to calculate exposure with "+ ((bin1Perc+bin2Perc)*100.0) as string+"% of the total image pixels taken into account. *************--------")
-- 		print "relevantAverage"
-- 		print relevantAverage
-- 		relevantAverage=relevantSum/(bin1.count+bin2.count)		
		theBinnedExposureMultiplier=theAnchorW/relevantAverage
		binnedMultString=(theBinnedExposureMultiplier as float ) as string
		print ("--------************* Calculated Bins Multiplier: " + binnedMultString +" *************--------" )
		
		binsImage = bitmap imageWidth imageHeight hdr:true

		for p=1 to bin1.count do
		(
			windows.processpostedmessages()
			if keyboard.EscPressed do 
			(
				exit with (close theFileStream)
			)
			thePixel=([bin1[p][1],0,0,1]) as color
			setPixels binsImage [bin1[p][2][1],bin1[p][2][2]] #(thePixel)
		)
		for p=1 to bin2.count do
		(
			windows.processpostedmessages()
			if keyboard.EscPressed do 
			(
				exit with (close theFileStream)
			)

			thePixel=([0,bin2[p][1],0,1]) as color
			setPixels binsImage [bin2[p][2][1],bin2[p][2][2]] #(thePixel)
		)
		for p=1 to bin3.count do
		(
			windows.processpostedmessages()
			if keyboard.EscPressed do 
			(
				exit with (close theFileStream)
			)

			thePixel=([0,0,bin3[p][1],1]) as color
			setPixels binsImage [bin3[p][2][1],bin3[p][2][2]] #(thePixel)
		)
	)
	
	fn doMCCalculations =
	(
		
		case of
		(
			( rangeV <= 3.0 ):	--indoor, long history
			(
				mcHistoryLenght=15
				mcHistoryCutCounter=mcPastFactualHistoryValues.count-mcHistoryLenght
-- 				mcHistoryLenghtPrevious=mcHistoryLenght
				print "History length set at 15"
			)
			( rangeV > 3.0 and rangeV <=15.0 ): --indoor glimpsing outdoors
			(
				mcHistoryLenght=10
				mcHistoryCutCounter=mcPastFactualHistoryValues.count-mcHistoryLenght
-- 				mcHistoryLenghtPrevious=mcHistoryLenght				
				print "History length set at 10"
			)
			( rangeV > 15.0 ):	--outdoors,
			(
				mcHistoryLenght=5
				mcHistoryCutCounter=mcPastFactualHistoryValues.count-mcHistoryLenght
-- 				mcHistoryLenghtPrevious=mcHistoryLenght				
				print "History length set at 5"
			)
		)

		if sliderTime == Start then
		(
			prevFrameMultiplier = theBinnedExposureMultiplier				
			prevFrameMultiplierString=(prevFrameMultiplier as float ) as string
			append mcPastFactualHistoryValues prevFrameMultiplier
			append mcPastFactualHistoryDerivates 0.0
		) 
		else
		(
			append mcPastFactualHistoryValues theBinnedExposureMultiplier
			append mcPastFactualHistoryDerivates ((mcPastFactualHistoryValues[mcPastFactualHistoryValues.count]-mcPastFactualHistoryValues[(mcPastFactualHistoryValues.count-1)])/theStep)	
		)
		
		-- old method, will immediately shrink to size.
-- 		while mcPastFactualHistoryValues.count > mcHistoryLenght do
-- 		(
-- 			deleteItem mcPastFactualHistoryValues 1
-- 			deleteItem mcPastFactualHistoryDerivates 1
-- 		)						
		--new method, check if it has shrunk, if it has, delete two at a time
		if mcHistoryCutCounter>0 then
		(
			print "Shrinking history length!"
			deleteItem mcPastFactualHistoryValues 1
			deleteItem mcPastFactualHistoryDerivates 1		
			deleteItem mcPastFactualHistoryValues 1
			deleteItem mcPastFactualHistoryDerivates 1	
			mcHistoryCutCounter-=1
		)
		else
		(
			if mcPastFactualHistoryValues.count > mcHistoryLenght do
			(
				deleteItem mcPastFactualHistoryValues 1
				deleteItem mcPastFactualHistoryDerivates 1					
			)
		)

		
		
		mcPastFactualHistoryValuesAvg=mcPastFactualHistoryDerivatesAvg=0.0
		for i =1 to mcPastFactualHistoryValues.count do 
		(
			mcPastFactualHistoryValuesAvg+=mcPastFactualHistoryValues[i]/mcPastFactualHistoryValues.count
			mcPastFactualHistoryDerivatesAvg+=mcPastFactualHistoryDerivates[i]/mcPastFactualHistoryDerivates.count
		)
		
		multFactor=(1.0+(percentExposureMultiplierVariancePerFrame/100.0))	
			


		--if the change is within the percent set , keep the last used multiplier.
		if theBinnedExposureMultiplier > prevFrameMultiplier/multFactor and theBinnedExposureMultiplier < prevFrameMultiplier*multFactor then 
		(
			if (mcPastFactualHistoryDerivatesAvg <= 0.0 and (theBinnedExposureMultiplier-prevFrameMultiplier) <= 0) or  (mcPastFactualHistoryDerivatesAvg >= 0.0 and (theBinnedExposureMultiplier-prevFrameMultiplier) >= 0) then
			(
				print "MC: Multiplier close to precendent but along the Derivatives: Using mcHistory Average."
				theExposureMultiplier=mcPastFactualHistoryValuesAvg
				prevFrameMultiplier=theExposureMultiplier
				theMultType="HistoryAverage"
			)
			else
			(
				print "MC: Multiplier too similar to precendent one: Using the last valid one."
				theExposureMultiplier=prevFrameMultiplier
				theMultType="Previous"
			)
		)
		--the change is too big to ignore, let's use the average of the history.
		else 
		(
			print "MC: Multiplier required different enough: Using mcHistory Average."
			theExposureMultiplier=mcPastFactualHistoryValuesAvg
			prevFrameMultiplier=theExposureMultiplier
			theMultType="HistoryAverage"
		)
			
			


		
		print "-------------------------------"
		print "mcPastFactualHistoryValues"
		print mcPastFactualHistoryValues
		print "-------------------------------"
		print "mcPastFactualHistoryValuesAvg"
		print mcPastFactualHistoryValuesAvg					
-- 		print "-------------------------------"
-- 		print "mcPastFactualHistoryDerivates"
-- 		print mcPastFactualHistoryDerivates
-- 		print "-------------------------------"
-- 		print "mcPastFactualHistoryDerivatesAvg"
-- 		print mcPastFactualHistoryDerivatesAvg
-- 		print "-------------------------------"
-- 		print "theBinnedExposureMultiplier"
-- 		print theBinnedExposureMultiplier
-- 		print "-------------------------------"
-- 		print "prevFrameMultiplier"
-- 		print prevFrameMultiplier
		print "-------------------------------"
		print "-------------------------------"
		print "The Used Exposure Multiplier"
		print theExposureMultiplier		
		print "-------------------------------"
		print "-------------------------------"
		

		finalExposureMultiplierString=(theExposureMultiplier as float ) as string
		prevFrameMultiplierString=(prevFrameMultiplier as float ) as string
	
		
	)


		
	fn produceFinalImage displayTheImage saveTheImage=
	(
		windows.processpostedmessages()
		if keyboard.EscPressed do 
		(
			exit with (close theFileStream)
		)
		
		exposedImage = bitmap imageWidth imageHeight hdr:true
		exposedImage2 = bitmap imageWidth imageHeight hdr:true


		
		
		for p=1 to theRgbPixelsF.count do
		(
			windows.processpostedmessages()
			if keyboard.EscPressed do 
			(
				exit with (close theFileStream)
			)

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
			theRGB.filename= maxFilePath + @"exposimeter_renders\"+(getfilenamefile maxfilename)+@"\"+(getfilenamefile maxfilename)+"_Raw." + (frameNum.frame as integer) as string + ".exr"
			exposedImage.filename= maxFilePath + @"exposimeter_renders\"+(getfilenamefile maxfilename)+@"\"+(getfilenamefile maxfilename)+"_Histogram." + (frameNum.frame as integer) as string + ".exr"
			exposedImage2.filename= maxFilePath + @"exposimeter_renders\"+(getfilenamefile maxfilename)+@"\"+(getfilenamefile maxfilename)+"_Unweighted." + (frameNum.frame as integer) as string + ".exr"
			binsImage.filename=  maxFilePath + @"exposimeter_renders\"+(getfilenamefile maxfilename)+@"\"+(getfilenamefile maxfilename)+"_Bins." + (frameNum.frame as integer) as string + ".exr"
			
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

			format "%, %, %, %, %, %\n" frameNum unweightedMultiplierString binnedMultString mcHistoryLenght mcPastFactualHistoryValues.count finalExposureMultiplierString to:theFileStream
		)
	)
	
	fn createStatsFile =
	(
		outputDir=(maxFilePath + @"exposimeter_renders\"+(getfilenamefile maxfilename)+@"\")
		makeDir outputDir
		statsFileName= maxFilePath + @"exposimeter_renders\"+(getfilenamefile maxfilename)+@"\"+(getfilenamefile maxfilename)+"_Stats.txt"
		theFileStream=createFile statsFileName
		format "Frame, Unweighted Mult., Histogram-Based Mult., Set History Lenght, Achieved History Lenght, History-Based Mult\n" to:theFileStream
	)

	
	-- Start, End and theStep are declared up top under the Animation Locals section.
	-- Use "animationRange.start" / "AnimaitonRange.end" to cover the whole animation range (duh.), or you can set both to "sliderTime" to render just the current frame.
	-- Any numerical Start or End time *needs* to be declared as frame, with the notation 12f, 0f, 22f and so on.
	-- Do not override the values below directly, as the animation exposure balancing depends on the "Start" variable.
	createStatsFile()
	
	for f=Start to End by theStep do
	(
		windows.processpostedmessages()
		if keyboard.EscPressed do 
		(
			exit with (close theFileStream)
		)
				
		frameNum=sliderTime=f

		currFrame= (frameNum-Start).frame as integer
		print ("\n\nOperating on frame " + (sliderTime.frame as integer) as string +"\n")
-- 		print ("Total image Pixels (MPx): " + (totPixelCount as float / 1000000.0) as string)		
-- 		st=timestamp()		
		renderToBuffers True			-- true : execute render, false: grab the VFB RGB contents (including the CCs)
		collectRenderBuffers()
		getFloatPixelValues true		-- true: initialise arrays, false:refresh the V array from the stored RGB one. Useful after value clamping
		calculateImageData()
-- 		theTimer=timestamp()-st
-- 		print ("pixels (Rendered), gathered and converted in " +  (theTimer/1000.0)as string + " s." )
-- 		print ("Milliseconds per pixel: " + ( theTimer as float/totPixelCount)as string )		
-- 		st=timestamp()
		createHistogram false	-- True: prepass the values to clamp the maximum at 10 times the image average (calculated before the clamping.), False: Leave the input data untouched. Useful only for the binning phase's distribution and the non-weighted exposure multiplier, calculated after clamping.
		doMCCalculations()
-- 		theTimer=timestamp()-st
-- 		print ("pixels Binned in " +  (theTimer/1000.0)as string + " s." )
-- 		print ("Milliseconds per pixel: " + ( theTimer as float/totPixelCount)as string )	
-- 		st=timestamp()	
		produceFinalImage false true -- True: display created buffers, False: do not display anything. // True: save buffers to disk in a subfolder of the scene file folder. False: Don't save a thing.
-- 		theTimer=timestamp()-st
-- 		print ("Image Exposed and Output in " + (theTimer/1000.0) as string + " s.")

	)
	close theFileStream
	shelllaunch outputDir ""
)
