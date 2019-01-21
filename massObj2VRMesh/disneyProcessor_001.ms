(
	bi = Python.Import "__builtin__"
	jr = python.import #json  

	masterFilePath="F:\\island-basepackage-v1\\island\\json\\isCoral\\isCoral.json"

	struct masterFile (masterFP, instancedPrimitiveJsonFiles, curveJsons, masterTM, instancedCopies, instancedTransforms )
	struct masterInstance (masterInstanceFP=undefined, archiveJsons=#("instance archive json file path"), curveJsons=#("curves archive json file path"), masterInstanceTM=(matrix3 1) )
	struct archivedInstance (archivedInstancesJsonFP="Archived Instances Json Distribution File Path", geometricSources=#("instanced VRmesh path") )
	struct curveInstance (curveInstanceJsonFP="Curve Instances Json Knots File Path", curveDegree=2, tipW=0.01, rootW=0.1 )

	jsf=bi.open(masterFilePath)
-- 	jsf=bi.open(@"F:\island-basepackage-v1\island\json\isBeach\isBeach.json")
	
	
	
	jsfs=jr.load(jsf)
	master=masterFile masterFP:masterFilePath archiveJsons:((jsfs["instancedPrimitiveJsonFiles"]) as array)

	
	
)

