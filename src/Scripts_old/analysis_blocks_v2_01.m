function [relwnds,aind,apind,amids,apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
    ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,moment,blade,D,R,F,L,Ks]...
    =analysis_blocks_v2_01...
    (inputs,hubRad,parentFolder,airfoils,numel)
    
    [blade]=bladeBuilderBEMv2_02(inputs,parentFolder,airfoils,[parentFolder,'\Inputs\15MW_v2.xlsx'],numel);
    blade.updateBlade
    R = double(inputs{end,1})+hubRad;
    wndspeed=10.65;
    fprintf('\n')
    fprintf('BEM Solver\n')

    for j=1:length(blade.ispan) %JJM: Here I would do length(blade.ispan)
        r = blade.ispan(j)+hubRad; %JJM: Here blade.ispan(j) instead
        twist = blade.idegreestwist(j)*pi/180; %JJM: idem
        chord = blade.ichord(j); %JJM: idem
        %find where this r lies
        %bigger=false;
        k=1;
        if (r-hubRad)==blade.span(end)
        airfoilno = double(inputs{end,"airfoil no"});
        else
            while (r-hubRad)>=blade.span(k)
                k=k+1;
                airfoilno = double(inputs{k-1,"airfoil no"});
            end
        end
        %JJM: coords = blade.profiles(:,:,j); This would be the way if I get the
        %xfoil routine working properly
        %airfoilno = double(inputs{k-1,"airfoil no"});
        % JJM: Open the text file for reading
        fid = fopen([parentFolder,'\Airfoils\',convertStringsToChars(airfoils{airfoilno,"name"}),'.dat'], 'r');
        for i=1:52
            fgetl(fid);
        end
        data = textscan(fid, '%f %f %f %f', 'HeaderLines', 2);
        fclose(fid); % Close the file
        table1 = array2table(cell2mat(data),'VariableNames',{'alpha rad','c_l','c_d','c_m'});
    
        %excecute bem solver
        % JJM: Maybe make it a function instead of a script?
        fprintf('\n')
        fprintf('Section %i at span %4.2f\n',j,r)
        
        [a,ap,cp,ct,cm,F,cl,cd,relWind,aoa,r,R,ltsr]=bem_solver_v3_01(3,9,chord,r,R,hubRad,twist,table1); %Here I would have bem_solver_v3_00 instead. solved
        
        chordVector(j)=chord;
        twistVector(j)=twist;
        span(j)=r;
        aind(j)=a;
        apind(j)=ap;
        aoas(j)=aoa;
        Fs(j)=F;
        cls(j)=cl;
        cds(j)=cd;
        nondimcl(j)=chord*cl/r;
        cpvector(j)=cp;
        ctvector(j)=ct;
        cmvector(j)=cm;
        relwnds(j)=relWind;
        %ltsrvect(j)=ltsr
    end
    
    [amids,apmids,cpmids,ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,moment,rsize,rmids]=AD_performance(chordVector,relwnds,aind,apind,aoas,Fs,cls,cds,cpvector,wndspeed,ltsr,R,span);

    blade.generateBeamModel
    
    %topSecProps(count).secprops=blade.secprops.data;
    %ispans(count).ispan=blade.ispan;
    
    XYZ=zeros(4,length(blade.span));
    for j=1:(length(blade.ispan))
        XYZ(1,j)=blade.ispan(j);
        XYZ(4,j)=0.00;
    end
    
    for j=1:(length(blade.ispan)-1)
        ELT(:,j)=[j,j+1];
    end
    
    RCT=zeros(6,length(blade.ispan));
    RCT(:,1)=[1,1,1,1,1,1];
    
    ixy = (blade.secprops.data(1:(end-1),19)+blade.secprops.data(1:(end-1),20))';
    ixx = blade.secprops.data(1:(end-1),19)';
    iyy = blade.secprops.data(1:(end-1),20)';

    %get areas of section
    for i=1:(length(blade.ispan)-1)
        midareas(i)=(blade.areas(i)+blade.areas(i+1))/2;
        iuu(i)=(ixx+iyy)/2+((ixx-iyy)/2)*cos(relwnds)
        iyy(i)=(blade.inertias.inertias(2,i)+blade.inertias.inertias(2,i+1))/2;
        ixx(i)=(blade.inertias.inertias(1,i)+blade.inertias.inertias(1,i+1))/2;
        %youngm(i)=(blade.matprops.modulus(1,i)+blade.matprops.modulus(1,i+1))/2;
        youngm(i)=(blade.secprops.data(i,4)/blade.secprops.data(i,19)+blade.secprops.data(i+1,4)/blade.secprops.data(i+1,19))/2; %im testing the code with the EI extracted from precomp. Remember I is at G and not E so it must be converted
        shearm(i)=(blade.matprops.modulus(2,i)+blade.matprops.modulus(2,i+1))/2;
        density(i)=(blade.matprops.modulus(3,i)+blade.matprops.modulus(3,i+1))/2;
    end
    
    %JJM: Ignore, I was trying different things
    %EAIJ=[blade.areas',blade.areas',blade.areas',...
    %    blade.inertias.inertias(3,:)',blade.inertias.inertias(2,:)',blade.inertias.inertias(1,:)',...
    %    blade.matprops.modulus(1,:)',blade.matprops.modulus(2,:)',...
    %    zeros(1,length(blade.ispan)-1)',blade.matprops.modulus(3,:)'];
    
    %EAIJ=[midareas;midareas;midareas;...
    %    ixy;iyy;ixx;...
    %    youngm;shearm;...
    %    zeros(1,length(blade.ispan)-1);density];
    
    %Project inertia in right place
    %ixx=
    EAIJ=[midareas;midareas;midareas;...
        (blade.secprops.data(1:(end-1),19)+blade.secprops.data(1:(end-1),20))';...
        blade.secprops.data(1:(end-1),19)';blade.secprops.data(1:(end-1),20)';...
        youngm;shearm;...
        zeros(1,length(blade.ispan)-1);density];
    
    P=zeros(6,length(blade.ispan));
    
    %Distr loads interpolation
    distrdT=dT./rsize;
    idT=interp1(rmids,distrdT,blade.ispan,'linear','extrap');
    %at the midpoints
    for i=1:(length(blade.ispan)-1)
        idTmids(i)=(idT(i)+idT(i+1))/2;
    end
    %JJM: reaaally checkkkkk
    %Remember that dT is on a different axis, so it must be projected as per
    %the pitch angle. Im not doing this right now, shouldn't be way off
    
    U=zeros(3,length(blade.ispan)-1);


    %for i=1:length(dT)
        cntrThr=sum((dT.*rmids)/sum(dT));%center of thrust
    %end

    i=1;
    larger=false;
    while larger==false
        if blade.ispan(i)<cntrThr
            i=i+1;
        else
            larger=true;
        end
    end
    %P(3,i)=sum(dT);
    U=[zeros(1,length(blade.ispan)-1);idTmids;zeros(1,length(blade.ispan)-1)];%not super robust
    
    D=zeros(6,length(blade.ispan));
    [D,R,F,L,Ks] = frame_3dd(XYZ,ELT,RCT,EAIJ,P,U,D);
    
end