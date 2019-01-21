-- macroScript makeVrayMaterial category:"VRay"
(
	global vrayMaterialMakerRoll
	try (destroyDialog vrayMaterialMakerRoll) catch()

	local materialsList=#("SSS_A ","SSS_B ","SSS_C ","SSS_Aa ","SSS_Ba ","SSS_Ca ")
	local listLength=0
	local editString=""
-- 	local materialString=""
	
	fn filterMaterialList fltStr =
	(
		editString=""
		listLength=0
		if fltStr=="" do  fltStr="*"
		for i=1 to materialsList.count do
		(
			if matchPattern materialsList[i] pattern:(fltStr) do 
			(
				editString+=(materialsList[i]+"\n")
				listLength+=1
			)
		)
		vrayMaterialMakerRoll.lbl1.text=editString
-- 		vrayMaterialMakerRoll.lbl1.height=(14*listLength)
		vrayMaterialMakerRoll.height=48+(14*listLength)
		if listLength == 1 do materialString = editString
	)
	
	fn makeVrayMtl matName=
	(
		case matName of
		(
			"SSS_A \n":
			(
				print "SSS_A"
			)
			"SSS_B \n":
			(
				print "SSS_B"
			)
			"SSS_C \n":
			(
				print "SSS_C"
			)
			"SSS_Aa ":
			(
				print "SSS_Aa"
			)
			"SSS_Ba ":
			(
				print "SSS_Ba"
			)
			"SSS_Ca ":
			(
				print "SSS_Ca"
			)
		)
	)
	
	rollout vrayMaterialMakerRoll "Create VrayMaterial" width:208 height:232
	(
		
		editText 'edt1' "" pos:[8,8] width:184 height:24 align:#left
		label 'lbl1' "" pos:[8,40] width:184 height:1840 align:#left

		on vrayMaterialMakerRoll open do
		(
			
			filterMaterialList edt1.text
		)
		
		on edt1 changed txt do
		(
			filterMaterialList edt1.text
			print listLength
		)
		
		on edt1 entered txt do
		(
			filterMaterialList edt1.text
			print listLength			
		)
		
		
-- 			--filterMaterialList txt
-- 			if listLength == 1 then
-- 			(
-- 				makeVrayMtl editString
-- 				edt1.text=""
-- 				filterMaterialList edt1.text
-- 			)
-- 			else
-- 			(
-- 				print listLength
-- 				messagebox "Make sure you filtered the list down to ONE material only!"
-- 			)
-- 		)
		
	)

	createdialog vrayMaterialMakerRoll
)