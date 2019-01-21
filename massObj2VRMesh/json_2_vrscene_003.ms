(
	
	global jsonRoll
	try (destroydialog jsonRoll) catch()
	
	rootPath=@"F:\island-basepackage-v1\island\"
	jsonsRoot=rootPath+@"json\_TEST\"
	objsRoot=rootPath+@"obj\"
-- 	jsonFilePath=@"F:\island-basepackage-v1\island\json\isBeach\isBeach_xgHibiscus.json"
	sourceGeoString=""
	instanceName=""
	sourceProxyPath=""
	newSource=true
	jsonFile=undefined
	instanceCounter=0
	theJsons=#()
	proxyDisplayMode=undefined
	theSource=undefined
	sourceEndingLine=0
	
	fn getFilesRecursive root pattern =
	(
		dir_Array=#()
		dir_Array[1] = (root+"\\")

		for d in dir_array do
			join dir_array (GetDirectories (d+"/*"))
		my_files = #()
		for f in dir_array do
			join my_files (getFiles (f + pattern))
		my_files
	)

	fn resetUIStatus = 
	(
		timeSliderWasVisible=undefined
		trackBarWasVisible=undefined
		statusPanelWasVisible=undefined
		expertModeWasActive=undefined
		matEditorWasOpen=undefined		
	)
	
	fn getUIStatus =
	(
		timeSliderWasVisible=timeslider.isVisible()
		trackBarWasVisible=trackbar.visible
		statusPanelWasVisible=statusPanel.visible
		expertModeWasActive=cui.getExpertMode() 
		matEditorWasOpen = MatEditor.isOpen()
	)	
	
	fn setSuperExpertMode status =
	(
		if status then 		--if the bool is true/1/on then 
		( 
			getUIStatus()	--we gather the UI status right before  changing it
			
			timeslider.Setvisible false		--turn off the time slider
			trackbar.visible = false		--turn off the track bar
			cui.expertModeOn()				-- set the UI in expert mode
			statusPanel.visible = false		--hide the status bar as well (consider NOT doing this if showing a progressbar.
			MatEditor.close()

		)
		
		else 				--if the bool is false/0/off, then 
		(
			--we return the UI to its original state, if those states were correctly gathered, otherwise we default to the standard UI visibility setup
			if timeSliderWasVisible != undefined then 
			(
				timeslider.Setvisible timeSliderWasVisible
			)
			else 
			(
				timeslider.Setvisible true	
			)
			
			if trackBarWasVisible != undefined then 
			(
				trackbar.visible = trackBarWasVisible 
			)
			else 
			(
				trackbar.visible = true
			)
			
			if expertModeWasActive != undefined then	
			(
				if not expertModeWasActive do cui.expertModeOff()
			)
			else 
			(
				cui.expertModeOff()
			)
			
			if statusPanelWasVisible != undefined then 
			(
				statusPanel.visible = statusPanelWasVisible 
			)
			else 
			(
				statusPanel.visible = true
			)
			
			if matEditorWasOpen != undefined do 
			(
				if matEditorWasOpen do matEditor.open()
			)
		)
	)
-- setSuperExpertMode off
	fn getSourceGeoString=	--fed a filtered, read file line, fills the sourceGeoString variable with it, or reading and filtering the next one
	(
		sourceGeoString=jsonFile.readtoken()
	)
	
	fn getSourceEdingLine=
	(
		oldPos=jsonFile.pos()
		jsonFile.skipBlock "{" "},"
		sourceEndingLine=jsonFile.pos()
		jsonFile.seek oldPos #seek_set
		sourceEndingLine
	)
	
	fn getInstanceTransforms =
	(
		print "getting transforms"
		if jsonFile.pos() < sourceEndingLine do
		(
			instringArray=#(jsonFile.readblock "[" "],")
			theTransformMatrix = matrix3 [inStringArray[1], inStringArray[3], inStringArray[2]] [inStringArray[5],inStringArray[7],inStringArray[6]]  [inStringArray[9], inStringArray[11], inStringArray[10]]  [inStringArray[13], inStringArray[15], inStringArray[14]] 
		)
	)

	fn getSourceProxyPath =
	(
		if sourceGeoString != "" do 
		(
			sourceProxyPath=rootPath + getFilenamePath sourceGeoString + getFilenameFile sourceGeoString + ".vrmesh"
			if (doesfileexist sourceProxyPath) then print sourceProxyPath else exit with print sourceProxyPath
			sourceProxyPath
		)
		
	)	

	fn getInstanceName =	--fed a filtered, read file line, fills the sourceGeoString variable with it, or reading and filtering the next one
	(
		if jsonFile.pos() < sourceEndingLine do
		(
			instanceName=jsonFile.readtoken()
		)
	)
-- 		print instanceName
		
	

	fn isGoodJson jsonFile =
	(
		isRight=false
		jsonFile.seek 0 #seek_set
		jsonFile.readline()
		if (matchpattern ((jsonFile.readline()) as string) pattern:"*[") then false else true
	)
	
	fn jsonReader jsonFile =
	(
		theSource=undefined

-- 		jsonFile.seek 0 #seek_set
		windows.processPostedMessages()
		newSource=true
		while not (jsonFile.eos()) do				--global stop to not read past EoF
		(		
			if newSource then
			(
				print "New Source Geo"
				getSourceEdingLine()
				SourceGeoString = getSourceGeoString()	--after this function, we are always at the line with the instance name.
				print SourceGeoString
				sourceProxyPath=getSourceProxyPath()
-- 				print proxydisplaymode
-- 				theSource= vrayProxy name:(uniquename "proxySource_") filename:sourceProxyPath 
-- 				theSource.display=proxyDisplayMode
				newSource=false
			)
			else
			(
-- 				Print "New Instance"
				getInstanceName() 
				print instanceName
				theTransformMatrix=getInstanceTransforms()
				print theTransformMatrix

-- 				theInstance= instance theSource name:instanceName transform:theTransformMatrix
-- 				theInstance.display=proxyDisplayMode
				instanceCounter+=1
			)

		)
		MemStreamMgr.close jsonFile
	)



	
	rollout jsonRoll "json importer" width:392 height:168
	(
		button 'btn1' "Browse" pos:[304,8] width:80 height:16 align:#left
		edittext 'edt1' "" pos:[8,32] width:376 height:24 enabled:true align:#left
		button 'btn2' "Go" pos:[8,112] width:376 height:48 align:#left
		dropdownList 'ddl1' "Proxy Display Mode" pos:[8,64] width:128 height:40 items:#("Bounding Box", "Edges", "Faces","Point", "Preview", "Mesh") align:#left
		label 'lbl1' "json Files root:" pos:[8,8] width:80 height:16 align:#left
		
		on btn1 pressed do
		(
			inPath=getSavePath initialDir:jsonsRoot
			rootPath = (replace inPath (findString inPath @"\json") (inPath.count-(findString inPath @"\json")+1) "")+@"\"
-- 			rootPath=substituteString inPath @"\json" ""
			print rootPath
			if inPath != undefined then
			(
				edt1.text=inPath
				theJsons=getFilesRecursive inPath "*xg*.json"
-- 				print theJsons
			)
			else
			(
				edt1.text=""
				theJsons=#()
			)
		)
		on ddl1 selected sel do
		(
			proxyDisplayMode = sel-1
		)
		
		on btn2 pressed do
		(
			if theJsons.count!=0 do
			(
				setSuperExpertMode true
				st=timestamp()
				for f in theJsons do
				(
					sourceGeoString=""
					instanceName=""
					sourceProxyPath=""
					newSource=true
					jsonFile=undefined
					if doesFileExist f do 
					(
				-- 		heapSize += getFileSize jsonFilePath
						print ("working on " + getfilenamefile f + ".json")
						jsonFile = (MemStreamMgr.openFile f	) 
						jsonFileStream = (jsonFile.readBlock "{" "}") as stringstream
						if (isGoodJson jsonFile) do jsonReader jsonFile
					)
				)
-- 				deleteSources()
-- 				delete theSource
				setSuperExpertMode false
				print ("it took " + ((timestamp()-st)/1000. ) as string + " seconds. for a total of " + instanceCounter as string + " instances")				
			)
		)
	)
	
	createDialog jsonRoll
	
	
)

