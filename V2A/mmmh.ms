 
fn isVrayIPRImageComplete= (
	while vrayIsRenderingIPR() do
	(
		if vrayIPRImageComplete do print "IPR Image completed "
	)
)

isVrayIPRImageComplete()
