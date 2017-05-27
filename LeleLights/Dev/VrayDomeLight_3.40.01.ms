plugin light VRayDomeLight name:"VRayDomeLight" category:"VRay" extends:vrayLight
(
	tool create
	(
		local p1=[0,0,0]
		local p2=[0,0,0]
 		local theLight
		
		on mousePoint click do
		(
			if click == 1 do 
			(
				if keyboard.ControlPressed do
				(
					for p in (getclassinstances vraylight target:rootnode) where (p.type==1 and p.on == true) do 
					(
						delete (refs.dependentNodes p)
					)
				)
				
				theLight=VRayLight type:1 name:(uniquename("VRayDomeLight")) multiplier:1 size0:1 pos:[0,0,0]		
				if environmentMap != undefined and useEnvironmentMap do 
				(
					theLight.texMap_on=true
					theLight.texMap=environmentMap
					theLight.texmap_resolution=2048
					useEnvironmentMap = false
				)
				select theLight
				#stop				
			)
		)
	)
)



