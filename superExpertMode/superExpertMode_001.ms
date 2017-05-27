(		-- Start of Local scope 
		
		/*
		First we need to collect the state of the four UI components we'll operate on, to be able to return the UI to the exact starting point the user had.
		*/
		local timeSliderWasVisible=undefined
		local trackBarWasVisible=undefined
		local statusPanelWasVisible=undefined
		local expertModeWasActive=undefined
	
		/*
		Simple function to fill the state UI variables 
		*/
		fn getUIStatus =
		(
			timeSliderWasVisible=timeslider.isVisible()
			trackBarWasVisible=trackbar.visible
			statusPanelWasVisible=statusPanel.visible
			expertModeWasActive=cui.getExpertMode() 
		)
		
		/*
		The function expects a boolean as only parameter.
		*/
		fn setSuperExpertMode status =
		(
			if status then 		--if the bool is true/1/on then 
			( 
				getUIStatus()	--we gather the UI status right before  changing it
				
				timeslider.Setvisible false		--turn off the time slider
				trackbar.visible = false		--turn off the track bar
				cui.expertModeOn()				-- set the UI in expert mode
				statusPanel.visible = false		--hide the status bar as well (consider NOT doing this if showing a progressbar.
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
				
			)
		)
		
		setSuperExpertMode off
)		--End of Local Scope
