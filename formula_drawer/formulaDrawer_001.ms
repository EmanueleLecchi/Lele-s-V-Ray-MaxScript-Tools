(
	
	
	
	global splineDrawerRoll
	try (destroyDialog splineDrawerRoll) catch()

	local theSpline1=theSpline2=undefined
	local imageMax= shoulderStrength = linearStrength = linearAngle = toeStrength = toeNumerator = toeDenominator = toeAngle = linearWhitePointValue = 0.0
	
	fn resetToDefaults =
	(
				splineDrawerRoll.spn1.value = 11.2
				splineDrawerRoll.spn2.value = 0.22
				splineDrawerRoll.spn3.value = 0.1
				splineDrawerRoll.spn4.value = 0.2
				splineDrawerRoll.spn5.value = 0.01
				splineDrawerRoll.spn6.value = 0.01
				splineDrawerRoll.spn7.value = 0.3
				splineDrawerRoll.ckb1.checked=false
	)	
	fn setVars =
	(
				imageMax= splineDrawerRoll.spn1.value as double
				shoulderStrength = splineDrawerRoll.spn2.value as double
				linearStrength = splineDrawerRoll.spn3.value as double
				linearAngle = splineDrawerRoll.spn4.value as double
				toeStrength = splineDrawerRoll.spn5.value as double
				toeNumerator = splineDrawerRoll.spn6.value as double
				toeDenominator = splineDrawerRoll.spn7.value as double
				toeAngle = toeNumerator/toeDenominator	
				linearWhitePointValue = 	( 	(imageMax*(shoulderStrength*imageMax+linearStrength*linearAngle)+toeNumerator*toeDenominator) /
												(imageMax*(shoulderStrength*imageMax+linearStrength)+toeStrength*toeDenominator)
											) 	- 
											( toeAngle )
	)	
	
	fn createSplines = 
	(
		theSpline1= splineShape steps:0 wirecolor:red
		addnewSpline theSpline1			
		theSpline2= splineShape steps:0 wirecolor:green
		addnewSpline theSpline2
		counter=10000
		for i=1 to counter do
		(
			percent=(i as float / counter)  /* 0.0 - 1.0 */
			theX=percent  
			theZ=percent * imageMax 
			addKnot theSpline1 1 #corner #line [theX,0,theZ]
			addKnot theSpline2 1 #corner #line [theX,0,theX]
		)
		updateShape theSpline2
		updateShape theSpline1
		theSpline1
	)
	
	fn setPoints theSpline doClamp= 
	(
		counter=10000
		for i=1 to counter do
		(
			percent=(i as float / counter) 
			theVal=percent * imageMax 
			theZ=	(( 	(theVal*(shoulderStrength*theVal+linearStrength*linearAngle)+toeNumerator*toeDenominator) /
						(theVal*(shoulderStrength*theVal+linearStrength)+toeStrength*toeDenominator)
					) 	- 
					( toeNumerator/toeDenominator ))/ (linearWhitePointValue)
			if doClamp do theZ = aMax #(theZ, 0.0)				
			theTriplet=[percent,0,(theZ)]
			setKnotPoint theSpline 1 i theTriplet
		)
		updateShape theSpline
	)
	







	rollout splineDrawerRoll "splineDrawerRoll" width:184 height:520
	(

		button 'btn1' "Create Shape" pos:[16,24] width:152 height:48 align:#left
		spinner 'spn1' "" pos:[116,168] width:60 height:16 range:[0.0,100,11.2] scale:0.001 align:#left
		spinner 'spn2' "" pos:[116,280] width:44 height:16 range:[0.0001,1.0,0.22] scale:0.001 align:#left
		spinner 'spn3' "" pos:[116,304] width:44 height:16 range:[0.0001,1.0,0.30] scale:0.001 align:#left
		spinner 'spn4' "" pos:[116,328] width:44 height:16 range:[0.0001,1.0,0.10] scale:0.001 align:#left
		spinner 'spn5' "" pos:[116,352] width:44 height:16 range:[0.0001,1.0,0.20] scale:0.001 align:#left
		spinner 'spn6' "" pos:[116,376] width:44 height:16 range:[0.0001,1.0,0.01] scale:0.001 align:#left
		spinner 'spn7' "" pos:[116,400] width:44 height:16 range:[0.0001,1.0,0.30] scale:0.001 align:#left
		checkbox 'ckb1' "" pos:[116,188] width:44 height:16 range:[0.0001,1.0,0.30] scale:0.001 align:#left checked:false
		
		button 'btn2' "Update Shape" pos:[16,464] width:152 height:40 enabled:false align:#left
		button 'btn3' "Reset Curve Settings" pos:[16,104] width:152 height:40 enabled:true align:#left
		
		groupBox 'grp5' "Filmic" pos:[16,256] width:152 height:168 align:#left
		GroupBox 'grp8' "Generate And Display Output" pos:[8,440] width:168 height:72 align:#left
		label 'lbl4' "Shoulder Strenght:" pos:[24,280] width:88 height:16 align:#left
		label 'lbl5' "Linear Strenght:" pos:[24,304] width:88 height:16 align:#left
		label 'lbl6' "Linear Angle:" pos:[24,328] width:88 height:16 align:#left
		label 'lbl7' "Toe Strenght:" pos:[24,352] width:88 height:16 align:#left
		label 'lbl8' "Toe Numerator:" pos:[24,376] width:88 height:16 align:#left
		label 'lbl9' "Toe Denominator:" pos:[24,400] width:88 height:16 align:#left	
		label 'lbl2' "ImageMax:" pos:[24,168] width:64 height:16 align:#left		
		label 'lbl10' "Clamp Negatives:" pos:[24,188] width:88 height:16 align:#left 
			
	
		on btn1 pressed do
		(
			setVars()
			theSpline1 = createSplines()
			btn2.enabled=true
		)
		
		on btn2 pressed do
		(
			setVars()
			setPoints theSpline1 ckb1.checked
		)
		
		on btn3 pressed do
		(
			resetToDefaults()
			setVars()
		)
	)
	
	createDialog splineDrawerRoll
)







