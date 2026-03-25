%main v4
%Code by Jose Mora @ UMass
%This one allows reading multiple section files
close all
clear
clc

%JJM: Very important to check these scripts and set your paths correctly!
addNumadPaths
addFrame3DDPath %jjm: This one is self made

%%%%%%%%%%%%%%%%%% Brief Description on input system %%%%%%%%%%%%%%%%%%%%
%JJM:
%The following lines are for reading the inputs for NuMADs blade object.
%The idea here is to prove the input file can come as a different thing
%than an excel, which is sort of NuMADs predilect (?) form. Recently,
%there has been a push to make input files in a common format (wind.io).
%We could definitely use that as input here, required some coding to get
%the information as a blade object
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get the current working directory (current folder)
currentFolder = pwd;
% Get the parent folder (folder above the current folder)
parentFolder = fileparts(currentFolder);

%read inputs
% Open the text file for reading
fid = fopen([parentFolder,'\Inputs\Driver.txt'], 'r');
tsr = fscanf(fid, '%f', 1);fgetl(fid); % Read the tip speed ratio (tsr)
fgetl(fid);
airfoils = textscan(fid, '%f %s', 'HeaderLines', 1);
fclose(fid);
col1=cell2mat(airfoils(:,1));
col2=cellfun(@string, airfoils(:,2), 'UniformOutput', false);
col2 = [col2{:}];
airfoils = table(col1,col2,'VariableNames',{'airfoil no','name'});

% Open the text file for reading
fid = fopen([parentFolder,'\Inputs\BladeSectionsv5.dat'], 'r');%CHECK!
%assign parameters and read comments/discard them
for i=1:4
    fgetl(fid);
end
inputs = textscan(fid, '%f %f %f %f %f %f %f', 'HeaderLines', 2);
fclose(fid); % Close the file
inputs = array2table(cell2mat(inputs),'VariableNames',{'span (r) [m]','not used1','not used2','not used3','twist','chord','airfoil no'});

%%%%%%%%%%%%%%%% bladeBuilderBEMv2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% JJM:
% This is a script I made to convert all these inputs into a blade
% object. As you can see in the input for this function, there is
% a link to an excel sheet. There, is the 100m snl blade material
% properties and section layouts for different span locations 
% (given as relative span, from 0 to 1). I'm taking these only because I've
% not made a similar file for the 15MW yet. We might want to know if we
% want to present inputs on a certain way before making any time
% investments on a certain format.

topSecProps=struct;
ispans=struct;
Dstory=struct;
cases=[10 20 50 100 200];%beam elements can't be smaller than 1m
for count=2
numel=cases(count);
[blade]=bladeBuilderBEMv2_01(inputs,parentFolder,airfoils,[parentFolder,'\Inputs\15MW.xlsx'],numel);
%[blade]=bladeBuilderBEMv2(inputs,parentFolder,airfoils,'C:\Users\josej\Downloads\NuMAD-3.0\examples\ExcelToObject\Excel2ObjectExample.xlsx');


%%%%% JJM:Profiles Check
% JJM: Tiny section to ensure the profiles look reasonable
%figure()
%for i=1:length(blade.stations)
%    plot(blade.stations(i).airfoil.coordinates(:,1),blade.stations(i).airfoil.coordinates(:,2))
%    hold on
%end
    
%JJM: Important method execution. This will interpolate all blade
%properties and geometric information
blade.updateBlade
%BladeDef_to_NuMADfile(blade,'numad.nmd','MatDBsi.txt')
    
%%%%%Profiles Check
% JJM: Same thing, just to check if NuMAD interpolated properly. I've seen it
% stumble in interpolating error, particularly when the same airfoil shape
% is given in two adjacent spans (say 0.77 and 1). When interpolating for
% values betweeen these, it self crosses sometimes which is a critical
% error

%figure()
%for i=1:length(blade.ispan)
%    plot(blade.profiles(:,1,i)*blade.ichord(i),blade.profiles(:,2,i)*blade.ichord(i))
%    hold on
%end

%%%%%JJM: Remember NuMAD treats the blade starting at zero. Yet, the hub is
%there too and we can't leave it out on bem calcs
hubRad=4.118878;
R = double(inputs{end,1})+hubRad;

%%%%%%%%%%%%%%%%% Blade Performance - BEM %%%%%%%%%%%%%%%%%%%%%%
% JJM: AFTER the blade has been defined in NuMAD, it is time to perform the
% BEM Calculations. Here, NREL (or anyone else) would use CCBlade by Ning.
% Many of the minute details of that algorithm are missing here, however,
% the same method was programmed (only for positive relative wind angle
% values). This means no propeller region solution in this code which might
% make it less suitable for optimization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wndspeed=10.65;
fprintf('\n')
fprintf('BEM Solver\n')

% JJM: I want to put xfoil into this script to be able to do cl and cd
% estimations for each of the interpolated profiles, thus, getting better
% (and healthier, less prone to error) data for performance calculations.
% This would be properly exploiting the benefit of using NuMAD as a
% preprocessor. I'm almost positive the new NuMAD has a method to obtain
% polars but I'm not sure about that yet

for j=1:height(inputs) %JJM: Here I would do length(blade.ispan)
    r = double(inputs{j,"span (r) [m]"}); %JJM: Here blade.ispan(j) instead
    twist = double(inputs{j,"twist"})*pi/180; %JJM: idem
    chord= double(inputs{j,"chord"}); %JJM: idem
    %JJM: coords = blade.profiles(:,:,j); This would be the way if I get the
    %xfoil routine working properly
    airfoilno = double(inputs{j,"airfoil no"});
    % JJM: Open the text file for reading
    fid = fopen([parentFolder,'\Airfoils\',convertStringsToChars(airfoils{airfoilno,"name"}),'.dat'], 'r');
    for i=1:52
        fgetl(fid);
    end
    data = textscan(fid, '%f %f %f %f', 'HeaderLines', 2);
    fclose(fid); % Close the file
    table = array2table(cell2mat(data),'VariableNames',{'alpha rad','c_l','c_d','c_m'});

    %excecute bem solver
    % JJM: Maybe make it a function instead of a script?
    fprintf('\n')
    fprintf('Section %i at span %4.2f\n',j,r)
    bem_solver_v2_01; %Here I would have bem_solver_v3_00 instead
    Chord(j)=chord;
    Twist(j)=twist;
    span(j)=r;
    aind(j)=a;
    apind(j)=ap;
    aoas(j)=aoa;
    Fs(j)=F;
    cls(j)=cl;
    cds(j)=cd;
    nondimcl(j)=chord*cl/r;
    cpi(j)=cp;
    relwnds(j)=relWind;
end

%JJM: FIX THIS!!!!! use weighted interpolation to avoid NaN values at end 
% and start. JJM v2: I dont think we need to do this still, better check.
aind(end)=0.32;
apind(end)=0.0045;

%JJM: all sections done, we check
%Its necessary to get the performance variables in the midpoints of each
%blade element
for i=1:(height(inputs)-1) %If we get the xfoil working (length(blade.ispan)-1)
    amids(i)=(aind(i)+aind(i+1))/2;
    apmids(i)=(apind(i)+apind(i+1))/2;
    rmids(i)=(span(i)+span(i+1))/2;
    rsize(i)=span(i+1)-span(i);
    Fmids(i)=(Fs(i+1)+Fs(i))/2;
    clsmid(i)=(cls(i+1)+cls(i))/2;
    cdsmid(i)=(cds(i+1)+cds(i))/2;
    chordmid(i)=(Chord(i+1)+Chord(i))/2;
    relwndsmid(i)=(relwnds(i+1)+relwnds(i))/2;
end
rotspeed=ltsr*wndspeed/R;

%JJM: This is where im getting an issue!! 
%Why are the equations not giving the same values? Did I do something
%wrong? AD. equations seem more reasonable so I use those in the rest of
%the code

    %Actuator disk
    dT=Fmids.*1.225*(wndspeed^2)*4.*amids.*(1-amids)*pi.*rmids.*rsize;
    dQ=Fmids.*4.*apmids.*(1-amids).*1.225*wndspeed*rotspeed*pi().*(rmids.^3).*rsize;
    
    %Blade element momentum
    dFn=(3/2)*1.225*(wndspeed^2).*(clsmid.*cos(relwndsmid)+cdsmid.*sin(relwndsmid)).*chordmid.*rsize;
    dQp=Fmids.*(3/2)*1.225*(wndspeed^2).*((clsmid).*sin(relwndsmid)-(cdsmid).*cos(relwndsmid)).*chordmid.*rmids.*rsize;

cpmids=4*amids.*((1-amids).^2);

%JJM: Corrections due to section 1 span=0 non convergence towards real
%value. FIX

dT(1)=0;
dQ(1)=0;
%power=cpmids.*1.225*(wndspeed^3)*pi().*(rannu.^2);
dpower=dQ*rotspeed;

totalpwr=sum(dpower(2:end))*0.93; %JJM: Is this correct? I'm assuming some generator efficiency;
% also with more discretization dpower will converge to a more accurate value

%%%%%%%%%%%%%%
%This script engages precomp and bmodes. I did some modding here!
blade.generateBeamModel
%%%%%%%%%%%%%%
topSecProps(count).secprops=blade.secprops.data;
ispans(count).ispan=blade.ispan;

%JJM: Here we do the beam calculations using frame 3dd. The next lines of code
%upon the frame3dd call are getting the inputs ready. There are some errors
%in the documentation so always do a sanity check by executing frame 3dd
%with the input file generated by the frame3dd.m script. To do this,
%excecute from the command window (you'll probably need to add a frame3dd
%as a path variable (see documentation).

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

%get areas of section
for i=1:(length(blade.ispan)-1)
    midareas(i)=(blade.areas(i)+blade.areas(i+1))/2;
    ixy(i)=(blade.inertias.inertias(3,i)+blade.inertias.inertias(3,i+1))/2;
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


EAIJ=[midareas;midareas;midareas;...
    (blade.secprops.data(1:(end-1),19)+blade.secprops.data(1:(end-1),20))';blade.secprops.data(1:(end-1),19)';blade.secprops.data(1:(end-1),20)';...
    youngm;shearm;...
    zeros(1,length(blade.ispan)-1);density];

%Lets use distro loads.
%JJM: All elastic properties are referenced to R axis (see precomp),
%can we say R axis is at aerodynamic center? It is located at the chord
%line, but is it at a quarter chord (or whatever the aero center is at per
%airfoil?) in any case, R is oriented theta_pitch to the horizontal axis
%and forces are theta_relwnd which is theta_pitch+alfa. Thus, we solve for
%for forces in theta pitch, project them alfa.

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
cntrThr=interp1(dT,rmids,mean(dT));%center of thrust

i=1;
larger=false;
while larger==false
    if blade.ispan(i)<cntrThr
        i=i+1;
    else
        larger=true;
    end
end
P(3,i)=sum(dT);
%U=[zeros(1,length(blade.ispan)-1);idTmids;zeros(1,length(blade.ispan)-1)];%not super robust

D=zeros(6,length(blade.ispan));
[D,R,F,L,Ks] = frame_3dd(XYZ,ELT,RCT,EAIJ,P,U,D);

Dstory(count).D=D;
end
%plots
%These are made with data from input sections, thus really coarse
figure();
plot(table2array(inputs(:,1)),aoas*180/pi());
title('angles of attack')
figure();
plot(table2array(inputs(:,1)),aind);
title('axial inductions')
figure();
plot(table2array(inputs(:,1)),apind);
title('tangential inductions')
figure();
plot(table2array(inputs(:,1)),Fs);
title('Tip Loss')
figure();
plot(table2array(inputs(:,1)),nondimcl);
title('non dimensional cl')
figure();
plot(blade.ispan,idT);
title('Thrust')

%these come from numad model
figure();
plot(blade.ispan,blade.matprops.modulus(1,:));%shear its a bit iffy at the root
title('Material Properties')
figure();
plot(blade.ispan,blade.matprops.modulus(3,:));
title('Density')
xlabel('span [m]')
ylabel('density [kg/m3]')
figure();
plot(blade.ispan,blade.inertias.inertias);
title('Inertia')
xlabel('span [m]')
ylabel('inertia [m4]')
figure();
%plot(blade.ispan,Dtotal);
for count=2
    plot(ispans(count).ispan,Dstory(count).D(3,:));
    hold on
end
title('Displacements')
xlabel('span [m]')
ylabel('displacements flap [m]')
legend('10 element','20 element','50 element','100 element','Location','southwest')