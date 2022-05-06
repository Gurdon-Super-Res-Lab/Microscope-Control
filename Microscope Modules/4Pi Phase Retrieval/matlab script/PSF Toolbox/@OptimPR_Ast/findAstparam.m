function findAstparam(obj,type)
% findAstparam - find parameters of Astigmatism calibration. 
%   Those parameters describe the shape of the PSFs at different z positions.
%   Astigmatism calibration uses a 2D Gaussian to model the PSFs, and the
%   width of the Gaussian in x and y dimensions can be approximated by a
%   function of z with a set of parameters.
Ax=0.01;               
Bx=0.04;
Ay=0.5;
By=0.2;
gamma=0.45 ;          %separation of x/y focal planes
d=0.5;
PSFsigmax=1.2;
Zrange=[obj.PRobj.Zstart,obj.PRobj.Zstep,obj.PRobj.Zend];
fitzRg=obj.FitZrange;
z=[Zrange(1):Zrange(2):Zrange(3)]';
mask=(z>=fitzRg(1))&(z<=fitzRg(2));
zfit=z(mask);
Sx=obj.Sx(mask);
Sy=obj.Sy(mask);
obj.Astparam = [];
startpoint=[Ax,Bx,Ay,By,gamma,d,PSFsigmax];
options = optimset('MaxFunEvals',10000,'MaxIter',10000);
switch type
    case 'both'
        Est=fminsearch(@(x) AstCalibr(x,Sx,Sy,zfit,1),startpoint,options);
        [sse,Sx1,Sy1]=AstCalibr(Est,Sx,Sy,zfit,1);
        obj.Astparam=Est;
    case 'single'
        Estx = fminsearch(@(x) AstCalibr(x,Sx,Sy,zfit,2),startpoint,options);
        Esty = fminsearch(@(x) AstCalibr(x,Sx,Sy,zfit,3),startpoint,options);
        [sse,Sx1,~]=AstCalibr(Estx,Sx,Sy,zfit,2);
        [sse,~,Sy1]=AstCalibr(Esty,Sx,Sy,zfit,3);
        obj.Astparam.estx = Estx;
        obj.Astparam.esty = Esty;
end
figure('position',[200,300,500,400],'color',[1,1,1])
plot(zfit,Sx,'r.',zfit,Sy,'b.','markersize',10)
hold on
plot(zfit,Sx1,'r-',zfit,Sy1,'b-','linewidth',2)
legend('found \sigma_x','found \sigma_y','calibration curve (\sigma_x)','calibration curve (\sigma_y)')
xlabel('z (\mum)','fontsize',12)
ylabel('\sigma_x, \sigma_y, (pixel)','fontsize',12)
title('Calibration curve for Gaussian model','fontsize',12)
set(gca,'fontsize',12)

end

function [SSE,Sx,Sy]=AstCalibr(x,inSx,inSy,z,fitType)
Ax=x(1);               %Aberration Terms
Bx=x(2);
Ay=x(3);
By=x(4);
gamma=x(5) ;          %separation of x/y focal planes
d=x(6);
PSFsigmax=x(7);

Sx=PSFsigmax*sqrt(1+((z-gamma)/d).^2+Ax.*((z-gamma)/d).^3+Bx.*((z-gamma)/d).^4);
Sy=PSFsigmax*sqrt(1+((z+gamma)/d).^2+Ay.*((z+gamma)/d).^3+By.*((z+gamma)/d).^4);

SSE1=sum((inSx-Sx).^2);
SSE2=sum((inSy-Sy).^2);
switch fitType
    case 1
        SSE=SSE1+SSE2;
    case 2
        SSE=SSE1;
    case 3
        SSE=SSE2;
end
end