/*
VCloud submitter mockup v 1.00
*/
(
	--global floater, to keep the instance unique 
	global vcFloater
	try (closeRolloutFloater vcfloater) catch()
	--local rollouts, these get destroyed as the floater is closed
	local vcRoll1, vcRoll2, vcRoll3, vcRoll4, vcRoll5, vcRoll6
	--local variables to carry the relevant data 
	local outputRes= if renderers.current.output_getsetsfrommax then [renderWidth,renderHeight,renderPixelAspect] else [renderers.current.output_width,renderers.current.output_height,renderers.current.output_aspect]
	local outputInterval=[rendStart,rendEnd,RendNthFrame]
	local outputPath = ""
	
	fn grabOutputPath =
	(
		renderSceneDialog.commit()
		outputPath = if renderers.current.output_saveRawFile then renderers.current.output_rawFileName else rendOutputFilename
	)

	rollout vcRoll1 "General Behaviour:" width:320 height:48
	(
		checkbox chk1 "" pos:[8,16] width:16 height:16 checked:true align:#left
		label lbl1 "Use Current 3ds Max Render Settings" pos:[32,16] width:180 height:16 align:#left
	
		on vcRoll1 open do
		(
			renderSceneDialog.commit()
		)
		on chk1 changed state do
		(
			if state then --disable them all,  rollouts closed, short floater
			(
				for c in vcRoll2.controls do c.enabled=not state
				for c in vcRoll3.controls do c.enabled=not state
				for c in vcRoll4.controls do c.enabled=not state
				vcFloater.size-=[0,248]
			)
			else
			(
				vcRoll2.controls[1].enabled=vcRoll3.controls[1].enabled=vcRoll4.controls[1].enabled=true
				vcFloater.size+=[0,248]
			)
	
-- 				
			vcRoll2.open=vcRoll3.open=vcRoll4.open=not state
			
		)			
	)
	
	rollout vcRoll2 "Image Properties:" width:320 height:64
	(
		checkbox 'chk1' "" pos:[8,16] width:16 height:16 checked:false align:#left 
 
 
		spinner 'spn1' "" pos:[24,40] width:64 height:16 enabled:false range:[1,16384,-1] type:#integer scale:1 align:#left
		spinner 'spn2' "" pos:[112,40] width:64 height:16 enabled:false range:[1,16384,-1] type:#integer scale:1 align:#left
		spinner 'spn3' "" pos:[200,40] width:64 height:16 enabled:false range:[1e-06,100000,-1] type:#float scale:1 align:#left
		button 'btn1' "Grab" pos:[272,16] width:40 height:16 align:#left
		
		label 'lbl1' "Override Resolution:" pos:[24,16] width:136 height:16 enabled:false align:#left
		label 'lbl2' "W:" pos:[8,40] width:16 height:16 enabled:false align:#left
		label 'lbl3' "H:" pos:[96,40] width:16 height:16 enabled:false align:#left
		label 'lbl4' "A:" pos:[184,40] width:16 height:16 enabled:false align:#left
		
		
		on vcRoll2 open do
		(
			renderSceneDialog.commit()
			if not vcRoll1.controls[1].checked do
			(
				for i = 2 to 7 do vcRoll2.controls[i].enabled=chk1.checked
			)
			outputRes= if renderers.current.output_getsetsfrommax then [renderWidth,renderHeight,renderPixelAspect] else [renderers.current.output_width,renderers.current.output_height,renderers.current.output_aspect]
		
			if spn1.value== -1 do spn1.value = outputRes.x 
			if spn2.value== -1 do spn2.value = outputRes.y
			if spn2.value== -1.0 do spn3.value = outputRes.z
		
		)
		on vcRoll2 rolledUp isOpen do
		(
			if isOpen and not vcRoll1.controls[1].checked do 
			(
				for i = 2 to 7 do vcRoll2.controls[i].enabled=chk1.checked
		
			)
		)
		on chk1 changed state do
		(
			for i = 2 to 7 do vcRoll2.controls[i].enabled=state
		)
		on btn1 pressed do
		(
			renderSceneDialog.commit()
			outputRes= if renderers.current.output_getsetsfrommax then [renderWidth,renderHeight,renderPixelAspect] else [renderers.current.output_width,renderers.current.output_height,renderers.current.output_aspect]
		
			spn1.value = outputRes.x 
			spn2.value = outputRes.y
			spn3.value = outputRes.z
		)
	)
	
	rollout vcRoll3 "Sequence Properties:" width:320 height:64
	(
		checkbox 'chk1' "" pos:[8,16] width:16 height:16 checked:false across:2 align:#left
		spinner 'spn1' "" pos:[24,40] width:64 height:16 enabled:false range:[-16384,16384,-1234567] type:#integer scale:1 align:#left
		spinner 'spn2' "" pos:[112,40] width:64 height:16 enabled:false range:[-16384,16384,-1234567] type:#integer scale:1 align:#left
		spinner 'spn3' "" pos:[216,40] width:64 height:16 enabled:false range:[1,16384,-1234567] type:#integer scale:1 align:#left
		button 'btn1' "Grab" pos:[272,16] width:40 height:16 align:#left
		
		label 'lbl1' "Override Start, End, Nth" pos:[24,16] width:136 height:16 enabled:false align:#left
		label 'lbl2' "S:" pos:[8,40] width:16 height:16 enabled:false align:#left
		label 'lbl3' "E:" pos:[96,40] width:16 height:16 enabled:false align:#left
		label 'lbl4' "Nth:" pos:[184,40] width:24 height:16 enabled:false align:#left
		
		on vcRoll3 open do
		(
			renderSceneDialog.commit()
			if not vcRoll1.controls[1].checked do 
			(
				for i = 2 to 9 do vcRoll3.controls[i].enabled=chk1.checked
			)
			if spn1.value==-1234567 do spn1.value = rendStart
			if spn2.value==-1234567 do spn2.value = rendEnd
			if spn3.value==-1234567 do spn3.value = rendNThFrame
		)
		on vcRoll3 rolledUp isOpen do
		(
			if isOpen and not vcRoll1.controls[1].checked do 
			(
				for i = 2 to 9 do vcRoll3.controls[i].enabled=chk1.checked
	
			)
		)
		on chk1 changed state do
		(
			for i = 2 to 9 do vcRoll3.controls[i].enabled=state
		)
		
		on btn1 pressed do
		(
			renderSceneDialog.commit()
			spn1.value = rendStart
			spn2.value = rendEnd
			spn3.value = rendNThFrame
		)
	)
	
	rollout vcRoll4 "Output Options:" width:320 height:120
	(
		checkbox 'chk1' "" pos:[8,16] width:16 height:16 checked:false across:2 align:#left
		button 'btn1' "Browse..." pos:[8,32] width:304 height:24 align:#left
		button 'btn2' "Grab" pos:[272,16] width:40 height:16 align:#left
		
		label 'edt1' "" pos:[8,64] width:304 height:54 enabled:true align:#left
		label 'lbl1' "Override Output Path" pos:[24,16] width:136 height:16 enabled:false align:#left
		
		fn fillText =
		(
			filePath = getfilenamepath outputPath
			fileName = getfilenamefile outputPath
			fileType = getfilenametype outputPath
			edt1.text = "Path: " + filepath +"\n" + "Name: " + filename +"\n" + "Type: " + filetype
		)
		
		on vcRoll4 open do
		(
			renderSceneDialog.commit()
			if not vcRoll1.controls[1].checked do 
			(
				for i = 2 to 5 do vcRoll4.controls[i].enabled=chk1.checked
			)
			
			if outputPath=="" do
			( 
				grabOutputPath()
				fillText()
			)
		)
		on vcRoll4 rolledUp isOpen do
		(
			if isOpen and not vcRoll1.controls[1].checked do 
			(
				for i = 2 to 5 do vcRoll4.controls[i].enabled=chk1.checked
				
			)
		)
		on chk1 changed state do
		(
			for i = 2 to 5 do vcRoll4.controls[i].enabled=state
		)
		
		on btn1 pressed do
		(
			outputPath = getSaveFileName()
			if outputPath == undefined do grabOutputPath()
			fillText()
		)
		on btn2 pressed do
		(
			grabOutputPath()
			fillText()
		)
	)
	
	rollout vcRoll5 "Local Test Preview:" width:320 height:240
	(
		button 'btn1' "Render locally what will be sent to the Cloud" pos:[8,16] width:304 height:24 align:#left
		
		checkbox 'chk1' "" pos:[8,48] width:16 height:16 checked:false across:2 align:#left
			spinner 'spn1' "" pos:[24,64] width:64 height:16 enabled:false range:[1,16384,-1] type:#integer scale:1 align:#left
			spinner 'spn2' "" pos:[112,64] width:64 height:16 enabled:false range:[1,16384,-1] type:#integer scale:1 align:#left
			spinner 'spn3' "" pos:[200,64] width:64 height:16 enabled:false range:[1e-06,100000,-1] type:#float scale:1 align:#left
			label 'lbl1' "Override Preview Resolution" pos:[24,48] width:144 height:16 enabled:false align:#left
			label 'lbl2' "W:"  pos:[8,64] width:16 height:16 enabled:false align:#left
			label 'lbl3' "H:" pos:[96,64] width:16 height:16 enabled:false align:#left
			label 'lbl4' "A:" pos:[184,64] width:16 height:16 enabled:false align:#left
			
		checkbox 'chk2' "" pos:[8,88] width:16 height:16 checked:false across:2 align:#left
			spinner 'spn4' "" pos:[24,104] width:64 height:16 enabled:false range:[0.0,16384.0,1.0] type:#float scale:0.1 align:#left
			spinner 'spn5' "" pos:[112,104] width:64 height:16 enabled:false range:[0.0,16384.0,0.04] type:#float scale:0.1 align:#left
			label 'lbl5' "Set preview quality" pos:[24,88] width:104 height:16 enabled:false align:#left
			label 'lbl6' "M:"  pos:[8,104] width:16 height:16 enabled:false align:#left
			label 'lbl7' "NT:"  pos:[96,104] width:16 height:16 enabled:false align:#left
			
		local hasbeenopenedonce=false
		on vcRoll5 open do
		(
			spn1.value = floor (outputRes.x/2.0)
			spn2.value = floor (outputRes.y/2.0)
			spn3.value = outputRes.z
		)
		on vcRoll5 rolledUp isOpen do
		(
			rolloutSize=128
			if isOpen then 
			(
				print vcFloater.size
				vcFloater.size+=[0,rolloutSize] 
				hasbeenopenedonce=true
			)
			else
			(
				if hasbeenopenedonce do vcFloater.size-=[0,rolloutSize] 
			)
		)

		on chk1 changed state do
		(
			for i = 3 to 9 do vcRoll5.controls[i].enabled= state

		)
		on chk2 changed state do
		(
			for i = 11 to 15 do vcRoll5.controls[i].enabled= state
		)
		
		on btn1 pressed do
		(
			--run the preview command with the vlaues specified in the rollout controls, or the global ones
		)
		
	)
	rollout vcRoll6 "Submission:" width:320 height:120
	(
		button 'btn1' "Submit to the Cloud" pos:[8,16] width:304 height:24 align:#left
		
	)
	
	vcFloater=newRolloutFloater "V-Ray Cloud Submitter" 328 220
	addRollout vcRoll1 vcFloater 
	addRollout vcRoll2 vcFloater rolledUp:true
	addRollout vcRoll3 vcFloater rolledUp:true
	addRollout vcRoll4 vcFloater rolledUp:true
	addrollout vcRoll5 vcFloater rolledUp:true
	addrollout vcRoll6 vcFloater rolledUp:false
	
	
)
