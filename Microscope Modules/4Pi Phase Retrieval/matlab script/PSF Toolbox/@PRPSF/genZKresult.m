function genZKresult(obj)
% genZKresult - expand phase retrieved pupil function into zernike polynomials. 
%   It uses the object, 'obj.Z', from Zernike_Polynomials class.
%
%   see also Zernike_Polynomials
pupil_phase=obj.PRstruct.Pupil.phase;
pupil_mag=obj.PRstruct.Pupil.mag;
n=obj.PRstruct.RefractiveIndex;
R=obj.PSFsize;
Z_N=obj.ZernikeorderN;
if isreal(pupil_phase)
    R_aber=pupil_phase.*obj.NA_constrain;
else
    R_aber=angle(pupil_phase).*obj.NA_constrain;
end
U=pupil_mag.*cos(R_aber).*obj.NA_constrain;
V=pupil_mag.*sin(R_aber).*obj.NA_constrain;
complex_Mag=U+1i*V;

[CN_complex,pupil_complexfit]=obj.Z.fitzernike(complex_Mag,'mag',   Z_N, R);
[CN_phase,pupil_phasefit]    =obj.Z.fitzernike(R_aber,     'phase', Z_N, R);
[CN_mag,pupil_magfit]        =obj.Z.fitzernike(pupil_mag,  'mag',   Z_N, R);

% phase unwrap

% uwR_aber = obj.unwrapPupil(R_aber);
% unwrapping = mydialog(R_aber,uwR_aber);
% if unwrapping == 1
%     [CN_phase,pupil_phasefit]    =obj.Z.fitzernike(uwR_aber,'phase', Z_N, R);
%     obj.Enableunwrap = 1;
% else
%     obj.Enableunwrap = 0;
% end

if obj.Enableunwrap == 1
    A = fspecial('gaussian',5,1);
    tmp = imfilter(pupil_phase,A);
    R_aber=angle(tmp).*obj.NA_constrain;
    uwR_aber = obj.unwrapPupil(R_aber);
    [CN_phase,pupil_phasefit]    =obj.Z.fitzernike(uwR_aber,'phase', Z_N, R);
end

% h = figure('Position',[300 300 400 300]);
% ha1 = axes('parent',h,'position',[0.05,0.3,0.45,0.65]);
% imagesc(R_aber,'parent',ha1);colormap(gray)
% axis off
% ha2 = axes('parent',h,'position',[0.5,0.3,0.45,0.65]);
% imagesc(uwR_aber,'parent',ha2);colormap(gray)
% axis off

pupilcompare=pupil_complexfit-pupil_magfit.*exp(pupil_phasefit.*1i);
% generate Zernike fitted PSF
switch obj.Ztype
    case 'random'
        z = obj.Zpos;
    case 'uniform'
        z=[obj.Zstart:obj.Zstep:obj.Zend];
end
N=numel(z);
zernike_psf=zeros(R,R,N);
k_z=sqrt((n/obj.PRstruct.Lambda)^2-obj.k_r.^2).*obj.NA_constrain;
for j=1:N
    defocus_phase=2*pi*z(j).*k_z.*1i;
    pupil_complex=pupil_magfit.*exp(pupil_phasefit.*1i).*exp(defocus_phase);
    psfA=abs(fftshift(fft2(pupil_complex)));
    Fig2=psfA.^2;
    zernike_psf(:,:,j)=Fig2./R^4;
end
% save zernike fitted results and PSF in PRstruct and PSFstruct 
obj.PSFstruct.ZKpsf=zernike_psf;
obj.PRstruct.Zernike_phase=CN_phase;
obj.PRstruct.Zernike_phaseinlambda=CN_phase./2./pi;
obj.PRstruct.Zernike_mag=CN_mag;
obj.PRstruct.Zernike_complex=CN_complex;
obj.PRstruct.Fittedpupil.complex=pupil_complexfit;
obj.PRstruct.Fittedpupil.phase=pupil_phasefit;
obj.PRstruct.Fittedpupil.mag=pupil_magfit;
end

function unwrapping=mydialog(phase,uwphase)
h = figure('Position',[300 300 400 300],'Name','My Dialog');
ha1 = axes('parent',h,'position',[0.05,0.3,0.45,0.65]);
imagesc(phase,'parent',ha1);colormap(gray)
axis off
ha2 = axes('parent',h,'position',[0.5,0.3,0.45,0.65]);
imagesc(uwphase,'parent',ha2);colormap(gray)
axis off

txt = uicontrol('parent',h,'Style','text','string','do you want to use phase unwrapping?','unit','normalized','position',[0.05,0.1,0.6,0.1]);
btn1 = uicontrol('parent',h,'Style','togglebutton','string','yes','unit','normalized','position',[0.7,0.13,0.1,0.1],'callback',@choice);
btn2 = uicontrol('parent',h,'Style','togglebutton','string','no','unit','normalized','position',[0.82,0.13,0.1,0.1],'callback',@choice);
uiwait(h);
    function choice(source,~)
        str=get(source,'string');
        switch str
            case 'yes'
                unwrapping = 1;
            case 'no'
                unwrapping = 0;
        end
        delete(gcf);
    end
end