(
	
	global ATSRoll
	
	try (destroyDialog ATSRoll)
	catch()

	theVRayHDRIs=getClassInstances VRayHDRI
	theTiled=#()
	theTiledNames=#()	
	
	fn getFilesRecursive root pattern =
	(
		dirArray = GetDirectories (root+"*")
		if dirArray.count == 0 then dirArray[1]=root
		for d in dirArray do join dirArray (GetDirectories (d+"*"))
		my_files = #()
		for f in dirArray do join my_files (getFiles (f + pattern))
		my_files
	)
	
	
	bleh=#("whatever","whatever_tiled")

	
	fn doTheDoodles rootStr appendStr =
	(
		theTiled=#()
		theTiledNames=#()
		theVRayHDRIs=getClassInstances VRayHDRI		
		theTiled=(getFilesRecursive rootStr  ( "*" + appendStr + ".exr") )
-- 		print theTiled
		for t in Thetiled do
		(
			append theTiledNames (getFileNameFile t)
		)
-- 		print theVRayHDRIs
		
		for v=1 to theVRayHDRIs.count do
		(
			oldName=getfilenameFile (theVRayHDRIs[v].hdriMapName)
			found=findItem theTiledNames (oldName + appendStr)
			print found
			if found!=0 do
			(
				print "found!"
				print theTiled[found]
				theVRayHDRIs[v].hdriMapName = theTiled[found]
			)
		)
		
	)
	
	rollout ATSRoll "Auto Tiled Replacer" width:488 height:88
	(
		label 'rootLbl' "Pick Search Root:" pos:[8,8] width:88 height:16 align:#left
		button 'browseBtn' "Browse..." pos:[96,8] width:56 height:16 align:#left
		editText 'rootEdt' "" pos:[160,8] width:320 height:16 enabled:false align:#left text:@"E:\_downloads\completed\Evermotion Archinteriors vol 37\Scene_001\maps"
		label 'appLbl' "Tiled images append string:" pos:[8,32] width:144 height:16 align:#left
		editText 'appEdt' "" pos:[160,32] width:320 height:16 enabled:true align:#left text:"_tiled"
		button 'goBtn' "GO" pos:[8,56] width:472 height:24 align:#left
		
		on browseBtn pressed do
		(
			try (rootEdt.text = getSavePath caption:"Choose the root of your Max files location" initialDir:@"E:\_downloads\completed\Evermotion Archinteriors vol 37\Scene_001\maps")
			catch (rootEdt.text = @"E:\")
		)
		on goBtn pressed do
		(

			doTheDoodles rootEdt.text appEdt.text
		)
	)
		
	createDialog ATSRoll
)