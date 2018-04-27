(
	global VRayLightingAnalysisRollout
	try (destroyDialog VRayLightingAnalysisRollout) catch()
	
	local theSel=#()
	local gradientBmp = bitmap 144 24 hdr:false
	fn getLightMetersSelection selectAll =
	(
		if selectAll then 
		(
			theSel= for h in helpers where (classOf h == VRayLightMeter) collect h	
		)
		else
		(
			theSel = for s in selection where (classOf s == VRayLightMeter) collect s		
		)
	)
	
	
	fn setVrayLightMeters controlNum = 
		(
			rc=VRayLightingAnalysisRollout

			for l in theSel do
				(
					case of
					(
						(controlNum==1):(l.active=rc.chk1.checked)
						(controlNum==2):(l.width=rc.spn1.value)
						(controlNum==3):(l.length=rc.spn2.value)
						(controlNum==4):(l.wsegs=rc.spn3.value)
						(controlNum==5):(l.lsegs=rc.spn4.value)
						(controlNum==6):(l.orient=rc.chk2.checked)
						(controlNum==7):(l.text=rc.chk3.checked)
						(controlNum==8):(l.colors=rc.chk4.checked)
						(controlNum==9):(l.log=rc.chk5.checked)
						(controlNum==10):(l.min=rc.spn5.value)
						(controlNum==11):(l.max=rc.spn6.value)
						(controlNum==12):(l.dispvalue=rc.ddl1.selection-1)
						(controlNum==13):(l.calc_error=rc.spn7.value)
					)
				)
		)
		

	fn calcVRayLightMeters doSequence= 
		(
			fs=fe=slidertime
			if doSequence do
			(
				fs=animationRange.start
				fe=animationRange.end
			)
			for f=fs to fe do
			(
				slidertime=f
				for l in theSel do 
				(
					if l.active do l.calculate()
				)
			)
		)
	
	fn saveToCSV outFolder doSequence=
	(
		fs=fe=slidertime
		if doSequence do
		(
			fs=animationRange.start
			fe=animationRange.end
		)
		for f=fs to fe do
		(
			slidertime=f
			for l in theSel where (l.total.count!=0 or l.direct.count!=0 or l.indirect.count!=0 or l.daylight.count!=0) do 
				(
					CSVFilename=outFolder+"\\"+(getfilenamefile maxFilename)+"_"+l.name+".f_"+(slidertime.frame as integer) as string+".csv"
					l.saveCSV CSVFilename
				)
		)
	)
		
	fn makeGradient =
	(
		theGradient=bitmap 144 1 hdr:false
		
		theColor=(color 0 0 255)
		thePixels=#()
		setPixels theGradient [0,0] #(theColor)
		for i = 1 to 143 do
		(

			theColor.h-=170.0/143
			setPixels theGradient [i,0] #(theColor)
		)

		copy theGradient gradientBmp
		free theGradient
		gradientBmp
	)
		
		
	rollout VRayLightingAnalysisRollout "V-Ray Lighting Analysis Rollout" width:176 height:504
	(
		checkbox 'chk1' "Active" pos:[8,8] width:48 height:16 checked:true align:#left
		spinner 'spn1' "" pos:[96,56] width:64 height:16 range:[0,1e+08,100] type:#worldunits align:#left
		spinner 'spn2' "" pos:[96,80] width:64 height:16 range:[0,1e+08,100] type:#worldunits align:#left
		spinner 'spn3' "" pos:[96,104] width:64 height:16 range:[2,1000,3] type:#integer scale:1 align:#left
		spinner 'spn4' "" pos:[96,128] width:64 height:16 enabled:true range:[2,1000,3] type:#integer scale:1 align:#left
		checkbox 'chk2' "Orientation" pos:[16,184] width:120 height:16 checked:true align:#left
		checkbox 'chk3' "Viewport text" pos:[16,200] width:120 height:16 checked:true align:#left
		checkbox 'chk4' "Pseudo Colors" pos:[16,216] width:120 height:16 checked:true align:#left
		checkbox 'chk5' "Logarithmic" pos:[32,232] width:120 height:16 align:#left
		spinner 'spn5' "" pos:[96,256] width:64 height:16 range:[0,1e+08,0] type:#float align:#left
		spinner 'spn6' "" pos:[96,280] width:64 height:16 range:[0,1e+08,10000] type:#float align:#left
		dropdownList 'ddl1' "Measured Value" pos:[16,344] width:144 height:40 items:#("Total illuminance", "Direct illuminance", "Indirect illuminance", "Day light factor") align:#left
		spinner 'spn7' "" pos:[112,400] width:48 height:16 range:[0.0001,0.1,0.01] type:#float scale:0.001 align:#left
		button 'btn1' "Calculate" pos:[16,448] width:144 height:20 align:#left
		button 'btn2' "Save to CSV file" pos:[16,472] width:144 height:20 align:#left
		-- 15
		
		GroupBox 'grp1' "Dimensions" pos:[8,32] width:160 height:120 align:#left
		label 'lbl1' "Width:" pos:[16,56] width:64 height:16 align:#left
		label 'lbl2' "Length:" pos:[16,80] width:64 height:16 align:#left
		label 'lbl3' "Width segs:" pos:[16,104] width:64 height:16 align:#left
		label 'lbl4' "Length segs:" pos:[16,128] width:64 height:16 align:#left
		GroupBox 'grp2' "Preview" pos:[8,160] width:160 height:176 align:#left 
 
 
		label 'lbl5' "Min lx:" pos:[16,256] width:64 height:16 align:#left
		label 'lbl6' "Max lx:" pos:[16,280] width:64 height:16 align:#left
		label 'lbl8' "Error tolerance:" pos:[16,400] width:80 height:16 align:#left
		checkbutton 'ckb1' "Selected Only" pos:[80,8] width:84 height:17 align:#left
							
		bitmap 'bmp1' "Bitmap" pos:[16,304] width:144 height:24 align:#left
		checkbox 'chk6' "Animation Range" pos:[16,424] width:144 height:16 align:#left
		
		on VRayLightingAnalysisRollout open do
		(
			bmp1.bitmap=makeGradient()
		)
		on chk1 changed state do
		(
			getLightMetersSelection ckb1.checked
			setVrayLightMeters 1			
		)
		on spn1 changed val do
		(
			getLightMetersSelection ckb1.checked
			setVrayLightMeters 2
		)
		on spn2 changed val do
		(
			getLightMetersSelection ckb1.checked
			setVrayLightMeters 3
		)
		on spn3 changed val do
		(
			getLightMetersSelection ckb1.checked
			setVrayLightMeters 4
		)
		on spn4 changed val do
		(
			getLightMetersSelection ckb1.checked
			setVrayLightMeters 5
		)
		on chk2 changed state do
		(
			getLightMetersSelection ckb1.checked
			setVrayLightMeters 6			
		)
		on chk3 changed state do
		(
			getLightMetersSelection ckb1.checked
			setVrayLightMeters 7			
		)
		on chk4 changed state do
		(
			getLightMetersSelection ckb1.checked
			setVrayLightMeters 8			
		)
		on chk5 changed state do
		(
			getLightMetersSelection ckb1.checked
			setVrayLightMeters 9			
		)
		on spn5 changed val do
		(
			getLightMetersSelection ckb1.checked
			setVrayLightMeters 10
		)
		on spn6 changed val do
		(
			getLightMetersSelection ckb1.checked
			setVrayLightMeters 11
		)
		on ddl1 selected sel do
		(
			getLightMetersSelection ckb1.checked
			chk5.enabled=spn5.enabled=spn6.enabled= (if sel==4 then false else true)
		
			setVrayLightMeters 12		
		)
		on spn7 changed val do
		(
			getLightMetersSelection ckb1.checked
			setVrayLightMeters 13
		)
		on btn1 pressed do
		(
			getLightMetersSelection ckb1.checked
			calcVRayLightMeters chk6.checked
		)
		on btn2 pressed do
		(
			getLightMetersSelection ckb1.checked 
			saveFolder=undefined
			saveFolder=getSavePath caption:"Choose where to save the CSV files:"
			if saveFolder != undefined do 
			( 
				saveToCSV saveFolder chk6.checked
				shelllaunch saveFolder ""
			)
		)
		on ckb1 changed state do
		(
			ckb1.text = if state then "Affect All" else "Selected Only"
			getLightMetersSelection ckb1.checked
		)
	)
	
	
	
	createDialog VRayLightingAnalysisRollout


	
)
