%main v3
%This one allows reading multiple section files
close all
clear
clc

addNumadPaths

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
fid = fopen([parentFolder,'\Inputs\BladeSectionsv3.dat'], 'r');
%assign parameters and read comments/discard them
for i=1:4
    fgetl(fid);
end
inputs = textscan(fid, '%f %f %f %f %f %f %f', 'HeaderLines', 2);
fclose(fid); % Close the file
inputs = array2table(cell2mat(inputs),'VariableNames',{'span (r) [m]','not used1','not used2','not used3','twist','chord','airfoil no'});

%%%%%%%
%%%%%%%
%%blade builder

[blade]=bladeBuilderBEM(inputs,parentFolder,airfoils,'C:\Users\josej\Downloads\NuMAD-3.0\examples\ExcelToObject\Excel2ObjectExample.xlsx');
%%%%%Profiles Check
figure()
for i=1:length(blade.stations)
    plot(blade.stations(i).airfoil.coordinates(:,1),blade.stations(i).airfoil.coordinates(:,2))
    hold on
end
    
blade.updateBlade
%BladeDef_to_NuMADfile(blade,'numad.nmd','MatDBsi.txt')
    
%%%%%Profiles Check
figure()
for i=1:length(blade.ispan)
    plot(blade.profiles(:,1,i),blade.profiles(:,2,i))
    hold on
end
blade.generateBeamModel
    %%%%%%%%%%
    %%%%%%%%
    %%%%%%%%%%

    
R = double(inputs{end,1});
%now we do bem calcs for each section
wndspeed=10.65;
for j=1:height(inputs)
    r = double(inputs{j,"span (r) [m]"});
    twist = double(inputs{j,"twist"})*pi/180;
    chord= double(inputs{j,"chord"});
    airfoilno = double(inputs{j,"airfoil no"});
    % Open the text file for reading
    fid = fopen([parentFolder,'\Airfoils\',convertStringsToChars(airfoils{airfoilno,"name"}),'.dat'], 'r');
    for i=1:52
        fgetl(fid);
    end
    data = textscan(fid, '%f %f %f %f', 'HeaderLines', 2);
    fclose(fid); % Close the file
    table = array2table(cell2mat(data),'VariableNames',{'alpha rad','c_l','c_d','c_m'});
    
    %excecute bem solver
    bem_solver_v2_00;
    Chord(j)=chord;
    Twist(j)=twist;
    span(j)=r;
    aind(j)=a;
    apind(j)=ap;
    aoas(j)=aoa;
    Fs(j)=F;
    cls(j)=cl;
    nondimcl(j)=chord*cl/r;
    cpi(j)=cp;
end

aind(end)=0.33;
apind(end)=0.005;

%all sections done, we check
for i=1:(height(inputs)-1)
    amids(i)=(aind(i)+aind(i+1))/2;
    apmids(i)=(apind(i)+apind(i+1))/2;
    rmids(i)=(span(i)+span(i+1))/2;
    rsize(i)=span(i+1)-span(i);
    Fmids(i)=(Fs(i+1)+Fs(i))/2;
end
rotspeed=ltsr*wndspeed/R;
dfx=Fmids.*1.225*(wndspeed^2)*4.*amids.*(1-amids)*pi().*rmids.*rsize;
dT=Fmids.*4.*apmids.*(1-amids).*1.225*wndspeed*rotspeed*pi().*(rmids.^3).*rsize;
cpmids=4*amids.*((1-amids).^2);
%power=cpmids.*1.225*(wndspeed^3)*pi().*(rannu.^2);
dpower=dT*rotspeed;

totalpwr=sum(dpower)*0.95;
%plots
figure();
plot(table2array(inputs(:,1)),aoas);
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