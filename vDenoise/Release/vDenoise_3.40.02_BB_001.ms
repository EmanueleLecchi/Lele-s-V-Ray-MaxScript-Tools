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
	local bbCommandArray=#()
	local foundDenoiser = false
	local denoiserPath=theCommandLine=""
	local inputFilePath=undefined
	local FilteredFilename = ""
	local framePadding=0
	local framesBlend=1
	local presetNameRoll
	local thePresetsList=#()
	local bbPath=""
	
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

	fn getBBPath =
	(
		if (doesFileExist @"C:\Program Files (x86)\Autodesk\Backburner\cmdjob.exe") then
		bbPath=@"C:\Program Files (x86)\Autodesk\Backburner\cmdjob.exe"
		else
		bbPath=""
	)
	
	fn padToNDigits framePadding numToPad =
	(
		numToPad = numToPad as string
		while numToPad.count < 4 do numToPad = append "0" numToPad
		numToPad
	)
	
	fn getFileListFromFolder theFile =
	(
		vR=vDenoiserRoll
		theFilenameString=""
		thePath = getfilenamepath theFile
		theName=substring theFile (thePath.count+1) -1
		theInputStringBits=filterString theName "."
		
		case theInputStringBits.count of
		(
			default:
			(	
				theFileNameString=thePath + theInputStringBits[1] + "."	
				padBit=2 --start from the second part of the filtered name string. Path and filename are already added above.
				for b=padBit to theInputStringBits.count do		
				(
					if ((theInputStringBits[b] as integer )== undefined) or theInputStringBits[b]=="" then 
					(					
						theFileNameString+=theInputStringBits[b] 
						if b < theInputStringBits.count do theFileNameString+="."
						theFileNameString
					)
					else 
					(
						for i=1 to theInputStringBits[b].count do 
						(
							theFileNameString+="?"
							
						)
						framePadding=theInputStringBits[b].count
						theFileNameString+="."
					)
				)
				theFileNameString
			)
			2:
			(
				theFileNameString=thePath
				for i=theInputStringBits[1].count to 1 by -1 do
				(
					
					if ((substring theInputStringBits[1] i theInputStringBits[1].count ) as integer ) == undefined do 
					( 
						if i == theInputStringBits[1].count-1 then 
						(
							framePadding=0
							framesBlend=1
						)
						else
						(
							framePadding=theInputStringBits[1].count-i
							framesBlend=1
						)
						exit
					)
				)
				theFileNameString+=(subString theInputStringBits[1] 1 (theInputStringBits[1].count-framePadding))
				if framePadding !=0 do
				(
					for i=1 to framePadding do
					(
						theFileNameString+="?"
					)
				)
				theFileNameString+="."+theInputStringBits[2]
			)
			1:
			(
				theFileNameString=thePath + theInputStringBits[1]
				messageBox "I can't seem to find an extension for the file you picked.\nThe denoiser may not work until that is fixed."
			)
			
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
		presetName = toLower(presetNameRoll.presetNameEdt.text)
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
		try (deleteFile presetFilename) catch()	--simple way to delete a preset if already there. safety net, normally not necessary at all.
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
		presetsPath = (getfilenamePath denoiserPath) + @"vDenoiserPresets\"
		presetName = vDenoiserPresetsRoll.presetsDdl.items[sel]
		presetFilename=(presetsPath+presetName+".vDenoiserPreset.txt")
		if doesFileExist presetFilename and (getFileSize presetFilename)!=0L  then 
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
			true
		)
		else
		(
			if not (doesFileExist presetFilename) do messageBox "Can't find this preset file!"
			if (getFileSize presetFilename)==0L do messageBox ("The preset file\n\n" + presetFilename + "\n\nseems empty or otherwise corrupt.\nPlease Delete it and create it again.")
			false
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
				
		if inputFilePath != undefined then
		(
			filtereFileName=getFileListFromFolder inputFilePath
			vR.frameBlendSpn.value=framesBlend
			vR.pickBtn.text=vR.pickBtn.tooltip=filtereFileName
		)
		
		else
		(
			filtereFileName=""
-- 			vR.frameBlendSpn.value=framesBlend
			vR.pickBtn.text=vR.pickBtn.tooltip="Pick a Frame..."
			
		)
		
		vR.bbPausedChk.enabled=vR.bbFPTSpn.enabled=vR.lbl19.enabled=vR.lbl20.enabled=vR.bbChk.checked
		vR.startFSpn.enabled=vR.endFSpn.enabled=vR.intFSpn.enabled=vR.lbl15.enabled=vR.lbl16.enabled=vR.lbl17.enabled=vR.fIntChk.checked
	)	
	
	fn applyCustomDefault =
	(
		foundDefault=false
		for f=1 to thePresetsList.count do
		(
			if (toLower thePresetsList[f]) == "default" do
			(
				if (applyUserPreset f) do
				(
					refreshControlState()
					print ( "Applied Custom Default Preset!")
					foundDefault=true
					vDenoiserFloater.rollouts[2].open=false
					vDenoiserFloater.size=[vDenoiserFloater.size[1],(vDenoiserFloater.size[2]-40)]
				)
			)
		)
		if not foundDefault do vDenoiserFloater.rollouts[2].open=true
		refreshControlstate()
	)
	
	fn buildCommandLine isBB=
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
		)
		
		if not vR.forceCpuChk.checked do
		(
				theCommandLine+=" -useGpu=" +  (vR.oclDdl.selection-1) as string
				if vR.oclDdl.selection > 1 and vR.memLimitSpn.value != 0 do theCommandLine+=" -memLimit=" +  vR.memLimitSpn.value as string
		)

		if vR.doElementsChk.checked do theCommandLine+= " -elements=1"			
		if vR.frameBlendSpn.value != 1 do theCommandLine+= " -frameBlend="+ vR.frameBlendSpn.value as string		
		if not vR.displayChk.checked do theCommandLine+=" -display=0"
		if vR.autoCloseChk.checked do theCommandLine+=" -autoClose=1"
		if vR.skipExistingChk.checked do theCommandLine+=" -skipExisting=1"		
		if vR.verbosityDdl.selection != 4 do theCommandLine+=" -verboseLevel=" + ( vR.verbosityDdl.selection-1) as string
		if vR.fIntChk.checked and not isBB do
		(
			theCommandLine+=" -frames=" + vR.startFSpn.value as string +"-"+vR.endFSpn.value as string +","+vR.intFSpn.value as string 
		)
		theCommandLine
	)	
	
	fn buildBBData framesPerTask isPaused=
	(
		bbCommandArray=#()
		/*
		For BB submission, i need the expanded file sequence, be it a single file, or the frame interval, 
		to then expand each file entry into a task, by the frames per task value.
		I can do so by ALWAYS passing it the frame interval, regardless of UI setup.
		UI frame interval should be considered only to prepare the BB command building task.
		*/
		if inputFilePath!=undefined do
		(		
			vR = vDenoiserRoll	
			theTempCommandLine=buildCommandLine true
			fileMask=(getFileListFromFolder inputFilePath) 
			theFiles=getFiles fileMask
-- 			print theFiles
			tempArray=#()
			if vR.fIntChk.checked then --interval selected. explicit filenames can be built.
			(
				for n = vR.startFSpn.value to vR.endFSpn.value by vR.intFSpn.value do
				(
					
					for f in theFiles do
					(
						if matchpattern f pattern:("*"+(padToNDigits framePadding n)+"*") do
						(
							append tempArray #(f,(padToNDigits framePadding n))
						)
					)
				)
			)
			else		--no interval, pick by the mask
			(
				stringToFind=""
				if framePadding!= 0 then
				(
					for p=0 to framePadding do
					(
						stringToFind+="?"
					)
					
					minFrame=(subString (getfilenamefile theFiles[1]) (findString (getfilenamefile theFiles[1]) stringToFind) -1) as integer
	-- 				minFrame=(subString (getfilenamefile "E:\_VRAY\___Dev\vDenoise\denoiseMe3vfbSave.exr" ) (findString (getfilenamefile "E:\_VRAY\___Dev\vDenoise\denoiseMe3vfbSave.exr" ) "?") -1) as integer
					
					maxFrame=(subString (getfilenamefile theFiles[theFiles.count]) (findString (getfilenamefile theFiles[theFiles.count]) stringToFind) -1) as integer
				)
				else
				(
					minFrame=maxFrame=1
				)
				
				for n = minFrame to maxFrame do
				(
					for f=1 to theFiles.count do
					(
						if framePadding!= 0 then
						(
							if matchpattern f pattern:("*"+(padToNDigits framePadding n)+"*") do
							(
								append tempArray #(theFiles[f],(padToNDigits framePadding n))
							)
						)
						else
						(
							append tempArray #(theFiles[f],"1")
						)
					)
				)
			)
			numTasks=if (mod tempArray.count framesPerTask ) !=0.0 then (tempArray.count/framesPerTask)+1 else (tempArray.count/framesPerTask)
			q=1
			for f=1 to numTasks do
			(	
				outputFilesList=#()
				jobname=""
				theString=""
				theTaskString=""
				theTaskString=" -frames="
				for t=0 to framesPerTask-1 do
				(
					if (q+t)<=tempArray.count do
					(
						theTaskString+=tempArray[(q+t)][2]+"-"+tempArray[(q+t)][2]+",1;"
						append outputFilesList tempArray[(q+t)][1]
					)

				)
				q=(framesPerTask*f)+1
			
				jobname=substituteString localTime "/" "-"
				jobname=substituteString jobname ":" "-"
				jobname=substituteString jobname " " "_"
				jobname= ("vDenoiseCmdJob_") + jobname
				theString = "\""+ bbPath 
				theString += "\" -jobname:" + jobname 
				theString += " -description:\"" + ("vDenoise Script Job") + "\""
				if isPaused do theString += " -suspended"
				theString += " \"" + denoiserPath +"\""+ theCommandLine
				theString += theTaskString
				theString = substring theString 1 (theString.count-1)
				theString = substituteString theString "\\" "\\\\"
				
				append bbCommandArray theString
			)
			for b in bbCommandArray do vrayshelllaunch b
			print "BackBurner Launched!"
			print bbCommandArray
		)				
	)	
	
	rollout vDenoiserRoll "vDenoise Options:" width:480 height:400
	(
		checkbox 'doElementsChk' "" pos:[456,32] width:16 height:16 checked:false align:#left 
		tooltip:"If checked, it instructs the denoiser to apply different heuristics and methods to each render element, and then to re-composite it back together once done.\n
This is the strongest method to retain detail, takes longer to process, and may require higher strength to perform at its best.
It may have however encounter difficulties with objects behind refractions.\n
Should that be the case, unchecking the tickbox will denoise only the RGB element, while still considering the other Render Elements to decide what to retain and what to smooth.\n
This is the quickest of the two methods, works well with objects behind refraction, and works well with the default strength and radius values (1.0/10).
It's not advised to raise strength or radius too much with the RGB-Only method as artifacts may appear."
		checkbox 'skipExistingChk' "" pos:[200,248] width:16 height:16 checked:false align:#left
		tooltip:"Skips denoising entirely when output files already exist."
		checkbox 'displayChk' "" pos:[16,248] width:16 height:16 checked:true align:#left 
		tooltip:"Show the Denoising process as it happens."
		checkbox 'autoCloseChk' "" pos:[120,248] width:16 height:16 checked:false align:#left 
		Tooltip:"Close the display after each image\nWarning: it will close after the last of the sequence too."
		checkbox 'forceCpuChk' "" pos:[24,112] width:16 height:16 checked:true align:#left 
		tooltip:"Force non-OpenCl CPU Denoising."
		checkbox 'fIntChk' "" pos:[16,208] width:16 height:16 align:#left
		tooltip:"Specify the exact frame Interval to be denoised within a sequence."
		checkbox 'bbChk' "" pos:[16,296] width:16 height:16 align:#left checked:false
		tooltip:"Submit to BackBurner.\nMake Sure you are properly set up!"
		checkbox 'bbPausedChk' "" pos:[280,296] width:16 height:16 align:#left checked:true enabled:false
		tooltip:"Submit Paused"
		dropdownList 'modeDdl' "" pos:[88,28] width:96 height:21 items:#("default", "strong", "mild", "manual") align:#left
		tooltip:"Pick a mode which suits your needs, or choose 'manual' to be able to edit the denoising settings as you prefer."
		dropdownList 'boostDdl' "" pos:[264,28] width:48 height:21 items:#("0", "1", "2") align:#left 
		tooltip:"Boost to apply to one of the preset modes"
		dropdownList 'oclDdl' "" pos:[168,132] width:124 height:21 enabled:false items:#("CPU", "Best OpenCL Device", "All OpenCL Devices") align:#left 
		Tooltip:"Choose if the openCl Kernel should use\n
just the CPU,\n\neither the CPU or the GPU (depending on which is deemed the quickest),\n\nor attempt to use both together.\n
The latter mode is experimental, and will fall back to the fastest OpenCL device available in case of failure to initiate."
		dropdownList 'verbosityDdl' "" pos:[376,244] width:96 height:21 fieldWidth:64 items:#("none", "Errors", "Warnings", "Information", "All") selection:4 align:#left
		tooltip:"Self Explanatory Verbosity Level list."
		spinner 'strengthSpn' "" pos:[80,64] width:56 height:16 enabled:false range:[0,100,1] align:#left 
		tooltip:"A strength of 1.0 will use the 'NoiseLevel' render element as it is,\n
values HIGHER than 1.0 will denoise more at the expense of Compute time and Detail loss,\n
values LOWER than 1.0 will be quicker to calculate, keep the detail crisp, but will likely retain some noise too."
		spinner 'radiusSpn' "" pos:[192,64] width:56 height:16 enabled:false range:[0,25,10] align:#left 
		tooltip:"Radius will govern how far the blending will happen from a pixel being analysed.\n
The default of 10 works well in most cases,\n
values HIGHER than 10 will denoise more, but take longer, use more memory, and potentially blur detail,\n
while LOWER values will preserve detail better, take less time and memory to compute, but may introduce splotchiness or artefacts."
		spinner 'frameBlendSpn' "" pos:[416,64] width:56 height:16 range:[0,3,1] type:#integer scale:1 align:#left 
		tooltip:"This drives how many frames before and after the one being denoise should be considered for temporal coherence.\n
It has no effect on single frames.\n
A Value of 0 will deactivate it (not suggested for animations),
while there is marginal benefit setting it above 1 (i.e. it's often not needed at all.)"
		spinner 'memLimitSpn' "" pos:[424,136] width:48 height:16 enabled:false range:[0,64,0] type:#float align:#left
		tooltip:"Specify a maximum memory limit for GPU operations. The default of 0 means 'use all available memory'"
		spinner 'startFSpn' "" pos:[192,208] width:48 height:16 enabled:false range:[0,100000,0] type:#integer scale:1 fieldwidth:32 align:#left
		tooltip:"Number of the first frame of the sequence to be denoised"
		spinner 'endFSpn' "" pos:[268,208] width:48 height:16 enabled:false range:[0,100000,0] type:#integer scale:1 fieldwidth:32 align:#left
		tooltip:"Number of the last frame of the sequence to be denoised"
		spinner 'intFSpn' "" pos:[348,208] width:48 height:16 enabled:false range:[1,10000,1] type:#integer scale:1 fieldwidth:32 align:#left		
		tooltip:"Increment by these many frames (the same as Max's render dialog,'Every Nth Frame')"
		spinner 'bbFPTSpn' "" pos:[224,296] width:48 height:16 range:[1,10000,3] type:#integer scale:1 align:#left enabled:false
		tooltip:"Number of frames per denoising task"		
		label 'lbl1' "Per-Element Denoising" pos:[344,32] width:112 height:16 align:#left
		label 'lbl2' "Skip Existing Files" pos:[216,248] width:88 height:16 align:#left
		label 'lbl3' "Display Progress" pos:[32,248] width:80 height:16 align:#left
		label 'lbl4' "Auto-Close" pos:[136,248] width:56 height:16 align:#left
		label 'lbl5' "Force CPU Denoising (Non-OpenCL)" pos:[40,112] width:176 height:16 align:#left
		label 'lbl6' "OpenCL Denoising mode:" pos:[24,136] width:136 height:16 enabled:false align:#left
		label 'lbl7' "Mode Preset:" pos:[16,32] width:72 height:16 align:#left
		label 'lbl8' "Mode Boost:" pos:[192,32] width:72 height:16 align:#left
		label 'lbl9' "Strength:" pos:[16,64] width:56 height:16 enabled:false align:#left
		label 'lbl10' "Radius:" pos:[144,64] width:40 height:16 enabled:false align:#left
		label 'lbl11' "Blend Frames:" pos:[344,64] width:72 height:16 align:#left
		label 'lbl12' "Specify Frame Interval:" pos:[32,208] width:120 height:16 align:#left
		label 'lbl13' "Verbosity:" pos:[320,248] width:48 height:16 align:#left
		label 'lbl14' "GPU Memory Limit (GB):" pos:[304,136] width:120 height:16 enabled:false align:#left
		label 'lbl15' "Start:" pos:[160,208] width:32 height:16 enabled:false align:#left
		label 'lbl16' "End:" pos:[240,208] width:24 height:16 enabled:false align:#left
		label 'lbl17' "NTh:" pos:[320,208] width:24 height:16 enabled:false align:#left
		label 'lbl18' "Submit To BackBurner" pos:[32,296] width:112 height:16 align:#left	
		label 'lbl19' "Submit Paused" pos:[296,296] width:112 height:16 align:#left enabled:false
		label 'lbl20' "Frames per Task" pos:[144,296] height:16 align:#left	enabled:false
		
		GroupBox 'grp1' "Denoising Quality:" pos:[8,8] width:472 height:80 align:#left
		GroupBox 'grp2' "Performance Options:" pos:[8,88] width:472 height:72 align:#left
		GroupBox 'grp3' "Ancillary Options:" pos:[8,232] width:472 height:40 align:#left
		GroupBox 'grp4' "Denoise!" pos:[8,328] width:472 height:64 align:#left		
		GroupBox 'grp5' "Frame/Sequence Operations:" pos:[8,160] width:472 height:72 align:#left
		GroupBox 'grp6' "Remote Submission:" pos:[8,280] width:472 height:40 align:#left
	
		button 'pickBtn' "Pick a Frame..." pos:[16,176] width:456 height:24 align:#left 
		tooltip:"Click the button to be able to pick a single file belonging to a sequence (at any point in the sequence), for the denoiser to operate on.\n
Works with VRImages and Multi-layer EXRs, best saved with V-Ray's raw file output"	
		button 'goBtn' "Denoise it!" pos:[16,344] width:456 height:40 align:#left 
		tooltip:"Once the parameters have been set and the file selected, click this button to start the denoising process in a command window"

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
		
		on bbChk changed state do
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
				if bbChk.checked then
				(
					getBBPath()
					buildBBData bbFPTSpn.value bbPausedChk.checked
				)
				else
				(
					buildCommandLine false
					theString = denoiserPath +  theCommandLine
					print theString
					if keyboard.controlPressed then 
					(
						setclipboardText theString
						messageBox "Command String Copied to Clipboard!"
					)
					else
					(
						shellLaunch denoiserPath theCommandLine
					)
				)
			)
		)
		
	)
	
	theString = "C:\Program Files\Chaos Group\V-Ray\3dsmax 2017 for x64\tools\vdenoise.exe -inputfile=\"D:\v018\snow_v018.????.exr\""
	substring theString ((findstring theString "-inputfile=")+11) -1
	rollout vDenoiserPresetsRoll "Presets Manager:" width:480 height:40
	(
		dropdownList 'presetsDdl' "" pos:[56,10] width:112 height:21 align:#left tooltip:"This lists all of your saved presets."
		label 'lbl1' "Presets:" pos:[8,14] width:48 height:16 align:#left
		button 'saveBtn' "Save Current as Preset" pos:[176,8] width:128 height:24 align:#left tooltip:"Save the current vDenoiser settings as a preset.\nClicking here will pop up a small window to enter a preset name into.\nSaving a preset with the name 'Default' (non case-sensitive) will load it at startup instead of the factory settings."
		button 'refreshBtn' "R" pos:[312,8] width:24 height:24 align:#left tooltip:"Press to manually refresh the preset list."
		button 'browseBtn' "Open Presets Folder" pos:[344,8] width:128 height:24 align:#left tooltip:"Press to browse directly to the stored presets folder."
		
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
		on refreshBtn pressed do
		(
			try (presetsDdl.items=populateList())
			catch()
		)
		on browseBtn pressed do
		(
			try (ShellLaunch ((getfilenamePath denoiserPath) + @"\vDenoiserPresets\") "")
			catch()
		)
	)
	
	if getDenoiserPath!="" then
	(
		vDenoiserFloater=newRolloutFloater "vDenoise Command-line Helper (v 3.40.02)" 500 482
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
