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
	local denoiserPath=theCommandLine=""
	local inputFilePath=undefined
	local FilteredFilename = ""
	local framePadding=4
	local framesBlend=0
	
	fn getDenoiserPath =
	(
		denoiserPath=(filterString (getDir #maxroot) @"\")[1]+@"\"+(filterString (getDir #maxroot) @"\")[2]+@"\Chaos Group\V-Ray\3dsmax " + ("20"+(((maxVersion())[1]/1000)-2)as string) +@" for x64\tools\vdenoise.exe"
		if not (doesFileExist denoiserPath) do denoiserPath=""
	)

	fn getFileListFromFolder theFile =
	(
		vR=vDenoiserRoll
		theFilenameString=""
		theBits=filterString theFile "."
		case theBits.count of
		(
			3:
			(	
				theFileNameString=theBits[1]+"."
				for i=theBits[2].count to 1 by -1 do
				(
					if (execute (substring theBits[2] i theBits[2].count ) ) == undefined do 
					( 
						if i == theBits[2].count then 
						(
							framePadding = theBits[2].count
							framesBlend=1
						)
						else
						(
							framePadding=theBits[2].count-i
							framesBlend=1
						)
						exit
					)
				)
				if framePadding !=0 do
				(
					for i=1 to framePadding do
					(
						theFileNameString+="?"
						
					)
					framesBlend=1
				)
				theFileNameString+="."+theBits[3]
			)
			2:
			(
				for i=theBits[1].count to 1 by -1 do
				(
					if (execute (substring theBits[1] i theBits[1].count ) ) == undefined do 
					( 
						if i == theBits[1].count-1 then 
						(
							framePadding=0

							framesBlend=0
						)
						else
						(
							framePadding=theBits[1].count-i

							framesBlend=1
						)
						exit
					)
				)
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
-- 		print theFileNameString
		theFileNameString
	)

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
-- 			if vR.thresholdSpn.value != 0.001 do theCommandLine+= " -threshold="+ vR.thresholdSpn.value as string
		)
		
		if not vR.forceCpuChk.checked do
		(
				theCommandLine+=" -useGpu=" +  (vR.oclDdl.selection-1) as string
		)
		
		if not vR.displayChk.checked do theCommandLine+=" -display=0"
		if vR.autoCloseChk.checked do theCommandLine+=" -autoClose=1"
		if vR.skipExistingChk.checked do theCommandLine+=" -skipExisting=1"		
		
-- 		print theCommandLine
		theCommandLine
	)	
	
	fn savePresetFile = 
	(
		vR = vDenoiserRoll
		presetFilename = (getfilenamePath denoiserPath) + @"DenoiserUserDefaults.txt"
		print presetFilename
		valuePairArray=#()
		
		for p in vR.controls do
		(
			case (classof p) of 
			(
				CheckBoxControl:append valuePairArray #(p.name, p.checked)
				ComboBoxControl:append valuePairarray #(p.name, p.selection)
				SpinnerControl:append valuePairArray #(p.name, p.value)
			)
		)
		
		thePresetFile = openFile presetFilename mode:"w+"
		for p in valuePairArray do
		(
			format "%\n%\n" p[1] p[2] to:thePresetFile
		)
		flush thePresetFile
		close thePresetFile
	)

	fn applyDefaultsPreset =
	(
		presetFilename = (getfilenamePath denoiserPath) + @"DenoiserUserDefaults.txt"

		if doesFileExist presetFilename then 
		(
			vR=vDenoiserRoll
			valuePairArray=#()
			theFile=openFile presetFilename mode:"r"
			seek theFile 0
			while not (eof theFile) do
			(
				append valuePairArray #(("vDenoiserRoll."+(readline theFile) as string),(readline theFile))
			)
			flush theFile
			close theFile			
			for p =1 to vR.controls.count do
			(
				case (classof vR.controls[p]) of 
				(
					CheckBoxControl:execute (valuePairArray[p][1] + ".checked=" + valuePairArray[p][2] as string)
					ComboBoxControl:execute (valuePairArray[p][1] + ".selection=" + valuePairArray[p][2] as string)
					SpinnerControl:execute (valuePairArray[p][1] + ".value=" + valuePairArray[p][2] as string)
				)
			)			
		)
		else
		(
-- 			messageBox "Can't find this preset file!"
		)
	)
	
	rollout vDenoiserRoll "vDenoise Command-line Helper (v 3.40.01)" width:328 height:528
	(
		checkbox 'doElementsChk' "" pos:[300,120] width:16 height:16 checked:false align:#left enabled:false tooltip:"If checked, it instructs the denoiser to apply different heuristics and methods to each render element, and then to re-composite it back together once done.\nThis is the strongest method to retain detail, takes longer to process, and may require higher strength to perform at its best.\nIt may have difficulties with objects behind refractions.\nShould that be the case, unchecking the tickbox will denoise only the RGB element, while still considering the other Render Elements to decide what to retain and what to smooth.\nIt's the quickest of the two methods, works well with objects behind refractive ones, and works well already with the default strength and radius values.\nIt's not advised to raise strength or radius too much with this method as artifacts may appear."
		checkbox 'skipExistingChk' "" pos:[16,312] width:16 height:16 checked:false align:#left tooltip:"Skips denoising entirely when output files already exist"
		checkbox 'displayChk' "" pos:[16,288] width:16 height:16 checked:true align:#left tooltip:"Show the Denoising process as it happens"
		checkbox 'autoCloseChk' "" pos:[168,288] width:16 height:16 checked:false align:#left Tooltip:"Close the display after each image\nWarning: it will close after the last of the sequence too."
		checkbox 'forceCpuChk' "" pos:[16,200] width:16 height:16 checked:true align:#left tooltip:"Force non-OpenCl CPU Denoising"
		dropdownList 'modeDdl' "" pos:[88,32] width:96 height:20 items:#("default", "strong", "mild", "manual") align:#left tooltip:"Pick a mode which suits your needs, or choose 'manual' to be able to edit the denoising settings as you prefer."
		dropdownList 'boostDdl' "" pos:[264,32] width:48 height:20 items:#("0", "1", "2") align:#left tooltip:"Boost to apply to one of the preset modes"
		dropdownList 'oclDdl' "" pos:[160,224] width:96 height:20 items:#("Cpu", "Gpu OR Cpu", "Gpu AND Cpu") align:#left enabled:false Tooltip:"Choose if the openCl Kernel should use just the CPU, Either the Cpu OR the Gpu, or attempt to use both together.\nThe latter mode is experimental, and will fall back to the fastest OpenCL device available in case fo failure to initiate."
		spinner 'strengthSpn' "" pos:[104,96] width:56 height:16 range:[0,100,1] align:#left enabled:false tooltip:"A strength of 1.0 will use the 'NoiseLevel' render element as it is,\nvalues higher than 1.0 will denoise more at the expense of Compute time and Detail loss,\nvalues lower than 1.0 will be quicker to calculate, keep the detail crisp, but will likely retain some noise too."
		spinner 'radiusSpn' "" pos:[256,96] width:56 height:16 range:[0,25,10] align:#left enabled:false tooltip:"Radius will govern how far the blending will happen from a pixel being analysed.\nThe default of 10 works well in most cases,\n value higher than 10 will denoise more, but take longer, use more memory, and potentially blur detail\nwhile lower values will preserve detail better, take less time and memory to compute, but may introduce splotchiness or artefacts."
		spinner 'frameBlendSpn' "" pos:[104,120] width:56 height:16 range:[0,3,0] type:#integer scale:1 align:#left tooltip:"This drives how many frames before and after the one being denoise should be considered for temporal coherence.\n it has no effect on single frames.\nA Value of 0 will deactivate it (not suggested for animations), while there is marginal benefit setting it above 1"
-- 		spinner 'thresholdSpn' "" pos:[256,120] width:56 height:16 range:[0,1,0.001] type:#float scale:1 align:#left enabled:false tooltip:"Noise Threshold in the rendered image to denoise.\nNormally it takes the 'noiseLevel' renderelement into account, when set to the default of 0.001.\nIt can be overridden, but it is not suggested."
		label 'lbl1' "Per-Element Denoising" pos:[180,120] width:119 height:16 align:#left enabled:false
		label 'lbl2' "Skip Existing Files" pos:[32,312] width:119 height:16 align:#left
		label 'lbl3' "Display Denoising Progress" pos:[32,288] width:136 height:16 align:#left
		label 'lbl4' "Auto-Close Display Window" pos:[184,288] width:136 height:16 align:#left
		label 'lbl6' "Force CPU Denoising (Non-oCl)" pos:[32,200] width:240 height:16 align:#left
		label 'lbl7' "OpenCL Denoising mode:" pos:[16,224] width:136 height:16 align:#left enabled:false
		label 'lbl8' "Mode Preset:" pos:[16,32] width:72 height:16 align:#left
		label 'lbl9' "Mode Boost:" pos:[192,32] width:72 height:16 align:#left
		label 'lbl10' "Strength:" pos:[16,96] width:56 height:16 align:#left enabled:false
		label 'lbl11' "Radius:" pos:[168,96] width:56 height:16 align:#left enabled:false
		label 'lbl12' "Frames to Blend:" pos:[16,120] width:88 height:16 align:#left
-- 		label 'lbl13' "Noise Threshold:" pos:[168,120] width:88 height:16 align:#left enabled:false
		groupBox 'grp1' "Quick Controls:" pos:[8,8] width:312 height:56 align:#left
		groupBox 'grp2' "Manual Set-up:" pos:[8,72] width:312 height:96 align:#left 
		groupBox 'grp3' "Performance Options:" pos:[8,176] width:312 height:80 align:#left
		groupBox 'grp4' "Ancillary Options:" pos:[8,264] width:312 height:72 align:#left
		groupBox 'grp5' "Custom Defaults Preset:" pos:[8,336] width:312 height:56 align:#left
		button 'presetBtn' "Save current settings as default"  pos:[12,352] width:264 height:36 align:#left tooltip:"Save a text file with the current script settings as default for future sessions."
		button 'wipeBtn' "R"  pos:[280,352] width:36 height:36 align:#left toolTip:"Deletes the custom defaults file and restores factory defaults."	
		groupBox 'grp6' "Select and execute:" pos:[8,392] width:312 height:128 align:#left		
		button 'pickBtn' "Pick a File in your sequence..."  pos:[12,412] width:304 height:36 align:#left tooltip:"Click the button to be able to pick a single file, or one belonging to a sequence (at any point in the sequence), for the denoiser to operate on.\n\nWorks with VRImages and Multi-layer EXRs, best saved with V-Ray's raw file output"	
		button 'goBtn' "Denoise it!"  pos:[12,452] width:304 height:64 align:#left tooltip:"Once the parameters have been set,\nthe file or sequence selected,\nclick this button to start the denoising process in a command window"
		fn refreshControlState =
			(
				if modeDdl.selection==4 then
				(
					doElementsChk.enabled=strengthSpn.enabled=radiusSpn.enabled=
					lbl1.enabled=lbl10.enabled=lbl11.enabled=true
					boostDdl.enabled=lbl9.enabled=false
				)
				else
				(
					doElementsChk.enabled=strengthSpn.enabled=radiusSpn.enabled=
					lbl1.enabled=lbl10.enabled=lbl11.enabled=false
					boostDdl.enabled=lbl9.enabled=true
				)
				oclDdl.enabled=lbl7.enabled=not forceCpuChk.checked 
			)
			
		on vDenoiserRoll open do
		(
			if (getDenoiserPath()) != "" then
				(
					foundDenoiser=true
-- 					print ("Denoiser Found at " +  denoiserPath)
					applyDefaultsPreset()
					refreshControlState()
				)
			else 
				(
					foundDenoiser=false
					messagebox "I can't find the V-Ray denoiser Executable.\nMake sure V-Ray 3.40.01 or newer is installed\nfor this version of 3D Studio Max.\n\n\n****************************************\n\n Nothing will happen running the script until then!\n\n****************************************"
				)
		)
		
		on presetBtn pressed do
		(
			savePresetFile()
		)
		
		on wipeBtn pressed do
		(
			fileName=((getfilenamePath denoiserPath) + @"DenoiserUserDefaults.txt")
			if (doesFileExist fileName) then 
			(
				try 
				( 
					deleteFile Filename 
				)
				catch ( messageBox "Couldn't delete the custom defaults file!")
			)
			else
			(
				messageBox "No custom defaults file to delete."
			)
			strengthSpn.value=1
			radiusSpn.value=10
			frameBlendSpn.value=0
-- 			thresholdSpn.value=0.001
			modeDdl.selection=boostDdl.selection=oclDdl.selection=1			
			doElementsChk.checked=skipExistingChk.checked=autoCloseChk.checked=false
			displayChk.checked=forceCpuChk.checked=true
			refreshControlState()
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
			refreshControlState()
		)
		
		on pickBtn pressed do 
		(
			inputFilePath=getOpenFileName caption:"Choose one file in the sequence:" types:"OpenEXR File|*.exr|VRImage File|*.vrimg|"

			if inputFilePath != undefined do
			(
				filtereFileName=getFileListFromFolder inputFilePath
				pickBtn.text=pickBtn.tooltip=filtereFileName
				frameBlendSpn.value=framesBlend
			)
		)
		
		on goBtn pressed do
		(

			if inputFilePath!=undefined do
			(	
				buildCommandLine()
				print ( denoiserPath +  theCommandLine)
				shellLaunch denoiserPath theCommandLine 
			)

		)
		
	)
	
	createDialog vDenoiserRoll
)
