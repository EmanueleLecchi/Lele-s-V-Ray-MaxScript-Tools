plugin material VRayMtlPresets
name:"VRayMtl_P"
classID:#(0x6b7ce092, 0x4a5a240e)
extends:VRayMtl replaceUI:false version:1
(
	
	local	presetsRoll
	local	presetNameRoll
	local	currPresetNum=1
	
	fn getOwner =
	(
		local deps = for m in (refs.dependents delegate) where classOf m == BRDF_Mixer collect m
		if deps.count == 0 then undefined else deps[1]	
	)
	/* Returns the name of the material that owns this instance           *********Tijn**********				*/ 
	fn getOwnerName =
	(
		local owner = getOwner()
		if owner == undefined then "" else owner.name
	)
	
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
		thePresetFile = openFile presetFilename mode:"w+"
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
			
			on presetSaveBtn pressed do
			(
				savePresetFile()
				presetsRoll.presetsDdl.items=populateList()
				destroyDialog presetNameRoll
			)
		)
		createDialog presetNameRoll
	)
	/* ap[lies the chose preset values to the controls*/
	fn applyUserPreset sel=
	(
		presetPath = getDir #plugCfg + @"\BDRF_Mixer_Presets\"
		presetName = presetsRoll.presetsDdl.items[sel]
		theFileName=(presetPath+presetName+".BRDF_Mixer_Preset.txt")
		if doesFileExist theFileName then 
		(
			theParms=#()
			theVals=#()
			owner = getOwnerName()			
			theFile=openFile theFileName mode:"r"
			seek theFile 0
			while not (eof theFile) do
			(
				append theParms (execute (readLine theFile))
				append theVals (execute (readLine theFile))
			)
			close theFile
			for i=1 to theParms.count do setProperty meditMaterials[activeMeditSlot].delegate theParms[i] theVals[i]
		)
		else
		(
			messageBox "Can't find this preset file!"
		)
	)	
	
	parameters main rollout:presetsRoll
	(
	
	)
	
	rollout presetsRoll "Presets Manager:" width:328 height:744 rolledup:false
	(
		dropDownList presetsDdl "" pos:[112,8] width:208 height:21
		label lbl1 "Presets:" pos:[8,8] width:88 height:16
		button saveBtn"Save Current as Material Preset" pos:[8,40] width:280 height:24
		button refreshBtn "R" pos:[296,40] width:24 height:24 
		button browseBtn "Open Presets Folder" pos:[8,72] width:312 height:24
		
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
		on browseBtn pressed do 
		(
			try (ShellLaunch (getDir #plugCfg + @"\BDRF_Mixer_Presets\") "")
			catch()
		)
		on refreshBtn pressed do
		(
			
			try (presetsDdl.items=populateList())
			catch()
		)			
	)
	
)

