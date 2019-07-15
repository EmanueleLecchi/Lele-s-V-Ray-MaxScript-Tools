(
	
	global ProxyOptRoll
	Try ( DestroyDialog ProxyOptRoll) Catch ()
		
	local proxies=#()
	local infoTxt = ""
	local proxiesRootPath = undefined
	local doSingleVoxel = true
	local conversionMode = "Scene"
	local appendText = "_O"
	local overWrite = false
	local existingFile = false
	local deleteOriginals = false
	
	fn getFilesRecursive root pattern =
	(
		doWeContinue=true
		dir_array=#(root)
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
	
	fn postProcessProxyList =
	(
		print proxies.count
		for p=proxies.count to 1 by -1 do
		(
			if (matchpattern proxies[p] pattern:("*"+appendText+".vrmesh")) do deleteItem proxies p
		)
		print proxies.count
	)
	
	fn findVRayBinFolder =
	(
		Val1=undefined
		try
		(
			registry.openKey HKEY_LOCAL_MACHINE "SYSTEM" accessRights:#readOnly key:&key1
			registry.openKey key1 "CurrentControlSet" accessRights:#readOnly key:&key2
			registry.openKey key2 "Control" accessRights:#readOnly key:&key3
			registry.openKey key3 "Session Manager" accessRights:#readOnly key:&key4
			registry.openKey key4 "Environment" accessRights:#readOnly key:&key5
			registry.queryValue key5 ("VRAY4_FOR_3DSMAX" + (maxVersion())[8] as string+"_MAIN") type:#REG_EXPAND_SZ value:&Val1 expand:true 
		)
		catch
		(

		)
		val1
	)

	fn getPly2VRMesh =
	(
		ply2vrm=""
		binPath=findVRayBinFolder()
		if binPath != undefined then 
		(
			ply2vrm = binPath+@"\ply2vrmesh.exe"
		)
		else
		(
			print "no path to ply2vrmesh.exe!"
		)
		ply2vrm
	)

	fn getSceneProxies =
	(
		proxies = getclassinstances vrayproxy
		if proxies.count != 0 then
		(
			infoTxt = ("Found " + proxies.count as string + " unique proxies in the scene.")
		)
		else
		(
			infoTxt = ("Found no proxies in the scene.")
		)
		ProxyOptRoll.infoLbl.text = infoTxt
	)
	
	fn getDiskProxies =
	(
		proxies = getFilesRecursive proxiesRootPath "*.vrmesh"
		postProcessProxyList()
		if proxies.count != 0 then
		(
			infoTxt = ("Found " + proxies.count as string + " unique proxies on disk.")
		)
		else
		(
			infoTxt = ("Found no proxies on disk.")
		)		
		ProxyOptRoll.infoLbl.text = infoTxt
	)
	
	fn convertProxies conversionMode=	
	(
		ply2vrmesh=getPly2VRMesh()
		if ply2vrmesh != "" then
		(
			if conversionMode == "Scene" then --proxies is filled with nodes, not filenames
			(
				for p in proxies do
				(
					print ("Working on " + p.filename)
					proxyPath=p.filename
					outputPath= getfilenamepath proxyPath + getfilenamefile proxyPath + "_O.vrmesh"
					cmdLine = "\"" + ply2vrmesh + "\" "+ "\"" + proxypath + "\" \""+ outputPath + "\"" 
					if doSingleVoxel do cmdLine += " -facesPerVoxel 10000000000 -mergeVoxels"
					print cmdLine
					hiddenDOSCommand cmdLine ExitCode:&exitCode
					if exitCode == 0 then
					(
						if doesfileExist outputPath then
						(
							p.filename = outputPath
							print "Proxy Replaced in its Loader!"
							if deleteOriginals do deleteFile proxyPath
						)
						else
						(
							print "Critical Error! Couldn't find the Optimised proxy file! No changes made to this Proxy Loader!"
						)
					)
					else
					(
						print exitCode
						print "Proxy Conversion Failed!"
					)
				)
			)
			else --proxies is filled with filenames, not nodes
			(
-- 				postProcessProxyList()
				
				for p in proxies do
				(
					exitCode=0
					print ("Working on " + p)
					proxyPath=p
					outputPath= getfilenamepath proxyPath + getfilenamefile proxyPath + appendText + ".vrmesh"
					if not overWrite then
					(
						if not doesFileExist outputPath do
						(
							cmdLine = "\"" + ply2vrmesh + "\" "+ "\"" + proxypath + "\" \""+ outputPath + "\"" 
							if doSingleVoxel do cmdLine += " -facesPerVoxel 10000000000 -mergeVoxels"
							print cmdLine
							
							hiddenDOSCommand cmdLine ExitCode:&exitCode
						)
					)
					else
					(
						cmdLine = "\"" + ply2vrmesh + "\" "+ "\"" + proxypath + "\" \""+ outputPath + "\"" 
						if doSingleVoxel do cmdLine += " -facesPerVoxel 10000000000 -mergeVoxels"
						print cmdLine
						
						hiddenDOSCommand cmdLine ExitCode:&exitCode						
					)
					
					if exitCode == 0 then
					(
						if doesfileExist outputPath then
						(
							if deleteOriginals do deleteFile proxyPath
							print "Proxy Converted on Disk!"
						)
						else
						(
							print "Critical Error! Couldn't find the Optimised proxy file!"
						)
					)
					else
					(
						print exitCode
						print "Proxy Conversion Failed!"
					)
				)				
			)
		)
		else
		(
			Messagebox "I couldn't find ply2vrmesh, make sure the V-Ray installation is current!"
		)
	)
	
	rollout ProxyOptRoll "V-Ray Proxy Optimiser" width:616 height:360
	(
		checkbutton 'modeCkb' "Process the Scene's Proxies" pos:[16,24] width:584 height:32 align:#left
		button 'browseBtn' "Browse" pos:[16,96] width:96 height:24 enabled:false align:#left
		edittext 'pathEdt' "" pos:[112,96] width:408 height:24 enabled:false align:#left
		button 'findBtn' "Find" pos:[528,96] width:72 height:24 enabled:false align:#left
		checkbutton 'SVCkb' "Single Voxel" pos:[16,160] width:136 height:24 checked:true align:#left
		label 'lbl6' "Append String:" pos:[168,160] width:72 height:16 align:#left		
		
		edittext 'appendEdt' "" pos:[248,160] width:72 height:24 align:#left
		checkButton 'keepCkb' "Keep Originals" pos:[352,160] width:112 height:24 align:#left		
		checkbutton 'writeCkb' "Skip Existing" pos:[472,160] width:122 height:24 align:#left	
		
		label 'infoLbl' "" pos:[16,224] width:584 height:56 align:#left
		button 'goBtn' "GO" pos:[8,296] width:600 height:56 align:#left
		
		
		GroupBox 'grp1' "Operation Mode:" pos:[8,8] width:600 height:56 align:#left
		GroupBox 'grp2' "Disk Options:" pos:[8,72] width:600 height:56 align:#left
		GroupBox 'grp3' "Common Options:" pos:[8,136] width:600 height:56 align:#left
		GroupBox 'grp4' "Info:" pos:[8,200] width:600 height:88 align:#left

	

		
		on ProxyOptRoll open do
		(
			appendEdt.text = appendText = "_O"			
			getSceneProxies()
		)
		on modeCkb changed state do
		(
			if state then
			(
				modeCkb.caption = "Process Proxies on Disk"
				conversionMode = "Disk"
				if proxiesRootPath == undefined or proxies.count == 0 do infoLbl.text="Pick a Folder and press 'Find' to look for proxies on disk"
			)
			else
			(
				modeCkb.caption = "Process the Scene's Proxies"
				conversionMode = "Scene"
				getSceneProxies()
			)
			pathEdt.enabled=browseBtn.enabled = state
		)
		on browseBtn pressed do
		(
			proxiesRootPath = getSavePath caption:"Choose a root to recursively scan for proxies..."
			if proxiesRootPath!=undefined then 
			(
				pathEdt.text = proxiesRootPath
				findBtn.enabled = true
			)
			else
			( 
				pathEdt.text = ""
				findBtn.enabled = false
				proxies=#()
				infoLbl.text = "Pick a Folder and press 'Find' to look for proxies on disk"
			)
		)
		on findBtn pressed do
		(
			getDiskProxies()
		)
		on SVCkb changed state do
		(
			doSingleVoxel = state
		)
		on appendEdt changed edtT do
		(
			appendText = edtT
		)
		on keepCkb changed state do
		(
			deleteOriginals=state
			if state then 
			(
				keepCkb.text = "Delete Originals"
			)
			else
			(
				keepCkb.text = "Keep Originals"
			)
		)
		on writeCkb changed state do
		(
			if state then
			(
				writeCkb.text = "Overwrite Existing"
			)
			else
			(
				writeCkb.text = "Skip Existing"
			)
			overWrite = state	
		)
		on goBtn pressed do
		(
			convertProxies doLoadersReplace
		)
	)

	createdialog ProxyOptRoll
)
