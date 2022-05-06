function [ims, qds, cocrops]=iPALM_readdcimg(filename,center,co_cropims)

% July 16th 2014 default position [299 464 1571 1736];

% default center position for quadrant July9th_2014 h_centers=[320 478 1556
% 1715];



files=dir(filename);
if numel(files)>1
    error('Multiple files with the same assigned name are detected');
elseif numel(files)==0
    error('No file detected');
end


[tmp, totalframes]= dcimgmatlab(0, filename);
ims=zeros(size(tmp,2),size(tmp,1),totalframes);

cutflag=0;
cocropflag=0;

qds=[];
cocrops=[];
if nargin>1
    cutflag=1;
end

if nargin>2
    cocropflag=1;
end

if cutflag==0
    for ii=1:totalframes
        ims(:,:,ii)=dcimgmatlab(ii-1, filename)';
    end
else
    for ii=1:totalframes
        ims(:,:,ii)=dcimgmatlab(ii-1, filename)';
    end
    
    if numel(center(1,:))==2 && numel(center)==4
        R = 256;
        ccH = center(1,:);
        ccV = center(2,:);
        im1 = ims(ccV(1)-R/2+1:ccV(1)+R/2,ccH(1)-R/2+1:ccH(1)+R/2,:);
        im2 = ims(ccV(2)-R/2+1:ccV(2)+R/2,ccH(2)-R/2+1:ccH(2)+R/2,:);
        im2 = flip(im2,2);
        qds = cat(4,im1,im2);
    elseif numel(center)==2
        R = 64;
        im1 = ims(center(1):center(1)+R-1,center(2):center(2)+R-1,:);
        qds = im1;
    else
        flipsigns=[0 0 1 1];
        [qds]=iPALMscmos_makeqds(ims,center,flipsigns);
        %     qd1=ims(:,(center(1)-84):(center(1)+83),:);
        %     qd2=ims(:,(center(2)-84):(center(2)+83),:);
        %     qd3=ims(:,(center(3)-84):(center(3)+83),:);
        %     qd4=ims(:,(center(4)-84):(center(4)+83),:);
        %     qd3=flipdim(qd3,2);
        %     qd4=flipdim(qd4,2);
        if cocropflag==1
            [cocrops]=iPALMscmos_makeqds(co_cropims,center,flipsigns);
            %crop all attached images
        end
    end
    
end

%clear mex



