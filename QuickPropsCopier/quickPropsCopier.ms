(
	source=$selection[1]
	target=$selection[2]
	
	for p in (getPropnames source) do
	(
		setProperty target p (getProperty source p)
	)
	
)