plugin light VRaySphereLight name:"VRaySphereLight" category:"VRay"
(
	tool create
	(
		local p1=[0,0,0]
		local p2=[0,0,0]
 		local theLight
		local theTarget
		local isTargeted 
		
		on mousePoint click do
		(
			if click == 1 then 
			(
				if keyboard.shiftPressed then	--direct creation mode
				(
					theLight=VRayLight type:2 name:(uniquename("VRaySphereLight")) multiplier:30 					
					theTM=inverse(viewport.getTM())
					
					theSize = (mapScreenToView (getViewSize()) 25 )

					theLight.size0=(aMin #(abs theSize.x , abs theSize.y))
					
					theLight.transform=theTM					
					in coordsys Local move theLight [0,0,-25]
					if keyboard.altPressed do
					(
						theLight.targeted =true
						theLight.Target.pos = theLight.pos
						in coordsys Local move theLight.target [0,0,-25]
					)
					#stop
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
			else if click == 3 then 
			(
				if isTargeted then
				(
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
			else if click == 4 then 
			(
				select theLight
				theLight=p1=p2=isTargeted=undefined
				#stop
			)
			
		)
	)
)
