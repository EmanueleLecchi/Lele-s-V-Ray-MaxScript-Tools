(
	/*
	The script should allow one-button inspection of the currently viewed/selected materialeditor map and subtree.
	*) Currently it (ab)uses the override material, evaluate doing it per parent shader.
	*) Find a way to detect if the current selection in the material editor changed. (A timer, perhaps?)
	*) Makke it work with SME and its selections!
	
	*/
	global shaderInspectorRoll
	try (destroydialog shaderInspectorRoll) catch()
	
	local oldOverrideMaterial=undefined
	local wasOverrideOn = renderers.current.options_overrideMtl_on
	local newOverrideMaterial=VrayLightMtl name:"shaderSubNetworkInspectorMaterial" compensate_exposure:on color:green
	local theSubNetwork = undefined
	local theMeditNumber = undefined
	local oldObjectMaterial=undefined
	local newObjectMaterial=newOverrideMaterial
	local theIsolateGeo=#()
	local theMaterial = undefined
	local oldHiddenLights = undefined 
	local theTimer = dotNetObject "System.Windows.Forms.Timer"	
	local theSecondTimer = dotNetObject "System.Windows.Forms.Timer"	

	
	
	fn collectStatus =
	(
		wasOverrideOn =renderers.current.options_overrideMtl_on
		oldOverrideMaterial=renderers.current.options_overrideMtl_mtl	
		oldHiddenLights = renderers.current.options_hiddenLights
	)
	
	fn isolateGeo mode =
	(
		for g in geometry where g.material != (medit.GetTopMtlSlot activeMeditSlot) do append theIsolateGeo g
		for l in lights where not l.isHidden do append theIsolateGeo l
		for g in theIsolateGeo do g.isHidden=mode
	)
	
	fn delayStartIPR =
	(
		fn startIPR = 
		(
						
			print "Starting IPR after having waited 5000ms"
			vrayStartIPR()

		)
		
		theSecondTimer.stop()
		theSecondTimer.start()	
		dotnet.addEventHandler theSecondTimer "tick" startIPR
		theSecondTimer.interval = 5000
		
	)
	
	fn setStatus status =
	(
		if status then
		(
			vrayStopIPR()			
			renderers.current.options_overrideMtl_on=true
			renderers.current.options_overrideMtl_mtl=newOverrideMaterial
			renderers.current.options_hiddenLights = false
			renderSceneDialog.commit()
			renderSceneDialog.update()	
			isolateGeo true
			delayStartIPR()
		)
		else
		(
			vrayStopIPR()
			renderers.current.options_overrideMtl_on=wasOverrideOn
			renderers.current.options_overrideMtl_mtl=oldOverrideMaterial
			renderers.current.options_hiddenLights = oldHiddenLights
			renderSceneDialog.commit()
			renderSceneDialog.update()	
			isolateGeo false
-- 			vrayStartIPR()
		)
	)
	
	fn setShader subNet =
	(
		newOverrideMaterial.texmap=undefined
		if (superclassof subNet == textureMap) then
		(
			newOverrideMaterial.texmap=subNet
		)
		else 
		(
			"undefined map!"
		)
	)
	

	

	
	fn checkShaderSelectionChange status= 
	(
		fn checkSelection =
		(
			currSel=(medit.GetCurMtl())
			if currSel != theSubNetwork do
			(
				print ("Old Map name was " + theSubNetwork.name + ", while the new Map name is " + currSel.name )
				vrayStopIPR()				
				theSubNetwork=currSel
				setShader theSubNetwork
-- 				setStatus on
				print "Map Changed!"
-- 				vrayUpdateIPR()
				delayStartIPR()
			)
			currMaterial = (medit.GetTopMtlSlot activeMeditSlot)
			if currMaterial != theMaterial do
			(
				print ("Old Material name was " + theMaterial.name + ", while the new Material name is " + currMaterial.name )
				vrayStopIPR()				
				theMaterial = currMaterial
				isolateGeo false
				theIsolateGeo = #()
				isolateGeo True
				print "Material Changed! Re-Isolating!"
				delayStartIPR()
			)
		)
		
		if status then 
		(
			theTimer.start()	
			dotnet.addEventHandler theTimer "tick" checkSelection
			theTimer.interval = 50
		)
		else
		(
			theTimer.stop()
		)
	)
	
	rollout shaderInspectorRoll "Shader Network Inspector v001" width:352 height:72
	(
		checkButton 'ckb1' "Inspection OFF" pos:[8,8] width:336 height:56 align:#left
		
		on ckb1 changed state do
		(
			if state then
			(
				ckb1.text="Inspection ON"	
				theIsolateGeo=#()
				collectStatus()
				theSubNetwork =	(medit.GetCurMtl())	
				theMaterial = (medit.GetTopMtlSlot activeMeditSlot)
				setShader theSubNetwork
				isolateGeo true
				setStatus On
				checkShaderSelectionChange on
			)
			else
			(
				ckb1.text="Inspection OFF"
				isolateGeo false
				theIsolateGeo=#()					
				checkShaderSelectionChange off
				setStatus Off

			)
		)

		on shaderInspectorRoll open do
		(
			
		)
		on shaderInspectorRoll close do
		(
				isolateGeo false
				theIsolateGeo=#()
				checkShaderSelectionChange off
				setStatus Off					
		)
	)
	
	createdialog shaderInspectorRoll
	
-- 	medit.GetCurMtl()
)