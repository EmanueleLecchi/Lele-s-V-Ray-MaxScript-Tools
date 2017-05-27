(
	global AFRoll
	try (destroyDialog AFRoll)
	catch()
fn AFtheCams theCamz=
	(
		local theObjs=#()
		for C in theCamz do
		(
			startTime=timestamp()				--timing starts
			coordSysTM =(C.transform)			--grab Camera TM
			invCoordSysTM = inverse coordSysTM	--invert it (to cast a ray INTO the scene along the view direction)
			if AFRoll.btn3.object ==undefined then 
			(
				theObjs= for o in geometry where not o.ishidden collect o
			) 
			else 
			(
				theObjs[1]=AFRoll.btn3.object
			)
			camRay=ray coordSysTM.row4 -coordSysTM.row3
			i=0
			theDists=#()
	-- 		theObjs.count
			for o in theObjs do 
				(
					theInt =intersectray o camRay
					--print o as string
					if theInt != undefined do
					(
						daDist=distance theInt.pos camray.pos
						if daDist>0.0 do
							(
								i+=1
								theDists[i]=daDist
							)
					)
				)
				
			if theDists.count !=0 then
				(
					if classOf C == VrayPhysicalCamera then
					(
						wastargeted=C.targeted
						theDist =amin theDists
						thePos=findItem theDists theDist
						theIntObj=theObjs[thePos]
	-- 					print ((theDist as string)+" " +theIntObj.name )
						C.focus_distance= theDist
						C.specify_focus=true
						C.targeted=wastargeted
					)
					else		--max physcam
					(
						wastargeted=C.targeted
						theDist =amin theDists
						thePos=findItem theDists theDist
						theIntObj=theObjs[thePos]
	-- 					print ((theDist as string)+" " +theIntObj.name )
						C.focus_distance= theDist
						C.specify_focus=1
						C.targeted=wastargeted						
					)
				) 
			else 
				(
					print ("sorry, no object was found in the center of the screen for "+ C.name)
				)
				
			print ("It took "+(timestamp()-startTime) as string+" ms. for "+C.name+" to choose and intesect "+theObjs.count as string+" objects over a total of " +geometry.count as string +" objects")
		)
	)
	

	rollout AFRoll "A-F Physcam(s)" width:296 height:64
	(
		fn Physcam_filt obj = classof obj == VRayPhysicalCamera
		fn geom_filt obj = superclassof obj == GeometryClass 
		pickbutton btn1 "A-F One" pos:[152,8] width:64 height:24 filter:Physcam_filt
		button btn2 "A-F All" pos:[224,8] width:64 height:24
		pickbutton btn3 "Full Auto-Focus" pos:[8,8] width:136 height:24 filter:geom_filt toolTip:"Leave as is for full auto-focus, or pick an object to attempt focusing on it"
		
		local isrolledup = false

		on AFRoll open do
		(
			theObjs=#()
			theDists=#()	
		)
		on btn1 picked obj do
		(
			theCams=#()
			theCams+=btn1.object
			btn1.caption=btn1.object.name
			afthecams thecams
		)
		on btn2 pressed do
		(
			theCams=for C in Cameras where (classof C == VRayPhysicalCamera) or (classof C == Physical) collect C
			afthecams theCams
		)
		on btn3 picked obj do
		(
				btn3.caption=obj.name
		)
	)
	
	createdialog AFRoll
)