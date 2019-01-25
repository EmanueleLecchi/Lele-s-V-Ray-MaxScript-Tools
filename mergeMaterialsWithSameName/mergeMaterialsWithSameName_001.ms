(
	local SEModeOn=false
	local timeSliderWasVisible=undefined
	local trackBarWasVisible=undefined
	local statusPanelWasVisible=undefined
	local expertModeWasActive=undefined
	local matEditorWasOpen=undefined

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
			suspendEditing()

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
			resumeEditing()
		)
	)
	
	fn uniquifyMaterials = --bhahahah!
	(
		allmats = for m in scenematerials collect m
		allHashes =  #()
		print "Parsing and hashing materials."
		for m in allmats do
		(
			hashStr = stringstream ""
			print (classOf m) to:hashStr
			print (m.name) to:hashStr
			for p in (getPropNames m) do
			(
				print p to:hashStr
				print ((getproperty m p) as string) to:hashStr
			)
			append allHashes #(m,(dotNetObject "System.String" hashStr).GetHashCode())
		)
		
		for i = allHashes.count to 2 by -1 do
		(
			if allHashes[i][2] ==  allHashes[i-1][2] do
			(
				deleteItem allHashes i
			)
		)

		free allMats
		print "Parsing and Hashing geometry."
		allGeo = #()
		for g in geometry where g.material != undefined do
		(
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
		)
		for g in allGeo do
		(
			for h in allHashes do
			(
				if h[2] == g[2] do --check hashes
				(
					g[1].material = h[1]
				)
			)
		)
		freescenebitmaps()
		gc light:true
		UpdateSceneMaterialLib() 
		print "all done."
	)

	setSuperExpertMode on
	try ( uniquifyMaterials() )
	catch
	(
		print "An error occurred! Please send a scene copy to Lele!"
		setSuperExpertMode off
	)
	setSuperExpertMode off
	
)