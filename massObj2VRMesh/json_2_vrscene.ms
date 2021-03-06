(
	
	global jsonRoll
	try (destroydialog jsonRoll) catch()
	
	rootPath=@"D:\_RnD\Disney\island-basepackage-v1\island\"
	jsonsRoot=rootPath+@"json\"
	jsonPaths=getDirectories (jsonsRoot+"*")
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

	
	
	fn getMasterJsonFile inputFolder =
	(
		jsonSplits=filterstring inputFolder "\\"
		jsonName=jsonSplits[jsonSplits.count]+".json"
		if doesFileExist (inputFolder+jsonName) then (inputFolder+jsonName) else undefined
	)
	
	getMasterJsonFile jsonPaths[1]
	
-- setSuperExpertMode off
	fn getSourceGeoString=	--fed a filtered, read file line, fills the sourceGeoString variable with it, or reading and filtering the next one
	(
		instring=(filterString (readline jsonFile) ":")[1]
		sourceGeoString=""
		--AFTER FILTERING by ":", one of three cases may happen:
		case of
		(
			--start of the file only: next line contains the geo name
			(matchpattern instring pattern:"{*"): 
			(
-- 				print "case 1 - self recalling"
				instring=""
				getSourceGeoString()
			)
			--end of an instance block, next line contains the geo name
			(matchpattern instring pattern:"*}*"): 
			(
-- 				print "case 2 - self recalling"
				if not (eof jsonFile) do getSourceGeoString()
			)
			--line with the geo name in it
			(matchpattern instring pattern:"*.obj*"): 
			(
-- 				print "case 3 - source obj found"
				sourceGeoString=instring
			)
		)
		execute sourceGeoString

	)
	
	fn getInstanceTransforms =
	(
-- 		print "getting transforms"
		instringArray=#(
			readvalue jsonFile, readvalue jsonFile, readvalue jsonFile, readvalue jsonFile, 
			readvalue jsonFile, readvalue jsonFile, readvalue jsonFile, readvalue jsonFile, 
			readvalue jsonFile, readvalue jsonFile, readvalue jsonFile, readvalue jsonFile, 
			readvalue jsonFile, readvalue jsonFile, readvalue jsonFile, readvalue jsonFile
			)
		readline jsonFile --skips the closed bracket
		theTransformMatrix = matrix3 [inStringArray[1], inStringArray[3], inStringArray[2]] [inStringArray[5],inStringArray[7],inStringArray[6]]  [inStringArray[9], inStringArray[11], inStringArray[10]]  [inStringArray[13], inStringArray[15], inStringArray[14]] 
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
-- 		print "getting instance name"
		instring= (filterString (readline jsonFile) ": [")[1]
-- 		print instring
		instanceName=""
		--AFTER FILTERING by ":", one of three cases may happen:
		case of
		(
			--end of an instance block, next line contains the geo name
			(matchpattern instring pattern:"*},*"): 
			(
				SourceGeoString=getSourceGeoString()
				sourceProxyPath=getSourceProxyPath()
				getInstanceName()
			)
			--line with the geo name in it
			(matchpattern instring pattern:"*.obj*"): 
			(
				newSource=false
				instanceName=execute instring
			)
			(matchpattern instring pattern:"*}"): 
			(
				exit with print "all done!"			
			)
		)
-- 		print instanceName
		
	)

	fn isGoodJson jsonFile =
	(
		isRight=false
		seek jsonFile 0
		readline jsonFile
		if (matchpattern (readline jsonFile) pattern:"*[") then false else true
	)
	
	fn jsonReader jsonFile =
	(
		theSource=undefined

		seek jsonFile 0
		windows.processPostedMessages()
		newSource=true
		while not (eof jsonFile) do				--global stop to not read past EoF
		(		
			if newSource then
			(
				print "New Source Geo"
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
				theTransformMatrix=getInstanceTransforms()
-- 				theInstance= instance theSource name:instanceName transform:theTransformMatrix
-- 				theInstance.display=proxyDisplayMode
				instanceCounter+=1
			)

		)
		close jsonFile
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
						jsonFile = openFile f mode:"rt"	
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

