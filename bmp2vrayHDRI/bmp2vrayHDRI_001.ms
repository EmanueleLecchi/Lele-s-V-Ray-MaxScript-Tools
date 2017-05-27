(
	theBmpLoaders=getclassinstances bitmaptexture
	theMap=vrayHDRI()
	theMap.hdrimapname=theBmpLoaders[1].filename
-- 	theBmpLoaders[1]=theMap

-- deps = for m in (refs.dependents theBmpLoaders[1]) where classOf m ==  collect m

for m in (refs.dependents theBmpLoaders[1]) where superclassof m==material do 
(
	print "hey!"
	print m
	getSubTexmapSlotName m 2
)

)


refs.dependents (refs.dependsOn (refs.dependents theBmpLoaders[1])[1])