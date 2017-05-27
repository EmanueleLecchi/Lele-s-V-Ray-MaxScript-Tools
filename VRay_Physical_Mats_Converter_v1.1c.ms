--Copyright 2007 Emanuele Lecchi
--you're free to modify this script as you wish, as long as the above lines remain in place, 
--and proper credit is given to the original author (me!) in case of public distribution and/or modification
--The script is released under DonationWare: feel free to drop a donation (yeah right!) through paypal @ emanuele_lecchi@hotmail.com


fn fixthemats dodiffuse doreflection diffCoeff reflCoeff isDiffAbs isReflAbs doTheBump isBumpAbs bumpCoeff = 
(
	undo on (
		theMats = getclassinstances vraymtl
		for i in theMats do 
		(
			if dodiffuse do (
				if i.texmap_diffuse != undefined do (
					print "Found Diffuse Map"
					if (hasproperty i.texmap_diffuse "*Output*") or (hasproperty i.texmap_diffuse "*RGB_Multiplier*") do 
					(
						print "Found map with Output or RGB_Level Parameters"
						if isDiffAbs then (
							try (i.texmap_diffuse.RGB_Multiplier =diffCoeff ) catch ()
							try (i.texmap_diffuse.output.RGB_Level =diffCoeff ) catch ()
							try (i.texmap_diffuse.Texture_Output.RGB_Level =diffCoeff ) catch ()
							print ("Multiplied the diffuse Texture RGB Output of the material " + i.name + " to " + diffCoeff as string)
						) else (
							try (i.texmap_diffuse.RGB_Multiplier *=diffCoeff ) catch ()
							try (i.texmap_diffuse.output.RGB_Level *=diffCoeff ) catch ()
							try (i.texmap_diffuse.Texture_Output.RGB_Level *=diffCoeff ) catch ()
							print ("Multiplied the diffuse Texture RGB Output of the material " + i.name + " times " + diffCoeff as string)
						)
					)
					if (not hasproperty i.texmap_diffuse "*Output*")and (not hasproperty i.texmap_diffuse "*RGB_Multiplier*")  do 
					(
						print "About to inset map in output map!"
						oldmap=i.texmap_diffuse
						i.texmap_diffuse = output map1:oldmap name:("output_"+oldmap.name)
						if isDiffAbs then (
							try (i.texmap_diffuse.output.RGB_Level =diffCoeff ) catch ()
							try (i.texmap_diffuse.Texture_Output.RGB_Level =diffCoeff ) catch ()
							print ("Embedded the diffuse Texture of the material " + i.name + " in an Output Map, and multiplied its RGB Output to " + diffCoeff as string)
						) else (
							try (i.texmap_diffuse.output.RGB_Level *=diffCoeff ) catch ()
							try (i.texmap_diffuse.Texture_Output.RGB_Level *=diffCoeff ) catch ()
							print ("Embedded the diffuse Texture of the material " + i.name + " in an Output Map, and multiplied its RGB Output times " + diffCoeff as string)
						)
					)
				)
	
				if (i.texmap_diffuse == undefined) do
				(	
					i.texmap_diffuse = VRayColor name:"VRColor_Diff_"
					i.texmap_diffuse.name = uniquename i.texmap_diffuse.name 
					i.texmap_diffuse.color = i.Diffuse
					if isDiffAbs then (
						i.texmap_diffuse.rgb_multiplier =diffCoeff
					)else (
						i.texmap_diffuse.rgb_multiplier *=diffCoeff
					)
					print ("Changed the Diffuse Colour of the material " + i.name + " with a VRayColor Map, and multiplied to " + diffCoeff as string)
				)
			)
			
			
			
			if doreflection do (
				if i.texmap_reflection != undefined do (
					print "Found reflection Map"
					if (hasproperty i.texmap_reflection "*Output*") or (hasproperty i.texmap_reflection "*RGB_Multiplier*") do 
					(
						print "Found map with Output or RGB_Level Parameters"
						if isreflAbs then (
							try (i.texmap_reflection.RGB_Multiplier =reflCoeff ) catch ()
							try (i.texmap_reflection.output.RGB_Level =reflCoeff ) catch ()
							try (i.texmap_reflection.Texture_Output.RGB_Level =reflCoeff ) catch ()
							print ("Multiplied the reflection Texture RGB Output of the material " + i.name + " to " + reflCoeff as string)
						) else (
							try (i.texmap_reflection.RGB_Multiplier *=reflCoeff ) catch ()
							try (i.texmap_reflection.output.RGB_Level *=reflCoeff ) catch ()
							try (i.texmap_reflection.Texture_Output.RGB_Level *=reflCoeff ) catch ()
							print ("Multiplied the reflection Texture RGB Output of the material " + i.name + " times " + reflCoeff as string)
						)
					)
					if (not hasproperty i.texmap_reflection "*Output*")and (not hasproperty i.texmap_reflection "*RGB_Multiplier*")  do 
					(
						print "About to inset map in output map!"
						oldmap=i.texmap_reflection
						i.texmap_reflection = output map1:oldmap name:("output_"+oldmap.name)
						if isreflAbs then (
							try (i.texmap_reflection.output.RGB_Level =reflCoeff ) catch ()
							try (i.texmap_reflection.Texture_Output.RGB_Level =reflCoeff ) catch ()
							print ("Embedded the reflection Texture of the material " + i.name + " in an Output Map, and multiplied its RGB Output to " + reflCoeff as string)
						) else (
							try (i.texmap_reflection.output.RGB_Level *=reflCoeff ) catch ()
							try (i.texmap_reflection.Texture_Output.RGB_Level *=reflCoeff ) catch ()
							print ("Embedded the reflection Texture of the material " + i.name + " in an Output Map, and multiplied its RGB Output times " + reflCoeff as string)
						)
					)
				)

			if (i.texmap_reflection == undefined ) do
				(	
					if i.reflection != color 0 0 0 do (
						i.texmap_reflection = VRayColor name:"VRColor_Refl_"
						i.texmap_reflection.name = uniquename i.texmap_reflection.name 
						i.texmap_reflection.color = i.reflection
						if isReflAbs then (
						i.texmap_reflection.rgb_multiplier =reflCoeff
					)else (
						i.texmap_reflection.rgb_multiplier *=reflCoeff
					)
					print ("Changed the Reflection Colour of the material " + i.name + " with a VRayColor Map, and multiplied it times " + reflCoeff as string)
	 				)
				)
			)
		if doTheBump do (
				if isBumpAbs then (
								i.texmap_bump_multiplier=bumpCoeff
								)
							else (
								i.texmap_bump_multiplier*=bumpCoeff
							)
				)
		)
	TheMats=#()
	)
)


 
rollout PhMatConvRoll "VRay PhysMat Converter 1.1c" width:304 height:112
(

	checkbox chk1 "Affect Diffuse" pos:[8,8] width:100 height:16 checked:true
	checkbox chk2 "Affect Reflection" pos:[8,32] width:100 height:16 checked:true
	checkbox chk5 "Affect Bump" pos:[8,56] width:92 height:16 enabled:true
	spinner spn1 "Diff. Mult.:" pos:[124,8] width:88 height:16 range:[0,5,0.255] scale:0.001 fieldwidth:40
	spinner spn2 "Refl. Mult.:" pos:[124,32] width:88 height:16 range:[0,5,0.255] scale:0.001 fieldwidth:40
	spinner spn3 "Bump Mult.:" pos:[124,56] width:88 height:16 range:[0,999,1] scale:0.001 fieldwidth:40
	
	
	checkbox chk3 "Relative" pos:[222,8] width:74 height:16
	checkbox chk4 "Relative" pos:[222,32] width:74 height:16
	checkbox chk6 "Relative" pos:[222,56] width:74 height:16
	
	
	button btn1 "Fix The materials!" pos:[8,80] width:288 height:24
	on btn1 pressed do
	(
			fixthemats chk1.state chk2.state spn1.value spn2.value chk3.state chk4.state chk5.state chk6.state spn3.value
		)
	on chk3 changed state do
	(
			chk3.caption = if state then "Absolute" else "Relative"
		)
	on chk4 changed state do
	(
			chk4.caption = if state then "Absolute" else "Relative"
		)
	on chk6 changed state do
	(
			chk6.caption = if state then "Absolute" else "Relative"
			if not state then spn3.value=1 else spn3.value=30
		)
)


createdialog PhMatConvRoll
