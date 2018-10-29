(
	--find nodes which have a multiSub material
	msNodes=for g in geometry where (classof g.material == multisubMaterial) collect g
	print ("found " + msNodes.count as string + " nodes to process")
	--iterate through those only
	for n in msNodes do
	(
		print ("processing " + n.name)
		--turn to poly 
		try (n=convertToPoly n) 
		catch ( exit with print ("error converting" + n.name + " to Poly") )
		msMat=n.Material
		
		while (polyop.getNumFaces n>0) do
			(
				--find material ID
				mtlID=(polyop.getFaceMatID n 1)
				--generate new object name
				newName=(n.name+"_mtlID_"+ mtlID as string)
				--find  the right m/s material
				newMat=undefined
				for id=1 to msMat.materialIDList.count where msMat.materialIDList[id]==mtlID do newMat=msMat[id]				
				print newMat
				--select and detach faces
				n.selectByMaterial mtlID clearCurrentSelection:true
				selFaces=(polyOp.getfaceSelection n)
				polyop.detachFaces n selFaces delete:true asNode:true name:newName
				
				-- assign the material to the new node
				execute ("$"+newName+".material=newMat")
			)
		if (polyop.getNumFaces n==0) do delete n
	)
)
