Installation instructions:

1) Download the "VRayKerneler.nk" file.
2) Copy the file into "%USERPROFILE%\.nuke\ToolSets"
3) Launch Nuke, you will find the tool named "VRayKerneler" under the Wrench Icon.

Scope of the tool:

It's meant as an aid to image analysis, both numerical and visual.
In the simplest form, it will detect an image min, max and average RGB and V values.
The modes other than "pass-through" will operate on the input image(s) and derive statistically relevant data from it.
Eleven modes of operation are currently provided, some of dubious utility, and the list will grow in time as the needs will demand.


Usage instructions:

The tool accepts two inputs: the first expects the image to be analysed, the second a reference image (for the modes which will need it. more on this later.).

Plug the image to be analysed into the input labelled "Source", choose the mode of operation from the dropdown (f.e. Absolute Noise Threshold), and press the "Analyse" button.
Viewing the result will show what the process turned the pixel values into, along with the text showing the measurements.
Stamp text placement will fix itself after a first analysis.


List of modes and brief maths:

*) 	"Pass-Through": Simply reads min, max and avg RGBV. Px = Px
*) 	"Noise Threshold (Abs)": Uses a 9Px square kernel to return the modulo of the difference between the pixel and the Kernel average. Px = abs(Px - KernelAvg). 
*) 	"Average": Returns the average value of the surrounding 9Px square Kernel. Px = KernelAvg.
*)	"Root Mean Square": Returns the square root of the arithmetic mean of the squares of the 9Px kernel values. Px= Sqrt(KernelSquaresSum/9)
	(Cfr: https://en.wikipedia.org/wiki/Root_mean_square)
*) 	"Variance": Expressed as "mean of square minus square of mean", in this mode the square of what the "average" mode produced is subtracted to the RMS produced by the "RootMeanSquare" mode. Px = RMS-(Average*Average)
	(Cfr: https://en.wikipedia.org/wiki/Variance)
*)	"SnR": Calculates Signal-To-Noise ratio as Standard Deviation over Mean, or for our modes, as the square root of Variance over the Average. Px = sqrt(Variance)/Average.
	WARNING: *BEFORE* analysing the image with this mode, ensure you checked "NaN Protection".
	ADDENDUM: By the "Rose Criterion" a values above 5.0 are considered necessary for human vision to be able to inequivocally distinguish a feature from noise.
	(Cfr: https://en.wikipedia.org/wiki/Signal-to-noise_ratio#Alternative_definition ; http://www.statsdirect.com/help/basic_descriptive_statistics/standard_deviation.htm )
*) 	"Normalised Noise Threshold": In essence, it divides the Absolute Noise Threshold by the original Pixel Values.
	WARNING: *BEFORE* analysing the image with this mode, ensure you checked "NaN Protection".
*)	"Absolute Error Ratio" (with Reference Input.): Simple modulo of Reference-Source. Px = abs (PxRef-PxSource)
*)	"Normalised Error Ratio" (with Reference Input.) : Normalised version of the above. Px = abs (PxRef-PxSource)/PxRef
*) 	"Mean Square Error" (with Reference Input.) : Defined as the square of the difference between Reference and Source. Px = (PxRef-PxSource)^2
*)	"Normalised Mean Square Error" (with Reference Input.)" The normalised version of the previous mode. Px = (PxRef-PxSource)^2/PxRef
*)	"Noise Threshold (Rel)": Divides the results of the Rel. NT calculations by the image Max in R, G and B. Px = abs(Px - KernelAvg)/MaxValue