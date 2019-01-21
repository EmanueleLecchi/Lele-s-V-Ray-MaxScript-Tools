(
	inPath=@"D:\_RnD\VRTRT\I-O\"
	Oaks=getFiles (inPath+"oak*var*.vrmesh")
	Pines=getFiles (inPath+"pine*var*.vrmesh")
	
	for o in Oaks do
	(
		theProxy=vrayProxy filename:o proxy_scale:0.1 flip_axis:true 
		theProxy.name=(getfilenamefile o)
		theProxy.material=meditmaterials[2]
	)
	for p in Pines do
	(
		theProxy=vrayProxy filename:p proxy_scale:0.1 flip_axis:true 
		theProxy.name=(getfilenamefile p)
		theProxy.material=meditmaterials[1]
	)	
)