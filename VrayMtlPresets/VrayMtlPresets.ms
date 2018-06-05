plugin material VRayMtlPresets
name:"VRayMtl_P"
classID:#(0x6b7ce092, 0x4a5a240e)
extends:VRayMtl replaceUI:false version:1
(
	
	local	presetsRoll
	local	presetNameRoll
	local	currPresetNum=1
	
	/* refreshes the presets dropdown list reading it from disk*/
	fn populateList = 
	(
		theList=#()
		thefiles=getFiles ((getDir #plugCfg) + @"\BDRF_Mixer_Presets\*.BRDF_Mixer_Preset.txt")
		for i= 1 to theFiles.count do append theList (getfilenamefile(getfilenamefile thefiles[i]))
		theList
	)
	/* saves a preset file in plain text format for the MAIN rollout only (much like the fastSSS2 behaviour) */
	fn savePresetFile = 
	(
		presetPath = getDir #plugCfg + @"\BDRF_Mixer_Presets\"
		makeDir presetPath
		presetName = presetNameRoll.presetNameEdt.text
		valuePairArray=#()
		
		for p in (getPropNames meditMaterials[activeMeditSlot].delegate) do
		(
			append valuePairArray #(p, (getProperty meditMaterials[activeMeditSlot].delegate p))
		)
		
		presetFilename = presetPath + presetName + ".BRDF_Mixer_Preset.txt"
		thePresetFile = openFile presetFilename mode:"w"
		for p in valuePairArray do
			format "%\n%\n" p[1] p[2] to:thePresetFile
		close thePresetFile
	)
	/* creates the rollout to choose a preset name, and passes the name to the preset file saving function above*/
	fn savePreset =
	(
		rollout presetNameRoll "Preset Name:" width:184 height:32
		(
			editText presetNameEdt "" pos:[8,8] width:128 height:16 
			button presetSaveBtn "Save" pos:[144,8] width:32 height:16
			
			on presetNameEdt entered txt do
			(
				savePresetFile()
				presetsRoll.presetsDdl.items=populateList()
				destroyDialog presetNameRoll
			)
			on presetSaveBtn pressed do
			(
				savePresetFile()
				presetsRoll.presetsDdl.items=populateList()
				destroyDialog presetNameRoll
			)
		)
		createDialog presetNameRoll
		setFocus presetNameRoll.presetNameEdt 
	)
	/* ap[lies the chose preset values to the controls*/
	fn applyUserPreset sel=
	(
		presetPath = getDir #plugCfg + @"\BDRF_Mixer_Presets\"
		presetName = presetsRoll.presetsDdl.items[sel]
		theFileName=(presetPath+presetName+".BRDF_Mixer_Preset.txt")
		if doesFileExist theFileName then 
		(
			Print (presetname + " Preset File Found")
			theParms=#()
			theVals=#()
			theFile=openFile theFileName mode:"r"
			seek theFile 0
			while not (eof theFile) do
			(
				append theParms (execute (readLine theFile))
				append theVals (execute (readLine theFile))
			)
			close theFile
			print "Applying Preset Values"
			for i=1 to theParms.count do 
			(
				try 
				( 
					oldValuepair=#(theParms[i], getProperty  meditMaterials[activeMeditSlot].delegate theParms[i] )
					setProperty meditMaterials[activeMeditSlot].delegate theParms[i] theVals[i]
					if oldValuePair[2]!=theVals[i] do
					(
						print ("Changed property "+ theParms[i] as string +" from "+ oldValuePair[2] as string + " to " + theVals[i] as string + "\n")
					)
				)
				catch 
				(
					print ("Couldn't set the property " + theParms[i] as string+ " for this shader!\n" )
				)
			)
		)
		else
		(
			messageBox "Can't find this preset file!"
		)
	)	
	
	parameters main rollout:presetsRoll
	(
	
	)
	
	rollout presetsRoll "Presets Manager:" width:328 height:72
	(
		label 'lbl1' "Presets:" pos:[8,12] width:40 height:20 align:#left
		dropdownList 'presetsDdl' "" pos:[56,8] width:220 height:20 align:#left tooltip:"Applies a preset on selection" selection:-1
		button 'refreshBtn' "R" pos:[278,8] width:20 height:20 align:#left tooltip:"Refreshes the presets list"
		button 'browseBtn' "O" pos:[300,8] width:20 height:20 align:#left tooltip:"Opens the presets Folder"
		button 'saveBtn' "Save Current as Material Preset" pos:[8,36] width:312 height:28 align:#left tooltip:"Saves the current material settings to a preset file with a name of your choice."
		
		on presetsRoll open do
		(
			try (presetsDdl.items=populateList())
			catch()
		)
		on presetsDdl selected sel do
		(
			applyUserPreset sel
		)
		on saveBtn pressed do
		(
			savePreset()
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
			try (ShellLaunch (getDir #plugCfg + @"\BDRF_Mixer_Presets\") "")
			catch()
		)
	)
	
)

