% example for imageJ_TIF class useage

%% Create an object of type imageJ_TIF

rFile = 'Example 16 Bit TIF Stack.tif';
rDir = 'C:\Users\User\Documents\MATLAB\TIF Read Write\Custom TIF Class';

myImage = imageJ_TIF([rDir, filesep, rFile]);

%% get a frame from the image

myFrame = myImage.getFrame(1);
% imagesc(myFrame); axis image; colormap gray

%% get all the frames from the image

% if you have a large image don't use this, it will take a very long time
myFullImage = myImage.getALLframes;

%% print out info from the TIF

% filePath
% totalFrames
% numZsteps
% framesPerStep
% zStepSize
% exposureTime
% pxWidth
% pxHeight
% pxWidth_um
% pxHeight_um
% bitsPerSample

fprintf(1, 'File Path: %s\n', myImage.filePath);
fprintf(1, 'Total Frames: %d\n', myImage.totalFrames);
fprintf(1, 'No. of Z Steps: %d\n', myImage.numZsteps);
fprintf(1, 'Frames per Step: %d\n', myImage.framesPerStep);
fprintf(1, 'Z Step Size: %d\n', myImage.zStepSize);
fprintf(1, 'Exposure Time: %d\n', myImage.exposureTime);
fprintf(1, 'Image Width (px): %d\n', myImage.pxWidth);
fprintf(1, 'Image Height (px): %d\n', myImage.pxHeight);
fprintf(1, 'Image Width (µm): %d\n', myImage.pxWidth_um);
fprintf(1, 'Image Height (µm): %d\n', myImage.pxHeight_um);
fprintf(1, 'Image Bit Depth): %d\n', myImage.bitsPerSample);