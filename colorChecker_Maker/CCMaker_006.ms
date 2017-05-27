(
	fn padtoNdigits theString numDigits =
	(
		for i=theString.count to (numDigits-1) do theString="0"+theString
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
		
	fn inverseGamma theColor theGamma =
	(
		newCol=theColor as point4
		for i=1 to 4 do
		(
			newCol[i] = newCol[i]^theGamma
		)
		newCol
	)
	
	fn makeColorChecker showGrayToo=
	(
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
			theColor=inverseGamma theCols[i] 1
			theMat=vrayMtl texMap_diffuse:(vrayColor red:theColor[1] green:theColor[2] blue:theColor[3] color_gamma:2.2) name:matName
			showTextureMap theMat on
			thePatch=chamferbox width:10 length:10 height:2 Fillet:0.125 name:patchName wirecolor:(theColor as color) smooth:0 material:theMat
			thePatch.pos = [(15 * col), (-15 * row), 0.0]
			col+=1
			append geoToGroup thePatch
		)
		theBlackBase = chamferbox width:(6*10 + 7*5) length:(4*10 + 5*5) height:2 Fillet:0.125 name:"colorCheckerBlackBase" smooth:0 wirecolor:black material:(vrayMtl diffuse:Black reflection:(color 64 64 64) reflection_glossiness:0.5 name:"colorCheckerBlackBase_Material") pos:[((5*10 + 5*5)/2), (5*10 + 5*5)/-2, -1.9 ]
		append geoToGroup theBlackBase
		
		theGrayBase = chamferbox width:(6*10 + 7*5) length:(4*10 + 5*5) height:2 Fillet:0.125 name:"colorCheckerGrayBase" smooth:0 wirecolor:black material:(vrayMtl texmap_diffuse:(vrayColor red:0.6 green:0.6 blue:0.6 color_gamma:2.2) name:"colorCheckerGrayBase_Material") pos:[((5*10 + 5*5)/2), (5*10 + 5*5)/-2, -3.9 ]
		append geoToGroup theGrayBase
		clearSelection() 
		theGroup = group geoToGroup name:(uniquename "V-RayMiniColorChecker") select:true 
		CenterPivot theGroup
		theGroup.pos=[0,0,0]
		
		if showGrayToo do 
		(
			maxOps.CloneNodes theGroup expandHierarchy:true cloneType:#instance newNodes:&theNewChecker
			in coordsys local 
			(
				theNewChecker[1].rotation.y= 180
				move theNewChecker[1] [-100,0,.75]
				clearSelection() 
				select theNewChecker[1]
			)
		)
	)
	
	makeColorChecker true
)
