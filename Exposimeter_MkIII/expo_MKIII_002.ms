(
	global expoRoll
	try (closedialog expoRoll) catch()	
	--	expect V-Ray as engine.
	local vr = renderers.current
	-- 	setup the message string as empty
	local theMsg = ""

	--	arrays and dumps used throughout the script
	
	local	theRgbPixels=#()			--array of the RGB pixels captured by line, 0-255 based
	local	theRgbPixelsF=#()			--array of the RGB pixels as floats, converted from the above
	local	theValuePixelsF=#()			--array of the Value of pixels as floats, derived from the above
	local	theAPixels=#()				--array of the A pixels captured by line, 0-255 based
	local	theAPixelsF=#()				--array of the A pixels' values as floats, converted from the above
	local	thePPosPixels=#()			--array of the pPos pixels captured by line, 0-255 based
	local	thePPosPixelsF=#()			--array of the pPos pixels' values as floats, converted from the above
	local	theTLPixels=#()				--array of the RawLighting RGB pixels captured by line, 0-255 based
	local	theTLPixelsF=#()			--array of the RawLighting pixels' values as floats, converted from the above
	local	theTLVPixelsF=#()			--array of the RawTotalLighting Value of pixels as floats, derived from the above
	local	theRTLPixels=#()			--array of the RawTotalLighting RGB pixels captured by line, 0-255 based
	local	theRTLPixelsF=#()			--array of the RawTotalLighting pixels' values as floats, converted from the above
	local	theRTLVPixelsF=#()			--array of the RawTotalLighting Value of pixels as floats, derived from the above
	local	theDiffFltPixels=#()
	local	theDiffFltPixelsF=#()
	local	theRawRefPixels=#()
	local	theRawRefPixelsF=#()
	local	theSpecPixels=#()
	local	theSpecPixelsF=#()
	local	theRefFltPixels=#()
	local	theRefFltPixelsF=#()
	
	local 	theNormalisedDists=#()		--array of the normalised distances from focus (weights)

	local	theRGB, theA, thePPos, theTL, theRTL, theDiffFlt, theRawRef, theSpec, theRefFlt		--Image buffers for REs

	local 	totPixelCount	= 		0
	local	theFocusDist	=		0.0
	local 	theFocusPPos	=		[0.0,0.0,0.0]
	local	WBMultiplier 	= 		[1.0,1.0,1.0]
	
	local	exposureMultiplier 	=  	1.0
	local	theAnchor 	= 			1.0	


/*------------------------------------------------------------------------- NEW CODE -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/	
	fn addREs doCleanup =
	(
		re=maxOps.GetCurRenderElementMgr()
		re.RemoveAllRenderElements()
		elemList = #( VRaySamplerInfo, VrayRawLighting, VrayRawTotalLighting, VrayDiffuseFilter, vrayRawReflection, vraySpecular, vrayReflectionFilter)
		elemBaseNamesList=#( "pPos", "vrayRawLighting","vrayRawTotalLighting", "vrayDiffuseFilter", "vrayRawReflection", "vraySpecular", "vrayReflectionFilter")
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
		theRawRef = vrayVFBGetChannelBitmap 7
		theSpec = vrayVFBGetChannelBitmap 8
		theRefFlt = vrayVFBGetChannelBitmap 9
		
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
		theRTLPixels=#()			--array of the RawTotalLighting RGB pixels captured by line, 0-255 based
		theRTLPixelsF=#()			--array of the RawTotalLighting pixels' values as floats, converted from the above
		theRTLVPixelsF=#()			--array of the RawTotalLighting Value of pixels as floats, derived from the above
		theDiffFltPixels=#()
		theDiffFltPixelsF=#()
		theRawRefPixels=#()
		theRawRefPixelsF=#()
		theSpecPixels=#()
		theSpecPixelsF=#()
		theRefFltPixels=#()
		theRefFltPixelsF=#()
		
		
		
		WBdImageArray=#()					--Array containing the pixels for the White-Balanced reconstructed Image
		
-- 		collect the pixels from the three buffers, by line, to be quick
		for y = yS to yE do
		(
			join theRgbPixels (getPixels theRgb [0,y-1] xE linear:true)
			join theAPixels (getPixels theA [0,y-1] xE linear:true)
			join thePPosPixels (getPixels thePPos [0,y-1] xE linear:true)
			join theTLPixels (getPixels theTL [0,y-1] xE linear:true)
			join theRTLPixels (getPixels theRTL [0,y-1] xE linear:true)
			join theDiffFltPixels (getPixels theDiffFlt [0,y-1] xE linear:true)	
			join theRawRefPixels (getPixels theRawRef [0,y-1] xE linear:true)
			join theSpecPixels (getPixels theSpec [0,y-1] xE linear:true)
			join theRefFltPixels (getPixels theRefFlt [0,y-1] xE linear:true)	
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
			
			thePoint4=(theRawRefPixels[p] as point4)
			theCol = [thePoint4[1],thePoint4[2],thePoint4[3]]
			append theRawRefPixelsF theCol	

			thePoint4=(theSpecPixels[p] as point4)
			theCol = [thePoint4[1],thePoint4[2],thePoint4[3]]
			append theSpecPixelsF theCol	
			
			thePoint4=(theRefFltPixels[p] as point4)
			theCol = [thePoint4[1],thePoint4[2],thePoint4[3]]
			append theRefFltPixelsF theCol	
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
		
		
		free theRGB 
		free theA 
		free thePPos 
		free theRTL
		free theTL
		free theDiffFlt
		free theRawRef
		free theSpec
		free theRefFlt	
		
	)

	fn checkArrayValues =
	(
		for midPixel = 1 to totPixelCount by 1000 do
		(
			print 	midPixel
			print 	theRgbPixelsF[midPixel]
			print 	theValuePixelsF[midPixel]
			print 	thePPosPixelsF[midPixel]
			print 	theTLPixelsF[midPixel]
			print 	theRTLPixelsF[midPixel]
			print 	theRTLVPixelsF[midPixel]
			print 	theDiffFltPixelsF[midPixel]
			print 	theRawRefPixelsF[midPixel]
			print 	theSpecPixelsF[midPixel]
			print 	theRefFltPixelsF[midPixel]
			print	"----------------------------------"
		)

	)
	
	fn mapFocusDistances displayWeightsBitmap=		
	(
		theDists=#()
		theNormalisedDists=#()

		
		for p=1 to thePPosPixelsF.count do 						--thePPosPixelsF
		(
			-- distance (pPos * Alpha) to pPosFocus
			if (theAPixelsF[p] as color).v == 255 then 		--theAPixelsF
			( 
				append theDists (distance (thePPosPixelsF[p] as point3) (theFocusPPos as point3))		--distance each of the thePPosPixelsF to theFocusPPos
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
			theDist=(1.0-(theDists[d]/distDelta))
			append theNormalisedDists theDist
		)

		if displayWeightsBitmap do
		(
			distsLine=#()
			distsBuffer=bitmap renderwidth renderheight hdr:true
		-- create weights bitmap
			for y=1 to renderHeight do
			(
				for x = 1 to renderwidth do
				(
					theCounter=x+((y-1)*renderwidth)
					theDist=((theNormalisedDists[theCounter])*((theAPixelsF[theCounter] as color).v/255.0))
					join distsLine ([theDist,theDist,theDist,1] as color)
				)
				setPixels  distsBuffer [0,y-1] distsLine
			)
			display distsBuffer caption:"Normalised Distance from Center Focus Point"
		)
	)	


	
	fn calculateWBValues =
	(
		theWBSum=0.0
-- 		theWeightedValueSum=0.0
		theCounter=0
		for p=1 to totPixelCount do
		( 
			theRawAlpha= 	theAPixelsF[p][1]		--point4 to float -> point4[1]
			theTLPixel= 	theTLPixelsF[p]			--point4
-- 			theRTLVPixel= 	theRTLVPixelsF[p]			--float
-- 			theValuePixel=	theValuePixelsF[p]			--float			
--  			theFocusWeight= theNormalisedDists[p]			--float
-- 			theFocusAvgWeight=	globalDataArray[13]					--single float
			
			/* 
			Weighted sum is  finalPx = raw * 1-distance weight + exposed * distanceweight
			*/
			if theRawAlpha == 1.0 do
			(
				theWBSum += theTLPixel
-- 				theWeightedValueSum += theRTLVPixel * theFocusWeight + theRTLVPixel * (1.0-theFocusWeight)
				theCounter+=1
			)
		)
		
		print "theWBSum"
		print theWBSum
		print "theWeightedValueSum"
		print theWeightedValueSum
		print "theCounter"
		print theCounter

		
		-- White Balance
		theWBAverage=theWBSum/theCounter
		print "theWBAverage"
		print theWBAverage
		tempArray=#()
		for i=1 to 3 do append tempArray theWBAverage[i]
		theV = amax tempArray
		WBMultiplier=theV/theWBAverage
		print "WBMultiplier"
		print WBMultiplier
		
		/*
		--Exposure
		theWeightedAverage=theWeightedValueSum/theCounter
		print "theWeightedAverage"
		print theWeightedAverage

		exposureMultiplier=theAnchor/theWeightedAverage
		print "exposureMultiplier"
		print exposureMultiplier
		*/
	)
	
	fn calculateExposedValues =
	(
		theCounter=0
		theDiffFltAvg=[0.0,0.0,0.0]
		theDiffFltAvgV=0.0
		theTRLVAvg=0.0

		for p=1 to totPixelCount do
		( 
			theRawAlpha= 		theAPixelsF[p][1]		--point4 to float -> point4[1]
			theDiffFltPixel=	theDiffFltPixelsF[p] 
			theRTLVPixel=		theRTLVPixelsF[p]
			
			if theRawAlpha == 1.0 do
			(
				--Calculate DiffFlt Average
				theDiffFltAvg += theDiffFltPixel
				theRTLVAvg+= theRTLVPixel
				theCounter+=1
			)
		)
		
		
		theDiffFltAvg/=theCounter
		tempArray=#()
		for i = 1 to 3 do append tempArray theDiffFltAvg[i]
		theDiffFltAvgV=amax tempArray	
		theRTLVAvg/=theCounter
		
		print "theDiffFltAvg"
		print theDiffFltAvg
		print "theDiffFltAvgV"
		print theDiffFltAvgV		
		print "theTRLVAvg"
		print theTRLVAvg

		
		for p=1 to totPixelCount do
		( 
			theRawAlpha= 		theAPixelsF[p][1]		--point4 to float -> point4[1]
			theDiffFltPixel=	theDiffFltPixelsF[theCounter] 

			if theRawAlpha == 1.0 do
			(
				theDiffFltAvg += theDiffFltPixel
				theCounter+=1
			)
		)		



	)	
	
	fn produceWBdImage =
	(
		WBdImageArray=#()
		
		WBdImage = bitmap renderwidth renderheight hdr:true
		WBdTotRef = bitmap renderwidth renderheight hdr:true
		WBdTotDiffuse = bitmap renderwidth renderheight hdr:true
		WBdRTLLine=#()
		for y=1 to renderHeight do
		(
			for x = 1 to renderwidth do
			(

				theCounter=		x+((y-1)*renderwidth)
				--grab the channels' pixels in their buffers, to operate on
				theDiffFltPixel=	theDiffFltPixelsF[theCounter] 
				theRTLPixel= 		theRTLPixelsF[theCounter] 
				theRawRefPixel=		theRawRefPixelsF[theCounter] 
				theSpecPixel=		theSpecPixelsF[theCounter] 
				theRefFltPixel=		theRefFltPixelsF[theCounter] 
				theRawSpecPixel=	if theRefFltPixel != [0.0,0.0,0.0] then theSpecPixel/theRefFltPixel else theSpecPixel
				
				
				
				/*Image Operations*/
				theWBdRTLPixel = (theRTLPixel*WBMultiplier)
				theWBdTotRefPixel = (theRawRefPixel+theRawSpecPixel)*WBMultiplier
				
				theWBdPixel=(theDiffFltPixel * theWBdRTLPixel )	+ (theRefFltPixel * theWBdTotRefPixel)
				theWBdPixel=theWBdPixel as point4
				append WBdImageArray theWBdPixel
				theWBdPixel=theWBdPixel as color				
				setPixels  WBdImage [x-1,y-1] #(theWBdPixel)
				setPixels  WBdTotRef [x-1,y-1] #(theWBdTotRefPixel)
				setPixels  WBdTotDiffuse [x-1,y-1] #(theWBdRTLPixel)
				
				
			)
		)
		
		display WBdImage caption:"White-Balanced Whole Composite"
		display WBdTotRef caption:"White-Balanced Total Raw Reflection"
		display WBdTotDiffuse caption:"White-Balanced Diffuse * TRL"
		
	)
	
	
	renderToBuffers()
	print ("Total image Pixels (MPx): " + (totPixelCount as float / 1000000.0) as string)
	st=timestamp()
	getFloatPixelValues 0 0 renderWidth renderHeight
	theTimer=timestamp()-st
	print ("pixels gathered and converted in " +  (theTimer/1000.0)as string + " s." )
	print ("Milliseconds per pixel: " + ( theTimer as float/totPixelCount)as string )
		
-- 	checkArrayValues()
	

-- 	st=timestamp()	
-- 	mapFocusDistances false
-- 	theTimer=timestamp()-st
-- 	print ("Distance map created in " + (theTimer/1000.0) as string + " s.")
-- 	print ("Milliseconds per pixel: " + ( theTimer as float/totPixelCount) as string )
-- 	
-- 	st=timestamp()	
-- 	calculateWBValues()
-- 	theTimer=timestamp()-st
-- 	print ("White Balance calculated in " + (theTimer/1000.0) as string + " s.")
-- 	print ("Milliseconds per pixel: " + ( theTimer as float/totPixelCount) as string )
	
	st=timestamp()	
	calculateExposedValues()
	theTimer=timestamp()-st
	print ("Exposure Multiplier calculated in " + (theTimer/1000.0) as string + " s.")
	print ("Milliseconds per pixel: " + ( theTimer as float/totPixelCount) as string )
	
-- 	st=timestamp()	
-- 	produceWBdImage()
-- 	theTimer=timestamp()-st
-- 	print ("White-Balanced the RawLighting in " + (theTimer/1000.0) as string + " s.")
-- 	print ("Milliseconds per pixel: " + ( theTimer as float/totPixelCount) as string )	

)