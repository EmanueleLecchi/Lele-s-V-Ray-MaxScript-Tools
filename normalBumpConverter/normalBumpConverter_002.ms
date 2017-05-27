(
	local theMaps =(getclassinstances Normal_Bump)
	for oldTex in theMaps do
	(
-- 		print ("Operating on " + oldTex.name)
-- 		print (refs.dependents oldTex)
		newTex=VrayNormalMap name:(uniquename (oldTex.name + "_vrnm_Converted"))
		--
		newTex.normal_map = oldTex.normal_map
		newTex.normal_map_on = oldTex.map1on
		newTex.normal_map_multiplier = oldTex.mult_spin
		newTex.bump_map = oldTex.bump_map
		newTex.bump_map_on = oldTex.map2on
		newTex.bump_map_multiplier = oldTex.bump_spin
		newTex.flip_red = oldTex.flip_red
		newTex.flip_green = oldTex.flip_green
		newTex.swap_red_and_green = oldTex.swap_red_green
			
		replaceinstances oldTex newTex
	)

)
