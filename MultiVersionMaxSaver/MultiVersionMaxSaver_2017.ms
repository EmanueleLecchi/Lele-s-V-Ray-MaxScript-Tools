(
	/*
	Script to collect all max files, open them, and save them out as previous versions.
	*/
	
	global multiVersionSaverRoll
	try (destroyDialog multiVersionSaverRoll) catch()
	
	local inputMaxFiles = #()
	local mainRoot=undefined	
	local totSize=0
	local initialDir = (getDir #maxroot) 
	
	fn getFilesRecursive root pattern =
	(
		dir_Array=#()
-- 		dir_Array[1] = (root+"\\")
		join dir_array ( GetDirectories (root+"/*"))

		for d in dir_array do
			join dir_array (GetDirectories (d+"/*"))
		my_files = #()
		for f in dir_array do
			join my_files (getFiles (f + pattern))
		my_files
	)
	
	fn savePreviousMaxVersions inFile do_14 do_15 do_16 =
	(
		if do_14 do saveMaxFile (getFilenamePath inFile + getFilenameFile inFile + "_2014.max") saveAsVersion:2014 clearNeedSaveFlag:false useNewFile:false quiet:true 
		if do_15 do saveMaxFile (getFilenamePath inFile + getFilenameFile inFile + "_2015.max") saveAsVersion:2015 clearNeedSaveFlag:false useNewFile:false quiet:true 
		if do_16 do saveMaxFile (getFilenamePath inFile + getFilenameFile inFile + "_2016.max") saveAsVersion:2016 clearNeedSaveFlag:false useNewFile:false quiet:true 
	)
	
	fn toggleUI enabled =
	(
		for i=3 to 9 do
		(
			multiVersionSaverRoll.controls[i].enabled=enabled
		)
	)
	
	fn fillInfoLabel getSizes = 
	(
		infoStr=""
		infoStr+="Total number of Input Max Files:" + inputMaxFiles.count as string + "\n"

		numVersions=0
		
		if getSizes do 
		(		
			totSize=0
			for m in inputMaxFiles do totSize+=(getFileSize m)/(1024.*1024.)
		)
		infoStr+="Total Mb to be read:" + totSize as string + "\n"
		if multiVersionSaverRoll.ckb1.checked do 
		(
			infoStr+="Saving 2014 Version\n"
			numVersions+=1
		)
		if multiVersionSaverRoll.ckb2.checked do 
		(
			infoStr+="Saving 2015 Version\n"
			numVersions+=1
		)
		if multiVersionSaverRoll.ckb3.checked do 
		(
			infoStr+="Saving 2016 Version\n"
			numVersions+=1
		)
		infoStr+="Total Mb to be written:" + (totSize*numVersions) as string + "\n"
		multiVersionSaverRoll.lbl1.text=infoStr
		
	)
	

	
	
	rollout multiVersionSaverRoll "Multi-Version Max File Saver - For Max 2017" width:464 height:288
	(
		button 'browseBtn' "Browse for Root:" pos:[8,8] width:96 height:24 align:#left		
		editText 'edt1' "" pos:[104,8] width:352 height:24 enabled:false align:#left enabled:false
		groupBox 'grp1' "InfoBox" pos:[8,72] width:448 height:144 align:#left enabled:false
		label 'lbl1' "" pos:[16,88] width:432 height:120 align:#left enabled:false
		button 'goBtn' "Process Files!" pos:[8,224] width:448 height:32 align:#left enabled:false
		progressBar 'pb1' "ProgressBar" pos:[8,264] width:448 height:16 align:#left enabled:false
		checkButton 'ckb1' "Save 2014" pos:[8,40] width:96 height:24 checked:true align:#left enabled:false
		checkButton 'ckb2' "Save 2015" pos:[112,40] width:96 height:24 checked:true align:#left enabled:false
		checkButton 'ckb3' "Save 2016" pos:[216,40] width:96 height:24 checked:true align:#left enabled:false
		
		on browseBtn pressed do
		(
			newRoot= getSavePath caption:"Pick the root you want to search Max files in..." initialDir:initialDir
			if newRoot!= undefined then 
			(
				mainRoot=initialDir=edt1.text=newRoot
				toggleUI true
				inputMaxFiles= getFilesRecursive mainRoot "*.max"
				fillInfoLabel true
			)
			else
			(
				mainRoot=undefined
				edt1.text=""
				toggleUI false
				inputMaxFiles=#()
				lbl1.text = ""
			)
		)
		
		on ckb1 changed state do
		(
			if not state do
			(
				if not ckb2.checked and not ckb3.checked do ckb1.checked=true
			)
			fillInfoLabel false
		)
		on ckb2 changed state do
		(
			if not state do
			(
				if not ckb1.checked and not ckb3.checked do ckb2.checked=true
			)
			fillInfoLabel false
		)		
		on ckb3 changed state do
		(
			if not state do
			(
				if not ckb2.checked and not ckb1.checked do ckb3.checked=true
			)
			fillInfoLabel false
		)			
		
		on goBtn pressed do
		(
			for m=1 to inputMaxFiles.count do
			(
				windows.processPostedMessages()
				setVRaySilentMode()
				loadMaxFile inputMaxFiles[m] useFileUnits:true quiet:true
				savePreviousMaxVersions (maxFilePath+maxFileName) ckb1.checked ckb2.checked ckb3.checked
				pb1.value=(m as float / inputMaxFiles.count)*100.0
			)
			lbl1.text += "\n\n ALL DONE!"
		)
	)
		
	createDialog multiVersionSaverRoll
)