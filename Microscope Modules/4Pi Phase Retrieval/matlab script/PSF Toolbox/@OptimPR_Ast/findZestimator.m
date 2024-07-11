function findZestimator(obj)
% findZestimator - find coefficients for initial estimation of z positions
% in 3D localization. 
%   The initial z estimation is found by the following steps:
%   1. found the width of the measured PSFs in x and y dimensions (Sx and Sy) at different z
%      positions using a 2D Gaussian fit.
%   2. calculate Sr = Sy^2 - Sx^2.
%   3. find coefficients of cubic fit of Sr relative to z
%   4. save the coefficients in 'Zestimator' for 3D localization
Nfit=obj.PRobj.DatadimZ;
Npixel=obj.BoxSizeFit;
R1=obj.PRobj.SubroiSize;
PSFsigma=1;         %PSF sigma in pixels
fittype=4;
GainRatio=zeros(obj.PRobj.DatadimY,obj.PRobj.DatadimX);
Coords=single(reshape(repmat([1,1],1,Nfit)',2,Nfit));
iterations=100;
a=floor(R1/2)-floor(Npixel/2)+1;
b=floor(R1/2)+ceil(Npixel/2);
data=single(obj.PRobj.Mpsf_subroi(a:b,a:b,:));
data1=permute(data,[2,1,3]);
[P CRLB LL]=GPUgaussMLEv2_sCMOS(data1,Coords,GainRatio,PSFsigma,iterations,fittype);
obj.Sx=P(:,5);
obj.Sy=P(:,6);
Sr=P(:,6).^2-P(:,5).^2;
%Sr = P(:,6).^3./P(:,5)-P(:,5).^3./P(:,6);

Zrange=[obj.PRobj.Zstart,obj.PRobj.Zstep,obj.PRobj.Zend];
fitzRg=obj.FitZrange;
zL=[Zrange(1):Zrange(2):Zrange(3)]';
mask=(zL>=fitzRg(1))&(zL<=fitzRg(2));
z=zL(mask);
fitSrRg=Sr(mask);
p1=polyfit(fitSrRg,z,3);
f1=polyval(p1,Sr);
figure('position',[200,200,700,600]);
plot(Sr,zL,'o',Sr,f1,'g.','markersize',10);
hold on
plot(fitSrRg,f1(mask),'r*-','linewidth',2,'markersize',10);
ylim([Zrange(1)-0.1,Zrange(3)+0.1])
title('Calibration curve for initial z estimation','fontsize',12)
xlabel('Sigma R (pixels)','fontsize',12)
ylabel('z (\mum)','fontsize',12)
set(gca,'fontsize',12)
obj.Zestimator=p1;
end
