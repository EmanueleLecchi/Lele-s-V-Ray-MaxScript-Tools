(
	global exposimeterRoll
	try (destroyDialog exposimeterRoll)
	catch()
	

	
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
	
	local 	theFileStream=statsFileName=""
	local	unweightedMultiplierString=binnedMultString=prevFrameMultiplierString=theRatioString=finalExposureMultiplierString=""
	
	---------------------------  Temporal Smoothing Locals --------------------
	local 	percentExposureMultiplierVariancePerFrame=1.5	--declare as float
	local	mcPastFactualHistoryValues=#()
	local	mcPastFactualHistoryDerivates=#()
	local 	mcPastFactualHistoryValuesAvg=1.0
	local	mcPastFactualHistoryDerivatesAvg=0.0
	local 	mcHistoryLenght = 5
	local 	mcHistoryCutCounter=0
	local	relevantPercentAverage=0.0

	--------------------------- bad locals. BAD LOCALS! Heel! --------------------
	local 	minV=maxV=minVLog=maxVLog=rangeV=relRangeV=rangeVLog=relRangeVLog=0
	
	--------------------------- Animation Locals --------------------	
	local 	currFrame=0			--declare as int
	local	Start= animationRange.start			--declare as either frames (NNf, 12f, 135f and so on), as animationRange.start, or as sliderTime
	local 	End=animationRange.end 			--declare as either frames (NNf, 12f, 135f and so on), as animationRange.end, or as sliderTime
	local	theStep=1			--declare as int
	--UI-related locals
	local 	fileList=#()
	local 	opMode=1
	local	writeLog = true
	local	forceClamp= false
	local 	clampLevel=3
	local	displayResults = false
	local	saveResults= true
	local	historyMultiplier = 1.0
	local 	binsRange=1.5
	local 	hyperRange = 128.0
	local	hThreshMin=3.0
	local	hThreshMax=15.0
	
/*------------------------------------------------------------------------- Functions --------------------------------------------------------------------------------------------------------------------*/	

	fn renderToBuffers doTheRender frameToPick=
	(
		if doTheRender == 1 then
		(
			max quick render
			theRGB = vrayVFBGetChannelBitmap 1
		)
		else if doTheRender == 2 then
		(
			theFilename= fileList[frameToPick][1] 
			if theFilename!= undefined then
			(
				tempBitmap= openbitmap fileList[frameToPick][1] hdr:true
				theRgb= copy tempBitmap
				free tempBitmap
			)
			else exit
		)
		else
		(
			theRGB = vrayVFBGetChannelBitmap 1
		)
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
			theValuePixelsF=#()	
			theRgbPixelsF=#()			
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
		print "Calculating Factors from Image Data"
		wholeImageSum=0.0 as double
		wholeImageAverage=0.0
		alphaMaskCounter=0
		minPixelValueF=#(100000000.0,[0,0])
		maxPixelValueF=#(0.0,[0,0])
		
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
		rangeV=(maxV-minV)
		relRangeV=rangeV/maxV

		print "-------------------------------"
		print "wholeImageAverage"
		print wholeImageAverage
		print "-------------------------------"
		print "minV"
		print minV
		print "-------------------------------"
		print "maxV"
		print maxV
		print "\n-------------------------------"
		print "rangeV"
		print rangeV
		print "-------------------------------\n"
		relevantPercentAverage=0.0		
		sortedPixelValuesF=#()
		for i in theValuePixelsF do append sortedPixelValuesF i[1]
		sortedPixelValuesF=sort sortedPixelValuesF
		theCount = sortedPixelValuesF.count
		for i=1 to theCount do
		(
			if i<(theCount*0.25) then
			(
				relevantPercentAverage+=sortedPixelValuesF[i]/theCount
			)
			else
			(
				if sortedPixelValuesF[i] < relevantPercentAverage*clampLevel then
					relevantPercentAverage+=sortedPixelValuesF[i]/theCount
				else
				(
					print ("Exited at " + ((i as float/theCount)*100) as string + "% of the total pixels" )
					print ("sortedPixelValuesF[i] = " + sortedPixelValuesF[i] as string + " relevantPercentAverage*clampLevel = " + (relevantPercentAverage*clampLevel) as string )
					exit
				)
			)
		)
		print "\n-------------------------------"
		print "relevantPercentAverage"
		print relevantPercentAverage
		print ((0.5/relevantPercentAverage) as string)
		print "-------------------------------\n"	
	)
	
	fn pruneOverbrights clampLevel=
	(
		counter=0
		print "clamping overbrights"
		for p=theValuePixelsF.count to 1 by -1 do
		(
			if theValuePixelsF[p][1] > (wholeImageAverage * clampLevel) do
				(
					theValuePixelsF[p][1] = (wholeImageAverage * clampLevel)
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
	
	fn createHistogram doPruneOverbrights clampLevel=
	(
		Print "Creating Values Histogram"
		if doPruneOverbrights do pruneOverbrights clampLevel

		case of
		(
			(rangeV <= hyperRange) :
			(
				print "-----------> 2) high dynamic range image"
				binRange1= (wholeImageAverage+minV)/binsRange
				binRange2= (wholeImageAverage+minV)*binsRange
			)
			( rangeV > hyperRange) :
			(
				print "-----------> 3) Impossible Range Image"
				print "-----------> *) Forcing Adaptive Value Clamping"
				pruneOverbrights clampLevel
				getFloatPixelValues false
				calculateImageData()
				binRange1= (wholeImageAverage+minV)/binsRange
				binRange2= (wholeImageAverage+minV)*binsRange
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
		
		bin1Sum = bin2Sum = bin3Sum = bin1Avg = bin2Avg = bin3Avg = 0.0
		

		relevantSum=0.0d0
		for p=1 to theValuePixelsF.count do
		(
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
		
		if bin1.Count!=0 do bin1Avg=bin1Sum/bin1.Count
		if bin2.Count!=0 do bin2Avg=bin2Sum/bin2.Count
		if bin3.Count!=0 do bin3Avg=bin3Sum/bin3.Count
		bin1Perc=(bin1.count as float/totPixelCount)
		bin2Perc=(bin2.count as float/totPixelCount)
		bin3Perc=(bin3.count as float/totPixelCount)
		
		relevantAverage=0.0d0

		activeBin[1] = "Low and Mid Key"
		activeBin[2] = bin1Perc+bin2Perc
		relevantAverage = bin1Avg+bin2Avg

		print ("--------************* Using the " + activeBin[1] + " bin to calculate exposure with "+ ((bin1Perc+bin2Perc)*100.0) as string+"% of the total image pixels taken into account. *************--------")
	
		theBinnedExposureMultiplier=theAnchorW/relevantAverage
		binnedMultString=(theBinnedExposureMultiplier as float ) as string
		print ("--------************* Calculated Bins Multiplier: " + binnedMultString +" *************--------" )
		
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
	
	fn doMCCalculations =
	(
		
		case of
		(
			( rangeV <= hThreshMin ):	--indoor, long history
			(
				mcHistoryLenght=15
				mcHistoryCutCounter=mcPastFactualHistoryValues.count-mcHistoryLenght
				print "History length set at 15"
			)
			( rangeV > hThreshMin and rangeV <= hThreshMax ): --indoor glimpsing outdoors
			(
				mcHistoryLenght=10
				mcHistoryCutCounter=mcPastFactualHistoryValues.count-mcHistoryLenght
				print "History length set at 10"
			)
			( rangeV > hThreshMax ):	--outdoors,
			(
				mcHistoryLenght=5
				mcHistoryCutCounter=mcPastFactualHistoryValues.count-mcHistoryLenght
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
		print "-------------------------------"
		print "-------------------------------"
		print "The Used Exposure Multiplier"
		print theExposureMultiplier		
		print "-------------------------------"
		print "-------------------------------"
		
		finalExposureMultiplierString=(theExposureMultiplier as float ) as string
		prevFrameMultiplierString=(prevFrameMultiplier as float ) as string
	)

	fn produceFinalImage displayResults saveResults =
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

		if displayResults do 
		(
			display theRGB caption:"Original Render"
			display exposedImage caption:"Histogram-Based Exposure"
			display exposedImage2 caption:"Non-Weighted Exposure"
			display binsImage caption:"Bin Zones"
		)
		if saveResults do 
		(
			if opMode==1 or opMode==3 then
			(
				theRGB.filename= outputDir +(getfilenamefile maxfilename)+"_RawInput." + (frameNum.frame as integer) as string + ".exr"
				exposedImage.filename= outputDir + (getfilenamefile maxfilename)+"_History." + (frameNum.frame as integer) as string + ".exr"
				exposedImage2.filename= outputDir +(getfilenamefile maxfilename)+"_Unweighted." + (frameNum.frame as integer) as string + ".exr"
				binsImage.filename=  outputDir + (getfilenamefile maxfilename)+"_Bins." + (frameNum.frame as integer) as string + ".exr"
			)
			else
			(
				theRGB.filename= outputDir +"RawInput." + (frameNum.frame as integer) as string + ".exr"
				exposedImage.filename= outputDir +"History." + (frameNum.frame as integer) as string + ".exr"
				exposedImage2.filename= outputDir +"Unweighted." + (frameNum.frame as integer) as string + ".exr"
				binsImage.filename=  outputDir+"Bins." + (frameNum.frame as integer) as string + ".exr"				
			)
			save theRGB
			save exposedImage
			save exposedImage2
			save binsImage
			if not displayResults do
			(
				free theRGB
				free exposedImage
				free exposedImage2
				free binsImage
			)
		)
		if writeLog do format "%, %, %, %, %, %\n" frameNum unweightedMultiplierString binnedMultString mcHistoryLenght mcPastFactualHistoryValues.count finalExposureMultiplierString to:theFileStream
	)
	
	fn createOutputFolder =
	(
		if opMode==1 or opMode==3 then
		(			
			outputDir=(maxFilePath + @"exposimeter_renders\"+(getfilenamefile maxfilename)+@"\")
			makeDir outputDir
		)
		else
		(
			outputDir=((getfilenamepath fileList[1][1])+ @"exposimeter_renders\"+(getfilenamefile fileList[1][1])+@"\")
			makeDir outputDir
		)		
	)
		
	
	fn createStatsFile =
	(
		if opMode==1 or opMode==3 then
		(			
			statsFileName= maxFilePath + @"exposimeter_renders\"+(getfilenamefile maxfilename)+@"\"+(getfilenamefile maxfilename)+"_Stats.txt"
			theFileStream=createFile statsFileName
			format "Frame, Unweighted Mult., Histogram-Based Mult., Set History Lenght, Achieved History Lenght, History-Based Mult\n" to:theFileStream
		)
		else
		(
			statsFileName= (getfilenamepath fileList[1][1]) + @"exposimeter_renders\"+(getfilenamefile fileList[1])+@"\"+(getfilenamefile fileList[1][1])+"_Stats.txt"
			theFileStream=createFile statsFileName
			format "Frame, Unweighted Mult., Histogram-Based Mult., Set History Lenght, Achieved History Lenght, History-Based Mult\n" to:theFileStream
		)
	)

	fn getExrSequence searchPath = 
	(
		rawFiles=(getfiles (searchPath + @"\*.exr") )
		for i=1 to rawFiles.count do
			(
				rawFiles[i]=#(rawFiles[i],(getFileCreateDate rawFiles[i]))
			)
		fn sorterFn v1 v2=
		(
			local date1 = v1[2]
			local date2 = v2[2]
			case of
			(
				(date1 < date2): -1
				(date1 > date2): 1
				default: 0
			)
		)
		qsort rawFiles sorterFn

		rawFiles	
	)
	
	fn initUiChoiches = 
	(
		rl=exposimeterRoll
		case of
		(
			(opMode==1):
			(
				rl.goBtn.enabled=on
				
			)
			(opMode==2):
			(
				if fileList.count==1 do rl.goBtn.enabled=on
			)
			(opMode==3):
			(
				Start=rl.startSpn.value as time
				End=rl.endSpn.value as time
				theStep=rl.stepSpn.value as integer
			)
			(opMode==4):
			(
				if fileList.count>1 do rl.goBtn.enabled=on
			)
		)
		
		writeLog = rl.logChk.checked
		forceClamp = rl.clampChk.checked
		clampLevel = rl.clampSpn.value
		displayResults = rl.displayChk.checked
		saveResults = rl.saveChk.checked
		historyMultiplier = rl.histSpn.value
		percentExposureMultiplierVariancePerFrame = rl.flickerSpn.value
		binsRange=rl.binsSpn.value
		hyperRange =rl.hyperSpn.value
		browseOutput=rl.browseChk.checked
		hThreshMin=rl.hThreshASpn.value
		hThreshMax=rl.hThreshBSpn.value
	)	
	
	fn processInputs opMode =
	(
		rl=exposimeterRoll
		writeLog = rl.logChk.checked
		forceClamp = rl.clampChk.checked
		clampLevel = rl.clampSpn.value
		displayResults = rl.displayChk.checked
		saveResults = rl.saveChk.checked
		historyMultiplier = rl.histSpn.value
		percentExposureMultiplierVariancePerFrame = rl.flickerSpn.value
		binsRange=rl.binsSpn.value
		hyperRange =rl.hyperSpn.value
		browseOutput=rl.browseChk.checked
		hThreshMin=rl.hThreshASpn.value
		hThreshMax=rl.hThreshBSpn.value

		case of
		(
			(opMode==1):
			(

				Start=sliderTime
				End=sliderTime
				theStep=1
				if saveResults or writeLog do createOutputFolder()
				if writeLog do createStatsFile()
				for f=Start to End by theStep do
				(
					windows.processpostedmessages()
					
					if keyboard.EscPressed do 
					(
						if writeLog then exit with (close theFileStream)
						else exit
					)
							
					frameNum=sliderTime=f
					currFrame= (frameNum-Start).frame as integer
					print ("\n\nOperating on frame " + (sliderTime.frame as integer) as string +"\n")
			
					renderToBuffers 1 (currFrame+1)		-- true : execute render, false: grab the VFB RGB contents (including the CCs)
					collectRenderBuffers()
					getFloatPixelValues true		-- true: initialise arrays, false:refresh the V array from the stored RGB one. Useful after value clamping
					calculateImageData()
					createHistogram forceClamp clampLevel	-- True: prepass the values to clamp the maximum at 10 times the image average (calculated before the clamping.), False: Leave the input data untouched. Useful only for the binning phase's distribution and the non-weighted exposure multiplier, calculated after clamping.
					doMCCalculations()
					produceFinalImage displayResults saveResults -- True: display created buffers, False: do not display anything. // True: save buffers to disk in a subfolder of the scene file folder. False: Don't save a thing.
				)
				if writeLog do close theFileStream
				if browseOutput do shelllaunch outputDir ""
			)
			
			(opMode==2):
			(
				Start=sliderTime
				End=sliderTime
				theStep=1
				if saveResults or writeLog do createOutputFolder()
				if writeLog do createStatsFile()
				for f=Start to End by theStep do
				(
					windows.processpostedmessages()
					
					if keyboard.EscPressed do 
					(
						if writeLog then exit with (close theFileStream)
						else exit
					)
							
					frameNum=sliderTime=f
					currFrame= (frameNum-Start).frame as integer
					print ("\n\nOperating on frame " + (sliderTime.frame as integer) as string +"\n")
			
					renderToBuffers 2 (currFrame+1)			-- true : execute render, false: grab the VFB RGB contents (including the CCs)
					collectRenderBuffers()
					getFloatPixelValues true		-- true: initialise arrays, false:refresh the V array from the stored RGB one. Useful after value clamping
					calculateImageData()
					createHistogram forceClamp clampLevel	-- True: prepass the values to clamp the maximum at 10 times the image average (calculated before the clamping.), False: Leave the input data untouched. Useful only for the binning phase's distribution and the non-weighted exposure multiplier, calculated after clamping.
					doMCCalculations()
					produceFinalImage displayResults saveResults -- True: display created buffers, False: do not display anything. // True: save buffers to disk in a subfolder of the scene file folder. False: Don't save a thing.
				)
				if writeLog do close theFileStream
				if browseOutput do shelllaunch outputDir ""
			)
			(opMode==3):
			(
				if saveResults or writeLog do createOutputFolder()
				if writeLog do createStatsFile()
				for f=Start to End by theStep do
				(
					windows.processpostedmessages()
					
					if keyboard.EscPressed do 
					(
						if writeLog then exit with (close theFileStream)
						else exit
					)
							
					frameNum=sliderTime=f
					currFrame= (frameNum-Start).frame as integer
					print ("\n\nOperating on frame " + (sliderTime.frame as integer) as string +"\n")
			
					renderToBuffers 1 (currFrame)		-- true : execute render, false: grab the VFB RGB contents (including the CCs)
					collectRenderBuffers()
					getFloatPixelValues true		-- true: initialise arrays, false:refresh the V array from the stored RGB one. Useful after value clamping
					calculateImageData()
					createHistogram forceClamp clampLevel	-- True: prepass the values to clamp the maximum at 10 times the image average (calculated before the clamping.), False: Leave the input data untouched. Useful only for the binning phase's distribution and the non-weighted exposure multiplier, calculated after clamping.
					doMCCalculations()
					produceFinalImage displayResults saveResults -- True: display created buffers, False: do not display anything. // True: save buffers to disk in a subfolder of the scene file folder. False: Don't save a thing.
				)
				if writeLog do close theFileStream
				if browseOutput do shelllaunch outputDir ""
			)
			(opMode==4):
			(
				if saveResults or writeLog do createOutputFolder()
				if writeLog do createStatsFile()
				for f=1f to (fileList.count as time) by 1 do
				(
					windows.processpostedmessages()
					
					if keyboard.EscPressed do 
					(
						if writeLog then exit with (close theFileStream)
						else exit
					)
							
					frameNum=f
					currFrame= (frameNum-Start).frame as integer
					print ("\n\nOperating on frame " + (currFrame+1) as string +" of the sequence\n")
			
					renderToBuffers 2 (currFrame)		-- true : execute render, false: grab the VFB RGB contents (including the CCs)
					collectRenderBuffers()
					getFloatPixelValues true		-- true: initialise arrays, false:refresh the V array from the stored RGB one. Useful after value clamping
					calculateImageData()
					createHistogram forceClamp clampLevel	-- True: prepass the values to clamp the maximum at 10 times the image average (calculated before the clamping.), False: Leave the input data untouched. Useful only for the binning phase's distribution and the non-weighted exposure multiplier, calculated after clamping.
					doMCCalculations()
					produceFinalImage displayResults saveResults -- True: display created buffers, False: do not display anything. // True: save buffers to disk in a subfolder of the scene file folder. False: Don't save a thing.
				)
				if writeLog do close theFileStream
				if browseOutput do shelllaunch outputDir ""
			)
			(opMode==5):
			(

				Start=sliderTime
				End=sliderTime
				theStep=1
				if saveResults or writeLog do createOutputFolder()
				if writeLog do createStatsFile()
				for f=Start to End by theStep do
				(
					windows.processpostedmessages()
					
					if keyboard.EscPressed do 
					(
						if writeLog then exit with (close theFileStream)
						else exit
					)
							
					frameNum=sliderTime=f
					currFrame= (frameNum-Start).frame as integer
					print ("\n\nOperating on frame " + (sliderTime.frame as integer) as string +"\n")
			
					renderToBuffers 3 (currFrame+1)		
					collectRenderBuffers()
					getFloatPixelValues true		-- true: initialise arrays, false:refresh the V array from the stored RGB one. Useful after value clamping
					calculateImageData()
					createHistogram forceClamp clampLevel	-- True: prepass the values to clamp the maximum at 10 times the image average (calculated before the clamping.), False: Leave the input data untouched. Useful only for the binning phase's distribution and the non-weighted exposure multiplier, calculated after clamping.
					doMCCalculations()
					produceFinalImage displayResults saveResults -- True: display created buffers, False: do not display anything. // True: save buffers to disk in a subfolder of the scene file folder. False: Don't save a thing.
				)
				if writeLog do close theFileStream
				if browseOutput do shelllaunch outputDir ""
			)
		)
		
	)

	
	rollout exposimeterRoll "History-Based Exposimeter" width:312 height:472
	(
		dropdownList 'modeDdl' "" pos:[120,28] width:176 height:21 items:#("Render Current Frame", "Pick Single Frame", "Render Current Sequence", "Pick Sequence","Grab VFB Contents") align:#left
		button 'fldPickBtn' "Pick a Folder..." pos:[16,80] width:280 height:16 enabled:false align:#left
		button 'filPickBtn' "Pick a File..." pos:[16,56] width:280 height:16 enabled:false align:#left
		spinner 'startSpn' "" pos:[48,104] width:56 height:16 enabled:false range:[0,100000,0] type:#integer align:#left
		spinner 'endSpn' "" pos:[136,104] width:56 height:16 enabled:false range:[0,100000,0] type:#integer align:#left
		spinner 'stepSpn' "" pos:[240,104] width:56 height:16 enabled:false range:[0,100,0] type:#integer align:#left
		spinner 'flickerSpn' "" pos:[240,152] width:56 height:16 range:[0,100,1] type:#float align:#left
		spinner 'clampSpn' "" pos:[240,176] width:56 height:16 range:[0,100,3] type:#float align:#left
		spinner 'binsSpn' "" pos:[240,224] width:56 height:16 range:[0,10,1.5] type:#float align:#left
		spinner 'histSpn' "" pos:[240,248] width:56 height:16 range:[0,100,1] type:#float align:#left
		spinner 'hyperSpn' "" pos:[240,200] width:56 height:16 range:[1,1e+09,128] type:#float align:#left		
		spinner 'hThreshASpn' "" pos:[240,272] width:56 height:16 range:[0,10000,3.0] type:#float align:#left
		spinner 'hThreshBSpn' "" pos:[240,296] width:56 height:16 range:[0,10000,15.0] type:#float align:#left		
		
		button 'goBtn' "Go!" pos:[8,416] width:296 height:48 enabled:false align:#left
		
		label 'lbl1' "Flicker Guard %:" pos:[16,152] width:216 height:16 align:#left
		label 'lbl2' "Bins Clamp Mult.:" pos:[16,176] width:112 height:16 align:#left
		label 'lbl3' "Start:" pos:[16,104] width:32 height:16 enabled:true align:#left
		label 'lbl4' "End:" pos:[112,104] width:24 height:16 enabled:true align:#left
		label 'lbl5' "Step:" pos:[208,104] width:32 height:16 enabled:true align:#left	
		label 'lbl6' "Mode of Operation:" pos:[16,32] width:104 height:16 align:#left
		label 'lbl7' "Binning Factor:" pos:[16,224] width:112 height:16 align:#left
		label 'lbl8' "History Length Mult.:" pos:[16,248] width:112 height:16 align:#left
		label 'lbl9' "Hyper Range Threshold:" pos:[16,200] width:128 height:16 align:#left	
		label 'lbl10' "Long History Threshold:" pos:[16,272] width:112 height:16 align:#left
		label 'lbl11' "Short History Threshold:" pos:[16,296] width:112 height:16 align:#left
	
	
		
		GroupBox 'grp2' "Exposure Controls:" pos:[8,128] width:296 height:192 align:#left
		GroupBox 'grp1' "Mode Controls:" pos:[8,8] width:296 height:120 align:#left
		
		GroupBox 'grp3' "Extra Settings:" pos:[8,328] width:296 height:80 align:#left
		checkbox 'logChk' "Write CSV Logfile" pos:[16,352] width:104 height:16 checked:true align:#left
		checkbox 'clampChk' "Force Bins Clamping" pos:[16,368] width:116 height:16 align:#left		
		
		
		checkbox 'displayChk' "Display Results" pos:[176,352] width:104 height:16 align:#left
		checkbox 'saveChk' "Save Results" pos:[176,368] width:116 height:16 checked:true align:#left
		checkbox 'browseChk' "Browse Output" pos:[16,384] width:116 height:16 checked:true align:#left		
		

	on exposimeterRoll open do
		(
			initUiChoiches()
		)
		
		on modeDdl selected sel do
		(
			case of
			(
				(sel==1):
				(
					print modeDdl.items[sel]
					fldPickBtn.enabled=filPickBtn.enabled=startSpn.enabled=endSpn.enabled=stepSpn.enabled=off
					goBtn.enabled=on
					opMode=sel
				)
				(sel==2):
				(
					print modeDdl.items[sel]
					goBtn.enabled=fldPickBtn.enabled=startSpn.enabled=endSpn.enabled=stepSpn.enabled=off
					filPickBtn.enabled=on
					opMode=sel
				)
				(sel==3):
				(
					print modeDdl.items[sel]
					fldPickBtn.enabled=filPickBtn.enabled=off
					startSpn.enabled=endSpn.enabled=stepSpn.enabled=goBtn.enabled=on
					startSpn.value=animationRange.start
					endSpn.value=animationRange.end
					stepSpn.value=1
					opMode=sel
				)
				(sel==4):
				(
					print modeDdl.items[sel]
					filPickBtn.enabled=startSpn.enabled=endSpn.enabled=stepSpn.enabled=goBtn.enabled=off
					fldPickBtn.enabled=on
					opMode=sel
				)
				(sel==5):
				(
					print modeDdl.items[sel]
					fldPickBtn.enabled=filPickBtn.enabled=startSpn.enabled=endSpn.enabled=stepSpn.enabled=off
					goBtn.enabled=on
					opMode=sel
				)				
			)
		)
		on fldPickBtn pressed do
		(
			thePath=undefined
			fileList=#()			
			thePath = getFilenamePath (getOpenFileName caption:"Pick one file in the sequence" filename:"*.exr" types:"openExr(*.exr)|*.exr|All|*.*|"historyCategory:"Exposimeter Files") 
			if thePath != undefined do
			(
				filelist= getExrSequence thePath
				fldPickBtn.caption=thePath
				filPickBtn.caption="Pick a File..."
			)
			initUiChoiches()
		)
		on filPickBtn pressed do
		(
			theFile = undefined
			fileList=#()			
			theFile = (getOpenFileName caption:"Pick one file" filename:"*.exr" types:"openExr(*.exr)|*.exr" historyCategory:"Exposimeter Files")
			if theFile != undefined do
			(
				filelist[1]= #(theFile,"")
				filPickBtn.caption=getFilenameFile thefile + getFilenameType theFile
				fldPickBtn.caption="Pick a Folder..."
			)
			initUiChoiches()
		)
		on goBtn pressed do
		(
			processInputs opMode
		)
	)
	
	createDialog exposimeterRoll


)





