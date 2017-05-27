(
	global sLMRoll
	try (destroyDialog sLMRoll) catch()
-- 	swf=dotNetObject "System.Windows.Forms"
	global moveToVrayVFB=undefined
	local findVrayVFB=undefined
	local theVFBId=numLayers=0
	local bName=""
	local theOldVFBPos=theVfBPos=box2 0 0 1 1

	sLMrc = rolloutCreator "sLMRoll" "Simple Light Mixer V. 0.001" width:384 
	
	local rem=maxOps.GetCurRenderElementMgr() 
	local theREs=#()
	local chanNames=undefined
	fn collectFullLightSelects = 
	(
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
			chanNames=(vfbControl #getchannelnames)
			theID=0
			for id=1 to chanNames[1].count do
			(
				for i=1 to theREs.count do
				(
					if theREs[i]==chanNames[1][id] do
					(
-- 						tempBmp=bitmap 1 1 color:black hdr:on
						print chanNames[1][id]
						vfbControl #setChannel (id-1)
-- 						(execute ("tempBmp_"+i as string))=
						vfbControl #duplicate
						deleteItem theREs i
-- 						display (execute ("tempBmp_"+i as string))
						exit
					)
				)
			)
		)
	)
	
-- 	collectFullLightSelects()
	
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
				thePos=box2 (theVfBPos.x+theVfBPos.w) theVfBPos.y 384 theVfBPos.h
				windows.setWindowPos sLMrc.def.hwnd thePos.x thePos.y thePos.w thePos.h true
			)
		theOldVFBPos = theVfBPos
	)

	fn createDynamicDialog numLayers=
	(

		sLMrc.begin()
		sLMrc.addHandler #sLMRoll #open codeStr:"moveToVrayVFB()"
		sLMrc.addHandler #sLMRoll #close codeStr:"moveToVrayVFB=undefined"
		
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
			sName=@"#mySlider_" + i as string
			cName=@"#myColor_" + i as string
			tName=@"#myToggle_" + i as string
			s2Name=@"#mySlider2_" + i as string
			
			sLMrc.addControl #label (execute lName) "100.0" paramStr:"width:64 height:16 align:#center offset:[16,0] across:2"
			sLMrc.addControl #label (execute l2Name) "0.0" paramStr:"width:64 height:16 align:#center offset:[42,0]"
			sLMrc.addControl #checkbox (execute tName) "" paramStr:"width:16 checked:true align:#left across:4"
			sLMrc.addControl #slider (execute sName) "" paramStr:"width:128 align:#left offset:[-56,-8] range:[0.0,100.0,100.0] scale:0.1"
			sLMrc.addControl #colorpicker (execute cName) "" paramStr:"width:48 color:white align:#right offset:[-56,-4]"
			sLMrc.addControl #slider (execute s2Name) "" paramStr:"width:128 align:#right offset:[0,-8] range:[-32,32,0.0] scale:0.01"
			
			-- Slider Labels Dynamic ext
			sLMrc.addHandler (execute sName) #changed paramStr:"val" codeStr:	(
																					"(\nsLMRoll."+(execute lName) as string +".text="+(execute sName) as string+
																					".value as string\nprint "+(execute sName) as string+".value as string\n"
																				)
			sLMrc.addHandler (execute sName) #rightClick paramStr:"val" codeStr:	(
																						"(\nsLMRoll."+(execute sName) as string +".value=100.0\n)"
																					)																				
																				
			sLMrc.addHandler (execute s2Name) #changed paramStr:"val" codeStr:	(
																					"(\nsLMRoll."+(execute l2Name) as string +".text="+(execute s2Name) as string+
																					".value as string\nprint "+(execute s2Name) as string+".value as string)"
																				)
			sLMrc.addHandler (execute s2Name) #rightClick paramStr:"val" codeStr:	(
																						"(\nsLMRoll."+(execute s2Name) as string +".value=0.0\n)"
																					)	
		)
		sLMrc.end()	
		findVrayVFB()
		createDialog sLMrc.def		
	)
		
	createDynamicDialog 3 --numLayers
)


