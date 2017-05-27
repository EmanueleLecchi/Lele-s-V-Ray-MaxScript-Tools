(

	global vRayLUTERoll
	try (destroyDialog vRayLUTERoll) catch ()

	local theLUTsList=theNamesList=#()
	local folderRoot=""

	fn getFilesRecursive root pattern =
	(
		dir_Array=#()
		dir_Array[1] = (root+"\\")
		join dir_array ( GetDirectories (root+"/*"))

		for d in dir_array do
			join dir_array (GetDirectories (d+"/*"))
		my_files = #()
		for f in dir_array do
			join my_files (getFiles (f + pattern))
		my_files
	)

	fn populateList folderRoot = 
	(
		
		theLUTsList=getFilesRecursive folderRoot "*.cube"
		for l in theLUTsList do append theNamesList (getfilenamefile l)
		theNamesList
	)
	
	fn savePresetFile = 
	(
		vR = vRayLUTERoll
		presetsPath = (getDir #plugCfg) + @"\V-Ray_LUTs_Explorer\"
		makeDir presetsPath
		presetName = "defaultFolder.txt"
		presetFilename = presetsPath + presetName
		thePresetFile = openFile presetFilename mode:"w+"
		format folderRoot to:thePresetFile
		flush thePresetFile
		close thePresetFile
	)
	
	fn loadPresetFile =
	(
		presetFilename = ((getDir #plugCfg) + @"\V-Ray_LUTs_Explorer\defaultFolder.txt")
		if (doesFileExist presetFilename) do
		(
			thePresetFile = openFile presetFilename mode:"r"
			seek thePresetFile 0
			folderRoot=readline thePresetFile
			close thePresetFile
			if folderRoot != "" do
			(
				vRayLUTERoll.pickBtn.text=vRayLUTERoll.pickBtn.tooltip=folderRoot
				vRayLUTERoll.lutsDdl.items = populateList folderRoot
				if vRayLUTERoll.lutsDdl.items.count!= 0 do vRayLUTERoll.lutsDdl.selection=1
			)
			
		)
	
	)
	
	rollout vRayLUTERoll "V-Ray LUTs Explorer V 0.01" width:288 height:160
	(
		button 'pickBtn' "Pick LUTs Root Folder..." pos:[8,8] width:248 height:24 align:#left
		button 'saveBtn' "S" pos:[256,8] width:24 height:24 align:#left
		label 'lbl1' "Found LUTs:" pos:[8,40] width:64 height:16 align:#left
		dropdownList 'lutsDdl' "" pos:[8,64] width:272 height:21 align:#left
		checkbox 'autoApplyChk' "" pos:[8,96] width:16 height:16 checked:true align:#left
		label 'lbl2' "Auto Apply selection (Hold Shift for Lin, Ctrl for Log)" pos:[24,96] width:249 height:16 align:#left
		button 'applyBtn' "Apply Selected in " pos:[8,112] width:152 height:40 align:#left
		checkbutton 'logLinCkb' "Log" pos:[160,112] width:120 height:40 checked:true align:#left
	
		
		
		
		on vRayLUTERoll open do
		(
			loadPresetFile()
		)
		
		on pickBtn pressed do
		(
			folderRoot=getfilenamePath(getOpenFileName caption:"Choose one LUT to mark the root:" types:"CUBE file|*.cube|All|*.*|")
			if folderRoot != "" and folderRoot != undefined then
			(
				pickBtn.text=pickBtn.tooltip=folderRoot
				lutsDdl.items = populateList folderRoot
				if lutsDdl.items.count!= 0 do lutsDdl.selection=1
			)
			else
			(
				pickBtn.text=pickBtn.tooltip= "Pick LUTs Root Folder..."
				lutsDdl.items = #()
			)
		
		)
		
		on saveBtn pressed do
		(
			savePresetFile()
		)
		
		on lutsDdl selected sel do
		(
			if autoApplyChk.checked do
			(
				theLUT = theLUTsList[sel]
				if doesFileExist theLUT do
				(
					vfbControl #lut on
					vfbControl #loadlut theLUT
					vfbControl #lutconverttolog logLinCkb.state
		-- 				vfbControl #lut off
		-- 				vfbControl #lut on
					if keyboard.shiftPressed do 
					(
						logLinCkb.text="Lin"
						logLinCkb.state=false
						vfbControl #lutconverttolog false
						vfbControl #lut off				
						vfbControl #lut on
					)
					if keyboard.controlPressed do 
					(
						logLinCkb.text="Log"
						logLinCkb.state=true
						vfbControl #lutconverttolog true
						vfbControl #lut off				
						vfbControl #lut on
					)
				)
			)
		)
		
		on logLinCkb changed state do
		(
			if state then 
			(
				logLinCkb.text="Log"
				vfbControl #lutconverttolog state
				vfbControl #lut off
				vfbControl #lut on
			)
			else
			(
				logLinCkb.text="Lin"
				vfbControl #lutconverttolog state
				vfbControl #lut off				
				vfbControl #lut on
			)
			
		)
		
		on applyBtn pressed do
		(
				theLUT = theLUTsList[lutsDdl.selection]
				if doesFileExist theLUT do
				(
					vfbControl #lut on
					vfbControl #loadlut theLUT
					vfbControl #lutconverttolog logLinCkb.state
		-- 				vfbControl #lut off
		-- 				vfbControl #lut on
					if keyboard.shiftPressed do 
					(
						logLinCkb.text="Lin"
						logLinCkb.state=false
						vfbControl #lutconverttolog false
						vfbControl #lut off				
						vfbControl #lut on
					)
					if keyboard.controlPressed do 
					(
						logLinCkb.text="Log"
						logLinCkb.state=true
						vfbControl #lutconverttolog true
						vfbControl #lut off				
						vfbControl #lut on
					)
				)			
		)
	)
	
	createDialog vRayLUTERoll
	--getFilesRecursive "e:\_LUTS" "*.cube"
	)
