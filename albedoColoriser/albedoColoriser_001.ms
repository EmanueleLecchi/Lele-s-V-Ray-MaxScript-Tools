(
	/*
	Abedo Coloriser: Add diffFlt and ReflFlt to the RE set, add the values, colorise the low and high pixels.
	*/
	
	global albedoMapperRoll
	try (destroyDialog albedoMapperRoll) catch()
	
	local vr=if (renderers.current.classID as string == "#(1941615238L, 2012806412L)") then renderers.current else undefined
		
	--Bitmap Buffers
	local rgbBuffer=diffFltBuffer=reflFltBuffer=albedoBuffer=colorisedAlbedoBuffer=colorisedRGBBuffer=undefined
	--Rich Pixel data for each buffer: #(color,value,[x,y])
	local rgbPixels=#()
	local diffFltPixels=#()
	local reflFltPixels=#()
	local albedoPixels=#()
	local lowBin = #()
	local highBin = #()
	local colorisedPixels=#()
	--message string
	local theMsg=""
	--cross-fn variables
	local allSet=false  --are we ready to render to the V-Ray VFB in RAM?
	local imageWidth=0
	local imageHeight=0
	
	--generic fns
	fn logBaseNum base num =
	(
		theLog = log num / log base
		theLog
	)
	
	fn lerp theA theB theFactor=
	(
		theResult=theA * theFactor + theB * (1.0-theFactor)
		theResult
	)
	--specific fns
	fn addREs =
	(
		print "addREs"
		re=maxOps.GetCurRenderElementMgr()
		elemList = #( VrayDiffuseFilter, VrayReflectionFilter)
		elemBaseNamesList=#("amDiffFlt", "amReflFlt")
		for r=1 to elemBaseNamesList.count do 
		(		
			for i=((re.NumRenderElements())-1) to 0 by -1 where ((re.GetRenderElement i).elementName == elemBaseNamesList[r]) do re.removeRenderElement (re.GetRenderElement i)
		)
		
		for r=1 to elemList.count do 
		(
			el = (elemList[r]) elementName:elemBaseNamesList[r]
			allSet = (re.AddRenderElement el)
			if allSet do print ("Added a " + el.elementName + " Render Element\n")
		)
		renderSceneDialog.commit()
	)

	fn activateVrayVfb =
	(
		print "activateVrayVfb"
		if vr!= undefined then
		(
			vr.output_on=true
			vr.output_useram=true
			allSet = allSet and vr.output_on and vr.output_useram
		)
		else 
		(
			allSet=false
		)
	)
	
	fn renderToVfb =
	(
		print "renderToVfb"
		if allSet do
		(
			max quick render
		)
	)
	
	fn getVFBRE REName =
	(
		print ( "getVFBRE " + REName)
		tempBmp=bitmap 1 1 hdr:true gamma:.4545
		chanNames=(vfbControl #getchannelnames)[1]
		for i=1 to chanNames.count where chanNames[i]==REName do tempBmp= vrayVFBGetChannelBitmap (i)
		
		imageWidth=tempBmp.width
		imageHeight=tempBmp.Height
		tempBmp
	)
	
	fn collectRenderBuffers inputBuffer=
	(
		print "Collecting Pixels From Render Buffers"
-- 		outputBuffer=bitmap imageWidth imageHeight hdr:true --gamma:.4545
		pixelArray=#()
		maxVPixel=0.0
		for y=1 to imageHeight do
		(
			for x=1 to imageWidth do
			(
				windows.processpostedmessages()
				coords= [x-1,y-1]
				thePixel=(getPixels inputBuffer coords 1 linear:true)[1]
				theFPixel=((thePixel as point4) as point3)
				theFPixelA=#(theFPixel[1],theFPixel[2],theFPixel[3])
				theVPixel= amax theFPixelA
				append pixelArray #(theFPixel,theVPixel,(coords))
				if theVPixel > maxVPixel do maxVPixel = theVPixel
-- 				setPixels outputBuffer coords #(thePixel)
			)
		)
-- 		display outputBuffer
		print maxVPixel
		pixelArray
	)

	fn sumFiltersToAlbedo =
	(
		print "sumFiltersToAlbedo"
		albedoBuffer=bitmap imageWidth imageHeight hdr:true
		tempPixels=#()
		for p=1 to diffFltPixels.count do
		(
			windows.processpostedmessages()
			tempPixels[p]=#((diffFltPixels[p][1]+reflFltPixels[p][1]),(diffFltPixels[p][2]+reflFltPixels[p][2]),diffFltPixels[p][3])
			albedoPixels[p]=tempPixels[p]
			setPixels albedoBuffer albedoPixels[p][3] #(((albedoPixels[p][1]) as point4) as color)
		)
		tempPixels=#()
		display albedoBuffer
	)
	
	fn coloriseAlbedo albedoPixels lowThreshold highThreshold lowFilterColor highFilterColor=
	(
		print "coloriseAlbedo"
		lowFilterColor=(lowFilterColor as point4) as point3
		highFilterColor=(highFilterColor as point4) as point3
		colorisedAlbedoBuffer=bitmap imageWidth imageHeight hdr:true
		tempPixels=#()
		print albedoPixels[212*281]
		for p=1 to albedoPixels.count do
		(
			windows.processpostedmessages()
			case of
			(
				(albedoPixels[p][2] <= lowThreshold) : (albedoPixels[p][1] = lowFilterColor)
				(albedoPixels[p][2] >= highThreshold) : (albedoPixels[p][1] = highFilterColor)
			)

			setPixels colorisedAlbedoBuffer albedoPixels[p][3] #(((albedoPixels[p][1]) as point4) as color)
		)
		display colorisedAlbedoBuffer
	)
	
	fn coloriseRGB rgbPixels albedoPixels lowThreshold highThreshold lowFilterColor highFilterColor=
	(
		print "coloriseAlbedo"
		lowFilterColor=(lowFilterColor as point4) as point3
		highFilterColor=(highFilterColor as point4) as point3
		colorisedRGBBuffer=bitmap imageWidth imageHeight hdr:true
		tempPixels=#()
-- 		print albedoPixels[212*281]
		for p=1 to albedoPixels.count do
		(
			windows.processpostedmessages()
			case of
			(
				(albedoPixels[p][2] <= lowThreshold) : (rgbPixels[p][1] = lowFilterColor)
				(albedoPixels[p][2] >= highThreshold) : (rgbPixels[p][1] = highFilterColor)
			)

			setPixels colorisedRGBBuffer albedoPixels[p][3] #(((rgbPixels[p][1]) as point4) as color)
		)
		display colorisedRGBBuffer
	)
	
	fn main =
	(
		print "main"
		addREs()
		activateVrayVFB()
		renderToVfb()
		RGBBuffer = getVFBRE "RGB color"
		diffFltBuffer = getVFBRE "amDiffFlt"
		reflFltBuffer = getVFBRE "amReflFlt"
		rgbPixels = collectRenderBuffers RGBBuffer
		diffFltPixels = collectRenderBuffers diffFltBuffer
		reflFltPixels = collectRenderBuffers reflFltBuffer
		sumFiltersToAlbedo()
		coloriseAlbedo albedoPixels 0.1 0.9 yellow red
		coloriseRGB rgbPixels albedoPixels 0.1 0.9 yellow red
	)

	main()
)




