(
	global sLMRoll
	try (destroyDialog sLMRoll) catch()
-- 	swf=dotNetObject "System.Windows.Forms"
	global moveToVrayVFB=undefined
	local findVrayVFB=undefined
	local theVFBId=0
	local bName=""
	local theOldVFBPos=theVfBPos=box2 0 0 1 1

	 sLMrc = rolloutCreator "sLMRoll" "Simple Light Mixer V. 0.001" width:256 
	
	fn findVrayVFB =
	(
		theVFBId=0
		for i in (windows.getChildrenHWND (windows.getDesktopHWND())) do
			(
				if matchpattern i[5] pattern:"V-Ray frame buffer*" do
				(
					theVFBId=i[1]
				)
			)
		theVFBId
	)	

	fn moveToVrayVFB= 
	(		
		theVfBPos=windows.getWindowPos (findVrayVFB())
		if theVfBPos != theOldVFBPos do
			(
				thePos=box2 (theVfBPos.x+theVfBPos.w) theVfBPos.y 256 theVfBPos.h
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
		sLMrc.addControl #label "lbl1" "On:" paramStr:"width:16 align:#left across:3 offset:[0,0]"
		sLMrc.addControl #label "lbl2" "Mix %:" paramStr:"width:64 align:#left offset:[-16,0]"
		sLMrc.addControl #label "lbl3" "Filter Col.:" paramStr:"width:48 align:#left offset:[16,0]"
		sLMrc.addControl #label "spacer1" "" paramStr:"width:256 height:8 align:#left"
			
		for i=1 to numLayers do
		(
			lName=@"#myLabel_" + i as string
			sName=@"#mySlider_" + i as string
			cName=@"#myColor_" + i as string
			tName=@"#myToggle_" + i as string
			sLMrc.addControl #label (execute lName) "100.0" paramStr:"width:128 align:#left offset:[104,0]"
		
			sLMrc.addControl #checkbox (execute tName) "" paramStr:"width:16 checked:true align:#left across:3"
			sLMrc.addControl #slider (execute sName) "" paramStr:"width:128 align:#left offset:[-48,0] range:[0.0,100.0,100.0] scale:0.01"
			--("Mix Amount " + i as string) 
			sLMrc.addControl #colorpicker (execute cName) "" paramStr:"width:48 color:white align:#right offset:[-16,6]"
			sLMrc.addHandler (execute sName) #changed paramStr:"val" codeStr:("sLMRoll."+lName+".text="+sName+".value as string")
		)
		sLMrc.end()	
		findVrayVFB()
		createDialog sLMrc.def			
-- 		sLMRoll.scrollbars
-- 		.style=#(#style_titlebar, #style_border, #style_sysmenu)
	)
		
	createDynamicDialog 10
)


