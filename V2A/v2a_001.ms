(
	/*
	"Simple" scene converter from V-Ray to Arnold
	Lights: they should all be translatable, minus perhaps a few inferred properties (f.e. exposure in A's).
	Materials: Translate to PhysicalMaterial.
	Maps: most should be directly pluggable at the root. This may turn out to be the most laborious part, however.
	*/

	local allMats = #()
	local leftOverMats = #()
	
	fn convertMap inMap =
	(
		
	)
	
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
	
	fn convertVrayMtl parentMat useADMaterials =
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
						ALM.emit_luminance = parentMat.multiplier*477.464 --Image multiplier to Luminance
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
						if parentMat.backMtlOn do A2S.back = parentMat.backMtl
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
				-- converto to Arnold Shaders only (AI_Surface etc.)
			)
		)
	)
	
	
	fn convertAllSceneMaterials =
	(
		ts=timestamp()
		-- ALWAYS join composited materials for last, lest they won't get converted!
		allMats = (getClassInstances vrayMtl)
		join allMats (getClassInstances vrayLightMtl)
		join allMats (getClassInstances VrayFastSSS2)		
		join allMats (getClassInstances VRay2SidedMtl)
		join allMats (getClassInstances VRayBlendMtl)


		for m in allMats do convertVrayMtl m true
		
		totTime=(timeStamp()-ts)/1000.
		print ("It took " + totTime as string + "s. to convert " + allMats.count as string + " Materials")
		if leftOverMats.count > 0 then 
			(
				print ("A total of " + leftOverMats.count as string + " materials were not converted")
				print leftOverMats
			)
		else print "All materials were converted."
	)
	
	convertAllSceneMaterials()
)
-- scenematerials.count
-- meditmaterials[1]=(getclassinstances vrayBlendMtl)[10]
-- meditmaterials[7]=(for m in (getclassinstances AI_mix_shader) where m.name== "metal_dark_anizo_Converted001" collect m)[1]
-- meditmaterials[1]=physicalMaterial()

-- show (ai_two_sided())
-- show (vrayMtl())
-- 	
	