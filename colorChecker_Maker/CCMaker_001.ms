(
	fn padtoNdigits theString numDigits =
	(
		for i=theString.count to numDigits do theString="0"+theString
		theString
	)
	
	theCols=#( 	
				(color 115 82 68), (color 194 150 130), (color 98 122 157), (color 87 108 67), (color 133 128 177), (color 103 189 170), 
				(color 214 126 44), (color 80 91 166), (color 193 90 99), (color 94 60 108), (color 157 188 64), (color 224 163 46), 
				(color 56 61 150), (color 70 148 73), (color 175 54 60), (color 231 199 31), (color 187 86 149), (color 8 133 161), 
				(color 243 243 243), (color 200 200 200), (color 160 160 160), (color 122 122 122), (color 85 85 85), (color 52 52 52) 
			)
	
	theColNames=#( 	
				"dark skin", "light skin", "blue sky", "foliage", "blue flower", "bluish green", 
				"orange", "purplish blue", "moderate red", "purple", "yellow green", "orange yellow", 
				"blue", "green", "red", "yellow", "magenta", "cyan", 
				"white (0.05)", "neutral 8 (0.23)", "neutral 6.5 (0.44)", "neutral 5 (0.70)", "neutral 3.5 (1.05)", "black (1.50)"
			)				
	row=0
	col=0
	geoToGroup=#()
	for i = 1 to 24 do
	(
		if (mod i 6) == 1  do
		(
			row+=1
			col=0
		)
		matName =("CP_" + (padtoNdigits (i as string) 2) + "_Material_" + theColNames[i]) 
		patchName=("CP_" + (padtoNdigits (i as string) 2) + "_" + theColNames[i])
		theMat=vrayMtl diffuse:theCols[i] name:matName
		thePatch=chamferbox width:10 length:10 height:2 Fillet:0.125 name:patchName wirecolor:theCols[i] material:theMat
		thePatch.pos = [(15 * col), (-15 * row), 0.0]
		col+=1
		append geoToGroup thePatch
	)
	theBase = chamferbox width:(6*10 + 7*5) length:(4*10 + 5*5) height:2 Fillet:0.125 name:"colorCheckerBase" wirecolor:black material:(vrayMtl diffuse:Black name:"colorCheckerBase_Material") pos:[((5*10 + 5*5)/2), (5*10 + 5*5)/-2, -1.9 ]
	append geoToGroup theBase
	theGroup=
	(group geoToGroup name:"V-RayColorChecker" select:true).pos= [0,0,0]
	
)

