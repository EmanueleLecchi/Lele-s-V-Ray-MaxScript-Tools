(
	global sLMrc
	try (destroyDialog sLMrc.def) catch()
-- 	swf=dotNetObject "System.Windows.Forms"
	global moveToVrayVFB=undefined
	local findVrayVFB=undefined
	theVFBId=0
	bName=""
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
-- 		print vfbHWND
	)	

	fn moveToVrayVFB = 
	(
		theVfBPos=windows.getWindowPos theVFBId
-- 		theRolloutPos=windows.getWindowPos sLMrc.def.hwnd 
		SetDialogPos sLMrc.def [(theVfBPos.x+theVfBPos.w), theVfBPos.y]
	)

	fn createDynamicDialog =
	(
		sLMrc.begin()
		sLMrc.addHandler #sLMRoll #open codeStr:"moveToVrayVFB()"
		sLMrc.addHandler #sLMRoll #close codeStr:"moveToVrayVFB=undefined"
		
		sLMrc.addControl #timer #invisibleTimer "" paramStr:"interval:0 active:true visible:false" 
		sLMrc.addHandler #invisibleTimer #tick codeStr:@"moveToVrayVFB()"
		for i=1 to 5 do
		(
			bName=@"#myButton" + i as string
			sLMrc.addControl #slider (execute bName) ("Mix Amount " + i as string) paramStr:"width:192 enabled:true range:[0.0,1.0,1.0] scale:0.001" 
			sLMrc.addHandler (execute bName) #changed paramStr:"val" codeStr:"print val"
		)
		sLMrc.end()	
		findVrayVFB()
		createDialog sLMrc.def	
	)
		
	createDynamicDialog()
)


