function OTFparam=findOTFparam(obj,plotflag)
% findOTFparam - find SigmaX and SigmaY of a Gaussian filter for OTF rescale. 
%   They are found by fitting the ratio OTF with a 2D gaussian, the ratio OTF
%   is the ratio between the measured OTF and the phase retreived OTF
R=obj.PSFsize;
switch obj.Ztype
    case 'random'
        z = obj.Zpos;
    case 'uniform'
        z=[obj.Zstart:obj.Zstep:obj.Zend];
end
N=obj.DatadimZ;
[val,ind]=min(abs(z));
realsize0=floor(obj.OTFratioSize/2);
realsize1=ceil(obj.OTFratioSize/2);
starty=-realsize0+R/2+1;endy=realsize1+R/2;
startx=-realsize0+R/2+1;endx=realsize1+R/2;
ss = [ind:ind];
Ns = numel(ss);
OTFparams = zeros(4,Ns);
for nn = 1:Ns
    mOTF=fftshift(ifft2(obj.Mpsf_extend(:,:,ss(nn))));% measured OTF
    rOTF=fftshift(ifft2(obj.PSFstruct.ZKpsf(:,:,ss(nn)))); % phase retrieved OTF
    tmp=abs(mOTF)./abs(rOTF);
    tmp1=tmp(startx:endx,starty:endy);
    ratio=tmp1;
    [I,sigmax,sigmay,bg]=GaussRfit(obj,ratio);
    OTFparam=[I,sigmax,sigmay,bg];
    OTFparam(OTFparam>5) = 1.5;
    OTFparams(:,nn) = OTFparam;
%     if ss(nn)==ind
%         fit_im = fit_imi;
%     end
end

% zL = linspace(obj.Zstart,obj.Zend,N).*1e3;
% z = zL(ss)';
% sx = OTFparams(2,:);
% sy = OTFparams(3,:);
% 
% f = polyfit(z',sx,2);
% obj.PRstruct.px = f;
% Sx = polyval(f,zL);
% f = polyfit(z',sy,2);
% obj.PRstruct.py = f;
% Sy = polyval(f,zL);
% if plotflag == 1
%     figure;
%     plot(z,sx,'bo',zL,Sx,'b-')
%     hold on
%     plot(z,sy,'ro',zL,Sy,'r-')
% end
%OTFparams1 = cat(1,mean(OTFparams(1,:)).*ones(1,N),Sx,Sy,zeros(1,N));
OTFparams1 = repmat(OTFparams,1,N);
% a = padarray(ratio,[44,44],0,'both');
% joinchannels('RGB',a,fit_im)
fit_ims = zeros(R,R,N);
for ii = 1:N
[fit_im] = genfitim(obj,OTFparams1(:,ii));
fit_ims(:,:,ii) = fit_im;
end
% generate zernike fitted PSF modified by OTF rescale
Mod_psf=zeros(R,R,N);
for ii=1:N
    Fig4=obj.PSFstruct.ZKpsf(:,:,ii);
    Fig4=Fig4./sum(sum(Fig4));
    
    Mod_OTF=fftshift(ifft2(Fig4)).*fit_ims(:,:,ii);
    Fig5=abs(fft2(Mod_OTF));
    Mod_psf(:,:,ii)=Fig5;
end
% save SigmaX and SigmaY in PRstruct
obj.PRstruct.SigmaX=OTFparams1(2,ind);
obj.PRstruct.SigmaY=OTFparams1(3,ind);
% save modified PSF in PSFstruct
obj.PSFstruct.Modpsf=Mod_psf;
end

function [I,sigmax,sigmay,bg]=GaussRfit(obj,ratio)
R=obj.PSFsize;
R1=obj.OTFratioSize;
scale=R*obj.Pixelsize;
x = [-R1/2:R1/2-1]./scale;
Ix = mean(ratio,1);
Iy = mean(ratio,2);

fx = fit(x',Ix','gauss1');
sigmax = fx.c1/sqrt(2);
fy = fit(x',Iy,'gauss1');
sigmay = fy.c1/sqrt(2);

I = (fx.a1 + fy.a1)/2;

Ixf = feval(fx,x);
Iyf = feval(fy,x);
% figure;plot(x,Ix,'bo',x,Ixf,'r-')
% figure;plot(x,Iy,'bo',x,Iyf,'r-')
bg = 0;

end

function [fit_im] = genfitim(obj,OTFparams)
R=obj.PSFsize;
I = OTFparams(1);
sigmax = OTFparams(2);
sigmay = OTFparams(3);
bg=0;
scale=R*obj.Pixelsize;
[xx,yy]=meshgrid(-R/2:R/2-1,-R/2:R/2-1);

X=abs(xx)./scale;
Y=abs(yy)./scale;
fit_im=I.*exp(-X.^2./2./sigmax^2).*exp(-Y.^2./2./sigmay^2)+bg;
end