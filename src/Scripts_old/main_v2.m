%main
%This one allows reading multiple section files
%Made By JMora
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
fid = fopen([parentFolder,'\Inputs\BladeSections.dat'], 'r');
%assign parameters and read comments/discard them
for i=1:4
    fgetl(fid);
end
inputs = textscan(fid, '%f %f %f %f %f %f %f', 'HeaderLines', 2);
fclose(fid); % Close the file
inputs = array2table(cell2mat(inputs),'VariableNames',{'span (r) [m]','not used1','not used2','not used3','twist','chord','airfoil no'});

R = double(inputs{end,1});

%now we do bem calcs for each section

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
    Span(j)=r;
    aind(j)=a;
    apind(j)=ap;
    aoas(j)=aoa;
    Fs(j)=F;
    cls(j)=cl;
    nondimcl(j)=chord*cl/r;
end

%Prepare data for numad model
for j=1:height(inputs)
    if cls(j)<0.1
        Thickness(j)=100;
    else
        Thickness(j)=NaN;
    end
end

for j=1:height(inputs)
    if cls(j)<0.1
        AeroCenter(j)=0.5;
    else
        AeroCenter(j)=0.275;
    end
end
Thickness(end)=18;

k=0;
for j=2:height(inputs)
    if table2array(inputs(j-1,7))==table2array(inputs(j,7))
    else
        k=k+1;
        afspan(k)=table2array(inputs(j,1));
        affile=sprintf('airfoils/%s.txt',col2(k));
    end
end

ChordOffset=zeros(1,height(inputs));
blade=BladeDef();
blade.span=Span;
blade.degreestwist=Twist*180/pi;
blade.chord=Chord;
blade.percentthick=Thickness;
blade.chordoffset=ChordOffset;
blade.aerocenter=AeroCenter;
blade.sweep        = zeros(size(blade.span));
blade.prebend      = zeros(size(blade.span));

prop = {'degreestwist','chord','percentthick','chordoffset','aerocenter'};

%Interpolation module
for k=1:length(prop)
        % For each of the input properties, interpolate where ever values
        % are missing.
        ind = isnan(blade.(prop{k}));
        if any(ind)
            if ~isequal(prop{k},'percentthick')
            blade.(prop{k})(ind) = interp1(blade.span(~ind),...
                                            blade.(prop{k})(~ind),...
                                            blade.span( ind),...
                                            'pchip');
            else
                % jcb: note that blade.chord must be interpolated before
                % blade.percentthick
                absthick = blade.percentthick .* blade.chord / 100;
                iabsthick = interp1(blade.span(~ind),...
                                    absthick(~ind),...
                                    blade.span( ind),...
                                    'pchip');
                blade.percentthick(ind) = iabsthick ./ blade.chord(ind) * 100;
            end
            % The next two lines report when a property has been
            % interpolated.
%             rowstr = sprintf('%d,',find(ind==1));
%             fprintf('Interpolating "%s" on rows [%s]\n',props{k},rowstr(1:end-1))
        end
end


%plots
figure(1);
plot(table2array(inputs(:,1)),aoas);
title('angles of attack')
figure(2);
plot(table2array(inputs(:,1)),aind);
title('axial inductions')
figure(3);
plot(table2array(inputs(:,1)),apind);
title('tangential inductions')
figure(4);
plot(table2array(inputs(:,1)),Fs);
title('Tip Loss')
figure(5);
plot(table2array(inputs(:,1)),nondimcl);
title('non dimensional cl')