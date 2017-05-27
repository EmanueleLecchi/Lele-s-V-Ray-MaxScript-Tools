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
	
	
	rollout VRaySp3QuickSettingsRoll "Vray 3 SP3 Quick Settings V. 0.04" width:456 height:152
	(
		button 'btn1' "Reset Settings" pos:[10,10] width:440 height:32 toolTip:"NOT Optional.\nPress the CTRL Key to execute without warning dialogs." align:#left
		label 'lbl4' "AA Type" pos:[16,48] width:56 height:16 align:#left
		dropdownList 'ddl1' "" pos:[16,64] width:92 height:21 items:#("Adaptive (Buckets)", "Progressive (Whole Image)") selection:2 align:#left
		label 'lbl5' "Internal Color Space" pos:[120,48] width:104 height:16 align:#left
		dropdownList 'ddl2' "" pos:[120,64] width:104 height:21 items:#("XYZ (Old)", "sRGB (New)") selection:2 align:#left		
		slider 'sld1' "" pos:[16,112] width:344 height:25 range:[1,0,0.215443] ticks:10 toolTip:"One slider to rule them all.\nClick once and use the cursor keys to fine tune.\nRight-mouse Click to return to defaults." align:#left
		label 'lbl1' "Low Quality" pos:[24,88] width:56 height:16 align:#left
		label 'lbl2' "High Quality" pos:[296,88] width:64 height:16 align:#left
		GroupBox 'grp1' "N.T.:" pos:[364,96] width:64 height:32 toolTip:"The resulting noise threshold." align:#left
		label 'lbl3' "WRONG!" pos:[372,110] width:54 height:16 align:#left 
 
 
		
		progressBar 'pb3' "ProgressBar" pos:[0,-1] width:460 height:9 value:100 color:(color 30 10 190) align:#left  	--top
		progressBar 'pb4' "ProgressBar" pos:[452,0] width:8 height:152 value:100 color:(color 30 10 190) align:#left  	--right
		progressBar 'pb5' "ProgressBar" pos:[0,0] width:8 height:152 value:100 color:(color 30 10 190) align:#left		--left
		progressBar 'pb2' "ProgressBar" pos:[0,144] width:460 height:10 value:100 color:(color 30 10 190) align:#left	--bottom
		
		fn refresh = 
		(
			renderers.current.options_rgbColorSpace=ddl2.selection-1
			NT= sld1.value^3
			renderers.current.twoLevel_threshold = renderers.current.progressive_noise_threshold = NT
			if ddl1.selection==1 then renderers.current.imageSampler_type=1
			else renderers.current.imageSampler_type=3
			lbl3.text = formattedPrint renderers.current.twoLevel_threshold format:"1.6f"
			c1=red
			c2=green
			c3= c2*(1-sld1.value)+c1*(sld1.value)
			pb2.color=pb3.color=pb4.color=pb5.color=c3
			renderSceneDialog.commit()
			
			if NT==0.0 do
			(
				for p = 1 to 3 do
				(
					for i = 0 to 500 do
					(
						c3= c2*(1-(i/500.0))+c1*(i/500.0)
						pb2.color=pb3.color=pb4.color=pb5.color=c3
					)
					for i = 500 to 0 by -1 do
					(
						c3= c2*(1-(i/500.0))+c1*(i/500.0)
						pb2.color=pb3.color=pb4.color=pb5.color=c3
					)	
				)				
			)
			
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
		on ddl2 selected i do
		(
			refresh()
		)
		on sld1 changed val do
		(
			refresh()
		)
		on sld1 rightClick do
		(
			sld1.value = 0.21544346900318837217592935665194
			refresh()
		)

	)
	
	createdialog VRaySp3QuickSettingsRoll
)