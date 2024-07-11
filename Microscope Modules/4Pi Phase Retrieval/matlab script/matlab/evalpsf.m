function pval = evalpsf(DMmodes,amp,boxsize,I,bg,method)
R = size(DMmodes,1);
psf = genpsffromDMmode(DMmodes,amp);
% oPSF = genpsffromDMmode(DMmodes,amp.*0);
% oPSFn = oPSF./sum(oPSF(:));
% oOTF = fftshift(fft2(fftshift(oPSFn)));
centers = [R/2,R/2];
start = floor(boxsize/2);
roi = psf(centers(1,2)-start+1:centers(1,2)+start,centers(1,1)-start+1:centers(1,1)+start);
data = single(roi.*I + bg);
sz1 = floor((R - boxsize)/2);

switch method
    case 'intensity'
         PSFsigma = 1.1;
%         iterations = 20;
%         fittype = 1;
%         [P, CRLB, LL]=GPUgaussMLEv2(data,PSFsigma,iterations,fittype);
%         Ii = P(3);
%         bgi = P(4);
        img = double(data);
        Edge=[mean(img(1,:)),mean(img(boxsize,:)),mean(img(:,1)),mean(img(:,boxsize))];
        bg0=max(Edge);
        I0 = sum(img(:)-bg0);
        P = fminsearch(@(x) gaussianD(x,data,boxsize,PSFsigma),[I0,bg0,0.5,0.5]); 
        Ii = P(1);
        bgi = P(2);
        %sigmai = P(2);
        %pval = sqrt(2*sigmai^2*pi);
        pval = -1*Ii./bgi;
    case 'reduceM'
%         Edge=[mean(data(1,:)),mean(data(boxsize,:)),mean(data(:,1)),mean(data(:,boxsize))];
%         bg=max(Edge);
        pval = -1*iPALM_ReducedMoments(data,1.1,0);
    case 'OTF'
        img = data;
        Edge=[mean(img(1,:)),mean(img(boxsize,:)),mean(img(:,1)),mean(img(:,boxsize))];
        bg0=max(Edge);
        img1 = img-bg0;
        img1(img1<0)=0;
        img2 = padarray(img1,[sz1,sz1]);
        Ri = size(img2,1);
        [X,Y]=meshgrid(-Ri/2:Ri/2-1,-Ri/2:Ri/2-1);
        Zr = sqrt(X.^2+Y.^2);
        maskc = (Zr<=boxsize/2);
        img2 = img2.*maskc;
        R1 = 50;
        mask = (Zr<=R1);
        psfn = img2./sum(img2(:));
        rOTF = fftshift(fft2(ifftshift(psfn)));
        rOTF1 = abs(rOTF);
        rOTF1n = rOTF1.*mask.*Zr;
        pval = -sum(rOTF1n(:));
        %rOTFi = angle(rOTF).*mask;
%         a = diff(rOTFi);
        %pval1 = sum(rOTFi(:).^2);
        %sigma = 18;
        %model=exp(-X.^2./2./sigma^2).*exp(-Y.^2./2./sigma^2);
%         model = abs(oOTF);
        %pval2 = sum((abs(rOTF(:))-model(:)).^2);
        %pval = pval1.*0.1+pval2;
        
    case 'gaussM'
        PSFsigma = 1.1;
        img = double(data);
        Edge=[mean(img(1,:)),mean(img(boxsize,:)),mean(img(:,1)),mean(img(:,boxsize))];
        bg0=max(Edge);
        img1 = img-bg0;
        img1 = img1./max(img1(:));
        [sse,model]=gaussianD([1,PSFsigma,0,0,0],img,boxsize);
        %img1 = img1.*model;
        pval = sum((model(:)-img1(:)).^2);
        
        
end
end