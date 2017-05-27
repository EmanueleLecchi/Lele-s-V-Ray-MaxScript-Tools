plugin light VRayAreaLight name:"VRayRect" category:"VRay"
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
		

			on mousePoint click do
			(
				with undo on
				(
					if click == 1 do 
					(
						if keyboard.shiftPressed then	--View creation mode
						(
							theLight=VRayLight type:0 name:(uniquename("VRayRectangularLight")) multiplier:30 size0:0 invisible:true			
							theTM=inverse(viewport.getTM())
							theLight.transform=theTM
							in coordsys Local move theLight [0,0,-10]
							if not keyboard.controlPressed do
							(						
		-- 						in coordsys Local move theLight [0,0,9.99]
								theSize = (mapScreenToView (getViewSize()) -10)
								theLight.size0 = abs ( theSize[1] )
								theLight.size1 = abs ( theSize[2] ) 
								theLight.multiplier = ((distance [0,0,0] theLight.pos)) * ((distance [0,0,0] theLight.pos)/10)
							)	
							if keyboard.altPressed do
							(
								theLight.targeted =true
								theLight.Target.pos = theLight.pos
								if viewport.getType()== #view_persp_user or viewport.getType()== #view_camera then
								(
									in coordsys Local move theLight.target [0,0,-viewport.getFocalDistance()]
								)
								else
								(
									in coordsys Local move theLight.target [0,0,0]							
								)
								select theLight
							)
							if keyboard.controlPressed then 
							(
								viewTransformed=true
								select theLight
							)
							else
							(
								select theLight
-- 								displaySafeFrames = hadSafeFrames
								#stop
							)					
						)
						
						else
						(
							coordsys grid
							(
								p1=gridPoint
								if keyboard.altPressed then
								(
									theLight=VRayLight type:0 pos:p1 size0:0 name:(uniquename("VRayAreaLight")) multiplier:30 
									isTargeted=true
								)
								else
								(
									theLight=VRayLight type:0 pos:p1 size0:0 name:(uniquename("VRayAreaLight")) multiplier:30 targeted:false
									isTargeted=false
								)
							)
						)
					)
				)
			)
			on mouseMove click do
			(
				
				if click == 2 then
				(
					if viewTransformed then
					(
						coordSys (viewport.getTM())
						(
							viewSize=getViewSize()
							viewCenter=viewSize/2
							screenSizePercent=[(abs (mouse.pos.x-viewCenter.x)/viewCenter.x as float), (abs (mouse.pos.y-viewCenter.y)/viewCenter.y as float)]
							screenSize=(mapScreenToView (getViewSize()) -10 )
							theLight.size0=abs(screenSize.x*screenSizePercent.x)
							theLight.size1=abs(screenSize.y*screenSizePercent.y)

						)
					)
					else
					(
						coordsys grid
						(
							p2=gridPoint
							diff=p2-p1
							if keyboard.controlPressed then
							(
								theLight.size0=abs(diff.x)
								theLight.size1=abs(diff.y)
								theLight.pos=p1
							)
							else
							(
								theLight.size0=abs(diff.x)/2
								theLight.size1=abs(diff.y)/2
								theLight.pos=(diff/2)+p1
							)							
						)
					)
				)
				
				else if click == 3 then 
				(
	-- 				print "isTargeted"
	-- 				print isTargeted
					if viewTransformed then
					(
						viewTransformed=false
						displaySafeFrames = hadSafeFrames
						#stop					
					)
					else
					(
						if isTargeted then
						(
	-- 						print "targeted!"
							theLight.targeted=true
							theTarget=theLight.target
							coordsys grid
							(
								p3=gridPoint
								theTarget.pos=p3
							)
						)
						else
						(
							select theLight
							theLight=p1=p2=isTargeted=undefined
							displaySafeFrames = hadSafeFrames						
							#stop
						)
					)
				)
				else if click == 4 do 
				(
					select theLight
					theLight=p1=p2=isTargeted=undefined
					displaySafeFrames = hadSafeFrames
					#stop
				)
			)
	)
)
