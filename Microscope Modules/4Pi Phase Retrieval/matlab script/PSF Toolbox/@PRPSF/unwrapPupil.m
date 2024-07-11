function pupilUnwrapped = unwrapPupil(obj, pupil)
% written by Emil B. Kromann from Bewersdorf Lab, Yale University
% modified by Sheng Liu

%% Initialize
Nxyspace    = obj.PSFsize; 
support     = obj.NA_constrain;
% A           = fspecial('gaussian',5,1);
% pupil       = imfilter(PUPIL,A);
%pupil       = angle(pupil);


%% Modify pupil, by repeating edge values
%second method (sideways extension; as in paper)
if (1 == 1)
    nvalidRow = 0;                                                          % initialize index in validRows
    for nrow = 1:Nxyspace;                                                  % for all rows
        [dummy, ncol1] = find(support(nrow,:) == 1, 1, 'first');            % find first pixel on pupil edge in current row
        [dummy, ncol2] = find(support(nrow,:) == 1, 1, 'last');             % find last pixel on pupil edge in current row
        if ~isnan(ncol1) ...                                                % if ncol is defined
                & abs(obj.Phi(nrow,ncol2)) <= pi/4;                            % and if it is the left/right side of the pupil
            nvalidRow = nvalidRow+1;                                            % update index in validRows
            validRows(nvalidRow) = nrow;                                        % remember valid rows
            pupil(nrow,1:ncol1) = pupil(nrow,ncol1);                            % extend pixel value from edge of pupil to edge of FOV in k-space
            pupil(nrow,ncol2:Nxyspace) = pupil(nrow,ncol2);                     % extend pixel value from edge of pupil to edge of FOV in k-space
        end                                                                 %
    end                                                                     %
    
    %extend pupil values up/down
    nvalidCol = 0;                                                          % initialize index in validCols
    for ncol = 1:Nxyspace;                                                  % for all cols
        [nrow1, dummy] = find(support(:,ncol) == 1, 1, 'first');            % find first pixel on pupil edge in current col
        [nrow2, dummy] = find(support(:,ncol) == 1, 1, 'last');             % find last pixel on pupil edge in current col
        if ~isnan(nrow1) ...                                                % if ncol is defined
                & abs(obj.Phi(nrow1,ncol)) >= pi/4 ...                         % and if it is the top/bottom side of the pupil
                & abs(obj.Phi(nrow1,ncol)) <= 3*pi/4;                          % and if it is the top/bottom side of the pupil
            nvalidCol = nvalidCol+1;                                            % update index in validCols
            validCols(nvalidCol) = ncol;                                        % remember valid cols
            pupil(1:nrow1,ncol) = pupil(nrow1,ncol);                            % extend pixel value from edge of pupil to edge of FOV in k-space
            pupil(nrow2:Nxyspace,ncol) = pupil(nrow2,ncol);                     % extend pixel value from edge of pupil to edge of FOV in k-space
        end                                                                 %
    end                                                                     %
    
    %extend pupil values towards corners
    pupil(1:validRows(1),validCols(end):Nxyspace)           = pupil(validRows(1),validCols(end));   % 1st quadrant
    pupil(1:validRows(1),1:validCols(1))                    = pupil(validRows(1),validCols(1));     % 2nd quadrant
    pupil(validRows(end):Nxyspace,1:validCols(1))           = pupil(validRows(end),validCols(1));   % 3rd quadrant
    pupil(validRows(end):Nxyspace,validCols(end):Nxyspace)  = pupil(validRows(end),validCols(end)); % 4th quadrant
end


%% mirror pupil along edges to form 4 quadrants
periodicPupil                                   = zeros(2*Nxyspace,2*Nxyspace);                     % preallocate
periodicPupil(1:Nxyspace,1:Nxyspace)            = pupil;                                            % 2nd quadrant
periodicPupil(1:Nxyspace,Nxyspace+1:2*Nxyspace) = fliplr(periodicPupil(1:Nxyspace,1:Nxyspace));     % 1st quadrant
periodicPupil(Nxyspace+1:2*Nxyspace,:)          = flipud(periodicPupil(1:Nxyspace,:));              % 3rd and 4th quadrant



%% find derivatives numerically and wrap to values within [-pi : pi]
xDeriv = [periodicPupil(:,2:end)  periodicPupil(:,1)] - [periodicPupil];                            % article definition
xDeriv = angle(exp(1i.*xDeriv)); %wrap                                                              % article definition
yDeriv = [periodicPupil(2:end,:); periodicPupil(1,:)] - [periodicPupil];                            % article definition
yDeriv = angle(exp(1i.*yDeriv)); %wrap                                                              % article definition


%% calculate B3
xDerivShiftm = [xDeriv(:,end)  xDeriv(:,1:end-1)];                                                  % article definition
yDerivShiftm = [yDeriv(end,:); yDeriv(1:end-1,:)];                                                  % article definition
rho          = (xDeriv-xDerivShiftm)+(yDeriv-yDerivShiftm);                                         % article definition


%% calculate B5
[n m]               = meshgrid(1:2*Nxyspace,1:2*Nxyspace);                                          % pixel index map
n                   = n - (Nxyspace+1);                                                             % zero to map center
m                   = m - (Nxyspace+1);                                                             % zero to map center
nominator           = (2.*cos( (pi.*m)./Nxyspace ) + 2.*cos( (pi.*n)./Nxyspace ) - 4);              % nominator in B5
oi                  = fft2(rho) ./ fftshift(nominator);                                             % B5
oi(isinf(oi))       = 0;                                                                            % remove inf values
oi(isnan(oi))       = 0;                                                                            % remove NaN values
pupilUnwrapped      = ifft2(oi);                                                                    % Fourier transform B5
pupilUnwrapped      = pupilUnwrapped(1:Nxyspace,1:Nxyspace).*support;                               % remove mirrored pupils


%% Plot results
if (1 == 0)
    figure(1);
    subplot(3,2,1)
    imagesc(abs(periodicPupil)); axis image; axis off; title('abs(phase)'); ylabel('periodic pupil')
    subplot(3,2,2)
    imagesc(angle(periodicPupil)); axis image; axis off; title('angle(phase)')
    subplot(3,2,3)
    imagesc(abs(rho)); axis image; axis off; title('abs(phase)'); ylabel('rho')
    subplot(3,2,4)
    imagesc(angle(rho)); axis image; axis off; title('angle(phase)')
    subplot(3,2,5)
    imagesc(abs(pupilUnwrapped)); axis image; axis off; title('abs(phase)'); ylabel('pupil unwrapped')
    subplot(3,2,6)
    imagesc(angle(pupilUnwrapped)); axis image; axis off; title('angle(phase)')
    colormap hot
end

if (1 == 0)
    figure(2);
    subplot(1,4,1)
    imagesc(pupil);
    subplot(1,4,2)
    imagesc(periodicPupil(1:Nxyspace,1:Nxyspace).*support)
    subplot(1,4,3)
    imagesc(pupilUnwrapped(1:Nxyspace,1:Nxyspace).*support)
    subplot(1,4,4)
    imagesc(angle(exp(1i.*(pupilUnwrapped(1:Nxyspace,1:Nxyspace)))).*support)
    
    figure(3);
    subplot(1,4,1)
    plot(pupil(Nxyspace/2+1,1:Nxyspace));
    subplot(1,4,2)
    plot(periodicPupil(Nxyspace/2+1,1:Nxyspace))
    subplot(1,4,3)
    plot(pupilUnwrapped(Nxyspace/2+1,1:Nxyspace));
    subplot(1,4,4)
    plot(angle(exp(1i.*(pupilUnwrapped(Nxyspace/2+1,1:Nxyspace)))))
end


%% Output results
obj.PRstruct.Pupil.uwphase = pupilUnwrapped;


end



