#include "Header.h"

// Normalized 2D CossCorrelation for two images of equal size OR Image 01 is larger than Image 02
void DLL_EXPORT TwoDnCC(double* im01, int im01rowSize, int im01colSize, double* im02, int im02rowSize, int im02colSize, double* theResult, int halfShiftAmount)
{
	// row parameters for both images
	int im01rowStartIndex = 0, im02rowStartIndex = -1, rowLength = 0;

	// column parameters for both images
	int im01colStartIndex = 0, im02colStartIndex = -1, colLength = 0;

	// set the number of row and column loops
	int rowLoopNum = im01rowSize + im02rowSize - 1, colLoopNum = im01colSize + im02colSize - 1;

	// starting row and column index for im01 (the larger image)
	im01rowStartIndex = im01rowSize - 1;
	im01colStartIndex = im01colSize - 1;

	int rowCenterPosition = 0, colCenterPosition = 0;
	int rowOoffset = 0, colOoffset = 0;

	int resultIndex = 0;

	// parameters adjusted if specifying a shift size
	if (halfShiftAmount > 0)
	{
		//////////////////// Adjust COL Parameters ////////////////////

		// find the center ROWS position of the image
		if (rowLoopNum % 2 == 0)
		{
			// even case of M + N - 1
			rowCenterPosition = rowLoopNum / 2;

		}
		else
		{
			// odd case of M + N - 1
			rowCenterPosition = (rowLoopNum / 2) + 1;
			rowOoffset = 1;
		}

		// adjust im02 start ROW index and ROW length
		if (rowCenterPosition - halfShiftAmount - rowOoffset > im02rowSize)
		{
			rowLength = im02rowSize;
			im02rowStartIndex = im02rowSize;
		}
		else
		{
			rowLength = rowCenterPosition - halfShiftAmount - rowOoffset;
			im02rowStartIndex = rowCenterPosition - halfShiftAmount - rowOoffset - 1;
		}

		// adjust the row loop limit
		rowLoopNum = rowCenterPosition + halfShiftAmount;

		//////////////////// Adjust COL Parameters ////////////////////

		// find the center COLS position of the image
		if (colLoopNum % 2 == 0)
		{
			// even case of M + N - 1
			colCenterPosition = colLoopNum / 2;

		}
		else
		{
			// odd case of M + N - 1
			colCenterPosition = (colLoopNum / 2) + 1;
			colOoffset = 1;
		}

		// adjust im02 start COL index and COL length
		if (colCenterPosition - halfShiftAmount - colOoffset > im02colSize)
		{
			colLength = im02colSize;
			im02colStartIndex = im02colSize;
		}
		else
		{
			colLength = colCenterPosition - halfShiftAmount - colOoffset;
			im02colStartIndex = colCenterPosition - halfShiftAmount - colOoffset - 1;
		}

		// adjust the COL loop limit
		colLoopNum = colCenterPosition + halfShiftAmount;

	}

	// save the initial col start index and loop number for each reset on rows loop
	int init_im02colStartIndex = im02colStartIndex, init_colLength = colLength;

	// get the total number of rows and columns used for results array
	//int iStart = rowCenterPosition - halfShiftAmount - rowOoffset, kStart = colCenterPosition - halfShiftAmount - colOoffset;
	//int totalCols = colLoopNum - kStart;

	// Loop over the image ROWS
	for (int i = rowCenterPosition - halfShiftAmount - rowOoffset; i < rowLoopNum; i++)
	{

		// Start index for ROWS
		if (i < im02rowSize)
		{
			rowLength = rowLength + 1;
			im02rowStartIndex = im02rowStartIndex + 1;

		}
		else if (i > im01rowSize - 1)
		{
			rowLength = rowLength - 1;
			im01rowStartIndex = im01rowStartIndex - 1;

		}
		else
		{
			im01rowStartIndex = im01rowStartIndex - 1;
		}

		// Loop over image COLUMNS
		for (int k = colCenterPosition - halfShiftAmount - colOoffset; k < colLoopNum; k++)
		{

			// Start index and length of COLUMNS
			if (k < im02colSize)
			{
				colLength = colLength + 1;
				im02colStartIndex = im02colStartIndex + 1;

			}
			else if (k > im01colSize - 1)
			{
				colLength = colLength - 1;
				im01colStartIndex = im01colStartIndex - 1;
			}
			else
			{
				im01colStartIndex = im01colStartIndex - 1;
			}

			// Call the cross correlation function here
			theResult[resultIndex] = normCrossCorr(im01, im02, im01rowStartIndex, im02rowStartIndex, rowLength, im01colStartIndex, im02colStartIndex, colLength, im01colSize, im02colSize);
			resultIndex = resultIndex + 1;
		}

		// reset values for the column loop
		im01colStartIndex = im01colSize - 1;
		im02colStartIndex = init_im02colStartIndex;
		colLength = init_colLength;

	}
}

// compute the 2D normalized correlation coefficient
double DLL_EXPORT normCrossCorr(double* im01, double* im02, int im01rowStartIndex, int im02rowStartIndex, int rowLength, int im01colStartIndex, int im02colStartIndex, int colLength, int im01numCols, int im02numCols)
{
	double totalNums = double(rowLength)*double(colLength), im01mean = 0, im02mean = 0;
	double numeratorSum = 0, im01subMeanSqSum = 0, im02subMeanSqSum = 0;
	double im01subMean = 0, im02subMean = 0;

	// MEAN value of IMAGE 01 and 02
	for (int r = 0; r < rowLength; r++)
	{
		for (int c = 0; c < colLength; c++)
		{
			im01mean = im01mean + im01[((im01rowStartIndex - r)*im01numCols) + (im01colStartIndex - c)];
			im02mean = im02mean + im02[((im02rowStartIndex - r)*im02numCols) + (im02colStartIndex - c)];
		}
	}
	im01mean = im01mean / totalNums;
	im02mean = im02mean / totalNums;

	// loop to compute the numerator and terms for the denominator
	for (int r = 0; r < rowLength; r++)
	{
		for (int c = 0; c < colLength; c++)
		{
			// compute the two elements we care about
			im01subMean = im01[((im01rowStartIndex - r)*im01numCols) + (im01colStartIndex - c)] - im01mean;
			im02subMean = im02[((im02rowStartIndex - r)*im02numCols) + (im02colStartIndex - c)] - im02mean;

			// do the sums
			numeratorSum = numeratorSum + im01subMean*im02subMean;
			im01subMeanSqSum = im01subMeanSqSum + (im01subMean*im01subMean);
			im02subMeanSqSum = im02subMeanSqSum + (im02subMean*im02subMean);
		}
	}

	return numeratorSum / sqrt(im01subMeanSqSum*im02subMeanSqSum);
}

// junk for Windows
extern "C" DLL_EXPORT BOOL APIENTRY DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
	switch (fdwReason)
	{
	case DLL_PROCESS_ATTACH:
		// attach to process
		// return FALSE to fail DLL load
		break;

	case DLL_PROCESS_DETACH:
		// detach from process
		break;

	case DLL_THREAD_ATTACH:
		// attach to thread
		break;

	case DLL_THREAD_DETACH:
		// detach from thread
		break;
	}
	return TRUE; // succesful
}
