function [Zernc]=GenZCoeffv1(obj,sampleS,Thresh)

R=round(64*sampleS.PixelSize/sampleS.Devx*1e3);
pxsz0=obj.Pixelsize;
psz=obj.PSFsize;

obj.PSFsize=R;
obj.Pixelsize=sampleS.PixelSizeFine;
obj.precomputeParam();
Z_N=obj.ZernikeorderN;
Nzern=size(obj.Z.ZM,3);
complex_Mag=zeros(R,R);
for k=1:Nzern
    complex_Mag=complex_Mag+obj.Z.ZM(:,:,k).*obj.PRstruct.Zernike_complex(k);
end
[CN_complex]=obj.Z.fitzernike(complex_Mag,'mag', Z_N, R);


[ZernC1,IndM1,IndN1,IndZern1]=ZernInd(Thresh,Nzern,CN_complex);
pCZ1_real=single(real(ZernC1)');
pCZ1_imag=single(imag(ZernC1)');
Zernc.pCZ1_real=pCZ1_real;
Zernc.pCZ1_imag=pCZ1_imag;
Zernc.IndM1=IndM1;
Zernc.IndN1=IndN1;
Zernc.IndZern1=IndZern1;

obj.PSFsize=psz;
obj.Pixelsize=pxsz0;
obj.precomputeParam();
end
function [ZernC1,IndM1,IndN1,IndZern1]=ZernInd(Thresh,ObjectN,CeffCom1)
NZ=sqrt(ObjectN)-1;
Temp=abs(CeffCom1(1:ObjectN));
mask1=Temp>=Thresh;
ZernC1=CeffCom1(mask1);
j=2;
IndM=zeros(1,ObjectN);
IndN=zeros(1,ObjectN);
IndM(1)=0;
IndN(1)=0;
for nn=1:NZ
    for m=(j-1)/nn:-1:0
        if m~=0 
        IndM(j)=m;IndN(j)=nn; j=j+1;
        IndM(j)=m;IndN(j)=nn; j=j+1;
        else IndM(j)=m;IndN(j)=nn; j=j+1;
        end
    end
end 

IndZern=[0:1:ObjectN-1];
IndM1=single(IndM(mask1)');
IndN1=single(IndN(mask1)');
IndZern1=single(IndZern(mask1)');
end


