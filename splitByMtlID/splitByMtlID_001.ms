(
	fn filterNameStrings inString = --needed to filter out bad characters which would confuse the execute() method later
	(
		inString = substituteString inString @"-" "_"
		inString = substituteString inString @"+" "_"
		inString = substituteString inString @"*" "_"
		inString = substituteString inString @"/" "_"
		inString = substituteString inString @" " "_"
		inString = substituteString inString "\"" "_"
		inString = substituteString inString @"?" "_"
		outString = substituteString inString @"!" "_"
		
		outString
	)
	

	--find nodes which have a multiSub material
	msNodes=for g in geometry where (classof g.material == multisubMaterial) and classOf g != forest_Pro collect g
	totCount=msNodes.count
	if msNodes.count !=0 do
	(	
		st=timeStamp()
		actionMan.executeAction 0 "40472"
		clearListener()
		print ("found " + totCount as string + " nodes to process")
		oldMode=getCommandPanelTaskMode()
		setCommandPanelTaskMode mode:#create
		with redraw off
		(
			--iterate through those only	
			p=0
			progressStart "Splitting Nodes by Material IDs"
			
			for n in msNodes do
			(
				p+=1.
				progressUpdate ((p / totCount)*100.)
				print ("processing " + n.name)
				--turn to poly 
				try (n=convertToPoly n) 
				catch ( exit with print ("error converting" + n.name + " to Poly") )
				msMat=n.Material
				windows.processPostedMessages()
				while (polyop.getNumFaces n>0) do
					(
						--find material ID
						mtlID=(polyop.getFaceMatID n 1)
						--generate new object name
						newName=filterNameStrings (n.name+"_mtlID_"+ mtlID as string)
						--find  the right m/s material
						newMat=undefined
						for id=1 to msMat.materialIDList.count where msMat.materialIDList[id]==mtlID do newMat=msMat[id]				
						--select and detach faces
						n.selectByMaterial mtlID clearCurrentSelection:true
						selFaces=(polyOp.getfaceSelection n)
						polyop.detachFaces n selFaces delete:true asNode:true name:newName
						-- assign the material to the new node
						execute ("$"+newName+".material=newMat")
						print ("\t\t" + newName)
					)
				if (polyop.getNumFaces n==0) do delete n
				freeSceneBitmaps()
			)
		)
		progressEnd() 
		setCommandPanelTaskMode mode:oldMode
		print ("Processing of the scene took " + ((timeStamp()-st)/1000.) as string )
	)
)
