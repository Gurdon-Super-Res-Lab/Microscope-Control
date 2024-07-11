addpath('C:\Program Files\DIPimage 2.9\common\dipimage');
dip_initialise;
dipfig -unlink
dipsetpref('DefaultMappingMode','lin');
dipsetpref('DebugMode','on');
dipsetpref('TrueSize','off');

addpath('PSF Toolbox/');
addpath('matlab/')
addpath('mex/')
%%

objective = 'Bottom';
NA = 1.35;
lambda = 0.6; % micron
RI = 1.406;
pixelsize = 0.129; % micron
zrange = [-1,1,0.2]; % start, end, step, micron
CCDoffset = 100;
gain = 2;
center = dlmread('test data\quad_center.txt','\t');
channel = '600';
datadir = 'test data\bead1_bot_001\bead1_bot__560_00000_00000.dcimg';
updateDM = 0;
pfactor = 1; %control convergence speed, if retrieved aberration doesn't converge after two iteration, can use 0.5
try
    switch objective
        case 'Bottom'
            dmfile = 'test data\Default Flat - Lower.txt';
            [coeff, obj] = getPR_bottom(NA, lambda, RI, pixelsize,zrange,CCDoffset,gain,center,channel, pfactor,dmfile,datadir, updateDM);
        case 'Top'
            dmfile = 'test data\Default Flat - Upper.txt';
            [coeff, obj] = getPR_top(NA, lambda, RI, pixelsize,-zrange,CCDoffset,gain,center,channel, pfactor,dmfile,datadir, updateDM);
    end
    
    N1 = numel(coeff);
    zN = linspace(1,N1,N1);
    
catch
    zN = 0;
    coeff = 0;
end

obj.PRobj.genPRfigs('zernike');
obj.PRobj.genPRfigs('pupil'); 
obj.PRobj.genPRfigs('PSF'); 

