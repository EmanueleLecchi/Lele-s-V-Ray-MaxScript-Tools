(
	global sLMRoll
	try (destroyDialog sLMRoll) catch()
	if (heapFree/1024.0 < 512000.0) do heapsize += (512000*1024)-heapFree
		
-- 	swf=dotNetObject "System.Windows.Forms"
	local numLayers=rollHeight=0
	local bName=""
	local sLMrc
	local rem=maxOps.GetCurRenderElementMgr() 
	local theREs=#()
	local chanNames=undefined
	local layerNames=#()
	local layerName = ""
	local tempFolder=""
	
	global wipeTemps
	global collectFullLightSelects
	
	fn makeTempFolder =
	(
		tempFolder=(getDir #temp ) + @"\sLMTemp\" --+ (((random 12345 99999) as integer) as string) + @"\"
		makeDir tempFolder
	)
	
	fn wipeTemps =
	(
		theDirs= #(tempFolder)
		for d in theDirs do
		(
			for f in (getFiles (d+"*.exr")) do deleteFile f
			str=(filterstring d @"\")[(filterstring d @"\").count]
			str = (@"rmDir " + str )
-- 			print str
			hiddenDosCommand str startpath:(getDir #temp ) 
		)
	)
	
	fn genFileName baseName REName =
	(
		layerName = (tempFolder+baseName+".exr")
		append layerNames #(REName, (tempFolder+baseName+"."+REName+".exr"))
		layerName
	)
	
	fn collectFullLightSelects = 
	(
		makeTempFolder()
		layerNames=#()
		
		chanNames=(vfbControl #getchannelnames)[1]
		theLSs=	for re=1 to chanNames.count where (matchpattern chanNames[re] pattern:"VRLS_*")  collect #(chanNames[re],re-1)
		numLayers=theLSs.count
		
		for l in theLSs do
		(
			vfbControl #setChannel l[2]
			fileName=(genFileName "VRLS" l[1])
			vfbControl #saveImage fileName
		)
		vfbControl #setChannel 0
		layerNames
	)

	fn virtualiseBitmap theBitmap =
	(
		theRawPixels=#()
		bH=theBitmap.height
		bW=theBitmap.width
		counter=0
		for y=1 to bH do
		(
			windows.processpostedmessages()
-- 			grab a line of pixels
			theRawPixelsLine = (getpixels theBitmap [0,y-1] bW linear:true) 
			theRawPixelsLineArray=#()
			for x=1 to theRawPixelsLine.count do 
			(	
				--arrray needed to work arround a maxscript bug with the .V of hdr colors
				thePixA=#()
				--grab a pixel from the line as point4 set of floats
				thePix=theRawPixelsLine[x] as point4
				--insert it in the temp array, find the max, storre it as V and LogV
				for i=1 to 3 do thePixA[i] = thePix[i]
				theV= ((amax thePixA))
				append theRawPixelsLineArray #([thePix[1],thePix[2],thePix[3],thePix[4]], theV)		--X,Y, Color as point4, Value (max(col)) as float, original Arrray position
				
			)
			append theRawPixels theRawPixelsLineArray
			if mod y (bH as float/10.0) ==0 do 
			( 
				counter+=10
				print ("Read " + counter as string + @"% out of " + (bH) as string + " lines")
			)

		)
		theRawPixels
	)	
	
	fn addVBitmaps vbm1 vbm2 =
	(
		outVBitmap=deepCopy vbm1 
		for y=1 to vbm1.count do
		(
			for x=1 to vbm1[y].count do
			(
				outVBitmap[y][x][1]=vbm1[y][x][1]+vbm2[y][x][1]		--Color
				outVBitmap[y][x][2]=vbm1[y][x][2]+vbm2[y][x][2]		--Value
			)
		)
		outVBitmap
	)
	
	fn genBitmap vbm1 =
	(
		outBitmap = bitmap vbm1[1].count vbm1.count color:black hdr:true
		for y=1 to vbm1.count do
		(
			pixelsLine=#()
			for x=1 to vbm1[y].count do
			(
				append pixelsLine (vbm1[y][x][1] as color)
-- 				setPixels outBitmap [(x-1), (y-1)] #(vbm1[y][x][1] as color)
			)
			setPixels outBitmap [0, (y-1)] pixelsLine
		)
		display outBitmap
	)	
	
	fn initPrecomp =
	(
		
		print "|----> 1/3: Virtualising Bitmaps..."
		ts2=timestamp()
		theREs=#()
		for f=1 to layerNames.count do
		(
			append theREs #(layerNames[f][1], virtualiseBitmap (openbitmap layerNames[f][2] hdr:on))
		)
		print ("|----> 1/3: It took " + ((timestamp()-ts2)/1000.0) as string + "s. to Virtualise "+ layerNames.count as string + " REs")
		
		print "|----> 2/3: Adding Virtual Bitmaps..."
		ts2=timestamp()
		theVbm=deepcopy theREs[1][2]
		for y=1 to theVbm.count do			-- this is Y
		(
			for x=1 to theVbm[1].count do
			(
				theVbm[y][x]=#([0.0,0.0,0.0,0.0],0.0) 
			)
		)
		for f=1 to theREs.count do
		(
			theVbm=addVBitmaps theVbm theREs[f][2]
		)
		print ("|----> 2/3: It took " + ((timestamp()-ts2)/1000.0) as string + "s. to Add the Virtual Bitmaps together")
		
		print "|----> 3/3: Creating a Max Bitmap from the Virtual one..."
		ts2=timestamp()
		genBitmap theVbm
		print ("|----> 3/3: It took " + ((timestamp()-ts2)/1000.0) as string + "s. to turn the Virtual Bitmap into a Max Bitmap")
		
-- 		print theVbm[1]
	)

	fn createDynamicDialog layerNames=
	(
		rollHeight=(64+layerNames.count*76)
		sLMrc = rolloutCreator "sLMRoll" "Simple Light Mixer V. 0.001" width:384 height:rollHeight

		sLMrc.begin()
-- 		sLMrc.addHandler #sLMRoll #open codeStr:""
		sLMrc.addHandler #sLMRoll #close codeStr:"wipeTemps()"
		
-- 		sLMrc.addControl #timer #invisibleTimer "" paramStr:"interval:0 active:true visible:false" 
-- 		sLMrc.addHandler #invisibleTimer #tick codeStr:"moveToVrayVFB()"
		sLMrc.addControl #label "lbl1" "On:" paramStr:"width:16 align:#left across:4 offset:[0,0]"
		sLMrc.addControl #label "lbl2" "Mix %:" paramStr:"width:64 align:#left offset:[-16,0]"
		sLMrc.addControl #label "lbl3" "Filter Col.:" paramStr:"width:48 align:#left offset:[-16,0]"
		sLMrc.addControl #label "lbl4" "f-Stops:" paramStr:"width:48 align:#left offset:[0,0]"
		sLMrc.addControl #label "spacer1" "" paramStr:"width:256 height:2 align:#left"
			
		for i=1 to layerNames.count  do
		(
			lName=@"#myLabel_" + i as string
			l2Name=@"#myLabel2_" + i as string
			l3Name=@"#myLabel3_" + i as string
			sName=@"#mySlider1_" + i as string
			cName=@"#myColor1_" + i as string
			tName=@"#myToggle1_" + i as string
			s2Name=@"#mySlider2_" + i as string
			localName=@"#bmpLayer1_" + i as string
			
			sLMrc.addControl #label (execute l3Name) layerNames[i][1] paramStr:"width:384 height:16 align:#left offset:[0,0]"
			sLMrc.addControl #label (execute lName) "100.0" paramStr:"width:64 height:16 align:#center offset:[16,0] across:2"
			sLMrc.addControl #label (execute l2Name) "0.0" paramStr:"width:64 height:16 align:#center offset:[42,0]"
			sLMrc.addControl #checkbox (execute tName) "" paramStr:"width:16 checked:true align:#left across:4"
			sLMrc.addControl #slider (execute sName) "" paramStr:"width:128 align:#left offset:[-56,-8] range:[0.0,100.0,100.0] scale:0.1"
			sLMrc.addControl #colorpicker (execute cName) "" paramStr:"width:48 color:white align:#right offset:[-56,-4]"
			sLMrc.addControl #slider (execute s2Name) "" paramStr:"width:128 align:#right offset:[0,-8] range:[-32,32,0.0] scale:0.01"
			
			-- Event Handlers
			
			sLMrc.addHandler (execute tName) #changed paramStr:"state" codeStr:	(
																						(execute sName) as string +".enabled="+ (execute lName) as string +".enabled="+ (execute cName) as string +".enabled="+ 
																						(execute l3Name) as string +".enabled="+ (execute s2Name) as string +".enabled="+ (execute l2Name) as string +".enabled=state"
																				)			
			
			sLMrc.addHandler (execute sName) #changed paramStr:"val" codeStr:	(
																					"(\nsLMRoll."+(execute lName) as string +".text=sLMRoll."+(execute sName) as string+
																					".value as string\nprint sLMRoll."+(execute sName) as string+".value as string\n)"
																				)
			sLMrc.addHandler (execute sName) #rightClick paramStr:"" codeStr:	(
																						"(\nsLMRoll."+(execute sName) as string +".value=100.0\nsLMRoll."+(execute lName) as string +".text=sLMRoll."+(execute sName) as string+
																					".value as string\n)"
																				)																				
																				
			sLMrc.addHandler (execute s2Name) #changed paramStr:"val" codeStr:	(
																					"(\nsLMRoll."+(execute l2Name) as string +".text="+(execute s2Name) as string+
																					".value as string\nprint "+(execute s2Name) as string+".value as string\n)"
																				)
			sLMrc.addHandler (execute s2Name) #rightClick paramStr:"" codeStr:	(
																						"(\nsLMRoll."+(execute s2Name) as string +".value=0.0\nsLMRoll."+(execute l2Name) as string +".text=sLMRoll."+(execute s2Name) as string+
																					".value as string\n)"
																					)	
		)
		sLMrc.end()	
		createDialog sLMrc.def		
	)
		

	fn createCompositeVFB =
	(
-- 		outPutBitmap=bitmap sLMRoll.bmpLayer_1.width sLMRoll.bmpLayer_1.height color:black hdr:true
		for l=1 to layerNames.count do
		(
			for y=1 to outPutBitmap.height+1 do
			(
-- 				getPixels 0,y
			)
		)
	)
	
	print "Reading and Saving LightSelect REs..."
	ts1=timestamp()
	createDynamicDialog (collectFullLightSelects())
	print ("It took a total of" + ((timestamp()-ts1)/1000.0) as string + "s. to dump the REs")
	Print "Pre-Comping REs..."
	ts1=timestamp()	
	initPrecomp()
	print ("It took a total of" + ((timestamp()-ts1)/1000.0) as string + "s. to pre-comp the REs")

)


