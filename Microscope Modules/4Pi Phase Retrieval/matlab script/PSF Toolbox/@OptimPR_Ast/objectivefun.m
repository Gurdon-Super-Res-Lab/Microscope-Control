function [dsse,dLL]=objectivefun(obj,x)
% objectivefun - the objective function to be optimized in the optimization
% step. 
%   It takes the input values in x to generated the phase retrieved PSFs and
%   calculated the log likelihood of the phase retrieved PSFs compared to the
%   measured PSFs.
%
%   see also OTFrescale
obj.PRobj.SubroiSize=x(1);
obj.PRobj.IterationNumK=x(2);
obj.PRobj.PRstruct.RefractiveIndex=x(3);
z=[obj.PRobj.Zstart:obj.PRobj.Zstep:obj.PRobj.Zend];
mask=(z>=obj.FitZrange(1))&(z<=obj.FitZrange(2));
% zind=[obj.PRobj.Zindstart:obj.PRobj.Zindstep:obj.PRobj.Zindend];
% indL=zeros(size(z));
% indL(zind)=1;
% mask1=mask&(indL==1);
obj.genPR();
Mpsfo=obj.PRobj.Mpsf_subroi(:,:,mask);
Zpsfo=obj.PRobj.PSFstruct.ZKpsf(:,:,mask);
% OTF rescale
obj.OTFobj.SigmaX=x(4);
obj.OTFobj.SigmaY=x(5);
obj.OTFobj.Pixelsize=obj.PRobj.Pixelsize;
obj.OTFobj.PSFs=Zpsfo;
obj.OTFobj.scaleRspace();
Zpsf=obj.OTFobj.Modpsfs;
[dsse,dLL]=calErr(Mpsfo,Zpsf);

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
data1i=data1(starty:endy,startx:endx,:);
sz=szm;
starty=-realsize0+floor(sz(2)/2)+1;endy=realsize1+floor(sz(2)/2);
startx=-realsize0+floor(sz(1)/2)+1;endx=realsize1+floor(sz(1)/2);
model1i=model1(starty:endy,startx:endx,:);
sz=size(model1i);
model1o=zeros(sz);

I=1000;
bg=2;
for ii=1:sz(3)
    est1=fminsearch(@(x)modelFit(x,model1i(:,:,ii),data1i(:,:,ii)),[I,bg],optimset('MaxIter',50,'Display','off'));
    est1(est1<0)=0;
    model1o(:,:,ii)=model1i(:,:,ii).*est1(1)+est1(2);
    %model1o(model1o<=0) = 1e-4;
end

overlay=joinchannels('RGB',data1i,model1o);
sse=sum(sum(sum((data1i-model1o).^2)));
%LL=sum(sum(sum(2*(data1i-model1o-model1o.*log(data1i)+model1o.*log(model1o)))));
LL=sum(sum(sum(2*(model1o-data1i+data1i.*log(data1i)-data1i.*log(model1o)))));
end

function sse=modelFit(x,model,data)
I=x(1);
bg=x(2);
modeli=model.*I+bg;
sse=sum(sum((modeli-data).^2));
end
