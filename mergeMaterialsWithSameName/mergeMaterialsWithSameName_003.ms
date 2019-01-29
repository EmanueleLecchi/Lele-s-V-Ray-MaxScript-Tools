macroscript VRayDuplicateMaterialCondenser 
	category:"VRay"
	buttonText:"Duplicate Material Condenser"
	toolTip: "Duplicate Material Condenser"
(
	-- globals
	global condenserRoll
	try (destroyDialog condenserRoll) catch()
	-- locals
	SEModeOn=false
	timeSliderWasVisible=undefined
	trackBarWasVisible=undefined
	statusPanelWasVisible=undefined
	expertModeWasActive=undefined
	matEditorWasOpen=undefined
	doUndo = on
	initialMaterials = 0
	totalGeo = 0
	finalMaterials = 0
	timeTaken = 0
	showMsgBox = true
	
	--Ancillary Functions
	fn resetUIStatus = 
	(
		timeSliderWasVisible=undefined
		trackBarWasVisible=undefined
		statusPanelWasVisible=undefined
		expertModeWasActive=undefined
		matEditorWasOpen=undefined		
	)
	
	fn getUIStatus =
	(
		timeSliderWasVisible=timeslider.isVisible()
		trackBarWasVisible=trackbar.visible
		statusPanelWasVisible=statusPanel.visible
		expertModeWasActive=cui.getExpertMode() 
		matEditorWasOpen = MatEditor.isOpen()
	)	
	
	fn setSuperExpertMode status =
	(
		if status then 		--if the bool is true/1/on then 
		( 
			getUIStatus()	--we gather the UI status right before  changing it
			
			timeslider.Setvisible false		--turn off the time slider
			trackbar.visible = false		--turn off the track bar
			cui.expertModeOn()				-- set the UI in expert mode
			statusPanel.visible = false		--hide the status bar as well (consider NOT doing this if showing a progressbar.
			MatEditor.close()
			disableSceneRedraw() 			
			suspendEditing() --this is like moving to the creation panel, in that it doesn't update the UI, regardless of what's active in the UI. new from max 7, i think. First time i use it! :P
			disableRefMsgs()
		)
		
		else 				--if the bool is false/0/off, then 
		(
			--we return the UI to its original state, if those states were correctly gathered, otherwise we default to the standard UI visibility setup
			if timeSliderWasVisible != undefined then 
			(
				timeslider.Setvisible timeSliderWasVisible
			)
			else 
			(
				timeslider.Setvisible true	
			)
			
			if trackBarWasVisible != undefined then 
			(
				trackbar.visible = trackBarWasVisible 
			)
			else 
			(
				trackbar.visible = true
			)
			
			if expertModeWasActive != undefined then	
			(
				if not expertModeWasActive do cui.expertModeOff()
			)
			else 
			(
				cui.expertModeOff()
			)
			
			if statusPanelWasVisible != undefined then 
			(
				statusPanel.visible = statusPanelWasVisible 
			)
			else 
			(
				statusPanel.visible = true
			)
			
			if matEditorWasOpen != undefined do 
			(
				if matEditorWasOpen do matEditor.open()
			)
			enableSceneRedraw()
			resumeEditing()
			enableRefMsgs()
		)
	)
	--Main Function
	fn uniquifyMaterials = --bhahahah!
	(
-- 		allmats = for m in scenematerials collect m
		initialMaterials = scenematerials.count
		allHashes =  #()
		print ("Parsing and hashing " + initialMaterials as string +" materials.")
		i=0
		for m in scenematerials do
		(
			windows.processPostedMessages()
			i+=1
			hashStr = stringstream ""
			print (classOf m) to:hashStr
			print (m.name) to:hashStr
			for p in (getPropNames m) do
			(
				print p to:hashStr
				print ((getproperty m p) as string) to:hashStr
			)
			append allHashes #(m,(dotNetObject "System.String" hashStr).GetHashCode())
			condenserRoll.pb1.value = (	i as float / initialMaterials) * 100
		)
		
		for i = allHashes.count to 2 by -1 do
		(
			if allHashes[i][2] ==  allHashes[i-1][2] do
			(
				deleteItem allHashes i
			)
		)

-- 		free allMats
		print ("Parsing and Hashing " + geometry.count as string + " geometry nodes.")
		allGeo = #()
		i = 0
		totalGeo = (for g in geometry where g.material != undefined collect g )
		for g in totalGeo do
		(
			windows.processPostedMessages()
			i+=1
			--calculate material hash
			m=g.material
			hashStr=stringStream ""
			print (classOf m) to:hashStr
			print (m.name) to:hashStr
			for p in (getPropNames m) do
			(
				print p to:hashStr
				print ((getproperty m p) as string) to:hashStr
			)
			append allGeo #(g,(dotNetObject "System.String" hashStr).GetHashCode())
			condenserRoll.pb2.value = (i as float / totalGeo.count ) * 100
		)
		i=0
		for g in allGeo do
		(
			windows.processPostedMessages()
			i+=1
			for h in allHashes do
			(
				windows.processPostedMessages()
				if h[2] == g[2] do --check hashes
				(
					g[1].material = h[1]
				)
			)
			condenserRoll.pb3.value = ( i as float / totalGeo.count )  * 100
		)
		freescenebitmaps()
		gc light:true
		UpdateSceneMaterialLib() 
		finalMaterials = scenematerials.count
	)
	
	--UI
	rollout condenserRoll "Duplicate Material Condenser" width:168 height:112
	(
		radiobuttons 'rdo1' "" pos:[8,8] width:158 height:16 labels:#("Undo On", "Undo Off") columns:2 align:#left
		button 'btn1' "Clean Up Materials" pos:[8,32] width:152 height:16 align:#left
		progressBar 'pb1' "" pos:[8,56] width:152 height:14 color:(color 255 0 0) align:#left
		progressBar 'pb2' "" pos:[8,72] width:152 height:14 color:(color 255 255 0) align:#left
		progressBar 'pb3' "" pos:[8,88] width:152 height:14 color:(color 0 255 0) align:#left
		
		on rdo1 changed state do
		(
			if state == 1 then doUndo = on else doUndo = off
		)
		on btn1 pressed do
		(
			pb1.value = pb2.value = pb3.value = 0
			setSuperExpertMode on
			ts=timestamp()
			undo (doUndo)
			(
				try ( uniquifyMaterials() )
				catch
				(
					print "An error occurred! Please send a scene copy to Lele!"
					setSuperExpertMode off
				)
				timeTaken = ((timestamp()-ts)/1000.) 
				setSuperExpertMode off	
				
				if showMsgBox do 
				(
					messageBox ("The script condensed " + initialMaterials as string + " materials across " + totalGeo.count as string + " nodes \ndown to " + finalMaterials as string + " in " + timeTaken as string +" seconds.")
				)
				print ("The script condensed " + initialMaterials as string + " materials across " + totalGeo.count as string + " nodes \ndown to " + finalMaterials as string + " in " + timeTaken as string +" seconds.")
			)
		)
	)

	createDialog condenserRoll

)
	
