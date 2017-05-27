(	
	global vRayLUTERoll,vRayLUTEExportRoll,vRayLUTEFloater
	try 
	(
		closeRolloutFloater vRayLUTEFloater
		destroyDialog vRayLUTERoll
		destroyDialog vRayLUTEExportRoll
	) 
	catch ()

	local theLUTsTempList=theLUTsList=theNamesList=#()
	local folderRoot=variantsPath=variantsType=variantsName=variantsRoot=undefined
	local numVariants = 0
	local doVerbose = false
	local isLogLUT = false 
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
		theLUTsList=theNamesList=#()
		theLUTsList=makeUniqueArray(getFilesRecursive folderRoot "*.cube")
		for l in theLUTsList do append theNamesList (getfilenamefile l)
		if doVerbose do
		(
			print theLutsList
			print theLutsList.count
			print theNamesList
			print theNamesList.count
		)
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
			if folderRoot != "" then
			(
				vRayLUTERoll.pickBtn.text=vRayLUTERoll.pickBtn.tooltip=folderRoot
				vRayLUTERoll.lutsDdl.items = populateList folderRoot
				if vRayLUTERoll.lutsDdl.items.count!= 0 do vRayLUTERoll.lutsDdl.selection=1
			)
			else folderRoot=undefined
			
		)
	
	)
	
	fn detectLogLut lutName=
	(
		isLogLUT = matchpattern lutName pattern:"*Log*" ignoreCase:true
	)
	
	rollout vRayLUTERoll "Main Controls" width:288 height:160
	(
		button 'pickBtn' "Pick LUTs Root Folder..." pos:[8,8] width:248 height:24 align:#left
		button 'saveBtn' "S" pos:[256,8] width:24 height:24 align:#left
		label 'lbl1' "Found LUTs:" pos:[8,40] width:64 height:16 align:#left
		dropdownList 'lutsDdl' "" pos:[8,64] width:272 height:21 align:#left
		checkbox 'autoApplyChk' "" pos:[8,96] width:16 height:16 checked:true align:#left
		label 'lbl2' "Auto Apply selection" pos:[24,96] width:104 height:16 align:#left
		button 'applyBtn' "Apply Selected in " pos:[8,112] width:152 height:40 align:#left
		checkbutton 'logLinCkb' "Lin" pos:[160,112] width:120 height:40 checked:false align:#left
	
		
		
		
		
		
		
		
		checkbox 'autoLogLinChk' "" pos:[160,96] width:16 height:16 checked:true align:#left
		label 'lbl3' "AutoDetect Log LUTs" pos:[176,96] width:104 height:16 align:#left
		
		on vRayLUTERoll open do
		(
			loadPresetFile()
		
		)
		on pickBtn pressed do
		(
			tempPath=(getOpenFileName caption:"Choose one LUT to mark the root:" types:"CUBE file|*.cube|All|*.*|")
			if tempPath != undefined do folderRoot=getfilenamePath tempPath
			
			if folderRoot != undefined then
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
				theLUTName= theNamesList[sel]
				if doesFileExist theLUT do
				(
					vfbControl #lut on
					vfbControl #loadlut theLUT
					if autoLogLinChk.checked then
					(
						detectLogLut theLUTName
						vfbControl #lutconverttolog isLogLUT
						if isLogLut then
						(
							logLinCkb.text="Log"
							
						)
						else
						(
							logLinCkb.text="Lin"
						)
						logLinCkb.state=isLogLut
					)
					else
					(
						vfbControl #lutconverttolog logLinCkb.state
					)
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
		on applyBtn pressed do
		(
				theLUT = theLUTsList[lutsDdl.selection]
				theLUTName= theNamesList[lutsDdl.selection]
				if doesFileExist theLUT do
				(
					vfbControl #lut on
					vfbControl #loadlut theLUT
					if autoLogLinChk.checked then
					(
						detectLogLut theLUTName
						vfbControl #lutconverttolog isLogLUT
						if isLogLut then
						(
							logLinCkb.text="Log"
							
						)
						else
						(
							logLinCkb.text="Lin"
						)
						logLinCkb.state=isLogLut
					)
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
	)
	
	rollout vRayLUTEExportRoll "Variations Exporter" width:288 height:184
	(
		button 'pickBtn' "Pick the Output folder for your Variations..." pos:[8,8] width:272 height:24 align:#left
		label 'infoLbl' "" pos:[8,40] width:272 height:64 align:#left
		button 'saveBtn' "Save Variations" pos:[8,112] width:272 height:40 align:#left
		progressBar 'pb1' "" pos:[13,157] width:262 height:14 color:(color 255 0 0) align:#left value:0
 
		
		
		
		
		on pickBtn pressed do
		(
			variantsPath=(getSaveFileName caption:"Select the path and base name for your variations:" types:"PNG|*.png|JPEG|*.jpg|All|*.*|")
			if variantsPath != undefined then
			(
				variantsType=getfilenameType variantsPath
				variantsName=getfilenameFile variantsPath
				variantsRoot=getfilenamePath variantsPath
				pickBtn.text=pickBtn.tooltip=variantsPath
				numVariants=vrayLUTERoll.lutsDdl.items.count
				infoLbl.text=("The script will save " + numVariants as string + " Variations of your render as \n" + variantsRoot +"\n"+ variantsName+"_LUTNAME_COLORSPACE"+ variantsType)
			)
			else
			(
				pickBtn.text=pickBtn.tooltip= "Pick the Output folder for your variants..."
				infoLbl.text=""
			)
		)
		on saveBtn pressed do
		(
			vR=vRayLUTERoll
			if numVariants != 0 and variantsPath!= undefined do
			(
				for L=1 to numVariants do
				(					

					theLUT = theLUTsList[L]
					theLUTName= theNamesList[L]
					if doesFileExist theLUT then
					(
						if doVerbose do
						(
							print L
							print newFilename
							print theLUT
						)
						vfbControl #lut on
						vfbControl #loadlut theLUT
						if vR.autoLogLinChk.checked then
						(
							detectLogLut theLUTName
							vfbControl #lutconverttolog isLogLUT
						)
						else
						(
							vfbControl #lutconverttolog vR.logLinCkb.checked
						)
						if isLogLUT then 
							newFilename=variantsroot+variantsname+"_"+theNamesList[L]+"_Log"+variantsType
						else
							newFilename=variantsroot+variantsname+"_"+theNamesList[L]+"_Lin"+variantsType						
							
						vfbControl #saveimage newFilename
-- 						
					)
					else
					(
						if doVerbose do print ("couldn't find " + theLUT)
					)
					theValue=ceil((L as float/numVariants)*100.)
					oldColor=pb1.color
					theColor=(color (255*(100.-theValue)) (2.55*theValue) 0)
					pb1.value = theValue
					pb1.color = theColor
					if L==numVariants do 
					(
						infoLbl.text+= "\n\nAll Variations Saved!"
						vfbControl #lut off
					)
					windows.processPostedMessages()					
				)
			)
		)
	)

	vRayLUTEFloater=newRolloutFloater "V-Ray LUTs Explorer V. 0.03" 300 380
	addRollout vRayLUTERoll vRayLUTEFloater
	addRollout vRayLUTEExportRoll vRayLUTEFloater

)

