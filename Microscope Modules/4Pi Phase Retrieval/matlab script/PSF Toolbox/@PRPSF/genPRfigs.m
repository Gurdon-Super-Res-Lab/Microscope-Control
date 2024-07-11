function genPRfigs(obj,ImgType)
% genPRfigs - generate figures of phase retrieval result, including various PSFs, pupil 
% functions, and plots of zernike coefficients. 
%
%   Input parameter: ImgType - type of image to be generated, select from
%   'PSF', 'pupil' and 'zernike'
switch ImgType
    case 'PSF'
        switch obj.Ztype
            case 'random'
                z = obj.Zpos;
            case 'uniform'
                z=[obj.Zstart:obj.Zstep:obj.Zend];
        end
        
        zind=[obj.Zindstart:obj.Zindstep:obj.Zindend];
        RC=64;
        L=length(zind);
        Mpsf=obj.Mpsf_extend(RC+1-RC/4:RC+1+RC/4,RC+1-RC/4:RC+1+RC/4,:);
        PRpsf=obj.PSFstruct.PRpsf(RC+1-RC/4:RC+1+RC/4,RC+1-RC/4:RC+1+RC/4,:);
        ZKpsf=obj.PSFstruct.ZKpsf(RC+1-RC/4:RC+1+RC/4,RC+1-RC/4:RC+1+RC/4,:);
        Modpsf=obj.PSFstruct.Modpsf(RC+1-RC/4:RC+1+RC/4,RC+1-RC/4:RC+1+RC/4,:);
        h1=[];h2=[];h3=[];h4=[];
        figure('Color',[1,1,1],'Name',' measured and phase retrieved PSF at sampled z positions','Resize','on','Units','pixel','Position',[100,400,1800,1800/(L+1)*4])
        for ii=1:L
            h1(ii)=subplot('position',[(ii-1)/(L+1),0.75,1/(L+1),1/4]);
            image(double(squeeze(Mpsf(:,:,zind(ii)))),'CDataMapping','scaled','Parent',h1(ii))
            if ii==1
                text(3,3,['Measured PSF ',num2str(z(zind(ii)),3),'\mum'],'color',[1,1,1]);
            else
                text(3,3,[num2str(z(zind(ii)),3),'\mum'],'color',[1,1,1]);
            end
            h2(ii)=subplot('position',[(ii-1)/(L+1),0.5,1/(L+1),1/4]);
            image(double(squeeze(PRpsf(:,:,zind(ii)))),'CDataMapping','scaled','Parent',h2(ii))
            if ii==1
                text(3,3,['PR PSF'],'color',[1,1,1]);                
            end
            h3(ii)=subplot('position',[(ii-1)/(L+1),0.25,1/(L+1),1/4]);
            image(double(squeeze(ZKpsf(:,:,zind(ii)))),'CDataMapping','scaled','Parent',h3(ii))
            if ii==1
                text(3,3,['Zernike fitted PSF'],'color',[1,1,1]);                
            end
            h4(ii)=subplot('position',[(ii-1)/(L+1),0,1/(L+1),1/4]);
            image(double(squeeze(Modpsf(:,:,zind(ii)))),'CDataMapping','scaled','Parent',h4(ii))
            if ii==1
                text(3,3,['OTF rescaled PSF'],'color',[1,1,1]);                
            end

        end
        h1(ii+1)=subplot('position',[L/(L+1),0.75,1/(L+1),1/4]);
        image(double(permute(squeeze(Mpsf(17-10:17+10,17,:)),[2,1])),'CDataMapping','scaled','Parent',h1(ii+1))
        text(3,3,['x-z'],'color',[1,1,1]);
        h2(ii+1)=subplot('position',[L/(L+1),0.5,1/(L+1),1/4]);
        image(double(permute(squeeze(PRpsf(17-10:17+10,17,:)),[2,1])),'CDataMapping','scaled','Parent',h2(ii+1))
        h3(ii+1)=subplot('position',[L/(L+1),0.25,1/(L+1),1/4]);
        image(double(permute(squeeze(ZKpsf(17-10:17+10,17,:)),[2,1])),'CDataMapping','scaled','Parent',h3(ii+1))
        h4(ii+1)=subplot('position',[L/(L+1),0,1/(L+1),1/4]);
        image(double(permute(squeeze(Modpsf(17-10:17+10,17,:)),[2,1])),'CDataMapping','scaled','Parent',h4(ii+1))
        colormap(jet)
        axis([h1(1:end-1),h2(1:end-1),h3(1:end-1),h4(1:end-1)],'equal')
        axis([h1(end),h2(end),h3(end),h4(end)],'square')
        axis([h1,h2,h3,h4],'off')
        
    case 'pupil'
        % pupil function at plane1
        figure('Color',[1,1,1],'Name',' phase retrieved and Zernike fitted pupil function','Resize','on','Units','normalized','Position',[0.3,0.3,0.22,0.42])
        h1=[];
        RC=64;
        Rsub=63;
        h1(1)=subplot('Position',[0,0.5,1/2,1/2]);
        image(double(obj.PRstruct.Pupil.mag(RC-Rsub:RC+Rsub,RC-Rsub:RC+Rsub)),'CDataMapping','scaled','Parent',h1(1))
        text(3,8,['PR pupil mag'],'color',[1,1,1]);
        h1(2)=subplot('Position',[0,0,1/2,1/2]);
        image(double(obj.PRstruct.Fittedpupil.mag(RC-Rsub:RC+Rsub,RC-Rsub:RC+Rsub)),'CDataMapping','scaled','Parent',h1(2))
        text(3,8,['Zernike pupil mag'],'color',[1,1,1]);
        h1(3)=subplot('Position',[0.5,0.5,1/2,1/2]);
        tmp=angle(obj.PRstruct.Pupil.phase);
        mag=obj.PRstruct.Pupil.mag;
        mag(mag>0)=1;
        PRphase=tmp.*mag;
        if obj.Enableunwrap==1
            PRphase=obj.PRstruct.Pupil.uwphase;
        end
        image(double(PRphase(RC-Rsub:RC+Rsub,RC-Rsub:RC+Rsub)),'CDataMapping','scaled','Parent',h1(3))
        text(3,8,['PR pupil phase'],'color',[0,0,0]);
        h1(4)=subplot('Position',[0.5,0,1/2,1/2]);
        image(double(obj.PRstruct.Fittedpupil.phase(RC-Rsub:RC+Rsub,RC-Rsub:RC+Rsub)),'CDataMapping','scaled','Parent',h1(4))
        text(3,8,['Zernike pupil phase'],'color',[0,0,0]);
        colormap(gray)
        axis(h1,'equal')
        axis(h1,'off')
     
    case 'zernike'
        ordering = obj.Z.Ordering;
        PlotZernikeC(obj.PRstruct.Zernike_phase,'phase',ordering);
        PlotZernikeC(obj.PRstruct.Zernike_mag,'magnitude',ordering);
end
end

function PlotZernikeC(CN_phase,type,ordering)
nZ=length(CN_phase);
vec=linspace(max(CN_phase),min(CN_phase),9);
dinv=vec(1)-vec(2);
ftsz=12;
figure('position',[200,200,700,300])
plot(CN_phase,'o-')
switch ordering
    case 'Wyant'
        text(nZ+5,vec(1),['x shift: ', num2str(CN_phase(2),'%.2f')],'fontsize',ftsz);
        text(nZ+5,vec(2),['y shift: ', num2str(CN_phase(3),'%.2f')],'fontsize',ftsz);
        text(nZ+5,vec(3),['z shift: ', num2str(CN_phase(4),'%.2f')],'fontsize',ftsz);
        text(nZ+5,vec(4),['Astigmatism: ', num2str(CN_phase(5),'%.2f')],'fontsize',ftsz);
        text(nZ+5,vec(5),['Astigmatism(45^o): ', num2str(CN_phase(6),'%.2f')],'fontsize',ftsz);
        text(nZ+5,vec(6),['Coma(x): ', num2str(CN_phase(7),'%.2f')],'fontsize',ftsz);
        text(nZ+5,vec(7),['Coma(y): ', num2str(CN_phase(8),'%.2f')],'fontsize',ftsz);
        text(nZ+5,vec(8),['Spherical: ', num2str(CN_phase(9),'%.2f')],'fontsize',ftsz);
        text(nZ+5,vec(9),['2nd Spherical: ', num2str(CN_phase(16),'%.2f')],'fontsize',ftsz);
        xlim([0,nZ+30])
        ylim([min(CN_phase)-dinv/2,max(CN_phase)+dinv/2])
        set(gca,'fontsize',ftsz)
        xlabel('Zernike coefficient number','fontsize',ftsz)
        ylabel('Value','fontsize',ftsz)
        title(type)
    case 'Noll'
        text(nZ+5,vec(1),['x shift: ', num2str(CN_phase(2),'%.2f')],'fontsize',ftsz);
        text(nZ+5,vec(2),['y shift: ', num2str(CN_phase(3),'%.2f')],'fontsize',ftsz);
        text(nZ+5,vec(3),['z shift: ', num2str(CN_phase(4),'%.2f')],'fontsize',ftsz);
        text(nZ+5,vec(4),['Astigmatism(45^o): ', num2str(CN_phase(5),'%.2f')],'fontsize',ftsz);
        text(nZ+5,vec(5),['Astigmatism: ', num2str(CN_phase(6),'%.2f')],'fontsize',ftsz);
        text(nZ+5,vec(6),['Coma(y): ', num2str(CN_phase(7),'%.2f')],'fontsize',ftsz);
        text(nZ+5,vec(7),['Coma(x): ', num2str(CN_phase(8),'%.2f')],'fontsize',ftsz);
        text(nZ+5,vec(8),['Spherical: ', num2str(CN_phase(11),'%.2f')],'fontsize',ftsz);
        text(nZ+5,vec(9),['2nd Spherical: ', num2str(CN_phase(22),'%.2f')],'fontsize',ftsz);
        xlim([0,nZ+30])
        ylim([min(CN_phase)-dinv/2,max(CN_phase)+dinv/2])
        set(gca,'fontsize',ftsz)
        xlabel('Zernike coefficient number','fontsize',ftsz)
        ylabel('Value','fontsize',ftsz)
        title(type)
end
% ImgName='_ZernCoeff';
% set(gcf,'PaperPositionMode','auto')
% print(gcf, '-r300', '-djpeg', [PRtest.FileDir,PRtest.FileName(1:end-4),ImgName])

end

