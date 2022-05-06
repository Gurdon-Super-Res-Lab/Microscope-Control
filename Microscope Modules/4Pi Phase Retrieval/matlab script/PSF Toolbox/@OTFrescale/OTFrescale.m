classdef OTFrescale < handle
    % (C) Copyright 2017                Huang Lab, Weldon School of Biomedical Engineering, 
    %     All rights reserved           Purdue University, West Lafayette, IN, USA
    %
    %                                   Lidke Lab, Physcis and Astronomy,
    %                                   University of New Mexico, Albuquerque,NM, USA                                   
    %                                   
    % Author: Sheng Liu, March 2020
    %
    % OTFrescale class for smoothing input PSFs using a 2D Gaussian filter
    %   create object: obj = OTFrescale();
    %
    % OTFrescale Methods
    %   scaleKspace - apply OTF rescale in k space
    %   scaleRspace - apply OTF rescale in real space
    
    properties
        PSFs;% Input PSFs, it is a 3D matrix with the third dimension to be the number of PSFs.
        % SigmaX - sigmax of Gaussian filter for OTF rescale, unit is
        % 1/micron in k space, the conversion to real space is
        % 1/(2*pi*SigmaX), unit is micron
        SigmaX;
        % SigmaY - sigmax of Gaussian filter for OTF rescale, unit is
        % 1/micron in k space, the conversion to real space is
        % 1/(2*pi*SigmaY), unit is micron
        SigmaY;
        Pixelsize;% pixel size at sample plane, unit is micron
    end
    
    properties (SetAccess = private, GetAccess = public)
        Modpsfs;% OTF rescaled PSFs, it has the same size of 'PSFs'
    end
    
    methods
        function scaleKspace(obj)
            % scaleKspace - apply OTF rescale in k space.
            %   A Gaussian image is generated with its sigmas in x and y
            %   dimensions to be 'SigmaX' and 'SigmaY'. This Gaussian image
            %   is multiplied to the OTFs of the input PSFs to generate
            %   modified OTFs. The Fourier transform of modified OTFs
            %   returns the 'Modpsfs'.
            sz=size(obj.PSFs);
            R=sz(1);
            if numel(sz)==2
                N=1;
            else
                N=sz(3);
            end
            scale=R*obj.Pixelsize;
            [xx,yy]=meshgrid(-R/2:R/2-1,-R/2:R/2-1);
            X=abs(xx)./scale;
            Y=abs(yy)./scale;
            I=1;
            bg=0;
            gauss_k=I.*exp(-X.^2./2./obj.SigmaX^2).*exp(-Y.^2./2./obj.SigmaY^2)+bg;
            
            Mod_psf=zeros(sz);
            for ii=1:N
                Fig1=obj.PSFs(:,:,ii);
                %Fig1=Fig1./sum(sum(Fig1));
                Mod_OTF=fftshift(ifft2(Fig1)).*gauss_k;
                Fig2=abs(fft2(Mod_OTF));
                Mod_psf(:,:,ii)=Fig2;
            end
            obj.Modpsfs=Mod_psf;
        end
        
        function scaleRspace(obj)
            % scaleRspace - apply OTF rescale in real space
            %   A Gaussian image is generated with its sigmas in x and y
            %   dimensions to be 'SigmaXr' and 'SigmaYr', which are
            %   conversions of 'SigmaX' and 'SigmaY' in real space. The
            %   Gaussian image is convolved with the input PSFs to generate
            %   'Modpsfs'.
            sz=size(obj.PSFs);
            R=sz(1);
            if numel(sz)==2
                N=1;
            else
                N=sz(3);
            end
            cropsize=min(29,R);
            sigmaXr=1/2/pi/obj.SigmaX;
            sigmaYr=1/2/pi/obj.SigmaY;
            [X,Y]=meshgrid(-R/2:R/2-1,-R/2:R/2-1);
            xx=X.*obj.Pixelsize;% spatial coordinate at image plane
            yy=Y.*obj.Pixelsize;
            I=1;
            tmp=I*2*pi*obj.SigmaX*obj.SigmaY*exp(-xx.^2./2./sigmaXr^2).*exp(-yy.^2./2./sigmaYr^2);
            realsize0=floor(cropsize/2);
            realsize1=ceil(cropsize/2);
            starty=floor(-realsize0+R/2+1);endy=floor(realsize1+R/2);
            startx=floor(-realsize0+R/2+1);endx=floor(realsize1+R/2);
            gauss_r=tmp(starty:endy,startx:endx);
            gauss_r=gauss_r.*obj.Pixelsize^2;
            
            Mod_psf=zeros(sz);
            for ii=1:N
                Fig1=obj.PSFs(:,:,ii);
                %Fig1=Fig1./sum(sum(Fig1));
                Mod_psf(:,:,ii)=conv2(Fig1,gauss_r,'same');
            end
            obj.Modpsfs=Mod_psf;
        end
        
    end
    
end

