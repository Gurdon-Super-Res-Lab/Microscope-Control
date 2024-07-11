function phaseretrieve(obj)
% phaseretrieve - generate pupil function based on a phase retrieval
% algorithm described in paper.
switch obj.Ztype
    case 'uniform'
        z = [obj.Zstart:obj.Zstep:obj.Zend];
    case 'random'
        z = obj.Zpos;
end
zind = [obj.Zindstart:obj.Zindstep:obj.Zindend];
N = length(zind);
n = obj.PRstruct.RefractiveIndex;
Freq_max = obj.PRstruct.NA/obj.PRstruct.Lambda;
NA_constrain = obj.k_r<Freq_max;
k_z = sqrt((n/obj.PRstruct.Lambda)^2-obj.k_r.^2).*NA_constrain;
Fig = NA_constrain;
pupil_mag = Fig/sum(sum(Fig)); % initial pupil function

R = obj.PSFsize;
MpsfA = zeros(R,R,N);
RpsfA_phase = zeros(R,R,N);
Rpupil_mag = zeros(R,R,N);
Rpupil_phase = zeros(R,R,N);
pupil_phase = ones(R,R);

for k = 1:obj.IterationNum
    for j=1:N
        defocus_phase=2*pi*z(zind(j)).*k_z;
        pupil_complex=pupil_mag.*exp(defocus_phase.*1i).*pupil_phase;
        Fig1=abs(fftshift(fft2(pupil_complex))).^2;
        PSF0=Fig1./sum(sum(Fig1));
        Mpsfo=squeeze(obj.Mpsf_extend(:,:,zind(j)));
        
        % at iteration number greater than IterationNumK, add previous retrieved PSF information in measured PSF
        if k>obj.IterationNumK
            Mask=(Mpsfo==0);
            Mpsfo(Mask)=PSF0(Mask);
        end
        
        RpsfA=fft2(pupil_complex);
        RpsfA_phase(:,:,j)=RpsfA./abs(RpsfA);
        Fig2=fftshift(sqrt(abs(Mpsfo)));
        MpsfA(:,:,j)=Fig2./sum(sum(Fig2));
        Rpupil=ifft2((MpsfA(:,:,j)).*RpsfA_phase(:,:,j));
        Rpupil_mag(:,:,j)=abs(Rpupil);
        Rpupil_phase(:,:,j)=Rpupil./Rpupil_mag(:,:,j).*exp(-defocus_phase.*1i);
    end
    % generate pupil phase
    Fig5=mean(Rpupil_phase,3);   
    pupil_phase=Fig5./abs(Fig5);
%     A = fspecial('gaussian',5,1);
%     tmp = imfilter(pupil_phase,A);
%     pupil_phase = tmp./abs(tmp);
    % generate pupil magnitude
    Fig3=mean(Rpupil_mag,3).*NA_constrain;
    Fig4=abs(Fig5).*Fig3; % pupil magnitude before normalization
    Fig4=Fig4.^2;
    Fig4=Fig4./sum(sum(Fig4));
    pupil_mag=sqrt(Fig4); % pupil magnitude after normalization
    
end
% generate phase retrieved PSF
psf=zeros(R,R,numel(z));

for j=1:numel(z)
    defocus_phase=2*pi*z(j).*k_z.*1i;
    pupil_complex=pupil_mag.*pupil_phase.*exp(defocus_phase);
    Fig2=abs(fftshift(fft2(pupil_complex))).^2;
    psf(:,:,j)=Fig2./R^2; % normalized PSF
end

% save pupil function and PSF in PRstruct
obj.PRstruct.Pupil.phase=pupil_phase;
obj.PRstruct.Pupil.mag=pupil_mag;
obj.PSFstruct.PRpsf=psf;
end