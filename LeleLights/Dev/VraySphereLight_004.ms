plugin light VRaySphereLight name:"VRaySphereLight" category:"VRay"
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
		
		on mousePoint click do
		(
			if click == 1 do 
			(
				if keyboard.shiftPressed then	--View creation mode
				(
					theLight=VRayLight type:2 name:(uniquename("VRaySphereLight")) multiplier:30 size0:0				
					theTM=inverse(viewport.getTM())
					theLight.transform=theTM
					in coordsys Local move theLight [0,0,-10]
					if not keyboard.controlPressed do
					(						
						theSize = (mapScreenToView (getViewSize()) -10 )
						theLight.size0=(aMin #(abs theSize.x , abs theSize.y))
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
							in coordsys Local move theLight.target [0,0,-10]							
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
							theLight=VRayLight type:2 pos:p1 size0:0 name:(uniquename("VRaySphereLight")) multiplier:30 
							isTargeted=true
						)
						else
						(
							theLight=VRayLight type:2 pos:p1 size0:0 name:(uniquename("VRaySphereLight")) multiplier:30 targeted:false
							isTargeted=false
						)
					)
				)
			)
		)
		on mouseMove click do
		(
-- 			print theLight
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
						theLight.size0=sqrt((screenSize.x*screenSizePercent.x)^2 + (screenSize.y*screenSizePercent.y)^2)
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
							theLight.pos=p1
						)
						else
						(
							theLight.size0=abs(diff.x/2)
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
						#stop
					)
				)
			)
			else if click == 4 do 
			(
				select theLight
				theLight=p1=p2=isTargeted=undefined
				#stop
			)
		)
	)
)
