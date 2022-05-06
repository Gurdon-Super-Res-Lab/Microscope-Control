
function [maxa,cc,maxcc] = cc2(ref,img)
ref = ref-mean(ref(:));
ref = ref/std(ref(:));
img = img-mean(img(:));
img = img/std(img(:));
cc = abs(ifft2(fft2(ref).*conj(fft2(img))));
maxa = 1/numel(img)*max(cc(:));

maxcc = sum(ref(:).*img(:))/numel(img);

end