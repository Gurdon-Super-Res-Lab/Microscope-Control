% Basic TIF writer - testing with ImageJ

%% clear everything
clear all; clc

%% read in a DBL to convert to TIF
% [theImage, ~, ~] = readDBL_uint16('C:\Users\Edward\Desktop\TempDM_TestData\ModeScan_wFlat_NoTT\DMpixel_002_Value_p800d000.dbl');
theImage = meshgrid(1:256, 1:256);

%% create a new file for writing
byteOrder = 'l';
fid = fopen('C:\Users\George Sirinakis\Desktop\Test Image Matlab.tif', 'w+', byteOrder, 'US-ASCII');

%% Write the basic TIF header
fwrite(fid, 'II', 'char', 0, byteOrder); % flag the file as little-endian
fwrite(fid, 42, 'uint16', 0, byteOrder); % add the number designating this as tif
fwrite(fid, 8, 'uint32', 0, byteOrder); % offset to the first IFD

%% write the TIFF TAGs

% write the number of IFD entries
fwrite(fid, 15, 'uint16', 0, byteOrder);

% 1) 254 - New Subfile Type - ImageJ sets this to zero for single images and stacks
fprintf(1, 'Tag 254 Offset: %d\n', ftell(fid))
fwrite(fid, 254, 'uint16', 0, byteOrder);   % tag
fwrite(fid, 4, 'uint16', 0, byteOrder);     % data type: 1 = uint8, 2 = char, 3 = uint16, 4 = uint32, 5 = uint64
fwrite(fid, 1, 'uint32', 0, byteOrder);     % count
fwrite(fid, 0, 'uint32', 0, byteOrder);     % value or offset to value

% 2) 256 - ImageWidth (in pixels)
fprintf(1, 'Tag 256 Offset: %d\n', ftell(fid))
fwrite(fid, 256, 'uint16', 0, byteOrder);   % tag
fwrite(fid, 4, 'uint16', 0, byteOrder);     % data type: 1 = uint8, 2 = char, 3 = uint16, 4 = uint32, 5 = uint64
fwrite(fid, 1, 'uint32', 0, byteOrder);     % count
fwrite(fid, size(theImage, 1), 'uint32', 0, byteOrder);  % VALUE

% 3) 257 - ImageHeight (in pixels)
fprintf(1, 'Tag 257 Offset: %d\n', ftell(fid))
fwrite(fid, 257, 'uint16', 0, byteOrder);   % tag
fwrite(fid, 4, 'uint16', 0, byteOrder);     % data type: 1 = uint8, 2 = char, 3 = uint16, 4 = uint32, 5 = uint64
fwrite(fid, 1, 'uint32', 0, byteOrder);     % count
fwrite(fid, size(theImage, 2), 'uint32', 0, byteOrder);  % VALUE

% 4) 258 - BitsPerSample (e.g. 16 bit)
fprintf(1, 'Tag 258 Offset: %d\n', ftell(fid))
fwrite(fid, 258, 'uint16', 0, byteOrder);   % tag
fwrite(fid, 3, 'uint16', 0, byteOrder);     % data type: 1 = uint8, 2 = char, 3 = uint16, 4 = uint32, 5 = uint64
fwrite(fid, 1, 'uint32', 0, byteOrder);     % count
fwrite(fid, 16, 'uint32', 0, byteOrder);    % VALUE

% 5) 262 - PhotometricInterpretation - 0 = White is zero, 1 = Black is zero
fprintf(1, 'Tag 262 Offset: %d\n', ftell(fid))
fwrite(fid, 262, 'uint16', 0, byteOrder);   % tag
fwrite(fid, 3, 'uint16', 0, byteOrder);     % data type: 1 = uint8, 2 = char, 3 = uint16, 4 = uint32, 5 = uint64
fwrite(fid, 1, 'uint32', 0, byteOrder);     % count
fwrite(fid, 1, 'uint32', 0, byteOrder);     % value or offset to value

% 6) 270 - Image Description
fprintf(1, 'Tag 270 Offset: %d\n', ftell(fid))
fwrite(fid, 270, 'uint16', 0, byteOrder);   % tag
fwrite(fid, 2, 'uint16', 0, byteOrder);     % data type: 1 = uint8, 2 = char, 3 = uint16, 4 = uint32, 5 = uint64
descriptionMark = ftell(fid); % mark the position to update later
fwrite(fid, 0, 'uint32', 0, byteOrder);     % count
fwrite(fid, 0, 'uint32', 0, byteOrder);     % value or offset to value

% 7) 273 - Strip Offset(s)
fprintf(1, 'Tag 273 Offset: %d\n', ftell(fid))
fwrite(fid, 273, 'uint16', 0, byteOrder);   % tag
fwrite(fid, 4, 'uint16', 0, byteOrder);     % data type: 1 = uint8, 2 = char, 3 = uint16, 4 = uint32, 5 = uint64
stripMark = ftell(fid); % mark the position to update later
fwrite(fid, 0, 'uint32', 0, byteOrder);     % count
fwrite(fid, 0, 'uint32', 0, byteOrder);     % value or offset to value

% 8) 277 - Samples Per Pixel (3 for RGB, 1 for gray scale)
fprintf(1, 'Tag 277 Offset: %d\n', ftell(fid))
fwrite(fid, 277, 'uint16', 0, byteOrder);   % tag
fwrite(fid, 3, 'uint16', 0, byteOrder);     % data type: 1 = uint8, 2 = char, 3 = uint16, 4 = uint32, 5 = uint64
fwrite(fid, 1, 'uint32', 0, byteOrder);     % count
fwrite(fid, 1, 'uint32', 0, byteOrder);     % value or offset to value

% 9) 278 - Rows Per Strip
fprintf(1, 'Tag 278 Offset: %d\n', ftell(fid))
fwrite(fid, 278, 'uint16', 0, byteOrder);   % tag
fwrite(fid, 3, 'uint16', 0, byteOrder);     % data type: 1 = uint8, 2 = char, 3 = uint16, 4 = uint32, 5 = uint64
fwrite(fid, 1, 'uint32', 0, byteOrder);     % count
fwrite(fid, size(theImage, 1), 'uint32', 0, byteOrder);  % VALUE

% 10) 279 - StripByteCounts (the number of bytes in each strip - basically the size of one frame in bytes)
fprintf(1, 'Tag 279 Offset: %d\n', ftell(fid))
fwrite(fid, 279, 'uint16', 0, byteOrder);   % tag
fwrite(fid, 4, 'uint16', 0, byteOrder);     % data type: 1 = uint8, 2 = char, 3 = uint16, 4 = uint32, 5 = uint64
fwrite(fid, 1, 'uint32', 0, byteOrder);     % count
fwrite(fid, size(theImage, 1)*size(theImage, 2)*2, 'uint32', 0, byteOrder);  % width X height X bytes per pixel

% 11) 282 - X Resolution
fprintf(1, 'Tag 282 Offset: %d\n', ftell(fid))
fwrite(fid, 282, 'uint16', 0, byteOrder);   % tag
fwrite(fid, 5, 'uint16', 0, byteOrder);     % data type: 1 = uint8, 2 = char, 3 = uint16, 4 = uint32, 5 = uint64
fwrite(fid, 1, 'uint32', 0, byteOrder);     % count
xResMark = ftell(fid);
fwrite(fid, 0, 'uint32', 0, byteOrder);     % OFFSET to be updated

% 12) 283 - Y Resolution
fprintf(1, 'Tag 283 Offset: %d\n', ftell(fid))
fwrite(fid, 283, 'uint16', 0, byteOrder);   % tag
fwrite(fid, 5, 'uint16', 0, byteOrder);     % data type: 1 = uint8, 2 = char, 3 = uint16, 4 = uint32, 5 = uint64
fwrite(fid, 1, 'uint32', 0, byteOrder);     % count
yResMark = ftell(fid);
fwrite(fid, 0, 'uint32', 0, byteOrder);     % OFFSET to be updated

% 13) 296 - Resolution Unit
fprintf(1, 'Tag 296 Offset: %d\n', ftell(fid))
fwrite(fid, 296, 'uint16', 0, byteOrder);   % tag
fwrite(fid, 3, 'uint16', 0, byteOrder);     % data type: 1 = uint8, 2 = char, 3 = uint16, 4 = uint32, 5 = uint64
fwrite(fid, 1, 'uint32', 0, byteOrder);     % count
fwrite(fid, 3, 'uint32', 0, byteOrder);     % Value - 1 = No unit, 2 = Inch, 3 = Centimeter

% % 14) 50838 - Adobe tag offset to where IJ seems to write the two letters IJ
% fwrite(fid, 50838, 'uint16', 0, byteOrder);   % tag
% fwrite(fid, 4, 'uint16', 0, byteOrder);     % data type: 1 = uint8, 2 = char, 3 = uint16, 4 = uint32, 5 = uint64
% fwrite(fid, 2, 'uint32', 0, byteOrder);     % count
% adobeIJtag = ftell(fid);
% fwrite(fid, 0, 'uint32', 0, byteOrder);     % value
% 
% % 15) 50839 - Adobe tag where IJ appears to put text description
% fwrite(fid, 50839, 'uint16', 0, byteOrder);   % tag
% fwrite(fid, 1, 'uint16', 0, byteOrder);     % data type: 1 = uint8, 2 = char, 3 = uint16, 4 = uint32, 5 = uint64
% adobeTextTag = ftell(fid);
% fwrite(fid, 0, 'uint32', 0, byteOrder);     % count
% fwrite(fid, 0, 'uint32', 0, byteOrder);     % value

% offset to next IFD (0 if none)
fwrite(fid, 0, 'uint32', 0, byteOrder);

%% Update Counts and Offsets

% write a description and update the tag
imDes = sprintf('ImageJ=1.46r\nunit=um\nspacing=5.3\nimages=10\nslices=10');
fprintf(1, 'Description Length: %d\n', length(imDes));

writeOffset = ftell(fid);
fwrite(fid, imDes, 'char', 0, byteOrder);
returnOffset = ftell(fid);

fseek(fid, descriptionMark, -1);
fwrite(fid, length(imDes), 'uint32', 0, byteOrder);   % COUNT
fwrite(fid, writeOffset, 'uint32', 0, byteOrder);     % OFFSET
fseek(fid, returnOffset, -1);

% % Update Adobe Tag 50839 - write a description and update
% adTagDes = sprintf('ImageDescription: Radom shit goes here\n');
% 
% writeOffset = ftell(fid);
% fwrite(fid, uint8([73, 74, 73, 74, 105, 110, 102, 111, 0, 0, 0, 1, 0]), 'uint8', 0, byteOrder);
% fwrite(fid, uint16(adTagDes), 'uint16', 0, byteOrder);
% returnOffset = ftell(fid);
% 
% fseek(fid, adobeTextTag, -1);
% fwrite(fid, 2*length(uint16(adTagDes))+12, 'uint32', 0, byteOrder);   % COUNT
% fwrite(fid, writeOffset, 'uint32', 0, byteOrder);                  % OFFSET
% fseek(fid, returnOffset, -1);
% 
% % Update Adobe Tag 50838 - Number of header bytes and text length
% writeOffset = ftell(fid);
% fwrite(fid, 12, 'uint32', 0, byteOrder);
% fwrite(fid, 2*length(uint16(adTagDes)), 'uint32', 0, byteOrder);
% returnOffset = ftell(fid);
% 
% fseek(fid, adobeIJtag, -1);
% fwrite(fid, writeOffset, 'uint32', 0, byteOrder); % OFFSET
% fseek(fid, returnOffset, -1);

% Write the X Resolution and offset
writeOffset = ftell(fid);
fwrite(fid, [10000, 1], 'uint32', 0, byteOrder);
returnOffset = ftell(fid);

fseek(fid, xResMark, -1);
fwrite(fid, writeOffset, 'uint32', 0, byteOrder);
fseek(fid, returnOffset, -1);

% Write the Y Resolution and offset
writeOffset = ftell(fid);
fwrite(fid, [10000, 1], 'uint32', 0, byteOrder);
returnOffset = ftell(fid);

fseek(fid, yResMark, -1);
fwrite(fid, writeOffset, 'uint32', 0, byteOrder);
fseek(fid, returnOffset, -1); % dont think we need this line

% Strip Offset(s)
fseek(fid, stripMark, -1);
fwrite(fid, 1, 'uint32', 0, byteOrder); % Count
fwrite(fid, returnOffset, 'uint32', 0, byteOrder); % Offset
fseek(fid, returnOffset, -1);

%% write the image
fprintf(1, 'Image Start Position: %d\n', ftell(fid))
for i = 1:10
    fwrite(fid, theImage(:), 'uint16', 0, byteOrder);
end

%% close the file
if not(fclose(fid))
    fprintf(1, 'File Closed\n');
end