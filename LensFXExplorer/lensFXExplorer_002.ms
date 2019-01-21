(	
	global lensFXExplorerRoll
	try ( destroyDialog lensFXExplorerRoll)	catch ()

	local fullArray=#()
	local OINames=#()
	local OIPaths=#()
	local FINames=#()
	local FIPaths=#()
	local imageFormats=#(".vrimg",".png",".bmp",".tga",".hdr",".sgi",".rgb",".rgba",".jpg",".jpeg",".jpe",".exr",".pic",".tif",".tiff",".jpg",".psd")
	
	local folderRoot=undefined
	local doVerbose = false
	
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
		fullFilePathArray=#()
		fullFilePathArray=getFilesRecursive folderRoot "*.*"
	
		imagesPathArray=#()
		for i in fullFilePathArray do
		(
			for f in imageFormats where (matchpattern (getfilenametype i) pattern:("*"+f)) do 
			(
				appendifunique imagesPathArray i
			)
		)
		menuNamesArray=#()
		for i in imagesPathArray do 
		(
			tempName= (getfilenamefile i)
			append menuNamesArray tempName
		)
		fullArray=#(imagesPathArray,menuNamesArray)
	)
	
	fn turnVFBOn type =
	(
			vfbcontrol #glare on
			if type == "obstacle" then
			(
				vfbcontrol #glareuseobstacle on
			)
			else
			(
				vfbcontrol #glarediffraction on  --doesn't work.
			)
	)
	
	fn applyObstacleImage imagePath =
	(
		turnVFBOn "obstacle"
		vfbcontrol #glareobstacleimage imagePath 
	)
	fn applyFilterImage imagePath =
	(
		turnVFBOn "filter"
		vfbcontrol #glareimage imagePath 
	)	

	rollout lensFXExplorerRoll "Obstacle Image Explorer" width:232 height:248
	(
		groupBox 'grp1' "Obstacle Images:" pos:[8,8] width:216 height:112 align:#left
		button 'pickBtn1' "Pick Obstacle Images Root Folder..." pos:[16,32] width:200 height:24 align:#left
		label 'lbl1' "Apply Obstacle Image:" pos:[16,64] width:128 height:16 align:#left
		dropdownList 'OIsDdl' "" pos:[16,88] width:200 height:21 align:#left
		
		groupBox 'grp2' "Filter Images:" pos:[8,128] width:216 height:112 align:#left
		button 'pickBtn2' "Pick Filter Images Root Folder..." pos:[16,152] width:200 height:24 align:#left
		label 'lbl2' "Apply Filter Image:" pos:[16,184] width:128 height:16 align:#left
		dropdownList 'FIsDdl' "" pos:[16,208] width:200 height:21 align:#left

		on lensFXExplorerRoll open do
		(

		)		
		
		
		----------------- Obstacle Images ---------------
		
		on pickBtn1 pressed do
		(
			tempPath=(getOpenFileName caption:"Choose one Image to mark the root:" types:"All|*.*|")
			if tempPath != undefined do folderRoot=getfilenamePath tempPath
			
			if folderRoot != undefined then
			(
				pickBtn1.text=pickBtn1.tooltip=folderRoot
				fullArray=populateList folderRoot
				OINames=deepcopy fullArray[2]
				OIPaths=deepcopy fullArray[1]
				OIsDdl.items = OINames
				if OIsDdl.items.count!= 0 do 
				(
					OIsDdl.selection=1
					applyObstacleImage OIPaths[1]
				)
			)
			else
			(
				pickBtn1.text=pickBtn1.tooltip= "Pick Obstacle Images Root Folder..."
				OIsDdl.items = #()
			)
		)
		on OIsDdl selected sel do
		(
			applyObstacleImage OIPaths[sel]
		)		
		
		----------------- Filter Images ---------------
		
		on pickBtn2 pressed do
		(
			tempPath=(getOpenFileName caption:"Choose one Image to mark the root:" types:"All|*.*|")
			if tempPath != undefined do folderRoot=getfilenamePath tempPath
			
			if folderRoot != undefined then
			(
				pickBtn2.text=pickBtn2.tooltip=folderRoot
				fullArray=populateList folderRoot
				FINames=deepcopy fullArray[2]
				FIPaths=deepcopy fullArray[1]
				FIsDdl.items = FINames
				if FIsDdl.items.count!= 0 do 
				(
					FIsDdl.selection=1
					applyFilterImage FIPaths[1]
				)
			)
			else
			(
				pickBtn2.text=pickBtn2.tooltip= "Pick Filter Images Root Folder..."
				FIsDdl.items = #()
			)
		)
		on FIsDdl selected sel do
		(
			applyFilterImage FIPaths[sel]
		)		
	)
	
	createdialog lensFXExplorerRoll

)

