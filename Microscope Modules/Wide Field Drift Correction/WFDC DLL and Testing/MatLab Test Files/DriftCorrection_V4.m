% generate a Zeta parameter for each image in a directory

%% clear everything
clear all; clc

%% set the directory to read from and get all the TIF images
rDir = 'C:\Users\User\Desktop\Drift Correction Test Stacks 20171123\StepSize 100 nm Stack 02';
filer = dir([rDir, filesep, '*.tif']);

%% make sure there are an odd number of images and pick the center

if mod(length(filer), 2)
    centerIndex = ((length(filer) - 1)/2) + 1;
    fprintf(1, 'Center Image: %s\n', filer(centerIndex).name);
else
   error('Odd number of steps required') 
end

%% set an ROI, or not

testImage = imread([rDir, filesep, filer(centerIndex).name]);
imSize = size(testImage);

if 1
    
    h = figure;
    imagesc(testImage); axis image; colormap gray
    
    set(gca, 'xtick', [], 'ytick', [])
    set(gcf, 'Position', [650, 600, 400, 400*(imSize(1)/imSize(2))])
    set(gca, 'Position', [0, 0, 1, 1])
    
    roiData = getrect(h);
    close(h)
    
    roiData = round(roiData);
    
    rowCrop = roiData(2):roiData(2) + roiData(4) - 1;
    colCrop = roiData(1):roiData(1) + roiData(3) - 1;
    
%     imagesc(testImage(rowCrop, colCrop)); axis image; colormap gray
    
else
    rowCrop = 1:imSize(1);
    colCrop = 1:imSize(2);
end

clear roiData h testImage

%% read in the first, last and middle images from the stack set these as the reference images
imRef01 = imread([rDir, filesep, filer(1).name]);
imRef02 = imread([rDir, filesep, filer(centerIndex).name]);
imRef03 = imread([rDir, filesep, filer(end).name]);

% adjust for ROI
imRef01 = imRef01(rowCrop, colCrop);
imRef02 = imRef02(rowCrop, colCrop);
imRef03 = imRef03(rowCrop, colCrop);

%% do the rest

stepSize = 100;
zetaInfo = zeros(length(filer), 2);

for i = 1:length(filer)
    
    fprintf(1, 'Running on: %s\n', filer(i).name);
    
    currImage = imread([rDir, filesep, filer(i).name]);
    currImage = currImage(rowCrop, colCrop);
    
    % get the correlations with ref images
    cPn = normxcorr2(imRef03, currImage);
    c0n = normxcorr2(imRef02, currImage);
    cMn = normxcorr2(imRef01, currImage);
    
    % get the peak intensity from each correlation
    PVcPn = max(cPn(:));
    PVc0n = max(c0n(:));
    PVcMn = max(cMn(:));
    
    % compute zeta
    zeta = (PVcPn - PVcMn)/PVc0n;
    
    % save the results
    zetaInfo(i, :) = [(i - 1)*stepSize, zeta];
    
end
fprintf(1, 'Done\n');
clear zeta cPn c0n cMn PVcPn PVc0n PVcMn currImage i

%% plot the zeta info

plot(zetaInfo(:, 1), zetaInfo(:, 2), 'o')
axis([-100, zetaInfo(end, 1)*1.1, zetaInfo(1, 2)*1.1, zetaInfo(end, 2)*1.1])