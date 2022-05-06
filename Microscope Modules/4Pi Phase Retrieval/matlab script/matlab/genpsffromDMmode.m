function psf = genpsffromDMmode(DMmodes,amp)
N = numel(amp);
R = size(DMmodes,1);
pupil = zeros(R,R);
scale = 8;
amps = amp./scale;
for ii = 1:N
    pupil = pupil + DMmodes(:,:,ii).*amps(ii);
end
mask = (DMmodes(:,:,1) ~= 0);
pupil = exp(1i.*pupil).*mask;
tmp1 = fftshift(fft2(pupil));
tmp2 = tmp1.*conj(tmp1);
psf = tmp2./sum(tmp2(:));
end