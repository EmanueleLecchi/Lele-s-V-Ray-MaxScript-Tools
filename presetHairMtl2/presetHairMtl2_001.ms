plugin material myVRayHairMtl2 name:"VRayHairMtl2_P" classID:#(0x1081c539, 0x665ccde3) extends:VRayHairMtl2 replaceUI:false version:1
(
	
	local presetsList = #(#(0.25,0.50,0.45,0.00,0.5,2.0,1.55),#(0.55,1.00,0.35,0.40,0.8,0.5,1.55),#(0.95,0.00,0.60,0.40,0.40,2.0,1.55),#(0.7,0.35,0.15,0.40,0.995,0.0,1.57))
	
	fn applyPreset num =
	(
		delegate.melanin = presetsList[num][1]
		delegate.pheomelanin = presetsList[num][2]
		delegate.glossiness = presetsList[num][3]
		delegate.primary_glossiness_boost = presetsList[num][4]
		delegate.softness = presetsList[num][5]
		delegate.highlight_shift = presetsList[num][6]
		delegate.ior = presetsList[num][7]
	)
	
	parameters main rollout:params
	(
		presetNumber type:#integer default:1 ui:ddl1
	)
	
	rollout params "Presets" width:328 height:168
	(
		label 'lbl1' "Select Preset:" pos:[8,12] width:80 height:16 align:#left
		dropDownList 'ddl1' "" pos:[88,8] width:232 height:21 align:#left items:#("Soft Blond","Fiery Red","Jet Black","Soft Brown Fur")
	
		on params open do
		(
			--
		)
	
		on ddl1 selected sel do
		(
			applyPreset ddl1.selection
		)
	
	)
	
	on create do 
	(
		applyPreset 1
	)
)
