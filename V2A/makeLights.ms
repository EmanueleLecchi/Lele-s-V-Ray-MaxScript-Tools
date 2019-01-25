undo off
(
	suspendEditing()
	disableSceneRedraw() 
	print "-----Lights-----"
	for i = 1 to 10 do
	(
		windows.processpostedmessages()
		ts=timestamp()
		for i = 1 to 1000 do omnilight()
		delete lights
		print ((timestamp()-ts)/1000.0)
	)
	resumeEditing()
	enableSceneRedraw() 
)

undo off
(
	suspendEditing()
	disableSceneRedraw() 
	print "-----Geo-----"
	for i = 1 to 10 do
	(
		windows.processpostedmessages()
		ts=timestamp()
		for i = 1 to 1000 do sphere()
		delete geometry
		print ((timestamp()-ts)/1000.0)
	)
	resumeEditing()
	enableSceneRedraw() 
)