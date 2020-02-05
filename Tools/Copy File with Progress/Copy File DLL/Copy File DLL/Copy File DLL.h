// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the COPYFILEDLL_EXPORTS
// symbol defined on the command line. This symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// COPYFILEDLL_API functions as being imported from a DLL, whereas this DLL sees symbols
// defined with this macro as being exported.

#ifdef COPYFILEDLL_EXPORTS
#define COPYFILEDLL_API __declspec(dllexport)
#else
#define COPYFILEDLL_API __declspec(dllimport)
#endif

// needed "decorate" the function names in C style to work with LabVIEW
#ifdef __cplusplus
extern "C"
{
#endif

	COPYFILEDLL_API unsigned _int16* getPointerU16(unsigned _int16* myPointer);
	COPYFILEDLL_API int* getPointerINT(int* myPointer);
	COPYFILEDLL_API BOOL copyFile(LPCSTR ptrReadFile, LPCSTR ptrWriteFile, unsigned _int16* updateParameter, BOOL* copyResult);

#ifdef __cplusplus
}
#endif