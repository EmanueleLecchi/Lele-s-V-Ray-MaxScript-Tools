macroScript vDenoiseTool category:"VRay" tooltip:"vDenoise Command Line Tool Helper UI" icon:#("VRayToolbar", 5)
(

	global vDenoiserRoll,vDenoiserPresetsRoll,vDenoiserFloater
	
	try 
	(
		destroyDialog vDenoiserRoll
		destroydialog vDenoiserPresetsRoll
		closeRolloutFloater vDenoiserFloater
	) 
	catch()
	
	local outputFrames=#()
	local expandedFilenames=#()
	local foundDenoiser = false
	local denoiserPath=theCommandLine=""
	local inputFilePath=undefined
	local FilteredFilename = ""
	local framePadding=4
	local framesBlend=0
	local presetNameRoll
	local thePresetsList=#()
	
	fn getDenoiserPath =
	(
		denoiserPath=(filterString (getDir #maxroot) @"\")[1]+@"\"+(filterString (getDir #maxroot) @"\")[2]+@"\Chaos Group\V-Ray\3dsmax " + ("20"+(((maxVersion())[1]/1000)-2)as string) +@" for x64\tools\vdenoise.exe"
		if not (doesFileExist denoiserPath) do denoiserPath=""
	)

	fn getFileListFromFolder theFile =
	(
		
		--separate the path only first
		--Work on the filename alone
		--split by .
		--one part: something is wrong, the extension dot isn't there.
		--Two parts, append wc to filename
		--more , analyse each bit and find the one which has the numbers
		vR=vDenoiserRoll
		theFilenameString=""
		thePath = getfilenamepath theFile
		theName=substring theFile (thePath.count+1) -1
		theBits=filterString theName "."
		case theBits.count of
		(
			default:  --if it's three bits or more, identify which has numbers, pad that one.
			(	

				theFileNameString=thePath + theBits[1] + "."	--path+first bit is surely the name
-- 				print theFileNameString
				padBit=2
				for b=padBit to theBits.count do		--traverse the bits
				(
					if ((theBits[b] as integer )== undefined) then --theBits in question is numbers
					(					
						theFileNameString+=theBits[b] 
						if b < theBits.count do theFileNameString+="."
						print theFileNameString
					)
					else 
					(
						print theBits[b]
						print "padding the numbers"
						for i=theBits[b].count to 1 by -1 do --analyse each split for numbers. ASSUME numbers are alone.
						(
							if (execute (substring theBits[b] i theBits[b].count ) ) == undefined do --
							( 
								if i == theBits[b].count then 
								(
									framePadding = theBits[b].count
									framesBlend=1
								)
								else
								(
									framePadding=theBits[b].count-i
									framesBlend=1
								)
								exit with padBit=b
							)
						)
						if framePadding !=0 do
						(
							for i=1 to framePadding do
							(
								theFileNameString+="?"
							)
							framesBlend=1
							theFileNameString+="."
						)
					)
				)
				theFileNameString
			)
			2:
			(
				for i=theBits[1].count to 1 by -1 do
				(
					
					if ((substring theBits[1] i theBits[1].count ) as integer ) == undefined do 
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
			1:(theFileNameString = theBits[1])
			
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
			if vR.radiusSpn.value != 10 do theCommandLine+= " -radius=" + vR.radiusSpn.value as string
			if vR.doElementsChk.checked do theCommandLine+= " -elements=1"			
		)
		
		if not vR.forceCpuChk.checked do
		(
				theCommandLine+=" -useGpu=" +  (vR.oclDdl.selection-1) as string
		)
		
		if vR.frameBlendSpn.value != 1 do theCommandLine+= " -frameBlend="+ vR.frameBlendSpn.value as string		
		if not vR.displayChk.checked do theCommandLine+=" -display=0"
		if vR.autoCloseChk.checked do theCommandLine+=" -autoClose=1"
		if vR.skipExistingChk.checked do theCommandLine+=" -skipExisting=1"		
		
		theCommandLine
	)	
	
	fn populateList = 
	(
		getDenoiserPath()
		thePresetsList=#()
		thefiles=getFiles ((getfilenamePath denoiserPath) + @"\vDenoiserPresets\*.vDenoiserPreset.txt")
		for i= 1 to theFiles.count do append thePresetsList (getfilenamefile(getfilenamefile thefiles[i]))
		thePresetsList
	)
	
	fn savePresetFile = 
	(
		vR = vDenoiserRoll
		presetsPath = (getfilenamePath denoiserPath) + @"\vDenoiserPresets\"
		makeDir presetsPath
		presetName = presetNameRoll.presetNameEdt.text
		valuePairArray=#()
		
		presetFilename = presetsPath + presetName + ".vDenoiserPreset.txt"

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
	
	/* creates the rollout to choose a preset name, and passes the name to the preset file saving function above*/
	fn genSavePresetDialog =
	(
		rollout presetNameRoll "Preset Name:" width:184 height:32
		(
			editText presetNameEdt "" pos:[8,8] width:128 height:16 
			button presetSaveBtn "Save" pos:[144,8] width:32 height:16
			
			on presetSaveBtn pressed do
			(
				savePresetFile()
				vDenoiserPresetsRoll.presetsDdl.items=populateList()
				destroyDialog presetNameRoll
			)
		)
		createDialog presetNameRoll
	)
	
	/* ap[lies the chose preset values to the controls*/
	fn applyUserPreset sel=
	(
		vR = vDenoiserRoll
		presetsPath = (getfilenamePath denoiserPath) + @"\vDenoiserPresets\"
		presetName = vDenoiserPresetsRoll.presetsDdl.items[sel]
		presetFilename=(presetsPath+presetName+".vDenoiserPreset.txt")
		if doesFileExist presetFilename then 
		(		
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
			messageBox "Can't find this preset file!"
		)
	)
	
	fn refreshControlState =
	(
		vR=vDenoiserRoll
	
		if vR.modeDdl.selection==4 then
		(
			vR.doElementsChk.enabled=vR.strengthSpn.enabled=vR.radiusSpn.enabled=
			vR.lbl1.enabled=vR.lbl10.enabled=vR.lbl11.enabled=true
			vR.boostDdl.enabled=vR.lbl9.enabled=false
		)
		else
		(
			vR.doElementsChk.enabled=vR.strengthSpn.enabled=vR.radiusSpn.enabled=
			vR.lbl1.enabled=vR.lbl10.enabled=vR.lbl11.enabled=false
			vR.boostDdl.enabled=vR.lbl9.enabled=true
		)
		vR.oclDdl.enabled=vR.lbl7.enabled=not vR.forceCpuChk.checked 
	)	
	
	fn applyCustomDefault =
	(
		foundDefault=false
		for f=1 to thePresetsList.count do
		(
			if (toLower thePresetsList[f]) == "default" do
			(
				applyUserPreset f
				refreshControlState()
				print ( "Applied Custom Default Preset!")
				foundDefault=true
				vDenoiserFloater.rollouts[2].open=false
				vDenoiserFloater.size=[340,512]
			)
		)
		if not foundDefault do vDenoiserFloater.rollouts[2].open=true
		refreshControlstate()
	)
	
	rollout vDenoiserRoll "vDenoise Options:" width:328 height:504
	(
		checkbox 'doElementsChk' "" pos:[300,120] width:16 height:16 checked:false align:#left enabled:false tooltip:"If checked, it instructs the denoiser to apply different heuristics and methods to each render element, and then to re-composite it back together once done.\nThis is the strongest method to retain detail, takes longer to process, and may require higher strength to perform at its best.\nIt may have difficulties with objects behind refractions.\nShould that be the case, unchecking the tickbox will denoise only the RGB element, while still considering the other Render Elements to decide what to retain and what to smooth.\nIt's the quickest of the two methods, works well with objects behind refractive ones, and works well already with the default strength and radius values.\nIt's not advised to raise strength or radius too much with this method as artifacts may appear."
		checkbox 'skipExistingChk' "" pos:[16,288] width:16 height:16 checked:false align:#left tooltip:"Skips denoising entirely when output files already exist"
		checkbox 'displayChk' "" pos:[16,264] width:16 height:16 checked:true align:#left tooltip:"Show the Denoising process as it happens"
		checkbox 'autoCloseChk' "" pos:[168,264] width:16 height:16 checked:false align:#left Tooltip:"Close the display after each image\nWarning: it will close after the last of the sequence too."
		checkbox 'forceCpuChk' "" pos:[16,176] width:16 height:16 checked:true align:#left tooltip:"Force non-OpenCl CPU Denoising"
		dropdownList 'modeDdl' "" pos:[88,32] width:96 height:20 items:#("default", "strong", "mild", "manual") align:#left tooltip:"Pick a mode which suits your needs, or choose 'manual' to be able to edit the denoising settings as you prefer."
		dropdownList 'boostDdl' "" pos:[264,32] width:48 height:20 items:#("0", "1", "2") align:#left tooltip:"Boost to apply to one of the preset modes"
		dropdownList 'oclDdl' "" pos:[160,200] width:96 height:20 items:#("Cpu", "Gpu OR Cpu", "Gpu AND Cpu") align:#left enabled:false Tooltip:"Choose if the openCl Kernel should use just the CPU, Either the Cpu OR the Gpu, or attempt to use both together.\nThe latter mode is experimental, and will fall back to the fastest OpenCL device available in case fo failure to initiate."
		spinner 'strengthSpn' "" pos:[104,96] width:56 height:16 range:[0,100,1] align:#left enabled:false tooltip:"A strength of 1.0 will use the 'NoiseLevel' render element as it is,\nvalues higher than 1.0 will denoise more at the expense of Compute time and Detail loss,\nvalues lower than 1.0 will be quicker to calculate, keep the detail crisp, but will likely retain some noise too."
		spinner 'radiusSpn' "" pos:[256,96] width:56 height:16 range:[0,25,10] align:#left enabled:false tooltip:"Radius will govern how far the blending will happen from a pixel being analysed.\nThe default of 10 works well in most cases,\n value higher than 10 will denoise more, but take longer, use more memory, and potentially blur detail\nwhile lower values will preserve detail better, take less time and memory to compute, but may introduce splotchiness or artefacts."
		spinner 'frameBlendSpn' "" pos:[104,120] width:56 height:16 range:[0,3,0] type:#integer scale:1 align:#left tooltip:"This drives how many frames before and after the one being denoise should be considered for temporal coherence.\n it has no effect on single frames.\nA Value of 0 will deactivate it (not suggested for animations), while there is marginal benefit setting it above 1"
		label 'lbl1' "Per-Element Denoising" pos:[180,120] width:119 height:16 align:#left enabled:false
		label 'lbl2' "Skip Existing Files" pos:[32,288] width:119 height:16 align:#left
		label 'lbl3' "Display Denoising Progress" pos:[32,264] width:136 height:16 align:#left
		label 'lbl4' "Auto-Close Display Window" pos:[184,264] width:136 height:16 align:#left
		label 'lbl6' "Force CPU Denoising (Non-oCl)" pos:[32,176] width:240 height:16 align:#left
		label 'lbl7' "OpenCL Denoising mode:" pos:[16,200] width:136 height:16 align:#left enabled:false
		label 'lbl8' "Mode Preset:" pos:[16,32] width:72 height:16 align:#left
		label 'lbl9' "Mode Boost:" pos:[192,32] width:72 height:16 align:#left
		label 'lbl10' "Strength:" pos:[16,96] width:56 height:16 align:#left enabled:false
		label 'lbl11' "Radius:" pos:[168,96] width:56 height:16 align:#left enabled:false
		label 'lbl12' "Frames to Blend:" pos:[16,120] width:88 height:16 align:#left
		groupBox 'grp1' "Quick Controls:" pos:[8,8] width:312 height:56 align:#left
		groupBox 'grp2' "Manual Set-up:" pos:[8,72] width:312 height:72 align:#left 
		groupBox 'grp3' "Performance Options:" pos:[8,152] width:312 height:80 align:#left
		groupBox 'grp4' "Ancillary Options:" pos:[8,240] width:312 height:72 align:#left
		groupBox 'grp6' "Select a File and Denoise:" pos:[8,320] width:312 height:128 align:#left		
		button 'pickBtn' "Pick a File in your sequence..."  pos:[12,340] width:304 height:36 align:#left tooltip:"Click the button to be able to pick a single file, or one belonging to a sequence (at any point in the sequence), for the denoiser to operate on.\n\nWorks with VRImages and Multi-layer EXRs, best saved with V-Ray's raw file output"	
		button 'goBtn' "Denoise it!"  pos:[12,380] width:304 height:64 align:#left tooltip:"Once the parameters have been set,\nthe file or sequence selected,\nclick this button to start the denoising process in a command window"
		
		

			
		on vDenoiserRoll open do
		(
			if (getDenoiserPath()) != "" then
				(
					foundDenoiser=true
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
	
	rollout vDenoiserPresetsRoll "Presets Manager:" width:328 height:240 rolledup:true
	(
		dropDownList presetsDdl "" pos:[112,8] width:208 height:21 tooltip:"This lists all of your saved presets."
		label lbl1 "Presets:" pos:[8,8] width:88 height:16
		button saveBtn"Save Current as Denoiser Preset" pos:[8,40] width:280 height:24 tooltip:"Save the current vDenoiser settings as a preset.\nClicking here will pop up a small window to enter a preset name into.\nSaving a preset with the name 'Default' (non case-sensitive) will load it at startup instead of the factory settings."
		button refreshBtn "R" pos:[296,40] width:24 height:24 tooltip:"Press to manually refresh the preset list."
		button browseBtn "Open Presets Folder" pos:[8,72] width:312 height:24 tooltip:"Press to browse directly to the stored presets folder."
		
		on vDenoiserPresetsRoll open do 
		(
			try 
				(
					presetsDdl.items=populateList()
				)
			catch()
		)
		
		on presetsDdl selected sel do 
		(
			applyUserPreset sel
			refreshControlState()
		)
		on saveBtn pressed do 
		(
			genSavePresetDialog()
			try (presetsDdl.items=populateList())
			catch()
		)
		on browseBtn pressed do 
		(
			try (ShellLaunch ((getfilenamePath denoiserPath) + @"\vDenoiserPresets\") "")
			catch()
		)
		on refreshBtn pressed do
		(
			try (presetsDdl.items=populateList())
			catch()
		)			
	)
	
	if getDenoiserPath!="" then
	(
		vDenoiserFloater=newRolloutFloater "vDenoise Command-line Helper (v 3.40.01)" 340 612
		addRollOut vDenoiserRoll vDenoiserFloater		
		addRollout vDenoiserPresetsRoll vDenoiserFloater
		applyCustomDefault()
		refreshControlState()
	)
	else
	(
		messagebox "I can't find the V-Ray denoiser Executable.\nMake sure V-Ray 3.40.01 or newer is installed\nfor this version of 3D Studio Max.\n\n\n****************************************\n\n Nothing will happen running the script until then!\n\n****************************************"
	)
)
