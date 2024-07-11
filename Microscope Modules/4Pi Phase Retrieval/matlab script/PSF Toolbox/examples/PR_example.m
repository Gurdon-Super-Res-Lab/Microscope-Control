%------ Demo code for phase retrieval on experimental recoreded PSF data------------
% software requirement: Matlab R2015a or later
%                       Dipimage toolbox 2.7 or later
% system requirement:   CPU Intel Core i7
%                       32 GB RAM 
% Data format: data must be .mat file, containing a R by R by t by N matrix, R
%              is the x and y dimension of the image, N is the number of
%              axial positions, t is the number of frames at each axial
%              position
% Note:this example code demonstrates the usage of OptimPR_Ast class, 
%      type 'help OptimPR_Ast' in the command window for more information
%
% (C) Copyright 2020                Huang Lab, Weldon School of Biomedical Engineering, 
%     All rights reserved           Purdue University, West Lafayette, IN, USA
%
%                                   Lidke Lab, Physcis and Astronomy,
%                                   University of New Mexico, Albuquerque,NM, USA                                   
%                                   
% Author: Sheng Liu, March 2020

%%
clearvars
addpath('test data\');
%% select a recorded PSF data
[FileDir, FileName] = fileparts(['test data\bead_bot_000_020.mat']);
F = load(fullfile(FileDir,FileName));
namei = fieldnames(F);
sz = size(F.(namei{1}));

%% create object and setup input for OptimPR_Ast class

oprobj = OptimPR_Ast();                             % create object from OptimPR_Ast class                                             
oprobj.PRobj.CCDoffset = 100;                       % camera offset of recorded PSF data, unit is ADU
oprobj.PRobj.Gain = 2;                              % camera gain of recorded PSF data
oprobj.PRobj.PRstruct.NA = 1.4;                     % numerical aperture of the objective lens
oprobj.PRobj.PRstruct.Lambda = 0.675;               % center wavelength of the emission band pass filter, unit is micron
oprobj.PRobj.PRstruct.RefractiveIndex = 1.516;      % refractive index of the immersion medium
oprobj.PRobj.nMed = 1.351;                          % refractive index of the sample medium
oprobj.PRobj.Pixelsize = 0.129;                     % pixel size on the sample plane, unit is micron
oprobj.PRobj.PSFsize = 128;                         % image size used for phase retrieval
oprobj.PRobj.SubroiSize = 40;                       % size of the cropped region from the recorded PSF data
oprobj.PRobj.OTFratioSize = 60;                     % image size used for 2D Gaussian fitting in OTF rescale
oprobj.PRobj.ZernikeorderN = 7;                     % maximum order of Zernike coefficient, which is index n defined by the Wyant ordering
oprobj.PRobj.Zstart = -1;                           % start z position of the PSF data, unit in micron
oprobj.PRobj.Zend = 1;                              % end z position of the PSF data, unit in micron
oprobj.PRobj.Zstep = 0.1;                           % step size of the PSF data, unit in micron
oprobj.PRobj.Zindstart = 1;                         % start index of PSF data used for phase retrieval
oprobj.PRobj.Zindend = sz(4);                       % end index of PSF data used for phase retrieval                      
oprobj.PRobj.Zindstep = 4;                          % index step of PSF data used for phase retrieval, if it is greater than 1, only a subset of the PSF data will be used for PR
oprobj.PRobj.Ztype = 'uniform';                     % axial position type, 'uniform': equally spaced positions, 'random': non-equally spaced positions  
oprobj.PRobj.IterationNum = 30;                     % total iteration number used in phase retrieval algorithm
oprobj.PRobj.IterationNumK = 5;                     % iteration number of PR algorithm after which the data preprocess will be changed 
oprobj.PRobj.PRstruct.SigmaX = 2;                   % sigmax of Gaussian filter for OTF rescale, unit is 1/micron in k space, the conversion to real space is 1/(2*pi*SigmaX), unit is micron
oprobj.PRobj.PRstruct.SigmaY = 2;                   % sigmay of Gaussian filter for OTF rescale, unit is 1/micron in k space, the conversion to real space is 1/(2*pi*SigmaY), unit is micron
oprobj.PRobj.Enableunwrap = 0;                      % enable or disable phase unwrapping for Zernike expansion. Enable: 1, Disable: 0
oprobj.FileDir = FileDir;                           % file directory of the PSF data
oprobj.FileName = FileName;                         % file name of the PSF data

%% generate PR result
oprobj.prepdata('EMCCD');                           % average over time dimension and convert ADU count to photon count
oprobj.initialPR();                                 % phase retrieval 
oprobj.PRobj.genPRfigs('zernike');                  % plot of Zernike coefficients from Zernike expansion of the phase and the magnitude parts of the pupil function
oprobj.PRobj.genPRfigs('pupil');                    % show images of phase retrieved and Zernike expanded pupil function
oprobj.PRobj.genPRfigs('PSF');                      % show images of PSFs from phase retrieval, Zernike expanded pupil function and after OTF rescale
%% save OptimPR_Ast object
resdir=fullfile('output\PR_result\');
if ~exist(resdir,'dir')
    mkdir(resdir)
end
oprobj.SaveDir=resdir;
oprobj.SaveName='_PR_result_optimAst';
oprobj.saveObj();


