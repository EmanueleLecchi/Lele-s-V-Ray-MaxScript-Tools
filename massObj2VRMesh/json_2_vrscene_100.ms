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

	masterInstances=#()
	variants=#()
	archivedInstances=#()
	curveInstances=#()

	struct masterFile (nodeName, instancedPrimitiveJsonFiles, geomObjFile, matFile, transformMatrix, instancedCopies, variants)
	struct archivedInstance (nodeName, type, geomObjFile, jsonFile) -- parent KEY NAME, "archive", any path to a json file of instanced transforms
	struct curveInstance (nodeName, type, jsonFile, degrees, widthTip, widthRoot, faceCamera)	-- parent KEY NAME, "curve",any path to a json file of  curves' knots, Int , Float, Float, bool

	rootPath=@"D:\_RnD\Disney\island-basepackage-v1\island\"
	jsonsRoot=rootPath+@"json\"
	jsonPaths=getDirectories (jsonsRoot+"*")
	
	fn getMasterJsonFile inputFolder =
	(
		jsonSplits=filterstring inputFolder "\\"
		jsonName=jsonSplits[jsonSplits.count]+".json"
		if doesFileExist (inputFolder+jsonName) then (inputFolder+jsonName) else undefined
	)
	
	fn parseMasterJsonFile inputFile =
	(
		masterInstances=#()
		archivedInstances=#()
		curveInstances=#()
		
-- 		jsf=pyBi.open(@"D:\_RnD\Disney\island-basepackage-v1\island\json\isBayCedarA1\isBayCedarA1.json")
		
		jsf=pyBi.open(inputFile)
		jsfs=pyJs.load(jsf)
		jsfs["instancedCopies"].keys()
		append masterInstances ( masterFile nodeName:jsfs["name"] instancedPrimitiveJsonFiles:((jsfs["instancedPrimitiveJsonFiles"])) geomObjFile:jsfs["geomObjFile"] matFile:jsfs["matFile"] transformMatrix:jsfs["transformMatrix"] instancedCopies:(jsfs["instancedCopies"]) variants:(jsfs["variants"]) )
		
		if masterInstances[1].instancedCopies != undefined then
		(
			print "found master instances!"
-- 			print (masterInstances[1].instancedCopies.keys() as array)
			for ic in (masterInstances[1].instancedCopies.keys() as array) do
			(
				append masterInstances ( masterFile nodeName:jsfs["instancedCopies"][ic]["name"] instancedPrimitiveJsonFiles:(jsfs["instancedCopies"][ic]["instancedPrimitiveJsonFiles"]) geomObjFile:jsfs["instancedCopies"][ic]["geomObjFile"] matFile:jsfs["instancedCopies"][ic]["matFile"] transformMatrix:jsfs["instancedCopies"][ic]["transformMatrix"] instancedCopies:(jsfs["instancedCopies"][ic]["instancedCopies"]) variants:(jsfs["instancedCopies"][ic]["variants"]) )
			)
		)
		else print "no master instanced copies found!"
		
		if masterInstances[1].variants != undefined then
		(
			print "found master variants!"
			jsfs[((masterInstances[1].variants.keys())[1])]
			for mv in (masterInstances[1].variants.keys() as array) do
			(
				masterInstance = ( masterFile nodeName:mv instancedPrimitiveJsonFiles:((jsfs["variants"][mv]["instancedPrimitiveJsonFiles"])) geomObjFile:jsfs["variants"][mv]["geomObjFile"] matFile:jsfs["variants"][mv]["matFile"] transformMatrix:jsfs["variants"][mv]["transformMatrix"] instancedCopies:(jsfs["variants"][mv]["instancedCopies"]) variants:(jsfs["variants"][mv]["variants"]) )
			
				append masterInstances masterInstance
			)
		)
		else print "no master variants copies found!"
		
-- 		print masterInstances
		
		for mi in masterInstances where (mi.instancedPrimitiveJsonFiles.keys() != undefined) and (mi.instancedPrimitiveJsonFiles.keys() as array).count != 0 do
		(
			print mi
			for k in (mi.instancedPrimitiveJsonFiles.keys() as array) do
			(
				if mi.instancedPrimitiveJsonFiles[k]["type"] == "archive" then
				(
					append archivedInstances (archivedInstance nodeName:k type:mi.instancedPrimitiveJsonFiles[k]["type"] geomObjFile:mi.instancedPrimitiveJsonFiles[k]["geomObjFile"] jsonFile:mi.instancedPrimitiveJsonFiles[k]["jsonFile"])
				)
				else 
				(
					append curveInstances (curveInstance nodeName:k type:mi.instancedPrimitiveJsonFiles[k]["type"] jsonFile:mi.instancedPrimitiveJsonFiles[k]["jsonFile"])
				)
			)
		)
	)

	parseMasterJsonFile (getMasterJsonFile jsonPaths[2])

	print masterInstances
	print archivedInstances
	print curveInstances
	
	
)

