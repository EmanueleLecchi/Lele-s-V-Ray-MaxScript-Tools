plugin light VRayDomeLight name:"VRayDomeLight" category:"VRay"
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
				theLight=VRayLight type:1 name:(uniquename("VRayDomeLight")) multiplier:30 size0:0 pos:[0,0,0]		
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
		
-- 		on mouseMove click do
-- 		(
-- 			print theLight
-- 			if click == 2 then
-- 			(
-- 				if viewTransformed then
-- 				(
-- 					coordSys (viewport.getTM())
-- 					(
-- 						viewSize=getViewSize()
-- 						viewCenter=viewSize/2
-- 						screenSizePercent=[(abs (mouse.pos.x-viewCenter.x)/viewCenter.x as float), (abs (mouse.pos.y-viewCenter.y)/viewCenter.y as float)]
-- 						screenSize=(mapScreenToView (getViewSize()) -10 )
-- 						theLight.size0=sqrt((screenSize.x*screenSizePercent.x)^2 + (screenSize.y*screenSizePercent.y)^2)
-- 					)
-- 				)
-- 				else
-- 				(
-- 					coordsys grid
-- 					(
-- 						p2=gridPoint
-- 						diff=p2-p1
-- 						if keyboard.controlPressed then
-- 						(
-- 							theLight.size0=abs(diff.x)
-- 							theLight.pos=p1
-- 						)
-- 						else
-- 						(
-- 							theLight.size0=abs(diff.x/2)
-- 							theLight.pos=(diff/2)+p1
-- 						)							
-- 					)
-- 				)
-- 			)
-- 			
-- 			else if click == 3 then 
-- 			(
-- 				print "isTargeted"
-- 				print isTargeted
-- 				if viewTransformed then
-- 				(
-- 					viewTransformed=false
-- 					#stop
-- 				)
-- 				else
-- 				(
-- 					if isTargeted then
-- 					(
-- 						print "targeted!"
-- 						theLight.targeted=true
-- 						theTarget=theLight.target
-- 						coordsys grid
-- 						(
-- 							p3=gridPoint
-- 							theTarget.pos=p3
-- 						)
-- 					)
-- 					else
-- 					(
-- 						select theLight
-- 						theLight=p1=p2=isTargeted=undefined
-- 						#stop
-- 					)
-- 				)
-- 			)
-- 			else if click == 4 do 
-- 			(
-- 				select theLight
-- 				theLight=p1=p2=isTargeted=undefined
-- 				#stop
-- 			)
-- 		)
	)
)
