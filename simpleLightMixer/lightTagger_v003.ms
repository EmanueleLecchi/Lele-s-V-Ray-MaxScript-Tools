-- LightTagger for LS REs
(
	global LTRoll
	try (destroyDialog LTRoll) catch()
	local theGroups=#()
	local parsedVRLSGroups=#()
	local rem=maxOps.GetCurRenderElementMgr() 
	local orphanedLights = #()
	
	fn setUserProps theLight theGroup =
	(
		if (getUserProp theLight "VRLSGRoup") == undefined then theGroups=#() else theGroups=execute (getUserProp theLight "VRLSGRoup")
		appendifunique theGroups theGroup
		setUserProp theLight "VRLSGRoup" theGroups 
	)

	fn selectedVRLight a b= 
	(
		parsedVRLSGroups=#()
		mySelection=(selection as array)
		for s in mySelection where (classof s == VRaylight or classof s == VRayIES or classof s == VRaySun or classof s == VRayAmbientLight) do
		(
			if ((getUserProp s "VRLSGRoup") != undefined) and ((getUserProp s "VRLSGRoup") != #()) do 
			(
				for p in (execute (getUserProp s "VRLSGRoup")) do
				(
					appendIfUnique parsedVRLSGroups p
				)
			)
		)
		sort parsedVRLSGroups
		LTRoll.lbx1.items=parsedVRLSGroups
	)

	fn LSMaker doSelectedOnly=
	(
		theLights=#()
		parsedVRLSGroups=#()
		orphanedLights=#()
		
		if doSelectedOnly then 
		(
			mySelection=(selection as array)
			theLights=for s in mySelection where (classof s == VRaylight or classof s == VRayIES or classof s == VRaySun or classof s == VRayAmbientLight) collect s
		)
		else
		(
			theLights= for l in lights where (classof l == VRaylight or classof l == VRayIES or classof l == VRaySun or classof l == VRayAmbientLight) collect l	
		)				
-- 		print theLights
		

		for l in theLights do
		(
			--collect all groups in the selection
			if (getUserProp l "VRLSGRoup") != undefined and (getUserProp l "VRLSGRoup") != #() then 
			(
				for p in (execute (getUserProp l "VRLSGRoup")) do
				(
					appendIfUnique parsedVRLSGroups p
				)
			)
			else
			(
				appendIfUnique orphanedLights l
			)
		)
-- 		print orphanedLights
		for g in parsedVRLSGroups do
		(
			theRE=vraylightselect mode:4 elementName:("VRLS_"+g) 
			theRELights=#()
			for l in theLights do
			(
				if (getUserProp l "VRLSGRoup") != undefined and (getUserProp l "VRLSGRoup") != #() do 
				(
					theProps=(execute (getUserProp l "VRLSGRoup"))
					if theProps.count != 0 do
					(	
						itemNum=(findItem theProps g)
						if itemNum != 0 do appendIfUnique theRELights l
					)
				)
			)
			theRE.lights= theRELights
			for re=(rem.numrenderelements()-1) to 0 by -1 do
			(
				oldRe=(rem.getrenderelement re)
				if matchpattern oldRe.elementName pattern:theRE.elementname do rem.removeRenderElement oldRe
			)
			rem.AddRenderElement theRE
		)
		if orphanedLights.count != 0 do
		(
			theRE=vraylightselect mode:4 elementName:"VRLS_OrphanedLights" lights:orphanedLights
			for re=(rem.numrenderelements()-1) to 0 by -1 do
			(
				oldRe=(rem.getrenderelement re)
				if matchpattern oldRe.elementName pattern:theRE.elementname do rem.removeRenderElement oldRe
			)
			rem.AddRenderElement theRE
		)
		
		
	)	
		
	rollout LTRoll "Light Tagger v. 0.03" width:272 height:368
	(
		label 'lbl1' "Group Name:" pos:[16,32] width:72 height:16 align:#left
		label 'lbl2' "The selected lights are member of:\n(double-click to remove from...)" pos:[16,136] width:176 height:32 align:#left
		GroupBox 'grp1' "Group Tagging" pos:[8,8] width:256 height:96 align:#left
		GroupBox 'grp2' "Group Inspection and Editing" pos:[8,112] width:256 height:152 align:#left
		groupBox 'grp3' "Render Elements Creation" pos:[8,272] width:248 height:88 align:#left
		edittext 'edt1' "" pos:[88,32] width:168 height:16 align:#left
		button 'btn1' "Tag!" pos:[16,56] width:240 height:40 align:#left
		listbox 'lbx1' "" pos:[8,176] width:248 height:6 align:#left
		button 'btn2' "Generate LightSelect REs" pos:[16,296] width:232 height:56 toolTip:"Press Ctrl for selected only" align:#left
		
		on LTRoll open do
		(
-- 			VRLSTaggerCB = when select lights changes id:#VRLSTaggerCB do selectedVRLight()
-- 			VRLSTaggerCB2 = when select lights changes id:#VRLSTaggerCB do selectedVRLight()
			callbackItem = NodeEventCallback mouseUp:true delay:10 all:selectedVRLight

			select selection
		)
		
		on LTRoll close do
		(
			callbackItem = undefined
-- 			deleteAllChangeHandlers id:#VRLSTaggerCB
			gc light:true
		)
		
		on btn1 pressed do
		(
			for s in selection as array where (classof s == VRaylight or classof s == VRayIES or classof s == VRaySun or classof s == VRayAmbientLight) do
			(
				if edt1.text != "" do 
				(
					setUserProps s edt1.text 
				)
			)
			select selection
		)
		on edt1 entered val do
		(
			for s in selection as array where (classof s == VRaylight or classof s == VRayIES or classof s == VRaySun or classof s == VRayAmbientLight) do
			(
				if edt1.text != "" do 
				(
					setUserProps s edt1.text 
				)
			)
			select selection
		)
		on lbx1 doubleClicked itm do
		(
			if keyboard.controlPressed then --delete the group
			(
				theProps=#()
				mySelection=(selection as array)
				for s in mySelection where (classof s == VRaylight or classof s == VRayIES or classof s == VRaySun or classof s == VRayAmbientLight) do
				(
					if (getUserProp s "VRLSGRoup") != undefined do 
					(
						theProps=(execute (getUserProp s "VRLSGRoup"))
						for p=1 to theProps.count where (theProps[p]==lbx1.items[itm]) do
						(
							deleteItem theProps p
						)
						setUserProp s "VRLSGRoup" theProps
					)
				)
				select selection
			)
			else	--select all lights in that group
			(
				theGroup=lbx1.items[itm]
-- 				print theGroup
				clearselection()
				for l in lights where (classof l == VRaylight or classof l == VRayIES or classof l == VRaySun or classof l == VRayAmbientLight) do
				(
					if (getUserProp l "VRLSGRoup") != undefined do 
					(
						theProps=(execute (getUserProp l "VRLSGRoup"))
						for p=1 to theProps.count where (theProps[p]==theGroup) do
						(
							selectmore l
						)
					)						
				)
-- 				select selection
			)
		)
		
		on btn2 pressed do
		(
			if keyboard.controlPressed then LSMaker true else LSMaker false
		)
	)
	
	
	
	createdialog LTRoll
)


-- getUserProp $ "VRLSGRoup"

-- for l in lights do setUserPropBuffer l "