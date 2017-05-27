plugin light VRayDiscLight name:"VRayDiscLight" category:"VRay"
(
	tool create
	(
		local p1=[0,0,0]
		local p2=[0,0,0]
 		local theLight
		
		on mousePoint click do
		(
			if click == 1 then 
			(
				coordsys grid
				(
					p1=gridPoint					
					theLight=VRayLight type:4 pos:p1 size0:0 name:(uniquename("VRayDiscLight")) multiplier:30
				)
			)
		)
		on mouseMove click do
		(
			if click == 2 then
			(
				coordsys grid
				(
					p2=gridPoint
					diff=p2-p1
					theLight.pos=(diff/2)+p1
					theLight.size0=diff.x/2
				)
			)
			else if click == 3 do 
			(
				select theLight
				theLight=p1=p2=undefined
				#stop

			)
		)
	)
)
