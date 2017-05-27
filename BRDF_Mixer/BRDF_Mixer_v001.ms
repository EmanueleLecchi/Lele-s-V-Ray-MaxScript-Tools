plugin material BRDF_Mixer
name:"BRDF Mixer"
classID:#(0x7ec7e5f7, 0x77351a94)
extends:VRayBlendMtl replaceUI:true version:1
(
  parameters main rollout:params
  (
	-- Controls Declaration
	sssAmt type:#float default:.25 scale:0.001 ui:sssAmt 
	sssClr type:#color default:Yellow ui:sssClr
	sssScl type:#float default:1 scale:0.001 ui:sssScl	
	sheenAmt type:#float default:0.05 scale:0.001 ui:sheenAmt	
	sheenClr type:#color default:White ui:sheenClr
	sheenIor type:#float default:3 scale:0.001 ui:sheenIor
	diffuseAmt type:#float default:1 scale:0.001 ui:diffuseAmt
	diffuseClr type:#color default:White ui:diffuseClr
	diffuseIor type:#float default:16 scale:0.001 ui:diffuseIor
	metallicAmt type:#float default:.5 scale:0.001 ui:metallicAmt
	metallicClr type:#color default:Blue ui:metallicClr
	metallicIor type:#float default:8 scale:0.001 ui:metallicIor
	specAmt type:#float default:1 scale:0.001 ui:specAmt
	specClr type:#color default:White ui:specClr
	specIor type:#float default:2 scale:0.001 ui:specIor
	  
	-- Behaviours Declaration
		--SSS
	on sssAmt set val do delegate.baseMtl.diffuse_amount  = 1.0-val    
	on sssClr set val do delegate.baseMtl.sub_surface_color = val
	on sssScl set val do delegate.baseMtl.scale = val	
		--Sheen
	on sheenAmt set val do delegate.texmap_blend[1].rgb_multiplier = val    
	on sheenClr set val do delegate.coatMtl[1].texmap_reflection.color = val
	on sheenIor set val do delegate.coatMtl[1].refraction_ior = val
		-- Diffuse
	on diffuseAmt set val do delegate.texmap_blend[2].rgb_multiplier = val	    
	on diffuseClr set val do delegate.coatMtl[2].texmap_reflection.color = val
	on diffuseIor set val do delegate.coatMtl[2].refraction_ior = val			
		-- Metallic
	on metallicAmt set val do delegate.texmap_blend[3].rgb_multiplier = val	    
	on metallicClr set val do delegate.coatMtl[3].texmap_reflection.color = val
	on metallicIor set val do delegate.coatMtl[3].refraction_ior = val				
		-- Specular
	on specAmt set val do delegate.texmap_blend[4].rgb_multiplier = val	    
	on specClr set val do delegate.coatMtl[4].texmap_reflection.color = val
	on specIor set val do delegate.coatMtl[4].refraction_ior = val		
		
  )
  
  rollout params "BRDF Layers:" width:328 height:336
  (
	  
  	GroupBox grp1 "SubSurface-Scattering:" pos:[8,8] width:312 height:40
  	spinner sssAmt "" pos:[64,24] width:56 height:16 range:[0,1,0.01] type:#float fieldwidth:52 scale:0.01
  	colorPicker sssClr "" pos:[160,24] width:48 height:20 color:(color 0 0 155)
  	spinner sssScl "" pos:[256,24] width:56 height:16 range:[0.00001,100000,0.01] type:#float fieldwidth:52 scale:0.01
  	label lb1 "Amt." pos:[16,24] width:24 height:16
  	label lb2 "Clr." pos:[136,24] width:24 height:16
  	label lb3 "Scl." pos:[224,24] width:24 height:16	  
	
  	GroupBox grp2 "Sheen:" pos:[8,56] width:312 height:40	
  	spinner sheenAmt "" pos:[64,72] width:56 height:16 range:[0,1,0.01] type:#float fieldwidth:52 scale:0.01
  	colorPicker sheenClr "" pos:[160,72] width:48 height:20 
  	spinner sheenIor "" pos:[256,72] width:56 height:16 range:[1.001,100,0.01] type:#float fieldwidth:52 scale:0.01
  	label lbl4 "Amt." pos:[16,72] width:24 height:16
  	label lbl5 "Clr." pos:[136,72] width:24 height:16
  	label lbl6 "IoR" pos:[224,72] width:24 height:16 
	  
  	GroupBox grp3 "Diffuse:" pos:[8,104] width:312 height:40	  
  	spinner diffuseAmt "" pos:[64,120] width:56 height:16 range:[0,1,0.01] type:#float fieldwidth:52 scale:0.01
  	colorPicker diffuseClr "" pos:[160,120] width:48 height:20 
  	spinner diffuseIor "" pos:[256,120] width:56 height:16 range:[1.001,100,0.01] type:#float fieldwidth:52 scale:0.01
  	label lbl7 "Amt." pos:[16,120] width:24 height:16
  	label lbl8 "Clr." pos:[136,120] width:24 height:16
  	label lbl9 "IoR" pos:[224,120] width:24 height:16
	
  	GroupBox grp4 "Metallic:" pos:[8,152] width:312 height:40	  
  	spinner metallicAmt "" pos:[64,168] width:56 height:16 range:[0,1,0.01] type:#float fieldwidth:52 scale:0.01
  	colorPicker metallicClr "" pos:[160,168] width:48 height:20 
  	spinner metallicIor "" pos:[256,168] width:56 height:16 range:[1.001,100,0.01] type:#float fieldwidth:52 scale:0.01
  	label lbl10 "Amt." pos:[16,168] width:24 height:16
  	label lbl11 "Clr." pos:[136,168] width:24 height:16
  	label lbl12 "IoR" pos:[224,168] width:24 height:16

  	GroupBox grp5 "Specular:" pos:[8,200] width:312 height:40	  
  	spinner specAmt "" pos:[64,216] width:56 height:16 range:[0,1,0.01] type:#float fieldwidth:52 scale:0.01
  	colorPicker specClr "" pos:[160,216] width:48 height:20 
  	spinner specIor "" pos:[256,216] width:56 height:16 range:[1.001,100,0.01] type:#float fieldwidth:52 scale:0.01
  	label lbl13 "Amt." pos:[16,216] width:24 height:16
  	label lbl14 "Clr." pos:[136,216] width:24 height:16
  	label lbl15 "IoR" pos:[224,216] width:24 height:16	

  )
  on create do
  (
	delegate.additiveMode = on
	for i=1 to delegate.Blend.count do delegate.blend[i]=white
	for i=1 to delegate.texmap_blend.count do 
	(
		delegate.texmap_blend[i]=VrayColor color:white 
		delegate.texmap_blend[i].rgb_multiplier=1
	)
	
    -- setup initial materials creation. Properties settings comes later on.

	delegate.baseMtl=VrayFastSSS2 name:"SubSurface-Scattering" 	--fastSSS2
	m0=delegate.baseMtl
	delegate.coatMtl[1]=VrayMtl name:"Sheen"					--gtr gamma 0.05 gloss 0.35
	m1=delegate.coatMtl[1]
	delegate.coatMtl[2]=VrayMtl name:"Diffuse"					--gtr gamma 1 gloss 0.15
	m2=delegate.coatMtl[2]
	delegate.coatMtl[3]=VrayMtl name:"Metallic"					--gtr gamma 10 gloss 0.85
	m3=delegate.coatMtl[3]	 
	delegate.coatMtl[4]=VrayMtl name:"Specular"					--gtr gamma 2 gloss 0.85
	m4=delegate.coatMtl[4]	 	
	
	m0.preset=6
	m0.scale=sssScl
	m0.diffuse_color=Black
	m0.specular_amount=0
	sssClr=m0.sub_surface_color
	m0.diffuse_amount  = 1.0-sssAmt 
	
	m1.brdf_type=4  
	m1.diffuse=black
	m1.texmap_reflection=vrayColor()
	m1.texmap_reflection.color=sheenClr
	delegate.texmap_blend[1].rgb_multiplier=sheenAmt
	m1.refraction_ior=sheenIor
	m1.reflection_glossiness=0.35
	m1.gtr_gamma=0.05
	m1.option_cutoff=0.0

	m2.brdf_type=4
	m2.diffuse=black
	m2.texmap_reflection=vrayColor()
	m2.texmap_reflection.color=diffuseClr
	delegate.texmap_blend[2].rgb_multiplier=diffuseAmt
	m2.refraction_ior=diffuseIor
	m2.reflection_glossiness=.15
	m2.gtr_gamma=1 
	m2.option_cutoff=0.0
	
	m3.brdf_type=4
	m3.diffuse=black
	m3.texmap_reflection=vrayColor()
	m3.texmap_reflection.color=metallicClr
	delegate.texmap_blend[3].rgb_multiplier=metallicAmt
	m3.refraction_ior=metallicIor
	m3.reflection_glossiness=.85
	m3.gtr_gamma=10
	m3.option_cutoff=0.0
	
	m4.brdf_type=4
	m4.diffuse=black
	m4.texmap_reflection=vrayColor()
	m4.texmap_reflection.color=specClr
	delegate.texmap_blend[3].rgb_multiplier=specAmt
	m4.refraction_ior=specIor
	m4.reflection_glossiness=.85
	m4.gtr_gamma=2
	m4.option_cutoff=0.0		  
  )
)

-- genClassID()

-- m=vrayblendMtl()
-- show m
