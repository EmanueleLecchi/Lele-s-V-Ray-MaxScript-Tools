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
		with redraw off
		(
			setSuperExpertMode on
			for m in (getclassinstances VrayMtl) do
			(
				m.brdf_type = 4
				m.option_glossyFresnel = true
			)
			setSuperExpertMode off
		)
	)
	
	fn upgradeOpacity =
	(
		with redraw off
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
	)

	fn upgradeVRayLightMtls = 
	(
		with redraw off
		(
			setSuperExpertMode on
			for m in getclassinstances vrayLightMtl do 
			(
				m.directLight_on = true
			)
			setSuperExpertMode off
		)
	)
	
	fn upgradeFiltering = 
	(
		with redraw off
		(
			setSuperExpertMode on
			for m in getclassinstances vrayHDRI do 
			(
				m.filterMode = 1
			)
			setSuperExpertMode off
		)
	)

	fn upgradeBumps = 
	(
		with redraw off
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
	)
	
	fn fixDirts = 
	(
		with redraw off
		(
			setSuperExpertMode on
			for m in getclassinstances vrayDirt do 
			(
				m.subdivs = 3
			)
			setSuperExpertMode off
		)
	)	

	fn resetVrayLights = 
	(
		with redraw off
		(
			setSuperExpertMode on
			for m in getclassinstances vrayLight do 
			(
				m.affect_diffuse = on
				m.diffuse_contribution = 1.0
				m.affect_specualr = on
				m.specular_contribution = 1.0
				m.affect_reflections = on
			)
			setSuperExpertMode off
		)		
	)
	
	fn upgradeSunSky = 
	(
		with redraw off
		(
			setSuperExpertMode on
			for m in getclassinstances vraySun do 
			(
				m.intensity_multiplier=1.0
				m.invisible=true
				m.affect_diffuse = on
				m.diffuse_contribution = 1.0
				m.affect_specualr = on
				m.specular_contribution = 1.0
				m.sky_model=3
			)
			for m in (getclassinstances vraysky) where m.manual_sun_node do
			(
				m.sun_intensity_multiplier = 1.0
				m.sun_invisible=true
				m.sky_model=3
			)
			setSuperExpertMode off
		)		
	)	

	rollout vrayShaderDeckRoll "V-Ray Toolset Deck v0.02" width:480 height:200
	(
		GroupBox 'grp1' "Shaders" pos:[8,8] width:464 height:56 align:#left
		button 'btn1' "Upgrade BRDFs" pos:[16,24] width:144 height:32 toolTip:"Turns to GGX, Enables Glossy Fresnel" align:#left
		button 'btn2' "Upgrade Opacity Mode and CutOffs" pos:[168,24] width:144 height:32 toolTip:"Sets opacity to Stochastic, shader cutoff to 0.001, turns on Fog Unit Scaling." align:#left
		button 'btn3' "Make VRayLightMtls emit Direct Light" pos:[320,24] width:144 height:32 toolTip:"Coupled with Adaptive Lights, allows for superior quality and speed." align:#left
	
		GroupBox 'grp2' "Maps" pos:[8,72] width:464 height:56 align:#left
		button 'btn4' "Upgrade Bitmap Filtering (VRayHDRI Only)" pos:[16,88] width:144 height:32 toolTip:"Sets filtering to Elliptical for VRayHDRI maps.\n\nUse the standard HDRI Converter to turn your maps to VRayHDRIs." align:#left
		button 'btn5' "Upgrade Bumps" pos:[168,88] width:144 height:32 toolTip:"Turns Bump into VRayColor2Bump, attempting a conversion.\n\nDouble Check the results." align:#left
		button 'btn6' "Fix V-Ray Dirts" pos:[320,88] width:144 height:32 toolTip:"Fixes Sampling for VRayDirt Maps" align:#left

		
		GroupBox 'grp5' "Lights and Light Materials" pos:[8,136] width:464 height:56 align:#left
		button 'btn7' "Reset V-Ray Lights' Influences" pos:[16,152] width:144 height:32 toolTip:"Resets all V-Ray Lights' Diffuse, Specular and Reflection influence." align:#left
		button 'btn8' "Upgrade Sun and Sky" pos:[168,152] width:144 height:32 toolTip:"Ensures the sun isn't set to visible, resets contributions, and sets the sky model is Hosek.\n\nColors WILL change." align:#left
		button 'btn9' "ToDo: Add REs" pos:[320,152] width:144 height:32 toolTip:"Temporary Placeholder" align:#left
		
		on btn1 pressed do
		(
			upgradeBRDFs()
		)
		on btn2 pressed do
		(
			upgradeOpacity()
		)
		on btn3 pressed do
		(
			upgradeVRayLightMtls()
		)
		
		on btn4 pressed do
		(
			upgradeFiltering()
		)
		on btn5 pressed do
		(
			upgradeBumps()
		)
		on btn6 pressed do
		(
			fixDirts()
		)
		on btn7 pressed do
		(
			resetVrayLights()
		)
		on btn3 pressed do
		(
			upgradeBumps()
		)
		on btn8 pressed do
		(
			upgradeSunSky()
		)
		on btn9 pressed do
		(
			
		)
	)
	
	
	createdialog vrayShaderDeckRoll
	
	
	
)

