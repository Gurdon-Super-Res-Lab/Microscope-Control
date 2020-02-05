// Copy File DLL.cpp : Defines the exported functions for the DLL application.
//

#include "stdafx.h"
#include "Copy File DLL.h"

using namespace std;

////////////////////////////////////////////////////////////////////////////////
// LabVIEW can pass the pointer for LabVIEW created variable into             //
// these function which will return the pointers to be used later             //
////////////////////////////////////////////////////////////////////////////////

COPYFILEDLL_API unsigned _int16* getPointerU16(unsigned _int16* myPointer)
{
    return myPointer;
}

COPYFILEDLL_API int* getPointerINT(int* myPointer)
{
	return myPointer;
}

////////////////////////////////////////////////////////////////////////////////
// Callback function for "CopyFileEx" used in "copyFile" function below       //
////////////////////////////////////////////////////////////////////////////////

DWORD CALLBACK progressRoutine(
	LARGE_INTEGER TotalFileSize,
	LARGE_INTEGER TotalBytesTransferred,
	LARGE_INTEGER StreamSize,
	LARGE_INTEGER StreamBytesTransferred,
	DWORD dwStreamNumber,
	DWORD dwCallbackReason,
	HANDLE hSourceFile,
	HANDLE hDestinationFile,
	LPVOID lpData
)
{

	// UPDATE THE LEFT 8 BITS FOR COPY PROGRESS
	// 65280 is 1111111100000000 in bits and 255 is 0000000011111111 in bits so we "AND" these two numbers with the respective
	// parts of the 16 bit unsigned int that we're using to track the progress and user cancel. The "lpData" is a void
	// pointer, meaning it is a pointer but with no type defined so we use "reinterpret_cast<unsigned _int16*>" to set
	// the pointer type to uint16. Adding the "*" at the front means we're using the value, not the memory address.
	// The "|" is the "OR" operator. We know the progress as a percent will not get bigger than 255 so we can safely
	// use the "lower, right" 8 bits for storing the progress. We keep the "upper, left" 8 bits "as is" to check for user
	// cancel later.
	*reinterpret_cast<unsigned _int16*>(lpData) = (65280 & *reinterpret_cast<unsigned _int16*>(lpData)) | (255 & static_cast<unsigned _int16>(100.0 * static_cast<float>(TotalBytesTransferred.QuadPart) / static_cast<float>(TotalFileSize.QuadPart)));
	
	// check the right 8 bits for user cancel, if the right bits are anything other than 0, cancel the file copy
	if (*reinterpret_cast<unsigned _int16*>(lpData) >> 8) {
		return PROGRESS_CANCEL;
	}
	else {
		return PROGRESS_CONTINUE;
	}

}

////////////////////////////////////////////////////////////////////////////////
// Wrapper function for the CopyFileExA from win32. We use this because       //
// LabVIEW cant pass function pointers (callbacks). Also note, we are         //
// using CopyFileA which takes "char" strings (8 bit, LPCSTR) and not         //
// CopyFileEx and / or CopyFileW which seem to both take wide strings         //
// (16 bit, LPCWSTR) and create more problems with trying to send a file      //
// path from LabVIEW                                                          //
////////////////////////////////////////////////////////////////////////////////

COPYFILEDLL_API BOOL copyFile(LPCSTR readFile, LPCSTR writeFile, unsigned _int16* updateParameter, BOOL* copyResult)
{

	BOOL cancel;
	cancel = FALSE;
	*copyResult = -1;

	// hard code the file to copy to confirm everything is working without LabVIEW
	// LPCWSTR readFile, writeFile;
	// readFile = "D:\\Microscope-Control\\Tools\\Copy File with Progress\\Test File.txt"; // the "L" prefix makes the characters into "wide" characters. Normal "char" is 8 bits while "wide" characters use 16 bits (word). Apparently this is a thing on Windows wchar_t
	// writeFile = "D:\\Microscope-Control\\Tools\\Copy File with Progress\\JunkJunk.txt";

	// call the win32 copy function using 8 bit characters (not wide strings, which is CopyFileEx or CopyFileW)
	*copyResult = CopyFileExA(readFile, writeFile, &progressRoutine, updateParameter, &cancel, COPY_FILE_FAIL_IF_EXISTS);
	
	return *copyResult;

}

// CopyFileExA has the following arguments
//	1. LPCSTR             lpExistingFileName - Name of an existing file - in LabVIEW use C String Pointer with "Constant" check box as true
//	2. LPCSTR             lpNewFileName - Name of new file, destinationin - LabVIEW use C String Pointer with "Constant" check box as true
//	3. LPPROGRESS_ROUTINE lpProgressRoutine - callback function to get the copy progress, this is a pointer to the progress function
//	4. LPVOID             lpData - whatever you want passed to the callback function
//	5. LPBOOL             pbCancel - If this is set to true during copy, the copy is canceled
//	6. DWORD              dwCopyFlags - Flag specifying how the file is to be copied (overwrite for example)