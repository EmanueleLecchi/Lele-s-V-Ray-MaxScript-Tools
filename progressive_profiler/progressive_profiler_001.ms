(
	global batcherRoll
	try (destroydialog batcherRoll) catch()
	isBucketed=off
	hasREs=off
	hasTX=off
	hasProxy=off
	totalRenders=0
	renderTime=0.0
	singleFileOps = true
	theMaxFiles=#()
	CSVFileName=getFilenameFile (maxFileName)+"_CSVResults.csv"
	theCSVFile=""
	outputPath = ""
	if maxfilepath != "" then outputPath=(maxfilepath+@"AD_Outputs\") else outputPath=((getDir #renderoutput)+@"\AD_Outputs\") 
	
	fn getFilesRecursive root pattern =
	(
		doWeContinue=true
		dir_array=#()
		join dir_array (GetDirectories (root+"/*"))
		for d in dir_array do
		  join dir_array (GetDirectories (d+"/*"))
		if dir_array.count > 1000 do doWeContinue = queryBox "Found MANY folders. Parsing may take a long time. Continue?" beep:true
		my_files = #()
		if doWeContinue do
			(
				for f in dir_array do
				  join my_files (getFiles (f + pattern))
			)
		my_files
	)
	
	
	
	fn reInit =
	(
		isBucketed=off
		hasREs=off
		hasTX=off
		hasProxy=off
		totalRenders=0
		renderTime=0.0
		CSVFileName=getFilenameFile (maxFileName)+"_CSVResults.csv"
		theCSVFile=""
		if maxfilepath != "" then outputPath=(maxfilepath+@"AD_Outputs\") else outputPath=((getDir #renderoutput)+@"\AD_Outputs\") 
	)
	
	
	
	fn createCSVFile =
	(
		if outputPath!="" do makeDir outputPath
		theCSVFile = createFile (outputPath+CSVFileName)
		format "File Name, Adaptive/Bucket, REs, Tiled TX, Proxies, Resolution, Render Time\n"  to:theCSVFile
		close theCSVFile
	)
	
	fn writeToCSVFile =
	(
		theCSVFile = openFile (outputPath+CSVFileName) mode:"a"
		format "%,%,%,%,%,%,%\n" (maxfilepath+maxFileName) (if isBucketed then "bucket" else "prog.") hasREs hasTX hasProxy renderwidth renderTime to:theCSVFile
		close theCSVFile
	)
	
	fn addREs =
	(
		re = maxOps.GetCurRenderElementMgr()
		re.RemoveAllRenderElements()
		elemList = #( VraySampleRate, VrayNoiseLevel, VrayRenderTime, VrayDiffuseFilter, VrayGlobalIllumination, VrayLighting, VrayNoiseLevel, VrayReflection, VrayRefraction, VraySpecular, VrayTotalLighting, VraySSS2, VrayAtmosphere)
		elemNamesList = #( "VraySampleRate", "VrayNoiseLevel", "VrayRenderTime", "VrayDiffuseFilter", "VrayGlobalIllumination", "VrayLighting", 
							"VrayNoiseLevel", "VrayReflection", "VrayRefraction", "VraySpecular", "VrayTotalLighting", "VraySSS2", "VrayAtmosphere")			

		for r=1 to elemList.count do 
		(
			theElement = elemList[r] elementName:elemNamesList[r]
			re.AddRenderElement theElement								
		)	
	)	
	
	fn gatherCameras =
	(
		theCams= for c in cameras where classof c != targetobject collect c
		print theCams.count
		theCams
	)

	fn renderVariants theCams=
	(
		/*
		for each option, render both adaptive and bucketed, one at a 640x resolution and the other at a 2048x resolution. 
		The file will be set up with a set of REs, tiled textures and a few proxies.
		For REs, i'll render with them on and off
		For TX textures, i'll render with a tight and a loose cahce ram value, so to have all textures in RAM, or be forced to swap them out.
		For proxies, in one instance i'll render normally, in the other i'll render with the mesh shown in viewport, forcing pre-load.
		
		For each of the eight variant below, i'll render Adaptive and Bucketed for 2 resolutions: 
		RE | TX | Proxy
		0 0 0
		1 0 0
		1 1 0
		1 1 1
		0 1 0
		0 1 1
		0 0 1
		1 0 1

		or 32 total renders per scene.
		*/
		
		rem=maxOps.GetCurRenderElementMgr() 
		addREs()
	
		for c in theCams[1] do --we collected all the cameras, we render the first one only.
		(
			show renderers.current
			vr=renderers.current
			togglesMatrix=#(#(false,false,false),#(true,false,false),#(true,true,false),#(true,false,true),#(true,true,true),#(false,true,false),#(false,true,true),#(false,false,true))
			renderModes=#(1,3)
			resolutions=#([640,360],[1920,1080])
			for t in togglesMatrix do
			(
				hasREs = t[1]
				hasTX = t[2]
				hasProxy = t[3]
				--common
				rem.SetElementsActive hasREs
				vr.textures_memLimit = if hasTX then 16000 else 128000
				vr.textures_clearMem = true
				for p in getclassinstances vrayProxy do p.display= if hasProxy then 3 else 4
-- 				if hasProxy then vr.system_raycaster_memLimit = 16000 else 0

				vr.twoLevel_baseSubdivs = vr.progressive_minSamples = 1
				vr.twoLevel_fineSubdivs = vr.progressive_maxSamples = 100
				vr.twoLevel_threshold = vr.progressive_noise_threshold = 0.25
				vr.progressive_max_render_time = 0.0
				--render mode
				for s in renderModes do
				(
					vr.imageSampler_type = s
					isBucketed = if s == 1 then true else false
						
					for r in resolutions do
					(
						renderwidth=r.x
						renderHeight=r.y
						
						makedir outputPath
						token=""
						(if s == 1 then token = "Bucket" else token = "Prog")
						theOutputFilename=outputPath+(getfilenamefile maxfilename)+"_" + (hasREs as integer) as string + (hasTX as integer) as string + (hasProxy as integer) as string + "_" + token + "_" + (r.x as string) +  ".exr"
						renderers.current.output_saveRawFile =true
						renderers.current.output_rawFileName = theOutputFilename
						freescenebitmaps()
						vrayfreebitmaps()
						gc()
						st=timeStamp()
						render camera:c vfb:off
						renderTime=(timestamp()-st)/1000.0
						writeToCSVFile()						
					)
				)
			)
		)
	)

	fn goFn =
	(
			if not singleFileOps then --open each file, and do the rest.
			(
				for m in theMaxFiles do 
				(
					loadMaxFile m
					CSVFileName=getFilenameFile (maxFileName)+"_CSVResults.csv"
					theCSVFile=""
					if maxfilepath != "" then outputPath=(maxfilepath+@"AD_Outputs\") else outputPath=((getDir #renderoutput)+@"\AD_Outputs\") 
					createCSVFile()
					addREs()
					renderVariants (gatherCameras())
					makedir outputPath
					shelllaunch outputPath ""
				)
			)	
			else --work on currently open file
			(
				CSVFileName=getFilenameFile (maxFileName)+"_CSVResults.csv"
				theCSVFile=""
				if maxfilepath != "" then outputPath=(maxfilepath+@"AD_Outputs\") else outputPath=((getDir #renderoutput)+@"\AD_Outputs\") 
				createCSVFile()
				addREs()
				renderVariants (gatherCameras())
				makedir outputPath
				shelllaunch outputPath ""
			)
	)
	
	rollout batcherRoll "Progressive Profiler" width:504 height:232
	(
		checkbutton 'ckb1' "Work on the open max file" pos:[8,8] width:240 height:24 align:#left
		button 'fldBtn' "Pick Root Folder to search into:" pos:[256,8] width:240 height:24 enabled:false align:#left
		
		GroupBox 'grp1' "Workload Info:" pos:[8,40] width:488 height:96 align:#left
		label 'nfoLbl' "Working only on the currently open Max file\nWill then render a total of 32 images." pos:[16,64] width:472 height:64 align:#left
		button 'goBtn' "Go" pos:[8,144] width:488 height:48 align:#left
		button 'browseBtn' "Browse Outputs" pos:[8,200] width:488 height:24 align:#left
		
		
		on ckb1 changed state do
		(
			if not state then
			(
				ckb1.text = "Work on the open max file"
				fldBtn.enabled=false
				singleFileOps=true
				nfoLbl.text = "Working only on the currently open Max file\nWill then render a total of 32 images."

			
			)
			else
			(
				ckb1.text = "Work on multiple files"
				fldBtn.enabled=true
				singleFileOps=false
				nfoLbl.text = "Browse for Max files..."
			)
		)
		
		on fldBtn pressed do
		(
			rootPath = (getSavePath caption:"Pick a folder to scan for Max files")
			if rootPath != undefined do 
			(
				theMaxFiles = getFilesRecursive rootPath "*.max"
			)
			if theMaxFiles.count > 0 then 
			(
				nfoLbl.text = "Found a total of " + ( theMaxFiles.count as string ) + " max files.\nWill then render a total of " + ( 32 * theMaxFiles.count ) as string + " images."
			)
			else
			(
				nfoLbl.text = ""
			)
			
		)
		
		on goBtn pressed do
		(
			goFn()
		)
		on browseBtn pressed do
		(
			if outputPath != "" do
			(
				makedir outputPath
				shelllaunch outputPath ""
			)
		)
	)
	createDialog batcherroll
)



-- show (vraylight())
-- show (vrayhdri())
	
