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
	local foundDenoiser = false
	local denoiserPath=inputFilePath=theCommandLine=""
	local framePadding=4
	
	fn getDenoiserPath =
	(
		denoiserPath=(filterString (getDir #maxroot) @"\")[1]+@"\"+(filterString (getDir #maxroot) @"\")[2]+@"\Chaos Group\V-Ray\3dsmax " + ("20"+(((maxVersion())[1]/1000)-2)as string) +@" for x64\tools\vdenoise.exe"
		if not (doesFileExist denoiserPath) do denoiserPath=""
	)

	fn getFileListFromFolder theFile =
	(
		theFilenameString=""
		theBits=filterString theFile "."
		case theBits.count of
		(
			3:
			(	
				theFileNameString=theBits[1]+"."
				framePadding = theBits[2].count
				for i=1 to framePadding do
				(
					theFileNameString+="?"
				)
				theFileNameString+="."+theBits[3]
			)
			2:
			(
				print theBits[1].count				
				for i=theBits[1].count+1 to 1 by -1 do
				(
					print i
					if (execute (substring theBits[1] i theBits[1].count ) ) == undefined do 
					( 
						if i == theBits[1].count then 
						(
							framePadding=0
						)
						else
						(
							framePadding=theBits[1].count-i
						)
						exit
					)
				)
				print "framePadding"
				print framePadding
				theFileNameString=(subString theBits[1] 1 (theBits[1].count-framePadding))
				if framePadding !=0 do
				(
					for i=1 to framePadding do
					(
						theFileNameString+="?"
					)
				)
				theFileNameString+="."+theBits[2]
			)
		)
		theFileNameString
	)
	execute ( substring "E:\_VRAY\___Dev\vDenoise\denoiseMe.exr" 38 ("E:\_VRAY\___Dev\vDenoise\denoiseMe.exr").count)
	fn buildCommandLine =
	(
		vR=vDenoiserRoll
		
		theCommandLine=" -inputfile=\"" + (getFileListFromFolder inputFilePath) +"\""
		
		if vR.modeDdl.selection < 4 then 
		(
			if vR.modeDdl.selection != 1 do theCommandLine+= " -mode=" + vR.modeDdl.items[vR.modeDdl.selection]
			if vR.boostDdl.selection != 1 do theCommandLine+= " -boost=" + vR.boostDdl.items[vR.boostDdl.selection] 			
		)
		else
		(
			if vR.strengthSpn.value != 1.0 do theCommandLine+= " -strength=" + vR.strengthSpn.value as string
			if vR.radiusSpn.value != 10 do theCommandLine+= " -strength=" + vR.radiusSpn.value as string
			if vR.doElementsChk.checked do theCommandLine+= " -elements=1"			
			if vR.frameBlendSpn.value != 0 do theCommandLine+= " -frameBlend="+ vR.frameBlendSpn.value as string
			if vR.thresholdSpn.value != 0.001 do theCommandLine+= " -threshold="+ vR.thresholdSpn.value as string
		)
		
		if not vR.forceCpuChk.checked do
		(
				theCommandLine+=" -useGpu=" +  (vR.oclDdl.selection-1) as string
		)
		
		if not vR.displayChk.checked do theCommandLine+=" -display=0"
		if vR.autoCloseChk.checked do theCommandLine+=" -autoClose=1"
		if vR.skipExistingChk.checked do theCommandLine+=" -skipExisting=1"		
		
		print theCommandLine
		theCommandLine
	)	
	
	
	
	rollout vDenoiserRoll "vDenoise Command-line Helper (v 3.40.01)" width:328 height:408
	(
		checkbox 'doElementsChk' "" pos:[16,144] width:16 height:16 checked:false align:#left enabled:false
		checkbox 'skipExistingChk' "" pos:[16,312] width:16 height:16 checked:false align:#left
		checkbox 'displayChk' "" pos:[16,288] width:16 height:16 checked:true align:#left
		checkbox 'autoCloseChk' "" pos:[168,288] width:16 height:16 checked:false align:#left
		checkbox 'forceCpuChk' "" pos:[16,200] width:16 height:16 checked:true align:#left
		dropdownList 'modeDdl' "" pos:[88,32] width:96 height:20 items:#("default", "strong", "mild", "manual") align:#left
		dropdownList 'boostDdl' "" pos:[264,32] width:48 height:20 items:#("0", "1", "2") align:#left
		dropdownList 'oclDdl' "" pos:[160,224] width:96 height:20 items:#("Cpu", "Gpu OR Cpu", "Gpu AND Cpu") align:#left enabled:false
		spinner 'strengthSpn' "" pos:[104,96] width:56 height:16 range:[0,100,1] align:#left enabled:false
		spinner 'radiusSpn' "" pos:[256,96] width:56 height:16 range:[0,25,10] align:#left enabled:false
		spinner 'frameBlendSpn' "" pos:[104,120] width:56 height:16 range:[0,3,0] type:#integer scale:1 align:#left enabled:false
		spinner 'thresholdSpn' "" pos:[256,120] width:56 height:16 range:[0,1,0.001] type:#float scale:1 align:#left enabled:false
		label 'lbl1' "Per-Element Denoising" pos:[33,144] width:119 height:16 align:#left enabled:false
		label 'lbl2' "Skip Existing Files" pos:[32,312] width:119 height:16 align:#left
		label 'lbl3' "Display Denoising Progress" pos:[32,288] width:136 height:16 align:#left
		label 'lbl4' "Auto-Close Display Window" pos:[184,288] width:136 height:16 align:#left
		label 'lbl6' "Force CPU Denoising (Non-oCl)" pos:[32,200] width:240 height:16 align:#left
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
		button 'goBtn' "Run Me!"  pos:[8,340] width:312 height:64 align:#left
		
		on vDenoiserRoll open do
		(
			
			if (getDenoiserPath()) != "" then
				(
					foundDenoiser=true
					print ("Denoiser Found at " +  denoiserPath)
				)
			else 
				(
					foundDenoiser=false
					messagebox "I can't find the V-Ray denoiser Executable.\nMake sure V-Ray 3.40.01 or newer is installed\nfor this version of 3D Studio Max.\n\n\n****************************************\n\n Nothing will happen running the script until then!\n\n****************************************"
				)
		)
		
		on modeDdl selected i do
		(
			case modeDdl.selection of
			(
				1:
				(
					strengthSpn.value=1.0
					radiusSpn.value=10
				)
				2:
				(
					strengthSpn.value=2.0
					radiusSpn.value=15					
				)
				3:
				(
					strengthSpn.value=0.5
					radiusSpn.value=5						
				)
				4: 
				(
					
				)
			)
		)
		
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
			inputFilePath=getOpenFileName caption:"Choose one file in the sequence:" types:"OpenEXR File|*.exr|VRImage File|*.vrimg|"
			if inputFilePath!=undefined do
			(	
				buildCommandLine()
				shellLaunch denoiserPath  ( theCommandLine )
			)

		)
		
	)
	
	createDialog vDenoiserRoll
)
