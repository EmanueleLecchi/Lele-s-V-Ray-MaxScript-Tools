(
	/*
	One click solution to making a set of selected objects shadow catchers through changging of object's vray properties
	*/
	global vrscRoll
	try (destroydialog vrscRoll) catch()
	
	fn setToShadowCatcher mode =
		(
			if mode then 
			(
				for s in selection where superclassof s == geometryClass do
				(
					setUserProp s "VRay_Matte_Enable" True
					setUserProp s "VRay_Secondary_Matte_Enable" True
					setUserProp s "VRay_Matte_Alpha" -1
					setUserProp s "VRay_Matte_Shadows" True
					setUserProp s "VRay_Matte_ShadowAlpha" True
				)
			)
			else
			(
				for s in selection where superclassof s == geometryClass do
				(
					setUserProp s "VRay_Matte_Enable" false
					setUserProp s "VRay_Secondary_Matte_Enable" false
					setUserProp s "VRay_Matte_Alpha" 1
					setUserProp s "VRay_Matte_Shadows" false
					setUserProp s "VRay_Matte_ShadowAlpha" false
				)				
			)
		)
		
	
	rollout vrscRoll "V-Ray ShadowCatcher Maker" width:216 height:48
	(
		button 'btn1' "Make Shadow Catcher" pos:[8,8] width:96 height:32 align:#left
		button 'btn2' "Return to Normal" pos:[112,8] width:96 height:32 align:#left
		
		on btn1 pressed do setToShadowCatcher on
		on btn2 pressed do setToShadowCatcher off
			
		
	)
	
	createdialog vrscRoll
)