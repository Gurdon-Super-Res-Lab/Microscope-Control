classdef CalCRLB_4pi_consI < handle
    % (C) Copyright 2017                Huang Lab, Weldon School of Biomedical Engineering, 
    %     All rights reserved           Purdue University, West Lafayette, IN, USA
    %
    %                                   
    % Author: Sheng Liu, March 2020
    %
    % CalCRLB_4pi_consI class for calculating CRLB of 4Pi PSF models with 5 fitting parameters: x, y, z, I, bg
    %   create object: obj = CalCRLB_4pi_consI(PRstruct)
    %
    % CalCRLB_4pi_consI Methods:
    %   prepInputparam - generate parameters of PSFs used for CRLB calculation
    %   calcrlb - calculate CRLB of simulated emitters, given a PSF model
    %   genfigs - generate plots of theoretical localization precision in x, y and z at z positions defined by 'Zpos'
    %
    properties
        % PRstruct - define necessary parameters for a PSF model
        %   NA
        %   Lambda
        %   RefractiveIndex
        %   Pupil: phase retrieved pupil function
        %           phase: phase image
        %           mag: magnitude image
        %   Zernike_phase: coefficient of zernike polynomials representing the pupil phase
        %   Zernike_mag: coefficient of zernike polynomials representing the pupil phase
        %   SigmaX: sigmax of Gaussian filter for OTF rescale, unit is 1/micron in k space, the conversion to real space is 1/(2*pi*SigmaX), unit is micron
        %   SigmaY: sigmay of Gaussian filter for OTF rescale, unit is 1/micron in k space, the conversion to real space is 1/(2*pi*SigmaY), unit is micron
        PRstruct;
        PSFobj;% object of PSF_pupil or PSF_zernike class, used for generating PSFs 
        Xpos;% x positions of simulated emitters, a vector of N elements, unit is pixel
        Ypos;% y positions of simulated emitters, a vector of N elements, unit is pixel
        Zpos;% z positions of simulated emitters, a vector of N elements, unit is micron
        Photon;% photon counts of simulated emitters, a vector of N elements
        Bg;% background photon counts of simulated emitters, a vector of N elements
        Pixelsize;% pixel size at sample plane, unit is micron
        Boxsize;% image size of simulated emitter
        PSFtype;% type of method to generate PSFs for CRLB
        Deltax;% increment in x and y directions for calculating first and second derivative of the objective function, unit is pixel
        Deltaz;% increment in z directions forcalculating first and second derivative of the objective function, unit is micron 
        PN = 4; % number of fitting parameters in CRLB calculation except of background
        FisherM;% Fisher information matrix
    end
    properties (SetAccess = private, GetAccess = public)
        Xin; % parameters of PSFs, a N*PN x PN matrix, N is the number of elements in Xpos. PN is the number of fitting parameters, including x, y, z, photon, bg  
    end
    % output parameters
    properties (SetAccess = private, GetAccess = public)
        CRLB; % CRLB of simulated emmiters, a N x PN matrix, N is the number of elements in Xpos. PN is the number of fitting parameters, including x, y, z, photon, bg  
        X_STD; % theoretical localization precision in X dimension, a vector of N elements, unit is pixel
        Y_STD; % theoretical localization precision in Y dimension, a vector of N elements, unit is pixel
        Z_STD; % theoretical localization precision in Z dimension, a vector of N elements, unit is micron
        Photon_STD; % theoretical localization precision in photon count, a vector of N elements
        Bg_STD; % theoretical localization precision in background count, a vector of N elements
    end
    
    methods
        function obj = CalCRLB_4pi_consI(PRstruct)
            
                    obj.PSFobj = PSF_4pi(PRstruct);
        end
        
        function prepInputparam(obj)
            % prepInputparam - generate parameters of PSFs use for CRLB calculation.
            %   the out put is Xin. it is a N*PN x PN matrix, N is the
            %   number of elements in Xpos. PN is the number of fitting
            %   parameters, including x, y, z, photon, bg
            N = numel(obj.Xpos);
            pN = obj.PN;
            PIx0 = zeros(1,pN);
            PIy0 = zeros(1,pN);
            PIz0 = zeros(1,pN);
            
            PIx0(2) = obj.Deltax;
            PIy0(3) = obj.Deltax;
            PIz0(4) = obj.Deltaz;
            
            x = [];
            y = [];
            z = [];
            x0 = cat(2,obj.Xpos,obj.Ypos,obj.Zpos);
            for t = 1:pN
                x = cat(2,x,x0(:,1)+PIx0(t));
                y = cat(2,y,x0(:,2)+PIy0(t));
                z = cat(2,z,x0(:,3)+PIz0(t));
            end
            obj.Xin = cat(2,reshape(x',N*pN,1),reshape(y',N*pN,1),reshape(z',N*pN,1));
            
        end
        
        function calcrlb(obj,PRstruct1,PRstruct2)
            % calcrlb - calculate CRLB of simulated emitters, given a PSF model.
            %   It uses PSF_pupil or PSF_zernike class to generate PSFs
            %   from given parameters in 'Xin'
            %
            %   see also PSF_pupil
            obj.PSFobj.Xpos = obj.Xin(:,1);
            obj.PSFobj.Ypos = obj.Xin(:,2);
            obj.PSFobj.Zpos = obj.Xin(:,3);
            obj.PSFobj.Boxsize = obj.Boxsize;
            obj.PSFobj.Pixelsize = obj.Pixelsize;
            obj.PSFobj.gen2Pupil(PRstruct1,PRstruct2);
            obj.PSFobj.genPupil_4pi('noIMMaber')
            obj.PSFobj.genPSF_4pi_md();
            label = {'s1','s2','p1','p2'};
            psfL = [];
            for nn = 1:4
                if strcmp(label{nn},'s1')||strcmp(label{nn},'s2')
                    obj.PSFobj.PlaneDis = 0;
                else
                    obj.PSFobj.PlaneDis = 0.0;
                end
                obj.PSFobj.PSFs = obj.PSFobj.PSF4pi.(label{nn});
                obj.PSFobj.scalePSF();
                psfI = obj.PSFobj.ScaledPSFs;
%                psfI = obj.PSFobj.PSFs;
                
                psfL = cat(4,psfL,psfI);
            end
            % calculate Fisher Information matrix
            N = numel(obj.Xpos);
            pN = obj.PN;
            pN0 = 5;
            funFi = zeros(obj.Boxsize,obj.Boxsize,pN0);
            FisherM = zeros(pN0,pN0,4);
            xVar = zeros(N,pN0);
            funFi4 = zeros(obj.Boxsize,obj.Boxsize,pN0,4);
            psfIni4 = zeros(obj.Boxsize,obj.Boxsize,4);
            for s = 0:N-1
                for nn = 1:4
                    t = s+1;
                    psf = psfL(:,:,:,nn);
                    %x
                    funFi(:,:,1) = obj.Photon(t).*(psf(:,:,s*pN+2)-psf(:,:,s*pN+1))./obj.Deltax;
                    %y
                    funFi(:,:,2) = obj.Photon(t).*(psf(:,:,s*pN+3)-psf(:,:,s*pN+1))./obj.Deltax;
                    %z
                    funFi(:,:,3) = obj.Photon(t).*(psf(:,:,s*pN+4)-psf(:,:,s*pN+1))./obj.Deltaz;
                    %I
                    funFi(:,:,4) = psf(:,:,s*pN+1);
                    %bg
                    funFi(:,:,5) = 1;
                    for j = 1:pN0
                        for k = 1:pN0
                            psfIni = psf(:,:,s*pN+1).*obj.Photon(t)+obj.Bg(t);
                            FisherM(j,k,nn) = sum(sum(funFi(:,:,j).*funFi(:,:,k)./psfIni));
                        end
                    end
                    funFi4(:,:,:,nn) = funFi;
                    psfIni4(:,:,nn) = psfIni;
                end
                FisherMsum = squeeze(sum(FisherM,3));
                %FisherMsum(abs(FisherMsum)<1e-12)=1e-12;
                LowerBi = pinv(FisherMsum);
                xVar(t,:) = diag(LowerBi)';
            end
            obj.CRLB = abs(xVar);
            obj.X_STD = sqrt(obj.CRLB(:,1));
            obj.Y_STD = sqrt(obj.CRLB(:,2));
            obj.Z_STD = sqrt(obj.CRLB(:,3));
            obj.Photon_STD = sqrt(obj.CRLB(:,4));
            obj.Bg_STD = sqrt(obj.CRLB(:,5));
            obj.FisherM.foo = funFi4;
            obj.FisherM.psf = psfIni4;
        end
        
        function genfigs(obj)
            % genfigs - generate plots of theoretical localization
            % precision in x, y and z at z positions defined by Zpos
            figure('position',[100,200,500,450])
            plot(obj.Zpos.*1e3,obj.X_STD.*obj.Pixelsize.*1e3,'.-','linewidth',1.2)
            hold on
            plot(obj.Zpos.*1e3,obj.Y_STD.*obj.Pixelsize.*1e3,'.-','linewidth',1.2)
            plot(obj.Zpos.*1e3,obj.Z_STD.*1e3,'.-','linewidth',1.2)
            axis tight;
            xlabel('z positions (nm)')
            ylabel('precison from CRLB (nm)')
            set(gca,'FontSize',14)
            %set(gca,'YLim',[0,51])
            legend('\sigmax','\sigmay','\sigmaz')
        end
    end
    
end
