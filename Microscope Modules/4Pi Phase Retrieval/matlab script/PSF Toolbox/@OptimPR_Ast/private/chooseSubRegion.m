function [subregion]=chooseSubRegion(Dim1,Dim2,Dim3,boxsize,in)
indouble=double(in);
realsize0=floor(boxsize/2);
realsize1=ceil(boxsize/2);
start1=-realsize0+Dim1+1;end1=realsize1+Dim1;
start2=-realsize0+Dim2+1;end2=realsize1+Dim2;
bxnum=length(Dim1);
subregion=zeros(boxsize,boxsize,bxnum);
for ii=1:bxnum
    subregion(:,:,ii)=indouble(start1(ii):end1(ii),start2(ii):end2(ii),Dim3(ii));
end
end