(
	ts=timestamp()
	fn objPathToVrmesh inputPath =
	(
		projectRoot+@"obj\"+ substituteString inputPath ".obj" ".vrmesh"
	)
	
	fn makeTM inputString =
	(
		tmBuffer=execute("#("+inputString+")")
		theTM= matrix3 [-tmBuffer[1],tmBuffer[3],tmBuffer[2]] [-tmBuffer[5],tmBuffer[7],tmBuffer[6]] [-tmBuffer[9],tmBuffer[11],tmBuffer[10]] [-tmBuffer[13],tmBuffer[15],tmBuffer[14]]
		theTM	
	)
	
	totInstanceCount=0
	projectRoot=@"F:/island-basepackage-v1/island/"
	theFilePath=projectRoot+ @"json/isCoral/isCoral.txt"
	tF= openFile theFilePath mode:"r"
	seek tF 0
	
	
	
	mainMeshName=readline tF
	mainMeshGeoSource=objPathToVrmesh (readline tF)
	mainMeshTM=makeTM (readline tF)
	
	--materials: skip
	readline tF
	readLine tF
	
	mainMeshNumInstances=readvalue tF
	archivedInstancePoolName=readline tF
	archivedInstancePoolCount=readvalue tF
	for i=1 to archivedInstancePoolCount do
	(
		instanceGeoSource = objPathToVrmesh (readline tF)
		instancesCount=readvalue tF
		totInstanceCount+=instancesCount
		for p=1 to instancesCount do
		(
			instanceName=readline tF
			instanceTM=makeTM (readline tF)
		)
	)
	print ("it took " + ((timestamp()-ts)/1000.) as string + "s. to process " + totInstanceCount as string + " instances and their TMs")
) 

