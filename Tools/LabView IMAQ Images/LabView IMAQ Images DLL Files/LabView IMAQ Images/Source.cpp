#include "Header.h"

// Find the (row, column) indices of non-zero array elements and the total number of non-zero elements in a LabView IMAQ image
unsigned __int16 DLL_EXPORT nonZeroIndices(unsigned __int16 *imPointer, int LVlineWidth, int LVrows, int LVcols, int *notZeroRows, int *notZeroCols)
{
	int currPosition = 0, indexPosition = 0;

	for (int row = 0; row < LVrows; row++)
	{
		for (int col = 0; col < LVcols; col++)
		{
			if (imPointer[LVlineWidth*row + col])
			{
				notZeroRows[indexPosition] = row;
				notZeroCols[indexPosition] = col;

				indexPosition = indexPosition + 1;
			}

			currPosition = currPosition + 1;
		}
	}

	return indexPosition;
}

// Find the total number of non-zero array elements in a LabView IMAQ image
unsigned __int16 DLL_EXPORT nonZeroTotal(unsigned __int16 *imPointer, int LVlineWidth, int LVrows, int LVcols)
{
	unsigned __int16 nonZeroTotal = 0;

	for (int row = 0; row < LVrows; row++)
	{
		for (int col = 0; col < LVcols; col++)
		{
			if (imPointer[LVlineWidth*row + col])
			{
				nonZeroTotal++;
			}
		}
	}

	return nonZeroTotal;
}

// some junk for Windows
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