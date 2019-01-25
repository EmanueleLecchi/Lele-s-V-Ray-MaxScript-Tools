(
	/*
	"Simple" scene converter from V-Ray to Arnold
	Lights: they should all be translatable, minus perhaps a few inferred properties (f.e. exposure in A's).
	Materials: Translate to PhysicalMaterial.
	Maps: most should be directly pluggable at the root. This may turn out to be the most laborious part, however.
	*/
	
	/*
	Addendum for v004+
	Lights: 
		*) Spherical could be created as mesh light and an implicit sphere (@ the origin, hide.) // V004 Done with sphere, and changed later to point with a radius > 0.
		*) Omni, spot and parallel need conversion from Max's own. //v 004 done.
	Materials:
		*) The Physical Material doesn't allow for caustics, and roughness is one instead of two parameters, making it unsuited  for most cases with refractive components. //v004 done. 
			for m in allMats do convertVrayMtl m TRUE 
			inside fn convertAllSceneMaterials
		*) The binary blend is now superseded by an eight layer shader. convert to that //v004 done. up to 8 layers, in BLEND mode use the layered shader. above 8, or additive, use the binary method
	Exposure: 
		*) I still have no clue as to why it's misbehaving intermittently. Need to work on it more.
	*/

	local allMats = #()
	local leftOverMats = #()
	local allLights = #()
	local lightsToDelete = #()
	local leftOverLights = #()
	local allCameras  = #()
	local leftOverCameras = #()
	local allProxies = #()
	local leftOverProxies = #()
	local allMaps = #()
	local leftOverMaps = #()
	local allSkies = #()
	local leftOverSkies = #()
	
	local maxRefractionDepth = 0
	local maxReflectionDepth = 0
	local maxDiffuseDepth = 0
	
	local useADMaterials = false
	local ArnoldRenderer = undefined
	
	local isAISky = false
	
	local SEModeOn=false
	local timeSliderWasVisible=undefined
	local trackBarWasVisible=undefined
	local statusPanelWasVisible=undefined
	local expertModeWasActive=undefined
	local matEditorWasOpen=undefined

-- 	show (VrayMtl())
	
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
	
	
	
	
	fn itsVray input =
	(
		matchpattern (input as string) pattern:"V_Ray_N*"
	)
	
	fn bakeMapInfluence inMap influenceAmt baseColor=
	(
		if inMap != undefined then
		(
			if  influenceAmt==100.0 then 
			(
				outMap = inMap 
			)
			else
			(
				multA=output map1:inMap 
				multA.output.output_amount=(influenceAmt/100.0)
				multB=VrayColor color:baseColor rgb_multiplier:(1.0-(influenceAmt/100.0))
				outMap = vrayCompTex sourceA:multA sourceB:multB
			)	
		)
		else
		(
			outMap=undefined
		)
		outMap
	)	
	
	fn convertVRayMap vM =
	(
		case (classOf vM) of
		(
			vrayDirt : 
			(
				aM = ai_ambient_occlusion name:(uniqueName (vM.name+"_Converted_")) 
				aM.white = vM.unoccluded_color
				aM.black = vM.occluded_color
				aM.spread = vM.distribution --i highly doubt it!
				aM.falloff = vM.falloff --not without a remap, i am sure!
				aM.samples = 2
				aM.near_clip = 0.0 --we don't have one!
				aM.far_Clip = vM.radius
				aM.normal = vM.bias
				aM.invert_normals = vM.invert_normal
				aM.self_only = vM.consider_same_object_only
				
				if vM.texmap_radius != undefined do aM.far_clip_shader = bakeMapInfluence vM.texmap_radius vM.texmap_radius_multiplier (vrayColor color:white rgb_Multiplier:vM.radius)
				if vM.texmap_occluded_color != undefined do aM.black_shader = bakeMapInfluence vM.texmap_occluded_color vM.texmap_occluded_color_multiplier vM.occluded_color
				if vM.texmap_unoccluded_color != undefined do aM.white_shader = bakeMapInfluence vM.texmap_unoccluded_color vM.texmap_unoccluded_color_multiplier vM.unoccluded_color
					
				replaceInstances vM aM
			)
			default :
			(
				append leftOverMaps vM
			)
		)
	)
	
	fn convertVRaySky VRS =
	(
		--The AD Physical Sky allows for the implementation of the Preetham model,
		--while the Arnold Sky implements a Hosek one.
		--I see no way to convert the CIE models.
		local aSky=undefined
-- 		print VRS
		case VRS.manual_sun_node of
		(
			on : --Manually specified sun node: settings transfer from the map itself
			(
-- 				print "Manually specified sun node"
-- 				print ("sun node: " + VRS.sun_node as string)
				case VRS.sky_model of
				(
					0 : --Preetham
					(
-- 						print "preetham"
						aSky = Physical_Sun___Sky_Environment name:(uniquename(VRS.name + "_Converted_")) illuminance_model:1
						isAISky = false	--to be used later to conveniently switch code paths
					)
					3 :	--Hosek
					(
-- 						print "hosek"
						aSky = ai_physical_sky name:(uniquename(VRS.name + "_Converted_")) use_degrees:true enable_sun:true
						isAISky = true
					)
					default : --CIE models: how to?
					(
						
					)
				)
				
				if VRS.sun_node == undefined then --no node specified. Sunless Sky
				(
-- 					print "NO sun node specified"
					if isAiSky then
					(
						aSky.enable_sun = false
					)
					else
					(
						aSky.sun_position_object = undefined
					)
				)
				else --sun node specified, create a sky locator widget for the Autodesk Map, simply paste the direction values for the Arnold one.
				(
					print "Sun node specified"
					if isAISky then
					(
						print "here"
						ASky.azimuth = acos VRS.sun_node.dir[1]
						ASky.elevation = acos VRS.sun_node.dir[3]
-- 						aSky.sun_direction = VRS.sun_node.dir
					)
					else
					(
						VRSun=VRS.sun_node
						ASun = Sun_Positioner name:(ASky.name+"_SunPositioner") --no need for a uniqueName, as the sky only supports one locator, and its name was already unique
						try (ASun.parent = VRSun.parent) catch()
						try (ASun.position=VRSun.target.position) catch (ASun.position=VRSun.position) --DON'T ASK...
						ASun.mode=0
						print "manual sun positioning"
						ASun.manual_sun_position = VRSun.position
						ASky.sun_position_object = aSun
					)
				)
				--Now copy all the relevant properties over from the sky MAP
				--isAISky determines the code path for Preetham or Hosek, going towards one or the other sky map type.
				if isAISky then --Hosek Model, Arnold Physical Sky
				(
					aSky.turbidity = VRS.sun_turbidity
					aSky.intensity = VRS.sun_intensity_multiplier * 150.0 -- arbitrary measured multiplier.
					aSky.ground_albedo = VRS.ground_albedo
					aSky.sun_size = VRS.sun_size_multiplier
					aSky.sun_tint = VRS.sun_filter_color
				)
				else --Pretham model, AD map
				(
					aSky.global_intensity = VRS.sun_intensity_multiplier
					aSky.ground_color = VRS.ground_albedo
					aSky.sun_disc_scale = VRS.sun_size_multiplier
					aSky.tint = VRS.sun_filter_color
					--The model shows no other parameter that can be copied across.
				)
			)
			off : --implicit Sun node: collect all suns, pick the first? Settings on the sun itself
			(
				print "Implicit Sun Node"
				VRSun = (for l in lights where (classOf l == vraySun) collect l)[1]
				if VRSun != undefined then
				(
					print "Sun node Found"
					case VRSun.sky_model of
					(
						0 : --Preetham
						(
							print "Preetham"
							ASky = Physical_Sun___Sky_Environment name:(uniquename(VRS.name + "_Converted_")) illuminance_model:1
							isAISky = false
							--create and assign sun widget
							ASun = Sun_Positioner name:(ASky.name+"_SunPositioner") --no need for a uniqueName, as the sky only supports one locator, and its name was already unique
							try (ASun.parent = VRSun.parent) catch()
							try (ASun.position=VRSun.target.position) catch (ASun.position=VRSun.position) --DON'T ASK...
							ASun.mode=0
							ASun.manual_sun_position = VRSun.position
							ASky.sun_position_object = ASun
						)
						3 :	--Hosek
						(
							print "Hosek"
							ASky = ai_physical_sky name:(uniquename(VRS.name + "_Converted_")) use_degrees:on 
							isAISky = true
							print "there"
							ASky.azimuth = acos VRSun.dir[2]
							ASky.elevation = acos VRSun.dir[1]
-- 							ASky.sun_direction=VRSun.dir
						)
						default : --CIE models: how to?
						(
							
						)
					)	
					
					
					--Now copy all the relevant properties over from the SUN
					--isAISky determines the code path for Preetham or Hosek, going towards one or the other sky map type.
					if isAISky then --Hosek Model, Arnold Physical Sky
					(
						aSky.turbidity = VRSun.turbidity
						aSky.intensity = VRSun.intensity_multiplier * 150.0
						aSky.ground_albedo = VRSun.ground_albedo
						aSky.sun_size = 0.51*VRSun.size_multiplier
						aSky.sun_tint = VRSun.filter_color
					)
					else --Pretham model, AD map
					(
						aSky.global_intensity = VRSun.intensity_multiplier
						aSky.ground_color = VRSun.ground_albedo
						aSky.sun_disc_scale = VRSun.size_multiplier
						aSky.tint = VRSun.filter_color
						--The model shows no other parameter that can be copied across.
					)
				)
				else --this ought to be an odd one, as there is no VRaySun in the scene and a custom sun locator isn't specidifed in the map. It's a Hosek model by default. Arnold map with sun off.
				(
					aSky = ai_physical_sky name:(uniquename(VRS.name + "_Converted_")) enable_sun:false
					isAISky = true
					--settings taken from the MAP, ofc.
					--Now copy all the relevant properties over from the sky MAP
					aSky.turbidity = VRS.sun_turbidity
					aSky.intensity = VRS.sun_intensity_multiplier * 150.0
					aSky.ground_albedo = VRS.ground_albedo
					aSky.sun_size = 0.51*VRS.sun_size_multiplier
					aSky.sun_tint = VRS.sun_filter_color
				)
			)
		)
		try (delete VRSun) catch ()		
		try (delete VRS.sun_node) catch ()
		try (replaceInstances VRS ASky) catch (append leftOverSkies VRS)
		if isAiSky do 
		( 
			try (environmentMap = ASky) --force this so that it doesn't break 
			catch ()
		)
		
	)

	fn convertBlend vM matA matB =  
	(
		aM=ai_mix_shader name:(uniquename(vM.name+"_Converted_"))
		aM.mode=vM.additiveMode
		aM.shader1 = matA[2]
		aM.shader2 = matB[2]
		if matB[4]!= undefined then 
		(
			if  matB[5]==100.0 then 
			(
				aM.Mix_shader = matB[4] 
			)
			else
			(
				multA=output map1:matB[4] 
				multA.output.output_amount=(matB[5]/100.0)
				multB=VrayColor color:matB[3] rgb_multiplier:(1.0-(matB[5]/100.0))
				aM.Mix_shader = vrayCompTex sourceA:multA sourceB:multB
			)
		)
		else 
		(
			aM.Mix_shader = VrayColor color:matB[3]
		)
		aM
	)
	
	fn convert8Layers vM matsArray=
	(
		aM=ai_layer_shader name:(uniquename(vM.name+"_Converted_"))
		--I wish i could do this procedurally, alas i can't as i'd have to execute() material names which may lead to a number of unintended consequences.
		--for lack of ideas, i'll list each layer and treat them as the ought to.
		if matsArray[1] != undefined do
		(
			aM.enable1=matsArray[1][1]
			aM.input1=matsArray[1][2]
			aM.mix1_shader = bakeMapInfluence matsArray[1][4] matsArray[1][5] matsArray[1][3]
			aM.mix1=1.0
		)
		if matsArray[2] != undefined do
		(
			aM.enable2=matsArray[2][1]
			aM.input2=matsArray[2][2]
			aM.mix2_shader = bakeMapInfluence matsArray[2][4] matsArray[2][5] matsArray[2][3]
			aM.mix2=1.0
		)
		if matsArray[3] != undefined do
		(
			aM.enable3=matsArray[3][1]
			aM.input3=matsArray[3][2]
			aM.mix3_shader = bakeMapInfluence matsArray[3][4] matsArray[3][5] matsArray[3][3]
			aM.mix3=1.0
		)
		if matsArray[4] != undefined do
		(
			aM.enable4=matsArray[4][1]
			aM.input4=matsArray[4][2]
			aM.mix4_shader = bakeMapInfluence matsArray[4][4] matsArray[4][5] matsArray[4][3]
			aM.mix4=1.0
		)
		if matsArray[5] != undefined do
		(
			aM.enable5=matsArray[5][1]
			aM.input5=matsArray[5][2]
			aM.mix5_shader = bakeMapInfluence matsArray[5][4] matsArray[5][5] matsArray[5][3]
			aM.mix5=1.0
		)
		if matsArray[6] != undefined do
		(
			aM.enable6=matsArray[6][1]
			aM.input6=matsArray[6][2]
			aM.mix6_shader = bakeMapInfluence matsArray[6][4] matsArray[6][5] matsArray[6][3]
			aM.mix6=1.0
		)
		if matsArray[7] != undefined do
		(
			aM.enable7=matsArray[7][1]
			aM.input7=matsArray[7][2]
			aM.mix7_shader = bakeMapInfluence matsArray[7][4] matsArray[7][5] matsArray[7][3]
			aM.mix7=1.0
		)
		if matsArray[8] != undefined do
		(
			aM.enable8=matsArray[8][1]
			aM.input8=matsArray[8][2]
			aM.mix8_shader = bakeMapInfluence matsArray[8][4] matsArray[8][5] matsArray[8][3]
			aM.mix8=1.0
		)
		aM
	)

	fn convertVrayMtl parentMat useADMaterials=
	(
		/*
		No need to convert MultiSub mtl
		Convert VrayMtl to PhysicalMaterial
		Blend Materials: Arnold's mix shader only has 2 entries. Will need parsing the VrayBlend and ensure i make enough nested mix shaders in arnold.
		*/
-- 		print parentMat
		if superClassOf parentMat==material do
		(
			-- if it has  two IoRs use the arnold path
			if (classOf parentMat == vrayMtl and (parentMat.reflection != black or parentMat.texmap_reflection != undefined) and not parentMat.reflection_lockIOR) do 
			(
-- 				print "unlocked IoRs"
				useADMaterials = false
			)			
			--But if if there is a bump map, we cannot convert to Arnold Surface, use the AD path and Physical Material instead		
			if (isproperty parentMat "texmap_bump") and parentMat.texmap_bump != undefined do 
			(
				
				useADMaterials = true
-- 				print ("Bump map detected in " + parentMat.name + ": forcing conversion to Physical")
			)
			-- However if it is refractive, we NEED the arnold path lest no light shines through.
			if (classOf parentMat == vrayMtl and (parentMat.refraction != black or parentMat.texmap_refraction != undefined)) do
			(
-- 				print "refractive"
				useADMaterials = false
			)
			if useADMaterials then --convert to AD shaders where possible (Physmat etc.)
			(
				theClass=(classof parentMat)
				case theClass of	--compound classes always go last!
				(
					vrayMtl : 
					(
						APM=physicalMaterial name:(uniquename(parentMat.name+"_Converted_")) base_weight:1 reflectivity:1 roughness_inv:on transparency:0 trans_color:black trans_roughness_lock:off trans_roughness_inv:on emission:1 emit_color:black material_mode:1
						--diffuse part
						APM.baseColor=parentMat.diffuse
						APM.base_color_map_on = parentMat.texmap_diffuse_on
						APM.base_color_map = bakeMapInfluence parentMat.texmap_diffuse parentMat.texmap_diffuse_multiplier parentMat.diffuse
						APM.diff_roughness = parentMat.diffuse_roughness
						APM.diff_rough_map_on =	parentMat.texmap_roughness_on
						colVal=parentMat.diffuse_roughness
						APM.diff_rough_map = bakeMapInfluence parentMat.texmap_roughness parentMat.texmap_roughness_multiplier (([colVal,colVal,colVal,1] as point4) as color)
						--emission part
						APM.emit_color = parentMat.selfIllumination
						APM.emit_color_map_on = parentMat.texmap_self_illumination_on
						APM.emit_color_map = bakeMapInfluence parentMat.texmap_selfIllumination parentMat.texmap_selfIllumination_multiplier parentMat.selfIllumination
						APM.emit_luminance = parentMat.selfIllumination_multiplier*477.464
						--reflection part
						APM.refl_color = parentMat.Reflection
						APM.refl_color_map_on = parentMat.texmap_Reflection_on
						APM.refl_color_map = bakeMapInfluence parentMat.texmap_Reflection parentMat.texmap_Reflection_multiplier parentMat.Reflection
						APM.roughness = parentMat.reflection_glossiness --already inverted the meaning of the physmat roughness on creation
						APM.roughness_map_on = parentMat.texmap_reflectionglossiness_on 
						colVal=parentMat.reflection_glossiness
						APM.roughness_map = bakeMapInfluence parentMat.texmap_reflectionglossiness parentMat.texmap_reflectionglossiness_multiplier (([colVal,colVal,colVal,1] as point4) as color)
						--IoR logic
						(
							if not parentMat.reflection_fresnel	then
							(
								APM.trans_ior = 50
							)
							else
							(
								if parentMat.reflection_lockIOR then 
								(
									APM.trans_ior = parentMat.refraction_ior 
									APM.trans_ior_map_on = parentMat.texmap_refractionior_on
									colVal= parentMat.refraction_ior 
									APM.trans_ior_map = bakeMapInfluence parentMat.texmap_refractionior parentMat.texmap_refractionior_multiplier (([colVal,colVal,colVal,1] as point4) as color)
								)
								else
								(
									if parentMat.reflection != black then 
									(
										APM.trans_ior = parentMat.reflection_ior 
										APM.trans_ior_map_on = parentMat.texmap_reflectionior_on
										colVal = parentMat.reflection_ior 
										APM.trans_ior_map = bakeMapInfluence parentMat.texmap_reflectionior parentMat.texmap_reflectionior_multiplier (([colVal,colVal,colVal,1] as point4) as color)
									)
									else 
									(
										APM.trans_ior = parentMat.refraction_ior 
										APM.trans_ior_map_on = parentMat.texmap_refractionior_on
										colVal= parentMat.refraction_ior 
										APM.trans_ior_map = bakeMapInfluence parentMat.texmap_refractionior parentMat.texmap_refractionior_multiplier (([colVal,colVal,colVal,1] as point4) as color)
									)
								)
							)
						)
						
						APM.metalness = parentMat.reflection_metalness	
						APM.metalness_map_on = parentMat.texmap_metalness_on
						colVal = parentMat.reflection_metalness
						APM.metalness_map = bakeMapInfluence parentMat.texmap_metalness parentMat.texmap_metalness_multiplier (([colVal,colVal,colVal,1] as point4) as color)
						-- Refraction Part
						APM.transparency = if parentMat.refraction!=black then 1.0 else 0.0
						APM.trans_color = parentMat.refraction
						APM.trans_color_map_on = parentMat.texmap_refraction_on
						APM.trans_color_map = bakeMapInfluence parentMat.texmap_refraction parentMat.texmap_refraction_multiplier parentMat.refraction
						APM.trans_roughness = parentMat.refraction_glossiness --already inverted the meaning of the physmat roughness on creation
						APM.trans_rough_map_on = parentMat.texmap_refractionglossiness_on 
						colVal = parentMat.refraction_glossiness
						APM.trans_rough_map = bakeMapInfluence parentMat.texmap_refractionglossiness parentMat.texmap_refractionglossiness_multiplier (([colVal,colVal,colVal,1] as point4) as color) 
						--Anisotropy part
						APM.anisotropy = parentMat.anisotropy+1.0
						APM.anisotropy_map_on = parentMat.texmap_anisotropy_on
						colVal = parentMat.anisotropy
						APM.anisotropy_map = bakeMapInfluence parentMat.texmap_anisotropy parentMat.texmap_anisotropy_multiplier (([colVal,colVal,colVal,1] as point4) as color)
						APM.anisoAngle = parentMat.anisotropy_rotation
						APM.aniso_Angle_map_on = parentMat.texmap_anisotropy_rotation_on
						colVal = parentMat.anisotropy_rotation
						APM.aniso_Angle_map = bakeMapInfluence parentMat.texmap_anisotropy_rotation parentMat.texmap_anisotropy_rotation_multiplier (([colVal,colVal,colVal,1] as point4) as color)
						APM.aniso_mode = parentMat.anisotropy_derivation
						APM.aniso_channel = parentMat.anisotropy_channel
						-- there is no Aniso Axis in the physmat.
						--Bump Part
						APM.bump_Map_on = parentMat.texmap_bump_on
						APM.bump_map = parentMat.texmap_bump
						APM.bump_map_amt = parentMat.texmap_bump_multiplier/100.
						--Displacement Part
						APM.displacement_map_on = parentMat.texmap_displacement_on
						APM.displacement_map = parentMat.texmap_displacement
						APM.displacement_map_amt = parentMat.texmap_displacement_multiplier
						--Opacity Part
						APM.cutout_map_on = parentMat.texmap_opacity_on
						
						APM.cutout_map = bakeMapInfluence parentMat.texmap_opacity parentMat.texmap_opacity_multiplier white

						replaceInstances parentMat APM
					)					
					vrayLightMtl : 
					(
						ALM=physicalMaterial name:(uniquename(parentMat.name+"_Converted_")) base_weight:0 reflectivity:0 material_mode:1 emission:1
						ALM.emit_color = parentMat.color
						ALM.emit_luminance = parentMat.multiplier*477.464 --Image multiplier to Luminance
						ALM.emit_color_map = parentMat.texmap
						ALM.cutout_map=parentMat.opacity_texmap
						ALM.displacement_map_amt = parentMat.displacement_multiplier
						ALM.displacement_map = parentMat.displacement_texmap
						replaceInstances parentMat ALM
					)
				)
			)
			else
			(
				-- converto to Arnold Shaders only (standard_suirface, AI_Surface etc.)
				theClass=(classof parentMat)
				case theClass of
				(
					vrayMtl : --skip bump, it doesn't work properly as it requires a normal map!
					(
						ASS=ai_standard_surface name:(uniquename(parentMat.name+"_Converted_")) base:1 specular:0 transmission:0 subsurface:0 caustics:on indirect_specular:1
						--diffuse part
						try (ASS.base_color.controller=parentMat.diffuse.controller) catch (ASS.base_color=parentMat.diffuse)
						ASS.base_color_connected = parentMat.texmap_diffuse_on
						ASS.base_color_shader = bakeMapInfluence parentMat.texmap_diffuse parentMat.texmap_diffuse_multiplier parentMat.diffuse
						ASS.diffuse_roughness = parentMat.diffuse_roughness
						ASS.diffuse_roughness_connected = parentMat.texmap_roughness_on
						colVal=parentMat.diffuse_roughness
						ASS.diffuse_roughness_shader = bakeMapInfluence parentMat.texmap_roughness parentMat.texmap_roughness_multiplier (([colVal,colVal,colVal,1] as point4) as color)
						--emission part
						ASS.emission_color = parentMat.selfIllumination
						ASS.emission_color_connected = parentMat.texmap_self_illumination_on
						ASS.emission_color_shader = bakeMapInfluence parentMat.texmap_selfIllumination parentMat.texmap_selfIllumination_multiplier parentMat.selfIllumination
						ASS.emission = parentMat.selfIllumination_multiplier
						--reflection part
-- 						ASS.specular = if parentMat.Reflection!=black then 1.0 else 0.0 --nope.
						ASS.specular = 1.0
						
						ASS.specular_color = parentMat.Reflection
						ASS.specular_color_connected = parentMat.texmap_Reflection_on
						ASS.specular_color_shader = bakeMapInfluence parentMat.texmap_Reflection parentMat.texmap_Reflection_multiplier parentMat.Reflection
						ASS.specular_roughness_connected = parentMat.texmap_reflectionglossiness_on 
						if parentMat.texmap_reflectionglossiness != undefined do
						(
							colVal=parentMat.reflection_glossiness
							theSubMap=(bakeMapInfluence parentMat.texmap_reflectionglossiness parentMat.texmap_reflectionglossiness_multiplier (([colVal,colVal,colVal,1] as point4) as color))
							theMap = output name:(uniqueName (parentMat.texmap_reflectionglossiness.name + "_Inverter_Map_")) map1:theSubMap
							theMap.output.invert=true
							ASS.specular_roughness_shader = theMap
							theMap = theSubMap = undefined
						)
						ASS.internal_reflections = parentMat.option_reflectOnBack
						--IoR logic
						(
							if not parentMat.reflection_fresnel	then
							(
								ASS.specular_ior = 100000
							)
							else
							(
								if parentMat.reflection_lockIOR then 
								(
									ASS.specular_ior = parentMat.refraction_ior 
									ASS.specular_ior_connected = parentMat.texmap_refractionior_on
									colVal= parentMat.refraction_ior 
									ASS.specular_ior_shader = bakeMapInfluence parentMat.texmap_refractionior parentMat.texmap_refractionior_multiplier (([colVal,colVal,colVal,1] as point4) as color)
								)
								else
								(
									if parentMat.reflection != black then 
									(
										ASS.specular_ior = parentMat.reflection_ior 
										ASS.specular_ior_connected = parentMat.texmap_reflectionior_on
										colVal = parentMat.reflection_ior 
										ASS.specular_ior_shader = bakeMapInfluence parentMat.texmap_reflectionior parentMat.texmap_reflectionior_multiplier (([colVal,colVal,colVal,1] as point4) as color)
									)
									else 
									(
										ASS.specular_ior = parentMat.refraction_ior 
										ASS.specular_ior_connected = parentMat.texmap_refractionior_on
										colVal= parentMat.refraction_ior 
										ASS.specular_ior_shader = bakeMapInfluence parentMat.texmap_refractionior parentMat.texmap_refractionior_multiplier (([colVal,colVal,colVal,1] as point4) as color)
									)
								)
							)
						)
						
						ASS.metalness = parentMat.reflection_metalness	
						ASS.metalness_connected = parentMat.texmap_metalness_on
						colVal = parentMat.reflection_metalness
						ASS.metalness_shader = bakeMapInfluence parentMat.texmap_metalness parentMat.texmap_metalness_multiplier (([colVal,colVal,colVal,1] as point4) as color)
						
						maxReflectionDepth=if parentMat.reflection_maxDepth > maxReflectionDepth then parentMat.reflection_maxDepth else maxReflectionDepth
						-- Refraction Part
						if parentMat.refraction!=black or (parentMat.texmap_refraction != undefined and parentMat.texmap_refraction_multiplier !=0.0) then
						(
							ASS.transmission = 1.0
						)
						else
						(
							ASS.transmission = 0.0
						)
						ASS.transmission_color = parentMat.refraction
						ASS.transmission_color_connected = parentMat.texmap_refraction_on
						ASS.transmission_color_shader = bakeMapInfluence parentMat.texmap_refraction parentMat.texmap_refraction_multiplier parentMat.refraction
						ASS.transmission_extra_roughness = 1.0 - parentMat.refraction_glossiness 
						ASS.transmission_extra_roughness_connected = parentMat.texmap_refractionglossiness_on 
						
						if parentMat.texmap_refractionglossiness != undefined do
						(
							colVal = parentMat.refraction_glossiness
							theSubMap=( bakeMapInfluence parentMat.texmap_refractionglossiness parentMat.texmap_refractionglossiness_multiplier (([colVal,colVal,colVal,1] as point4) as color) )
							theMap = output name:(uniqueName (parentMat.texmap_refractionglossiness.name + "_Inverter_Map_")) map:theSubMap
							theMap.output.invert=true
							ASS.transmission_extra_roughness_shader = theMap
							theMap = theSubMap = undefined
						)
						ASS.transmit_aovs= if parentMat.refraction_affectAlpha == 0 then off else on
						ASS.transmission_dispersion = if parentMat.refraction_dispersion_on then parentMat.refraction_dispersion else 0
						maxRefractionDepth=if parentMat.refraction_maxDepth > maxRefractionDepth then parentMat.refraction_maxDepth else maxRefractionDepth

						--Anisotropy part
						ASS.specular_anisotropy = (parentMat.anisotropy+1) / 2.0
						ASS.specular_anisotropy_connected = parentMat.texmap_anisotropy_on
						colVal = parentMat.anisotropy
						ASS.specular_anisotropy_shader = bakeMapInfluence parentMat.texmap_anisotropy parentMat.texmap_anisotropy_multiplier (([colVal,colVal,colVal,1] as point4) as color)
						ASS.specular_rotation = if parentMat.anisotropy_rotation == 0 then 0 else (mod parentMat.anisotropy_rotation 360)/360
						ASS.specular_rotation_connected = parentMat.texmap_anisotropy_rotation_on
						colVal = parentMat.anisotropy_rotation
						ASS.specular_rotation_shader = bakeMapInfluence parentMat.texmap_anisotropy_rotation parentMat.texmap_anisotropy_rotation_multiplier (([colVal,colVal,colVal,1] as point4) as color)
-- 						No Anisotropy mode in the ai_Standard_Surface
-- 						ASS.aniso_mode = parentMat.anisotropy_derivation
-- 						ASS.aniso_channel = parentMat.anisotropy_channel
						-- there is no Aniso Axis in the physmat.
						--Bump Part
-- 						ASS.normal_connected = parentMat.texmap_bump_on
-- 						ASS.normal_shader = bakeMapInfluence parentMat.texmap_bump parentMat.texmap_bump_multiplier black
						--Opacity Part
						ASS.opacity = white
						ASS.opacity_connected = parentMat.texmap_opacity_on
						ASS.opacity_shader = bakeMapInfluence parentMat.texmap_opacity parentMat.texmap_opacity_multiplier white
						replaceInstances parentMat ASS
					)
					vrayLightMtl : 
					(
	-- 					convert to standard_surface
						ASS=ai_standard_surface name:(uniquename(parentMat.name+"_Converted_")) base:0 specular:0 transmission:0 subsurface:0 caustics:on
							
						ASS.emission_color = parentMat.color
						ASS.emission_color_connected = parentMat.texmap_on
						ASS.emission_color_shader = parentMat.texmap
						ASS.emission = parentMat.multiplier

						ASS.opacity = white
						ASS.opacity_connected = parentMat.opacity_texmap_on
						ASS.opacity_shader = parentMat.opacity_texmap

						replaceInstances parentMat ASS
					)
				)
			)
			-- Shared conversion code
			case theClass of
			(
				vrayMtl :
				(
					--PLACEHOLDER
				)
				vrayLightMtl :
				(
					--PLACEHOLDER
				)
				VrayFastSSS2 : 
				(
-- 					convert to physical material
					APM=physicalMaterial name:(uniquename(parentMat.name+"_Converted_")) base_weight:0 reflectivity:0 roughness_inv:on material_mode:1 scattering:1 
					--Diffuse Part
					APM.base_color = parentMat.diffuse_color
					APM.base_color_map_on = parentMat.texmap_diffuse_color_on
					APM.base_color_map = bakeMapInfluence parentMat.texmap_diffuse_color parentMat.texmap_diffuse_color_multiplier parentMat.diffuse_color
					--Diffuse Weight
					APM.base_weight = parentMat.diffuse_amount
					APM.base_weight_map_on = parentMat.texmap_diffuse_amount_on
					colVal=parentMat.diffuse_amount
					APM.base_weight_map = bakeMapInfluence parentMat.texmap_diffuse_amount parentMat.texmap_diffuse_amount_multiplier (([colVal,colVal,colVal,1] as point4) as color)
					--SSS Color
					APM.sss_color = parentMat.sub_surface_color
					APM.sss_color_map_on =  parentMat.texmap_sss_color_on
					APM.sss_color_map = bakeMapInfluence parentMat.texmap_sss_color parentMat.texmap_sss_color_multiplier parentMat.sub_surface_color
					--Scatter Color
					APM.sss_scatter_color = parentMat.scatter_color
					APM.sss_depth = parentMat.scatter_radius*parentMat.scale
					APM.sss_scale = 1 --always set to 1, map with a texture in an output
-- 						APM.sss_scale_map = vrayColor name:"sss_scale_map" color:white rgb_multiplier:parentMat.scale
					--Specular Part
					APM.refl_color = parentMat.specular_color
					APM.refl_color_map_on = parentMat.texmap_specular_color_on
					APM.refl_color_map = bakeMapInfluence parentMat.texmap_specular_color parentMat.texmap_specular_color_multiplier parentMat.specular_color
					--Specular Amount
					APM.reflectivity = parentMat.specular_amount
					APM.reflectivity_map_on = parentMat.texmap_specular_amount_on
					colVal = parentMat.specular_amount
					APM.reflectivity_map = bakeMapInfluence parentMat.texmap_specular_amount parentMat.texmap_specular_amount_multiplier (([colVal,colVal,colVal,1] as point4) as color)
					--Specular Glossiness
					APM.roughness = parentMat.specular_glossiness --already inverted the meaning of the physmat roughness on creation
					APM.roughness_map_on = parentMat.texmap_specular_glossiness_on 
					colVal=parentMat.specular_glossiness
					APM.roughness_map = bakeMapInfluence parentMat.texmap_specular_glossiness parentMat.texmap_specular_glossiness_multiplier (([colVal,colVal,colVal,1] as point4) as color)
					--IoR
					APM.trans_ior = parentMat.ior
					--Opacity (using CutOff!)
					APM.cutout_map_on = parentMat.texmap_opacity_on
					APM.cutout_map = bakeMapInfluence parentMat.texmap_opacity parentMat.texmap_opacity_multiplier white
					--Bump
					APM.bump_Map_on = parentMat.texmap_bump_on
					APM.bump_map = parentMat.texmap_bump
					APM.bump_map_amt = parentMat.texmap_bump_multiplier/100.						
					
					replaceInstances parentMat APM
				) 
				vrayBlendMtl : 
				(
					matsArray=#()
					append matsArray #(on, parentMat.baseMtl, white, undefined, 100.0)
					for i=1 to parentMat.coatMtl.count where parentMat.coatMtl[i]!=undefined do
					(
						append matsArray #(parentMat.coatMtl_enable[i], parentMat.coatMtl[i], parentMat.blend[i], parentMat.texMap_Blend[i], parentMat.texmap_blend_multiplier[i])
					)
					if matsArray.count == 0 then print "empty blend material!?"
					else if matsArray.count > 0 and matsArray.count <= 8 and not parentMat.additiveMode then
					(
						replaceinstances parentMat (convert8Layers parentMat matsArray)
					)
					else if matsArray.count > 8 or parentMat.additiveMode then
					(
						-- create the first blend with the first two materials in it, and Add to an array! 
						AMarray=#()
						append AMarray #(parentMat.coatMtl_enable[1], (convertBlend parentMat matsArray[1] matsArray[2]), parentMat.blend[1], parentMat.texMap_Blend[1], parentMat.texmap_blend_multiplier[1])
						for i = 3 to matsArray.count do -- for each successive material to blend, we need to pipe in the previous one into a new blend
						(
							append AMarray #(parentMat.coatMtl_enable[i], (convertBlend parentMat AMarray[i-2] matsArray[i]), parentMat.texMap_Blend[i], parentMat.texmap_blend_multiplier[i])
						)
						replaceinstances parentMat AMarray[AMarray.count][2]
					)
				)					
				VRay2SidedMtl : 
				(
-- 					convert to ai_two_sided, which misses options
					A2S=ai_two_sided name:(uniquename(parentMat.name+"_Converted_")) front:parentMat.frontMtl
					if parentMat.backMtlOn then A2S.back = parentMat.backMtl else A2S.back = parentMat.frontMtl
					replaceInstances parentMat A2S
				)
				VRayMtlWrapper : 
				(
					replaceInstances parentMat parentMat.baseMtl
				)
				default : 
				(
					print ("!!!!!!! " + theClass as string) 
					append leftOverMats parentMat
				)
			)				
		)
	)
	
	
	fn convertVRayLight VL=
	(
		-- Arnold Light creation
		AL=Arnold_Light name:(uniquename(VL.name + "_Converted_")) exposure:0 normalize:off useColor:on intensity:666 

		--ArnoldLight Common Properties
		--On		
		try (AL.on=VL.on) catch (AL.on=VL.enabled)
		--Transforms
		AL.transform = VL.transform
			
		AL.cast_shadows = try (VL.castShadows) catch (true)		
		--Class
		case of
		(
			(classOf VL == vrayLight) : 
			(
				--Intensity
				--Set the VL to image units multiplier for easier conversion.
				VL.normalizeColor=0
				AL.normalize=off
				AL.intensity = VL.multiplier
				--Color
				--Set the VL's color mode to color, not temperature, for easier conversion
				VL.color_mode=0
				try (AL.color.controller = copy VL.color.controller) catch (AL.color = VL.color)
				--Texture
				if VL.texMap_on and VL.texmap != undefined do
				(
		-- 			AL.useColor = off	--?!?
					AL.useTexmap = on
					AL.texmap = VL.texmap
				)
				-- Influences
				if VL.affect_diffuse then 
				(
					AL.diffuse = VL.diffuse_contribution
				)
				else
				(
					AL.diffuse = 0
				)
				if VL.affect_specular then
				(
					AL.specular = VL.specular_contribution
				)
				--Shadow Casting				
				AL.cast_shadows = VL.castshadows				
				--Fixture Visibility
				AL.lightShapeVisible = not VL.invisible

				--Shape
				case VL.type of
				(
					0 : 
					(
						--Plane
						--Type
						AL.shapeType = 3
						--Directionality
						AL.spread = 1.0-VL.lightDistribution
						--Sizes
						AL.quadX = VL.size0*2
						AL.quadY = VL.size1*2
						--Ancillaries
						AL.quadRoundness=0
						AL.soft_edge=0
						--Portal
						AL.portal=VL.skylightPortal
					)
					1 : 
					(
						-- If it's a dome, i seem to be able to ONLY make it work in "Physical mode", copying the map to the Background.
						--Dome
-- 						AL.shapeType = 6
-- 						AL.resolution = VL.texmap_resolution
-- 						AL.format = 2 --LatLong. To Verify!
						delete AL	--no need for the arnold light
						ArnoldRenderer.env_mode = 0 --use environment settings / implicit IBL?
						if VL.texMap_on and VL.texmap != undefined then
						(
							useEnvironmentMap = true
							if classOf VL.texmap == VRayHDRI and VL.texmap.maptype == 2 do VL.texmap.horizontalRotation -= 90 --It seems Arnold interprets maps wrong.
							if VL.multiplier != 1.0 then 
							(
								om=output map1:VL.texmap 
								om.output.output_amount=VL.multiplier
								environmentMap = om
							)
							else
							(
								environmentMap = VL.texmap
							)
						)
						else
						(
							useEnvironmentMap = false
							environmentMap = undefined
							try (backgroundColorController = copy VL.color.controller) catch (backgroundColor = VL.Color)
						)
					)
					2 : 
					(
						--Sphere
						--Doesn't exist. Approximating with a sphere mesh(?!)
-- 						AL.shapeType = 8
-- 						sphereMesh= geoSphere radius:VL.size0 isHidden:true renderable:false
-- 						AL.lightMesh = sphereMesh
						
						--Arnold Omni has a RADIUS. will use that.
						AL.shapeType = 0
						AL.lightRadius=VL.size0
					)
					3 : 
					(
						--Mesh
						AL.shapeType = 8
						AL.lightMesh = VL.mesh_source
					)
					4 : 
					(
						--Disc
						AL.shapeType = 4
						AL.lightRadius = VL.size0
						--Directionality
						AL.spread = 1.0-VL.lightDistribution
						
					)
					
				)
			)
			(classOf VL == VRayIES) :
			(
				--Set to Photometric light
				AL.shapeType = 7				
				--filename
				AL.filename = VL.ies_file				
				--Color
				--Set the VL's color mode to color, not temperature, for easier conversion
				VL.color_mode=0
				AL.color = VL.color
				--Intensity
				--Set the VL to lm units, then convert with 945.2486:1 towards the AL.
				AL.intensity = VL.intensity_value/945.2486  --?!?
				
-- 				AL.photometricRadius = 10 --no equivalent?
				--Influences
				AL.diffuse = if VL.affect_diffuse then 1 else 0
				AL.specular = if VL.affect_specular then 1 else 0
				AL.cast_shadows = VL.cast_shadows
			)
			(classOf VL == VRayAmbientLight) :
			(
				-- no equivalent?
			)
			(classOf VL == VRaySun) :
			(
				AL.shapeType = 1
			)
			(classOf VL == omniLight or classOf VL == freeSpot or classOf VL == targetSpot or classOf VL == Directionallight or classOf VL == TargetDirectionallight) : --max lights
			(
				--common properties
				--shadow size (V-Ray only)
				if ((classOf VL.shadowGenerator == VRayShadow) and VL.AreaShadow ) then 
				(
					if VL.areaShadowType==1 then AL.lightRadius = VL.usize else AL.lightRadius = amax#(VL.usize,VL.vsize,VL.wsize)
				)
				else AL.lightRadius=0
				--Don't scale energy with light size.
				AL.normalize=on
				--color and intensity
				AL.intensity = VL.multiplier
				AL.useColor = on
				AL.color = VL.rgb
				AL.cast_shadows = VL.castShadows
				
				if classOf VL == omnilight then
				(
					AL.shapeType = 0
				)
				if classOf VL == Directionallight or classOf VL == TargetDirectionallight then
				(
					AL.shapeType = 2 --I'll convert them into truncated spots so to translate the softness parameters
					AL.cone_angle = VL.falloff
					AL.penumbra_angle =  VL.falloff - VL.hotspot
					AL.lens_radius=360 --truncates the light cone point entirely
					if VL.coneShape == 1 then --circle
					(
						AL.aspect_ratio=1 	--no AR for circle spots in max
						AL.spotRoundness =1 	--perfectly circular
					)
					else	--rectangle
					(
						AL.aspect_ratio = VL.aspect --AR
						AL.spotRoundness =0	--perfectly square
					)					
				)				
				if classOf VL == freeSpot or classOf VL == targetSpot then
				(
					AL.shapeType = 2
					AL.cone_angle = VL.falloff
					AL.penumbra_angle =  VL.falloff - VL.hotspot
					AL.lens_radius=0 --truncates the light cone point
					if VL.coneShape == 1 then --circle
					(
						AL.aspect_ratio=1 	--no AR for circle spots in max
						AL.spotRoundness=1 	--perfectly circular
					)
					else	--rectangle
					(
						AL.aspect_ratio = VL.aspect --AR
						AL.spotRoundness=0	--perfectly square
					)
				)				
			)
			default :
			(
				append leftOverLights VL
			)
		)
		
		try (
-- 				try (AL.parent = VL.parent) catch()
-- 				try (
					append lightsToDelete VL
-- 					delete VL
-- 					) catch()
			) 
		catch 
			(
				append leftOverLights VL
-- 				try (
-- 				delete AL
					append lightsToDelete AL
-- 					) catch ()
			)

	)
	
	fn convertVRayCamera VRC =
	(
		try 
		(
			PC = physical_Camera name:(uniquename (VRC.name + "_Converted_")) targeted:false
				
			if VRC.target != undefined then --copy just the position
			(
	-- 			print "Animated Target"
				try (PC.position.controller = copy VRC.position.controller) catch (PC.position = VRC.position)
	-- 			try (PC.transform.controller = copy VRC.transform.controller) catch (PC.transform = VRC.transform)
				PC.targeted=true
				try (PC.target.position.controller = copy VRC.target.position.controller) catch (PC.target.position = VRC.target.position)
			)
			else	--else copy the whole transform
			(
				try (PC.transform.controller = copy VRC.transform.controller) catch (PC.transform = VRC.transform)
			
			)

			for p in (getPropNames VRC) do
			(
				try 
				(
					try
					(
						setPropertyController PC p (getPropertyController VRC p)
					)
					catch
					(
						setProperty PC p (getProperty VRC p)
					)
				)
				catch
				(
	-- 				print ("couldn't set the property named " + p as string + " on the " + VRC.name + " camera.")
				)
			)
			-- this part deals with the non-directly-mappable properties, in a dictionary fashion
			try (PC.film_width_mm.controller = copy VRC.film_width.controller) catch (PC.film_width_mm = VRC.film_width)
			try (PC.focal_length_mm.controller = copy VRC.focal_length.controller) catch (PC.focal_length_mm = VRC.focal_length)
			PC.motion_blur_enabled = VRC.use_moblur
			-- Exposure
			if VRC.exposure do 
			(
				--Check for the current exposure control first
				EC=SceneExposureControl.exposureControl
				case (classOf EC) of
				(
					undefinedClass : --exposure was wholly on camera. Install the new one and set it up accordingly
					(
						newEC = Physical_Camera_Exposure_Control()
						newEC.use_physical_camera_controls = true
						newEC.use_global_ev=0
						newEC.global_ev = 0
						SceneExposureControl.exposureControl=newEC
						PC.exposure_gain_type=0 --ISO
						PC.ISO=VRC.ISO
					)
					VRay_Exposure_Control :
					(
						case EC.mode of
						(
							105 :	--From Camera: there is no way to assign a camera to the Physical Exposure controls. Treat as "Photographic"
							(
								newEC = Physical_Camera_Exposure_Control()
								newEC.use_physical_camera_controls = true --make it use the camera settings
								newEC.use_global_ev=0
								newEC.global_ev = 0
								SceneExposureControl.exposureControl=newEC
								--copy settings over to the physical camera
								PC.exposure_gain_type=0 --ISO
								PC.ISO=VRC.ISO
							)
							106 :	--From EV
							(
								newEC = Physical_Camera_Exposure_Control()
								newEC.use_physical_camera_controls = off --make it use the panel settings
								newEC.use_global_ev=1
								newEC.global_ev = EC.exposureControl.ev
								SceneExposureControl.exposureControl=newEC
							)
							107 : 	--Photographic
							(
								newEC = Physical_Camera_Exposure_Control()
								newEC.use_physical_camera_controls = true --make it use the camera settings
								newEC.use_global_ev=0
								newEC.global_ev = 0
								SceneExposureControl.exposureControl=newEC
								--copy settings over to the physical camera
								PC.exposure_gain_type=0 --ISO
								PC.ISO=VRC.ISO
							)
						)
					)
					
				)
			)
			--shutter
			case VRC.type of
			(
				0: --still cam: 1/s
				(
					PC.shutter_unit_type = 0
					PC.shutter_offset_enabled = false
					try 
					(
						PC.shutter_length_seconds.controller = copy VRC.shutter_speed.controller
						for k in PC.shutter_length_seconds.controller.keys do k.value=1.0/k.value
					) 
					catch (PC.shutter_length_seconds = 1.0/VRC.shutter_speed)
				)
				1: --movie cam: angle + offset
				(
					PC.shutter_unit_type = 2
					PC.shutter_offset_enabled = true
					try 
					(
						PC.shutter_length_frames.controller = copy VRC.shutter_angle.controller
						for k in PC.shutter_length_frames.controller.keys do k.value/=360.0
						PC.shutter_offset_frames.controller = copy VRC.shutter_offset.controller
						
					) 
					catch 
					(
						PC.shutter_length_frames = VRC.shutter_angle/360
						PC.shutter_offset_frames = VRC.shutter_offset
					)
				)
				2: --video cam: latency 
				(
					PC.shutter_unit_type = 1
					PC.shutter_offset_enabled = false
					try
					(
						PC.shutter_length_seconds.controller = copy VRC.latency.controller
					)
					catch 
					(
						PC.shutter_length_seconds = VRC.latency
					)
				)
			)
			--Wignetting and WB
			PC.vignetting_enabled = VRC.vignetting
			PC.white_balance_type = 2	--manual
			try (PC.white_balance_custom.controller = copy VRC.whiteBalance.controller) catch (PC.white_balance_custom = VRC.whiteBalance)

			--Lens Correction
			try (PC.vertical_tilt_correction.controller = copy VRC.lens_tilt.controller) catch (PC.vertical_tilt_correction = VRC.lens_tilt)
			try (PC.horizontal_tilt_correction.controller = copy VRC.lens_horTilt.controller) catch (PC.horizontal_tilt_correction = VRC.lens_horTilt)
			try (PC.horizontal_shift.controller = copy VRC.horizontal_shift.controller) catch (PC.horizontal_shift = VRC.horizontal_shift)
			try (PC.vertical_shift.controller = copy VRC.vertical_shift.controller) catch (PC.vertical_shift = VRC.vertical_shift)
			PC.auto_vertical_tilt_correction = VRC.lens_tilt_auto
			
			--Bokeh
			if not VRC.use_Blades then PC.bokeh_shape = 0 --Circular
				else 
				(
					PC.bokeh_shape = 1 --Bladed
					try (PC.bokeh_blades_number.controller = copy VRC.blades_number.controller) catch (PC.bokeh_blades_number = VRC.blades_number)
					try (PC.pb_bokeh_blaades_rotation_degrees.controller = copy VRC.blades_rotation.controller) catch (PC.pb_bokeh_blaades_rotation_degrees = VRC.blades_rotation) -- SERIOUSLY?
				)
			if VRC.bitmap_aperture_on do 
			(
				PC.bokeh_shape = 2 --texture mapped
				PC.bokeh_texture_affect_exposure = VRC.bitmap_aperture_affectExposure
				PC.bokeh_texture = VRC.bitmap_aperture_texmap
			)
			try (PC.bokeh_center_bias.controller = copy VRC.center_bias.controller) catch (PC.bokeh_center_bias = VRC.center_bias) 
			try (PC.bokeh_optical_vignetting.controller = copy VRC.optical_vignetting.controller) catch (PC.bokeh_optical_vignetting = VRC.optical_vignetting) 
			try (PC.bokeh_anisotropy.controller = copy VRC.anisotropy.controller) catch (PC.bokeh_anisotropy = VRC.anisotropy) 
			try (PC.baseObject.ReferenceTarget.bitmap_aperture_res.controller = VRC.bitmap_aperture_res.controller) catch (PC.baseObject.ReferenceTarget.bitmap_aperture_res = VRC.bitmap_aperture_res)
			case VRC.distortion_type of
			(
				0: --Quadratic: no equivalent
				(
					PC.distortion_type=0 --set to none
				)
				1: --Cubic
				(
					PC.distortion_type=1 --set to Cubic
					try (PC.distortion_cubic_amount.controller = copy VRC.Distortion) catch (PC.distortion_cubic_amount=VRC.Distortion)
				)
				2: -- Lens File, no equivalent
				(
					PC.distortion_type=0 --set to none
				)
				3: --Textured
				(
					PC.distortion_type=2 --set to Texture
					PC.distortion_texture = VRC.distortion_map
				)
			)
			try (delete VRC) catch()
		)
		catch
		(
			append leftOverCameras VRC
			try (delete PC) catch () --shouldn't ever be needed, but hey...
		)
	)

	fn convertVrayProxy VRP =
	(
		try 
		(
			if VRP.modifiers.count==0 do VRP.baseObject.display = 4 --and done.
		)
		catch 
		(
			append leftOverProxies VRP
		)
	)
	
	fn convertAllVrayMaps =
	(		
		ts=timestamp()
		print "Processing V-Ray Textures"
		allMaps = getclassinstances vrayDirt 
		for vM in allMaps do convertVRayMap vM
		totTime=(timeStamp()-ts)/1000.
		print ("It took " + totTime as string + "s. to convert " + allMaps.count as string + " V-Ray Textures")
		if leftOverMaps.count > 0 then 
			(
				print ("A total of " + leftOverMaps.count as string + " V-Ray Textures were not converted")
				print leftOverMaps
			)
		else print "All V-Ray Textures were converted."		
	)

	fn convertAllSunAndSky =
	(
		ts=timestamp()
		print "Processing V-Ray Skies"
		allSkies = getclassinstances vraySky
		for vS in allSkies do 
		(
-- 			print vS.sun_node
			convertVRaySky vS
		)
		totTime=(timeStamp()-ts)/1000.
		print ("It took " + totTime as string + "s. to convert " + allSkies.count as string + " V-Ray Skies")
		if leftOverSkies.count > 0 then 
			(
				print ("A total of " + leftOverSkies.count as string + " V-Ray Skies were not converted")
				print leftOverSkies
			)
		else print "All V-Ray Skies were converted."		
	)	

	fn convertAllProxies =
	(
		ts=timestamp()
		print "Processing V-Ray Proxies"		
		allProxies = for o in objects where classOf o == vrayProxy collect o
		for p in allProxies where p.modifiers.count == 0 do 
		(
			convertVrayProxy p
		)
		totTime=(timeStamp()-ts)/1000.
		print ("It took " + totTime as string + "s. to convert " + allProxies.count as string + " V-Ray Proxies")
		if leftOverProxies.count > 0 then 
			(
				print ("A total of " + leftOverProxies.count as string + " V-Ray Proxies were not converted")
				print leftOverProxies
			)
		else print "All V-Ray Proxies were converted."
	)
	
	fn convertAllSceneMaterials useADMaterials=
	(
		ts=timestamp()
		print "Processing Materials"
		-- ALWAYS join composited materials for last, lest they won't get converted!
		allMats = (getClassInstances vrayMtl)
		join allMats (getClassInstances vrayLightMtl)
		join allMats (getClassInstances VrayFastSSS2)		
		join allMats (getClassInstances VRay2SidedMtl)
		join allMats (getClassInstances VRayBlendMtl)
		join allMats (getClassInstances VRayMtlWrapper)		
		
		for m in allMats do convertVrayMtl m useADMaterials --convertVrayMtl inMaterial useADMaterials
		totTime=(timeStamp()-ts)/1000.
		print ("It took " + totTime as string + "s. to convert " + allMats.count as string + " Materials")
		if leftOverMats.count > 0 then 
			(
				print ("A total of " + leftOverMats.count as string + " Materials were not converted")
				print leftOverMats
			)
		else print "All Materials were converted."
	)	
		
	fn convertAllSceneLights =
	(
		ts=timestamp()
		print "Processing Lights"
		lightsToDelete=#()
		allLights = for l in lights where classof l != targetobject and classOf l == VRayLight collect l
		join allLights (for l in lights where classof l != targetobject and classOf l == VRayIES collect l)
		join allLights (for l in lights where classof l != targetobject and classOf l == VRayAmbientLight collect l)
		join allLights (for l in lights where classof l != targetobject and classOf l == VRaySun collect l)
		join allLights (for l in lights where classof l != targetobject and classOf l == omniLight collect l)
		join allLights (for l in lights where classof l != targetobject and classOf l == freeSpot collect l)
		join allLights (for l in lights where classof l != targetobject and classOf l == targetSpot collect l)
		join allLights (for l in lights where classof l != targetobject and classOf l == Directionallight collect l)
		join allLights (for l in lights where classof l != targetobject and classOf l == TargetDirectionallight collect l)
		print allLights.count
		
		--split the array in sub-arrays with 100 lights each max.
		
		batchSize = 25
		print ("Splitting big array in batches of " + batchSize as string)
		
		arraysCount = if ( mod allLights.count batchSize == 0 ) then (allLights.count / batchSize) else ( (allLights.count / batchSize) + 1 )
		newLightsArray = #()
		for p=1 to arraysCount do
		(
			newArray=#()
			for i = 1 to batchSize do
			(
				append newArray allLights[((p-1) * batchSize)+i]
			)
			append newLightsArray newArray
		)
		
		print ("Processing " + newLightsArray.count as string + " smaller arrays")
		ts1=timestamp()
		i=0
		ii=0
		for nA in newLightsArray do
		(
			i+=1
			print "Converting"
			for l in nA do
			(
				ii+=1
				windows.processPostedMessages()
				convertVRayLight l
			)
			print "Deleting"
			delete lightsToDelete 
			lightsToDelete = #()
			print ( ((i as float/newLightsArray.count)*100.) as string + @"% done so far")
			print ( (((timestamp()-ts1)/(1000.*batchSize)) as string) + "s. per light")
			ts1=timestamp()
		)
-- 		gc()
-- 		freescenebitmaps()
-- 		print "Deleting old Lights"
-- 		clearSelection()
-- 		for l in lightsToDelete do selectmore l
-- 		delete selection
-- 		delete lightsToDelete 
		
		totTime=(timeStamp()-ts)/1000.
		print ("It took " + totTime as string + "s. to convert " + allLights.count as string + " Lights")
		if leftOverLights.count > 0 then 
			(
				print ("A total of " + leftOverLights.count as string + " Lights were not converted")
				print leftOverLights
			)
		else print "All Lights were converted."
	)

	fn convertAllVRayCameras = 
	(
		ts=timestamp()
		print "Processing V-Ray Physical Cameras"
		allCameras = for c in cameras where classof c == vrayPhysicalCamera collect c
-- 		print allCameras
		for c in allCameras do convertVRayCamera c	
		if allCameras.count == 1 do viewport.setType #view_camera
		totTime=(timeStamp()-ts)/1000.
		print ("It took " + totTime as string + "s. to convert " + allCameras.count as string + " V-Ray Physical Cameras")
		if leftOverCameras.count > 0 then 
			(
				print ("A total of " + leftOverCameras.count as string + " V-Ray Physical Cameras were not converted")
				print leftOverCameras
			)
		else print "All V-Ray Physical Cameras were converted."		
	)
	
	fn switchToArnold =
	(
		print "Switching to the Arnold Renderer"
		Print "Depending on the license, it could take a while, nothing to do with me..."
		wasOpen = renderscenedialog.isopen()
		renderscenedialog.close()
		vrayRenderer=undefined
		
		if (itsVray renderers.current) do
		(
			vrayRenderer = renderers.current
			maxDiffuseDepth = if vrayRenderer.gi_secondary_type==3 then amin #(vrayRenderer.lightcache_bounces,5) else vrayRenderer.dmcgi_depth
		)
		arnoldRenderer.GI_diffuse_samples = arnoldRenderer.GI_specular_samples = arnoldRenderer.GI_transmission_samples = arnoldRenderer.GI_sss_samples = arnoldRenderer.GI_volume_samples = floor (sqrt (vrayRenderer.imageSampler_shadingRate as float)) as integer
		arnoldRenderer.indirect_sample_clamp=if (itsVray renderers.current) and vrayRenderer.options_maxRayIntensity_on then vrayRenderer.options_maxRayIntensity else 10000000.0
		arnoldRenderer.legacy_3ds_max_map_support = true
		arnoldRenderer.GI_diffuse_depth = if maxDiffuseDepth!=0 then maxDiffuseDepth else 3
		arnoldRenderer.GI_specular_depth = if maxReflectionDepth != 0 then maxReflectionDepth else 5
		arnoldRenderer.GI_transmission_depth = if maxRefractionDepth != 0 then maxRefractionDepth else 5
		arnoldRenderer.GI_total_depth = arnoldRenderer.GI_specular_depth + arnoldRenderer.GI_transmission_depth
		arnoldRenderer.auto_transparency_depth = arnoldRenderer.GI_total_depth
		arnoldRenderer.bucket_size = 16 --you'll thank me later.
		renderers.production = arnoldRenderer
		
		if wasOpen do  renderscenedialog.open()
	)

	fn switchToCreateMode onOff = 
	(
		oldMode=undefined
		if onOff then
		(
			oldMode = getCommandPanelTaskMode
			setCommandPanelTaskMode #create
		)
		else
		(
			if oldMode!=undefined do setCommandPanelTaskMode oldMode
		)
	)
	
	fn processVRayScene useADMaterials= 
	(
		ArnoldRenderer = arnold()
		if itsVRay renderers.current then
		(
			if useADMaterials then 
			(
				print "Converting to Autodesk Materials and Maps where possible." 
			)
			else 
			(
				print "Converting to Arnold Materials and Maps where possible." 
			)
			try 
			(
				print "Massaging Heap Size"
				if heapfree < 500000000 do ( heapsize += (500000000-heapfree))
				
				suspendEditing() --this is like moving to the creation panel, in that it doesn't update the UI, regardless of what's active in the UI. new from max 7, i think. First time i use it! :P
				disableSceneRedraw() 
				switchToCreateMode on
				convertAllVrayMaps()
				convertAllSunAndSky()				
				convertAllProxies()
				convertAllSceneLights()
				convertAllSceneMaterials useADMaterials
				convertAllVRayCameras()
				switchToArnold()
				switchToCreateMode off
				resumeEditing()
				enableSceneRedraw() 
				print " ALL DONE! "
			)
			catch
			(
				Print "--------------------- MASSIVE FAILURE!!! -----------------------"
				Print "Could you please copy the above text and pass it to Lele, along with a reference as to the scene?"
				resumeEditing()
				enableSceneRedraw() 
			)
		)
		else
		(
			if queryBox "V-Ray isn't the current renderer, I can't proceed!\nDo you want me to set it for you and start over?" beep:true then
			(
				for R in RendererClass.classes where itsVray R do renderers.current = R()
				processVrayScene useADMaterials
			)
			else
			(
				print "Aborted because of Wrong Render Engine selection"
			)
		)
	)
	
	useADMaterials = false
	undo off 
	(
		setSuperExpertMode true
		processVrayScene useADMaterials
		setSuperExpertMode false
	)
)

