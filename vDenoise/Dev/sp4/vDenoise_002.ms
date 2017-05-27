(
	/*
	Find vDenoise.exe -> max version, build path.
	Gather max's output settings and ONLY the vray Raw output (for now?)
	Build the cmd line, passing -frame as a string, for now.
	*/
	global vDenoiserRoll
	try (destroyDialog vDenoiserRoll) catch()
	local outputFrames=#()
	local expandedFilenames=#()
	
	fn getDenoiserPath =
	(
		thePath=(filterString (getDir #maxroot) @"\")[1]+@"\"+(filterString (getDir #maxroot) @"\")[2]+@"\Chaos Group\V-Ray\3dsmax " + ("20"+(((maxVersion())[1]/1000)-2)as string) +@" for x64\tools\vdenoise.exe"
		thePath
	)

	fn padToFourDigits numToPad =
	(
		numToPad = numToPad as string
		while numToPad.count < 4 do numToPad = append "0" numToPad
		numToPad
	)
	
	fn gatherOutputData =
	(
		renderSceneDialog.commit()
		case rendTimeType of 
		(
			1:
				(
					"single frame"
					outputFrames=#(padToFourDigits (sliderTime.frame as integer))
				)
			2:
				(
					"Active time segment"
					for i = (animationRange.start.frame as integer) to (animationRange.end.frame as integer) by rendNThFrame do
					(
						append outputFrames (padToFourDigits (i+rendFileNumberBase))
					)
					outputFrames
				)
			3:
				(
					"Range"
					for i = (rendStart.frame as integer) to (rendEnd.frame as integer) by rendNThFrame do
					(
						append outputFrames (padToFourDigits (i+rendFileNumberBase))
					)
					outputFrames
				)
			4:
				(
					"User"
					frameRanges=filterString rendPickupFrames ","
					for i in frameRanges do
					(
						case (filterstring i "-").count of
						(
							1: (append outputFrames (padToFourDigits i))
							2: for f = ((filterstring i "-")[1] as integer) to ((filterstring i "-")[2] as integer) do  append outputFrames (padToFourDigits f)
						)
					)
					outputFrames
				)
		)
	)
	
	fn buildRawFileNames =
	(
		baseName=renderers.current.output_rawFileName
		if baseName!= undefined then
		(
			if renderers.current.fileName_addDot then
			(
				for i in outputFrames do
				(
					append expandedFilenames (getfilenamepath basename+getfilenamefile basename+"."+i+getfilenametype basename)
				)
			)
			else
			(
				for i in outputFrames do
				(
					append expandedFilenames (getfilenamepath basename+getfilenamefile basename+i+getfilenametype basename)
				)
			)
			expandedfilenames
		)
		else
		(
			messageBox "Add a Raw File Output, will ya?"
		)
	)
	
	fn buildCommandLine =
	(		
		gatherOutputData()
		theString =getDenoiserPath() + "\n"
		for f in (buildRawFileNames()) do theString+=f+"\n"
		messageBox theString
	)
	
	rollout vDenoiserRoll "vDenoise" width:328 height:592
	(
		checkbox 'doElementsChk' "" pos:[16,144] width:16 height:16 checked:true align:#left enabled:false
		checkbox 'skipExistingChk' "" pos:[16,312] width:16 height:16 checked:true align:#left
		checkbox 'displayChk' "" pos:[16,288] width:16 height:16 checked:true align:#left
		checkbox 'autoCloseChk' "" pos:[168,288] width:16 height:16 checked:true align:#left
		checkbox 'forceCpuChk' "" pos:[16,200] width:16 height:16 checked:true align:#left
		dropdownList 'modeDdl' "" pos:[88,32] width:96 height:20 items:#("default", "Strong", "Mild", "Manual") align:#left
		dropdownList 'boostDdl' "" pos:[264,32] width:48 height:20 items:#("0", "1", "2") align:#left
		dropdownList 'oclDdl' "" pos:[160,224] width:96 height:20 items:#("Cpu", "Gpu OR Cpu", "Gpu AND Cpu") align:#left enabled:false
		spinner 'strengthSpn' "" pos:[104,96] width:56 height:16 range:[0,100,1] align:#left enabled:false
		spinner 'radiusSpn' "" pos:[256,96] width:56 height:16 range:[0,25,10] align:#left enabled:false
		spinner 'frameBlendSpn' "" pos:[104,120] width:56 height:16 range:[0,3,1] type:#integer scale:1 align:#left enabled:false
		spinner 'thresholdSpn' "" pos:[256,120] width:56 height:16 range:[0,1,0.001] type:#float scale:1 align:#left enabled:false
		label 'lbl1' "Per-Element Denoising" pos:[33,144] width:119 height:16 align:#left enabled:false
		label 'lbl2' "Skip Existing Files" pos:[32,312] width:119 height:16 align:#left
		label 'lbl3' "Display Denoising Progress" pos:[32,288] width:136 height:16 align:#left
		label 'lbl4' "Auto-Close Display Window" pos:[184,288] width:136 height:16 align:#left
		label 'lbl6' "Force CPU Denoising" pos:[32,200] width:136 height:16 align:#left
		label 'lbl7' "OpenCL Denoising mode:" pos:[16,224] width:136 height:16 align:#left enabled:false
		label 'lbl8' "Mode Preset:" pos:[16,32] width:72 height:16 align:#left
		label 'lbl9' "Mode Boost:" pos:[192,32] width:72 height:16 align:#left
		label 'lbl10' "Strength:" pos:[16,96] width:56 height:16 align:#left enabled:false
		label 'lbl11' "Radius:" pos:[168,96] width:56 height:16 align:#left enabled:false
		label 'lbl12' "Frames to Blend:" pos:[16,120] width:88 height:16 align:#left enabled:false
		label 'lbl13' "Noise Threshold:" pos:[168,120] width:88 height:16 align:#left enabled:false
		groupBox 'grp1' "Quick Controls:" pos:[8,8] width:312 height:56 align:#left
		groupBox 'grp2' "Manual Set-up:" pos:[8,72] width:312 height:96 align:#left enabled:false
		groupBox 'grp3' "Performance Options:" pos:[8,176] width:312 height:80 align:#left
		groupBox 'grp4' "Ancillary Options:" pos:[8,264] width:312 height:72 align:#left
		button 'goBtn' "Test Run Me!"  pos:[8,360] width:312 height:64 align:#left
		
		on forceCpuChk changed chk do
		(
			oclDdl.enabled=lbl7.enabled=not forceCpuChk.checked
		)
		
		on modeDdl selected sel do
		(
			if sel==4 then
			(
				grp2.enabled=doElementsChk.enabled=strengthSpn.enabled=radiusSpn.enabled=
				frameBlendSpn.enabled=thresholdSpn.enabled=lbl1.enabled=lbl10.enabled=lbl11.enabled=lbl12.enabled=
				lbl13.enabled=true
				boostDdl.enabled=lbl9.enabled=false
			)
			else
			(
				grp2.enabled=doElementsChk.enabled=strengthSpn.enabled=radiusSpn.enabled=
				frameBlendSpn.enabled=thresholdSpn.enabled=lbl1.enabled=lbl10.enabled=lbl11.enabled=lbl12.enabled=
				lbl13.enabled=false
				boostDdl.enabled=lbl9.enabled=true
			)
		)
		
		on goBtn pressed do
		(
			buildCommandLine()
		)
		
	)
	
	createDialog vDenoiserRoll
)
