(
	local spheroCam = undefined
	local oldRenderOptions= #()
	local oldRenderWidth = oldRenderHeight = 0
	local oldExposure = undefined
	local wasExposureActive = false
	local vr = undefined
	local theBakedSky = undefined
	local theDome = undefined
	local theSun = undefined
	
	fn checkVRay =
	(
		if (renderers.current.classid as string == "#(1941615238L, 2012806412L)" or renderers.current.classid as string == "#(1941615238, 2012806412))") do
		(
			print "V-Ray found!"
			vr=renderers.current
		)
	)
	
	fn collectRenderOptions=
	(
		oldRenderOptions= #()		
		append oldRenderOptions #("options_hiddenLights", vr.options_hiddenLights)
		
		append oldRenderOptions #("camera_type", vr.camera_type)
		append oldRenderOptions #("camera_overrideFOV", vr.camera_overrideFOV)
		append oldRenderOptions #("camera_fov", vr.camera_fov)
		
		append oldRenderOptions #("imageSampler_type_new", vr.imageSampler_type_new)
		append oldRenderOptions #("twoLevel_baseSubdivs", vr.twoLevel_baseSubdivs)
		append oldRenderOptions #("twoLevel_adaptiveEnable", vr.twoLevel_adaptiveEnable)
		append oldRenderOptions #("twoLevel_bucket_width", vr.twoLevel_bucket_width)
		append oldRenderOptions #("twoLevel_bucket_lockSize", vr.twoLevel_bucket_lockSize)
		append oldRenderOptions #("gi_on", vr.gi_on)
		

		oldExposure =  SceneExposureControl.exposureControl
		if oldExposure != undefined and ( (classof oldExposure == Physical_Camera_Exposure_Control) or (classof oldExposure == VRay_Exposure_Control) )then 
		(
			wasExposureActive = SceneExposureControl.exposurecontrol.active
		)
			
		else
		wasExposureActive = false
		
		oldRenderWidth = renderWidth
		oldRenderHeight = renderHeight
	)
	
	fn createSpheroCam =
	(
		spheroCam = physical position:[0,0,0] targeted:false specify_fov:on fov:90.0
		rotate spherocam (angleaxis 90 [1,0,0])
		spheroCam
	)
	
	fn prepScene =
	(
		theDome = (for l in lights where (classof l == vrayLight and l.type==1 and l.texmap_on and (classof l.texmap != vrayHDRI or classof l.texmap != bitmapTexture ) )collect l)[1]
		theSun =  (for l in lights where classof l == vraysun collect l)[1]
		theDome.isHidden = theSun.isHidden = false
		--hide everithing but the dome
		select spheroCam
		selectmore theDome
		selectmore theSun
		IsolateSelection.EnterIsolateSelectionMode()
		clearSelection()
	)

	fn setRenderOptions =
	(
		-- turn hidden lights off
		vr.options_hiddenLights=false
		--set camera to spherical
		vr.camera_type=1
		vr.camera_overrideFOV=true
		vr.camera_fov=360
		--set simple render settings
		vr.imageSampler_type_new=0
		vr.twoLevel_baseSubdivs=2
		vr.twoLevel_adaptiveEnable=false
		vr.twoLevel_bucket_width=128
		vr.twoLevel_bucket_lockSize=true
		vr.gi_on=false
		--set image resolution
		renderWidth =4096
		renderHeight=2048
	)
	

	fn bakeToExr =
	(
		oldRawOn=vr.output_saveRawFile
		oldRawPath=vr.output_rawFileName
		theBakedSky=(maxFilePath + @"bakedVRaySky.exr")
		vr.output_saveRawFile=true
		vr.output_rawFileName=theBakedSky
		render camera:spheroCam vfb:off
		vr.output_saveRawFile=oldRawOn
		if oldRawPath != undefined do vr.output_rawFileName=oldRawPath
	)
	
	fn loadIntoDome =
	(
		theMap = vrayhdri hdrimapname:theBakedSky name:(uniqueName "bakedVRaySky_")
		theDome.texmap = theMap
		theSun.enabled=false
	)
	
	fn restoreRenderOptions =
	(
		for pv in oldRenderOptions do
		(
			setProperty vr (pv[1] as name) pv[2]
		)
		
		if wasExposureActive do SceneExposureControl.exposurecontrol.active=true

		renderWidth = oldRenderWidth
		renderHeight = oldRenderHeight
	)
	
	fn cleanupScene =
	(
		
		delete spheroCam
		IsolateSelection.ExitIsolateSelectionMode()
	)
	
	checkVRay()
 	collectRenderOptions()
 	createSpheroCam()
	prepScene()
 	setRenderOptions()
	bakeToExr()
	loadIntoDome()
	restoreRenderOptions()
	cleanupScene()
	shellLaunch maxfilepath ""
	
)

