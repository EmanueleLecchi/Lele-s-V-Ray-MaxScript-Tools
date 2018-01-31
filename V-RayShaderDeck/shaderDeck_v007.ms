(
	global vrayToolsetDeckRoll
	try (destroydialog vrayToolsetDeckRoll) catch()
	
	local SEModeOn=false
	local timeSliderWasVisible=undefined
	local trackBarWasVisible=undefined
	local statusPanelWasVisible=undefined
	local expertModeWasActive=undefined
	local matEditorWasOpen=undefined


	fn resetUIStatus = 
	(
		timeSliderWasVisible=undefined
		trackBarWasVisible=undefined
		statusPanelWasVisible=undefined
		expertModeWasActive=undefined
		matEditorWasOpen=undefined		
	)
	
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
	
	fn upgradeBRDFs doBoosted =
	(
		if doBoosted then
		(
			with undo off
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
		)
		else
		(
			for m in (getclassinstances VrayMtl) do
			(
				m.brdf_type = 4
				m.option_glossyFresnel = true
			)
		)
	)
	
	fn upgradeOpacity doBoosted=
	(
		if doBoosted then
		(
			with undo off
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
		)
		else
		(
			for m in (getclassinstances VrayMtl) do
			(
				m.option_opacityMode = 2
				m.option_cutOff = 0.001
				m.refraction_fogUnitsScale_on = on
			)	
		)
	)

	fn upgradeVRayLightMtls doBoosted= 
	(
		if doBoosted then
		(
			with undo off
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
		)
		else
		(
			for m in getclassinstances vrayLightMtl do 
			(
				m.directLight_on = true
			)
		)
	)
	
	fn upgradeFiltering doBoosted= 
	(
		if doBoosted then
		(
			with undo off
			(
				with redraw off
				(
					setSuperExpertMode on
					for m in getclassinstances vrayHDRI do 
					(
						m.filterMode = 1
						m.coords.blur = 1.0
						m.color_space = 2
					)
					setSuperExpertMode off
				)
			)
		)
		else
		(
			for m in getclassinstances vrayHDRI do 
			(
				m.filterMode = 1
				m.coords.blur = 1.0
				m.color_space = 2
			)
		)
	)

	fn upgradeBumps doBoosted= 
	(
		if doBoosted then
		(
			with undo off
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
		)
		else
		(
			for m in (getclassinstances VrayMtl) where (m.texmap_bump != undefined and (classof m.texmap_bump) != vrayColor2Bump and m.texmap_bump_on ) do
			(
				theTex=vrayColor2Bump map:m.texmap_bump height:(m.texmap_bump_multiplier/100.0)
				m.texmap_bump = theTex
				m.texmap_bump_multiplier = 100
			)	
		)
	)
	
	fn fixDirts doBoosted= 
	(
		if doBoosted then
		(
			with undo off
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
		)
		else
		(
			for m in getclassinstances vrayDirt do 
			(
				m.subdivs = 3
			)			
		)
	)	

	fn resetVrayLights doBoosted= 
	(
		if doBoosted then
		(
			with undo off
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
		)
		else
		(
			for m in getclassinstances vrayLight do 
			(
				m.affect_diffuse = on
				m.diffuse_contribution = 1.0
				m.affect_specualr = on
				m.specular_contribution = 1.0
				m.affect_reflections = on
			)
		)
	)
	
	fn upgradeSunSky doBoosted= 
	(
		if doBoosted then
		(
			with undo off
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
		)
		else
		(
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
		)
	)	

	fn addREs doBoosted doExtended doWipe=
		(
			re = maxOps.GetCurRenderElementMgr()
			elemList=#()
			elemNamesList=#()
			if doWipe do re.RemoveAllRenderElements() 
			if doExtended then 
			(
				elemList = #( VraySampleRate, VrayNoiseLevel, VrayRenderTime, VrayDiffuseFilter, VrayGlobalIllumination, VrayLighting, VrayNoiseLevel, VrayReflection, VrayRefraction, VraySpecular, VrayTotalLighting, VraySSS2, VrayAtmosphere)
				elemNamesList = #( "VraySampleRate", "VrayNoiseLevel", "VrayRenderTime", "VrayDiffuseFilter", "VrayGlobalIllumination", "VrayLighting", "VrayNoiseLevel", "VrayReflection", "VrayRefraction", "VraySpecular", "VrayTotalLighting", "VraySSS2", "VrayAtmosphere")			
			)
			else
			(
				elemList = #( VrayDenoiser,VraySampleRate)
				elemNamesList = #("VrayDenoiser",  "VRaySampleRate")
			)
			if doBoosted then
			(
				with undo off
				(
					with redraw off
					(
						for r=1 to elemList.count do 
						(
							theElement = elemList[r] elementName:elemNamesList[r]
							if elemList[r]==VrayDenoiser do theElement.mode = 0
							re.AddRenderElement theElement								
						)
					)
				)
			)
			else
			(
				for r=1 to elemList.count do 
				(
					theElement = elemList[r] elementName:elemNamesList[r]
					if elemList[r]==VrayDenoiser do theElement.mode = 0					
					re.AddRenderElement theElement
				)
			)
		)

		
	rollout vrayToolsetDeckRoll "V-Ray Toolset Deck v0.07" width:480 height:220
	(
		GroupBox 'grp1' "Shaders" pos:[8,8] width:464 height:56 align:#left
		button 'btn1' "Upgrade BRDFs" pos:[16,24] width:144 height:32 toolTip:"Turns to GGX, Enables Glossy Fresnel" align:#left
		button 'btn2' "Upgrade Opacity Mode and CutOffs" pos:[168,24] width:144 height:32 toolTip:"Sets opacity to Stochastic, shader cutoff to 0.001, turns on Fog Unit Scaling." align:#left
		button 'btn3' "Make VRayLightMtls emit Direct Light" pos:[320,24] width:144 height:32 toolTip:"Coupled with Adaptive Lights, allows for superior quality and speed." align:#left
	
		GroupBox 'grp2' "Maps" pos:[8,72] width:464 height:56 align:#left
		button 'btn4' "Upgrade Bitmap Filtering (VRayHDRI Only)" pos:[16,88] width:144 height:32 toolTip:"Sets filtering to Elliptical for VRayHDRI maps, and returns filtering blur to 1.0.\n\nUse the standard HDRI Converter to turn your maps to VRayHDRIs." align:#left
		button 'btn5' "Upgrade Bumps" pos:[168,88] width:144 height:32 toolTip:"Turns Bump into VRayColor2Bump, attempting a conversion.\n\nDouble Check the results." align:#left
		button 'btn6' "Fix V-Ray Dirts" pos:[320,88] width:144 height:32 toolTip:"Fixes Sampling for VRayDirt Maps" align:#left

		
		GroupBox 'grp5' "Lights and Render Elements" pos:[8,136] width:464 height:56 align:#left
		button 'btn7' "Reset V-Ray Lights' Influences" pos:[16,152] width:144 height:32 toolTip:"Resets all V-Ray Lights' Diffuse, Specular and Reflection influence." align:#left
		button 'btn8' "Upgrade Sun and Sky" pos:[168,152] width:144 height:32 toolTip:"Ensures the sun isn't set to visible, resets contributions, and sets the sky model is Hosek.\n\nColors WILL change." align:#left
		button 'btn9' "Add Denoiser and SampleRate REs" pos:[320,152] width:144 height:32 toolTip:"Adds a Denoiser RE in passthrough mode, so to generate the relevant beauty and data REs, which coupled with the SampleRate should help the debugging of a scene.\nRunning it multiple times will keep adding the two REs.\n\nPressing SHIFT will create a different set of REs useful for image analysis.\n\nPressing ALT will also delete any previous RE in the list." align:#left
		checkbutton 'ckb1' "Toggle Super Expert Mode" pos:[16,200] width:448 height:16 toolTip:"Toggles the leanest possible Max UI, to squeeze all possible performance out of long operations." align:#left
		
		on btn1 pressed do
		(
			upgradeBRDFs (keyboard.controlPressed)
			
		)
		on btn2 pressed do
		(
			upgradeOpacity (keyboard.controlPressed)
		)
		on btn3 pressed do
		(
			upgradeVRayLightMtls (keyboard.controlPressed)
		)
		
		on btn4 pressed do
		(
			upgradeFiltering (keyboard.controlPressed)
		)
		on btn5 pressed do
		(
			upgradeBumps (keyboard.controlPressed)
		)
		on btn6 pressed do
		(
			fixDirts (keyboard.controlPressed)
		)
		on btn7 pressed do
		(
			resetVrayLights (keyboard.controlPressed)
		)
		on btn3 pressed do
		(
			upgradeBumps (keyboard.controlPressed)
		)
		on btn8 pressed do
		(
			upgradeSunSky (keyboard.controlPressed)
		)
		on btn9 pressed do
		(
			addREs (keyboard.controlPressed) (keyboard.shiftPressed) (keyboard.altPressed)
		)
		on ckb1 changed state do
		(
			setSuperExpertMode state
			if state then ckb1.text="Super Expert Mode Active!" else ckb1.text= "Toggle Super Expert Mode"
			if keyboard.controlPressed do --force UI state variables reset, hence the mode toggle returns the UI to the factory state regardless
			(
				resetUIStatus()
				setSuperExpertMode false
				ckb1.checked=false
			)
		)
		-- set expert mode off on close, to avoid getting visibility states stuck in between script runs
		on vrayToolsetDeckRoll close do setSuperExpertMode false
	)
	
	createdialog vrayToolsetDeckRoll
	
)

