(
	global batcherRoll
	try (destroydialog batcherRoll) catch()
	
	--locals
	isBucketed=off
	hasREs=off
	hasTX=off
	hasProxy=off
	txRam=4000
	pxRam=0
	minAA=1
	maxAA=100
	ntr=0.01
	totalRenders=0
	renderTime=0.0
	singleFileOps = true
	theMaxFiles=#()
	CSVFileName=getFilenameFile (maxFileName)+"_CSVResults.csv"
	theCSVFile=""
	outputPath = ""
	if maxfilepath != "" then outputPath=(maxfilepath+@"AD_Outputs\") else outputPath=((getDir #renderoutput)+@"\AD_Outputs\") 
	
	--functions
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
	
	fn itsVray input =
	(
		matchpattern (input as string) pattern:"V_Ray_N*"
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
-- 			show renderers.current

			vr=renderers.current
			baseRes=[1,1]
			
			toggles=#(false,true)
			renderModes=#(1,3)
			usesMaxRes=vr.output_getsetsfrommax
			if usesMaxRes then
			(
				baseRes=[renderwidth,renderHeight]
			)
			else
			(
				baseRes=[vr.output_width,vr.output_height]
			)
			if baseRes!=[1,1] then
				resolutions=#(baseRes/4.,baseRes/2.,baseRes)
			else
				resolutions=#()
			for t in toggles do
			(
				rem.SetElementsActive t

				vr.twoLevel_baseSubdivs = vr.progressive_minSamples = minAA
				vr.twoLevel_fineSubdivs = vr.progressive_maxSamples = maxAA
				vr.twoLevel_threshold = vr.progressive_noise_threshold = ntr
				vr.progressive_max_render_time = 0.0
				--render modes (2)
				for s in renderModes do
				(
					vr.imageSampler_type = s
					isBucketed = if s == 1 then true else false
					--resolutions (3)
					for r in resolutions do
					(
						if usesMaxRes then
						(
							renderwidth=r[1]
							renderHeight=r[2]
						)
						else
						(
							vr.output_width=r[1]
							vr.output_heightr[2]
						)
						
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

	fn updateVars =
	(
		minAA=batcherRoll.spn3.value
		maxAA=batcherRoll.spn4.value
		ntr=batcherRoll.spn.value
	)	
	
	fn reInit =
	(
		isBucketed=off
		minAA=1
		maxAA=100
		ntr=0.01
		totalRenders=0
		renderTime=0.0
		singleFileOps = true
		theMaxFiles=#()
		CSVFileName=getFilenameFile (maxFileName)+"_CSVResults.csv"
		theCSVFile=""
		outputPath = ""
		if maxfilepath != "" then outputPath=(maxfilepath+@"AD_Outputs\") else outputPath=((getDir #renderoutput)+@"\AD_Outputs\") 
		updateVars()
	)
	
	fn goFn =
	(
		if itsVRay renderers.current then
			(
				updateVars()
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
			else
			(
				if queryBox "V-Ray isn't the current renderer, I can't proceed!\nDo you want me to set it for you and start over?" beep:true then
				(
					for R in RendererClass.classes where itsVray R do renderers.current = R()
					goFn()
				)
				else
				(
					print "Aborted because of Wrong Render Engine selection"
				)
			)
	)
	

	
	rollout batcherRoll "Progressive Profiler" width:504 height:328
	(
		checkbutton 'ckb1' "Work on the open max file" pos:[8,8] width:240 height:24 align:#left
		button 'fldBtn' "Pick Root Folder to search into:" pos:[256,8] width:240 height:24 enabled:false align:#left
		
		spinner 'spn3' "" pos:[416,168] width:72 height:16 range:[1,1000,1] type:#integer scale:1 align:#left
		spinner 'spn4' "" pos:[416,184] width:72 height:16 range:[1,1000,100] type:#integer scale:1 align:#left
		spinner 'spn5' "" pos:[416,200] width:72 height:16 range:[0,10,0.01] type:#float scale:0.01 align:#left		
		
		button 'goBtn' "Go" pos:[8,240] width:488 height:48 align:#left
		button 'browseBtn' "Browse Outputs" pos:[8,296] width:488 height:24 align:#left
		
		
		GroupBox 'grp1' "Workload Info:" pos:[8,40] width:488 height:96 align:#left
		groupBox 'grp3' "Sampling" pos:[256,144] width:240 height:80 align:#left
		
		label 'nfoLbl' "Working only on the currently open Max file\nWill then render a total of 12 images." pos:[16,64] width:472 height:64 align:#left
		label 'lbl3' "Min AA Subdivs:.................." pos:[272,168] width:136 height:16 align:#left
		label 'lbl4' "Max AA Subdivs:.................." pos:[272,184] width:136 height:16 align:#left
		label 'lbl5' "Noise Threshold:................." pos:[272,200] width:136 height:16 align:#left

		on ckb1 changed state do
		(
			if not state then
			(
				ckb1.text = "Work on the open max file"
				fldBtn.enabled=false
				singleFileOps=true
				nfoLbl.text = "Working only on the currently open Max file\nWill then render a total of 12 images."
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
				nfoLbl.text = "Found a total of " + ( theMaxFiles.count as string ) + " max files.\nWill then render a total of " + ( 8 * theMaxFiles.count ) as string + " images."
			)
			else
			(
				nfoLbl.text = ""
			)
			
		)
		on spn1 changed val do updateVars()
		on spn2 changed val do updateVars()
		on spn3 changed val do updateVars()
		on spn4 changed val do updateVars()
		on spn5 changed val do updateVars()
		
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

