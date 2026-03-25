%BEM Solver v2
%Made by JMora
%precalc

function [a,ap,cp,ct,cm,F,cl,cd,relWind,aoa,r,R,ltsr]=bem_solver_v3_01(B,designTSR,chord,r,R,hubRad,twist,table1)

    ltsr=designTSR*r/R;
    solp=B*chord/(2*pi()*r);
        
    [fpi2,~,~,~,~,~,~,~]=f(pi/2,twist,table1,solp,ltsr,r,R);

    %bisection method bounds
    hBound=pi/2;
    epsilon=0.00001;
    lBound=epsilon;
    
    i=0;stop=false;
    
    while and(abs(hBound-lBound)>epsilon,stop==false)
        i=i+1;
        relWind=(lBound+hBound)/2;
        relWindvct(i)=relWind;
        
        [flb,~,~,~,~,~,~,~]=f(lBound,twist,table1,solp,ltsr,r,R);
        [fphi,aoa,cl,cd,a,kappa,kappap,F]=f(relWind,twist,table1,solp,ltsr,r,R);
            
        fphivect(i)=fphi;
        fphilb(i)=flb;
        
        if sign(fphi)==sign(flb)
            lBound=relWind;
        else
            hBound=relWind;
        end
    
        if i>20
            stop=true;
        end
    end
    ap=kappap/(1-kappap);
    cp=4*a*((1-a)^2);
    ct=4*a*(1-a);
    cm=(8/3)*a*(1-a);
    if i<20
        fprintf('section coverged\n')
        fprintf('fphi   aoa[deg]   cl   cd   a   kappa   kappap   F   count\n')
        fprintf('%4.4f %4.4f %4.4f %4.4f %4.4f %4.4f %4.4f %4.4f %i\n',fphi,aoa,cl,cd,a,kappa,kappap,F,i)
    else
        fprintf('section NOT coverged\n')
    end
end

%zero function
function [fval,aoa,cl,cd,a,kappa,kappap,F]=f(angle,twist,table,solp,ltsr,r,R)
    %inputs dependent on relative wind
    aoa=angle-twist;
    cl=interp1(table.("alpha rad"),table.c_l,aoa);
    cd=interp1(table.("alpha rad"),table.c_d,aoa);
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