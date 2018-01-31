(
	global expoRoll
	try (closedialog expoRoll) catch()	
	--	expect V-Ray as engine.
	local vr = renderers.current
	-- 	setup the message string as empty
	local theMsg = ""

	--	arrays and dumps used throughout the script
	local 	globalDataArray=#()			--array of computed arrays and key values: #(theRgbPixelsF , theValuePixelsF, theAPixelsF, thePPosPixelsF, theFocusDist, theFocusPPos)
	local	theRgbPixels=#()			--array of the RGB pixels captured by line, 0-255 based
	local	theRgbPixelsF=#()			--array of the RGB pixels as floats, converted from the above
	local	theValuePixelsF=#()			--array of the Value of pixels as floats, derived from the above
	local	theAPixels=#()				--array of the A pixels captured by line, 0-255 based
	local	theAPixelsF=#()				--array of the A pixels' values as floats, converted from the above
	local	thePPosPixels=#()			--array of the pPos pixels captured by line, 0-255 based
	local	thePPosPixelsF=#()			--array of the pPos pixels as floats, converted from the above
	local 	theNormalisedDists=#()		--array of the normalised distances from focus (weights)
	local	theRGB, theA, thePPos, theTL, theRTL, theDiffFlt
	local 	totPixelCount = 0
	--	dubious locals. Verify.	
	local	theFocusDist	=	theFocusDist	=	0.0
	local	finalImageMultiplier 	= 	[1.0,1.0,1.0]
	local	theTargetValue 	= 	1.0	


/*------------------------------------------------------------------------- NEW CODE -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/	
	fn addREs doCleanup =
	(
		re=maxOps.GetCurRenderElementMgr()
		re.RemoveAllRenderElements()
		elemList = #( VRaySamplerInfo, VrayRawLighting, VrayRawTotalLighting, VrayDiffuseFilter)
		elemBaseNamesList=#( "pPos", "vrayRawLighting","vrayRawTotalLighting", "vrayDiffuseFilter")
		for i=1 to elemList.count do
		(
			theElement = (elemList[i]) elementName:elemBaseNamesList[i]
			if i==1 do 
			(
				theElement.type=0
				theElement.coord_system=2
			)
			re.AddRenderElement theElement
			theMsg+="Added a " + theElement.elementName + " Render Element\n"
		)
	)

	fn renderToBuffers =
	(
		addREs true
		max quick render
		theRGB = vrayVFBGetChannelBitmap 1
		theA = vrayVFBGetChannelBitmap 2
		thePPos = vrayVFBGetChannelBitmap 3
		theTL = vrayVFBGetChannelBitmap 4
		theRTL = vrayVFBGetChannelBitmap 5
		theDiffFlt = vrayVFBGetChannelBitmap 6
		totPixelCount=renderWidth*renderHeight
	)

	fn getFloatPixelValues xS yS xE yE =		
	(
		theRgbPixels=#()			--array of the RGB pixels captured by line, 0-255 based
		theRgbPixelsF=#()			--array of the RGB pixels as floats, converted from the above
		theValuePixelsF=#()			--array of the Value of pixels as floats, derived from the above
		theAPixels=#()				--array of the A pixels captured by line, 0-255 based
		theAPixelsF=#()				--array of the A pixels' values as floats, converted from the above
		thePPosPixels=#()			--array of the pPos pixels captured by line, 0-255 based
		thePPosPixelsF=#()			--array of the pPos pixels' values as floats, converted from the above
		theTLPixels=#()				--array of the RawLighting RGB pixels captured by line, 0-255 based
		theTLPixelsF=#()			--array of the RawLighting pixels' values as floats, converted from the above
		theTLVPixelsF=#()			--array of the RawTotalLighting Value of pixels as floats, derived from the above
		theRTLPixels=#()			--array of the RawTotalLighting RGB pixels captured by line, 0-255 based
		theRTLPixelsF=#()			--array of the RawTotalLighting pixels' values as floats, converted from the above
		theRTLVPixelsF=#()			--array of the RawTotalLighting Value of pixels as floats, derived from the above
		theDiffFltPixels=#()
		theDiffFltPixelsF=#()
		
-- 		collect the pixels from the three buffers, by line, to be quick
		for y = yS to yE do
		(
			join theRgbPixels (getPixels theRgb [0,y-1] xE linear:true)
			join theAPixels (getPixels theA [0,y-1] xE linear:true)
			join thePPosPixels (getPixels thePPos [0,y-1] xE linear:true)
			join theTLPixels (getPixels theTL [0,y-1] xE linear:true)
			join theRTLPixels (getPixels theRTL [0,y-1] xE linear:true)
			join theDiffFltPixels (getPixels theDiffFlt [0,y-1] xE linear:true)			
		)
		
-- 		convert the buffers into floats, performing alpha masking if needed

		for p=1 to totPixelCount do
		(
			thePoint4=(theRgbPixels[p] as point4)
			theCol = [thePoint4[1],thePoint4[2],thePoint4[3]]
			append theRgbPixelsF theCol
		
			theNormalisedCol= normalize theCol
			theNormalFactor = theCol/TheNormalisedCol
			theNormalValue = (theNormalisedCol as color).v / 255.0
			theRealValue = theNormalValue * theNormalFactor[1]
			append theValuePixelsF theRealValue
		
			append theAPixelsF (theAPixels[p] as point4)
			append thePPosPixelsF -((thePPosPixels[p] as point4))

			thePoint4=(theTLPixels[p] as point4)
			theCol = [thePoint4[1],thePoint4[2],thePoint4[3]]
			append theTLPixelsF theCol
	
			theNormalisedCol= normalize theCol
			theNormalFactor = theCol/TheNormalisedCol
			theNormalValue = (theNormalisedCol as color).v / 255.0
			theRealValue = theNormalValue * theNormalFactor[1]
			append theTLVPixelsF theRealValue

			thePoint4=(theRTLPixels[p] as point4)
			theCol = [thePoint4[1],thePoint4[2],thePoint4[3]]
			append theRTLPixelsF theCol

			theNormalisedCol= normalize theCol
			theNormalFactor = theCol/TheNormalisedCol
			theNormalValue = (theNormalisedCol as color).v / 255.0
			theRealValue = theNormalValue * theNormalFactor[1]
			append theRTLVPixelsF theRealValue
	
			thePoint4=(theDiffFltPixels[p] as point4)
			theCol = [thePoint4[1],thePoint4[2],thePoint4[3]]
			append theDiffFltPixelsF theCol
	
		)

		midImagePixel=[(renderwidth/2)-1, (renderheight/2)-1]
		theFocusRGB=(getPixels theRgb midImagePixel 1 linear:true)[1] as point4
		tempPPos=-(getPixels thePPos midImagePixel 1 linear:true)[1] as point4
		theFocusPPos=[ tempPPos[1], tempPPos[2], tempPPos[3] ] 
		print ("theFocusPPos: " + theFocusPPos as string)
		theFocusDist = (distance theFocusPPos [0,0,0])
		print ("theFocusAbsDist: " + theFocusDist as string)
		theFocusZDist= theFocusPPos.z
		print ("theZOnlyDistance: " + theFocusZDist as string)
		
		globalDataArray = #(theRgbPixelsF , theValuePixelsF, theAPixelsF, thePPosPixelsF, theFocusPPos, theFocusDist, theTLPixelsF, theTLVPixelsF, theRTLPixelsF, theRTLVPixelsF, theDiffFltPixelsF)
		
		free theRGB 
		free theA 
		free thePPos 
		free theRTL
-- 		theRgbPixels=#()			--array of the RGB pixels captured by line, 0-255 based
-- 		theRgbPixelsF=#()			--array of the RGB pixels as floats, converted from the above
-- 		theValuePixelsF=#()			--array of the Value of pixels as floats, derived from the above
-- 		theAPixels=#()				--array of the A pixels captured by line, 0-255 based
-- 		theAPixelsF=#()				--array of the A pixels' values as floats, converted from the above
-- 		thePPosPixels=#()			--array of the pPos pixels captured by line, 0-255 based
-- 		thePPosPixelsF=#()
		
		return globalDataArray
	)

	fn mapFocusDistances=		
	(
		theDists=#()
		theNormalisedDists=#()
		distsBuffer=bitmap renderwidth renderheight hdr:true
		
		for p=1 to globalDataArray[4].count do 						--thePPosPixelsF
		(
			-- distance (pPos * Alpha) to pPosFocus
			if (globalDataArray[3][p] as color).v == 255 then 		--theAPixelsF
			( 
				append theDists (distance (globalDataArray[4][p] as point3) (globalDataArray[5] as point3))		--distance each of the thePPosPixelsF to theFocusPPos
			)
			else
			(
				append theDists 0.0
			)
		)
		
		newArray = deepCopy theDists
		maxDist = aMax newArray
		minDist = aMin newArray
		distDelta = (maxDist-minDist)
		print ("maxDist: " + maxDist as string)
		print ("minDist: " + minDist as string)
		print ("distDelta: " + distDelta as string)
		 
		for d=1 to theDists.count do
		(
			append theNormalisedDists (theDists[d]/distDelta)
		)
		
		distsAvg=0.0
		for y=1 to renderHeight do
		(
			for x = 1 to renderwidth do
			(
				theCounter=x+((y-1)*renderwidth)
				
				theDist=((1.0-(theNormalisedDists[theCounter]))*((globalDataArray[3][theCounter] as color).v/255.0))
				distsAvg+=theDist
				setPixels  distsBuffer [x-1,y-1] #([theDist,theDist,theDist,1] as color) 
			)
		)
		distsAvg/=totPixelCount
		append globalDataArray theNormalisedDists
		append globalDataArray distsAvg
		print distsAvg
		display distsBuffer caption:"Normalised Distance from Center Focus Point"
	)	


	
	fn calculateWeightedValues =
	(
		theWeightedValueSum=0.0
		theCounter=0
		for p=1 to totPixelCount do
		( 
-- 			theRawPixel=		globalDataArray[1][p]			--point4
-- 			theRawValue= 		globalDataArray[2][p]			--float
			theRawAlpha= 		globalDataArray[3][p][1]		--point4 to float -> point4[1]
			theTLPixel= 		globalDataArray[7][p]			--point4
-- 			theTLValue= 		globalDataArray[8][p]			--float
-- 			theFocusWeight= 	globalDataArray[12][p]			--float
-- 			theFocusAvgWeight=	globalDataArray[13]				--single float
			
			if theRawAlpha == 1.0 do
			(
				theWeightedValueSum += theTLPixel
				theCounter+=1
			)
			
		)
		print "theWeightedValueSum"
		print theWeightedValueSum
		print "theCounter"
		print theCounter
		theWeightedAverage=theWeightedValueSum/theCounter
		print theWeightedAverage
		tempArray=#()
		for i=1 to 3 do append tempArray theWeightedAverage[i]
		theV = amax tempArray
		finalImageMultiplier=theV/theWeightedAverage
		print finalImageMultiplier
	)
	
	fn produceWBdLighting =
	(
		correctedRTL = bitmap renderwidth renderheight hdr:true
		rebuiltRender = bitmap renderwidth renderheight hdr:true
		for y=1 to renderHeight do
		(
			for x = 1 to renderwidth do
			(
				theCounter=		x+((y-1)*renderwidth)
				theRTLPixel= 	globalDataArray[9][theCounter] 
				theRawAlpha=	globalDataArray[3][theCounter][1]
				theDFPixel=		globalDataArray[11][theCounter] as point3
				
				theWBdRTLPixel=theRTLPixel*finalImageMultiplier
				theRebuiltPixel=theDFPixel*theWBdRTLPixel
				setPixels  correctedRTL [x-1,y-1] #((theWBdRTLPixel as point4)as color) 
				setPixels  rebuiltRender [x-1,y-1] #((theRebuiltPixel as point4)as color) 
				
			)
		)
		
		display correctedRTL	caption:"White-Balanced rawTotalLighting"
		display rebuiltRender	caption:"RebuiltRender (diffFlt * rawLight)"
	)
	
	
	renderToBuffers()
	print ("Total image Pixels (MPx): " + (totPixelCount as float / 1000000.0) as string)
	st=timestamp()
	getFloatPixelValues 0 0 renderWidth renderHeight
	theTimer=timestamp()-st
	print ("pixels gathered and converted in " +  (theTimer/1000.0)as string + " s." )
	print ("Milliseconds per pixel: " + ( theTimer as float/totPixelCount)as string )
		
	
-- 	st=timestamp()	
-- 	mapFocusDistances()
-- 	theTimer=timestamp()-st
-- 	print ("Distance map created in " + (theTimer/1000.0) as string + " s.")
-- 	print ("Milliseconds per pixel: " + ( theTimer as float/totPixelCount) as string )
-- 	
	st=timestamp()	
	calculateWeightedValues()
	theTimer=timestamp()-st
	print ("Weighted Multiplier calculated in " + (theTimer/1000.0) as string + " s.")
	print ("Milliseconds per pixel: " + ( theTimer as float/totPixelCount) as string )
	
	st=timestamp()	
	produceWBdLighting()
	theTimer=timestamp()-st
	print ("White-Balanced the RawLighting in " + (theTimer/1000.0) as string + " s.")
	print ("Milliseconds per pixel: " + ( theTimer as float/totPixelCount) as string )	


)