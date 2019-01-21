(
	for o in (selection as array) do
	(
		mtlIDs=#()
		thePoly = convertToPoly (copy o)
		for i=1 to (polyop.getNumFaces thePoly) do
			(
				--find material ID
				appendIfUnique mtlIDs (polyop.getFaceMatID thePoly i)
			)
		theMS = multiMaterial()
		for i=1 to mtlIDs.count do 
		(
			theMS.materialList[i]=VrayMtl diffuse:(random white black)
			theMS.materialIDList[i]=mtlIDs[i]
		)
		for i = (mtlIDs.count + 1) to theMS.materialList.count do
		(
			theMS.materialList[i]=undefined
-- 			theMS.materialIDList[i]=undefined
		)
		o.material = theMS
		delete thePoly
	)
	
)