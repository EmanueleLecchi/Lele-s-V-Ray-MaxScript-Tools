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
		theMaxVersion=("20"+(((maxVersion())[1]/1000)-2)as string)
		oslPath=systemTools.getEnvVariable	("VRAY_OSL_PATH_3DSMAX"+theMaxVersion+"_x64")
		if oslPath != undefined do
		(
			denoiserPath=(substring oslPath 1 (oslPath.count-6))+@"tools\vdenoise.exe"
		)
		if not (doesFileExist denoiserPath) do denoiserPath=""
	)

	fn getFileListFromFolder theFile =
	(
		vR=vDenoiserRoll
		theFilenameString=""
		thePath = getfilenamepath theFile
		theName=substring theFile (thePath.count+1) -1
		theBits=filterString theName "."
		case theBits.count of
		(
			default:
			(	
				theFileNameString=thePath + theBits[1] + "."	
				padBit=2
				for b=padBit to theBits.count do		
				(
					if ((theBits[b] as integer )== undefined) then 
					(					
						theFileNameString+=theBits[b] 
						if b < theBits.count do theFileNameString+="."
						theFileNameString
					)
					else 
					(
						for i=theBits[b].count to 1 by -1 do 
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
		theFileNameString
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

		case vR.modeDdl.selection of
		(
			1:
			(
				vR.strengthSpn.value=1.0
				vR.radiusSpn.value=10
			)
			2:
			(
				vR.strengthSpn.value=2.0
				vR.radiusSpn.value=15					
			)
			3:
			(
				vR.strengthSpn.value=0.5
				vR.radiusSpn.value=5						
			)
			4: 
			(
				
			)
		)
		
		if vR.modeDdl.selection==4 then
		(
			vR.strengthSpn.enabled=vR.radiusSpn.enabled=
			vR.lbl10.enabled=vR.lbl9.enabled=true
			vR.boostDdl.enabled=vR.lbl8.enabled=false
		)
		else
		(
			vR.strengthSpn.enabled=vR.radiusSpn.enabled=
			vR.lbl10.enabled=vR.lbl9.enabled=false
			vR.boostDdl.enabled=vR.lbl8.enabled=true
		)
					
		vR.oclDdl.enabled=vR.lbl6.enabled=not vR.forceCpuChk.checked
		
		if not vR.forceCpuChk.checked and vR.oclDdl.selection > 1 then 
		(
			vR.lbl14.enabled=vR.memLimitSpn.enabled=true
		)
		else
		(
			vR.lbl14.enabled=vR.memLimitSpn.enabled=false
		)
				
		if inputFilePath != undefined do
		(
			filtereFileName=getFileListFromFolder inputFilePath
			vR.frameBlendSpn.value=framesBlend
			vR.pickBtn.text=vR.pickBtn.tooltip=filtereFileName
		)
		
		vR.startFSpn.enabled=vR.endFSpn.enabled=vR.intFSpn.enabled=vR.lbl15.enabled=vR.lbl16.enabled=vR.lbl17.enabled=vR.fIntChk.checked
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
				if vR.oclDdl.selection > 1 and vR.memLimitSpn.value != 0 do theCommandLine+=" -memLimit=" +  vR.memLimitSpn.value as string
		)
		
		if vR.frameBlendSpn.value != 1 do theCommandLine+= " -frameBlend="+ vR.frameBlendSpn.value as string		
		if not vR.displayChk.checked do theCommandLine+=" -display=0"
		if vR.autoCloseChk.checked do theCommandLine+=" -autoClose=1"
		if vR.skipExistingChk.checked do theCommandLine+=" -skipExisting=1"		
		if vR.verbosityDdl.selection != 4 do theCommandLine+=" -verboseLevel=" + ( vR.verbosityDdl.selection-1) as string
		if vR.fIntChk.checked do
		(
			theCommandLine+=" -frames=" + vR.startFSpn.value as string +"-"+vR.endFSpn.value as string +","+vR.intFSpn.value as string 
		)
		theCommandLine
	)	
	rollout vDenoiserRoll "vDenoise Options:" width:328 height:504
	(
		checkbox 'doElementsChk' "" pos:[448,32] width:16 height:16 checked:false align:#left 
-- 		tooltip:"If checked, it instructs the denoiser to apply different heuristics and methods to each render element, and then to re-composite it back together once done.\nThis is the strongest method to retain detail, takes longer to process, and may require higher strength to perform at its best.\nIt may have difficulties with objects behind refractions.\nShould that be the case, unchecking the tickbox will denoise only the RGB element, while still considering the other Render Elements to decide what to retain and what to smooth.\nIt's the quickest of the two methods, works well with objects behind refractive ones, and works well already with the default strength and radius values.\nIt's not advised to raise strength or radius too much with this method as artifacts may appear."
		checkbox 'skipExistingChk' "" pos:[248,272] width:16 height:16 checked:false align:#left 
-- 		tooltip:"Skips denoising entirely when output files already exist"
		checkbox 'displayChk' "" pos:[16,272] width:16 height:16 checked:true align:#left 
-- 		tooltip:"Show the Denoising process as it happens"
		checkbox 'autoCloseChk' "" pos:[168,272] width:16 height:16 checked:false align:#left 
-- 		Tooltip:"Close the display after each image\nWarning: it will close after the last of the sequence too."
		checkbox 'forceCpuChk' "" pos:[24,112] width:16 height:16 checked:true align:#left 
-- 		tooltip:"Force non-OpenCl CPU Denoising"
		checkbox 'fIntChk' "" pos:[16,208] width:16 height:16 align:#left		
		dropdownList 'modeDdl' "" pos:[88,28] width:96 height:21 items:#("default", "strong", "mild", "manual") align:#left
-- 		tooltip:"Pick a mode which suits your needs, or choose 'manual' to be able to edit the denoising settings as you prefer."
		dropdownList 'boostDdl' "" pos:[264,28] width:48 height:21 items:#("0", "1", "2") align:#left 
-- 		tooltip:"Boost to apply to one of the preset modes"
		dropdownList 'oclDdl' "" pos:[168,132] width:124 height:21 enabled:false items:#("CPU", "Best OpenCL Device", "All OpenCL Devices") align:#left 
-- 		Tooltip:"Choose if the openCl Kernel should use just the CPU, either the CPU or the GPU depending on which is deemed the quickest, or attempt to use both together.\nThe latter mode is experimental, and will fall back to the fastest OpenCL device available in case fo failure to initiate."
		dropdownList 'verbosityDdl' "" pos:[416,268] width:56 height:21 items:#("none", "Errors", "Warnings", "Information", "All") selection:4 align:#left
		spinner 'strengthSpn' "" pos:[80,64] width:56 height:16 enabled:false range:[0,100,1] align:#left 
-- 		tooltip:"A strength of 1.0 will use the 'NoiseLevel' render element as it is,\nvalues higher than 1.0 will denoise more at the expense of Compute time and Detail loss,\nvalues lower than 1.0 will be quicker to calculate, keep the detail crisp, but will likely retain some noise too."
		spinner 'radiusSpn' "" pos:[192,64] width:56 height:16 enabled:false range:[0,25,10] align:#left 
-- 		tooltip:"Radius will govern how far the blending will happen from a pixel being analysed.\nThe default of 10 works well in most cases,\n value higher than 10 will denoise more, but take longer, use more memory, and potentially blur detail\nwhile lower values will preserve detail better, take less time and memory to compute, but may introduce splotchiness or artefacts."
		spinner 'frameBlendSpn' "" pos:[88,232] width:56 height:16 range:[0,3,0] type:#integer scale:1 align:#left 
-- 		tooltip:"This drives how many frames before and after the one being denoise should be considered for temporal coherence.\n it has no effect on single frames.\nA Value of 0 will deactivate it (not suggested for animations), while there is marginal benefit setting it above 1"
		spinner 'memLimitSpn' "" pos:[424,136] width:48 height:16 enabled:false range:[0,64,0] type:#float align:#left
		spinner 'startFSpn' "" pos:[192,208] width:48 height:16 fieldWidth:32 range:[0,100000,0] type:#integer scale:1 align:#left enabled:false
		spinner 'endFSpn' "" pos:[296,208] width:48 height:16 fieldWidth:32 range:[0,100000,0] type:#integer scale:1 align:#left enabled:false
		spinner 'intFSpn' "" pos:[424,208] width:48 height:16 fieldWidth:32  range:[1,10000,1] type:#integer scale:1 align:#left enabled:false		
		label 'lbl1' "Per-Element Denoising" pos:[328,32] width:112 height:16 align:#left
		label 'lbl2' "Skip Existing Files" pos:[264,272] width:88 height:16 align:#left
		label 'lbl3' "Display Denoising Progress" pos:[32,272] width:136 height:16 align:#left
		label 'lbl4' "Auto-Close" pos:[184,272] width:56 height:16 align:#left
		label 'lbl5' "Force CPU Denoising (Non-OpenCL)" pos:[40,112] width:240 height:16 align:#left
		label 'lbl6' "OpenCL Denoising mode:" pos:[24,136] width:136 height:16 enabled:false align:#left
		label 'lbl7' "Mode Preset:" pos:[16,32] width:72 height:16 align:#left
		label 'lbl8' "Mode Boost:" pos:[192,32] width:72 height:16 align:#left
		label 'lbl9' "Strength:" pos:[16,64] width:56 height:16 enabled:false align:#left
		label 'lbl10' "Radius:" pos:[144,64] width:40 height:16 enabled:false align:#left
		label 'lbl11' "Blend Frames:" pos:[16,232] width:72 height:16 align:#left
		label 'lbl12' "Specify Frame Interval:" pos:[32,208] width:120 height:16 align:#left
		label 'lbl13' "Verbosity:" pos:[360,272] width:48 height:16 align:#left
		label 'lbl14' "GPU Memory Limit (GB):" pos:[304,136] width:120 height:16 enabled:false align:#left
		label 'lbl15' "Start:" pos:[160,208] width:32 height:16 align:#left enabled:false
		label 'lbl16' "End:" pos:[268,208] width:24 height:16 align:#left enabled:false
		label 'lbl17' "NTh:" pos:[396,208] width:24 height:16 align:#left enabled:false
		
		GroupBox 'grp1' "Denoising Quality:" pos:[8,8] width:472 height:80 align:#left
		GroupBox 'grp2' "Performance Options:" pos:[8,88] width:472 height:72 align:#left
		GroupBox 'grp3' "Ancillary Options:" pos:[8,256] width:472 height:40 align:#left
		GroupBox 'grp4' "Denoise!" pos:[8,296] width:472 height:80 align:#left		
		GroupBox 'grp5' "Frame/Sequence Operations:" pos:[8,160] width:472 height:96 align:#left
		button 'pickBtn' "Pick a Frame..." pos:[16,176] width:456 height:24 align:#left 
-- 		tooltip:"Click the button to be able to pick a single file, or one belonging to a sequence (at any point in the sequence), for the denoiser to operate on.\n\nWorks with VRImages and Multi-layer EXRs, best saved with V-Ray's raw file output"	
		button 'goBtn' "Denoise it!" pos:[16,312] width:456 height:56 align:#left 
-- 		tooltip:"Once the parameters have been set,\nthe file or sequence selected,\nclick this button to start the denoising process in a command window"
			
		on vDenoiserRoll open do
		(
			if (getDenoiserPath()) != "" then
				(
					foundDenoiser=true
					refreshControlState()
				)
			else 
				(
					foundDenoiser=false
					messagebox "I can't find the V-Ray denoiser Executable.\nMake sure V-Ray 3.40.01 or newer is installed\nfor this version of 3D Studio Max.\n\n\n****************************************\n\n Nothing will happen running the script until then!\n\n****************************************"
				)

		)
		
		on modeDdl selected i do
		(

			refreshControlState()
		)
		
		on forceCpuChk changed chk do
		(
			refreshControlState()
		)
		
		on oclDdl selected i do
		(
			refreshControlState()
		)

		on fIntChk changed state do
		(
			refreshControlState()
		)
		
		on pickBtn pressed do 
		(
			inputFilePath=getOpenFileName caption:"Choose one file in the sequence:" types:"OpenEXR File|*.exr|VRImage File|*.vrimg|"
			refreshControlState()

		)
		
		on startFSpn changed val do
		(
			if endFSpn.value < val do endFSpn.value = val
		)
		
		on endFSpn changed val do
		(
			if startFSpn.value > val do startFSpn.value = val
		)		
		
		on goBtn pressed do
		(
			if inputFilePath!=undefined do
			(	
				buildCommandLine()
				theString = denoiserPath +  theCommandLine
				print theString
				if keyboard.controlPressed then 
				(
					setclipboardText theString
				)
				else
				(
					shellLaunch denoiserPath theCommandLine
				)
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
		vDenoiserFloater=newRolloutFloater "vDenoise Command-line Helper (v 3.40.01)" 500 612
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
