plugin light VRayArealight name:"VRayAreaLight" category:"VRay"
(
	tool create
	(
		local p1=[0,0,0]
		local p2=[0,0,0]
		local theLight=undefined
		local theTarget=undefined
		local isTargeted=false
		local directCreation=false
		
		on mousePoint click do
		(
			if click == 1 do 
			(
				if keyboard.shiftPressed then	--direct creation mode
				(
					theLight=VRayLight type:0 name:(uniquename("VRayAreaLight")) multiplier:30 					
					theTM=inverse(viewport.getTM())
					
					theSize = (mapScreenToView (getViewSize()) 25 )

					theLight.size0=abs theSize.x
					theLight.size1=abs theSize.y
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
							theLight=VRayLight type:0 pos:p1 size0:0 size1:0 name:(uniquename("VRayAreaLight")) multiplier:30 
							isTargeted=true
						)
						else
						(
							theLight=VRayLight type:0 pos:p1 size0:0 size1:0 name:(uniquename("VRayAreaLight")) multiplier:30 targeted:false
							isTargeted=false
						)
					)
				)
			)
		)
		on mouseMove click do
		(
-- 			if directCreation do #stop
			if click == 2 then
			(
				coordsys grid
				(
					p2=gridPoint
					diff=p2-p1
-- 					thePos=[diff.x,diff.y,diff.z]+p1

					
					if keyboard.controlPressed then
					(
						theLight.size0=abs(diff.x)
						theLight.size1=abs(diff.y)
						theLight.pos=p1
					)
					else
					(
						theLight.size0=abs(diff.x/2)
						theLight.size1=abs(diff.y/2)
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
			else if click == 4 do 
			(
				select theLight
				theLight=p1=p2=isTargeted=undefined
				#stop
			)
		)
	)
)
