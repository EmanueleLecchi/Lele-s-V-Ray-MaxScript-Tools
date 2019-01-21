(
	global clocker
	try (destroyDialog clocker) catch()
	
	local st=totTime=0.0
	rollout clocker "Clocker" width:336 height:136
	(
		button 'btn1' "Start Render!" pos:[8,8] width:320 height:48 align:#left
		button 'btn2' "Stop Timer!" pos:[8,64] width:320 height:64 align:#left
		
		on btn1 pressed do
		(
			st=timestamp()
			setFocus clocker.btn2
			max quick render
		)
		on btn2 pressed do
		(
			totTime=(timestamp()-st)/1000.
			if totTime>=86400 do totTime-=86400
			print totTime
			st=totTime=0.0
		)
	)
	
	createDialog clocker
	setFocus clocker.btn1
	
)