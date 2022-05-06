function [Pvals,updateM] = optimpsf(updateM,DMmodes,Nm,Pvals,boxsize,I,bg,flatdata,iterN,method)
h = figure;
h.Position = [680   278   620   810];
ha = axes;
ha.Position = [0.13, 0.72, 0.77,0.25];
ha1 = axes;
ha1.Position = [0.13, 0.4, 0.77,0.25];
ha2 = axes;
ha2.Position = [0.13, 0.08, 0.77,0.25];
Nm = size(updateM,1);
modeNm = size(updateM,2);
ModeN = [1:modeNm]';
I0 = I;
bg0 = bg;
count = 0;
Pmin_val = [];
for nn = 1:iterN
%%  plot
%   I = I0 - I0*count.*0.005;
%     bg = bg0 - bg0*count.*0.001;

    count = count + 1;
    plot(Pvals,'Parent',ha)
    ha.YLabel.String='Pval';
    ha.XLabel.String='mirror mode';
    drawnow
%     if mod(nn,75) == 0
%         set(h,'PaperPositionMode','auto')
%         print(h,'-dpng','-r300',['simulate_Ioverbg_',num2str(nn)])
%     end
    %% order
    Pm = sortrows(cat(2,Pvals,ModeN),1);
    Pmin = Pm(1,1);
    Pmax = Pm(modeNm,1);
    Pmax_1 = Pm(modeNm-1,1);
    
    Pmin_val = cat(1,Pmin_val,Pmin);
    plot(Pmin_val,'Parent',ha1)
    ha1.YLabel.String='Pmin';
    ha1.XLabel.String='iteration number';

    x1 = updateM(:,Pm(1,2));
    plot(x1,'Parent',ha2)
    ha2.YLabel.String='x min';
    ha2.XLabel.String='mirror mode';
    
    %% centroid
    x0 = zeros(Nm,1);
    for ii = 1:modeNm
        amp = updateM(:,ii);
        x0 = x0 + amp.*Pvals(ii);
    end
    x0 = x0./sum(Pvals);
    %% reflect
    indn1 = Pm(modeNm,2);
    xn1 = updateM(:,indn1);
    a = 1;
    xr = x0 + a.*(x0-xn1);
    amp = xr - flatdata;
    pvalr = evalpsf(DMmodes,amp,boxsize,I,bg,method);
    
    if pvalr>=Pmin && pvalr<Pmax_1
        updateM(:,indn1) = xr;
        Pvals(indn1) = pvalr;
    elseif pvalr<Pmin
        % expansion
        r = 2;
        xe = x0 + r.*(xr-x0);
        amp = xe - flatdata;
        pvale = evalpsf(DMmodes,amp,boxsize,I,bg,method);
        if pvale<pvalr
            updateM(:,indn1) = xe;
            Pvals(indn1) = pvale;
        else
            updateM(:,indn1) = xr;
            Pvals(indn1) = pvalr;
        end
    elseif pvalr>=Pmax_1
        %contraction
        c = 0.5;
        xc = x0 + c.*(xn1-x0);
        amp = xc - flatdata;
        pvalc = evalpsf(DMmodes,amp,boxsize,I,bg,method);
        if pvalc<Pmax
            updateM(:,indn1) = xc;
            Pvals(indn1) = pvalc;
        else
            % shrink
            s = 0.5;
            x1 = updateM(:,Pm(1,2));
            for ii = 2:modeNm
                xi = updateM(:,Pm(ii,2));
                xi1 = x1 + s.*(xi-x1);
                amp = xi1 - flatdata;
                pvali = evalpsf(DMmodes,amp,boxsize,I,bg,method);
                updateM(:,Pm(ii,2)) = xi1;
                Pvals(Pm(ii,2)) = pvali;
            end
%             count = 0;
%             I0 = I0*(1+rand(1));
%             nn
        end
    end
end
