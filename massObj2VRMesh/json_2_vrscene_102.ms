(
	/*
	A master json file is made up of a set of hierachical keys
	in sparse order:
	"name" -> node name
	"instancedPrimitiveJsonFiles" -> set of curves and geometric archives scattered on the base geo
	"geomObjFile" -> base obj/vrmesh geometry for this node
	"matFile" -> materials assignements json file path
	"transformMatrix" -> the TM for the base geo (multiplies the childrens'!)
	an OPTIONAL "instancedCopies", which when present contains the same set of keys as the master object, 
	with different scatter jsons, and a different Transform Matrix
	Another OPTIONAL key is "variants", which specify a "geomObjFile" and their own set of scattered instances, either as archives or curves. 
	Variants are still stored as archivedInstances, not master ones. check this works.
	
	"instancedPrimitiveJsonFiles" further contains a few keys of its own:
	"jsonFile" -> path to the scatter json file
	"type" -> can be either "archive", which specifies a geometric file on disk, \
	or "curve", which specifies some of the curve parameters within the key itself
	if the type is "archive", it's enough to parse the "jsonFile", as the geometric sources appear in there too.
	If the type is curve, a curve object needs to be created per strand, and the set of 5 vector3 for the knots has to be specified for each. 
	Parameters for curve rendering are general to the curves, and can be copied over or maintained as parent setting
	"jsonFile": "json/isMountainB/isMountainB_xgLowGrowth.json", 
	"widthTip": 12, 
	"faceCamera": true, 
	"degrees": 2, 
	"type": "curve", 
	"widthRoot": 12
	
	*/

	
	pyBi = Python.Import "__builtin__"
	pyJs = python.import #json  

	rootPath=@"D:\_RnD\Disney\island-basepackage-v1\island\"
	jsonsRoot=rootPath+@"json\"
	jsonPaths=getDirectories (jsonsRoot+"*")	

	struct masterFile (nodeName, instancedPrimitiveJsonFiles, geomObjFile, matFile, transformMatrix, instancedCopies, variants)
	struct masterVariant (nodeName, instancedPrimitiveJsonFiles, geomObjFile )
	struct archivedInstance (nodeName, type, geomObjFile, jsonFile) -- parent KEY NAME, "archive", any path to a json file of instanced transforms
	struct curveInstance (nodeName, type, jsonFile, degrees, widthTip, widthRoot, faceCamera)	-- parent KEY NAME, "curve",any path to a json file of  curves' knots, Int , Float, Float, bool
	struct instancedArchive (geoSource, nodeName, transformMatrix)

	masterInstances=#()
	masterVariants=#()
	archivedInstances=#()
	curveInstances=#()
	instancedArchives=#()
	
	fn getMasterJsonFile inputFolder =
	(
		jsonSplits=filterstring inputFolder "\\"
		jsonName=jsonSplits[jsonSplits.count]+".json"
		if doesFileExist (inputFolder+jsonName) then (inputFolder+jsonName) else undefined
	)
	
	fn parseMasterJsonFile inputFile =
	(
		masterInstances=#()
		masterVariants=#()
		archivedInstances=#()
		curveInstances=#()

		
-- 		jsf=pyBi.open(@"D:\_RnD\Disney\island-basepackage-v1\island\json\isBayCedarA1\isBayCedarA1.json")
		
		jsf=pyBi.open(inputFile)
		jsfs=pyJs.load(jsf)

		append masterInstances ( masterFile nodeName:jsfs["name"] instancedPrimitiveJsonFiles:((jsfs["instancedPrimitiveJsonFiles"])) geomObjFile:jsfs["geomObjFile"] matFile:jsfs["matFile"] transformMatrix:jsfs["transformMatrix"] instancedCopies:(jsfs["instancedCopies"]) variants:(jsfs["variants"]) )
		-- the first masterFile contains the instanced copies json list. If there are more masterfiles in the array, they all inherit the instanced distribution from the first masterFile, and apply their own TM to the result
		-- ONLY masterfile types can have archived and curve copies
		
		if masterInstances[1].instancedCopies != undefined do
		(
-- 			print "found master instances!"
-- 			print (masterInstances[1].instancedCopies.keys() as array)
			for ic in (masterInstances[1].instancedCopies.keys() as array) do
			(
				append masterInstances ( masterFile nodeName:jsfs["instancedCopies"][ic]["name"] instancedPrimitiveJsonFiles:(jsfs["instancedCopies"][ic]["instancedPrimitiveJsonFiles"]) geomObjFile:jsfs["instancedCopies"][ic]["geomObjFile"] matFile:jsfs["instancedCopies"][ic]["matFile"] transformMatrix:jsfs["instancedCopies"][ic]["transformMatrix"] instancedCopies:(jsfs["instancedCopies"][ic]["instancedCopies"]) variants:(jsfs["instancedCopies"][ic]["variants"]) )
			)
		)
-- 		else print "no master instanced copies found!"
		-- master variants ONLY change the base geo, and node name, referring back to the base jsonFile used in the first masterfile (see above.)
		
		if masterInstances[1].variants != undefined do
		(
-- 			print "found master variants!"
			for mv in (masterInstances[1].variants.keys() as array) do
			(
				append masterVariants ( masterVariant nodeName:mv instancedPrimitiveJsonFiles:((jsfs["variants"][mv]["instancedPrimitiveJsonFiles"])) geomObjFile:jsfs["variants"][mv]["geomObjFile"] )
			)
		)
-- 		else print "no master variants copies found!"
		
	)

	-- open the humongous json files, and read the node name and TM for each instance
	fn parseAIJsonFile inputFile inputTM=
	(
		fileSize=((getFileSize inputFile)/(1024*1024.0))
		if fileSize<=32.0 do
		(
			print ("About to load " + inputFile + ", fileSize: " + fileSize as string + "MB.")
			ts= timestamp()
	 
			aiJsf=pyBi.open(inputFile)
			aiJsfs=pyJs.load(aiJsf)		
			
			instancedArchives=#()
			for k in (aiJsfs.keys() as array) do 
			(
				geoSource= rootPath + (substituteString (k as string) ".obj" ".vrmesh")
				
				for i=1 to aiJsfs[k].count do 
				(
					append instancedArchives (instancedArchive geoSource:geoSource nodeName:(aiJsfs[k].keys())[i] transformMatrix:(aiJsfs[k].values())[i])
				)
			)
			endTime= (timeStamp()-ts)/1000.0
			print endtime 
			print instancedArchives
		)
	)

	for p=3 to 3 do -- (jsonPaths.count) do
	(
		masterJsonFile= (getMasterJsonFile jsonPaths[p])
		print ("Parsing " + masterJsonFile)
		parseMasterJsonFile masterJsonFile
		print masterInstances
		print masterVariants

		
		for mi in masterInstances where (mi.instancedPrimitiveJsonFiles != undefined) do
		(
			masterTM=mi.transformMatrix
			for k in (mi.instancedPrimitiveJsonFiles.keys() as array) do
			(
				windows.processpostedmessages()
				if mi.instancedPrimitiveJsonFiles[k]["type"] == "archive" then
				(
					
					aInstance = (archivedInstance nodeName:k type:mi.instancedPrimitiveJsonFiles[k]["type"] geomObjFile:mi.instancedPrimitiveJsonFiles[k]["geomObjFile"] jsonFile:(rootPath + mi.instancedPrimitiveJsonFiles[k]["jsonFile"] as string))
					append archivedInstances aInstance
					parseAIJsonFile aInstance.jsonFile masterTM
				)
				else 
				(
					cInstance = (curveInstance nodeName:k type:mi.instancedPrimitiveJsonFiles[k]["type"] jsonFile:(rootPath + mi.instancedPrimitiveJsonFiles[k]["jsonFile"] as string) degrees:mi.instancedPrimitiveJsonFiles[k]["degrees"] widthTip:mi.instancedPrimitiveJsonFiles[k]["widthTip"] widthRoot:mi.instancedPrimitiveJsonFiles[k]["widthRoot"] faceCamera:mi.instancedPrimitiveJsonFiles[k]["faceCamera"] )
					append curveInstances cInstance
				)
			)
		)
-- 		print archivedInstances
-- 		print curveInstances		
		
	)
)

-- 			aiJsf=pyBi.open(@"D:\_RnD\Disney\island-basepackage-v1\island\json/isBeach/isBeach_xgHibiscus.json")
-- 			aiJsfs=pyJs.load(aiJsf)	

-- 		

-- 	((aiJsfs.items())[1][2].values())[1]
-- 			(aiJsfs.keys())[1].values())