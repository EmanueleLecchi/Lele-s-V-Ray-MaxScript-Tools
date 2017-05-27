plugin light VRayDomeLight name:"VRayDome" category:"VRay"
(
	tool create
	(
		local p1=[0,0,0]
		local p2=[0,0,0]
 		local theLight
		on mousePoint click do
		(
			with undo on
			(			
				if click == 1 do 
				(
					if keyboard.ControlPressed do
					(
						for p in (getclassinstances vraylight target:rootnode) where (p.type==1) do 
						(
							delete (refs.dependentNodes p)
						)
					)
					
					if keyboard.altPressed do
					(
						for p in (getclassinstances vraylight target:rootnode) where (p.type==1) do 
						(
							p.on=false
						)
					)
					
					if keyboard.shiftPressed do
					(
						in coordsys grid p1=gridPoint					
					)
					
					theLight=VRayLight type:1 name:(uniquename("VRayDomeLight")) multiplier:1 size0:1 pos:p1
					if environmentMap != undefined and useEnvironmentMap then 
					(
						theLight.texMap_on=true
						theLight.texMap=environmentMap
						theLight.texmap_resolution=2048
						useEnvironmentMap = false
						backgroundColor = black
					)
					else
					(
						backgroundColor = black						
					)
					select theLight
					#stop				
				)
			)
		)
	)
)



