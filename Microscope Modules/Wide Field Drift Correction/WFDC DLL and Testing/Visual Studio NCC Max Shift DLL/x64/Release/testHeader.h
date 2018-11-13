#ifndef __MAIN_H__
#define __MAIN_H__

#include <windows.h>
#include <math.h>

/*  To use this exported function of dll, include this header
*  in your project.
*/

#ifdef BUILD_DLL
#define DLL_EXPORT __declspec(dllexport)
#else
#define DLL_EXPORT __declspec(dllimport)
#endif

#ifdef __cplusplus
extern "C"
{
#endif

	void DLL_EXPORT TwoDnCC(double* im01, int im01rowSize, int im01colSize, double* im02, int im02rowSize, int im02colSize, double* theResult, int halfShiftAmount);
	double DLL_EXPORT normCrossCorr(double* im01, double* im02, int im01rowStartIndex, int im02rowStartIndex, int rowLength, int im01colStartIndex, int im02colStartIndex, int colLength, int im01numCols, int im02numCols);

#ifdef __cplusplus
}
#endif

#endif // __MAIN_H__

