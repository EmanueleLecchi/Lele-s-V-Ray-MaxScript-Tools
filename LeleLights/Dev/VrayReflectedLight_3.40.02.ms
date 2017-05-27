plugin light VRayReflectedLight name:"VRayReflLgt" category:"VRay"
(
	tool create
	(
		local p1=[0,0,0]
		local p2=[0,0,0]
 		local theLight
		local theTarget
		local isTargeted = false
		local viewTransformed = false
		local theTM
		local hadSafeFrames = false
		local theLight
		local theInt,theRay,faceNormal,refVector,theMatrix
		local vpCenter = (point2 (gw.getWinSizeX()) (gw.getWinSizeY()))/2
		local vpQuarter = point2 (vpCenter.x/2) vpCenter.y
	
		
-- 		fn getMesh =
-- 		(
-- 			circleRegion = box2 0 0 0 0
-- 			circleRegion.left = mouse.pos.x-10 
-- 			circleRegion.bottom = mouse.pos.y-10
-- 			circleRegion.right =  1
-- 			circleRegion.top =  1
-- 			theMeshes=(circlePickNode circleRegion crossing:true)
-- 		)
		
		on freeMove do 
		(
			theMeshes=undefined
			setSysCur #select
-- 			gw.getWinSizeY()
			circleRegion = box2 0 0 0 0
			circleRegion.left = mouse.pos.x -- the center of the circle
			circleRegion.bottom = mouse.pos.y
			circleRegion.right = mouse.pos.x/2 -- a point on the circle
			circleRegion.top = mouse.pos.y
-- 			print circleRegion
-- 			circleRegion.left = mouse.pos.x-1 
-- 			circleRegion.bottom = mouse.pos.y-1
-- 			circleRegion.right =  2
-- 			circleRegion.top = 2
			theMeshes=(circlePickNode circleRegion crossing:true)
-- 			theMeshes=getMesh()
-- 			print "cursor selected "
-- 			print theMeshes
			theMesh=undefined
			theDistances=#()
			theOldDistance=100000000000000000000000000000000.0
			thePos=0
			for n=1 to theMeshes.count do
			(
				if classof theMeshes[n]==editable_Mesh then
				(				
					theRay = mapScreenToWorldRay mouse.pos
					theInt = IntersectRay theMeshes[n] theRay
					if theInt != undefined do
					(
						theDistance=(distance theInt.pos theRay.pos)
						if theDistance < theOldDistance do
						(
							theOldDistance= theDistance
							thePos=n
							theDistances[thePos] = theDistance
						)
					
-- 						print ( "Mesh number " + n as string + " " + theMeshes[n].name + " intersected @" + theDistance as string)
					)
					if theDistances.count != 0 do
					(
-- 						print theDistances
-- 						thePos=(finditem theDistances (amin theDistances))
-- 						print ("the pos in the array is " + thePos as string)
						if thePos!= 0 do 
						(
-- 							print ("shortest distance found for " + theMeshes[thePos].name + " @ " + theDistances[thePos] as string)
							theMesh= theMeshes[thePos]
						)
					)
				)
			)

			if theMesh != undefined do
			(
-- 				print ( "selected " + theMesh.name )
				if theInt != undefined then
				(
					faceNormal = theInt.dir
					refVector = 2*(dot faceNormal -theRay.dir) * faceNormal + theRay.dir
					theMatrix = matrixFromNormal (normalize(refVector*250))
					if keyboard.controlPressed do
					(
						theLight= vrayLight type:0 
						theLight.size0=theLight.size1=2.5 
						theLight.name=(uniquename "VrayReflectedLight001")
						theLight.invisible=true
						theLight.transform=theMatrix
						theLight.pos =  (theInt.pos+refVector*250)
					)
				)	
				else
				(
					theInt = faceNormal = refVector = theMatrix = undefined
-- 					print theMatrix
				)
			)
		)
	)
		
		on mousePoint click do
		(
			if click == 1 do 
			(
-- 				print theMatrix
				if theMatrix != undefined do
				(
					theLight= vrayLight type:0 
					theLight.size0=theLight.size1=10 
					theLight.name=(uniquename "VrayReflectedLight001")
					theLight.invisible=true
					theLight.transform=theMatrix
					theLight.pos =  (theInt.pos+refVector*250)
					select theLight
				)
			)
		)
	)

