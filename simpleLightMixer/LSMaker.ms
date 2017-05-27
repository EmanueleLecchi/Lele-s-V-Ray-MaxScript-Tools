(
	local rem=maxOps.GetCurRenderElementMgr() 
	
	fn LSMaker =
	(
		theLights=#()
		theLights= for l in lights where (classof l == vrayLight or classof l == vrayIes) collect l			
		print theLights
		for l in theLights do
		(
			theRE=vraylightselect mode:4 elementName:("VRLS_"+l.name) lights:#(l)
			rem.AddRenderElement theRE
		)
	)
	
	LSMaker()
	
)
