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
	local newOverrideMaterial=VrayLightMtl name:"shaderSubNetworkInspectorMaterial"
	local theSubNetwork = undefined
	local oldObjectMaterial=undefined
	local newObjectMaterial=newOverrideMaterial
	
	fn collectStatus =
	(
		wasOverrideOn =renderers.current.options_overrideMtl_on
		oldOverrideMaterial=renderers.current.options_overrideMtl_mtl		
	)
	
	fn setStatus status =
	(
		if status then
		(
			vrayStopIPR()			
			renderers.current.options_overrideMtl_on=true
			renderers.current.options_overrideMtl_mtl=newOverrideMaterial
			renderSceneDialog.commit()
			renderSceneDialog.update()	
			vrayStartIPR()						
		)
		else
		(
			vrayStopIPR()
			renderers.current.options_overrideMtl_on=wasOverrideOn
			renderers.current.options_overrideMtl_mtl=oldOverrideMaterial
			renderSceneDialog.commit()
			renderSceneDialog.update()	
			vrayStartIPR()
		)
	)
	
	fn setShader subNet =
	(
		newOverrideMaterial.texmap=undefined
		if (superclassof subNet == textureMap) do
		(
			newOverrideMaterial.texmap=subNet
		)
	)
	
	local theTimer = dotNetObject "System.Windows.Forms.Timer"	
	
	fn checkShaderSelectionChange status= 
	(
		fn checkSelection =
		(
			currSel=(medit.GetCurMtl())
			if currSel != theSubNetwork do
			(
				theSubNetwork=currSel
				setShader theSubNetwork
-- 				setStatus on
				print "Changed!"
			)
				
		)
		if status then 
		(
			theTimer.start()	
			dotnet.addEventHandler theTimer "tick" checkSelection
			theTimer.interval = 250
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
				collectStatus()
				theSubNetwork =	(medit.GetCurMtl())		
				setShader theSubNetwork
				setStatus On
				checkShaderSelectionChange on
			)
			else
			(
				ckb1.text="Inspection OFF"
				checkShaderSelectionChange off
				setStatus Off				
			)
		)
		
		on shaderInspectorRoll close do
		(
				checkShaderSelectionChange off
				setStatus Off					
		)
	)
	
	createdialog shaderInspectorRoll
	
-- 	medit.GetCurMtl()
)