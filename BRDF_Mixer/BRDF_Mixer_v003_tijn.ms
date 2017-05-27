plugin material BRDF_Mixer
name:"BRDF Mixer"
classID:#(0x7ec7e5f7, 0x77351a94)
extends:VRayBlendMtl replaceUI:true version:1
(
  parameters main rollout:params
  (
	-- Controls Declaration
	sssAmt type:#float default:.25 scale:0.001 ui:sssAmt
	sssRad type:#float default:1 scale:0.001 ui:sssRad
	sssPhase type:#Float default:0.0 scale:0.001 ui:sssPhase
	sssSssClr type:#color default:Yellow ui:sssSssClr
	sssSctClr type:#color default:Yellow ui:sssSctClr	  
	sssScl type:#float default:1 scale:0.001 ui:sssScl
	sheenAmt type:#float default:0.05 scale:0.001 ui:sheenAmt	
	sheenClr type:#color default:White ui:sheenClr
	sheenIor type:#float default:3 scale:0.001 ui:sheenIor
	  
	diffuseAmt type:#float default:1 scale:0.001 ui:diffuseAmt
	diffuseClr type:#color default:White ui:diffuseClr
	diffuseIor type:#float default:64 scale:0.001 ui:diffuseIor
	diffuseRoughness type:#float default:.8 scale:0.001 ui:diffuseRoughness  
	
	metallicAmt type:#float default:.5 scale:0.001 ui:metallicAmt
	metallicClr type:#color default:Blue ui:metallicClr
	metallicIor type:#float default:8 scale:0.001 ui:metallicIor
	metallicCtr type:#float default:1 scale:0.001 ui:metallicCtr 
	  
	specAmt type:#float default:1 scale:0.001 ui:specAmt
	specCtr type:#float default:.1579 scale:0.001 ui:specCtr
	specIor type:#float default:2 scale:0.001 ui:specIor
	specClr type:#color default:White ui:specClr
	specRoughness type:#float default:.5 scale:0.001 ui:specRoughness	
	-- Behaviours Declaration
		--SSS
	on sssAmt set val do delegate.baseMtl.diffuse_amount  = 1.0-val
	on sssRad set val do delegate.baseMtl.scatter_radius  = val
	on sssPhase set val do delegate.baseMtl.phase_function  = val	
	on sssSssClr set val do delegate.baseMtl.sub_surface_color = val
	on sssSctClr set val do delegate.baseMtl.scatter_color = val	
	on sssScl set val do delegate.baseMtl.scale = val	
		--Sheen
	on sheenAmt set val do delegate.texmap_blend[1].rgb_multiplier = val    
	on sheenClr set val do delegate.coatMtl[1].texmap_reflection.color = val
	on sheenIor set val do delegate.coatMtl[1].refraction_ior = val
		-- Diffuse
	on diffuseAmt set val do delegate.texmap_blend[2].rgb_multiplier = val	    
	on diffuseClr set val do delegate.coatMtl[2].texmap_reflection.color = val
	on diffuseIor set val do delegate.coatMtl[2].refraction_ior = val
	on diffuseRoughness set val do delegate.coatMtl[2].gtr_gamma = 8.09-(val*8)
		
		-- Metallic
	on metallicAmt set val do delegate.texmap_blend[3].rgb_multiplier = val	    
	on metallicClr set val do delegate.coatMtl[3].texmap_reflection.color = val
	on metallicIor set val do delegate.coatMtl[3].refraction_ior = val
	on metallicCtr set val do delegate.coatMtl[3].gtr_gamma = 1+(val*8)		--------------------------------------------------<<<<<<<<<<<<<<<<<<< 
		-- Specular
	on specAmt set val do delegate.texmap_blend[4].rgb_multiplier = val	    
	on specCtr set val do delegate.coatMtl[4].gtr_gamma = 0.5 + (val*9.5)  -- 0.5 / 10.0
	on specIor set val do delegate.coatMtl[4].refraction_ior = val		
	on specClr set val do delegate.coatMtl[4].texmap_reflection.color = val
	on specRoughness set val do delegate.coatMtl[4].reflection_glossiness = 0.995-(val*0.85)  -- 0.145 / 0.995  			 0.995-0.85
  )
  rollout params "BRDF Layers:" width:328 height:584
  (
	  
  	GroupBox grp1 "SubSurface-Scattering:" pos:[8,8] width:312 height:64
  	spinner sssAmt "" pos:[48,24] width:56 height:16 range:[0,1,0.01] type:#float scale:0.01 fieldwidth:52
  	spinner sssRad "" pos:[152,24] width:56 height:16 range:[1e-005,100000,0.01] type:#float scale:0.01 fieldwidth:52 	
 	
 	
  	spinner sssPhase "" pos:[256,24] width:56 height:16 range:[-1,1,0.01] type:#float scale:0.01 fieldwidth:52	
	
	
  	colorPicker sssSssClr "" pos:[56,48] width:48 height:20 color:(color 0 0 155)
  	colorPicker sssSctClr "" pos:[168,48] width:48 height:20 color:(color 0 0 155)
  	spinner sssScl "" pos:[256,48] width:56 height:16 range:[1e-005,100000,0.01] type:#float scale:0.01 fieldwidth:52
  	label lb1 "Amt." pos:[16,24] width:24 height:16
  	label lbl18 "Radius" pos:[112,24] width:32 height:16
  	label lbl16 "Phase" pos:[216,24] width:32 height:16	  
	  
	  
  	label lbl17 "SSS Clr." pos:[16,48] width:40 height:16	
	
	
  	label lb2 "Scatter Clr." pos:[112,48] width:56 height:16
  	label lb3 "Scl." pos:[232,48] width:16 height:16	  
	  
	  

  	GroupBox grp2 "Sheen:" pos:[8,80] width:312 height:40	
	
	
  	spinner sheenAmt "" pos:[64,96] width:56 height:16 range:[0,1,0.01] type:#float scale:0.01 fieldwidth:52
  	colorPicker sheenClr "" pos:[160,96] width:48 height:20 
 
 
  	spinner sheenIor "" pos:[256,96] width:56 height:16 range:[1.001,100,0.01] type:#float scale:0.01 fieldwidth:52
  	label lbl4 "Amt." pos:[16,96] width:24 height:16
  	label lbl5 "Clr." pos:[136,96] width:24 height:16
  	label lbl6 "IoR" pos:[232,96] width:16 height:16 
 
 
	  
  	GroupBox grp3 "Diffuse:" pos:[8,128] width:312 height:72	  
	  
	  
  	spinner diffuseAmt "" pos:[48,144] width:56 height:16 range:[0,1,0.01] type:#float scale:0.01 fieldwidth:52
  	colorPicker diffuseClr "" pos:[56,168] width:48 height:20 
 
 
  	spinner diffuseIor "" pos:[256,144] width:56 height:16 range:[1.001,1024,0.01] type:#float scale:0.01 fieldwidth:52
  	spinner diffuseRoughness "" pos:[176,144] width:40 height:16 range:[0,1,2] type:#float scale:0.01 fieldwidth:34
  	label lbl7 "Amt." pos:[16,144] width:24 height:16
  	label lbl8 "Clr." pos:[16,168] width:24 height:16
  	label lbl9 "IoR" pos:[232,144] width:16 height:16
  	label lbl55 "Roughness" pos:[112,144] width:52 height:16	
	
	
	
  	GroupBox grp4 "Metallic:" pos:[8,208] width:312 height:64	  
	  
	  
  	spinner metallicAmt "" pos:[48,224] width:56 height:16 range:[0,1,0.01] type:#float scale:0.01 fieldwidth:52
  	colorPicker metallicClr "" pos:[56,248] width:48 height:20 
 
 
  	spinner metallicIor "" pos:[256,224] width:56 height:16 range:[1.001,100,0.01] type:#float scale:0.01 fieldwidth:52
  	spinner metallicCtr "" pos:[168,224] width:48 height:16 range:[0,1,0.01] type:#float scale:0.01 fieldwidth:42
  	label lbl10 "Amt." pos:[16,224] width:24 height:16
  	label lbl11 "Clr." pos:[16,248] width:24 height:16
  	label lbl12 "IoR" pos:[232,224] width:16 height:16
  	label lbl75 "Contrast" pos:[112,224] width:48 height:16

  	GroupBox grp5 "ISOTropic Specular:" pos:[8,280] width:312 height:64	  
	  
	  
  	spinner specAmt "" pos:[48,296] width:56 height:16 range:[0,1,0.01] type:#float scale:0.01 fieldwidth:52
  	spinner specRoughness "" pos:[176,296] width:40 height:16 range:[0,1,2] type:#float scale:0.01 fieldwidth:34
  	spinner specIor "" pos:[256,296] width:56 height:16 range:[1.001,100,0.01] type:#float scale:0.01 fieldwidth:52
  	colorPicker specClr "" pos:[56,320] width:48 height:20 	
 	
  	spinner specCtr "" pos:[168,320] width:48 height:16 range:[0,1,0.01] type:#float scale:0.01 fieldwidth:42	
	
  	label lbl13 "Amt." pos:[16,296] width:24 height:16
  	label lbl96 "Roughness" pos:[112,296] width:52 height:16
  	label lbl15 "IoR" pos:[232,296] width:16 height:16	
	
  	label lbl14 "Clr." pos:[16,320] width:24 height:16
  	label lbl97 "Contrast" pos:[112,320] width:48 height:16
	
  	button reBtn "Make Render Elements" pos:[8,352] width:312 height:32

	/* Returns the material that owns this instance */
	fn getOwner =
	(
		local deps = for m in (refs.dependents delegate) where classOf m == BRDF_Mixer collect m
		if deps.count == 0 then undefined else deps[1]	
	)
	
	/* Returns the name of the material that owns this instance */
	fn getOwnerName =
	(
		local owner = getOwner()
		if owner == undefined then "" else owner.name
	)

	on reBtn pressed do
	(
		-- get the base name for the elements
		local ownerName = getOwnerName()
		local elementBaseName = "BRDFMxr_" + ownerName
		if ownerName.count > 0 do append elementBaseName "_"
		
		local re = maxOps.GetCurRenderElementMgr()
		local elementNames = #(elementBaseName + delegate.baseMtl.name)
		for i = 1 to 4 do
			append elementNames (elementBaseName + delegate.coatMtl[i].name)

		-- insert delete part here: find by name part and wipe		
		for n = (re.numRenderElements() - 1) to 0 by -1 do
		(
			el = re.getRenderElement n
			for elementName in elementNames where
				el.elementName == elementName do 
			(
				re.RemoveRenderElement el
				format "Found and deleted a \"%\" element!\n" el.elementName
			)
		)

		--add 5 mtlSelect REs 
			--base
			theElement = VrayMtlSelect() 
			theElement.material = delegate.baseMtl
			theElement.elementName=elementNames[1]
			re.AddRenderElement theElement
			-- 4 coats  
		for i=1 to 4 do 
		(
			theElement = VrayMtlSelect()
			theElement.material = delegate.coatMtl[i]
			theElement.elementName=elementNames[i+1]
			re.AddRenderElement theElement
		)
-- 		-- add base VrayMtlSelect render element
-- 		re.AddRenderElement (VrayMtlSelect material:delegate.baseMtl elementName:elementNames[1])
		
		-- add coat VrayMtlSelect render elements
-- 		for i = 1 to 4 do
-- 			re.AddRenderElement (VrayMtlSelect material:delegate.coatMtl[i] elementName:elementNames[i+1])
	)
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
	m0.diffuse_color=Black
	m0.specular_amount=0
	sssSssClr=m0.sub_surface_color
	sssSctClr=m0.scatter_color
	sssRad=m0.scatter_radius
	sssScl=m0.scale
	sssPhase=m0.phase_function
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
	m2.gtr_gamma=diffuseRoughness
	m2.reflection_glossiness=.075
	m2.gtr_gamma=0.25
	m2.option_cutoff=0.0
	
	m3.brdf_type=4
	m3.diffuse=black
	m3.texmap_reflection=vrayColor()
	m3.texmap_reflection.color=metallicClr
	delegate.texmap_blend[3].rgb_multiplier=metallicAmt
	m3.refraction_ior=metallicIor
	m3.reflection_glossiness=.9
	m3.gtr_gamma=1	+(8*metallicCtr)
	m3.option_cutoff=0.0
	
	m4.brdf_type=4
	m4.diffuse=black
	m4.texmap_reflection=vrayColor()
	m4.texmap_reflection.color=specClr
	delegate.texmap_blend[3].rgb_multiplier=specAmt
	m4.refraction_ior=specIor
	m4.reflection_glossiness=0.995-(specRoughness*0.85) 
	m4.gtr_gamma=0.5 + (specCtr*9.5)
	m4.option_cutoff=0.0		  
  )
  
)
  


-- genClassID()

-- m=vrayblendMtl()
-- show m
