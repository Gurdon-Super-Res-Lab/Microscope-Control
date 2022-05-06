%------ Demo code for simulation of 4Pi PSFs------------
% software requirement: Matlab R2015a or later
%                       Dipimage toolbox 2.7 or later
% system requirement:   CPU Intel Core i7
%                       32 GB RAM 
% Note:this example code demonstrates the usage of PSF_zernike and CalCRLB class, 
%      type 'help PSF_4pi' and 'help CalCRLB_4pi_consI' in the command window for more information
%
% (C) Copyright 2020                Huang Lab, Weldon School of Biomedical Engineering, 
%     All rights reserved           Purdue University, West Lafayette, IN, USA
%
%                                   
% Author: Sheng Liu, March 2020
%%
clearvars;
%% create PRstruct and setup parameters
R = 128;                                            % image size used for PSF generation
nmed = 1.351;                                       % refractive index of sample medium
nimm = 1.516;                                       % refractive index of immersion oil
PRstruct.NA = 1.4;                                  % numerical aperture of the objective lens
PRstruct.Lambda = 0.675;                            % center wavelength of the emission band pass filter, unit is micron
PRstruct.RefractiveIndex = nimm;
PRstruct.Pupil.phase = zeros(R,R);                  % initialize pupil function
PRstruct.Pupil.mag = zeros(R,R);
PRstruct.SigmaX = 2;                                % sigmax of Gaussian filter for OTF rescale, unit is 1/micron in k space, the conversion to real space is 1/(2*pi*SigmaX), unit is micron
PRstruct.SigmaY = 2;
PRstruct1 = PRstruct;                               % PRstruct for top objective
PRstruct2 = PRstruct;                               % PRstruct for bottom objective
% add aberrations: same sign for axial symmetric terms, opposite sign for axial asymmetric terms as below 
% aberation for top objective
PRstruct1.Zernike_phase = [0,0,0,0,1.5,0,0,0,0,];   % this generate astigmatism aberration, vector length must be N^2, N is an integer
PRstruct1.Zernike_mag = [1,0,0,0,0,0,0,0,0,];
% aberation for bottom objective
PRstruct2.Zernike_phase = [0,0,0,0,-1.5,0,0,0,0,];  % this generate astigmatism aberration, vector length must be N^2, N is an integer
PRstruct2.Zernike_mag = [1,0,0,0,0,0,0,0,0,];
%% generate PSFs
Num = 101;                                          % number of PSFs
psfobj = PSF_4pi(PRstruct1);                        % create object from PSF_4pi class
zpos = linspace(-1,1,Num);                          % z positions of the PSFs , unit is micron
psfobj.Xpos = zeros(Num,1);                         % x positions of the PSFs, unit is pixel
psfobj.Ypos = zeros(Num,1);                         % y positions of the PSFs, unit is pixel
psfobj.Zpos = zpos';
psfobj.Boxsize = 64;                                % output size of the PSFs
psfobj.Pixelsize = 0.129;                           % pixel size on the sample plane, unit is micron
psfobj.PSFsize = R;                                 % image size used for PSF generation
psfobj.nMed = nmed;
psfobj.Phasediff = pi/2;                            % phase difference between s- and p-polarizations
psfobj.Iratio = 0.7;                                % transmission ratio between top and bottom emission path, from 0 to 1
psfobj.ModulationDepth = 0.7;                       % modulation strength of interferometric PSFs,from 0 to 1 
psfobj.Phi0 = 0;                                    % cavity phase

psfobj.gen2Pupil(PRstruct1,PRstruct2);              % generate pupil functions for top and bottom emission paths
psfobj.genPupil_4pi('noIMMaber');                   % generate interference wavefront of each quadrant (qd)
psfobj.genPSF_4pi_md();
label = {'p1','s2','p2','s1'};                      % labels of the four quadrants, s: s-polarization, p: p-polarization
psf_4pi = [];                                       % simulated 4Pi PSFs, saved as a 4-D matrix (x,y,z,qd)
for nn = 1:4
    psfobj.PSFs = psfobj.PSF4pi.(label{nn});
    psfobj.scalePSF();
    psfI = psfobj.ScaledPSFs;
    psf_4pi = cat(4,psf_4pi,psfI);
end

%% show PSFs in x-z and y-z view
N = 11;
qN = 4;
ind = round(linspace(1,Num,N));
Ri = min([24,psfobj.Boxsize]);
h1 = figure('position',[100,100,100*N,102*4]);
for ii = 1:qN
    psfr = squeeze(psf_4pi(:,:,:,ii));
    Ro = size(psfr,1);
    for jj = 1:N
        ha = axes('position',[(jj-1)/N,(qN-ii)/qN,1/N,1/qN],'parent',h1);
        imagesc(psfr(Ro/2-Ri/2+1:Ro/2+Ri/2,Ro/2-Ri/2+1:Ro/2+Ri/2,ind(jj)));
        axis equal;axis off;
        if ii == 1
        text(2,3, ['z=',num2str(zpos(ind(jj)),3),'\mum'],'color',[1,1,1],'fontsize',12);
        end
        if jj == 1
        text(2,Ri-3, label{ii},'color',[1,1,1],'fontsize',12);
        end
    end
end
colormap(gray)
h1.Position = [100,100,102*N,102*qN];

zm = 0.98;
h2 = figure('position',[100,100,200,(zpos(end)-zpos(1))/(Ri*psfobj.Pixelsize)*200*qN]);
h2.InvertHardcopy = 'off';
for ii = 1:qN
    psfr = squeeze(psf_4pi(:,:,:,ii));
    Ro = size(psfr,1);
    psfroi = psfr(Ro/2-Ri/2+1:Ro/2+Ri/2,Ro/2-Ri/2+1:Ro/2+Ri/2,:);
    ha = axes('position',[0,(qN-ii)/qN,1*zm,1/qN*zm],'parent',h2);
    imagesc(squeeze(psfroi(Ri/2,:,:))');
    text(2,10, label{ii},'color',[1,1,1],'fontsize',12);
    axis off
end

colormap(jet)

%% calculate CRLB from above PSF model
photon = 500;                                       % photon from one objective
bg = 5;                                             % background photon per pixel
crobj = CalCRLB_4pi_consI(PRstruct1);               % create object for CalCRLB_4pi_consI class:5 fitting parameters
                                                    % use "crobj = CalCRLB_4pi(PRstruct1);" for 11 fitting parameters
crobj.Photon = photon.*ones(Num,1);
crobj.Bg = bg.*ones(Num,1);
crobj.Pixelsize = psfobj.Pixelsize;                 % --------copy parameters from psfobj to crobj-----
crobj.Xpos = psfobj.Xpos;
crobj.Ypos = psfobj.Ypos;
crobj.Zpos = psfobj.Zpos;
crobj.Boxsize = psfobj.Boxsize;
crobj.PSFobj.PSFsize = psfobj.PSFsize;
crobj.PSFobj.nMed = nmed;
crobj.PSFobj.Phi0 = psfobj.Phi0;
crobj.PSFobj.Iratio = psfobj.Iratio;
crobj.PSFobj.Phasediff = psfobj.Phasediff;
crobj.PSFobj.ModulationDepth = psfobj.ModulationDepth;%---------------------------------------------------
crobj.Deltax = 0.01;                                % increment in x and y directions for calculating first and second derivative of the objective function, unit is pixel
crobj.Deltaz = 0.001;                               % increment in z direction for calculating first and second derivative of the objective function, unit is micron 

crobj.prepInputparam();                             % generate parameters of PSFs used for CRLB calculation
crobj.calcrlb(PRstruct1, PRstruct2);                % calculate CRLB of simulated emitters, given a PSF model
crobj.genfigs()                                     % generate plots of theoretical localization precision in x, y and z at z positions defined by 'crobj.Zpos'

% output: crobj.X_STD       - precision in x estimation
%         crobj.Y_STD       - precision in y estimation
%         crobj.Z_STD       - precision in z estimation


