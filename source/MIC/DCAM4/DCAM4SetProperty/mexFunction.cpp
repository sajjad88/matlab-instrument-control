#include "stdafx.h"

// [] = DCAM4SetProperty(cameraHandle, propertyID, value)
// Set the property defined by 'propertyID' to the double given in 'value'. See
// dcamprop.h for hexadecimal propertyIDs (which must be converted to decimal 
// before use here).
void mexFunction(int nlhs, mxArray* plhs[], int	nrhs, const	mxArray* prhs[])
{
	// Grab the inputs from MATLAB and check their types before proceeding.
	unsigned long* mHandle;
	HDCAM handle;
	int32 propertyID;
	double propertyValue;
	mHandle = (unsigned long*)mxGetUint64s(prhs[0]);
	handle = (HDCAM)mHandle[0];
	propertyID = (int32)mxGetScalar(prhs[1]);
	propertyValue = (double)mxGetScalar(prhs[2]);

	// Call the dcam function.
	DCAMERR error;
	error = dcamprop_setvalue(handle, propertyID, propertyValue);
	if (failed(error))
	{
		mexPrintf("Error = 0x%08lX\ndcamprop_setvalue() failed.\n", error);
	}

	return;
}