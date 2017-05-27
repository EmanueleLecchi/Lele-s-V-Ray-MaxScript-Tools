(
	global AFRoll
	try (destroyDialog AFRoll)
	catch()
	
	local theCams=#()
	local theObjs=#()
	local theDists=#()
	local doOne = false
	
	
	fn init =
	(
		theCams=#()
		theObjs=#()
		theDists=#()		
	)
	
	fn AFtheCams theCamz=
		(
			local theObjs=#()
			for C in theCamz do
			(
				startTime=timestamp()				--timing starts
				coordSysTM =(C.transform)			--grab Camera TM
				invCoordSysTM = inverse coordSysTM	--invert it (to cast a ray INTO the scene along the view direction)
				if AFRoll.objBtn.object ==undefined then 
				(
					theObjs= for o in geometry where not o.ishidden collect o
				) 
				else 
				(
					theObjs[1]=AFRoll.objBtn.object
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
-- 							wastargeted=C.targeted
							theDist =amin theDists
							thePos=findItem theDists theDist
							theIntObj=theObjs[thePos]
		-- 					print ((theDist as string)+" " +theIntObj.name )
							C.focus_distance= theDist
							C.specify_focus=true
-- 							C.targeted=wastargeted
						)
						else		--max physcam
						(
-- 							wastargeted=C.targeted
							theDist =amin theDists
							thePos=findItem theDists theDist
							theIntObj=theObjs[thePos]
		-- 					print ((theDist as string)+" " +theIntObj.name )
							C.focus_distance= theDist
							C.specify_focus=1
-- 							C.targeted=wastargeted						
						)
					) 
				else 
					(
						print ("sorry, no object was found in the center of the screen for "+ C.name)
					)
					
				print ("It took "+(timestamp()-startTime) as string+" ms. for "+C.name+" to choose and intesect "+theObjs.count as string+" objects over a total of " +geometry.count as string +" objects")
			)
		)
	

	rollout AFRoll "Auto-Focus Physical Cameras" width:296 height:72
	(
		fn Physcam_filt obj = (classof obj == VRayPhysicalCamera or classof obj == Physical)
		fn geom_filt obj = superclassof obj == GeometryClass 
			
		pickbutton 'camBtn' "All Cameras" pos:[152,8] width:136 height:24 align:#left filter:Physcam_filt	toolTip:"Click this and select a camera in your scene to AF only that one, \nor leave it as it is to AF all the cameras in the scene"
		pickbutton 'objBtn' "Full Auto-Focus" pos:[8,8] width:136 height:24 align:#left filter:geom_filt toolTip:"Leave as is for full auto-focus, or pick an object to attempt focusing on it"
		button 'goBtn' "Go!" pos:[8,40] width:280 height:24 align:#left
		
		local isrolledup = false

		on AFRoll open do
		(
			init()
		)
		on camBtn picked obj do
		(
			init()
			camBtn.caption=camBtn.object.name
			doOne=True
		)
		on goBtn pressed do
		(
			init()			
			if doOne then
			(
				theCams[1]=camBtn.object
			)
			else
			(
				theCams=for C in Cameras where (classof C == VRayPhysicalCamera) or (classof C == Physical) collect C
			)

			afthecams theCams
		)
		on objBtn picked obj do
		(
				objBtn.caption=obj.name
		)
	)
	
	createdialog AFRoll
)