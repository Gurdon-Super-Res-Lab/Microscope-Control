% test the NCC dll with shifting parameter

%% load the DLL

fprintf(1, 'Loading Libray...');
baseDir = 'C:\Users\George Sirinakis\Documents\Microscope Control\Microscope Modules\Wide Field Drift Correction\WFDC DLL and Testing\Visual Studio NCC Max Shift DLL\x64\Release';
[notfound, warnings] = loadlibrary([baseDir, filesep, 'VSmaxShiftNCC.dll'], [baseDir, filesep, 'testHeader.h']);
fprintf(1, 'Done\n');

%% see what was loaded
libfunctionsview VSmaxShiftNCC

%% Load two images for testing the NCC

testImage01 = imread('C:\Users\George Sirinakis\Documents\Microscope Control\Microscope Modules\Wide Field Drift Correction\WFDC DLL and Testing\Egg Chamber Test Data\Stack02\Color02\Color02_00007.tif');
testImage02 = imread('C:\Users\George Sirinakis\Documents\Microscope Control\Microscope Modules\Wide Field Drift Correction\WFDC DLL and Testing\Egg Chamber Test Data\Stack02\Color02\Color02_00001.tif');

% make a rectangular image for testing
% testImage01 = testImage01(51:200, 51:250);
% testImage02 = testImage02(51:200, 51:250);

rows = size(testImage01, 2);
cols = size(testImage01, 1);

%% Setup the needed parameters for testing the NCC

imageInput01 = double(reshape(testImage01, rows*cols, 1));
imageInput02 = double(reshape(testImage02, rows*cols, 1));

halfShift = 20;

if halfShift
    
    % check the size for rows
    if mod(size(testImage01, 1) + size(testImage02, 1) - 1, 2)
        rowSize = halfShift + halfShift + 1;
    else
        rowSize = 2*halfShift;
    end
    
    % check the size for columns
    if mod(size(testImage01, 2) + size(testImage02, 2) - 1, 2)
        colSize = halfShift + halfShift + 1;
    else
        colSize = 2*halfShift;
    end
    
    theResult = double(zeros(rowSize*colSize + 500, 1));
else
    theResult = double(zeros((rows + rows - 1)*(cols + cols - 1) + 500, 1));
end

subplot(1, 2, 1)
imagesc(testImage01); axis image

subplot(1, 2, 2)
imagesc(testImage02); axis image

%% 2D cross correlation with shift parameter
fprintf(1, 'Runing NCC...');
tic
[~, ~, fullResult] = calllib('VSmaxShiftNCC', 'TwoDnCC', imageInput01, int32(rows), int32(cols), imageInput02, int32(rows), int32(cols), theResult, int32(halfShift));
toc
fprintf(1, 'DONE\n');

%% Show the results

if halfShift
        
    sizedResult = reshape(fullResult(1:rowSize*colSize), rowSize, colSize);
    imagesc(sizedResult); axis image
    
else
    
    fullResult = fullResult(1:(rows + rows - 1)*(cols + cols - 1));
    imagesc(reshape(fullResult, (rows + rows - 1), (cols + cols - 1))); axis image
    
end

%% unload the library

unloadlibrary('VSmaxShiftNCC')