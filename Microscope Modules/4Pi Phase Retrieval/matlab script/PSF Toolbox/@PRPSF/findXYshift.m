function findXYshift(obj)
% findXYshift - find x,y shift of selected bead image using a 2D Gaussian
% fit to the most infocus PSF.
%   The selected bead image is cropped around the selected pixel from the
%   BeadData.
R=[obj.DatadimX,obj.DatadimY];
Fig1=squeeze(obj.BeadData(:,:,ceil(obj.DatadimZ/2)));
h=dipshow(Fig1);
maxdim = max(size(Fig1));
diptruesize(h,1000/maxdim*100);
Centers=dipgetcoords(1);
close(h)
Ri=32;
PHI=obj.PhiC;
Zo=obj.ZoC;
realsize0=floor(Ri/2);
realsize1=ceil(Ri/2);
starty=-realsize0+R(2)/2+1;endy=realsize1+R(2)/2;
startx=-realsize0+R(1)/2+1;endx=realsize1+R(1)/2;

tmp=fftshift(ifft2(Fig1));
shiftphase=-Zo./R(1).*cos(PHI).*(R(1)/2-Centers(1,1)-1)-Zo./R(2).*sin(PHI).*(R(2)/2-Centers(1,2)-1);
tmp1=fft2(tmp.*exp(-2*pi.*shiftphase.*1i));
tmp2=abs(tmp1(starty:endy,startx:endx));
Mfocus=tmp2;
[Dxy,fval,exitflag]=fminsearch(@(x) gaussianD(x,Mfocus,Ri),[1000,1,1,0.5,0.5]); %Dxy(4:5) are XY shift 

obj.Beadcenter=Centers;
obj.BeadXYshift=Dxy(4:5);
end

function [sse,data]=gaussianD(x,input_im,R)
I=x(1);
sigma=x(2);
bg=x(3);
x0=x(4);
y0=x(5);
[xx,yy]=meshgrid(-R/2:R/2-1,-R/2:R/2-1);

X=abs(xx);
Y=abs(yy);
Model=I.*exp(-X.^2./2./sigma^2).*exp(-Y.^2./2./sigma^2)+bg;

PHI=atan2(yy,xx);
Zo=sqrt(xx.^2+yy.^2);

tmp=fftshift(ifft2(input_im));
shiftphase=-Zo./R.*cos(PHI).*x0-Zo./R.*sin(PHI).*y0;
tmp1=fft2(tmp.*exp(-2*pi.*shiftphase.*1i));

data=abs(tmp1);

sse=sum(sum((Model-data).^2));
end