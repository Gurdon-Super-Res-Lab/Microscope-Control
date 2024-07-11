function fitPSFdata(obj)
% fitPSFdata - find 3D localization results of the measured PSFs that were
% used for phase retrieval. 
%   This is used to test phase retrieved PSF model in 3D localization. It
%   uses mexfunction cudaAst_SM_Streams, which uses interpolation from sample
%   PSFs to generate the PSF model. It is compatible with both EMCCD and
%   sCMOS cameras.
tmp=load(fullfile(obj.FileDir,obj.FileName),'dataset');
namei=fields(tmp);
data=single(tmp.(namei{1}));
sz=size(data);
if numel(obj.PRobj.CCDoffset)>1
    CCDoffset=obj.PRobj.CCDoffset(:,:,1);
    Gain=obj.PRobj.Gain(:,:,1);
    CCDoffsetL=repmat(CCDoffset,[1,1,sz(3),sz(4)]);
    GainL=repmat(Gain,[1,1,sz(3),sz(4)]);
    data=(data-CCDoffsetL)./GainL;
else
    data=(data-obj.PRobj.CCDoffset)./obj.PRobj.Gain;
end
data=single(permute(data,[1,2,3,4]));

data(data<=0)=0.01;
P=[];
LL=[];
SSE=[];
crlb=[];
CG=[];
zL=linspace(obj.PRobj.Zstart,obj.PRobj.Zend,sz(4));
for ii=1:sz(4)
    z=zL(ii);
    datai=squeeze(data(:,:,:,ii));
    [Pi,LLi,SSEi,crlbi,CGi]=PRfit(obj,datai,z);
    P=cat(1,P,Pi);
    LL=cat(1,LL,LLi);
    SSE=cat(1,SSE,SSEi);
    crlb=cat(1,crlb,crlbi);
    CG=cat(1,CG,CGi);
end
obj.Fitresult.P=P;
obj.Fitresult.LL=LL;
obj.Fitresult.SSE=SSE;
obj.Fitresult.CRLB=crlb;
obj.Fitresult.CG=CG;
end
function [P,LL,SSE,crlb,CG]=PRfit(obj,dataset,z)
boxsize=obj.BoxSizeFit;
data0=obj.PRobj.BeadData;
dimz0=obj.PRobj.DatadimZ;

sz=size(dataset);
if numel(sz)==3
    obj.PRobj.DatadimZ=sz(3);
else
    obj.PRobj.DatadimZ=1;
end
obj.PRobj.BeadData=dataset;
obj.PRobj.datapreprocess();
MpsfC1=obj.PRobj.Mpsf_subroi;

sz=size(MpsfC1);
Num=sz(3);
Dim1=ones(Num,1).*floor(sz(1)/2);
[subregion1]=chooseSubRegion(Dim1,Dim1,[1:1:Num],boxsize,MpsfC1);

BoxCenters1=zeros(Num,3);
tmp1=repmat([80,60],Num,1);
BoxCenters1(:,1:2)=tmp1-floor(boxsize/2);

channel1=reshape(single(subregion1),Num*boxsize^2,1);
Coords1=reshape(single(BoxCenters1(1:Num,:)'),Num*3,1);
x0=genIniguess(subregion1,z);
x0i=single(reshape(x0',Num*5,1));
switch obj.FitType
    case 1
        [Pi,CGi,CRLBi,Erri,psf]=cudaAst_SM_Streams(channel1,...
            Coords1,...
            obj.SamplePSF,...
            obj.SampleSpacingXY,obj.SampleSpacingZ,...
            obj.SampleS.StartX,obj.SampleS.StartY,obj.SampleS.StartZ,...
            obj.Iterationsfit,Num,obj.FitType,x0i);
        
    case 2
        gainR=repmat(obj.GainRatio,[1,1,sz(3)]);
        obj.PRobj.BeadData=gainR;
        obj.PRobj.datapreprocess();
        gainR1=obj.PRobj.Mpsf_subroi;
        [gainR2]=chooseSubRegion(Dim1,Dim1,[1:1:Num],boxsize,gainR1);
        gainRi=reshape(single(gainR2),Num*boxsize^2,1);
        [Pi,CGi,CRLBi,Erri,psf]=cudaAst_SM_Streams(channel1,...
            Coords1,...
            obj.SamplePSF,...
            obj.SampleSpacingXY,obj.SampleSpacingZ,...
            obj.SampleS.StartX,obj.SampleS.StartY,obj.SampleS.StartZ,...
            obj.Iterationsfit,Num,obj.FitType,x0i,gainRi);
end

ResultSize=6;
x0Size=5;
P=reshape(Pi,ResultSize,Num)';
Err=reshape(Erri,2,Num)';
LL=Err(:,2);
SSE=Err(:,1);
crlb=reshape(CRLBi,x0Size,Num)';
CG=reshape(CGi,x0Size,Num)';  
PSF=reshape(psf,[16,16,Num]);
maxf=max(max(max(mean(PSF,3))),max(max(mean(subregion1,3))));
ov=joinchannels('RGB',mean(PSF,3)./maxf,mean(subregion1,3)./maxf);
ov=single(ov);
figure('position',[400,100,600,200]);
subplot(131)
image(mean(subregion1,3),'cdatamapping','scale');
axis equal;axis tight;
subplot(132)
image(mean(PSF,3),'cdatamapping','scale')
axis equal;axis tight;
subplot(133)
image(ov);
axis equal;axis tight;
colormap(jet)
% put back to origninal data
obj.PRobj.BeadData=data0;
obj.PRobj.DatadimZ=dimz0;
end


function x0=genIniguess(ROIStack1,z)
sz=size(ROIStack1);
Num=sz(3);
start=floor(sz(1)/2);
% xy
subroi=ROIStack1(start-2:start+2,start-2:start+2,:);
[x,y]=meshgrid([start-2:start+2],[start-2:start+2]);
xL=repmat(x,[1,1,Num]);
yL=repmat(y,[1,1,Num]);
area=squeeze(sum(sum(subroi,1),2));
comx=squeeze(sum(sum(subroi.*xL,1),2))./area;
comy=squeeze(sum(sum(subroi.*yL,1),2))./area;
%I,bg
subroi=ROIStack1(2:end-1,2:end-1,:);
sz1=size(subroi);
bg=(sum(sum(ROIStack1,1),2)-sum(sum(subroi,1),2))./(sz(1)^2-sz1(1)^2);
BG=repmat(bg,[sz(1),sz(2),1]);
I=squeeze(sum(sum(ROIStack1-BG,1),2));
I(I<200)=200;
bg=squeeze(bg);
x0=cat(2,comx,comy,I,bg,ones(Num,1).*z);
end

