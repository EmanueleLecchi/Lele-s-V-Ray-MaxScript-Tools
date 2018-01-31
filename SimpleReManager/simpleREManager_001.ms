(
	global REAdderRoll
	try (destroyDialog REAdderRoll) catch()
	
	fn addREs setType doWipe=
		(
			re = maxOps.GetCurRenderElementMgr()
			elemList=#()
			elemNamesList=#()
			if doWipe do re.RemoveAllRenderElements() 
			case of 
			(
				(setType==0):
				(
					--beauty
					elemList = #( VrayDiffuseFilter, VrayGlobalIllumination, VrayLighting, VrayReflection, VrayRefraction, VraySpecular, VrayReflectionFilter, VrayRefractionFilter, VraySSS2, VrayAtmosphere)
					elemNamesList = #( "VrayDiffuseFilter", "VrayGlobalIllumination", "VrayLighting", "VrayReflection", "VrayRefraction", "VraySpecular", "VrayReflectionFilter", "VrayRefractionFilter", "VraySSS2", "VrayAtmosphere")			
				)
				(setType==1):
				(
					--data
					elemList = #( VRaySamplerInfo, VRaySamplerInfo, VRaySamplerInfo, VRayVelocity)  --VRaySamplerInfo, VRaySamplerInfo, VrayZDepth,VRayVelocity
					elemNamesList=#("VrayNW", "VrayPW", "VrayUV", "VrayVelocity")	
				)	
				(setType==2):
				(
					--forensics
					elemList = #( VraySampleRate, VrayNoiseLevel, VrayRenderTime)
					elemNamesList = #( "VraySampleRate", "VrayNoiseLevel", "VrayRenderTime")			
			
				)				
			)
			for r=1 to elemList.count do 
			(
				theElement = elemList[r] elementName:elemNamesList[r]
				case theElement.elementName of 
					(
						"VrayNW":	(
									theElement.type=1
									theElement.coord_system=0
									)
						"VrayPW":	(
										theElement.type=0
										theElement.point_multiplier=1.0
										theElement.coord_system=0
									)
						"UV":		(
									theElement.type=4
									)
						"VrayVelocity": (
									theElement.clamp_velocity=false
									)
					)
				re.AddRenderElement theElement
			)
		)
	
	fn setBtnLabel =
	(
		if keyboard.controlPressed then
		(
			REAdderRoll.btn1.caption = "Add Forensics"
			REAdderRoll.btn2.caption = "Add Beauty"
			REAdderRoll.btn3.caption = "Add Data"
		)
		else
		(
			REAdderRoll.btn1.caption = "Forensics"
			REAdderRoll.btn2.caption = "Beauty"
			REAdderRoll.btn3.caption = "Data"			
		)
	)
	
	rollout REAdderRoll "Simple REs Set creator" width:296 height:48
	(
		button 'btn1' "Forensics" pos:[200,8] width:88 height:32 align:#left
		button 'btn2' "Beauty" pos:[8,8] width:88 height:32 align:#left
		button 'btn3' "Data" pos:[104,8] width:88 height:32 align:#left
		
		timer clockie "" interval:50 active:true
		
		on clockie tick do
		(
			setBtnLabel()
		)
		
		on btn1 pressed do
		(
			if keyboard.controlPressed then
			(
				addREs 2 false
			)
			else
			(
				addREs 2 true
			)
		)
		
		on btn2 pressed do
		(
			if keyboard.controlPressed then
			(
				addREs 0 false
			)
			else
			(
				addREs 0 true
			)
		)	

		on btn3 pressed do
		(
			if keyboard.controlPressed then
			(
				addREs 1 false
			)
			else
			(
				addREs 1 true
			)
		)		
	)
	
	createDialog REAdderRoll
	
)