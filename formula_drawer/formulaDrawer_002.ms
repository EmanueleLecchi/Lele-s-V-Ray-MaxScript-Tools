(
	
	
	
	global splineDrawerRoll
	try (destroyDialog splineDrawerRoll) catch()

	local theSpline=undefined
	local sigma=0
	local mu=0
	local xMin = -5.0
	local xMax = 5.0
	
	fn resetToDefaults =
	(
		splineDrawerRoll.spn1.value = 1.0
		splineDrawerRoll.spn2.value = 0.0
	)	
	fn setVars =
	(
		sigma= splineDrawerRoll.spn1.value as double
		mu = splineDrawerRoll.spn2.value as double
	)	
	
	fn createSplines = 
	(
		setVars()
		theSpline= splineShape steps:0 wirecolor:red
		addnewSpline theSpline		
		counter=(xMax-xMin)*100.0
		for i=1 to counter do
		(
			theX=xMin+ (i/100.0)
			theZ=(1.0d0 / (sigma * sqrt(2*Pi)) ) * e ^ ( ((theX-mu)^2) / (2*(sigma^2)) )
			addKnot theSpline 1 #corner #line [theX,0,theZ]
		)
		updateShape theSpline
		theSpline
	)
	
	fn setPoints theSpline = 
	(
		counter=(xMax-xMin)*100.0
		for i=1 to counter do
		(
			theX=xMin+ (i/100.0)
			theZ=(1.0d0 / (sigma * sqrt(2*Pi)) ) * (e ^ (((theX-mu)^2) / (2*(sigma^2))) )
			theTriplet=[theX,0,(theZ)]
			setKnotPoint theSpline 1 i theTriplet
		)
		updateShape theSpline
	)
	







	rollout splineDrawerRoll "splineDrawerRoll" width:184 height:520
	(

		button 'btn1' "Create Shape" pos:[16,24] width:152 height:48 align:#left
		spinner 'spn1' "" pos:[116,280] width:44 height:16 range:[0.0,10.0,1.0] scale:0.001 align:#left
		spinner 'spn2' "" pos:[116,304] width:44 height:16 range:[0.0,10.0,0.0] scale:0.001 align:#left
		
		button 'btn2' "Update Shape" pos:[16,464] width:152 height:40 enabled:false align:#left
		button 'btn3' "Reset Curve Settings" pos:[16,104] width:152 height:40 enabled:true align:#left
		
		GroupBox 'grp8' "Generate And Display Output" pos:[8,440] width:168 height:72 align:#left
		label 'lbl4' "Variance:" pos:[24,280] width:88 height:16 align:#left
		label 'lbl5' "Mean:" pos:[24,304] width:88 height:16 align:#left
			
		
	
		on btn1 pressed do
		(
			theSpline = createSplines()
			btn2.enabled=true
		)
		
		on btn2 pressed do
		(
			setVars()
			setPoints theSpline
		)
		
		on btn3 pressed do
		(
			resetToDefaults()
			setVars()
		)
	)
	
	createDialog splineDrawerRoll
)







