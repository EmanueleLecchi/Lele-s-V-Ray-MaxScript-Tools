plugin Camera OldVRayPhysCam name:"OldVRayPhysCam" classID:#(0x3668563d, 0x3c8094c7) category:"VRay" extends:Freecamera replaceUI:true
( 
	/*
	 Add your own presets simply copying and editing the line below as it is, initial comma included: 
	
	,#("Full 35mm",36,false,1.50,1)
	
	It's a list of five prroperties: the preset name, the film width in mm, if the resolution is fixed by the preset or not, the format width and height, or if the resolution isn't fixed, the A/R and 1.0
	*/
	local thePresetsArray=#(	
								#("Full 35mm",36,false,1.50,1.0),										#("Four Thirds",17.3,false,1.33333,1.0),								#("ARRI ALEXA Mini - Full Sensor",28.25,true,3424,2202),
								#("ARRI ALEXA Mini - MVF-1/Mon",28.25,true,3168,1762),				#("ARRI ALEXA Mini - MXF/ARRIRAW, ProResHD",28.25,true,2880,1620),	#("ARRI ALEXA Mini - ProRes 2K",28.25,true,2868,1612),
								#("ARRI ALEXA Mini - Frameline ARRI 1.85",28.25,true,2880,1558),	#("ARRI ALEXA Mini - Frameline ARRI 2.39",28.25,true,2880,1206),	#("ARRI ALEXA Mini - Frameline ARRI 1.33",28.25,true,2160,1620)		
							
							)	--the added presets need to be ABOVE this bracket, the last of them should NOT end with a comma
					
	local lastselected=0
	fn fillTheList = 
		(
			theRolloutArray=#()	
			for i = 1 to thePresetsArray.count do append theRolloutArray thePresetsArray[i][1]
			theRolloutArray
		)
	
	

	parameters pblock rollout:FBPresets
	(
	)

	rollout FBPresets "Film Back/Sensor Presets:"
	(	
		dropdownlist presets_dd "Scale" items:#()
		
		on FBPresets open do
		(
			if presets_dd.items.count==0 do presets_dd.items=(fillTheList())
			if lastSelected != 0 do presets_dd.selection=lastselected
		)
		
		on presets_dd selected i do
		(
			if lastSelected != i do
			(
				format "Applying % preset" thePresetsArray[i][1]
				lastSelected=i
	-- 			delegate.film_width=thePresetsArray[i][2]
				if thePresetsArray[i][3]==true then		--fixed resolution, change render output
				(
					renderWidth=thePresetsArray[i][4]
					renderHeight=thePresetsArray[i][5]
					renderSceneDialog.commit()
					
				)
				else									--fixed aspect ratio, change that instead
				(
					renderHeight=renderWidth/thePresetsArray[i][4]
					renderSceneDialog.commit()
				)
			)
		)
	)

) 
