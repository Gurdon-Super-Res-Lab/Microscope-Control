% read in the ref. images and compute Zeta for each

%% clear everything
clear all; clc

%% read in the ref images

refpath = ['C:\Users\STED\Documents\Drift Correction\Test Data\Drift Correction Stack Test 40X\01_40X_OldChamber_RefIm_0000nm.tif';
    'C:\Users\STED\Documents\Drift Correction\Test Data\Drift Correction Stack Test 40X\02_40X_OldChamber_RefIm_0700nm.tif';
    'C:\Users\STED\Documents\Drift Correction\Test Data\Drift Correction Stack Test 40X\03_40X_OldChamber_RefIm_1400nm.tif'];

% get the image size
imSize = size(imread(refpath(1, :)));

refImages = zeros(imSize(1), imSize(2), size(refpath, 1));

fprintf(1, 'Reading in ref images...');
for i = 1:3
   refImages(:, :, i) = double(imread(refpath(i, :)));
end
clear i
fprintf(1, 'DONE\n');

%% select an ROI

h = figure;

imagesc(refImages(:, :, 2)); axis image; colormap gray

set(gca, 'xtick', [], 'ytick', [])
set(gcf, 'Position', [650, 600, 400, 400*(imSize(1)/imSize(2))])
set(gca, 'Position', [0, 0, 1, 1])

roiData = getrect(h);
close(h)

roiData = round(roiData);
cropImages = zeros(roiData(4), roiData(3), 3);

for i = 1:size(cropImages, 3)
    cropImages(:, :, i) = refImages(roiData(2):roiData(2) + roiData(4) - 1, roiData(1):roiData(1) + roiData(3) - 1, i);
end;

imagesc(cropImages(:, :, 1)); axis image; colormap gray

%% zeta for the MINUS image
cP1 = normxcorr2(cropImages(:, :, 3), cropImages(:, :, 1));
c01 = normxcorr2(cropImages(:, :, 2), cropImages(:, :, 1));
cM1 = normxcorr2(cropImages(:, :, 1), cropImages(:, :, 1));

PVcP1 = max(cP1(:));
PVc01 = max(c01(:));
PVcM1 = max(cM1(:));

zetaM = (PVcP1 - PVcM1)/PVc01;
fprintf(1, '%f\n', zetaM);

%% zeta for the ZERO image
cP2 = normxcorr2(cropImages(:, :, 3), cropImages(:, :, 2));
c02 = normxcorr2(cropImages(:, :, 2), cropImages(:, :, 2));
cM2 = normxcorr2(cropImages(:, :, 1), cropImages(:, :, 2));

PVcP2 = max(cP2(:));
PVc02 = max(c02(:));
PVcM2 = max(cM2(:));

zeta0 = (PVcP2 - PVcM2)/PVc02;
fprintf(1, '%f\n', zeta0);

%% zeta for the PLUS image
cP3 = normxcorr2(cropImages(:, :, 3), cropImages(:, :, 3));
c03 = normxcorr2(cropImages(:, :, 2), cropImages(:, :, 3));
cM3 = normxcorr2(cropImages(:, :, 1), cropImages(:, :, 3));

PVcP3 = max(cP3(:));
PVc03 = max(c03(:));
PVcM3 = max(cM3(:));

zetaP = (PVcP3 - PVcM3)/PVc03;
fprintf(1, '%f\n', zetaP);

%% plot the zetas

x = [0 700 1400];
y = [zetaM zeta0 zetaP];

plot([0 700 1400], [zetaM zeta0 zetaP], '.')

%% check zeta for another image

theImage = imread('C:\Users\STED\Documents\Drift Correction\Test Data\Drift Correction Stack Test 40X\40X_OldChamber_RefIm_0500nm.tif');
cropCurrent = theImage(roiData(2):roiData(2) + roiData(4) - 1, roiData(1):roiData(1) + roiData(3) - 1);

cPn = normxcorr2(cropImages(:, :, 3), cropCurrent);
c0n = normxcorr2(cropImages(:, :, 2), cropCurrent);
cMn = normxcorr2(cropImages(:, :, 1), cropCurrent);

PVcPn = max(cPn(:));
PVc0n = max(c0n(:));
PVcMn = max(cMn(:));

zetaN = (PVcPn - PVcMn)/PVc0n;
fprintf(1, '%f\n', zetaN);

hold on
plot(500, zetaN, 'r.')