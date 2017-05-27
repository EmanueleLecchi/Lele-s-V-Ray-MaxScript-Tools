(
	--"Vray 3 SP3 Quick Settings"
	global VRaySp3QuickSettingsRoll
	try (destroydialog VRaySp3QuickSettingsRoll) catch()
	local cr= renderers.current
	
	fn resetVray = 
	(
	if	(queryBox "Resetting V-Ray Settings to SP3 Defaults.\nMake sure you saved a V-Ray preset to restore parts of the settings you may need.\nContinue?") then 
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
		else 
		(
			messagebox "Don't blame ME if i don't do what you want me to!"
		)
	)
	
	
	rollout VRaySp3QuickSettingsRoll "Vray 3 SP3 Quick Settings V. 0.01" width:460 height:104
	(
		button 'btn1' "Reset Settings" pos:[8,8] width:(460-16) height:32 align:#left
		slider 'sld1' "" pos:[8,64] width:360 height:18 range:[45,0,5.73918] ticks:2 align:#left
		label 'lbl1' "Low Quality" pos:[8,48] width:56 height:16 align:#left
		label 'lbl2' "High Quality" pos:[300,48] width:64 height:16 align:#left
		GroupBox 'grp1' "N.T.:" pos:[368,56] width:80 height:32 align:#left
		label 'lbl3' "0.001" pos:[376,70] width:64 height:16 align:#left
	
		fn refresh = 
		(
-- 			(sin 5.73918)^2
			NT= (sin sld1.value)^2
			renderers.current.twoLevel_threshold = renderers.current.progressive_noise_threshold = NT
			lbl3.text = renderers.current.twoLevel_threshold as string
		)
		

		
		on VRaySp3QuickSettingsRoll open do
		(
			refresh()
		)
		on btn1 pressed do
		(
			resetVray()
			refresh()
		)
		on sld1 changed val do
		(
			refresh()
			print val
		)
	)
	
	createdialog VRaySp3QuickSettingsRoll
)