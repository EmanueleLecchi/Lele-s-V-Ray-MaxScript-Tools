(
	
	global proxyConverterRoll
	try (destroyDialog proxyConverterRoll) catch()
	local inPath = undefined
	local Objs=#()
	local totalFileSize= 0.0
	plyPath = @"C:\Program Files\Chaos Group\V-Ray\3ds Max 2018\bin\ply2vrmesh.exe"
				
	fn getFilesRecursive root pattern =
	(
		dir_Array=#()
		dir_Array[1] = (root+"\\")
-- 		join dir_array ( GetDirectories (root+"/*"))

		for d in dir_array do
			join dir_array (GetDirectories (d+"/*"))
		my_files = #()
		for f in dir_array do
			join my_files (getFiles (f + pattern))
		my_files
	)

	fn sanitizeObjPaths Objs =
	(
		for o=1 to Objs.count do
		(
			objs[o]="\""+substituteString objs[o] @"\" @"\\"+"\""
		)
		Objs
	)
	fn sanitizePlyPath =
	(
		plyPath="\""+substituteString plyPath @"\" @"\\"+"\""
	)	
	
	fn sanitizeFilePath filePath doSlashes =
	(
		if doSlashes then filePath="\""+substituteString filePath @"\" @"\\"+"\"" 
			else filePath="\""+filePath+"\"" 
		filePath
	)	
	
	fn getObjsSize Objs =
	(
		totalFileSize=0.0
		for o in objs do totalFileSize += getfilesize o
		totalFileSize/=1024*1024.0
		totalFileSize
	)
	
	fn convertToProxy Objs =
	(

		plyPath=sanitizeFilePath plyPath false
		
		thecounter=0
		for o in Objs do
		(
			windows.processPostedMessages()
			thecounter+=1			
			proxyName=getfilenamepath o + (getfilenamefile o) + ".vrmesh"
			if not (doesFileExist proxyname) do
			(
				print ("about to convert " + o + "; " + thecounter as string + " out of "+ objs.count as string +"; Filesize: " + ((getfilesize o)/1024.0^2) as string + "mb")
				str=plyPath +" " + sanitizeFilePath o false + " " + sanitizeFilePath proxyName false+" -facesPerVoxel 5000"
				sanitizeFilePath str false
				HiddenDOSCommand str donotwait:false exitCode:&exitcode
				if exitcode==0 then 
				(
					print ("processed file " + theCounter as string + " out of a total of " + objs.count as string)
				)
				else
				(
					print ("file " + o + " encountered an error of type " + exitcode as string)
-- 					exit
				)
			)
		)
		if thecounter==Objs.count do print "all done!"
	)
	
	rollout proxyConverterRoll "Untitled" width:392 height:168
	(
		button 'btn1' "Browse" pos:[304,8] width:80 height:24 align:#left
		edittext 'edt1' "" pos:[8,8] width:280 height:24 enabled:true align:#left
		button 'btn2' "Go" pos:[8,136] width:376 height:24 align:#left
		label 'lbl1' "" pos:[16,40] width:360 height:88 align:#left
		
		on btn1 pressed do
		(
			inPath=getSavePath initialDir:@"G:\_Lele\Disney_Island\extracted\BasePackage\island\obj"
			if inPath != undefined then
			(
				edt1.text=inPath
				Objs=#()
				Objs=getFilesRecursive inPath "*.obj"
				print objs
				totalFileSize = getObjsSize Objs
				lbl1.text=("Found a total of " + objs.count as string + " .obj files to convert\nTotal Filesize on disk is " + totalFileSize as string + " Mb")
			)
			else
			(
				edt1.text=""
				objs=#()
			)
		)
		on btn2 pressed do
		(
			if objs.count!=0 do
			(
				
				if doesFileExist plyPath then
				(
					convertToProxy objs
				)
				else
				(
					messagebox "can't find the Ply2VRmesh.exe file!"
				)
			)
		)
	)
	
	createDialog proxyConverterRoll
	
)

