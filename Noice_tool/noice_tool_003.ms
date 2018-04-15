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
	)
	
	fn collectExrs =
	(
		if inPath != undefined do
		(
			exrs=for f in (getfiles (inPath+"*.exr")) where (matchpattern f pattern:"*AOV*") and not (matchpattern f pattern:"*denoised_*") collect f
		)
	)	
	
	fn fillInfoLabel =
	(
		noiceRoll.lbl1.text = if exrs.count > 1 then ("Found " + exrs.count as string+ " frames to process.") else if exrs.count == 1 then ("Found a single frame to process.") else ("")
	)
	
	fn sanitiseString inString =
	(
		outString=substituteString instring "." "_"
	)
	
	fn deNoice =
	(	
		if exrs.count != 0 do
		(
			pr=noiceRoll.spn1.value as string
			sr=noiceRoll.spn2.value as string
			va=noiceRoll.spn3.value as string
			shellString=""
			
			if exrs.count > 1 then
			(
				for i = 1 to exrs.count do
				(
					if i == 1 then
					(
						shellString += ("\""+ noice + "\" -pr " + pr + " -sr " + sr + " -v " + va + " -i \"" + exrs[i] + "\" -i \"" + exrs[i+1] + "\" -o \"" + inpath + "denoised_" + pr + "_" + sr + "_" + sanitiseString va + "_" + (getfilenamefile exrs[i]) +".exr\"\n")
					)
					else if i == exrs.count then
					(
						shellString += ("\""+ noice + "\" -pr " + pr + " -sr " + sr + " -v " + va + " -i \"" + exrs[i] + "\" -i \"" + exrs[i-1] + "\" -o \"" + inpath + "denoised_" + pr + "_" + sr + "_" + sanitiseString va + "_" + (getfilenamefile exrs[i]) +".exr\"\n")
					)
					else
					(
						shellString += ("\""+ noice + "\" -pr " + pr + " -sr " + sr + " -v " + va + " -i \"" + exrs[i] + "\" -i \"" + exrs[i-1] + "\" -i \"" + exrs[i+1] + "\" -o \"" + inpath + "denoised_" + pr + "_" + sr + "_" + sanitiseString va + "_" + (getfilenamefile exrs[i]) +".exr\"\n")
					)
				)	
			)
			else
			(
				shellString += ("\""+ noice + "\" -pr " + pr + " -sr " + sr + " -v " + va + " -i \"" + exrs[1] + "\" -o \"" + inpath + "denoised_" + pr + "_" + sr + "_" + sanitiseString va + "_" + (getfilenamefile exrs[1]) +".exr\"\n")
			)
			
			outfilePath=inpath + (getfilenamefile exrs[1]) + "_pr_" + pr + "_sr_" + sr + "_va_" + sanitiseString va + "_deNoice.bat"
			outFileStream=createFile outFilePath
			format "%" shellString to:outFileStream
			close outFileStream
			shellLaunch inPath ""
		)
	)
	
	rollout noiceRoll "Noice helper roll" width:368 height:200
	(
		button 'btn1' "Pick Path" pos:[8,8] width:352 height:16 align:#left
		button 'btn2' "go" pos:[8,152] width:352 height:40 enabled:false align:#left

		spinner 'spn1' "" pos:[16,72] width:56 height:16 range:[1,10,3] type:#integer scale:1 align:#left
		spinner 'spn2' "" pos:[16,96] width:56 height:16 range:[1,100,9] type:#integer scale:1  align:#left
		spinner 'spn3' "" pos:[16,120] width:56 height:16 range:[0.001,10,0.5] type:#float scale:0.01 align:#left

		groupBox 'grp1' "Parameters:" pos:[8,48] width:352 height:96 align:#left
		label 'lbl1' "" pos:[8,32] width:352 height:16 align:#left
		label 'lbl2' "Pixel Neighborhood Patch Radius" pos:[80,72] width:264 height:16 align:#left
		label 'lbl3' "Pixel Search Radius" pos:[80,96] width:264 height:16 align:#left
		label 'lbl4' "Variance" pos:[80,120] width:264 height:16 align:#left
		
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
