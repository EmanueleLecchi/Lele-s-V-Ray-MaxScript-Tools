(	
	global lensFXExplorerRoll
	try ( destroyDialog lensFXExplorerRoll)	catch ()

	local theOIsTEMPList=#()
	local theOIsList=#()
	local theNamesList=#()
	local folderRoot=undefined
	local doVerbose = false
	local imageFormats=#(".vrimg",".png",".bmp",".tga",".hdr",".sgi",".rgb",".rgba",".jpg",".jpeg",".jpe",".exr",".pic",".tif",".tiff",".jpg",".psd")
	
	fn getFilesRecursive root pattern =
	(
		dir_Array=#()
		
		join dir_array ( GetDirectories (root+"/*"))
		if dir_array.count ==0 do dir_Array[1] = (root+"\\")
		for d in dir_array do
			join dir_array (GetDirectories (d+"/*"))
		my_files = #()
		for f in dir_array do
			join my_files (getFiles (f + pattern))
		my_files
	)

	fn populateList folderRoot = 
	(
		theOIsTEMPList=getFilesRecursive folderRoot "*.*"
		if doVerbose do
		(
			print "theOIsTEMPList\n"
			print theOIsTEMPList
			print theOIsTEMPList.count
		)
		
		theOIsList=#()
		for i in theOIsTEMPList do
		(
			for f in imageFormats where (matchpattern (getfilenametype i) pattern:("*"+f)) do 
			(
				appendifunique theOIsList i
			)
		)
		
		if doVerbose do
		(
			print "theOIsList"			
			print theOIsList
			print theOIsList.count
		)
		theNamesList=#()
		for i in theOIsList do 
		(
			tempName= (getfilenamefile i)
			append theNamesList tempName
		)
		
		if doVerbose do
		(
			print theNamesList
			print theNamesList.count
		)
		theNamesList
	)
	
	fn applyObstacleImage imagePath =
	(
		vfbcontrol #glare on
		vfbcontrol #glareuseobstacle on
		vfbcontrol #glareobstacleimage imagePath 
	)
	

	rollout lensFXExplorerRoll "Main Controls" width:288 height:160
	(
		button 'pickBtn' "Pick Obstacle Images Root Folder..." pos:[8,8] width:248 height:24 align:#left
		label 'lbl1' "Found Obstacle Images:" pos:[8,40] width:128 height:16 align:#left
		dropdownList 'OIsDdl' "" pos:[8,64] width:272 height:21 align:#left
		button 'applyBtn' "Apply Selected in " pos:[8,112] width:152 height:40 align:#left
		
		on lensFXExplorerRoll open do
		(
			vfbcontrol #glare on
			vfbcontrol #glareuseobstacle on
		)
		
		on pickBtn pressed do
		(
			tempPath=(getOpenFileName caption:"Choose one Image to mark the root:" types:"All|*.*|")
			if tempPath != undefined do folderRoot=getfilenamePath tempPath
			
			if folderRoot != undefined then
			(
				pickBtn.text=pickBtn.tooltip=folderRoot
				populateList folderRoot
				OIsDdl.items = theNamesList
				if OIsDdl.items.count!= 0 do 
				(
					OIsDdl.selection=1
					applyObstacleImage theOIsList[1]
				)
			)
			else
			(
				pickBtn.text=pickBtn.tooltip= "Pick LUTs Root Folder..."
				OIsDdl.items = #()
			)
		)
		
		on OIsDdl selected sel do
		(
			applyObstacleImage theOIsList[sel]
		)
	)
	
	
	createdialog lensFXExplorerRoll

)

