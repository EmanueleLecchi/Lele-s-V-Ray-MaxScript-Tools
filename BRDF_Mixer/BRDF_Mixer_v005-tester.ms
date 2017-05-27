/*
To Do: 
	*check https://disney-animation.s3.amazonaws.com/library/s2012_pbs_disney_brdf_notes_v2.pdf page 15 for layers' parameters		------- mostly useless now. some was grabbed, some not. mostly arbitrary and perceptual anyway, save a precious few bits of info
	*add textures rollout
	*add preset manager rollout
	
Current Bugs:
ticking off "emit GI" for the wrapper of the emissive material changes the look of the SSS (which would make sense IF the sss was inside the wrapper, or the wrapper had any influence on the shading at all.)
Notice that to support blending amounts textures, i had to make the standard, untextured blending of the layers depend on the 8bit color construct (which i am feeding normal float fractions to, but it quantizes nevertheless), whereas before it was computed fully in float through the vray color texture rgb_multiplier. 
*/
genclassid()
plugin material BRDF_Mixer_Tester
name:"BRDF Mixer Tester"
classID:#(0x415803cd, 0x4fe10d44)
extends:VRayMtl replaceUI:true version:1
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
		
	)

	parameters textures rollout:texRoll rolledup:true
	(
		
	)
	rollout params "BSSRDF/BRDF Layers:" width:328 
	(

		GroupBox grp99 "Utilities:" pos:[8,8] width:312 height:56
		button spitBtn "Extract Material Copy" pos:[140,24] width:120 height:32



		on spitBtn pressed do
		(
			
			meditmaterials[24]=copy delegate
			meditmaterials[24].name= "Extracted_"+(getOwnerName())
		)
	)  
	
	rollout texRoll "Layers' Texture Mapping:" width:328 height:960
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
				delegate.texmap_diffuse=texmap
				diffuseAmtTxb.caption=texmap.name
		)
		
	)


	
	
	on create do
	(
	
	)
  
)
