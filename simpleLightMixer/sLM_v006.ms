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
	local tempFolder=""
	
	
	fn makeTempFolder =
	(
		tempFolder=(getDir #temp ) + @"\sLMTemp_" + (((random 12345 99999) as integer) as string) + @"\"
		makeDir tempFolder
	)
	
	fn wipeTemps =
	(
		theDirs= (	getDirectories ((getDir #temp ) + @"\sLMTemp_*" ))
		for d in theDirs do
		(
			for f in (getFiles (d+"*.exr")) do deleteFile f
			str=(filterstring d @"\")[(filterstring d @"\").count]
			str = (@"rmDir " + str )
-- 			print str
			hiddenDosCommand str startpath:(getDir #temp ) 
		)
	)
	

	fn genFileName REName pos=
	(
		baseFileName=tempFolder+REName
		counter=1
		while ( doesFileExist (baseFileName+".exr")) do 
		(
			counter+=1
			baseFileName+=counter as string
		)
		append layerNames (baseFileName+".exr")
		(baseFileName+".exr")
	)
	
	fn collectFullLightSelects = 
	(
		makeTempFolder()
		
		theREs=#()
		for n = 0 to (rem.numrenderelements () - 1) do
		(
			el = rem.getrenderelement n
			if classof el == VRayLightSelect and el.mode==4 do
				append theREs el.elementname
		)

		if theREs.count!= 0 do
		(
			numLayers=theREs.count
			chanNames=(vfbControl #getchannelnames)[1]
			tempREs=copy theREs #noMap
			for id=chanNames.count to 1 by -1 do
			(
				for i=tempREs.count to 1 by -1 do
				(
					if tempREs[i]==chanNames[id] do
					(
						print chanNames[id]
						vfbControl #setChannel (id-1)
						vfbControl #saveImage (genFileName chanNames[id] i)
						deleteItem tempREs i
						deleteItem chanNames id
					)
				)
			)
		)
	)
	
	collectFullLightSelects()
	
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
		sLMrc.addHandler #sLMRoll #close codeStr:"moveToVrayVFB=undefined\nwipeTemps()"
		
		sLMrc.addControl #timer #invisibleTimer "" paramStr:"interval:0 active:true visible:false" 
		sLMrc.addHandler #invisibleTimer #tick codeStr:@"moveToVrayVFB()"
		sLMrc.addControl #label "lbl1" "On:" paramStr:"width:16 align:#left across:4 offset:[0,0]"
		sLMrc.addControl #label "lbl2" "Mix %:" paramStr:"width:64 align:#left offset:[-16,0]"
		sLMrc.addControl #label "lbl3" "Filter Col.:" paramStr:"width:48 align:#left offset:[-16,0]"
		sLMrc.addControl #label "lbl4" "f-Stops:" paramStr:"width:48 align:#left offset:[0,0]"
		sLMrc.addControl #label "spacer1" "" paramStr:"width:256 height:2 align:#left"
			
		for i=1 to numLayers do
		(
			lName=@"#myLabel_" + i as string
			l2Name=@"#myLabel2_" + i as string
			l3Name=@"#myLabel3_" + i as string
			sName=@"#mySlider_" + i as string
			cName=@"#myColor_" + i as string
			tName=@"#myToggle_" + i as string
			s2Name=@"#mySlider2_" + i as string
			localName=@"#bmpLayer_" + i as string
			
			sLMrc.addLocal (execute localName) init:(openBitmap layerNames[i] hdr:on)
			
			sLMrc.addControl #label (execute l3Name) (getfilenamefile layerNames[(numLayers+1-i)]) paramStr:"width:384 height:16 align:#left offset:[0,0]"
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
	createDynamicDialog numLayers
-- 	createCompositeVFB()
)


