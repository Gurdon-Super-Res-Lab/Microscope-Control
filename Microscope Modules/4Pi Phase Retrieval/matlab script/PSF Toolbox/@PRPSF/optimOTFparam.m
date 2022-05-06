function [LLs] = optimOTFparam(obj,ss,plotflag)
R=obj.PSFsize;
Mpsfo = obj.Mpsf_subroi;
Zpsfo = obj.PSFstruct.ZKpsf;
N = size(Mpsfo,3);
OTFparams = zeros(4,N);
Mod_psf=zeros(R,R,N);
LLs = zeros(1,N);
for ii = 1:N
    zkpsfi = Zpsfo(:,:,ii);
    mpsfi = Mpsfo(:,:,ii);
    startpoint = [1,1.5,1.5];
    est = fminsearch(@(x) fitOTF(x,obj,zkpsfi,mpsfi),startpoint,optimset('MaxIter',100,'Display','off'));
    OTFparams(:,ii) = [est,0]';
end
zL = linspace(obj.Zstart,obj.Zend,N).*1e3;
z = zL(ss)';
sx = OTFparams(2,ss);
sy = OTFparams(3,ss);

f = polyfit(z',sx,4);
obj.PRstruct.px = f;
Sx = polyval(f,zL);
f = polyfit(z',sy,4);
obj.PRstruct.py = f;
Sy = polyval(f,zL);
if plotflag == 1
    figure;
    plot(z,sx,'bo',zL,Sx,'b-')
    hold on
    plot(z,sy,'ro',zL,Sy,'r-')
end

OTFparams1 = cat(1,mean(OTFparams(1,ss)).*ones(1,N),Sx,Sy,zeros(1,N));
for ii = 1:N
    zkpsfi = Zpsfo(:,:,ii);
    mpsfi = Mpsfo(:,:,ii);
    
    [LL, psfo] = fitOTF(OTFparams1(:,ii),obj,zkpsfi,mpsfi);
    LLs(ii) = LL;
    Mod_psf(:,:,ii) = psfo;
end
obj.PSFstruct.Modpsf = Mod_psf;
obj.PRstruct.OTFparams = OTFparams;
obj.PRstruct.SigmaX = median(sx);
obj.PRstruct.SigmaY = median(sy);

end

function [LL, Mod_psf] = fitOTF(x,obj,zkpsf,mpsf)
I = x(1);
sx = x(2);
sy = x(3);
[fit_im] = genfitim(obj,[I,sx,sy]);

Fig1 = zkpsf./sum(sum(zkpsf));
Mod_OTF = fftshift(ifft2(Fig1)).*fit_im;
Fig2 = abs(fft2(Mod_OTF));
Mod_psf = Fig2;
[sse,LL] = calErr(mpsf,Mod_psf);

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

function [sse,LL]=calErr(data1,model1)
sz=size(data1);
R1=min(31,sz(1));
szd=size(data1);
szm=size(model1);

realsize0=floor(R1/2);
realsize1=ceil(R1/2);
sz=szd;
starty=-realsize0+floor(sz(2)/2)+1;endy=realsize1+floor(sz(2)/2);
startx=-realsize0+floor(sz(1)/2)+1;endx=realsize1+floor(sz(1)/2);
data1i=data1(starty:endy,startx:endx);
sz=szm;
starty=-realsize0+floor(sz(2)/2)+1;endy=realsize1+floor(sz(2)/2);
startx=-realsize0+floor(sz(1)/2)+1;endx=realsize1+floor(sz(1)/2);
model1i=model1(starty:endy,startx:endx);

I=1000;
bg=2;

est1=fminsearch(@(x)modelFit(x,model1i,data1i),[I,bg],optimset('MaxIter',50,'Display','off'));
est1(est1<0)=0;
model1o=model1i.*est1(1)+est1(2);
%model1o(model1o<=0) = 1e-4;

overlay=joinchannels('RGB',data1i,model1o);
sse = sum((data1i(:)-model1o(:)).^2);
%LL=sum(sum(sum(2*(data1i-model1o-model1o.*log(data1i)+model1o.*log(model1o)))));
LL = sum(2*(model1o(:)-data1i(:)+data1i(:).*log(data1i(:))-data1i(:).*log(model1o(:))));
end

function sse=modelFit(x,model,data)
I=x(1);
bg=x(2);
modeli=model.*I+bg;
sse=sum(sum((modeli-data).^2));
end
