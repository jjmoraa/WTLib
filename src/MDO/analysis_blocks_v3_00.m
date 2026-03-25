function [relwnds,aind,apind,amids,apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
    ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,mass,moment,blade,D,R,F,L,Ks,COE,AEP]...
    =analysis_blocks_v3_00...
    (caseName,inputs,hubRad,parentFolder,airfoils,numel)

    cutout=25;
    
    [blade]=bladeBuilderBEMv2_03(inputs,parentFolder,airfoils,[parentFolder,'\Inputs\15MW_v2.xlsx'],numel);
        blade.updateBlade
        R = double(inputs{end,1})+hubRad;
        fprintf('\n')
        fprintf('BEM Solver\n')

    wndspeed_range=0.1:0.1:cutout;
        
    for index=1:length(wndspeed_range)
        wndspeed=wndspeed_range(index);
        for j=1:length(blade.ispan) 
            r = blade.ispan(j)+hubRad; 
            twist = blade.idegreestwist(j)*pi/180; 
            chord = blade.ichord(j); 
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
            % JJM: Open the text file for reading
            filename=sprintf('%s\\Airfoils\\IEA-15-240-RWT_AeroDyn15_Polar_%02d.dat', ...
                     parentFolder,airfoilno-1);
            fid = fopen(filename, 'r');
            for i=1:52
                fgetl(fid);
            end
            data = textscan(fid, '%f %f %f %f', 'HeaderLines', 2);
            fclose(fid); % Close the file
            table1 = array2table(cell2mat(data),'VariableNames',{'alpha rad','c_l','c_d','c_m'});
            if max(table1.("alpha rad"))>pi()
                table1.("alpha rad")=table1.("alpha rad")*pi()/180;
            end
            %excecute bem solver
            % JJM: Maybe make it a function instead of a script?
            fprintf('\n')
            fprintf('Section %i at span %4.2f\n',j,r)
            [a,ap,cp,ct,cm,F,cl,cd,relWind,aoa,r,R,ltsr]=bem_solver_v3_01(3,9,chord,r,R,hubRad,twist,table1); %Here I would have bem_solver_v3_00 instead. solved
            
            %pack data to run the AD equations
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
            ltsrvect(j)=ltsr;
        end
        
        
        [amids,apmids,cpmids,ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,moment,rsize,rmids]=AD_performance(chordVector,relwnds,aind,apind,aoas,Fs,cls,cds,cpvector,wndspeed,ltsrvect,R,span);
        %quick patch: fix for article
        if wndspeed>=10.65
            % amids_r=amids;
            % apmids_r=apmids;
            % cpmids_r=cpmids;
            % ctmids_r=ctmids;
            % cmmids_r=cmmids;
            % ocp_r=ocp;
            % oct_r=oct;
            % ocm_r=ocm;
            % dT_r=dT;
            % dQ_r=dQ;
            % totalpwr_r=totalpwr;
            % moment_r=moment;
            % rsize_r=rsize;
            % rmids_r=rmids;
            break
        end
        powercurve(index)=totalpwr;
    end
    rated_speed_index=index;
    rated_speed=wndspeed_range(rated_speed_index);
    powercurve(index)=totalpwr;
    powercurve=[powercurve,repmat(totalpwr,1,length(wndspeed_range)-index)];
    % set you cut in power
    cut_in_pwr=100000;
    powercurve(powercurve<=cut_in_pwr)=0;
    
    %Site wind distribution (Using Weibull) well, actually rayleigh since
    %k=2;
    k=2;
    mean_wind_speed=9;
    c=mean_wind_speed/((0.568+0.433/k)^(1/k));
    
    P_w=0;
    for i=2:rated_speed_index
        P_w=P_w+((powercurve(i-1)+powercurve(i))/2)*(exp(-(wndspeed_range(i-1)/c)^k)-exp(-(wndspeed_range(i)/c)^k));
    end
    P_w=P_w+totalpwr*(exp(-(rated_speed/c)^k)-exp(-(cutout/c)^k));
    AEP=P_w*8760;
    AEP=AEP/1000;
    
    %here we can calculate cost
    materials_table=read_material_costs("C:\Users\josej\Documents\MATLAB BEM Solver\Inputs\MaterialCostDatabase.txt");
    components=[blade.bom.hp;blade.bom.lp;blade.bom.sw{1};blade.bom.sw{2}];
    material_cost=componentCostCalculator(components,materials_table);
    adhesive_cost=(blade.bom.lebond+blade.bom.tebond+sum(blade.bom.swbonds{1})+sum(blade.bom.swbonds{2}))*table2array(materials_table(11,3))/1000;
    direct_costs=material_cost+adhesive_cost;
    blades_cost=3*direct_costs/0.66;%from a detailed cost model by bortolotti
    rotor_cost=blades_cost/0.75;
    capital_cost=rotor_cost/0.171; %from CAPEX for land based wind turbine 2022 cost of wind energy review
    %Fixed COE metrics
    FCR=0.09; %Check this value
    C_om=50*totalpwr/1000;%per kW
    COE=(capital_cost*FCR+C_om)/AEP;% units are $/KW

    
        

    
    blade.generateBeamModel
    mass=sum(blade.secprops.data(1:(end-1),18)*(blade.ispan(2)-blade.ispan(1)));
    mu_values=[0.001 0.001 0.001 0.001 0.001 0.001];
    output_filename=caseName;
    generate_beamdyn_input(blade, mu_values, output_filename, dT)
    %topSecProps(count).secprops=blade.secprops.data;
    %ispans(count).ispan=blade.ispan;
    
    [status, cmdout] = run_beamdyn(output_filename);
    
    D=zeros(6,length(blade.ispan));
    Ks=zeros(6,length(blade.ispan));
    L=zeros(6,length(blade.ispan));
    F=zeros(6,length(blade.ispan));
    R=zeros(6,length(blade.ispan));
    if contains(cmdout, 'BD_Static:Solution does not converge')
        disp('BeamDyn static solution failed to converge.');
    else
        beamDynOutput = read_BeamDyn_out(output_filename);
        xDeflection = beamDynOutput(:, startsWith(beamDynOutput.Properties.VariableNames, 'N') & endsWith(beamDynOutput.Properties.VariableNames, '_TDxr'));
        yDeflection = beamDynOutput(:, startsWith(beamDynOutput.Properties.VariableNames, 'N') & endsWith(beamDynOutput.Properties.VariableNames, '_TDyr'));
        D(1,:)=table2array(xDeflection(end,:));
        D(2,:)=table2array(yDeflection(end,:));
    end

    %move al files to results folder
    movefile('*.inp', [parentFolder,'\Results\root_moment\']);
    movefile('*.out', [parentFolder,'\Results\root_moment\']);
    movefile('*.ech', [parentFolder,'\Results\root_moment\']);
    movefile('*.yaml', [parentFolder,'\Results\root_moment\']);

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
    
    
    %ixy = (blade.secprops.data(1:(end-1),19)+blade.secprops.data(1:(end-1),20))';
    ixx = blade.secprops.data(1:(end-1),19)';
    iyy = blade.secprops.data(1:(end-1),20)';
    ixy = zeros(size(ixx));

    iuu=(ixx+iyy)/2+((ixx-iyy)/2).*cos(2*relwnds(2:end))-ixy.*sin(2*relwnds(2:end));
    ivv=(ixx+iyy)/2-((ixx-iyy)/2).*cos(2*relwnds(2:end))+ixy.*sin(2*relwnds(2:end));
    iuv=((iyy-ixx)/2).*sin(2*relwnds(2:end)).*cos(2*relwnds(2:end))+ixy.*cos(2*relwnds(2:end));
    %get areas of section
    for i=1:(length(blade.ispan)-1)
        midareas(i)=(blade.areas(i)+blade.areas(i+1))/2;
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
        iuv;...
        iuu;ivv;...
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
    
    %[D,R,F,L,Ks] = frame_3dd(XYZ,ELT,RCT,EAIJ,P,U,D);
    
end