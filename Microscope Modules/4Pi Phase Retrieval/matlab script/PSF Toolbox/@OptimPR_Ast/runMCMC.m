function [x_next,dLL]=runMCMC(obj)
% runMCMC - generate optimized parameters for phase retrieval using Monte
% Carlo Markov Chain. 
%   It only accept the step gives better result.
%
%   see also objectivefun
R1=obj.PRobj.SubroiSize;
nImm=obj.PRobj.PRstruct.RefractiveIndex;
iterK=obj.PRobj.IterationNumK;
otfsigmax=obj.PRobj.PRstruct.SigmaX;
otfsigmay=obj.PRobj.PRstruct.SigmaY;

x0=[R1,iterK,nImm,otfsigmax,otfsigmay];
x_next=x0;
sigma=[5,1.5,0.005,0.5,0.5];%[5,1.5,0.005,0.5,0.5]
sigma_LL=sqrt(3e3);% sigma for acceptance distribution
param_dis=[];
param=[];
param_pdf=[];
dsse=[];
dLL=[];
[dsse_next,dLL_next]=obj.objectivefun(x_next);
dsse=cat(1,dsse,dsse_next);
dLL=cat(1,dLL,dLL_next);
P_next=acceptpdf(dLL_next,sigma_LL);
count=0;
for ii=1:obj.IterationMonte
    mu = x_next;
    kai=randn(size(sigma));
    xIncrem=kai.*sigma;
    xIncrem([1,2])=round(xIncrem([1,2]));
    x_guess = mu + xIncrem;
    if x_guess(2)<0
        x_guess(2)=0;
    end
    if x_guess(1)<=31
        x_guess(1)=31;
    end
    tic
    [dsse_guess,dLL_guess]=obj.objectivefun(x_guess);
    P_guess=acceptpdf(dLL_guess,sigma_LL);
    a=exp(log(P_guess/P_next));
    %a=min([1,exp(log(P_guess/P_next))]);
    if  a>1 %a>rand(1)
        x_next=x_guess;
        param_dis=cat(1,param_dis,a);
        param_pdf=cat(1,param_pdf,P_guess);
        param=cat(1,param,x_next);   
        P_next=P_guess;
        dsse=cat(1,dsse,dsse_guess);
        dLL=cat(1,dLL,dLL_guess);
        count=0;
    else
        count=count+1;
    end
    if count>20
        sigma=[2,1,0.005,0.2,0.2];
    end
end

end
function [prob]=acceptpdf(data,sigma)
prob=exp(-1/(2*sigma^2)*double(data));
end