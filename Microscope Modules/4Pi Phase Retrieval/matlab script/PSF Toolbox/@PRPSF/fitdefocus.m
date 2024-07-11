function [sse,defocus_phase]=fitdefocus(obj,x,C4)
% fitdefocus - find amount of defocus in z of the measured PSF. 
%   It uses the zernike coefficient of defocus aberration found from zernike
%   expansion of phase retrieved pupil function. This method function is used
%   in OptimPR_Bi and OptimPR_Ast classes.
%   
%   see also OptimPR_Bi.initialPR OptimPR_Ast.initialPR
z0=x(1);
bg=x(2);
n=obj.PRstruct.RefractiveIndex;
Freq_max=obj.PRstruct.NA/obj.PRstruct.Lambda;
NA_constrain=obj.k_r<Freq_max;
k_z=sqrt((n/obj.PRstruct.Lambda)^2-obj.k_r.^2);
defocus_phase=real((2*pi*z0.*k_z-bg).*NA_constrain);
Z4=obj.Z.ZM(:,:,4);
sse=sum(sum((C4.*Z4-defocus_phase).^2));
end