
classdef PSF_4pi < handle
    % (C) Copyright 2017                Huang Lab, Weldon School of Biomedical Engineering, 
    %     All rights reserved           Purdue University, West Lafayette, IN, USA
    %
    %                                   
    % Author: Sheng Liu, March 2020
    %
    % PSF_4pi class for generating 4PI PSF models
    %   create object: obj = PSF_4pi(PRstruct)
    %
    % PSF_4pi Methods:
    %   precomputeParam - generate images for k space operation
    %   gen2Pupil - generate pupil functions for top and bottom emission paths from user defined or phase retrieved Zernike coefficients
    %   genPupil - generate pupil functions from user defined or phase retrieved Zernike coefficients
    %   genPupil_4pi - generate coherent pupil functions for the four detection channels
    %   genPSF - generate PSF from a given pupil function
    %   genPSF_4pi - generate interferometric PSFs for the four detection channels assuming complete interference where the modulation depth is at the maximum
    %   genPSF_4pi_md - generate interferometric PSFs for the four detection channels assuming partial interference
    %   scalePSF - generate OTF rescaled PSFs
    
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
        Xpos;% x positions of simulated emitters, a vector of N elements, unit is pixel
        Ypos;% y positions of simulated emitters, a vector of N elements, unit is pixel
        Zpos;% z positions of simulated emitters, a vector of N elements, unit is micron
        nMed;% refractive index of the sample medium
        PSFsize; % image size of the pupil function 
        Boxsize; % image size of out put PSF
        Pixelsize;% pixel size at sample plane, unit is micron
        Z;% object from Zernike_Polynomials class
        StagePosUp;% used for PSF model with index mismatch aberration, the distance the top objective moved to focus on the bead away from the coverslip, unit: micron
        StagePosDown;% used for PSF model with index mismatch aberration, the distance the sample stage (relative to bottom objective) moved to focus on the bead away from the coverslip, unit: micron
        Phasediff;% phase difference between s- and p-polarizations
        Iratio = 1;% transmission ratio between top and bottom emission path, from 0 to 1
        Phi0;% cavity phase
        Zoffset = 0; % z offset caused by index mismatch aberration, set to zero when using 'mvbead'
        ChamberH; % the height of the sample chamber
        PlaneDis = 0; % parameter used for dual focal plane method in 4pi
        ModulationDepth = 1;% modulation strength of interferometric PSFs,from 0 to 1 
        % PSFs - out put PSFs from Fourier transform of the pupil function,
        % it's a 3D matrix of Boxsize x Boxsize x N, N is the number of
        % elements in Xpos.
        PSFs;

    end
    
    properties (SetAccess = private, GetAccess = private)
        % precompute images for k space operation
        Zo;% r coordinates of out put PSF, it's a image of PSFsize x PSFsize
        k_r;% k_r coordinates of out put OTF, it's a image of PSFsize x PSFsize
        k_z;% k_z coordinates of out put OTF, it's a image of PSFsize x PSFsize
        Phi;% phi coordinates out put PSF, it's a image of PSFsize x PSFsize
        NA_constrain;% a circle function defining the limit of k_r, it's a image of PSFsize x PSFsize
        Cos1;% cos(theta1), theta1 is the angle of between the k vector and the optical axis in the sample medium
        Cos3;% cos(theta3), theta3 is the angle of between the k vector and the optical axis in the immersion medium
    end    
    
    properties (SetAccess = private, GetAccess = public)
        % IMMPSFs - out put PSFs from Fourier transform of the pupil
        % function modified with the index mismatch aberration, it's a 3D
        % matrix of Boxsize x Boxsize x N, N is the number of elements in
        % Xpos.
        IMMPSFs;
        % ScaledPSFs - out put PSFs after OTF rescale, it's a 3D matrix of
        % Boxsize x Boxsize x N, N is the number of elements in Xpos.
        ScaledPSFs;
        % Pupil - pupil function generated from a set of zernike polynomials
        %           phase: phase image of PSFsize x PSFsize
        %           mag: magnitude image of PSFsize x PSFsize
        Pupila; % Pupil from top objective lens
        Pupilb; % Pupil from bottom objective lens
        Pupil;
        Pupil4pi;% coherent pupil function for each quadrant
        PSF4pi;% 4PiPSF model, containing PSFs from the four quadrants
    end
    
    methods
        function obj=PSF_4pi(PRstruct)
            obj.PRstruct=PRstruct;
        end
        
        function precomputeParam(obj)
            % precomputeParam - generate images for k space operation, and saved in
            % precomputed parameters.
            [X,Y]=meshgrid(-obj.PSFsize/2:obj.PSFsize/2-1,-obj.PSFsize/2:obj.PSFsize/2-1);
            obj.Zo=sqrt(X.^2+Y.^2);
            scale=obj.PSFsize*obj.Pixelsize;
            obj.k_r=obj.Zo./scale;
            obj.Phi=atan2(Y,X);
            n=obj.PRstruct.RefractiveIndex;
            Freq_max=obj.PRstruct.NA/obj.PRstruct.Lambda;
            obj.NA_constrain=obj.k_r<Freq_max;
            obj.k_z=sqrt((n/obj.PRstruct.Lambda)^2-obj.k_r.^2).*obj.NA_constrain;
            sin_theta3=obj.k_r.*obj.PRstruct.Lambda./n;
            sin_theta1=n./obj.nMed.*sin_theta3;
            
            obj.Cos1=sqrt(1-sin_theta1.^2);
            obj.Cos3=sqrt(1-sin_theta3.^2);

            % create Zernike_Polynomials object
            zk = Zernike_Polynomials();
            %zk.Ordering = 'Wyant';
            zk.Ordering = 'Noll';
            ZN=sqrt(numel(obj.PRstruct.Zernike_phase))-1;
            zk.setN(ZN);
            zk.initialize();
            [Zrho, Ztheta, Zinit] = ...
               zk.params3_Zernike(obj.Phi, obj.k_r, obj.PRstruct.NA, obj.PRstruct.Lambda);
            zk.matrix_Z(Zrho, Ztheta, Zinit);
            obj.Z = zk;

        end
        function gen2Pupil(obj,PRstruct1,PRstruct2)
            obj.PRstruct = PRstruct1;
            obj.precomputeParam();
            obj.genPupil();
            obj.Pupila.phase = obj.Pupil.phase;
            obj.Pupila.mag = obj.Pupil.mag;
            obj.PRstruct = PRstruct2;
            obj.precomputeParam();
            obj.genPupil();
            obj.Pupilb.phase = obj.Pupil.phase;
            obj.Pupilb.mag = obj.Pupil.mag;
        end
        function genPupil(obj)
            % genPupil - generate pupil function from Zernike polynomials
            %   Zernike polynomials are a set of images generated by using
            %   Zernike_Polynomials class. The coefficients of the Zernike
            %   polynomials are given from the 'PRstruct'. The resulting
            %   pupil function includes a phase image and a magnitude image
            %
            %   see also Zernike_Polynomials
            R=obj.PSFsize;
            ceffp=obj.PRstruct.Zernike_phase;
            ceffm=obj.PRstruct.Zernike_mag;
            pupil_phase=zeros(R,R);
            pupil_mag=zeros(R,R);
            N=numel(ceffp);
            for k = 1 : N
                pupil_phase = pupil_phase + obj.Z.ZM(:, :, k) .* ceffp(k);
            end
            
            for k = 1 : N
                pupil_mag = pupil_mag + obj.Z.ZM(:, :, k) .* ceffm(k);
            end
            
            % Normalize Zernike coefficients.
            tmp = pupil_mag .* (1/R);
            normF = sqrt(sum(sum(tmp .* conj(tmp))));
            Ceffnorm = ceffm ./ normF;
            
            pupil_magnorm = zeros(R, R);
            for k = 1 : N
                pupil_magnorm = pupil_magnorm + obj.Z.ZM(:, :, k) .* Ceffnorm(k);
            end
            
            obj.Pupil.phase=pupil_phase;
            obj.Pupil.mag=pupil_magnorm;

        end
        
        function genPupil_4pi(obj,type)
            n = obj.PRstruct.RefractiveIndex;
            pupila = obj.Pupila.mag.*exp(1.*obj.Pupila.phase.*1i).*obj.Iratio;%top
            pupilb = obj.Pupilb.mag.*exp(1.*obj.Pupilb.phase.*1i).*exp(1i.*obj.Phi0).*exp(-1i*pi/2);%bottom

            switch type
                case 'noIMMaber'
                    pupilA = pupila;
                    pupilB = pupilb;
                    kz = obj.k_z;
                    zpos = obj.Zpos;
                case 'IMMaber_mvbead'
                    depth1 = obj.StagePosUp*obj.nMed/n;     % top
                    depth2 = obj.StagePosDown*obj.nMed/n;   % bottom
                    % aberration phase from index mismatch
                    %IMMphase1 = obj.getIMM_phase(depth1);
                    IMMphase2 = obj.getIMM_phase(depth2);
                    
                    deltaH = (obj.ChamberH-depth2)*obj.nMed.*obj.Cos1-depth1*n^2/obj.nMed.*obj.Cos3;
                    IMMphase1 = exp(2*pi/obj.PRstruct.Lambda.*deltaH.*obj.NA_constrain.*1i);
                    
                    pupilA = pupila.*IMMphase1;
                    pupilB = pupilb.*IMMphase2;
                    kz = obj.nMed./obj.PRstruct.Lambda.*obj.Cos1;
                    zpos = obj.Zpos;
                    dmin = min([obj.ChamberH-depth2,depth2]);
                    zpos(zpos<-dmin) = -dmin;
                case 'IMMaber_mvstage'
                    depth1 = obj.StagePosUp*obj.nMed/n;     % top
                    depth2 = obj.StagePosDown*obj.nMed/n;   % bottom
                    % aberration phase from index mismatch
                    IMMphase1 = obj.getIMM_phase(depth1);
                    IMMphase2 = obj.getIMM_phase(depth2);
                    
                    pupilA = pupila.*IMMphase1;
                    pupilB = pupilb.*IMMphase2;
                    kz = obj.k_z;
                    zpos = obj.Zpos;
            end
            phia = 0;% no effect on 4pi PSF
            phib = phia-obj.Phasediff;
            N = numel(obj.Xpos);
            R = obj.PSFsize;
            obj.Pupil4pi.s1 = zeros(R,R,N);
            obj.Pupil4pi.s2 = zeros(R,R,N);
            obj.Pupil4pi.p1 = zeros(R,R,N);
            obj.Pupil4pi.p2 = zeros(R,R,N);
            obj.Pupil.top = zeros(R,R,N);
            obj.Pupil.bot = zeros(R,R,N);
            for ii=1:N
                defocusphaseA = exp(-2.*pi.*1i.*(zpos(ii)+obj.Zoffset).*kz);%top
                defocusphaseB = exp(2.*pi.*1i.*zpos(ii).*kz); %bottom
                obj.Pupil4pi.s1(:,:,ii) = pupilA.*exp(1i*pi).*exp(1i*phia).*defocusphaseA+pupilB.*exp(1i*phib).*defocusphaseB;
                obj.Pupil4pi.s2(:,:,ii) = pupilA.*exp(1i*phia).*defocusphaseA+pupilB.*exp(1i*phib).*defocusphaseB;
                obj.Pupil4pi.p1(:,:,ii) = pupilA.*defocusphaseA+pupilB.*exp(1i*pi).*defocusphaseB;
                obj.Pupil4pi.p2(:,:,ii) = pupilA.*defocusphaseA+pupilB.*defocusphaseB;
                
                obj.Pupil.top(:,:,ii) = pupilA.*defocusphaseA;
                obj.Pupil.bot(:,:,ii) = pupilB.*defocusphaseB;
            end
        end
        
        function psfs=genPSF(obj,pupil)
            % genPSF - generate PSFs from the given pupil function.
            %   The PSFs are directly calculated from the Fourier transform
            %   of pupil functions modified by shift phase in x, y and
            %   defocus phase in z. The out put is 'PSFs'
            N=numel(obj.Xpos);
            R=obj.PSFsize;
            Ri=obj.Boxsize;
            psfs=zeros(Ri,Ri,N);
            for ii=1:N
                shiftphase=-obj.k_r.*cos(obj.Phi).*obj.Xpos(ii).*obj.Pixelsize-obj.k_r.*sin(obj.Phi).*obj.Ypos(ii).*obj.Pixelsize;
                shiftphaseE=exp(-1i.*2.*pi.*shiftphase);
                defocusphaseDual = exp(2.*pi.*1i.*obj.PlaneDis.*obj.k_z);
                if nargin>1
                    pupil_complex=pupil(:,:,ii).*shiftphaseE.*defocusphaseDual;
                else
                    defocusphaseE=exp(2.*pi.*1i.*obj.Zpos(ii).*obj.k_z);
                    pupil_complex=obj.Pupil.mag.*exp(obj.Pupil.phase.*1i).*shiftphaseE.*defocusphaseE;
                end
                psfA=abs(fftshift(fft2(pupil_complex)));
                Fig2=psfA.^2;
                realsize0=floor(Ri/2);
                realsize1=ceil(Ri/2);
                startx=-realsize0+R/2+1;endx=realsize1+R/2;
                starty=-realsize0+R/2+1;endy=realsize1+R/2;
                psfs(:,:,ii)=Fig2(startx:endx,starty:endy)./R^4;
            end
            obj.PSFs=psfs;
        end
       
        function genPSF_4pi(obj)
            obj.PSF4pi.s1=obj.genPSF(obj.Pupil4pi.s1)./4;
            obj.PSF4pi.s2=obj.genPSF(obj.Pupil4pi.s2)./4;
            obj.PSF4pi.p1=obj.genPSF(obj.Pupil4pi.p1)./4;
            obj.PSF4pi.p2=obj.genPSF(obj.Pupil4pi.p2)./4;
        end
        
        function genPSF_4pi_md(obj)
            
            obj.PSF4pi.s1 = obj.ModulationDepth.*obj.genPSF(obj.Pupil4pi.s1)./4 + (1-obj.ModulationDepth).*(obj.genPSF(obj.Pupil.top)+obj.genPSF(obj.Pupil.bot))./4;
            obj.PSF4pi.s2 = obj.ModulationDepth.*obj.genPSF(obj.Pupil4pi.s2)./4 + (1-obj.ModulationDepth).*(obj.genPSF(obj.Pupil.top)+obj.genPSF(obj.Pupil.bot))./4;
            obj.PSF4pi.p1 = obj.ModulationDepth.*obj.genPSF(obj.Pupil4pi.p1)./4 + (1-obj.ModulationDepth).*(obj.genPSF(obj.Pupil.top)+obj.genPSF(obj.Pupil.bot))./4;
            obj.PSF4pi.p2 = obj.ModulationDepth.*obj.genPSF(obj.Pupil4pi.p2)./4 + (1-obj.ModulationDepth).*(obj.genPSF(obj.Pupil.top)+obj.genPSF(obj.Pupil.bot))./4;
        end        
        function scalePSF(obj)
            % scalePSF - generate OTF rescaled PSFs
            %   It operates 'PSFs' using the OTFrescale class. The OTF
            %   rescale acts as a 2D Gaussian filter, the resulting PSFs
            %   are smoother than the orignal PSFs.
            %
            %   see also OTFrescale
            otfobj=OTFrescale;
            otfobj.SigmaX=obj.PRstruct.SigmaX;
            otfobj.SigmaY=obj.PRstruct.SigmaY;
            otfobj.Pixelsize=obj.Pixelsize;
            otfobj.PSFs=obj.PSFs;
            otfobj.scaleRspace();
            obj.ScaledPSFs=otfobj.Modpsfs;
        end
        
        function calcrlb(obj)
            % calcrlb - calculate CRLB based on PSF model from phase retrieval result. 
            %   It uses the CalCRLB class. It gives the CRLB in x,y,z
            %   at z positions defined by [obj.Zstart:0.1:obj.Zend], and at 
            %   given photon and background counts at 1000 and 2 respectively 
            %
            %   see also CalCRLB
            crobj = CalCRLB(obj.PRstruct,'4Pi');
            z = obj.Zpos;
            Num = numel(z);
            crobj.Pixelsize = obj.Pixelsize;%micron
            crobj.Xpos = zeros(Num,1);
            crobj.Ypos = zeros(Num,1);
            crobj.Zpos = z;
            crobj.Photon = 1000.*ones(Num,1);
            crobj.Bg = 2.*ones(Num,1);
            crobj.Boxsize = 16;
            crobj.Deltax = 0.1;% pixel
            crobj.Deltaz = 0.01;% micron
            crobj.PSFobj.PSFsize = obj.PSFsize;
            crobj.PSFobj.nMed = obj.nMed;

            crobj.prepInputparam();
            crobj.calcrlb();
            crobj.genfigs();
            
        end
        
        function IMMphase = getIMM_phase(obj,depth)
            n = obj.PRstruct.RefractiveIndex;
            deltaH = depth*obj.nMed.*obj.Cos1-depth*n^2/obj.nMed.*obj.Cos3;
            IMMphase = exp(2*pi/obj.PRstruct.Lambda.*deltaH.*obj.NA_constrain.*1i);
        end
    end
    
        
    
    
end



