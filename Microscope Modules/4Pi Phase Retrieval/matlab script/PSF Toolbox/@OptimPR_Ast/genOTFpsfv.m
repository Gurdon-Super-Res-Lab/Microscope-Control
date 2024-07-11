function genOTFpsfv(obj)
z=[obj.PRobj.Zstart:obj.PRobj.Zstep:obj.PRobj.Zend].*1e3;
Sx = polyval(obj.PRobj.PRstruct.px,z);
Sy = polyval(obj.PRobj.PRstruct.py,z);
N = numel(z);
zkpsf = obj.PRobj.PSFstruct.ZKpsf;
modpsf = zeros(size(zkpsf));
for ii = 1:N
    obj.OTFobj.SigmaX = Sx(ii);
    obj.OTFobj.SigmaY = Sy(ii);
    obj.OTFobj.Pixelsize = obj.PRobj.Pixelsize;
    obj.OTFobj.PSFs = zkpsf(:,:,ii);
    obj.OTFobj.scaleRspace();
    modpsf(:,:,ii) = obj.OTFobj.Modpsfs;
end
obj.PRobj.PSFstruct.Modpsf = modpsf;
end