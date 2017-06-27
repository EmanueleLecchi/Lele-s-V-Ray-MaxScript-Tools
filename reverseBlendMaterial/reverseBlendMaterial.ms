plugin material VrayRBlendMtl name:"VRayRBlendMtl" classID:#(0x1081c539, 0x665ccde3) extends:VRayBlendMtl replaceUI:true version:1
(
	parameters main rollout:params
	(
		coatMtl_enable_9 type:#boolean default:true ui:ckb9
		coatMtl9 type:#material ui:mBtn9		
		blendCol9 type:#color default:gray ui:cpk9
		texmap_blend9 type:#texturemap  ui:mpBtn9
		texmap_blend_multiplier9 type:#float default:100.0 ui:spn9
		on coatMtl_enable_9 set val do delegate.coatMtl_enable[9] = val
		on coatMtl9 set val do delegate.coatMtl[9]=val
		on blendCol9 set val do delegate.blend[9]=val
		on texmap_blend9 set val do delegate.texmap_blend[9]=val
		on texmap_blend_multiplier9 set val do delegate.texmap_blend_multiplier[9]=val
		
		coatMtl_enable_8 type:#boolean default:true ui:ckb8
		coatMtl8 type:#material ui:mBtn8		
		blendCol8 type:#color default:gray ui:cpk8
		texmap_blend8 type:#texturemap  ui:mpBtn8
		texmap_blend_multiplier8 type:#float default:100.0 ui:spn8
		on coatMtl_enable_8 set val do delegate.coatMtl_enable[8] = val
		on coatMtl8 set val do delegate.coatMtl[8]=val
		on blendCol8 set val do delegate.blend[8]=val
		on texmap_blend8 set val do delegate.texmap_blend[8]=val
		on texmap_blend_multiplier8 set val do delegate.texmap_blend_multiplier[8]=val
		
		coatMtl_enable_7 type:#boolean default:true ui:ckb7
		coatMtl7 type:#material ui:mBtn7		
		blendCol7 type:#color default:gray ui:cpk7
		texmap_blend7 type:#texturemap  ui:mpBtn7
		texmap_blend_multiplier7 type:#float default:100.0 ui:spn7
		on coatMtl_enable_7 set val do delegate.coatMtl_enable[7] = val
		on coatMtl7 set val do delegate.coatMtl[7]=val
		on blendCol7 set val do delegate.blend[7]=val
		on texmap_blend7 set val do delegate.texmap_blend[7]=val
		on texmap_blend_multiplier7 set val do delegate.texmap_blend_multiplier[7]=val
		
		coatMtl_enable_6 type:#boolean default:true ui:ckb6
		coatMtl6 type:#material ui:mBtn6		
		blendCol6 type:#color default:gray ui:cpk6
		texmap_blend6 type:#texturemap  ui:mpBtn6
		texmap_blend_multiplier6 type:#float default:100.0 ui:spn6
		on coatMtl_enable_6 set val do delegate.coatMtl_enable[6] = val
		on coatMtl6 set val do delegate.coatMtl[6]=val
		on blendCol6 set val do delegate.blend[6]=val
		on texmap_blend6 set val do delegate.texmap_blend[6]=val
		on texmap_blend_multiplier6 set val do delegate.texmap_blend_multiplier[6]=val
		
		coatMtl_enable_5 type:#boolean default:true ui:ckb5
		coatMtl5 type:#material ui:mBtn5		
		blendCol5 type:#color default:gray ui:cpk5
		texmap_blend5 type:#texturemap  ui:mpBtn5
		texmap_blend_multiplier5 type:#float default:100.0 ui:spn5
		on coatMtl_enable_5 set val do delegate.coatMtl_enable[5] = val
		on coatMtl5 set val do delegate.coatMtl[5]=val
		on blendCol5 set val do delegate.blend[5]=val
		on texmap_blend5 set val do delegate.texmap_blend[5]=val
		on texmap_blend_multiplier5 set val do delegate.texmap_blend_multiplier[5]=val
		
		coatMtl_enable_4 type:#boolean default:true ui:ckb4
		coatMtl4 type:#material ui:mBtn4		
		blendCol4 type:#color default:gray ui:cpk4
		texmap_blend4 type:#texturemap  ui:mpBtn4
		texmap_blend_multiplier4 type:#float default:100.0 ui:spn4
		on coatMtl_enable_4 set val do delegate.coatMtl_enable[4] = val
		on coatMtl4 set val do delegate.coatMtl[4]=val
		on blendCol4 set val do delegate.blend[4]=val
		on texmap_blend4 set val do delegate.texmap_blend[4]=val
		on texmap_blend_multiplier4 set val do delegate.texmap_blend_multiplier[4]=val
		
		coatMtl_enable_3 type:#boolean default:true ui:ckb3
		coatMtl3 type:#material ui:mBtn3		
		blendCol3 type:#color default:gray ui:cpk3
		texmap_blend3 type:#texturemap  ui:mpBtn3
		texmap_blend_multiplier3 type:#float default:100.0 ui:spn3
		on coatMtl_enable_3 set val do delegate.coatMtl_enable[3] = val
		on coatMtl3 set val do delegate.coatMtl[3]=val
		on blendCol3 set val do delegate.blend[3]=val
		on texmap_blend3 set val do delegate.texmap_blend[3]=val
		on texmap_blend_multiplier3 set val do delegate.texmap_blend_multiplier[3]=val
		
		coatMtl_enable_2 type:#boolean default:true ui:ckb2
		coatMtl2 type:#material ui:mBtn2		
		blendCol2 type:#color default:gray ui:cpk2
		texmap_blend2 type:#texturemap  ui:mpBtn2
		texmap_blend_multiplier2 type:#float default:100.0 ui:spn2
		on coatMtl_enable_2 set val do delegate.coatMtl_enable[2] = val
		on coatMtl2 set val do delegate.coatMtl[2]=val
		on blendCol2 set val do delegate.blend[2]=val
		on texmap_blend2 set val do delegate.texmap_blend[2]=val
		on texmap_blend_multiplier2 set val do delegate.texmap_blend_multiplier[2]=val
		
		coatMtl_enable_1 type:#boolean default:true ui:ckb1
		coatMtl1 type:#material ui:mBtn1		
		blendCol1 type:#color default:gray ui:cpk1
		texmap_blend1 type:#texturemap  ui:mpBtn1
		texmap_blend_multiplier1 type:#float default:100.0 ui:spn1
		on coatMtl_enable_1 set val do delegate.coatMtl_enable[1] = val
		on coatMtl1 set val do delegate.coatMtl[1]=val
		on blendCol1 set val do delegate.blend[1]=val
		on texmap_blend1 set val do delegate.texmap_blend[1]=val
		on texmap_blend_multiplier1 set val do delegate.texmap_blend_multiplier[1]=val
		
		base_Material type:#material ui:mBtn0
		on base_Material set val do delegate.baseMtl = val
			
		additive_Mode type:#boolean ui:ckb10
		on additive_Mode set val do delegate.additiveMode = val
		
	)
	rollout params "Parameters"
	(
		label lbl9 "9:" align:#left across:6 width:16
		checkbox ckb9 "" width:16 offset:[-40,0]
		materialButton mBtn9 "None" width:112 height:16 offset:[-48,0]
		colorPicker cpk9 "" color:gray width:20 height:16 offset:[-20,0]
		mapButton mpBtn9 "None" width:112 height:16 offset:[-20,0]
		spinner spn9 "" fieldWidth:40 height:16 offset:[8,0] range:[0.0,100.0,100.0] scale:0.1
		
		label lbl8 "8:" align:#left across:6 width:16
		checkbox ckb8 "" width:16 offset:[-40,0]
		materialButton mBtn8 "None" width:112 height:16 offset:[-48,0]
		colorPicker cpk8 "" color:gray width:20 height:16 offset:[-20,0]
		mapButton mpBtn8 "None" width:112 height:16 offset:[-20,0]
		spinner spn8 "" fieldWidth:40 height:16 offset:[8,0] range:[0.0,100.0,100.0] scale:0.1		
		
		label lbl7 "7:" align:#left across:6 width:16
		checkbox ckb7 "" width:16 offset:[-40,0]
		materialButton mBtn7 "None" width:112 height:16 offset:[-48,0]
		colorPicker cpk7 "" color:gray width:20 height:16 offset:[-20,0]
		mapButton mpBtn7 "None" width:112 height:16 offset:[-20,0]
		spinner spn7 "" fieldWidth:40 height:16 offset:[8,0] range:[0.0,100.0,100.0] scale:0.1		
		
		label lbl6 "6:" align:#left across:6 width:16
		checkbox ckb6 "" width:16 offset:[-40,0]
		materialButton mBtn6 "None" width:112 height:16 offset:[-48,0]
		colorPicker cpk6 "" color:gray width:20 height:16 offset:[-20,0]
		mapButton mpBtn6 "None" width:112 height:16 offset:[-20,0]
		spinner spn6 "" fieldWidth:40 height:16 offset:[8,0] range:[0.0,100.0,100.0] scale:0.1		
		
		label lbl5 "5:" align:#left across:6 width:16
		checkbox ckb5 "" width:16 offset:[-40,0]
		materialButton mBtn5 "None" width:112 height:16 offset:[-48,0]
		colorPicker cpk5 "" color:gray width:20 height:16 offset:[-20,0]
		mapButton mpBtn5 "None" width:112 height:16 offset:[-20,0]
		spinner spn5 "" fieldWidth:40 height:16 offset:[8,0] range:[0.0,100.0,100.0] scale:0.1

		label lbl4 "4:" align:#left across:6 width:16
		checkbox ckb4 "" width:16 offset:[-40,0]
		materialButton mBtn4 "None" width:112 height:16 offset:[-48,0]
		colorPicker cpk4 "" color:gray width:20 height:16 offset:[-20,0]
		mapButton mpBtn4 "None" width:112 height:16 offset:[-20,0]
		spinner spn4 "" fieldWidth:40 height:16 offset:[8,0] range:[0.0,100.0,100.0] scale:0.1
		
		label lbl3 "3:" align:#left across:6 width:16
		checkbox ckb3 "" width:16 offset:[-40,0]
		materialButton mBtn3 "None" width:112 height:16 offset:[-48,0]
		colorPicker cpk3 "" color:gray width:20 height:16 offset:[-20,0]
		mapButton mpBtn3 "None" width:112 height:16 offset:[-20,0]
		spinner spn3 "" fieldWidth:40 height:16 offset:[8,0] range:[0.0,100.0,100.0] scale:0.1
		
		label lbl2 "2:" align:#left across:6 width:16
		checkbox ckb2 "" width:16 offset:[-40,0]
		materialButton mBtn2 "None" width:112 height:16 offset:[-48,0]
		colorPicker cpk2 "" color:gray width:20 height:16 offset:[-20,0]
		mapButton mpBtn2 "None" width:112 height:16 offset:[-20,0]
		spinner spn2 "" fieldWidth:40 height:16 offset:[8,0] range:[0.0,100.0,100.0] scale:0.1
		
		
		label lbl1 "1:" align:#left across:6 width:16
		checkbox ckb1 "" width:16 offset:[-40,0]
		materialButton mBtn1 "None" width:112 height:16 offset:[-48,0]
		colorPicker cpk1 "" color:gray width:20 height:16 offset:[-20,0]
		mapButton mpBtn1 "None" width:112 height:16 offset:[-20,0]
		spinner spn1 "" fieldWidth:40 height:16 offset:[8,0] range:[0.0,100.0,100.0] scale:0.1
		
		label lbl0 "Base Material:" align:#left across:2
		materialButton mBtn0 "None" width:248 height:16 offset:[-42,0]
		
		checkbox ckb10 "" width:16  align:#left across:2 offset:[12,0]
		label lbl10 "Additive (Shellac) Mode" offset:[-152,0]
	)
)
