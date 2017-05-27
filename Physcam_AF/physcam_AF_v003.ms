/*
To Do: While intersectRayScene isn't optimal, intersecting with everything, could i use a min focus distance instead?
*/

(
	global AFRoll
	try (destroyDialog AFRoll)
	catch()
	
	local theCams=#()
	local theDists=#()
	local minDist=0
	local doOne = false
	
	
	fn init =
		(
			theCams=#()
			theDists=#()
			minDist=0
			doOne=false
		)
	
	fn AFtheCams theCamz=
		(
			for C in theCamz do
			(
				startTime=timestamp()				--timing starts
				coordSysTM =(C.transform)			--grab Camera TM
				invCoordSysTM = inverse coordSysTM	--invert it (to cast a ray INTO the scene along the view direction)
				camRay=ray coordSysTM.row4 -coordSysTM.row3				
				theDists=#()
				localhits=#()
				localhits = intersectRayScene camRay --intersect with scene
				for l in localHits do
					(
						theDistance=(distance l[2].pos camRay.pos)
						if theDistance > minDist do
						(
							append theDists theDistance
						)
					)
				if theDists.count !=0 then
					(
						if classOf C == VrayPhysicalCamera then
						(
							theDist =amin theDists
							thePos=findItem theDists theDist
							C.focus_distance= theDist
							C.specify_focus=true
							AFRoll.minSpn.value=theDist
						)
						else		--max physcam
						(
							theDist =amin theDists
							thePos=findItem theDists theDist
							C.focus_distance=theDist
							if AFRoll.tgtChk.checked do c.target_distance=theDist			--i HAVE to set target distance for the vp preview to work
							C.specify_focus=1
							AFRoll.minSpn.value=theDist
						)
					) 
				else 
					(
						print ("sorry, no object was found in the center of the screen for "+ C.name)
					)
				print ("It took "+(timestamp()-startTime) as string+" ms. for "+C.name+" to find its focus point in the scene")
			)
		)
	

	rollout AFRoll "Auto-Focus Physical Cameras" width:296 height:88
	(
		fn Physcam_filt obj = (classof obj == VRayPhysicalCamera or classof obj == Physical)

		pickbutton 'camBtn' "All Cameras" pos:[8,8] width:104 height:40 align:#left filter:Physcam_filt toolTip:"Click to Select a camera to AF,\nor leave it as it is to AF all the cameras in the scene"
		spinner 'minSpn' "" pos:[208,8] width:80 height:16 range:[0,1e+016,0] type:#worldunits scale:0.1 align:#left toolTip:"This is useful if you want the camera to avoid focusing, for example, on a pane of glass in front of it.\nLeave alone, and press 'Go!' recursively to focus deeper into the scene. "
		label 'minLbl' "Min. Focus Dist.:" pos:[120,8] width:80 height:16 align:#left 
		checkbox 'tgtChk' "Copy to Target Distance" pos:[120,32] width:160 height:16 checked:true align:#left tooltip:"This copies the focus distance to the target distance of MAX Physical Cameras (max 2016 and up) to make sure the viewport preview shows the DoF.\nUntick if your camera target has specific needs (Animation and so on.)."
		button 'goBtn' "Go!" pos:[8,56] width:280 height:24 align:#left	tooltip:"Let's RayTrace!\nPress recursively to focus further into your scene.\nMake sure you select a single camera when you do so, for the results to be what you intended."
		
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
			minDist=minSpn.value
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
	)
	
	createdialog AFRoll
)