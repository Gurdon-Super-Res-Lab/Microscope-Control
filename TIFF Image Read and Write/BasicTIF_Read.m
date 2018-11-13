% Test for reading a TIF image manually

%% Clear everything
clear all; clc

%% open an ID for reading the file
fid = fopen('C:\Users\George Sirinakis\Documents\Microscope Control\Microscope Modules\Wide Field Drift Correction\WFDC DLL and Testing\Drift Correction Test Stacks 20171123\StepSize 100 nm Stack 02 - IJ Save\Image001.tif', 'r', 'n', 'US-ASCII');

%% BYTES 0-1: get the bit order for the file

readReturn = fseek(fid, 0, -1);
byteOrder = char(fread(fid, 2, 'char'));

% confirm that the byeOrder makes sense
if and(byteOrder(1) == byteOrder(2), byteOrder(1) == 'I')
    byteOrder = 'l';
elseif and(byteOrder(1) == byteOrder(2), byteOrder(1) == 'M')
    byteOrder = 'b';
else
    fprintf(1, 'Error: byte order unknown.\n');
end

%% BYTES 2-3: get confirmation this is a TIFF image
readReturn = fseek(fid, 2, -1);
tifCon = fread(fid, 1, 'uint16', byteOrder);

if tifCon ~= 42
    fprintf(1, 'This is not a TIF image\n')
else
    clear tifCon
end

%% BYTES 4-7: get offset to first IFD
readReturn = fseek(fid, 4, -1);
IFDoffset = fread(fid, 1, 'uint32', byteOrder);

%% Number of IFD Entries
readReturn = fseek(fid, IFDoffset, -1);
numberOfIFD = fread(fid, 1, 'uint16', byteOrder);

theTags = zeros(numberOfIFD, 3);

%% Read the first IFD
for i = 1:numberOfIFD
    
    if fseek(fid, IFDoffset + 2 + (i - 1)*12, -1)
        
    else
        % fprintf(1, 'Reading from: %d\n', ftell(fid));
        fieldTag = fread(fid, 1, 'uint16', byteOrder);
        theTags(i, 1) = fieldTag;
        
        fieldType = fread(fid, 1, 'uint16', byteOrder);
        theTags(i, 2) = fieldType;
        
        if fieldType == 1
            fieldType = 'uint8';
        elseif fieldType == 2
            fieldType = 'char';
        elseif fieldType == 3
            fieldType = 'uint16';
        elseif fieldType == 4
            fieldType = 'uint32';
        elseif fieldType == 5
            fieldType = 'uint64';
        else
            fprintf(1, 'Data type not supported\n')
        end
        
        fieldCount = fread(fid, 1, 'uint32', byteOrder);
        theTags(i, 3) = fieldCount;
        
        if fieldCount > 1
            fieldOffsetValue = fread(fid, 1, 'uint32', byteOrder);
            readReturn = fseek(fid, fieldOffsetValue, -1);
            fieldOffsetValue = fread(fid, fieldCount, fieldType, byteOrder);
            if strcmp(fieldType, 'char')
                fprintf(1, '%s\n', char(fieldOffsetValue))
            end
        else
            if strcmp(fieldType, 'uint64')
                fieldOffsetValue = fread(fid, 1, 'uint32', byteOrder);
                fseek(fid, fieldOffsetValue, -1);
                resFrac = fread(fid, 2, 'uint32', byteOrder);
                fprintf(1, 'Resolution: %f\n', resFrac(1)/resFrac(2));
            else
                fieldOffsetValue = fread(fid, fieldCount, fieldType, byteOrder);
            end
        end
    end
end

%% close the file
if not(fclose(fid))
    fprintf(1, 'File Closed\n');
end

clear fid readReturn tifCon
fprintf(1, '%s\n', char(fieldOffsetValue))