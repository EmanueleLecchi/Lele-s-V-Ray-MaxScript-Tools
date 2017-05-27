(
	--"Vray 3 SP3 Quick Settings"
	global VRaySp3QuickSettingsRoll
	try (destroydialog VRaySp3QuickSettingsRoll) catch()
	local cr= renderers.current
	
	fn resetVray = 
	(
		wasOpen = renderSceneDialog.isOpen()
		if wasOpen do renderSceneDialog.close()
		macros.run "Render" "RenderButtonMenu_Switch_To_Production_Mode"
		renderers.current = (for i in RendererClass.classes where matchPattern (i as string) pattern:"Default_Scanline_Renderer" do exit with i()) 
		renderers.current = (for i in RendererClass.classes where matchPattern (i as string) pattern:"V_Ray_Adv*" do exit with i())	
		/*Small Default Adjustments*/
		cr=renderers.current
		cr.progressive_max_render_time = 0
		cr.twoLevel_fineSubdivs = 100
		cr.twoLevel_threshold= 0.005
		renderSceneDialog.commit()
		if wasOpen do renderSceneDialog.open()
	)
	
	
	rollout VRaySp3QuickSettingsRoll "Vray 3 SP3 Quick Settings V. 0.02 - Has Tooltips" width:460 height:104
	(
		button 'btn1' "Reset Settings" pos:[8,8] width:444 height:32 align:#left tooltip:"NOT Optional.\nPress the CTRL Key to execute without warning dialogs."
-- 		slider 'sld1' "" pos:[8,64] width:360 height:18 range:[52.5327,0,12.44156] ticks:10 align:#left tooltip:"One slider to rule them all.\nRight-mouse Click to return to defaults."
		label 'lbl4' "AA Type" pos:[8,48] width:56 height:16 align:#left
		dropdownlist 'ddl1' pos:[8,72] width:92 items:#("Adaptive (Buckets)", "Progressive (Whole Image)")
		slider 'sld1' "" pos:[128,64] width:232 height:18 range:[1,0,0.21544346900318837217592935665194] ticks:10 align:#left tooltip:"One slider to rule them all.\nClick once and use the cursor keys to fine tune.\nRight-mouse Click to return to defaults."
		label 'lbl1' "Low Quality" pos:[128,48] width:56 height:16 align:#left
		label 'lbl2' "High Quality" pos:[300,48] width:64 height:16 align:#left
		GroupBox 'grp1' "N.T.:" pos:[368,56] width:84 height:32 align:#left tooltip:"The resulting noise threshold."
		label 'lbl3' "WRONG!" pos:[376,70] width:68 height:16 align:#left 
	
		
		fn refresh = 
		(
-- 			formattedPrint ( (sin 52.5327)^3 ) format:"1.18f"
			NT= sld1.value^3
			renderers.current.twoLevel_threshold = renderers.current.progressive_noise_threshold = NT
			if ddl1.selection==1 then renderers.current.imageSampler_type=1
			else renderers.current.imageSampler_type=3

			lbl3.text = formattedPrint renderers.current.twoLevel_threshold format:"1.6f"
			renderSceneDialog.commit()
-- 			print NT
		)


		
		on VRaySp3QuickSettingsRoll open do
		(
			refresh()
		)
		
		on btn1 pressed do
		(
			if keyboard.controlPressed then -- direct mode, no questions asked
			(
				resetVray()
				refresh()
			)
			else 							--ask questions
			(
				if	(queryBox "Resetting V-Ray Settings to SP3 Defaults.\nMake sure you saved a V-Ray preset to restore parts of the settings you may need.\nContinue?") then 
				(
					resetVray()
					refresh()
				)
				else 
				(
					messagebox "Don't blame ME if i don't do what you want me to!"
				)
			)
		)
		
		on ddl1 selected i do
		(
			refresh()
		)
		on sld1 changed val do
		(
			refresh()
-- 			print val
		)
		
		on sld1 rightclick do 
		(
			sld1.value = 0.21544346900318837217592935665194
			refresh()
		)
		
	)
	
	createdialog VRaySp3QuickSettingsRoll
)