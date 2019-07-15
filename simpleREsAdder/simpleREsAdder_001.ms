(
	/*
	Simple Render Elements Set creator
	Creates one of two predefined sets of REs, to aid in compositing.
	*/
	--Globals
	global simpleReAdder
	try (destroyDialog simpleReAdder) catch()

	--Locals	
	elemList = #(  VrayDiffuseFilter, VrayGlobalIllumination, VrayLighting, VraySpecular, VrayReflection, VrayReflectionFilter, VrayRefraction, VrayRefractionFilter, VraySSS2, VrayAtmosphere )
	elemNamesList = #(  "VrayDiffuseFilter", "VrayGlobalIllumination", "VrayLighting", "VraySpecular", "VrayReflection", "VrayReflectionFilter", "VrayRefraction", "VrayRefractionFilter", "VraySSS2", "VrayAtmosphere")			
			
	--Functions
	
	--Fill in the arrays of element classes and element names
	fn setElemList type doShortNames =
	(
		case type of
		(
			"Beauty" : 
			(
				elemList = #( VRayBackGround, VrayDiffuseFilter, VrayGlobalIllumination, VrayLighting, VraySelfIllumination, VrayShadows, VraySpecular, VrayReflection, VrayReflectionFilter, VrayRefraction, VrayRefractionFilter, VraySSS2, VrayAtmosphere )
				if doShortNames then
				(
					elemNamesList = #( "Bkgnd", "DiffFlt", "GI", "Light", "SelfIllum", "Shdw", "Spec", "Refl", "ReflFlt", "Refr", "RefrFlt", "SSS", "Atmos")			
				)
				else
				(
					elemNamesList = #(  "VrayBackGround", "VrayDiffuseFilter", "VrayGlobalIllumination", "VrayLighting", "VraySelfIllumination", "VrayShadows", "VraySpecular", "VrayReflection", "VrayReflectionFilter", "VrayRefraction", "VrayRefractionFilter", "VraySSS2", "VrayAtmosphere")			
				)
			)
			"Data" : 
			(
				elemList = #( VRaySamplerInfo, VRaySamplerInfo, VRaySamplerInfo, VRayVelocity)  --VRaySamplerInfo, VRaySamplerInfo, VrayZDepth,VRayVelocity
				-- then add all the ones we need, and configure those that need  it
				
				if doShortNames then
				(
					elemNamesList = #("nrmBmpWrld", "pntWrld", "UV", "Vel")			
				)
				else
				(
					elemNamesList =#("VrayNormalBumpWorld", "VrayPointWorld", "VRayUV", "VrayVelocity")
				)
			)			
			"Forensics" : 
			(
				elemList = #(  VraySampleRate, VrayNoiseLevel, VrayRenderTime, VrayLightingAnalysis )
				if doShortNames then
				(
					elemNamesList = #( "SmpRte", "NseLvl", "RndTme", "LgtAnl")			
				)
				else
				(
					elemNamesList = #( "VraySampleRate", "VrayNoiseLevel", "VrayRenderTime", "VrayLightingAnalysis")
				)
			)
		)
	)

	fn addREs type doShortNames doWipe=
	(
		--call the function above to fill in the element types and names lists.
		setElemList type doShortNames
		--process the lists and add the REs
		re = maxOps.GetCurRenderElementMgr()
		--if needed, wipe those which are present already
		if doWipe do re.RemoveAllRenderElements() 
		--if it's of Data type, the REs need some settings changed
		if type == "Data" then
		(
			for r=1 to elemList.count do 
			(
				local theElement = (elemList[r]) elementName:elemNamesList[r]
				re.AddRenderElement theElement
				case r of 
				(
					1:	(
							theElement.type=5
							theElement.coord_system=0
						)
					2:	(
							theElement.type=0
							theElement.point_multiplier=1.0
							theElement.coord_system=0
						)
					3:	(
							theElement.type=4
						)
					4: 	(
							theElement.clamp_velocity=false
						)
				)
				re.SetRenderElementFilename (r-1) ""
-- 				theMsg+="Added a " + theElement.elementName + " Render Element\n"
			)
		)
		--otherwise it's fine to just add them
		else
		(
			for r=1 to elemList.count do 
			(
				theElement = elemList[r] elementName:elemNamesList[r]
				re.AddRenderElement theElement
			)
		)
	)
	
	--UI
	
	rollout simpleReAdder "Simple REs Adder v 0.01" width:272 height:160
	(
		button 'btn1' "Beauty" pos:[8,72] width:80 height:80 align:#left
		button 'btn2' "Data" pos:[96,72] width:80 height:80 align:#left
		button 'btn3' "Forensics" pos:[184,72] width:80 height:80 align:#left
		checkButton 'ckb1' "Standard Names" pos:[8,8] width:256 height:24 checked:true align:#left
		checkButton 'ckb2' "Clear Existing" pos:[8,40] width:256 height:24 checked:true align:#left
		
		on ckb1 changed state do
		(
			ckb1.text = if state then "Standard Names" else "Short Names"
		)
		on ckb2 changed state do
		(
			ckb2.text = if state then "Clear Existing" else "Keep Existing"
		)

		on btn1 pressed do
		(
			addREs btn1.text (not ckb1.checked) ckb2.checked
		)
		on btn2 pressed do
		(
			addREs btn2.text (not ckb1.checked) ckb2.checked
		)
		on btn3 pressed do
		(
			addREs btn3.text (not ckb1.checked) ckb2.checked
		)
	)
	
	createdialog simpleReAdder
	
)

