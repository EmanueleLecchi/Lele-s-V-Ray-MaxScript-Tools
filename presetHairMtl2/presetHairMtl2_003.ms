/*
Control hair whitening with a mapped gradient ramp, the hairInfoTex as map, at default values.
Middle key position drives hair %, its value the melanin amount
Watch out for special cases 0 and 100%, solid interpolation fails.
*/

plugin material myVRayHairMtl2 name:"VRayHairMtl2_P2" classID:#(0x643f19af, 0x63131ced) extends:VRayHairMtl2 replaceUI:false version:1 autoPromoteDelegateProps:true
(
	
	local params
	local presetsList = #(#(0.25,0.50,0.45,0.00,0.5,2.0,1.55),#(0.55,1.00,0.35,0.40,0.8,0.5,1.55),#(0.95,0.00,0.60,0.40,0.40,2.0,1.55),#(0.7,0.35,0.15,0.40,0.995,0.0,1.57))
-- 	local theTex = undefined
	local theSel = 1
		
	fn initialiseWhiteHairMapping =
	(
		theTex=vrayHairInfoTex output:1
		theRamp=gradient_Ramp Gradient_Type:5
		meditmaterials[1]=theRamp
		meditmaterials[1].Source_Map=theTex
		delegate.texmap_melanin = theRamp
	)
	
	fn applyPreset num =
	(
		print theSel
		theSel=num
		
		delegate.melanin = presetsList[num][1]
		delegate.pheomelanin = presetsList[num][2]
		delegate.glossiness = presetsList[num][3]
		delegate.primary_glossiness_boost = presetsList[num][4]
		delegate.softness = presetsList[num][5]
		delegate.highlight_shift = presetsList[num][6]
		delegate.ior = presetsList[num][7]
	)

	fn setWhiteHairTex =
	(
-- 		if theTex==undefined do initialiseWhiteHairMapping()

-- 		theTex.texmap_Color_A.rgb_multiplier=delegate.melanin
-- 		theTex.texmap_Color_B.rgb_multiplier=delegate.melanin * ((100.0-params.spn2.value)/100.0)
-- 		theTex.bias=params.spn1.value/100
	)

	parameters main rollout:params
	(
-- 		melaninAmt type:#float default:1 scale:0.001 ui:spn3
-- 		percWH type:#float default:75 scale:0.1 ui:spn1
-- 		whiteness type:#float default:100 scale:0.1 ui:spn2
		
-- 		on melaninAmt set val do 
-- 		(
-- 			delegate.melanin = val
-- 			setWhiteHairTex()
-- 		)
-- 		on percWH set val do 
-- 		(
-- 			setWhiteHairTex()
-- 		)
-- 		on whiteness set val do 
-- 		(
-- 			setWhiteHairTex()
-- 		)
	)
	
	rollout params "Presets" width:328 height:120
	(
		label 'lbl1' "Select Preset:" pos:[8,12] width:80 height:16 align:#left
		dropdownList 'ddl1' "" pos:[96,8] width:224 height:21 items:#("Soft Blond", "Fiery Red", "Jet Black", "Soft Brown Fur") align:#left
	
-- 		label 'lbl2' "% of WH:" pos:[8,72] width:48 height:16 align:#left
-- 		spinner 'spn1' "" pos:[64,72] width:56 height:16 range:[0,100,15] scale:0.1 align:#left
-- 		label 'lbl3' "Whiteness:" pos:[128,72] width:56 height:16 align:#left
-- 		spinner 'spn2' "" pos:[192,72] width:56 height:16 range:[0,100,100] scale:0.1 align:#left
		
-- 		label 'lbl4' "Melanin:" pos:[8,40] width:56 height:16 align:#left
-- 		spinner 'spn3' "" pos:[64,40] width:56 height:16 range:[0,1,0] scale:0.01 align:#left
-- 		
		
		on params open do
		(
			ddl1.selection = theSel
			applyPreset theSel
-- 			if theTex==undefined do initialiseWhiteHairMapping()
-- 			setWhiteHairTex()
		)
		on ddl1 selected sel do
		(
			theSel = sel
			applyPreset theSel
-- 			if theTex==undefined do initialiseWhiteHairMapping()
-- 			setWhiteHairTex()
		)
-- 		on spn1 changed val do
-- 		(
-- 			if theTex==undefined do initialiseWhiteHairMapping()
-- 			setWhiteHairTex()
-- 		)
-- 		on spn2 changed val do
-- 		(
-- 			if theTex==undefined do initialiseWhiteHairMapping()
-- 			setWhiteHairTex()
-- 		)
-- 		on spn3 changed val do
-- 		(
-- 			if theTex==undefined do initialiseWhiteHairMapping()
-- 			setWhiteHairTex()
-- 		)
	)
	
	on create do 
	(
-- 		initialiseWhiteHairMapping()
		applyPreset theSel
-- 		setWhiteHairTex()
	)
)

