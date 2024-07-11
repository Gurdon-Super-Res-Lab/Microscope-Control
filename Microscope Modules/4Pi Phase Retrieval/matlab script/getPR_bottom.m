function [CN_phase,oprobj] = getPR_bottom(NA, lambda, RI, pixelsize,zrange,CCDoffset,gain,center,channel,pfactor,dmfile,datadir)

%[filename,datapath] = uigetfile([datadir,'*.dcimg'],'MultiSelect','off');

[datapath,fname] = fileparts(datadir);
datafiles = dir([datapath,'\',fname(1:4),'*.dcimg']);
N = length(datafiles);
filename1 = [datapath,'\',datafiles(1).name];
[ims]=iPALM_readdcimg(filename1);
imsz = size(ims);
if ndims(ims)<3
    imsz(3) = 1;
end
imsz(3) = 1;
flipsigns=[0 0 1 1];

for ss = 1:4
eval(['qd',num2str(ss),'= zeros(imsz(1),imsz(1),imsz(3),N);']);
end

for ii = 1:N
    filename1 = [datapath,'\',datafiles(ii).name];
    [ims]=iPALM_readdcimg(filename1);
    [qds]=double(iPALMscmos_makeqds(ims,center,flipsigns));
    for ss = 1:4
        eval(['qd',num2str(ss),'(:,:,:,ii) = qds(:,:,end,ss);']);
    end
end
clear mex

save([datapath,'\',fname,'.mat'],'qd1','qd2','qd3','qd4')


%% create object and setup input for OptimPR_Ast class

oprobj = OptimPR_Ast();                             % create object from OptimPR_Ast class                                             
oprobj.PRobj.CCDoffset = CCDoffset;                       % camera offset of recorded PSF data, unit is ADU
oprobj.PRobj.Gain = gain;                              % camera gain of recorded PSF data
oprobj.PRobj.PRstruct.NA = NA;                     % numerical aperture of the objective lens
oprobj.PRobj.PRstruct.Lambda = lambda;               % center wavelength of the emission band pass filter, unit is micron
oprobj.PRobj.PRstruct.RefractiveIndex = RI;      % refractive index of the immersion medium
oprobj.PRobj.nMed = RI;                          % refractive index of the sample medium
oprobj.PRobj.Pixelsize = pixelsize;                     % pixel size on the sample plane, unit is micron
oprobj.PRobj.PSFsize = 128;                         % image size used for phase retrieval
oprobj.PRobj.SubroiSize = 40;                       % size of the cropped region from the recorded PSF data
oprobj.PRobj.OTFratioSize = 60;                     % image size used for 2D Gaussian fitting in OTF rescale
oprobj.PRobj.ZernikeorderN = 8;                     % maximum order of Zernike coefficient, which is index n defined by the Wyant ordering
oprobj.PRobj.Zstart = zrange(1);                           % start z position of the PSF data, unit in micron
oprobj.PRobj.Zend = zrange(2);                              % end z position of the PSF data, unit in micron
oprobj.PRobj.Zstep = zrange(3);                           % step size of the PSF data, unit in micron
oprobj.PRobj.Zindstart = 1;                         % start index of PSF data used for phase retrieval
oprobj.PRobj.Zindend = N;                       % end index of PSF data used for phase retrieval                      
oprobj.PRobj.Zindstep = 1;                          % index step of PSF data used for phase retrieval, if it is greater than 1, only a subset of the PSF data will be used for PR
oprobj.PRobj.Ztype = 'uniform';                     % axial position type, 'uniform': equally spaced positions, 'random': non-equally spaced positions  
oprobj.PRobj.IterationNum = 30;                     % total iteration number used in phase retrieval algorithm
oprobj.PRobj.IterationNumK = 5;                     % iteration number of PR algorithm after which the data preprocess will be changed 
oprobj.PRobj.PRstruct.SigmaX = 2;                   % sigmax of Gaussian filter for OTF rescale, unit is 1/micron in k space, the conversion to real space is 1/(2*pi*SigmaX), unit is micron
oprobj.PRobj.PRstruct.SigmaY = 2;                   % sigmay of Gaussian filter for OTF rescale, unit is 1/micron in k space, the conversion to real space is 1/(2*pi*SigmaY), unit is micron
oprobj.PRobj.Enableunwrap = 0;                      % enable or disable phase unwrapping for Zernike expansion. Enable: 1, Disable: 0
oprobj.FileDir = datapath;                           % file directory of the PSF data
oprobj.FileName = [fname,'.mat'];                         % file name of the PSF data

% generate PR result
oprobj.prepdata('EMCCD');                           % average over time dimension and convert ADU count to photon count
oprobj.initialPR();                                 % phase retrieval 
%oprobj.PRobj.genPRfigs('zernike');                  % plot of Zernike coefficients from Zernike expansion of the phase and the magnitude parts of the pupil function
%oprobj.PRobj.genPRfigs('pupil');                    % show images of phase retrieved and Zernike expanded pupil function
%oprobj.PRobj.genPRfigs('PSF');                      % show images of PSFs from phase retrieval, Zernike expanded pupil function and after OTF rescale
%% save OptimPR_Ast object
resdir=['output\',datestr(now,'mm-dd-yyyy'),'\PR_result\'];
if ~exist(resdir,'dir')
    mkdir(resdir)
end
oprobj.SaveDir=resdir;
oprobj.SaveName='_PR_result_optimAst';
oprobj.saveObj();

%% conversion to dm amplitude
switch channel
    case '600'
        T = 7.8; % 600 channel
    case '676'
        T = 8.6; % 676 channel
end
phaseZ = oprobj.PRobj.PRstruct.Zernike_phase;
dphase = -1.*phaseZ.*T/2/pi*pfactor;
dphase(1:4) = 0;
load('calibration files\lowerDM_z2m.mat')
flat_current = dlmread(dmfile,'\t');
phase_current = C'\flat_current';
N1 = length(dphase);
phase_next = phase_current;
phase_next(1:N1) = phase_next(1:N1)+dphase';
flat_next = C'*phase_next;
[dmdir,dmfilename,ext] = fileparts(dmfile);
dlmwrite([dmfilename,ext],flat_next','delimiter','\t','precision','%10.8f');
%copyfile([dmfilename,ext],dmdir);
CN_phase = oprobj.PRobj.PRstruct.Zernike_phase;


