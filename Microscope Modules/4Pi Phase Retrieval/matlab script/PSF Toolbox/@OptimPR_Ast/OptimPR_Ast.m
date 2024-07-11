classdef OptimPR_Ast < handle
    % (C) Copyright 2017                Huang Lab, Weldon School of Biomedical Engineering, 
    %     All rights reserved           Purdue University, West Lafayette, IN, USA
    %
    %                                   Lidke Lab, Physcis and Astronomy,
    %                                   University of New Mexico, Albuquerque,NM, USA                                   
    %                                   
    % Author: Sheng Liu, March 2020
    %
    % OptimPR_Ast class for optimizing PR result that will be used for 3D localization based on Astigmatism method. 
    %   create object: obj = OptimPR_Ast();
    %
    % OptimPR_Ast Methods:
    %   prepdata - converting ADU count to photon count and averaging over time dimension
    %   initialPR - generate initial phase retrieval result
    %   genPR - generate phase retrieval result with current parameters
    %   genOTFpsf - generated OTF rescaled PSFs
    %   optimPR - optimize phase retrieval result
    %   findAstparam - find parameters of Astigmatism calibration. 
    %   findZestimator - find coefficients for initial estimation of z positions in 3D localization
    %   genSamplePSF - generate sample PSFs used for 3D localization
    %   fitFigure - generate figures from localization results of measured PSFs
    %   fitPSFdata - find 3D localization results of the measured PSFs that were used for phase retrieval
    %   objectivefun - the objective function to be optimized in the optimization step
    %   runMCMC - generate optimized parameters for phase retrieval using Monte Carlo Markov Chain
    %   saveObj - save OptimPR_Ast object in SaveDir with a SaveName
    %
    properties
        Astparam;% parameters from Astigmatism calibration, which relates the width of the PSF in x and y dimensions with z positions. 
        BoxSizeFit;% subregion size for 3D localization, it must be 16
        FileDir;% file directory of the measured PSF data
        FileName;% file name of the measured PSF data
        FitType;% fitting type for specific camera, options are 1: for 'EMCCD' and 2: for 'sCMOS'
        FitZrange;% z range for 3D localization
        % Fitresult - fitting result of bead data that were used for phase retrieval
        %   P: results of fitting parameters, which is [x; y; I; Bg; z]
        %   LL: log likelihood between data and PSF model
        %   SSE: sum of square error between data and PSF model
        %   CRLB: CRLB of each fitting parameters
        %   CG: convergence of each fitting parameters
        Fitresult;
        GainFileDir;% file directory of gain calibration result
        GainFileName;% file name of gain calibration result
        GainRatio;% a 2D matrix with the same size as the PSF image, it is generated from gain calibration results when FitType is 2
        IterationMonte;% number of iterations in optimization of phase retrieved PSF
        Iterationsfit;% number of iterations in 3D localization
        % MCResult - a structure of optimization history
        %   LLTrace: log likelihood values from accepted step
        MCResult;
        OTFobj;% object of OTFrescale class
        PRobj;% object of PRPSF class
        % SamplePSF - a 3D stack of PSF images with finer sampling size than measured
        % PSFs, the sampling size in x,y is 1/4 of the pixel size on the sample
        % plane, the sampling size in z is 5 nm
        SamplePSF;
        SamplePSFsize;% x and y dimensions of SamplePSF, unit is micron
        SampleSpacingXY;% sampling size in xy, which is 1/4 of the pixel size on the sample plane, unit is micron
        SampleSpacingZ;% sampling size in z, which is 0.005 um, unit is micron
        % SampleS - define necessary parameters for generating a set of sample PSFs
        %   Devz: sampling size in z, which is 0.005 um
        %   Devx: sampling size in xy, which is 1/4 of the pixel size on the sample plane, unit is nm
        %   Dlimz: z range of sample PSFs, which is [-1.5, 1.5] um
        %   Pixelsize: pixel size of the sample plane
        %   PixelSizeFine: pixel size of the sample PSFs
        %   PsfSizeFine: x and y dimensions of sample PSFs, unit is pixel
        %   StartX: start position of x coordinate in sample PSFs, unit is micron
        %   StartY: start position of y coordinate in sample PSFs, unit is micron
        %   StartZ: start position of z coordinate in sample PSFs, which is -1.5 um
        %   x0size: number of fitting parameters in 3D localization, which are x, y, z, photon and bg
        %   Zstack: z positions of sample PSFs
        SampleS;
        SaveDir;% save directory of OptimPR_Ast object
        SaveName;% save name of OptimPR_Ast object
        Sx;% width of measured PSFs in x dimension
        Sy;% width of measured PSFs in y dimension
        Zestimator;% coefficients from polynomial fitting for initial estimation of z positions in 3D localization
    end
    
    methods
        function obj=OptimPR_Ast()
            obj.PRobj=PRPSF();
            obj.OTFobj=OTFrescale();
            obj.BoxSizeFit=16;% boxsize must be 16
            obj.SampleS.Devz=0.005; %um
            obj.SampleS.Dlimz=single([-1.5,1.5])'; % um
            obj.SampleS.x0Size=5;
            obj.SampleS.Zstack=[obj.SampleS.Dlimz(1):obj.SampleS.Devz:obj.SampleS.Dlimz(2)]';
        end
        
        function prepdata(obj,cameratype)
            % prepdata - converting ADU count to photon count and averaging
            % over time dimension. 
            %   It is depend on the camera type because of the difference in
            %   gain calibration results
            %   Input parameter: cameratype - type of camera, options are
            %   'EMCCD' and 'sCMOS'
            obj.PRobj.FileDir=obj.FileDir;
            obj.PRobj.FileName=obj.FileName;
            obj.SampleS.PixelSize=obj.PRobj.Pixelsize;
            obj.SampleS.Devx=obj.SampleS.PixelSize/4*1e3; %nm
            obj.SampleS.PsfSizeFine=round(2*obj.BoxSizeFit*obj.SampleS.PixelSize/obj.SampleS.Devx*1e3);
            obj.SampleS.PixelSizeFine=2*obj.BoxSizeFit*obj.SampleS.PixelSize/obj.SampleS.PsfSizeFine;
            w=obj.SampleS.PixelSize./obj.SampleS.PixelSizeFine;
            sigma=[2,2].*w^2;
            obj.SampleS.OTFparam1=single([1/w,sigma(1),sigma(2),0])';

            switch cameratype
                case 'EMCCD'
                    obj.PRobj.prepdata();
                case 'sCMOS'
                    % input validation
                    load(fullfile(obj.FileDir,obj.FileName),'dataset');
                    in=double(dataset);
                    in=squeeze(mean(in,3));
                    szB=size(in);
                    load(fullfile(obj.GainFileDir,obj.GainFileName),'Params');
                    szA=size(Params.Gain);
                    a=szA(1)/2-szB(1)/2+1;
                    b=szA(1)/2+szB(1)/2;
                    Gaini=Params.Gain(a:b,a:b);
                    CCDoffseti=Params.CCDOffset(a:b,a:b);
                    CCDVari=Params.CCDVar(a:b,a:b);
                    CCDoffset=repmat(CCDoffseti,[1,1,szB(3)]);
                    Gain=repmat(Gaini,[1,1,szB(3)]);
                    
                    obj.PRobj.CCDoffset=CCDoffset;
                    obj.PRobj.Gain=Gain;
                    obj.PRobj.prepdata();
                    obj.GainRatio=CCDVari./Gaini./Gaini;
            end
        end
        
        function initialPR(obj)
            % initialPR - generate initial phase retrieval result and use
            % the resulting zernike coefficient to minimize the x,y and z
            % shifts. 
            %
            %   see also PRPSF genPR
            obj.PRobj.precomputeParam();
            if isempty(obj.PRobj.BeadXYshift)
                obj.PRobj.findXYshift();
            end
            obj.genPR();
            % minimize xyz shift
            switch obj.PRobj.Z.Ordering
                case 'Wyant'
                    C4=obj.PRobj.PRstruct.Zernike_phase(4);
                    CXY=obj.PRobj.PRstruct.Zernike_phase([2,3]);
                case 'Noll'
                    C4=obj.PRobj.PRstruct.Zernike_phase(4);
                    CXY=obj.PRobj.PRstruct.Zernike_phase([2,3]).*2;
                    CXY(2) = -1.*CXY(2);
            end
            est=fminsearch(@(x)obj.PRobj.fitdefocus(x,C4),[0.2,1]);% calculate defocus
            zshift=est(1);
            xyshift=CXY*obj.PRobj.PRstruct.Lambda/(2*pi*obj.PRobj.Pixelsize*obj.PRobj.PRstruct.NA);% calculate XY shift
            switch obj.PRobj.Ztype
                case 'random'
                    obj.PRobj.Zpos = obj.PRobj.Zpos+zshift;
                case 'uniform'
                    obj.PRobj.Zstart=obj.PRobj.Zstart+zshift;
                    obj.PRobj.Zend=obj.PRobj.Zend+zshift;
            end
            obj.PRobj.BeadXYshift=obj.PRobj.BeadXYshift-xyshift;
            
            obj.genPR();
            obj.PRobj.findOTFparam(1);
        end
        
        function genPR(obj)
            % genPR - generate phase retrieval result with current
            % parameters
            %
            %   see also PRPSF
            obj.PRobj.datapreprocess();
            obj.PRobj.genMpsf();
            if strcmp(obj.PRobj.PSFtype,'IMM')
                obj.PRobj.phaseretrieveIMM();
            else
                obj.PRobj.phaseretrieve();
            end
            obj.PRobj.genZKresult();
        end
        function genOTFpsf(obj)
            % genOTFpsf - generated OTF rescaled PSFs. 
            %   It uses the OTFrescale class, and operates on zernike fitted
            %   PSFs.
            %
            %   see also OTFrescale
            obj.OTFobj.SigmaX=obj.PRobj.PRstruct.SigmaX;
            obj.OTFobj.SigmaY=obj.PRobj.PRstruct.SigmaY;
            obj.OTFobj.Pixelsize=obj.PRobj.Pixelsize;
            obj.OTFobj.PSFs=obj.PRobj.PSFstruct.ZKpsf;
            obj.OTFobj.scaleRspace();
            obj.PRobj.PSFstruct.Modpsf=obj.OTFobj.Modpsfs;
        end
        function optimPR(obj)
            % optimPR - optimize phase retrieval result. 
            %   It uses Monte Carlo Markov Chain to iteratively update 5
            %   parameters, which are the refractive index, sigmax and sigmay
            %   in OTF rescale, 'SubroiSize' and 'IterationNumK' defined in
            %   PRPSF class, in order to minimize the difference between
            %   phase retrieved PSFs and measured PSFs.
            %   
            %   see also runMCMC objectivefun
            [est,dLL]=obj.runMCMC();
            obj.PRobj.PRstruct.RefractiveIndex=est(3);
            obj.PRobj.PRstruct.SigmaX=est(4);
            obj.PRobj.PRstruct.SigmaY=est(5);
            obj.PRobj.SubroiSize=est(1);
            obj.PRobj.IterationNumK=est(2);
            if isfield(obj.MCResult,'LLTrace')
                obj.MCResult.LLTrace=cat(1,obj.MCResult.LLTrace,dLL);
            else
                obj.MCResult.LLTrace=dLL;
            end
        end
        
        function FileOut=saveObj(obj)
            filename=obj.FileName;
            
            if isempty(obj.SaveDir)
                error('PR:NoSaveDir','save directry is empty')
            else
                PRFileName=fullfile(obj.SaveDir,[filename(1:end-4) obj.SaveName '.mat']);
                save(PRFileName,'obj');
            end
            
            FileOut=[filename(1:end-4) obj.SaveName '.mat'];
        end
       
    end
    
end

