#ifndef __MAIN_H__
#define __MAIN_H__

#include <windows.h>
#include <math.h>

/*  To use this exported function of dll, include this header
*  in your project.
*/

//#ifdef BUILD_DLL
//#define DLL_EXPORT __declspec(dllexport)
//#else
//#define DLL_EXPORT __declspec(dllimport)
//#endif

#define DLL_EXPORT __declspec(dllexport)

#ifdef __cplusplus
extern "C"
{
#endif

	unsigned __int16 DLL_EXPORT nonZeroIndices(unsigned __int16 *imPointer, int LVlineWidth, int LVrows, int LVcols, int *notZeroRows, int *notZeroCols);
	unsigned __int16 DLL_EXPORT nonZeroTotal(unsigned __int16 *imPointer, int LVlineWidth, int LVrows, int LVcols);

#ifdef __cplusplus
}
#endif

#endif // __MAIN_H__

