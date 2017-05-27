fn getOwner theMap =
(
	local deps = for m in (refs.dependents theMap) collect m
	if deps.count == 0 then undefined else deps[1]
)
fn getOwnerName theClass =
(
	mapsArray= getclassinstances theClass
	for m in mapsArray do
	(
		local owner = getOwner m
		if owner == 0 then undefined else meditmaterials[1] = owner
	)
)

getOwnerName vrayDirt 