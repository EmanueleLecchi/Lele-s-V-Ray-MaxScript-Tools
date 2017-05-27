(
	global vrayShaderDeckRoll
	try (destroydialog vrayShaderDeckRoll) catch()
	
	
	local timeSliderWasVisible=undefined
	local trackBarWasVisible=undefined
	local statusPanelWasVisible=undefined
	local expertModeWasActive=undefined
	local matEditorWasOpen=undefined
	
	fn getUIStatus =
	(
		timeSliderWasVisible=timeslider.isVisible()
		trackBarWasVisible=trackbar.visible
		statusPanelWasVisible=statusPanel.visible
		expertModeWasActive=cui.getExpertMode() 
		matEditorWasOpen = MatEditor.isOpen()
	)	
	
	fn setSuperExpertMode status =
	(
		if status then 		--if the bool is true/1/on then 
		( 
			getUIStatus()	--we gather the UI status right before  changing it
			
			timeslider.Setvisible false		--turn off the time slider
			trackbar.visible = false		--turn off the track bar
			cui.expertModeOn()				-- set the UI in expert mode
			statusPanel.visible = false		--hide the status bar as well (consider NOT doing this if showing a progressbar.
			MatEditor.close()
		)
		
		else 				--if the bool is false/0/off, then 
		(
			--we return the UI to its original state, if those states were correctly gathered, otherwise we default to the standard UI visibility setup
			if timeSliderWasVisible != undefined then 
			(
				timeslider.Setvisible timeSliderWasVisible
			)
			else 
			(
				timeslider.Setvisible true	
			)
			
			if trackBarWasVisible != undefined then 
			(
				trackbar.visible = trackBarWasVisible 
			)
			else 
			(
				trackbar.visible = true
			)
			
			if expertModeWasActive != undefined then	
			(
				if not expertModeWasActive do cui.expertModeOff()
			)
			else 
			(
				cui.expertModeOff()
			)
			
			if statusPanelWasVisible != undefined then 
			(
				statusPanel.visible = statusPanelWasVisible 
			)
			else 
			(
				statusPanel.visible = true
			)
			
			if matEditorWasOpen != undefined do 
			(
				if matEditorWasOpen do matEditor.open()
			)
		)
	)	
	
	fn upgradeBRDFs =
	(
		setSuperExpertMode on
		for m in (getclassinstances VrayMtl) do
		(
			m.brdf_type = 4
			m.option_glossyFresnel = true
		)
		setSuperExpertMode off
	)
	
	fn upgradeBumps = 
	(
		setSuperExpertMode on
		for m in (getclassinstances VrayMtl) where (m.texmap_bump != undefined and (classof m.texmap_bump) != vrayColor2Bump and m.texmap_bump_on ) do
		(
			theTex=vrayColor2Bump map:m.texmap_bump height:(m.texmap_bump_multiplier/100.0)
			m.texmap_bump = theTex
			m.texmap_bump_multiplier = 100
		)
		setSuperExpertMode off	
	)
	
	fn upgradeOpacity =
	(	
		setSuperExpertMode on
		for m in (getclassinstances VrayMtl) do
		(
			m.option_opacityMode = 2
			m.option_cutOff = 0.001
			m.refraction_fogUnitsScale_on = on
		)
		setSuperExpertMode off		
	)
	
	fn upgradeFiltering = 
	(
		setSuperExpertMode on
		for m in getclassinstances vrayHDRI do 
		(
			m.filterMode = 1
		)
		setSuperExpertMode off
	)
	
	rollout vrayShaderDeckRoll "V-Ray Shader Deck v0.01" width:160 height:168
	(
		button 'btn1' "Upgrade BRDFs" pos:[8,8] width:144 height:32 toolTip:"Turns to GGX, Enables Glossy Fresnel" align:#left
		button 'btn2' "Upgrade Bumps" pos:[8,48] width:144 height:32 toolTip:"Turns Bump into VRayColor2Bump" align:#left
		button 'btn3' "Upgrade Opacity Mode and CutOffs" pos:[8,88] width:144 height:32 toolTip:"Sets opacity to Stochastic, shader cutoff to 0.001, turns on Fog Unit Scaling." align:#left
		button 'btn4' "Upgrade Bitmap Filtering (VRayHDRI Only)" pos:[8,128] width:144 height:32 toolTip:"Sets filtering to Elliptical for VRayHDRI maps. Use the standard HDRI Converter to turn your maps to VRayHDRIs." align:#left
	
		on btn1 pressed do
		(
			upgradeBRDFs()
		)
		
		on btn2 pressed do
		(
			upgradeBumps()
		)
		
		on btn3 pressed do
		(
			upgradeOpacity()
		)	
		
		on btn4 pressed do
		(
			upgradeFiltering()
		)		
	)
	
	
	createdialog vrayShaderDeckRoll
)

