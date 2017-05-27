	rollout presetsRoll "Presets Manager:" width:328 height:744
	(
		dropDownList presetsDdl "" pos:[112,8] width:208 height:21
		label lbl1 "Presets:" pos:[8,8] width:88 height:16
		button saveBtn"Save Current as Material Preset" pos:[8,40] width:280 height:24
		button refreshBtn "O" pos:[296,40] width:24 height:24 
		button browseBtn "Open Presets Folder" pos:[8,72] width:312 height:24

		fn populateList = 
		(
			theList=#()
			thefiles=getFiles ((getDir #plugCfg) + @"\BDRF_Mixer_Presets\*.BRDF_Mixer_Preset.txt")
			for i= 1 to theFiles.count do append theList (getfilenamefile(getfilenamefile thefiles[i]))
			theList
		)

		fn savePreset =
		(
			rollout presetNameRoll "Preset Name:" width:184 height:32
			(
				editText presetNameEdt "" pos:[8,8] width:128 height:16 
				button presetSaveBtn "Save" pos:[144,8] width:32 height:16
				
				on presetNameRoll open do 
				(

				)
				
				on SaveBtn pressed do
				(
					presetPath = getDir #plugCfg + @"\BDRF_Mixer_Presets\"
					makeDir presetPath
					presetName = presetNameEdt.text
					valuePairArray=#()
					
					for c in (execute("params.controls")) where classof c == SpinnerControl do
						(
							append valuePairArray #((c.name+".value"),c.value)
						)
					for c in (execute("params.controls")) where (classof c == CheckBoxControl or classof c == CheckButtonControl) do
						(
							append valuePairArray #((c.name+".checked"),c.checked)
						)
					for c in (execute("params.controls")) where classof c == colorPickerControl do
						(
							append valuePairArray #((c.name+".color"),c.color)
						)
				
					presetFilename = presetPath + presetName + ".BRDF_Mixer_Preset.txt"
					thePresetFile = openFile presetFilename mode:"w+"
					format "%\n" presetNameEdt.text to:thePresetFile
					for p in valuePairArray do
						format "%=%\n" p[1] p[2] to:thePresetFile
					close thePresetFile
								
					destroyDialog presetNameRoll

				)
				
			)
			createDialog presetNameRoll
		)
		
		fn applyUserPreset=
		(
			local theLabel
			presetPath = getDir #plugCfg + @"\BDRF_Mixer_Presets\"
			presetName = presetsDdl.items[presetsDdl.selection]
			theFileName=(presetPath+presetNumber+".txt")
			if doesFileExist theFileName then 
			(
				theFile=openFile theFileName mode:"r"
				seek theFile 0
				presetName=readLine theFile
				while not (eof theFile) do
				(
					theLine=readLine theFile
					theWholeLine="params."+theLine
					execute theWholeLine
				)
				close theFile
				print ("Applied preset " + presetName )
			)
			else
			(
				messageBox "Can't find this preset file!"
			)
		)
		
		on presetsRoll open do presetsDdl.items=populateList()
		on presetsDdl selected do applyUserPreset()
		on saveBtn pressed do 
		(
			savePreset()
			presetsDdl.items=populateList()
		)
		on browseBtn pressed do ShellLaunch (getDir #plugCfg + @"\BDRF_Mixer_Presets\") ""
	)
createdialog presetsRoll