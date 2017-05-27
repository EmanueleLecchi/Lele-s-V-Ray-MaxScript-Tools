(
	fn virtualiseBitmap theBitmap =
	(
		theRawPixels=#()
		bH=theBitmap.height
		bW=theBitmap.width
		counter=0
		for y=1 to bH do
		(
			windows.processpostedmessages()
-- 			grab a line of pixels
			theRawPixelsLine = (getpixels theBitmap [0,y-1] bW linear:true) 
			theRawPixelsLineArray=#()
			for x=1 to theRawPixelsLine.count do 
			(	
				--arrray needed to work arround a maxscript bug with the .V of hdr colors
				thePixA=#()
				--grab a pixel from the line as point4 set of floats
				thePix=theRawPixelsLine[x] as point4
				--insert it in the temp array, find the max, storre it as V and LogV
				for i=1 to 3 do thePixA[i] = thePix[i]
				theV= ((amax thePixA))
				append theRawPixelsLineArray #([thePix[1],thePix[2],thePix[3],thePix[4]], theV)		--X,Y, Color as point4, Value (max(col)) as float, original Arrray position
				
			)
			append theRawPixels theRawPixelsLineArray
			if mod y (bH as float/10.0) ==0 do 
			( 
				counter+=10
				print ("Read " + counter as string + @"% out of " + (bH) as string + " lines")
			)

		)
		theRawPixels
	)
	
	fn addVBitmaps vbm1 vbm2 =
	(
		outVBitmap=deepCopy vbm1 
		for y=1 to vbm1.count do
		(
			for x=1 to vbm1[y].count do
			(
				outVBitmap[y][x][1]=vbm1[y][x][1]+vbm2[y][x][1]		--Color
				outVBitmap[y][x][2]=vbm1[y][x][2]+vbm2[y][x][2]		--Value
			)
		)
		outVBitmap
	)
	
	fn genBitmap vbm1 =
	(
		outBitmap = bitmap vbm1[1].count vbm1.count color:black hdr:true
		for y=1 to vbm1.count do
		(
			pixelsLine=#()
			for x=1 to vbm1[y].count do
			(
				append pixelsLine (vbm1[y][x][1] as color)
-- 				setPixels outBitmap [(x-1), (y-1)] #(vbm1[y][x][1] as color)
			)
			setPixels outBitmap [0, (y-1)] pixelsLine
		)
		display outBitmap
	)
	
	ts1=timestamp()
	imagePath1=@"D:\_RnD\ToneMapping\Renders\ForVlado\kitchen_latlong.exr"
	theBitmap1=openBitMap imagePath1 hdr:true
	theVirtualBmp1 = virtualiseBitmap theBitmap1
	print ("Image Reading took " + ((timestamp()-ts1)/1000.0) as string + "s.")
	
	
	ts2=timestamp()
	imagePath2=@"D:\_RnD\ToneMapping\Renders\ForVlado\stpeters_latlong.exr"
	theBitmap2=openBitMap imagePath2 hdr:true
	theVirtualBmp2 = virtualiseBitmap theBitmap2
	print ("Image Reading took " + ((timestamp()-ts2)/1000.0) as string + "s.")
	
	ts3=timestamp()
	theVirtualBitmap3 = addVBitmaps theVirtualBmp1 theVirtualBmp2
	print ("Image Maths took " + ((timestamp()-ts3)/1000.0) as string + "s.")
		
	ts4=timestamp()
	genBitmap theVirtualBitmap3
	print ("Bitmap Generation took " + ((timestamp()-ts4)/1000.0) as string + "s.")
	
	
	copyBitmap 

)


(
	ts1=timestamp()
	imagePath1=@"D:\_RnD\ToneMapping\Renders\ForVlado\kitchen_latlong.exr"
	imagePath2=@"D:\_RnD\ToneMapping\Renders\ForVlado\stpeters_latlong.exr"
	
	theBitmap1=openBitMap imagePath1 hdr:true
	theBitmap2=openBitMap imagePath2 hdr:true
	fn addPixels c1 p1 c2 p2 =
	(
		res = c1 + c2
		res
	)
	
	pasteBitmap theBitmap1 theBitmap2 [0,0] [0,0] type:#function function:addPixels
	
	display theBitmap2
	print ("pasteBitmap took " + ((timestamp()-ts1)/1000.0) as string + "s.")
	
)