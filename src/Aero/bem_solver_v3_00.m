%BEM Solver v3
%Made by JMora
%precalc
B=3;
ltsr=9*r/R;
solp=B*chord/(2*pi()*r);

[fpi2,~,~,~,~,~,~,~]=f(pi/2,twist,coords,solp,ltsr,r,R);
%bisection method bounds
hBound=pi/2;
epsilon=0.001;
lBound=epsilon;
    
for i=1:20
    relWind=(lBound+hBound)/2;
    relWindvct(i)=relWind;
    
    [flb,~,~,~,~,~,~,Flb]=f(lBound,twist,coords,solp,ltsr,r,R);
    [fphi,aoa,cl,cd,a,kappa,kappap,F]=f(relWind,twist,coords,solp,ltsr,r,R);
        
    fphivect(i)=fphi;
    fphilb(i)=flb;
    
    if sign(fphi)==sign(flb)
        lBound=relWind;
    else
        hBound=relWind;
    end
end
ap=kappap/(1-kappap);
cp=4*a*((1-a)^2);

function [fval,aoa,cl,cd,a,kappa,kappap,F]=f(angle,twist,coords,solp,ltsr,r,R)
    %inputs dependent on relative wind
    aoa=angle-twist;
    cl=0.01;
    cd=0.35;
    %if r>R/2
        [pol,~]=xfoil(coords,aoa*180/pi(),14000000,0.2,'oper/iter 25'); %varargin
        %if pol == 'not converged'
        %    cl=0.01;
        %    cd=0.35;
        %else
        %    cl=4;
        %end
    %end
    %cl=interp1(table.("alpha rad"),table.c_l,aoa);
    %cd=interp1(table.("alpha rad"),table.c_d,aoa);
    
    F=(2/pi)*acos(exp(-(2.5*(1-r/R))/(r*sin(angle)/R)));
    
    %force coefficients
    cn=cl*cos(angle)+cd*sin(angle);
    ct=cl*sin(angle)-cd*cos(angle);
    
    kappa=solp*cn/(4*F*(sin(angle)^2));
    kappap=solp*ct/(4*F*sin(angle)*cos(angle));
    
    %zero function
    a=kappa/(1+kappa);
    if kappa>(2/3)
        gamma1=2*F*kappa-(10/9-F);
        gamma2=2*F*kappa-F*(4/3-F);
        gamma3=2*F*kappa-(25/9-2*F);
        a=(gamma1-sqrt(gamma2))/gamma3;
    end

    fval=sin(angle)/((1-a))-cos(angle)*(1-kappap)/ltsr;
end