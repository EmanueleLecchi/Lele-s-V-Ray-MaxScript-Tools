(
	/*
	"Simple" scene converter from V-Ray to Arnold
	Lights: they should all be translatable, minus perhaps a few inferred properties (f.e. exposure in A's).
	Materials: Translate to PhysicalMaterial.
	Maps: most should be directly pluggable at the root. This may turn out to be the most laborious part, however.
	*/

	local allMats = #()
	local leftOverMats = #()
	local allLights = #()
	local leftOverLights = #()
	local allCameras  = #()
	local leftOverCameras = #()
	
	
	fn convertBlend blendMat matA matB =  
	(
		AM=ai_mix_shader name:(uniquename(blendMat.name+"_Converted_"))
		AM.mode=blendMat.additiveMode
		AM.shader1 = matA[2]
		AM.shader2 = matB[2]
		if matB[4]!= undefined then 
		(
			if  matB[5]==100.0 then 
			(
				AM.Mix_shader = matB[4] 
			)
			else
			(
				multA=output map1:matB[4] 
				multA.output.output_amount=(matB[5]/100.0)
				multB=VrayColor color:matB[3] rgb_multiplier:(1.0-(matB[5]/100.0))
				AM.Mix_shader = vrayCompTex sourceA:multA sourceB:multB
			)
		)
		else 
		(
			AM.Mix_shader = VrayColor color:matB[3]
		)
		AM
	)
	
	fn bakeMapInfluence inMap influenceAmt baseColor=
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
		outMap
	)
	
	fn convertVrayMtl parentMat useADMaterials=
	(
		/*
		No need to convert MultiSub mtl
		Convert VrayMtl to PhysicalMaterial
		Blend Materials: Arnold's mix shader only has 2 entries. Will need parsing the VrayBlend and ensure i make enough nested mix shaders in arnold.
		*/

		if superClassOf parentMat==material do
		(
			if useADMaterials then --convert to AD shaders where possible (Physmat etc.)
			(
				theClass=(classof parentMat)
-- 				print theClass
				case theClass of
				(
					vrayBlendMtl : 
					(
						matsArray=#()
						append matsArray #(on, parentMat.baseMtl, white, undefined, 100.0)
						for i=1 to parentMat.coatMtl.count where parentMat.coatMtl[i]!=undefined do
						(
							append matsArray #(parentMat.coatMtl_enable[i], parentMat.coatMtl[i], parentMat.blend[i], parentMat.texMap_Blend[i], parentMat.texmap_blend_multiplier[i])
						)
						if matsArray.count == 0 then print "empty blend material!?"
						else if matsArray.count == 1 then print "Single-Material Blend!?"
						else if matsArray.count == 2 then 
						(
							replaceinstances parentMat (convertBlend parentMat matsArray[1] matsArray[2])
						)
						else if matsArray.count >= 3 then
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
						APM.emit_luminance = parentMat.selfIllumination_multiplier*477.464/pi
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
						APM.anisotropy = parentMat.anisotropy
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
						ALM.emit_luminance = parentMat.multiplier*477.464/pi --Image multiplier to Luminance
						ALM.emit_color_map = parentMat.texmap
						ALM.cutout_map=parentMat.opacity_texmap
						ALM.displacement_map_amt = parentMat.displacement_multiplier
						ALM.displacement_map = parentMat.displacement_texmap
						replaceInstances parentMat ALM
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
					VRay2SidedMtl : 
					(
	-- 					convert to ai_two_sided, which misses options
						A2S=ai_two_sided name:(uniquename(parentMat.name+"_Converted_")) front:parentMat.frontMtl
						if parentMat.backMtlOn then A2S.back = parentMat.backMtl else A2S.back = parentMat.frontMtl
						replaceInstances parentMat A2S
					)
					default : 
					(
						print ("!!!!!!! " + theClass as string) 
						append leftOverMats parentMat
					)
				)
			)
			else
			(
				-- converto to Arnold Shaders only (standard_suirface, AI_Surface etc.)
			)
		)
	)
	
	fn convertVRayLight VL=
	(
		/*
		Five modes for the standard light: all but the dome can be portals
		VRayIES
		VrayAmbientLight
		VRaySun
		*/
		-- Arnold Light creation
		AL=Arnold_Light name:(uniquename(VL.name + "_Converted_")) exposure:0 normalize:on useColor:on intensity:666
		
		--Class
		case (classOf VL) of
		(
			vrayLight : 
			(
				--VRayLight Common Properties
				--On
				AL.on=VL.on
				--Transforms
				try (AL.transform.controller = copy VL.transform.controller) catch (AL.transform = VL.transform)
				--Target Distance
				try (AL.targdist.controller = copy VL.target_distance.controller) catch (AL.targdist = VL.target_distance)
					
				if VL.targeted do 
				(
					VL.targeted=true
					try (AL.target.transform.controller = copy VL.target.transform.controller) catch (AL.target.transform = VL.target.transform)
				)
				--Intensity
				--Set the VL to image units multiplier for easier conversion.
				VL.normalizeColor=0
				try (AL.intensity.controller = copy VL.multiplier.controller) catch (AL.intensity = VL.multiplier/pi) --REALLY?!? p.s.: remember that if it's the case to divide by Pi, you have to care for the controller keys too.
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
					try (AL.diffuse.controller = copy VL.diffuse_contribution.controller) catch (AL.diffuse = VL.diffuse_contribution)
				)
				else
				(
					AL.diffuse = 0
				)
				if VL.affect_specular then
				(
					try (AL.specular.controller = copy VL.specular_contribution.controller) catch (AL.specular = VL.specular_contribution)
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
						if VL.lightDistribution.controller != undefined then 
						(
							AL.spread.controller = copy VL.lightDistribution.controller
							for k in AL.spread.controller.keys do k.value=1.0-k.value
						)
						else
						(
							AL.spread = 1.0-VL.lightDistribution
						)
						--Sizes
						if VL.size0.controller !=  undefined then 
						(
							AL.quadX.controller = copy VL.size0.controller 
							for k in AL.quadX.controller.keys do k.value*=2
						)
						else
						(
							AL.quadX = VL.size0*2
						)
						if VL.size1.controller != undefined then
						(
							AL.quadY.controller = copy VL.size1.controller 
							for k in AL.quadY.controller.keys do k.value*=2
						)
						else
						(
							AL.quadY = VL.size1*2
						)
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
						--set Arnold to use the dome!
						renderers.current.env_mode = 1
						renderers.current.env_adv_ibl_multiplier = 1/Pi
						delete AL						
						if VL.texMap_on and VL.texmap != undefined then
						(
							useEnvironmentMap = true
-- 							om=multA=output map1:VL.texmap output_amount:1.0/Pi
							environmentMap = VL.texmap
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
						--Doesn't exist. Approximating with a cylinder (!)
						AL.shapeType = 5
						if VL.size0.controller!= undefined then
						(
							AL.lightRadius.controller = copy VL.size0.controller
							AL.height.controller = copy VL.size0.controller
							for k in AL.height.controller.keys do k.value=sqrt(pi*k.value*k.value)
						)
						else
						(
							AL.lightRadius=VL.size0
							AL.height=sqrt(pi*VL.size0*VL.size0)
						)
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
						try (AL.lightRadius.controller = copy VL.size0.controller) catch (AL.lightRadius = VL.size0)
					)
				)
			)
			VRayIES :
			(
				--Set to Photometric light
				AL.shapeType = 7				
				--filename
				AL.on = VL.enabled
				AL.filename = VL.ies_file				
				--Transforms
				try (AL.transform.controller = copy VL.transform.controller) catch (AL.transform = VL.transform)
				--Target
				if VL.targeted do 
				(
					VL.targeted=true
					try (AL.target.transform.controller = copy VL.target.transform.controller) catch (AL.target.transform=VL.target.transform)
				)
				--Color
				--Set the VL's color mode to color, not temperature, for easier conversion
				VL.color_mode=0
				try (AL.color.controller = copy VL.color.controller) catch (AL.color = VL.color)
				--Intensity
				--Set the VL to lm units, then convert with 945.2486:1 towards the AL.
				if VL.intensity_value.controller != undefined then
				(
					AL.intensity.controller = copy VL.intensity_value.controller
					for k in AL.intensity.controller.keys do k.value/=945.2486
				)
				else
				(
					AL.intensity = VL.intensity_value/945.2486
				)
-- 				AL.photometricRadius = 10 --no equivalent?
				--Influences
				AL.diffuse = if VL.affect_diffuse then 1 else 0
				AL.specular = if VL.affect_specular then 1 else 0
				AL.cast_shadows = VL.cast_shadows
			)
			VRayAmbientLight :
			(
				-- no equivalent?
			)
			VRaySun :
			(
				--?
			)
			default :
			(
				append leftOverLights VL
			)
		)
		
		try (
				try (AL.parent = VL.parent) catch()
-- 				replaceinstances VL AL
				try (delete VL) catch()
			) 
		catch 
			(
				append leftOverLights VL
				try (delete AL) catch ()
			)
	)
	
	fn convertVRayCamera VRC =
	(
		PC = physical_Camera name:(uniquename (VRC.name + "_Converted_"))
		try (PC.transform.controller = copy VRC.transform.controller) catch (PC.transform = VRC.transform)
		if VRC.targeted do
		(
			PC.targeted=true
			try (PC.target.transform.controller = copy VRC.target.transform.controller) catch (PC.target.transform = VRC.target.transform)
		)
		try (PC.parent=VRC.parent) catch()

		--procedurally copy over animation or values, where property names match
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
	
	

	fn convertAllSceneMaterials =
	(
		ts=timestamp()
		print "Processing Materials"
		-- ALWAYS join composited materials for last, lest they won't get converted!
		allMats = (getClassInstances vrayMtl)
		join allMats (getClassInstances vrayLightMtl)
		join allMats (getClassInstances VrayFastSSS2)		
		join allMats (getClassInstances VRay2SidedMtl)
		join allMats (getClassInstances VRayBlendMtl)


		for m in allMats do convertVrayMtl m true --convertVrayMtl inMaterial useADMaterials
		
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
		allLights = for l in lights where classof l != targetobject and classOf l == VRayLight collect l
		join allLights (for l in lights where classof l != targetobject and classOf l == VRayIES collect l)
		join allLights (for l in lights where classof l != targetobject and classOf l == VRayAmbientLight collect l)
		join allLights (for l in lights where classof l != targetobject and classOf l == VRaySun collect l)
		
		for l in allLights do
		(
			convertVRayLight l
		)
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
		print "Processing Cameras"
		allCameras = for c in cameras where classof c == vrayPhysicalCamera collect c
		print allCameras
		for c in allCameras do convertVRayCamera c	
	)
	
	fn switchToArnold =
	(
		renderers.production = Arnold()
		renderers.production.legacy_3ds_max_map_support = true
		renderers.current.env_mode = 1
		renderers.current.env_adv_ibl_multiplier = 1/Pi
	)
	
	fn switchToCreateMode onOff = 
	(
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
	
	
-- 	suspendEditing() --this is like moving to the creation panel, in that it doesn't update the UI, regardless of what's active in the UI. new from max 7, i think. First time i use it! :P
	switchToCreateMode on
	switchToArnold()
	convertAllSceneMaterials()
	convertAllSceneLights()
	convertAllVRayCameras()
	switchToCreateMode off
-- 	resumeEditing()
)
-- scenematerials.count
-- meditmaterials[1]=(getclassinstances vrayBlendMtl)[10]
-- meditmaterials[7]=(for m in (getclassinstances AI_mix_shader) where m.name== "metal_dark_anizo_Converted001" collect m)[1]
-- meditmaterials[1]=physicalMaterial()

-- show (ai_two_sided())
-- show (vrayMtl())
-- 	
-- 				for l in lights where classof l == targetSpot do l.enabled = on	