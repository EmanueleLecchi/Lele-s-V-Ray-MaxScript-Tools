plugin light VRayArealight name:"VRayAreaLight" category:"VRay"
(
	tool create
	(
		local p1=p2=[0,0,0]
		local theLight
		
		on mousePoint click do
		(
			if click == 1 then 
			(
				coordsys grid
				(
					p1=gridPoint					
					theLight=VRayLight type:0 pos:p1 size0:0 size1:0 name:(uniquename("VRayArealLight"))
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
					theLight.size1=diff.y/2
				)
			)
			else if click == 3 do 
			(
				theLight=p1=p2=undefined
				#stop

			)
		)
	)
)
