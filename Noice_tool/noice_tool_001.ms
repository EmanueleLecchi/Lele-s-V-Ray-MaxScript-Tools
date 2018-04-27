(
	global noiceRoll
	try (destroyDialog noiceRoll) catch()
	local inPath=undefined
	
	local exrs=#()
	local noice=undefined
	
	fn findGlobalNoice =
	(
		noice=if doesFileExist ((getDir #maxroot) + @"Plugins\MAXtoA\noice.exe") then ((getDir #maxroot) + @"Plugins\MAXtoA\noice.exe") else undefined
		print noice
	)
	fn findLocalNoice =
	(
		noice = if doesFileExist (inPath + @"noice.exe") then (inPath + @"noice.exe") else undefined
	)
	
	fn getInPath =
	(
		inPath= try (getfilenamepath (getOpenFileName filename:"*.exr" caption:"pick any image or AOV in the sequence")) catch (undefined)
-- 		if inPath != undefined do inPath+=@"\"
	)
	
	fn collectExrs =
	(
		if inPath != undefined do
		(
			exrs=for f in (getfiles (inPath+"*.exr")) where (matchpattern f pattern:"*AOV*") collect f
		)
	)	
	
	fn fillInfoLabel =
	(
		noiceRoll.lbl1.text = if exrs.count > 0 then ("Found " + exrs.count as string+ " frames to process.") else ("")
	)
	
	fn deNoice =
	(	
		if exrs.count > 0 do
		(
			shellString=""
			for i = 1 to exrs.count do
			(
				if i == 1 then
				(
					shellString += (noice + " -i " + exrs[i] + " -i " + exrs[i+1] + " -o " + inpath + (getfilenamefile exrs[i]) + "_denoised.exr\n")
				)
				else if i == exrs.count then
				(
					shellString += (noice + " -i " + exrs[i] + " -i " + exrs[i-1] + " -o " + inpath + (getfilenamefile exrs[i]) + "_denoised.exr\n")
				)
				else
				(
					shellString += (noice + " -i " + exrs[i] + " -i " + exrs[i-1] + " -i " + exrs[i+1] + " -o " + inpath + (getfilenamefile exrs[i]) + "_denoised.exr\n")
				)
-- 				print shellstring
-- 				doscommand shellstring 
			)	
		)	
		outfilePath=inpath+"deNoice.bat"
		outFileStream=createFile outFilePath
		format "%" shellString to:outFileStream
		close outFileStream
		shellLaunch inPath ""
	)
	
	rollout noiceRoll "Noice helper roll" width:368 height:104
	(
		button 'btn1' "Pick Path" pos:[8,8] width:352 height:16 align:#left
		label 'lbl1' "" pos:[8,32] width:352 height:16 align:#left
		button 'btn2' "go" pos:[8,56] width:352 height:40 align:#left enabled:false
		
-- 		on noiceRoll open do
-- 		(
-- 			findGlobalNoice()
-- 		)
		on btn1 pressed do
		(
			getInPath()
			collectEXRs()
			fillInfoLabel()
			btn2.enabled=if exrs.count > 0 then true else false
		)
		on btn2 pressed do
		(
			findGlobalNoice()
			if noice == undefined do findLocalNoice()
			if noice != undefined then deNoice() else messageBox "noice.exe not found!"
		)
	)
	createDialog noiceRoll
)
