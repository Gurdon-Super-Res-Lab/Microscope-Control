%% select a measured PSF data
function [beadcenter,beadXYshift]=getbeadcenter(FileDir,FileName,sz)

% create object and set input properties of PRPSF class
% here the settings are for SEQ microscope
probj=PRPSF();
probj.CCDoffset=100;
probj.Gain=2;
probj.PRstruct.NA=1.4;
probj.PRstruct.Lambda=0.7;
probj.PRstruct.RefractiveIndex=1.51;
probj.Pixelsize=0.13;
probj.PSFsize=128;
probj.SubroiSize=30;
probj.OTFratioSize=60;
probj.ZernikeorderN=7;
probj.Zstart = -1; %micron
probj.Zend = 1; %micron
probj.Zstep = 0.4; %micron
probj.Zindstart = 1; %index
probj.Zindend = sz(4);
probj.Zindstep = 1;
probj.IterationNum=25;
probj.IterationNumK=5;
probj.Enableunwrap=1;
probj.nMed = 1.35;
%% generate PR result
probj.FileDir=FileDir;
probj.FileName=FileName;
probj.prepdata();
probj.precomputeParam();
probj.findXYshift();

beadcenter=probj.Beadcenter;
beadXYshift=probj.BeadXYshift;

