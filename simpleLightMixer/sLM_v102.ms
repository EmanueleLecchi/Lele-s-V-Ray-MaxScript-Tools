(
	global sLMRoll
	try (destroyDialog sLMRoll) catch()
-- 	swf=dotNetObject "System.Windows.Forms"
	global moveToVrayVFB=undefined
	local findVrayVFB=undefined
	local theVFBId=numLayers=rollHeight=0
	local bName=""
	local theOldVFBPos=theVfBPos=box2 0 0 1 1
	local sLMrc
	local rem=maxOps.GetCurRenderElementMgr() 
	local theREs=#()
	local chanNames=undefined
	local layerNames=#()
	local layerName = ""
	local tempFolder=""
	
	global wipeTemps
	global findVrayVFB
	global moveToVrayVFB
	global collectFullLightSelects
	
	fn LSMaker =
	(
		theLights=#()
		theLights= for l in lights where (classof l == vrayLight or classof l == vrayIes) collect l			
-- 		print theLights
		for l in theLights do
		(
			theRE=vraylightselect mode:4 elementName:("VRLS_"+l.name) lights:#(l)
			rem.AddRenderElement theRE
		)
	)
	
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
		append layerNames REName
		layerName

	)
	
	fn collectFullLightSelects = 
	(
		makeTempFolder()
		layerNames=#()
-- 		vfbControl #setChannel 0
-- 		vfbControl #saveImage (genFileName "test.RGBColor")		
		
		chanNames=(vfbControl #getchannelnames)[1]
		theLSs=	for re=1 to chanNames.count where (matchpattern chanNames[re] pattern:"VRLS_*")  collect #(chanNames[re],re-1)
		numLayers=theLSs.count
		
		for l in theLSs do
		(
			vfbControl #setChannel l[2]
-- 			print l[1]
			fileName=(genFileName "VRLS" l[1])
-- 			print ("saving " + fileName)
			vfbControl #saveImage fileName
		)
		vfbControl #setChannel 0
	)
	
	fn initPrecomp =
	(
		
		for f=1 to layerNames.count do
		(
			bmpName=getFilenameFile layerNames[f]
			openbitmap layerNames[f] hdr:on
		)
	)

	fn findVrayVFB =
	(
		theVFBId=0
		for i in (windows.getChildrenHWND (windows.getDesktopHWND())) do
			(
				if matchpattern i[5] pattern:"V-Ray frame buffer -*" do
				(
					theVFBId=i[1]
				)
			)
		theVFBId
	)	
	
	fn moveToVrayVFB= 
	(		
		theVfBPos=windows.getWindowPos theVFBId
		if theVfBPos != theOldVFBPos do
			(
				thePos=box2 (theVfBPos.x+theVfBPos.w) theVfBPos.y 384 rollHeight
				windows.setWindowPos sLMrc.def.hwnd thePos.x thePos.y thePos.w thePos.h true
			)
		theOldVFBPos = theVfBPos
	)

	fn createDynamicDialog numLayers=
	(
		rollHeight=(64+numLayers*76)
		sLMrc = rolloutCreator "sLMRoll" "Simple Light Mixer V. 0.001" width:384 height:rollHeight

		sLMrc.begin()
		sLMrc.addHandler #sLMRoll #open codeStr:"moveToVrayVFB()"
		sLMrc.addHandler #sLMRoll #close codeStr:"(moveToVrayVFB=undefined\nwipeTemps())"
		
		sLMrc.addControl #timer #invisibleTimer "" paramStr:"interval:0 active:true visible:false" 
		sLMrc.addHandler #invisibleTimer #tick codeStr:"moveToVrayVFB()"
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
			
-- 			thebmp=(openBitmap layerNames[i+1] hdr:on)
-- 			print layerNames[i+1]
-- 			print thebmp
-- 			sLMrc.addLocal (execute localName) init:thebmp
-- 			lName=( substring (getFilenameType(getfilenamefile layerNames[i])) 2 1000 )
-- 			print lName
			sLMrc.addControl #label (execute l3Name) layerNames[i] paramStr:"width:384 height:16 align:#left offset:[0,0]"
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
		findVrayVFB()
		createDialog sLMrc.def		
	)
		
-- 	substring (getFilenameType (getfilenamefile @"C:\Users\Lele\AppData\Local\Autodesk\3dsMax\2017 - 64bit\ENU\temp\sLMTemp\test.VRLS_livingroom_fill.exr")) 2 1000
	
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
	collectFullLightSelects()
	createDynamicDialog numLayers
-- 	createCompositeVFB()
)


