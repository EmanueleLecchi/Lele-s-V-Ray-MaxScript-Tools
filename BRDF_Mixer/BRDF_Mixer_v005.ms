/*
To Do: 
	*check https://disney-animation.s3.amazonaws.com/library/s2012_pbs_disney_brdf_notes_v2.pdf page 15 for layers' parameters		------- mostly useless now. some was grabbed, some not. mostly arbitrary and perceptual anyway, save a precious few bits of info
	*add textures rollout
	*add preset manager rollout
	
Current Bugs:
ticking off "emit GI" for the wrapper of the emissive material changes the look of the SSS (which would make sense IF the sss was inside the wrapper, or the wrapper had any influence on the shading at all.)
Notice that to support blending amounts textures, i had to make the standard, untextured blending of the layers depend on the 8bit color construct (which i am feeding normal float fractions to, but it quantizes nevertheless), whereas before it was computed fully in float through the vray color texture rgb_multiplier. 
*/

plugin material BRDF_Mixer
name:"BRDF Mixer"
classID:#(0x7ec7e5f7, 0x77351a94)
extends:VRayBlendMtl replaceUI:true version:1
(
	--plugin-wide Variable and Functions declaration
	local params, texRoll
	local isEnergyPreserving=true

	/* Returns the material that owns this instance           *********Tijn**********				*/ 
	fn getOwner =
	(
		local deps = for m in (refs.dependents delegate) where classOf m == BRDF_Mixer collect m
		if deps.count == 0 then undefined else deps[1]	
	)
	/* Returns the name of the material that owns this instance           *********Tijn**********				*/ 
	fn getOwnerName =
	(
		local owner = getOwner()
		if owner == undefined then "" else owner.name
	)
	
	fn reshreshInfluences = 
	(
-- 		print "refreshed"
		ly1=params.chk1.state
		ly2=params.chk2.state
		ly3=params.chk3.state
		ly4=params.chk4.state
		ly5=params.chk5.state
		ly6=params.chk6.state
		ly7=params.chk7.state
		ly8=params.chk8.state
		ly9=params.chk9.state
		
		sssAmt=params.sssAmtS.value
		sheenAmt=params.sheenAmtS.value
		diffuseAmt=params.diffuseAmtS.value
		metallicAmt=params.metallicAmtS.value
		specAmt=params.specAmtS.value
		anisoAmt=params.anisoAmtS.value
		gmAmt=params.gmAmtS.value
	)

	fn getConservationCoefficient inputValue =
	(
		try
		(
			dynamicFactor=1
			coefficient=0
			counter=0
			sum=0
			normalCoeff=1.0		
			amountsArray=#(params.sssAmtS.value, params.sheenAmtS.value, params.diffuseAmtS.value, params.metallicAmtS.value, params.specAmtS.value, params.anisoAmtS.value, params.gmAmtS.value)
			layersArray=#(params.chk1.checked, params.chk3.checked, params.chk4.checked, params.chk5.checked, params.chk6.checked, params.chk7.checked, params.chk8.checked )

			for i = 1 to amountsArray.count do
			(
				if (layersArray[i] ) do --and amountsArray[i]!=0.0
				(
					counter+=1
					sum+=amountsArray[i]
				)
			)
			if sum >= 1.0 and isEnergyPreserving then
			(
				normalCoeff = 1.0/sum
			)
			else
			(
				normalCoeff = sum
			)
			coefficient = inputValue*(counter / sum)*normalCoeff
		)
		catch (1)
	)
	
	fn setCCs =
	(
		layerNumsArray=#(1,3,4,5,6,7,8)
		amountsArray=#(params.sssAmtS.value, params.sheenAmtS.value, params.diffuseAmtS.value, params.metallicAmtS.value, params.specAmtS.value, params.anisoAmtS.value, params.gmAmtS.value)
		layersArray=#(params.chk1.checked, params.chk3.checked, params.chk4.checked, params.chk5.checked, params.chk6.checked, params.chk7.checked, params.chk8.checked )
		
		for i = 1 to amountsArray.count do
		(
			if (layersArray[i] ) do  --and amountsArray[i]!=0.0
			(
				if i!= 1 then
				(
-- 					print ("setting " + delegate.texmap_blend[(layerNumsArray[i])].name + " multiplier to " + (100*(getConservationCoefficient amountsArray[i])) as string)
					chanValue=255*(getConservationCoefficient amountsArray[i])
					delegate.blend[(layerNumsArray[i])-1]=color chanValue chanValue chanValue
					
				)
				else
				(
					delegate.baseMtl.diffuse_amount  = 1.0-(getConservationCoefficient amountsArray[i])
				)
			)
		)

	)
	
	parameters main rollout:params
	(
		--control-less variable declaration
		-- 	isEnergyPreserving type:#boolean default:true
		-- Controls Declaration
		sssAmt type:#float default:1 scale:0.001 ui:sssAmtS
		sssRad type:#float default:1 scale:0.001 ui:sssRad
		sssPhase type:#Float default:0.0 scale:0.001 ui:sssPhase
		sssSssClr type:#color default:Yellow ui:sssSssClr
		sssSctClr type:#color default:Yellow ui:sssSctClr	  
		sssScl type:#float default:1 scale:0.001 ui:sssScl
		  
		refractionAmt type:#float default:1 scale:0.001 ui:refractionAmt
		refractionClr type:#color default:White ui:refractionClr
		refractionIor type:#float default:1.4 scale:0.001 ui:refractionIor
		refractionRoughness type:#float default:0 scale:0.001 ui:refractionRoughness 
		refractionDispersion type:#boolean default:false ui:refractionDispersion
		refractionAbbe type:#float default:1 scale:0.001 ui:refractionAbbe
		  
		sheenAmt type:#float default:1 scale:0.001 ui:sheenAmtS
		sheenClr type:#color default:White ui:sheenClr
		sheenIor type:#float default:1.6 scale:0.001 ui:sheenIor

		diffuseAmt type:#float default:1 scale:0.001 ui:diffuseAmtS
		diffuseClr type:#color default:White ui:diffuseClr
		diffuseIor type:#float default:64 scale:0.001 ui:diffuseIor
		diffuseRoughness type:#float default:.875 scale:0.001 ui:diffuseRoughness  

		metallicAmt type:#float default:1 scale:0.001 ui:metallicAmtS
		metallicClr type:#color default:White ui:metallicClr
		metallicIor type:#float default:8 scale:0.001 ui:metallicIor
		metallicCtr type:#float default:1 scale:0.001 ui:metallicCtr 
		metallicIrd type:#float default:0 scale:0.001 ui:metallicIrd

		specAmt type:#float default:1 scale:0.001 ui:specAmtS
		specCtr type:#float default:.25 scale:0.001 ui:specCtr
		specIor type:#float default:1.5 scale:0.001 ui:specIor
		specClr type:#color default:White ui:specClr
		specRoughness type:#float default:.5 scale:0.001 ui:specRoughness	

		anisoAmt type:#float default:1 scale:0.001 ui:anisoAmtS
		anisoCtr type:#float default:.25 scale:0.001 ui:anisoCtr
		anisoIor type:#float default:1.5 scale:0.001 ui:anisoIor
		anisoClr type:#color default:White ui:anisoClr
		anisoRoughness type:#float default:.5 scale:0.001 ui:anisoRoughness		
		anisoStretch type:#float default:.5 scale:0.001 ui:anisoStretch	
		anisoRot type:#float default:0 scale:0.1 ui:anisoRot
		anisoAxisX type:#boolean default:true ui:anisoAxisX
		anisoAxisY type:#boolean default:false ui:anisoAxisY	
		anisoAxisZ type:#boolean default:false ui:anisoAxisZ
		anisoAxisUV type:#boolean default:false ui:anisoAxisUV 
		anisoUVChannel type:#integer default:1 scale:1 ui:anisoUVChannel

		gmAmt type:#float default:1 scale:0.001 ui:gmAmtS
		gmIor type:#float default:2 scale:0.001 ui:gmIor
		gmClr type:#color default:White ui:gmClr
		gmRoughness type:#float default:.35 scale:0.001 ui:gmRoughness

		emAmt type:#float default:1 scale:0.001 ui:emAmt
		emInt type:#float default:1 scale:0.001 ui:emInt
		emClr type:#color default:White ui:emClr
		emDl type:#boolean default:false ui:emDl	
		emGI type:#boolean default:true ui:emGI

		ly1 type:#boolean default:false ui:chk1
		ly2 type:#boolean default:false ui:chk2	
		ly3 type:#boolean default:false ui:chk3
		ly4 type:#boolean default:true ui:chk4
		ly5 type:#boolean default:false ui:chk5
		ly6 type:#boolean default:false ui:chk6
		ly7 type:#boolean default:false ui:chk7
		ly8 type:#boolean default:false ui:chk8
		ly9 type:#boolean default:false ui:chk9


		-- Behaviours Declaration
			--SSS
		on sssAmt set val do 
		(
			if ly1 do
			(
					
					delegate.baseMtl.diffuse_amount  = 1.0-(getConservationCoefficient val)
			)
		)

		on sssRad set val do delegate.baseMtl.scatter_radius  = val
		on sssPhase set val do delegate.baseMtl.phase_function  = val	
		on sssSssClr set val do delegate.baseMtl.sub_surface_color = val
		on sssSctClr set val do delegate.baseMtl.scatter_color = val	
		on sssScl set val do delegate.baseMtl.scale = val
			
			-- refraction
		on refractionAmt set val do delegate.texmap_blend_multiplier[1] = 100*val
		on refractionClr set val do delegate.coatMtl[1].texmap_refraction.color = val
		on refractionIor set val do delegate.coatMtl[1].refraction_ior = val
		on refractionRoughness set val do delegate.coatMtl[1].refraction_glossiness = 1-val
		on refractionDispersion set val do delegate.coatMtl[1].refraction_dispersion_on = val
		on refractionAbbe set val do delegate.coatMtl[1].refraction_dispersion = 150.0-(149* val)

			--Sheen
		on sheenAmt set val do
		(
			if ly3 do
			(
					chanValue=255*(getConservationCoefficient val)
					delegate.blend[2]=color chanValue chanValue chanValue
			)
		)		
		on sheenClr set val do delegate.coatMtl[2].texmap_reflection.color = val
		on sheenIor set val do delegate.coatMtl[2].refraction_ior = val


			-- Diffuse
		on diffuseAmt set val do
		(
			if ly4 do
			(
					chanValue=255*(getConservationCoefficient val)
					delegate.blend[3]=color chanValue chanValue chanValue
			)
		)		
		on diffuseClr set val do delegate.coatMtl[3].texmap_reflection.color = val
		on diffuseIor set val do delegate.coatMtl[3].refraction_ior = val
		on diffuseRoughness set val do delegate.coatMtl[3].gtr_gamma = 8.01-(val*8)
			
			-- Metallic
		on metallicAmt set val do
		(
			if ly5 do 
			(
					chanValue=255*(getConservationCoefficient val)
					delegate.blend[4]=color chanValue chanValue chanValue
			)
		)		
		on metallicClr set val do delegate.coatMtl[4].texmap_reflection.map1.color = val
		on metallicIor set val do delegate.coatMtl[4].refraction_ior = val
		on metallicCtr set val do delegate.coatMtl[4].gtr_gamma = 1+(val*8)		--------------------------------------------------<<<<<<<<<<<<<<<<<<< 
		on metallicIrd set val do delegate.coatMtl[4].texmap_reflection.mixAmount=100*val
			-- Specular
		on specAmt set val do
		(
			if ly6 do
			(
					chanValue=255*(getConservationCoefficient val)
					delegate.blend[5]=color chanValue chanValue chanValue
			)
		)
		on specCtr set val do delegate.coatMtl[5].gtr_gamma = 0.5 + (val*9.5)  -- 0.5 / 10.0
		on specIor set val do delegate.coatMtl[5].refraction_ior = val		
		on specClr set val do delegate.coatMtl[5].texmap_reflection.color = val
		on specRoughness set val do delegate.coatMtl[5].reflection_glossiness = 0.995-(val*0.85)  -- 0.145 / 0.995  			 0.995-0.85
			-- Aniso Specular
		on anisoAmt set val do
		(
			if ly7 do
			(
					chanValue=255*(getConservationCoefficient val)
					delegate.blend[6]=color chanValue chanValue chanValue
			)
		)			
		on anisoCtr set val do delegate.coatMtl[6].gtr_gamma = 0.5 + (val*9.5)  -- 0.5 / 10.0
		on anisoIor set val do delegate.coatMtl[6].refraction_ior = val		
		on anisoClr set val do delegate.coatMtl[6].texmap_reflection.color = val
		on anisoRoughness set val do delegate.coatMtl[6].reflection_glossiness = 0.995-(val*0.85)  -- 0.145 / 0.995  			 0.995-0.85
		on anisoStretch set val do delegate.coatMtl[6].anisotropy = val	
		on anisoRot set val do delegate.coatMtl[6].anisotropy_rotation = val
		on anisoAxisX set val do 
		(
			if val do
			(
				delegate.coatMtl[6].anisotropy_derivation=0
				delegate.coatMtl[6].anisotropy_axis=0
			)

		)
		on anisoAxisY set val do 
		(
			if val do
			(
				delegate.coatMtl[6].anisotropy_derivation=0
				delegate.coatMtl[6].anisotropy_axis=1
			)
		)
		on anisoAxisZ set val do 
		(
			if val do 
			(
				delegate.coatMtl[6].anisotropy_derivation=0
				delegate.coatMtl[6].anisotropy_axis=2
			)
		)
		on anisoAxisUV set val do 
		(
			if val do
			(
				delegate.coatMtl[6].anisotropy_derivation=1
				delegate.coatMtl[6].anisotropy_channel=anisoUVChannel
			)
		)
		on anisoUVChannel set val do 
		(
			delegate.coatMtl[6].anisotropy_channel=val
		)

			-- GunMetal
		on gmAmt set val do
		(
			if ly8 do 
			(
					chanValue=255*(getConservationCoefficient val)
					delegate.blend[7]=color chanValue chanValue chanValue
			)
		)			
		on gmIor set val do delegate.coatMtl[7].refraction_ior = val		
		on gmClr set val do delegate.coatMtl[7].texmap_reflection.color = val
		on gmRoughness set val do delegate.coatMtl[7].reflection_glossiness = 0.8-(val*0.4)  -- .2/ 0.6

			-- Emissive
		on emAmt set val do delegate.blend[8] =color (255*val) (255*val) (255*val)
		on emInt set val do delegate.coatMtl[8].baseMtl.multiplier = val		
		on emClr set val do delegate.coatMtl[8].baseMtl.texmap.color = val
		on emDl set val do delegate.coatMtl[8].baseMtl.directLight_on = val
		on emGI set val do delegate.coatMtl[8].generateGI = delegate.coatMtl[8].generateCaustics = val


		on ly1 set val do if val then delegate.baseMtl.overall_color=white else delegate.baseMtl.overall_color=black
		on ly2 set val do if val then delegate.blend[1]=color (255*refractionAmt) (255*refractionAmt) (255*refractionAmt)  else delegate.blend[1]=black
		on ly3 set val do if val then delegate.blend[2]=color (255*sheenAmt) (255*sheenAmt) (255*sheenAmt) else delegate.blend[2]=black
		on ly4 set val do if val then delegate.blend[3]=color (255*diffuseAmt) (255*diffuseAmt) (255*diffuseAmt) else delegate.blend[3]=black
		on ly5 set val do if val then delegate.blend[4]=color (255*metallicAmt) (255*metallicAmt) (255*metallicAmt) else delegate.blend[4]=black
		on ly6 set val do if val then delegate.blend[5]=color (255*specAmt) (255*specAmt) (255*specAmt) else delegate.blend[5]=black
		on ly7 set val do if val then delegate.blend[6]=color (255*anisoAmt) (255*anisoAmt) (255*anisoAmt) else delegate.blend[6]=black
		on ly8 set val do if val then delegate.blend[7]=color (255*gmAmt) (255*gmAmt) (255*gmAmt) else delegate.blend[7]=black
		on ly9 set val do if val then delegate.blend[8]=color (255*emAmt) (255*emAmt) (255*emAmt) else delegate.blend[8]=black		
-- 		on ly1 set val do if val then delegate.baseMtl.overall_color=white else delegate.baseMtl.overall_color=black
-- 		on ly2 set val do if val then delegate.texmap_blend[1].rgb_multiplier=1 else delegate.texmap_blend[1].rgb_multiplier=0
-- 		on ly3 set val do if val then delegate.texmap_blend[2].rgb_multiplier=1 else delegate.texmap_blend[2].rgb_multiplier=0
-- 		on ly4 set val do if val then delegate.texmap_blend[3].rgb_multiplier=1 else delegate.texmap_blend[3].rgb_multiplier=0
-- 		on ly5 set val do if val then delegate.texmap_blend[4].rgb_multiplier=1 else delegate.texmap_blend[4].rgb_multiplier=0
-- 		on ly6 set val do if val then delegate.texmap_blend[5].rgb_multiplier=1 else delegate.texmap_blend[5].rgb_multiplier=0
-- 		on ly7 set val do if val then delegate.texmap_blend[6].rgb_multiplier=1 else delegate.texmap_blend[6].rgb_multiplier=0
-- 		on ly8 set val do if val then delegate.texmap_blend[7].rgb_multiplier=1 else delegate.texmap_blend[7].rgb_multiplier=0
-- 		on ly9 set val do if val then delegate.texmap_blend[8].rgb_multiplier=1 else delegate.texmap_blend[8].rgb_multiplier=0
	)

	rollout params "BSSRDF/BRDF Layers:" width:328 height:744
	(

		GroupBox grp99 "Utilities:" pos:[8,8] width:312 height:56
		button reBtn "Make Render Elements" pos:[16,24] width:120 height:32
		button spitBtn "Extract Material Copy" pos:[140,24] width:120 height:32
		checkbutton epBtn "Cons." pos:[264,24] width:40 height:32 checked:true	highlightcolor:Gray

		GroupBox grp1 "SubSurface-Scattering:" pos:[8,72] width:312 height:64
		spinner sssAmtS "" pos:[56,88] width:48 height:16 range:[0,1,0.01] type:#float scale:0.01 
		spinner sssRad "" pos:[176,88] width:48 height:16 range:[1e-005,100000,0.01] type:#float scale:0.01  	
		spinner sssPhase "" pos:[264,88] width:48 height:16 range:[-1,1,0.01] type:#float scale:0.01 	
		colorPicker sssSssClr "" pos:[56,112] width:48 height:20 color:(color 0 0 155)
		colorPicker sssSctClr "" pos:[176,112] width:48 height:20 color:(color 0 0 155)
		spinner sssScl "" pos:[264,112] width:48 height:16 range:[1e-005,100000,0.01] type:#float scale:0.01
		label lbl1 "Amt." pos:[16,88] width:24 height:16
		label lbl2 "Radius" pos:[120,88] width:32 height:16
		label lbl3 "Phase" pos:[232,88] width:32 height:16	  
		label lbl4 "SSS Clr." pos:[16,112] width:40 height:16	
		label lbl5 "Scatter Clr." pos:[120,112] width:56 height:16
		label lbl6 "Scl." pos:[240,112] width:16 height:16	  
		  
		GroupBox grp2 "Refraction:" pos:[8,144] width:312 height:64
		spinner refractionAmt "" pos:[56,160] width:48 height:16 range:[0,1,0.01] type:#float scale:0.01 
		spinner refractionRoughness "" pos:[176,160] width:48 height:16 range:[0,1,2] type:#float scale:0.01 		
		spinner refractionIor "" pos:[264,160] width:48 height:16 range:[1.001,1024,0.01] type:#float scale:0.01 
		colorPicker refractionClr "" pos:[56,184] width:48 height:20 color:(color 0 0 155)
		checkbox refractionDispersion "" pos:[176,184] checked:false
		spinner refractionAbbe "" pos:[264,184] width:48 height:16 range:[0,1,0.01] type:#float scale:0.01 		
		
		label lbl7 "Amt." pos:[16,160] width:24 height:16
		label lbl8 "Roughness" pos:[112,160] width:52 height:16  	
		label lbl9 "IoR" pos:[240,160] width:16 height:16	
		label lbl10 "Clr." pos:[16,184] width:24 height:16
		label lbl45 "Dispersive" pos:[112,184] width:52 height:16  	
		label lbl46 "Disp. Amt." pos:[208,184] width:52 height:16	
		
		GroupBox grp3 "Sheen:" pos:[8,216] width:312 height:40	
		spinner sheenAmtS "" pos:[56,232] width:48 height:16 range:[0,1,0.01] type:#float scale:0.01 fieldwidth:42
		colorPicker sheenClr "" pos:[176,232] width:48 height:20 
		spinner sheenIor "" pos:[264,232] width:48 height:16 range:[1.001,100,0.01] type:#float scale:0.01 fieldwidth:42
		label lbl11 "Amt." pos:[16,232] width:24 height:16
		label lbl12 "Clr." pos:[152,232] width:24 height:16
		label lbl13 "IoR" pos:[240,232] width:16 height:16 


		GroupBox grp4 "Diffuse:" pos:[8,264] width:312 height:64	  
		spinner diffuseAmtS "" pos:[56,280] width:48 height:16 range:[0,1,0.01] type:#float scale:0.01 fieldwidth:42
		colorPicker diffuseClr "" pos:[56,304] width:48 height:20 
		spinner diffuseIor "" pos:[264,280] width:48 height:16 range:[1.001,1024,0.01] type:#float scale:0.01 fieldwidth:42
		spinner diffuseRoughness "" pos:[176,280] width:48 height:16 range:[0,1,2] type:#float scale:0.01 fieldwidth:42
		label lbl14 "Amt." pos:[16,280] width:24 height:16
		label lbl15 "Roughness" pos:[112,280] width:52 height:16  	
		label lbl16 "IoR" pos:[240,280] width:16 height:16
		label lbl17 "Clr." pos:[16,304] width:24 height:16

		GroupBox grp5 "Metallic:" pos:[8,336] width:312 height:64
		spinner metallicAmtS "" pos:[56,352] width:48 height:16 range:[0,1,0.01] type:#float scale:0.01 fieldwidth:42
		spinner metallicIor "" pos:[264,352] width:48 height:16 range:[1.001,100,0.01] type:#float scale:0.01 fieldwidth:42
		spinner metallicCtr "" pos:[176,352] width:48 height:16 range:[0,1,0.01] type:#float scale:0.01 fieldwidth:42
		colorPicker metallicClr "" pos:[56,376] width:48 height:20 
		spinner metallicIrd "" pos:[264,376] width:48 height:16 range:[0,1,0.01] type:#float scale:0.01 fieldwidth:42
		label lbl18 "Amt." pos:[16,352] width:24 height:16
		label lbl19 "Contrast" pos:[120,352] width:48 height:16
		label lbl20 "IoR" pos:[240,352] width:16 height:16
		label lbl21 "Clr." pos:[16,376] width:24 height:16
		label lbl44 "Cheap Thin Film" pos:[176,376] width:80 height:16

		GroupBox grp6 "ISOTropic Specular:" pos:[8,408] width:312 height:64	  
		spinner specAmtS "" pos:[56,424] width:48 height:16 range:[0,1,0.01] type:#float scale:0.01 fieldwidth:42
		spinner specRoughness "" pos:[176,424] width:48 height:16 range:[0,1,2] type:#float scale:0.01 fieldwidth:42
		spinner specIor "" pos:[264,424] width:48 height:16 range:[1.001,100,0.01] type:#float scale:0.01 fieldwidth:42
		colorPicker specClr "" pos:[56,448] width:48 height:20 	
		spinner specCtr "" pos:[176,448] width:48 height:16 range:[0,1,0.01] type:#float scale:0.01 fieldwidth:42	
		label lbl22 "Amt." pos:[16,424] width:24 height:16
		label lbl23 "Roughness" pos:[112,424] width:52 height:16
		label lbl24 "IoR" pos:[240,424] width:16 height:16	
		label lbl25 "Clr." pos:[16,448] width:24 height:16
		label lbl26 "Contrast" pos:[120,448] width:48 height:16

		GroupBox grp7 "ANISOTropic Specular:" pos:[8,480] width:312 height:112	  
		spinner anisoAmtS "" pos:[56,496] width:48 height:16 range:[0,1,0.01] type:#float scale:0.01 fieldwidth:42
		spinner anisoRoughness "" pos:[176,496] width:48 height:16 range:[0,1,2] type:#float scale:0.01 fieldwidth:42
		spinner anisoIor "" pos:[264,496] width:48 height:16 range:[1.001,100,0.01] type:#float scale:0.01 fieldwidth:42
		colorPicker anisoClr "" pos:[56,520] width:48 height:20 	
		spinner anisoCtr "" pos:[176,520] width:48 height:16 range:[0,1,0.01] type:#float scale:0.01 fieldwidth:42	
		spinner anisoStretch "" pos:[56,544] width:48 height:16 range:[-1,1,0.5] type:#float scale:0.01 fieldwidth:42	
		spinner anisoRot "" pos:[176,544] width:48 height:16 range:[-360,360,0] type:#float fieldwidth:42	
		spinner anisoUVChannel "" pos:[176,568] width:48 height:16 range:[0,100,1] type:#integer fieldwidth:42
		checkbutton anisoAxisX "X" pos:[16,568] width:16 height:16 checked:true
		checkbutton anisoAxisY "Y" pos:[36,568] width:16 height:16 checked:false
		checkbutton anisoAxisZ "Z" pos:[54,568] width:16 height:16 checked:false
		checkbutton anisoAxisUV "UV" pos:[80,568] width:24 height:16 checked:false
		label lbl27 "Amt." pos:[16,496] width:24 height:16
		label lbl28 "Roughness" pos:[112,496] width:52 height:16
		label lbl29 "IoR" pos:[240,496] width:16 height:16	
		label lbl30 "Clr." pos:[16,520] width:24 height:16
		label lbl31 "Contrast" pos:[120,520] width:48 height:16
		label lbl32 "Stretch" pos:[14,544] width:40 height:16
		label lbl33 "Rotation" pos:[120,544] width:40 height:16
		label lbl34 "UV Ch" pos:[128,568] width:32 height:16

		GroupBox grp8 "GunMetal" pos:[8,600] width:312 height:64
		spinner gmAmtS "" pos:[56,616] width:48 height:16 range:[0,1,0.01] type:#float scale:0.01 fieldwidth:42
		spinner gmRoughness "" pos:[176,616] width:48 height:16 range:[0,1,2] type:#float scale:0.01 fieldwidth:42
		spinner gmIor "" pos:[264,616] width:48 height:16 range:[1.001,100,0.01] type:#float scale:0.01 fieldwidth:42
		colorPicker gmClr "" pos:[56,640] width:48 height:20 color:(color 0 0 155)
		label lbl35 "Amt." pos:[16,616] width:24 height:16
		label lbl36 "Roughness" pos:[112,616] width:52 height:16
		label lbl37 "IoR" pos:[240,616] width:16 height:16
		label lbl38 "Clr." pos:[16,640] width:24 height:16

		GroupBox grp28 "Emissive:" pos:[8,672] width:312 height:64
		spinner emAmt "" pos:[56,688] width:48 height:16 range:[0,1,0.01] type:#float scale:0.01 fieldwidth:42
		spinner emInt "" pos:[176,688] width:48 height:16 range:[0,1e+007,1] type:#float scale:0.01 fieldwidth:42
		colorPicker emClr "" pos:[264,688] width:48 height:20 color:(color 0 0 155)
		checkbox emDl "" pos:[92,712] width:16 height:16
		checkbox emGI "" pos:[212,712] width:16 height:16	
		label lbl39 "Amt." pos:[16,688] width:24 height:16
		label lbl40 "Intensity" pos:[120,688] width:48 height:16
		label lbl41 "Clr." pos:[240,688] width:24 height:16
		label lbl42 "Emit Direct" pos:[16,712] width:56 height:16
		label lbl43 "Emit Gi" pos:[160,712] width:40 height:16

		checkbox chk1 "" pos:[136,72] width:16 height:16 checked:false
		checkbox chk2 "" pos:[80,144] width:16 height:16 checked:false
		checkbox chk3 "" pos:[56,216] width:16 height:16 checked:false
		checkbox chk4 "" pos:[64,264] width:16 height:16 checked:true
		checkbox chk5 "" pos:[64,336] width:16 height:16 checked:false
		checkbox chk6 "" pos:[120,408] width:16 height:16 checked:false
		checkbox chk7 "" pos:[128,480] width:16 height:16 checked:false
		checkbox chk8 "" pos:[120,600] width:16 height:16 checked:false	
		checkbox chk9 "" pos:[120,672] width:16 height:16 checked:false	






		on params open do
		(
			reshreshInfluences()
		-- 		setCCs()
		)

		on epBtn changed state do 
		(
			isEnergyPreserving = state
			if state then epBtn.caption="Cons." else epBtn.caption="Disp."
			reshreshInfluences()
			setCCs()
		)

		on sssAmtS changed val do
		(
			reshreshInfluences()
			setCCs()		
		)
		on sheenAmtS changed val do
		(
			reshreshInfluences()
			setCCs()		
		)
		on diffuseAmtS changed val do
		(
			reshreshInfluences()
			setCCs()		
		)
		on metallicAmtS changed val do
		(
			reshreshInfluences()
			setCCs()		
		)
		on specAmtS changed val do
		(
			reshreshInfluences()
			setCCs()		
		)
		on anisoAmtS changed val do
		(
			reshreshInfluences()
			setCCs()		
		)
		on gmAmtS changed val do
		(
			reshreshInfluences()
			setCCs()		
		)



		on chk1 changed state do
		(
			reshreshInfluences()
			setCCs()
		)
		on chk2 changed state do
		(
			reshreshInfluences()
			setCCs()
		)
		on chk3 changed state do
		(
			reshreshInfluences()
			setCCs()
		)
		on chk4 changed state do
		(
			reshreshInfluences()
			setCCs()
		)
		on chk5 changed state do
		(
			reshreshInfluences()
			setCCs()
		)
		on chk6 changed state do
		(
			reshreshInfluences()
			setCCs()
		)
		on chk7 changed state do
		(
			reshreshInfluences()
			setCCs()
		)
		on chk8 changed state do
		(
			reshreshInfluences()
			setCCs()
		)
		on chk9 changed state do
		(
			reshreshInfluences()
			setCCs()
		)
		on anisoAxisX changed state do
		(
		  if state do
		  (
			anisoAxisY.checked=anisoAxisZ.checked=anisoAxisUV.checked=off  
		  )
		)
		on anisoAxisY changed state do
		(
		  if state do
		  (
			anisoAxisX.checked=anisoAxisZ.checked=anisoAxisUV.checked=off  
		  )
		)
		on anisoAxisZ changed state do
		(
		  if state do
		  (
			anisoAxisX.checked=anisoAxisY.checked=anisoAxisUV.checked=off  
		  )
		)
		on anisoAxisUV changed state do
		(
		  if state do
		  (
			anisoAxisX.checked=anisoAxisY.checked=anisoAxisZ.checked=off  
		  )
		)
		on reBtn pressed do
		(
			-- get the base name for the elements			*********Tijn**********
			local ownerName = getOwnerName()
			local elementBaseName = "BRDFMxr_" + ownerName
			if ownerName.count > 0 do append elementBaseName "_"
			
			local re = maxOps.GetCurRenderElementMgr()
			local elementNames = #(elementBaseName + delegate.baseMtl.name)
			for i = 1 to 8 do
				append elementNames (elementBaseName + delegate.coatMtl[i].name)

			-- insert delete part here: find by name part and wipe		
			for n = (re.numRenderElements() - 1) to 0 by -1 do
			(
				el = re.getRenderElement n
				for elementName in elementNames where
					el.elementName == elementName do 
				(
					re.RemoveRenderElement el
				)
			)

			--add 5 mtlSelect REs 
				--base
				theElement = VrayMtlSelect() 
				theElement.material = delegate.baseMtl
				theElement.elementName=elementNames[1]
				re.AddRenderElement theElement
				-- 4 coats  
			for i=1 to 8 do 
			(
				theElement = VrayMtlSelect()
				theElement.material = delegate.coatMtl[i]
				theElement.elementName=elementNames[i+1]
				re.AddRenderElement theElement
			)
		)
		on spitBtn pressed do
		(
			
			meditmaterials[24]=copy delegate
			meditmaterials[24].name= "Extracted_"+(getOwnerName())
		)
	)  
	
	rollout texRoll "Layers' Texture Mapping:" width:328 height:960 rolledUp:true
	(
		GroupBox grp99 "Utilities:" pos:[8,8] width:312 height:56
		button reBtn "Wipe All Textures" pos:[16,24] width:296 height:32
	
		GroupBox grp1 "SubSurface-Scattering:" pos:[8,72] width:312 height:120
		mapButton sssAmtTxb "None" pos:[168,88] width:144 height:16
		mapButton sssRadTxb "None" pos:[168,108] width:144 height:16
		mapButton sssPhaseTxb "None" pos:[168,128] width:144 height:16
		mapButton sssSSSClrTxb "None" pos:[168,148] width:144 height:16
		mapButton sssSctClrTxb "None" pos:[168,168] width:144 height:16
		label lbl1 "Amt." pos:[16,88] width:24 height:16
		label lbl2 "Radius" pos:[16,108] width:32 height:16
		label lbl3 "Phase" pos:[16,128] width:32 height:16	  	  
		label lbl4 "SSS Clr." pos:[16,148] width:40 height:16	
		label lbl5 "Scatter Clr." pos:[16,168] width:56 height:16
		
		GroupBox grp2 "Refraction:" pos:[8,192] width:312 height:100
		mapButton refractionAmtTxb "None" pos:[168,208] width:144 height:16
		mapButton refractionRoughnessTxb "None" pos:[168,228] width:144 height:16
		mapButton refractionIorTxb "None" pos:[168,248] width:144 height:16
		mapButton refractionClrTxb "None" pos:[168,268] width:144 height:16
		label lbl6 "Amt." pos:[16,208] width:24 height:16
		label lbl7 "Roughness" pos:[16,228] width:52 height:16  	
		label lbl8 "IoR" pos:[16,248] width:16 height:16	
		label lbl9 "Clr." pos:[16,268] width:24 height:16
  			
		GroupBox grp3 "Sheen:" pos:[8,292] width:312 height:80	
		mapButton sheenAmtTxb "None" pos:[168,308] width:144 height:16
		mapButton sheenIorTxb "None" pos:[168,328] width:144 height:16
		mapButton sheenClrTxb "None" pos:[168,348] width:144 height:16
		label lbl10 "Amt." pos:[16,308] width:24 height:16
		label lbl11 "Clr." pos:[16,328] width:24 height:16
		label lbl12 "IoR" pos:[16,348] width:16 height:16 
		
		GroupBox grp4 "Diffuse:" pos:[8,372] width:312 height:80
		mapButton diffuseAmtTxb "None" pos:[168,388] width:144 height:16
		mapButton diffuseIorTxb "None" pos:[168,408] width:144 height:16
		mapButton diffuseClrTxb "None" pos:[168,428] width:144 height:16
		label lbl13 "Amt." pos:[16,388] width:24 height:16
		label lbl14 "IoR" pos:[16,408] width:16 height:16
		label lbl15 "Clr." pos:[16,428] width:24 height:16
		
		GroupBox grp5 "Metallic:" pos:[8,452] width:312 height:80
		mapButton metallicAmtTxb "None" pos:[168,468] width:144 height:16
		mapButton metallicIorTxb "None" pos:[168,488] width:144 height:16
		mapButton metallicClrTxb "None" pos:[168,508] width:144 height:16
		label lbl16 "Amt." pos:[16,468] width:24 height:16
		label lbl17 "IoR" pos:[16,488] width:16 height:16
		label lbl18 "Clr." pos:[16,508] width:24 height:16

		GroupBox grp6 "ISOTropic Specular:" pos:[8,532] width:312 height:96 
		mapButton specAmtTxb "None" pos:[168,544] width:144 height:16
		mapButton specRoughnessTxb "None" pos:[168,564] width:144 height:16
		mapButton specIorTxb "None" pos:[168,584] width:144 height:16
		mapButton specClrTxb "None" pos:[168,604] width:144 height:16
		label lbl19 "Amt." pos:[16,544] width:24 height:16
		label lbl20 "Roughness" pos:[16,564] width:52 height:16
		label lbl21 "IoR" pos:[16,580] width:16 height:16	
		label lbl22 "Clr." pos:[16,604] width:24 height:16
		
		GroupBox grp7 "ANISOTropic Specular:" pos:[8,628] width:312 height:140	  
		mapButton anisoAmtTxb "None" pos:[168,644] width:144 height:16
		mapButton anisoRoughnessTxb "None" pos:[168,664] width:144 height:16
		mapButton anisoIorTxb "None" pos:[168,684] width:144 height:16
		mapButton anisoClrTxb "None" pos:[168,704] width:144 height:16
		mapButton anisoStretchTxb "None" pos:[168,724] width:144 height:16
		mapButton anisoRotTxb "None" pos:[168,744] width:144 height:16
		label lbl23 "Amt." pos:[16,644] width:24 height:16
		label lbl24 "Roughness" pos:[16,664] width:52 height:16
		label lbl25 "IoR" pos:[16,684] width:16 height:16	
		label lbl26 "Clr." pos:[16,704] width:24 height:16
		label lbl27 "Stretch" pos:[16,726] width:40 height:16
		label lbl28 "Rotation" pos:[16,744] width:40 height:16

		GroupBox grp8 "GunMetal" pos:[8,768] width:312 height:98
		mapButton gmAmtTxb "None" pos:[168,782] width:144 height:16
		mapButton gmRoughnessTxb "None" pos:[168,802] width:144 height:16
		mapButton gmIorTxb "None" pos:[168,822] width:144 height:16
		mapButton gmClrTxb "None" pos:[168,842] width:144 height:16 
		label lbl29 "Amt." pos:[16,782] width:24 height:16
		label lbl30 "Roughness" pos:[16,802] width:52 height:16
		label lbl31 "IoR" pos:[16,822] width:16 height:16
		label lbl32 "Clr." pos:[16,842] width:24 height:16	

		GroupBox grp28 "Emissive:" pos:[8,866] width:312 height:60
		mapButton emAmtTxb "None" pos:[168,882] width:144 height:16
		mapButton emClrTxb "None" pos:[168,902] width:144 height:16
		label lbl33 "Amt." pos:[16,882] width:24 height:16
		label lbl34 "Clr." pos:[16,902] width:24 height:16	
		
		on diffuseAmtTxb picked texmap do
		(
				delegate.texmap_blend[3]=texmap
				diffuseAmtTxb.caption=texmap.name
		)
		
	)


	
	
	on create do
	(
		delegate.additiveMode = on
		for i=1 to delegate.Blend.count do 
		(
			delegate.blend[i]=black
-- 			delegate.texmap_blend[i]=VrayColor color:white name:("white_colour" + i as string)
-- 			delegate.texmap_blend[i].rgb_multiplier=1
			delegate.texmap_blend_multiplier[i]=100
		)

		-- setup initial materials creation. Properties settings comes later on.
		delegate.baseMtl=VrayFastSSS2 name:"SubSurface-Scattering" 		--fastSSS2 - marble - raytraced
		m0=delegate.baseMtl
		delegate.coatMtl[1]=VrayMtl name:"Refraction"					--gtr gamma 2
		m1=delegate.coatMtl[1]	
		delegate.coatMtl[2]=VrayMtl name:"Sheen"					--gtr gamma 0.05 gloss 0.35
		m2=delegate.coatMtl[2]
		delegate.coatMtl[3]=VrayMtl name:"Diffuse"					--gtr gamma 1 gloss 0.15
		m3=delegate.coatMtl[3]
		delegate.coatMtl[4]=VrayMtl name:"Metallic"					--gtr gamma 10 gloss 0.85
		m4=delegate.coatMtl[4]	 
		delegate.coatMtl[5]=VrayMtl name:"Specular"					--gtr gamma 2 gloss 0.85
		m5=delegate.coatMtl[5]	 	
		delegate.coatMtl[6]=VrayMtl name:"Anisotropic"					--gtr gamma 2 gloss 0.85
		m6=delegate.coatMtl[6]	 
		delegate.coatMtl[7]=VrayMtl name:"GunMetal"					--gtr gamma 2 gloss 0.85
		m7=delegate.coatMtl[7]
		lMat=VrayLightMtl name:"EmissiveLightMtl" 
		oMat=VrayMtlWrapper name:"Emissive"
		oMat.baseMtl=lMat
		delegate.coatMtl[8]=oMat					--gtr gamma 2 gloss 0.85
		m8=delegate.coatMtl[8]


		-- per material setups
		m0.preset=6									--SSS
		m0.diffuse_color=Black
		m0.specular_amount=0
		sssSssClr=m0.sub_surface_color
		sssSctClr=m0.scatter_color
		sssRad=m0.scatter_radius
		sssScl=m0.scale
		sssPhase=m0.phase_function
		m0.diffuse_amount  = 1.0-sssAmt 

		m1.brdf_type=4								--Refraction
		m1.diffuse=black
		m1.texmap_refraction=vrayColor()
		m1.texmap_refraction.color=refractionClr
		m1.refraction_ior=refractionIor
		m1.refraction_glossiness=0.995-(refractionRoughness*0.85) 
		m1.gtr_gamma=2
		m1.option_cutoff=0.0	
		m1.refraction_affectShadows = on

		m2.brdf_type=4  							--Sheen
		m2.diffuse=black
		m2.texmap_reflection=vrayColor()
		m2.texmap_reflection.color=sheenClr
		m2.refraction_ior=sheenIor
		m2.reflection_glossiness=0.35
		m2.gtr_gamma=0.05
		m2.option_cutoff=0.0

		m3.brdf_type=4								--Diffuse
		m3.diffuse=black
		m3.texmap_reflection=vrayColor()
		m3.texmap_reflection.color=diffuseClr
		-- 	m3.texmap_reflection.rgb_multiplier=3.1415
		m3.refraction_ior=diffuseIor
		m3.gtr_gamma=8.01-(diffuseRoughness*8)
		m3.reflection_glossiness=.075
		m3.option_cutoff=0.0

		m4.brdf_type=4								--Metallic
		m4.diffuse=black
		si1=vraysamplerInfoTex type:2 coord_system:2 output:1
		s12=vraysamplerInfoTex type:3 coord_system:2 output:1 refract_ior:100
		vct=vrayCompTex operator:1 sourceA:si1 sourceB:si2
		m4.texmap_reflection=mix map1:(vrayColor color:white) map2:vct
		m4.texmap_reflection.mixAmount=0
		m4.texmap_reflection.map1.color=metallicClr
		m4.refraction_ior=metallicIor
		m4.reflection_glossiness=.9
		m4.gtr_gamma=1	+(8*metallicCtr)
		m4.option_cutoff=0.0

		m5.brdf_type=4								-- iso Spec
		m5.diffuse=black
		m5.texmap_reflection=vrayColor()
		m5.texmap_reflection.color=specClr
		m5.refraction_ior=specIor
		m5.reflection_glossiness=0.995-(specRoughness*0.85) 
		m5.gtr_gamma=0.5 + (specCtr*9.5)
		m5.option_cutoff=0.0

		m6.brdf_type=4									--aniso Spec
		m6.diffuse=black
		m6.texmap_reflection=vrayColor()
		m6.texmap_reflection.color=anisoClr
		m6.refraction_ior=anisoIor
		m6.reflection_glossiness=0.995-(anisoRoughness*0.85) 
		m6.gtr_gamma=0.5 + (anisoCtr*9.5)
		m6.option_cutoff=0.0
		m6.anisotropy = anisoStretch
		m6.anisotropy_rotation= anisoRot

		m7.brdf_type=4										--Gunmetal
		m7.diffuse=black
		m7.texmap_reflection=vrayColor()
		m7.texmap_reflection.color=gmClr
		m7.refraction_ior=gmIor
		m7.reflection_glossiness = 0.8-(gmRoughness*0.4) 	
		m7.gtr_gamma=1
		m7.option_cutoff=0.0

		m8.baseMtl.texmap = VrayColor color:white 			--Emissive
		m8.baseMtl.multiplier = emInt
		m8.baseMtl.directLight_on = emDl
		m8.generateGI = m8.generateCaustics = emGi
		m8.baseMtl.compensate_exposure = on
	)
  
)
