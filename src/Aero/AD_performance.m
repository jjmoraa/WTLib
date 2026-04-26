function [amids,apmids,cpmids,ctmids,cmmids,aeq,ocp,oct,ocm,dT,dQ,totalpwr,oopmoment,rsize,rmids]=AD_performance(chordVector,relwnds,aind,apind,aoas,Fs,cls,cds,cpvector,wndspeed,ltsr,R,span)

%ask this to lackner
aind(end)=0;
%aind(end)=aind(end-1);
apind(end)=0;
%apind(end)=apind(end-1);
%Fs(end)=1;
rotspeed=ltsr(end).*wndspeed/R;
%So, due to the "flawed" evaluation of the final section of the blade, I'm
%going to assume temporaly no tip losses on this forced condiiton
for i=1:(length(chordVector)-1) %If we get the xfoil working (length(blade.ispan)-1)
    amids(i)=(aind(i)+aind(i+1))/2;
    apmids(i)=(apind(i)+apind(i+1))/2;
    rmids(i)=(span(i)+span(i+1))/2;
    rsize(i)=span(i+1)-span(i);
    Fmids(i)=(Fs(i+1)+Fs(i))/2;
    clsmid(i)=(cls(i+1)+cls(i))/2;
    cdsmid(i)=(cds(i+1)+cds(i))/2;
    chordmid(i)=(chordVector(i+1)+chordVector(i))/2;
    relwndsmid(i)=(relwnds(i+1)+relwnds(i))/2;
    ltsrmids(i)=(ltsr(i+1)+ltsr(i))/2;
end

%Actuator disk
    dT=Fmids.*1.225*(wndspeed^2)*4.*amids.*(1-amids)*pi.*rmids.*rsize;
    dQ=Fmids.*4.*apmids.*(1-amids).*1.225*wndspeed.*rotspeed*pi().*(rmids.^3).*rsize;
    
%Blade element momentum %%%%%%%its urel!!!!!! fixxxx
    % dFn=(3/2)*1.225*(wndspeed^2).*(clsmid.*cos(relwndsmid)+cdsmid.*sin(relwndsmid)).*chordmid.*rsize;
    % dQp=Fmids.*(3/2)*1.225*(wndspeed^2).*((clsmid).*sin(relwndsmid)-(cdsmid).*cos(relwndsmid)).*chordmid.*rmids.*rsize;

cpmids=4*amids.*((1-amids).^2);
ctmids=4*amids.*(1-amids);
cmmids=(8/3)*amids.*(1-amids);

localwind=sqrt(wndspeed^2+(ltsrmids).^2);

%
% VERY IMPORANT NOTICE
% dQ is the "in plane bending moment". Thats why we can use it to calculate
% power. That will allow obtaining c_q. It is NOT related to c_m which is
% the out of plane bending moment which is much more related to thrust

% check this procedure
% normwind=localwind./wndspeed;
% annulusAreas=pi()*((rmids+rsize/2).^2-(rmids-rsize/2).^2);
% ocp=sum(cpmids.*annulusAreas.*(normwind.^3))/(pi()*R^2);
% oct=sum(ctmids.*annulusAreas.*(normwind.^3))/(pi()*R^2);
% ocm=sum(cmmids.*annulusAreas.*(normwind.^3))/(pi()*R^2);
%dpower=cpmids

% moment=0.5*1.225*(wndspeed^2)*pi()*(R^3)*ocm;
dpower=dQ.*rotspeed; %CHECK THIS METHOD!!
%totalpwr=sum(dpower(2:end))*0.96; %JJM: Is this correct? I'm assuming some generator efficiency;

totalpwr=sum(dpower(2:end));
thrust=sum(dT(2:end));

%Distr loads interpolation
    %for i=1:length(dT)
        cntrThr=sum((dT.*rmids)/sum(dT));%center of thrust
    %end

oopmoment=cntrThr*thrust;
%moment=sum(dQ(2:end));

ocp=totalpwr/((1/2)*1.225*pi()*(R^2)*(wndspeed^3));
oct=thrust/((1/2)*1.225*pi()*(R^2)*(wndspeed^2));
ocm=oopmoment/((1/2)*1.225*pi()*(R^3)*(wndspeed^2));

% recover global axial induction
aeq = 1/2 * (1 - sqrt(1 - oct));
% also with more discretization dpower will converge to a more accurate value
