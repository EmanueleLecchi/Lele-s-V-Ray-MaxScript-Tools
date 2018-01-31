(
	/*
	General script workflow:
	*) Fill the RGB buffer
	*) Collect 8bit-based pixels provided they are not black. Count how many you collected.
	*) Convert to point4s, then to point3s
	*) Collect all the Values as floats
	*) Find min, max and range of Values
	*) Append the range to the mcHistory
	*) Perform historyAverage range-based cutoff on pixel values
	*) Compute the image average from the valid pixels
	*) Compute the histogram image multiplier 
	*) Calculate the delta between the current frame multiplier and the previous one used, append the derivative to the mcHistory array
	*) Check the value of the histogram image multiplier  against mc P (the average of the multipliers' history, plus the average of the derivatives history.):
	**)	If the current histogram multiplier lies along the mcHistory average of multipliers, plus their derivative average, append it to the mcHistory array. 
	***)		Calculate the mcHistory Average.
	**) 	If the current histogram multiplier does not lie along the mcHistory average of multipliers, plus their derivative average, check the value of the mcHistory average multiplier against the one of the previous frame,
	***)		If the new and old values are within a certain % to each other, use the previous value, else use the mcHistoryAverage *without* the new histogram image multiplier added in.
	****)			Finally add the histogram image multiplier  for this frame to the mcHistory array
	*) Display or save the outputs.
	*) Flush and clean after yourself.
	*/
	
	--	arrays and buffers used throughout the script
	local	theRGB, binsImage, unweightedImage, historyImage	--Image Buffers
	local	theRGBs=#()			--array of the RGB pixels as floats, converted from the image 8-bit color values
	local	theVs=#()			--array of the Value of pixels as floats, derived from the above
	local 	sortedVs=#()		--Sorted Values, so to find min and max quickly.
	local 	toKeepBin=#()				--array of the Value of pixels as floats to include in calculating the image average.
	local 	toDiscardBin=#()			--array of the Value of pixels as floats to discard in calculating the image average.
	local 	imagesList=#()

	local	minPixelValueF=#(100000000.0,[0,0])
	local 	maxPixelValueF=#(0.0,[0,0])

	local 	imageWidth=imageHeight=0
	local	theAnchor 	= 				0.5	
	local 	totPixelCount	= 		0
	local 	nonZeroPixelsCounter	=		0	
	local 	minV=maxV=rangeV=1.0
	local 	toKeepBinMax=0.0
	local 	unweightedImageSum = 0.0
	local	unweightedImageAverage	=	0.0
	local 	unweightedImageMult =		1.0
	local	histogramAverage=0.0	
	local	histogramExposureMult = 1.0
	local	prevFrameMult	=		1.0	
	local	finalExposureMult 	=  	1.0

	
	local 	theFileStream=statsFileName=outputDir=unweightedMultString=histogramMultString=prevFrameMultString=theRatioString=finalExposureMultString=""

	
	---------------------------  Temporal Smoothing Locals --------------------
	local 	percentExposureMultVariancePerFrame=1.5	--declare as float
	local	mcHistoryMults=#()
	local	mcHistoryDerivatives=#()
	local	mcHistoryRanges=#()
	local 	mcHistoryMultAvg=1.0
	local	mcHistoryDerivativesAvg=0.0
	local 	mcHistoryLenght = 25
	local 	mcHistoryCutCounter=0
	local	mcHistoryRangesAvg=1.0
	

	--------------------------- Animation Locals --------------------	
	local 	currFrame=0							--declare as int, base 0. (or 1?)
	local	Start=animationRange.start			--declare as either frames (NNf, 12f, 135f and so on), as animationRange.start, or as sliderTime
	local 	End=animationRange.end 			--declare as either frames (NNf, 12f, 135f and so on), as animationRange.end, or as sliderTime
	local	theStep=1			--declare as int
	
	--------------------------- UI-related Declarations ---------------------
	global exposimeterRoll
	try (destroyDialog exposimeterRoll)
	catch()
	
	local 	opMode=1
	local	writeLog = true
	local	forceClamp= false
	local 	clampLevel=3
	local	displayResults = false
	local	saveResults= true
	local	historyMult = 1.0
	local 	binsRange=1.5
	local 	hyperRange = 128.0
	local	hThreshMin=3.0
	local	hThreshMax=15.0
	local   doInput=doBins=doUnweighted=doHistory=true
	
/*------------------------------------------------------------------------- Functions --------------------------------------------------------------------------------------------------------------------*/	

	fn clearUp =
	(
		theRgbPixels=#()			--array of the RGB pixels captured by line, 0-255 based
		theRGBs=#()			--array of the RGB pixels as floats, converted from the above
		theVs=#()			--array of the Value of pixels as floats, derived from the above
	
		toKeepBin=#()
		toDiscardBin=#()
			
		totPixelCount	= 		0

		finalExposureMult 	=  	1.0
		histogramExposureMult = 1.0
		prevFrameMult	=		1.0
		unweightedImageAverage	=		0.0
		unweightedImageMult =		0.0
		theAnchor 	= 				0.5
		frameNum	=				0f
		nonZeroPixelsCounter	=		0

		minPixelValueF=#(100000000.0,[0,0])
		maxPixelValueF=#(0.0,[0,0])

		minV=maxV=rangeV=1.0
		
		theFileStream=statsFileName=""
		unweightedMultString=histogramMultString=prevFrameMultString=theRatioString=finalExposureMultString=""
		
		percentExposureMultVariancePerFrame=1.5	--declare as float
		mcHistoryMults=#()
		mcHistoryDerivatives=#()
		mcHistoryMultAvg=1.0
		mcHistoryDerivativesAvg=0.0
		mcHistoryLenght = 5
		mcHistoryCutCounter=0
		histogramAverage=0.0
		mcHistoryRanges=#()
		mcHistoryRangesAvg=1.0
	)
	
	fn initBufferVars = 
	(
		imageWidth=imageHeight=totPixelCount=0
	)	
	fn renderToBuffers doTheRender frameToPick=
	(
		initBufferVars()
		if doTheRender == 1 then
		(
			max quick render
			theRGB = vrayVFBGetChannelBitmap 1
		)
		else if doTheRender == 2 then
		(
			theFilename= imagesList[frameToPick][1] 
			if theFilename!= undefined then
			(
				tempBitmap= openbitmap imagesList[frameToPick][1] hdr:true
				theRGBs= copy tempBitmap
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
	
	fn initCollectionVars = 
	(
		theRGBs=#()
		theVs=#()
		nonZeroPixelsCounter=0
		unweightedImageSum=0.0
	
	)
	fn collectRenderBuffers =
	(
		Print "Collecting Pixels From Render Buffer"
		initCollectionVars()
		for y=1 to imageHeight do
		(
			for x=1 to imageWidth do
			(
				coords= [x-1,y-1]
				thePixel=(getPixels theRGB coords 1 linear:true)[1]
				theFPixel=(thePixel as point4) as point3
				theVPixel= length theFPixel
				if theVPixel != 0.0 do
				(
					append theRGBs #(theFPixel,(coords))
					append theVs #(theVPixel,(coords))
-- 					if theVPixel < minPixelValueF[1] do minPixelValueF = #(theVPixel,coords)
-- 					if theVPixel > maxPixelValueF[1] do maxPixelValueF = #(theVPixel,coords)
					unweightedImageSum+=theVPixel
					nonZeroPixelsCounter+=1
				)		
			)
		)
		if not doInput do free theRGB
	)
	
	fn initImageDataRangesVars = 
	(
		minV=maxV=unweightedImageAverage=0.0
		unweightedImageMult=1.0	
		sortedVs=#()
	)
	fn calculateImageDataRanges =
	(
		initImageDataRangesVars()
		
		unweightedImageAverage=unweightedImageSum/nonZeroPixelsCounter
		unweightedImageMult=theAnchor/unweightedImageAverage

		for i in theVs do append sortedVs i[1]
		sortedVs=sort sortedVs
		minV=sortedVs[1]
		maxV=sortedVs[sortedVs.count]
		rangeV=maxV-minV
		
		append mcHistoryRanges rangeV
		mcHistoryRangesAvg=0.0
		for i = 1 to mcHistoryRanges.count do
		(
			mcHistoryRangesAvg+=mcHistoryRanges[i]/mcHistoryRanges.count
		)
		
		print "-------------------------------"
		print "unweightedImageAverage"
		print unweightedImageAverage
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
		print "\n-------------------------------"
		print "mcHistoryRangesAvg"
		print mcHistoryRangesAvg
		print "-------------------------------\n"
		
	)
	
	fn initHistogramVars =
	(
		histogramAverage=0.0
		histogramExposureMult=1.0
		toKeepBinMax=0.0
	)
	fn createHistogram clampLevel=
	(
		Print "Creating Values Histogram"
		
		initHistogramVars()
		
		theCount = sortedVs.count
		
		for i=1 to theCount where ( (log sortedVs[i]) < ((log mcHistoryRangesAvg)*clampLevel) ) do
		(
			histogramAverage+=sortedVs[i]/theCount
			toKeepBinMax=sortedVs[i]
		)
		
		histogramExposureMult=theAnchor/histogramAverage		
		histogramMultString=(histogramExposureMult as float ) as string
		print ("--------************* Calculated Bins Mult: " + histogramMultString +" *************--------" )
	)
	
	fn initBinsVars = 
	(
		toKeepBin=#()		
		toDiscardBin=#()
	)
	fn createBins =
	(
		initBinsVars()
		for p=1 to theVs.count do
		(
			case of
			(
				(theVs[p][1] < toKeepBinMax) :
				(
					append toKeepBin theVs[p]
				)

				(theVs[p][1] >= toKeepBinMax) :
				(
					append toDiscardBin theVs[p]
				)
			)
		)
	)
	
	fn initMCHistoryVars =
	(
		mcHistoryLenght=25
		mcHistoryCutCounter=0
	)
	fn setMCHistoryLength =
	(
		initMCHistoryVars()
		case of
		(
			( rangeV <= hThreshMin ):	--indoor, long history
			(
				mcHistoryLenght=floor(25*historyMult) 
				mcHistoryCutCounter=mcHistoryMults.count-mcHistoryLenght
			)
			( rangeV > hThreshMin and rangeV <= hThreshMax ): --indoor glimpsing outdoors
			(
				mcHistoryLenght=floor(17*historyMult)
				mcHistoryCutCounter=mcHistoryMults.count-mcHistoryLenght
			)
			( rangeV > hThreshMax ):	--outdoors,
			(
				mcHistoryLenght=floor(10*historyMult)
				mcHistoryCutCounter=mcHistoryMults.count-mcHistoryLenght
			)
		)
		print ("History length set at "+mcHistoryLenght as string)
	)
	fn refreshMCArrays = 
	(
		if currFrame == 0 then	--first, or only, frame of the sequence
		(
			prevFrameMult = histogramExposureMult				
			prevFrameMultString=(prevFrameMult as float ) as string
			append mcHistoryMults prevFrameMult
			append mcHistoryDerivatives 0.0
		) 
		else
		(
			append mcHistoryMults histogramExposureMult
			append mcHistoryDerivatives ((mcHistoryMults[mcHistoryMults.count]-mcHistoryMults[(mcHistoryMults.count-1)])/theStep)	
		)
		
		if mcHistoryCutCounter>0 then
		(
			print "Shrinking history length!"
			deleteItem mcHistoryMults 1
			deleteItem mcHistoryDerivatives 1
			deleteItem mcHistoryRanges 1		
			deleteItem mcHistoryMults 1
			deleteItem mcHistoryDerivatives 1	
			deleteItem mcHistoryRanges 1	
			mcHistoryCutCounter-=1
		)
		else
		(
			if mcHistoryMults.count > mcHistoryLenght do
			(
				deleteItem mcHistoryMults 1
				deleteItem mcHistoryDerivatives 1	
				deleteItem mcHistoryRanges 1					
			)
		)
	)
	fn initMCCalcVars =
	(
		mcHistoryMultAvg=mcHistoryDerivativesAvg=0.0
	)

	fn calcMCValues = 
	(
		setMCHistoryLength()
		refreshMCArrays()
		initMCCalcVars()		
		for i =1 to mcHistoryMults.count do 
		(
			mcHistoryMultAvg+=mcHistoryMults[i]/mcHistoryMults.count
			mcHistoryDerivativesAvg+=mcHistoryDerivatives[i]/mcHistoryDerivatives.count
		)
		
		multFactor=(1.0+(percentExposureMultVariancePerFrame/100.0))	
			
		--if the change is within the percent set , keep the last used multiplier.
		if histogramExposureMult > prevFrameMult/multFactor and histogramExposureMult < prevFrameMult*multFactor then 
		(
			if (mcHistoryDerivativesAvg <= 0.0 and (histogramExposureMult-prevFrameMult) <= 0) or  (mcHistoryDerivativesAvg >= 0.0 and (histogramExposureMult-prevFrameMult) >= 0) then
			(
				print "MC: Mult close to precendent but along the Derivatives: Using mcHistory Average."
				finalExposureMult=mcHistoryMultAvg
				prevFrameMult=finalExposureMult
				theMultType="HistoryAverage"
			)
			else
			(
				print "MC: Mult too similar to precendent one: Using the last valid one."
				finalExposureMult=prevFrameMult
				theMultType="Previous"
			)
		)
		--the change is too big to ignore, let's use the average of the history.
		else 
		(
			print "MC: Mult required different enough: Using mcHistory Average."
			finalExposureMult=mcHistoryMultAvg
			prevFrameMult=finalExposureMult
			theMultType="HistoryAverage"
		)
			
		print "-------------------------------"
		print "mcHistoryMults"
		print mcHistoryMults
		print "-------------------------------"
		print "mcHistoryMultAvg"
		print mcHistoryMultAvg					
		print "-------------------------------"
		print "-------------------------------"
		print "The Used Exposure Mult"
		print finalExposureMult		
		print "-------------------------------"
		print "-------------------------------"
		
		finalExposureMultString=(finalExposureMult as float ) as string
		prevFrameMultString=(prevFrameMult as float ) as string
	)

	fn produceFinalImage displayResults saveResults =
	(
		if doHistory do historyImage = bitmap imageWidth imageHeight hdr:true
		if doUnweighted do unweightedImage = bitmap imageWidth imageHeight hdr:true
			
		for p=1 to theRGBs.count do
		(
			if doHistory do
			(
				thePixel=#( ((theRGBs[p][1]*finalExposureMult) as point4) as color, theRGBs[p][2] )
				setPixels historyImage thePixel[2] #(thePixel[1])
			)
			if doUnweighted do
			(				
				thePixel=#( ((theRGBs[p][1]*unweightedImageMult) as point4) as color, theRGBs[p][2] )
				setPixels unweightedImage thePixel[2] #(thePixel[1])
			)
		)
		
		if doBins do
		(
			binsImage = bitmap imageWidth imageHeight hdr:true
			for p=1 to toKeepBin.count do
			(
				thePixel=([0,toKeepBin[p][1],0,1]) as color
				setPixels binsImage [toKeepBin[p][2][1],toKeepBin[p][2][2]] #(thePixel)
			)
			for p=1 to toDiscardBin.count do
			(
				thePixel=([toDiscardBin[p][1],0,0,1]) as color
				setPixels binsImage [toDiscardBin[p][2][1],toDiscardBin[p][2][2]] #(thePixel)
			)
		)
		
		if displayResults do 
		(
			if doInput do display theRGB caption:"Original Render"
			if doHistory do display historyImage caption:"Histogram-Based Exposure"
			if doUnweighted do display unweightedImage caption:"Non-Weighted Exposure"
			if doBins do display binsImage caption:"Bin Zones"
		)
		if saveResults do 
		(
			if opMode==1 or opMode==3 then
			(
				if doInput do theRGB.filename= outputDir +(getfilenamefile maxfilename)+"_RawInput." + (frameNum.frame as integer) as string + ".exr"
				if doHistory do historyImage.filename= outputDir + (getfilenamefile maxfilename)+"_History." + (frameNum.frame as integer) as string + ".exr"
				if doUnweighted do unweightedImage.filename= outputDir +(getfilenamefile maxfilename)+"_Unweighted." + (frameNum.frame as integer) as string + ".exr"
				if doBins do binsImage.filename=  outputDir + (getfilenamefile maxfilename)+"_Bins." + (frameNum.frame as integer) as string + ".exr"
			)
			else
			(
				if doInput do theRGB.filename= outputDir +"RawInput." + (frameNum.frame as integer) as string + ".exr"
				if doHistory do historyImage.filename= outputDir +"History." + (frameNum.frame as integer) as string + ".exr"
				if doUnweighted do unweightedImage.filename= outputDir +"Unweighted." + (frameNum.frame as integer) as string + ".exr"
				if doBins do binsImage.filename=  outputDir+"Bins." + (frameNum.frame as integer) as string + ".exr"				
			)
			if doInput do save theRGB
			if doHistory do save historyImage
			if doUnweighted do save unweightedImage
			if doBins do save binsImage
			if not displayResults do
			(
				if doInput do free theRGB
				if doHistory do free historyImage
				if doUnweighted do free unweightedImage
				if doBins do free binsImage
			)
		)
	)
	
	fn createOutputFolder =
	(
		case of
		(
			(opMode==1 or opMode==3):
			(			
				outputDir=(maxFilePath + @"exposimeter_renders\"+(getfilenamefile maxfilename)+@"\")
				makeDir outputDir
			)
			(opMode==2 or opMode==4):
			(
				outputDir=((getfilenamepath imagesList[1][1])+ @"exposimeter_renders\"+(getfilenamefile imagesList[1][1])+@"\")
				makeDir outputDir
			)	
			(opMode==5):
			(
				outputDir=((getDir #renderoutput)+ @"\exposimeter_renders\VFB_Dump\")
				makeDir outputDir
			)			
		)		
	)
		
	
	fn createStatsFile =
	(
		statsFileName= outputDir + (getfilenamefile maxfilename) + "_Stats.txt"
		theFileStream=createFile statsFileName
		format "Frame, Unweighted Mult., Histogram-Based Mult., Set History Lenght, Achieved History Lenght, History-Based Mult\n" to:theFileStream
		close theFileStream
	)
	
	fn writeToStatsFile =
	(
		theFileStream = openFile statsFileName mode:"a"
		format "%, %, %, %, %, %\n" frameNum unweightedMultString histogramMultString mcHistoryLenght mcHistoryMults.count finalExposureMultString to:theFileStream
		close theFileStream
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
		opMode=rl.modeDdl.selection
		
		case of
		(
			(opMode==1):
			(
				rl.logChk.checked=rl.saveChk.checked=rl.browseChk.checked=false
				rl.displayChk.checked=true
				rl.goBtn.enabled=on
			)
			(opMode==2):
			(
				rl.logChk.checked=rl.saveChk.checked=rl.browseChk.checked=false
				rl.displayChk.checked=true
				if imagesList.count==1 do rl.goBtn.enabled=on
			)
			(opMode==3):
			(
				Start=rl.startSpn.value as time
				End=rl.endSpn.value as time
				theStep=rl.stepSpn.value as integer
				rl.logChk.checked=rl.saveChk.checked=rl.browseChk.checked=true
				rl.displayChk.checked=false
			)
			(opMode==4):
			(
				rl.logChk.checked=rl.saveChk.checked=rl.browseChk.checked=true
				rl.displayChk.checked=false
				if imagesList.count>1 do rl.goBtn.enabled=on
			)
			(opMode==5):
			(
				rl.logChk.checked=rl.saveChk.checked=rl.browseChk.checked=false
				rl.displayChk.checked=true
				rl.goBtn.enabled=on
			)			
		)
		
		writeLog = rl.logChk.checked
		clampLevel = rl.clampSpn.value
		displayResults = rl.displayChk.checked
		saveResults = rl.saveChk.checked
		historyMult = rl.histSpn.value
		percentExposureMultVariancePerFrame = rl.flickerSpn.value
		browseOutput=rl.browseChk.checked
		hThreshMin=rl.hThreshASpn.value
		hThreshMax=rl.hThreshBSpn.value
		doInput=rl.inputChk.checked
		doBins=rl.binsChk.checked
		doUnweighted=rl.unweightedChk.checked
		doHistory=rl.historyChk.checked
	)	
	
	fn processInputs opMode =
	(
		rl=exposimeterRoll
		writeLog = rl.logChk.checked
		clampLevel = rl.clampSpn.value
		displayResults = rl.displayChk.checked
		saveResults = rl.saveChk.checked
		historyMult = rl.histSpn.value
		percentExposureMultVariancePerFrame = rl.flickerSpn.value
		browseOutput=rl.browseChk.checked
		hThreshMin=rl.hThreshASpn.value
		hThreshMax=rl.hThreshBSpn.value
		doInput=rl.inputChk.checked
		doBins=rl.binsChk.checked
		doUnweighted=rl.unweightedChk.checked
		doHistory=rl.historyChk.checked
		
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
					currFrame= (f-Start).frame as integer
					print ("\n\nOperating on frame " + (sliderTime.frame as integer) as string +"\n")
			
					renderToBuffers 1 (currFrame+1)		-- true : execute render, false: grab the VFB RGB contents (including the CCs)
					collectRenderBuffers()
					getFloatPixelValues true		-- true: initialise arrays, false:refresh the V array from the stored RGB one. Useful after value clamping
					calculateImageData()
					createHistogram clampLevel	-- True: prepass the values to clamp the maximum at 10 times the image average (calculated before the clamping.), False: Leave the input data untouched. Useful only for the binning phase's distribution and the non-weighted exposure multiplier, calculated after clamping.
					doMCCalculations()
					produceFinalImage displayResults saveResults -- True: display created buffers, False: do not display anything. // True: save buffers to disk in a subfolder of the scene file folder. False: Don't save a thing.
					if writeLog do writeToStatsFile()
				)
				if writeLog do try (close theFileStream) catch()				
				if browseOutput do shelllaunch outputDir ""
				clearUp()
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
					createHistogram clampLevel	-- True: prepass the values to clamp the maximum at 10 times the image average (calculated before the clamping.), False: Leave the input data untouched. Useful only for the binning phase's distribution and the non-weighted exposure multiplier, calculated after clamping.
					doMCCalculations()
					produceFinalImage displayResults saveResults -- True: display created buffers, False: do not display anything. // True: save buffers to disk in a subfolder of the scene file folder. False: Don't save a thing.
					if writeLog do writeToStatsFile()
				)
				if writeLog do try (close theFileStream) catch()				
				if browseOutput do shelllaunch outputDir ""
				clearUp()
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
					createHistogram clampLevel	-- True: prepass the values to clamp the maximum at 10 times the image average (calculated before the clamping.), False: Leave the input data untouched. Useful only for the binning phase's distribution and the non-weighted exposure multiplier, calculated after clamping.
					doMCCalculations()
					produceFinalImage displayResults saveResults -- True: display created buffers, False: do not display anything. // True: save buffers to disk in a subfolder of the scene file folder. False: Don't save a thing.
					if writeLog do writeToStatsFile()
				)
				if writeLog do try (close theFileStream) catch()
				if browseOutput do shelllaunch outputDir ""
				clearUp()
			)
			(opMode==4):
			(
				if saveResults or writeLog do createOutputFolder()
				if writeLog do createStatsFile()
				Start=1f
				End=(imagesList.count as time)
				theStep=1
				for f=Start to End by theStep do
				(
					windows.processpostedmessages()
					
					if keyboard.EscPressed do 
					(
						if writeLog then exit with (close theFileStream)
						else exit
					)
							
					frameNum=f
					currFrame= f.frame as integer
					print ("\n\nOperating on frame " + (currFrame) as string +" of the sequence\n")
			
					renderToBuffers 2 (currFrame)		-- true : execute render, false: grab the VFB RGB contents (including the CCs)
					collectRenderBuffers()
					getFloatPixelValues true		-- true: initialise arrays, false:refresh the V array from the stored RGB one. Useful after value clamping
					calculateImageData()
					createHistogram clampLevel	-- True: prepass the values to clamp the maximum at 10 times the image average (calculated before the clamping.), False: Leave the input data untouched. Useful only for the binning phase's distribution and the non-weighted exposure multiplier, calculated after clamping.
					doMCCalculations()
					produceFinalImage displayResults saveResults -- True: display created buffers, False: do not display anything. // True: save buffers to disk in a subfolder of the scene file folder. False: Don't save a thing.
					if writeLog do writeToStatsFile()
				)
				if writeLog do try (close theFileStream) catch()
				if browseOutput do shelllaunch outputDir ""
				clearUp()
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
					calculateImageDataRanges()
					createHistogram clampLevel	-- True: prepass the values to clamp the maximum at 10 times the image average (calculated before the clamping.), False: Leave the input data untouched. Useful only for the binning phase's distribution and the non-weighted exposure multiplier, calculated after clamping.
					createBins()
					calcMCValues()
					produceFinalImage displayResults saveResults -- True: display created buffers, False: do not display anything. // True: save buffers to disk in a subfolder of the scene file folder. False: Don't save a thing.
					if writeLog do writeToStatsFile()
				)
				if writeLog do try (close theFileStream) catch()
				if browseOutput do shelllaunch outputDir ""
				clearUp()
			)
		)
		
	)

	
	rollout exposimeterRoll "History-Based Exposimeter" width:312 height:472
	(
		dropdownList 'modeDdl' "" pos:[120,28] width:176 height:21 items:#("Render Current Frame", "Pick Single Frame", "Render Current Sequence", "Pick Sequence", "Grab VFB Contents") selection:5 toolTip:"Self-Explanatory operation mode for the script." align:#left
		
		button 'fldPickBtn' "Pick a Folder..." pos:[16,80] width:280 height:16 enabled:false toolTip:"Pick a file in a folder to process that entire folder as a single animation sequence." align:#left
		button 'filPickBtn' "Pick a File..." pos:[16,56] width:280 height:16 enabled:false toolTip:"Pick the image to expose." align:#left
		
		spinner 'startSpn' "" pos:[48,104] width:56 height:16 enabled:false range:[0,100000,0] type:#integer toolTip:"Self-Explanatory" align:#left
		spinner 'endSpn' "" pos:[136,104] width:56 height:16 enabled:false range:[0,100000,0] type:#integer toolTip:"Self-Explanatory" align:#left
		spinner 'stepSpn' "" pos:[240,104] width:56 height:16 enabled:false range:[0,100,0] type:#integer toolTip:"Self-Explanatory" align:#left
		spinner 'flickerSpn' "" pos:[240,152] width:56 height:16 range:[0,100,1.5] type:#float toolTip:"When two values are within this percent to one another, the old exposure may be used to prevent unwanted flickering.\nThere is normally no need to change this." align:#left
		spinner 'clampSpn' "" pos:[240,176] width:56 height:16 range:[0,100,0.5] type:#float toolTip:"Where in the Log of the image range should the algorithm cut off overbrights.\nThis is just for image partitioning, no clamping ever happens." align:#left
		spinner 'histSpn' "" pos:[240,200] width:56 height:16 range:[0,100,1] type:#float toolTip:"A higher multiplier will make adaptation to changes take longer, but will provide more stability in difficul lighting conditions.\nThe algorithm already chooses the right length based ond etected image range.\nThere is normally no need to change this." align:#left
		spinner 'hThreshASpn' "" pos:[240,224] width:56 height:16 range:[0,10000,3] type:#float toolTip:"Range threshold for the longest history length.\nThere is normally no need to change this." align:#left
		spinner 'hThreshBSpn' "" pos:[240,248] width:56 height:16 range:[0,10000,15] type:#float toolTip:"Range threshold for the shortest history length.\nThere is normally no need to change this." align:#left	
	
		
		
		checkbox 'logChk' "Write CSV Logfile" pos:[16,384] width:104 height:16 checked:false toolTip:"Writes a log file for debug/analysis purposes.\nInterruption of the script with this option active *may* leave the file locked and open, requiring a max restart." align:#left	
		checkbox 'displayChk' "Display Results" pos:[176,368] width:104 height:16 checked:true toolTip:"Displays the results of the operations: Raw Input, Image Partitioning, Unweighted Exposure, and History-Based Exposure.\nAs the buffers are created anew for each frame of an animation, it's suggested t not use this option when operating on sequences." align:#left
		checkbox 'saveChk' "Save Results" pos:[16,368] width:116 height:16 checked:false toolTip:"Saves the processed images.\nHaving it off will speed up the script, and allow for quicker iteration through long sequences." align:#left
		checkbox 'browseChk' "Browse Output" pos:[176,384] width:116 height:16 checked:false toolTip:"Opens a Windows Explorer window at the output folder." align:#left		
		checkbox 'unweightedChk' "Gen. Unweighted" pos:[176,304] width:116 height:16 checked:false toolTip:"Saves the processed images.\nHaving it off will speed up the script, and allow for quicker iteration through long sequences." align:#left
		checkbox 'binsChk' "Gen. Bins" pos:[16,320] width:116 height:16 checked:false toolTip:"Saves the processed images.\nHaving it off will speed up the script, and allow for quicker iteration through long sequences." align:#left
		checkbox 'inputChk' "Gen. Input Copy" pos:[16,304] width:116 height:16 checked:false toolTip:"Saves the processed images.\nHaving it off will speed up the script, and allow for quicker iteration through long sequences." align:#left
		checkbox 'historyChk' "Gen. History-Based" pos:[176,320] width:116 height:16 checked:false toolTip:"Saves the processed images.\nHaving it off will speed up the script, and allow for quicker iteration through long sequences." align:#left
		
		
		
		button 'goBtn' "Go!" pos:[8,416] width:296 height:48 enabled:false toolTip:"Really?" align:#left
		
		label 'lbl1' "Flicker Guard %:" pos:[16,152] width:216 height:16 align:#left
		label 'lbl2' "Image Range Cutoff:" pos:[16,176] width:112 height:16 align:#left
		label 'lbl3' "Start:" pos:[16,104] width:32 height:16 enabled:true align:#left
		label 'lbl4' "End:" pos:[112,104] width:24 height:16 enabled:true align:#left
		label 'lbl5' "Step:" pos:[208,104] width:32 height:16 enabled:true align:#left	
	
	
		label 'lbl6' "Mode of Operation:" pos:[16,32] width:104 height:16 align:#left
		label 'lbl8' "History Length Bias:" pos:[16,200] width:112 height:16 align:#left
		label 'lbl10' "Long History Threshold:" pos:[16,224] width:112 height:16 align:#left
		label 'lbl11' "Short History Threshold:" pos:[16,248] width:112 height:16 align:#left
		GroupBox 'grp2' "Exposure Controls:" pos:[8,128] width:296 height:144 align:#left
		GroupBox 'grp1' "Mode Controls:" pos:[8,8] width:296 height:120 align:#left
		GroupBox 'grp3' "Extra Settings:" pos:[8,352] width:296 height:56 align:#left
		groupBox 'grp4' "Outputs Creation:" pos:[8,280] width:296 height:64 align:#left		
		

		

		
		
		
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
			imagesList=#()			
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
			imagesList=#()			
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
			clearUp()
			processInputs opMode
		)
	)
	
	createDialog exposimeterRoll


)





