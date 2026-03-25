%main v4
%Code by Jose Mora @ UMass
%This one allows reading multiple section files
close all
clear
clc

parallel=1;
if parallel
    if isempty(gcp('nocreate'))
        parpool(5)
    end
end
%% initiation
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

%read inputs function
[inputs,airfoils]=scriptInit_v2(parentFolder);


%define hub radius and wind speed (this can be included in inputs later)
tsr=9;
hubRad=4.118878;
wndspeed=10.65;

%define the cases for the required ammount of beam elements
cases=[10 20 50 100 200];%beam elements can't be smaller than 1m


for count=3
    numel=cases(count);
    referenceCase=struct([]);
    inputs = array2table(cell2mat(inputs),'VariableNames',{'span (r) [m]','not used1','not used2','not used3','twist','chord','airfoil no','not used4','not used5','not used6'});
    
%% reference case run
tic
    %This runs the analysis blocks
    [relWind,a,ap,amids,apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
    ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,mass,refmoment,blade,D,R,F,L,Ks]...
    =analysis_blocks_v2_03...
    ('referenceCase',inputs,hubRad,parentFolder,airfoils,numel);

    %This saves all the variables of this reference case
    referenceCase =...
    variable_saving(1,1,1,a,ap,amids,apmids,ocp,oct,ocm,cpmids,ctmids,...
    cmmids,dT,dQ,totalpwr,refmoment,mass,blade,rmids,hubRad,D,R,F,L,Ks,[parentFolder,'\Results'],'referenceCase');

    %Plotting all the reference case plots
    plottingCase(referenceCase,parentFolder,'root_moment','referenceCase')

%% jamiesons fit
    %This fits the axial induction curve to what outputs from the reference
    %analysis

    rootPct=.30;
    [fitcurve, gof]=jamiesonsFit(referenceCase,rootPct);
   

    %equivalent fit model
    fig=figure('Name', 'Equivalent fit');
    plot((blade.ispan+hubRad)/(blade.ispan(end)+hubRad),referenceCase.a,...
        0:0.01:1,fitcurve.a*(1-(0:0.01:1).^fitcurve.n).^fitcurve.p,'LineWidth',5)
    xlabel('Span [m]')
    ylabel('axial induction')
    legend('Calculated induction','Fit Curve','Location','south')
    saveas(fig,[parentFolder,'/Results/root_moment/','RefCase','equivalent fit.jpg'])
    %legend('dT','dQ','Location','Southwest')

%% modified reference case

[crefjinputs,ajam,apjam,jamchord,jamtwist,crefnewhubRad,relWind,a,ap,amids,...
            apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
            ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,crefmass,crefmoment,blade,D,R,F,L,Ks]=...
            moment_matching...
            (referenceCase,refmoment,wndspeed,fitcurve.a,...
            fitcurve.n,fitcurve.p,hubRad,3,inputs,parentFolder,airfoils,numel);
%crefmass=sum(cell2mat(blade.secprops.data(:,18)*(blade.ispan(2)-blade.ispan(1))));
%This saves all the variables of this reference case
    crefjamiesonsCase =...
    variable_saving(1,1,1,a,ap,amids,apmids,ocp,oct,ocm,cpmids,ctmids,...
    cmmids,dT,dQ,totalpwr,crefmoment,crefmass,blade,rmids,hubRad,D,R,F,L,Ks,[parentFolder,'\Results\root_moment'],'crefjamiesonsCase');

%Plotting all the reference case plots
    plottingCase(crefjamiesonsCase,parentFolder,'root_moment','crefJamiesonsCase')
    
time1=toc
% aprox 210 seg or 3:30 min
%% jamiesons case
tic
%3 is the isoline im taking as a treshold (30% difference) and 10 the
%resoution of points in x
%function grid_points=JamiesonsBoundGenerator(a0,n_ref,p_ref,curve,n_min,n_max,resolution)
grid_points=JamiesonsBoundGenerator(fitcurve.a,fitcurve.n,fitcurve.p,4,fitcurve.p,5,20);


%powervector=zeros(50,50,50);

%nbounds=[100 50 500];
%pbounds=[10 50 500];
%newRow={a_in,n_in,p_in,a,ap,ocp,oct,ocm,totalpwr,blade.span(end),D(2,end)};
powertable_rootmom = table([], [], [], [], [], [], [], [], [], [], [], [], [], [], 'VariableNames', {'A','n','p','a','ap','ocp','oct','ocm','total power','cpR^2','blade span', 'tip deflection','moment','mass'});
fprintf('a_in   n_in    p_in\n')
jamiesonsCase=struct([]);

%Future=parallel.FevalFuture;
index=0;

for index=1:length(grid_points)
%for a_in=32
    %for n_in=nbounds(1):nbounds(2):nbounds(3) %concave <1 convex
        %for p_in=pbounds(1):pbounds(2):pbounds(3)
            a_in=fitcurve.a;
            n_in=grid_points(index,1);
            p_in=grid_points(index,2);
            fprintf('%4.4f %4.4f %4.4f \n',a_in,n_in,p_in)

            [jinputs,ajam,apjam,jamchord,jamtwist,newhubRad,relWind,a,ap,amids,...
            apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
            ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr, mass, newjammoment,blade,D,R,F,L,Ks]=...
            moment_matching...
            (crefjamiesonsCase,crefmoment,wndspeed,a_in,...
            n_in,p_in,crefnewhubRad,3,crefjinputs,parentFolder,airfoils,numel);
         
            jamiesonsCase(index).n=n_in;
            jamiesonsCase(index).p=p_in;
            jamiesonsCase(index).a=a;
            jamiesonsCase(index).ap=ap;
            jamiesonsCase(index).amids=amids;
            jamiesonsCase(index).apmids=apmids;
            jamiesonsCase(index).ocp=ocp;
            jamiesonsCase(index).oct=oct;
            jamiesonsCase(index).ocm=ocm;
            jamiesonsCase(index).cpmids=cpmids;
            jamiesonsCase(index).ctmids=ctmids;
            jamiesonsCase(index).cmmids=cmmids;
            jamiesonsCase(index).dT=dT;
            jamiesonsCase(index).dQ=dQ;
            jamiesonsCase(index).totalpwr=totalpwr;
            jamiesonsCase(index).blade=blade;
            jamiesonsCase(index).rmids=rmids;
            jamiesonsCase(index).hubRad=newhubRad;
            jamiesonsCase(index).D=D;
            jamiesonsCase(index).R=R;
            jamiesonsCase(index).F=F;
            jamiesonsCase(index).L=L;
            jamiesonsCase(index).Ks=Ks;
            jamiesonsCase(index).mass=mass;
            jamiesonsCase(index).moment=newjammoment;

     %add case to results table
                newRow={a_in,n_in,p_in,a,ap,ocp,oct,ocm,totalpwr/crefjamiesonsCase.totalpwr...
                    ,(ocp*blade.span(end)^2)/(crefjamiesonsCase.ocp*crefjamiesonsCase.blade.span(end)^2)...
                    ,jamiesonsCase(index).blade.ispan(end)/crefjamiesonsCase.blade.span(end),D(1,end)/crefjamiesonsCase.D(1,end),newjammoment/crefmoment,mass/crefmass};
                %D1=[jamiesonsCase(a_in,n_in,p_in).ocp,jamiesonsCase(a_in,n_in,p_in).oct,jamiesonsCase(a_in,n_in,p_in).ocm,jamiesonsCase(a_in,n_in,p_in).totalpwr,jamiesonsCase(a_in,n_in,p_in).blade.span(end),jamiesonsCase(a_in,n_in,p_in).D(3,end)];
                %D2=[referenceCase.ocp,referenceCase.oct,referenceCase.ocm,referenceCase.totalpwr,referenceCase.blade.span(end),referenceCase.D(3,end)];
                %P=[D1;D2];
                %spider_plot(P,'AxesLabels', {'ocp', 'oct', 'ocm', 'totalpwr', 'R' ,'tipdfl'})
                powertable_rootmom=[powertable_rootmom;newRow];
end
% individual graphs
% fig=figure('Name','Total power heatmap');
% title('power')
% heatmap(powertable,'n','p','ColorVariable','total power')
% saveas(fig,[parentFolder,'/Results/','CRefCase','totalpowerj.jpg'])
% fig=figure('Name','R heatmap');
% title('radius')
% heatmap(powertable,'n','p','ColorVariable','blade span')
% saveas(fig,[parentFolder,'/Results/','CRefCase','radiusj.jpg'])
% fig=figure('Name','Tip deflection heatmap');
% title('tip dfl')
% heatmap(powertable,'n','p','ColorVariable','tip deflection')
% saveas(fig,[parentFolder,'/Results/','CRefCase','tipdflj.jpg'])
% fig=figure('Name','Energy capture heatmap');
% title('cpR^2')
% heatmap(powertable,'n','p','ColorVariable','cpR^2')
% saveas(fig,[parentFolder,'/Results/','CRefCase','cpr2.jpg'])
%mixed graphs
%corrected reference plots

    fig=figure('Name', 'BEM Parameters both references');
    plot(crefjamiesonsCase.blade.ispan+crefnewhubRad,crefjamiesonsCase.a,crefjamiesonsCase.blade.ispan+crefnewhubRad,crefjamiesonsCase.ap,'LineWidth',5)
    hold on
    plot(referenceCase.blade.ispan+hubRad,referenceCase.a,referenceCase.blade.ispan+hubRad,referenceCase.ap,'LineWidth',5)
    xlabel('Span [m]')
    ylabel('[-]')
    legend('a_corr','a_ref','ap_corr','ap_ref','Location','Southwest')
    fontsize(gcf,scale=1.2)
    saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','BEM Parameters both references.jpg'])    
   
    %yeah im cheating a little with this one
    fig=figure('Name', 'AD Calculations both references');
    plot(crefjamiesonsCase.blade.ispan(1:end-1),crefjamiesonsCase.cpmids,crefjamiesonsCase.blade.ispan(1:end-1),crefjamiesonsCase.ctmids,crefjamiesonsCase.blade.ispan(1:end-1),crefjamiesonsCase.cmmids,'LineWidth',5)
    hold on
    plot(referenceCase.blade.ispan(1:end-1),referenceCase.cpmids,referenceCase.blade.ispan(1:end-1),crefjamiesonsCase.ctmids,referenceCase.blade.ispan(1:end-1),crefjamiesonsCase.cmmids,'LineWidth',5)
    xlabel('Span [m]')
    ylabel('[-]')
    legend('cp_corr','ct_corr','cm_corr','cp_ref','ct_ref','cm_ref','Location','Southwest')
    saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','AD Calculations both references.jpg'])

    fig=figure('Name', 'Summary of performance calculations for both blades');
    plot(crefjamiesonsCase.blade.ispan(1:end-1),crefjamiesonsCase.dT,crefjamiesonsCase.blade.ispan(1:end-1),crefjamiesonsCase.dQ,'LineWidth',5)
    hold on
    plot(referenceCase.blade.ispan(1:end-1),referenceCase.dT,referenceCase.blade.ispan(1:end-1),referenceCase.dQ,'LineWidth',5)
    xlabel('Span [m]')
    ylabel('Force [N], Torque [Nm]')
    legend('dT_corr','dT_ref','dQ_corr','dQ_ref','Location','Southwest')
    saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','Summary of performance calculations both references.jpg'])

    fig=figure('Name', 'Deflection both references');
    plot(crefjamiesonsCase.blade.ispan,crefjamiesonsCase.D(1,:),'LineWidth',5)
    hold on
    plot(referenceCase.blade.ispan,referenceCase.D(1,:),'LineWidth',5)
    xlabel('Span [m]')
    ylabel('Deflection [m]')
    legend('dfl_corr','dfl_ref','Location','southeast')
    saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','Deflection both references.jpg'])
    %legend('dT','dQ','Location','Southwest')

%save the powertable
scriptName = mfilename; % Get the script name
currentDate = datestr(now, 'yyyy-mm-dd_HH-MM-SS'); % Get the current date
filename = sprintf('%s_%s.mat', scriptName, currentDate); % Create the filename
foldername = [parentFolder, '/Results/root_moment/', sprintf('%s_%s/', scriptName, currentDate)]; % Create the filename
if ~isfolder(foldername)
    mkdir(foldername);
end
crefjamiesonsCaseMoment=crefjamiesonsCase;
crefjinputsmoment=crefjinputs;
save(foldername, 'powertable_rootmom','referenceCase','crefjamiesonsCaseMoment','crefjinputsmoment'); % Save the variable


%jamiesonsSlicer(jamiesonsCase,foldername)
% to retrieve the jamiesons slices
% jamiesonsWrapper(numParts,folderName) foldername is the entire path [parentFolder,'/Results/root_moment/',foldername,'/']
    %Heatmaps

%% plots
fig = plotHeatmapFromTable(powertable_rootmom, 'n','p', 'total power');
saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','totalpowerjheatmap.jpg'])
fig = plotHeatmapFromTable(powertable_rootmom, 'n','p', 'blade span');
saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','bladespanjheatmap.jpg'])
fig = plotHeatmapFromTable(powertable_rootmom, 'n','p', 'cpR^2');
saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','cpr2heatmap.jpg'])

mod_power_table = powertable_rootmom(powertable_rootmom.('tip deflection') ~= 0, :);

fig = plotHeatmapFromTable(mod_power_table, 'n','p', 'tip deflection');
saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','tipdflheatmap.jpg'])

    %surface plots
fig=plotSurfaceFromTable(powertable_rootmom, 'n','p', 'total power');
fig.Position = [100, 100, 800, 600];  % [left, bottom, width, height]
saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','totalpowerjsurf.jpg'])
fig=plotSurfaceFromTable(powertable_rootmom, 'n','p', 'blade span');
saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','radiusjsurf.jpg'])
fig=plotSurfaceFromTable(powertable_rootmom, 'n','p', 'cpR^2');
saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','cpr2surf.jpg'])
fig=plotSurfaceFromTable(mod_power_table, 'n','p', 'tip deflection');
saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','tipdfljsurf.jpg'])


time2=toc
delete(gcp('nocreate'))
end

%% Paretos

[fig,modpowertable,paretoX, paretoY, idx]=ParetoFront_v2(powertable_rootmom,'cpR^2','tip deflection'); %max, min
saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','ParetoCpr2tipdfl.jpg'])
fig=Important_plotter(idx,modpowertable,fitcurve.a,fitcurve.n,fitcurve.p);
saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','ParetocurvesCpr2tipdfl.jpg'])

[fig,modpowertable,paretoX, paretoY, idx, globalidx]=ParetoFront_v3(powertable_rootmom,'cpR^2','tip deflection','mass'); %max, min
saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','ParetoCpr2tipdflmass.jpg'])
fig=Important_plotter(idx,modpowertable,fitcurve.a,fitcurve.n,fitcurve.p);
saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','ParetocurvesCpr2tipdflmass.jpg'])

[fig,modpowertable,paretoX, paretoY, idx, globalidx]=ParetoFront_v3(powertable_rootmom,'cpR^2','blade span','mass'); %max, min
saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','ParetoCpr2bladespanmass.jpg'])
fig=Important_plotter(idx,modpowertable,fitcurve.a,fitcurve.n,fitcurve.p);
saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','ParetocurvesCpr2bladespanmass.jpg'])

[fig,modpowertable,paretoX, paretoY, idx, globalidx]=ParetoFront_v3(powertable_rootmom,'cpR^2','blade span','tip deflection'); %max, min
saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','ParetoCpr2bladespanmass.jpg'])
fig=Important_plotter(idx,modpowertable,fitcurve.a,fitcurve.n,fitcurve.p);
saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','ParetocurvesCpr2bladespanmass.jpg'])

[fig,modpowertable,paretoX, paretoY, idx]=ParetoFront_v2(powertable_rootmom,'cpR^2','blade span'); %max, min
saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','ParetoCpr2span.jpg'])
fig=Important_plotter(idx,modpowertable,fitcurve.a,fitcurve.n,fitcurve.p);
saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','ParetocurvesCpr2span.jpg'])

[fig,modpowertable,paretoX, paretoY, idx]=ParetoFront_v2(powertable_rootmom,'blade span','tip deflection'); %max, min
saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','Paretospantipdfl.jpg'])
fig=Important_plotter(idx,modpowertable,fitcurve.a,fitcurve.n,fitcurve.p);
saveas(fig,[parentFolder,'/Results/root_moment/','CRefCase','Paretocurvesspantipdfl.jpg'])

% here's how youd locate an index in the big table and consequently on the
% big jamiesons case structure
% rowIndex = find(all(abs([powertable.('A'), powertable.('n'), powertable.('p')] - [0.31605, 3.7957, 0.87103]) < 1e-3, 2))
%% comparisson plots
figure('Name', 'PreComp Analysis Results Jamiesons');
for i = 2:size(referenceCase.blade.secprops.data,2)
    subplot(5, 5, i);
    data = [referenceCase.blade.secprops.data]; % Concatenate results to form 'data'
    plot(data(:, 1), data(:, i), 'r-*');
    hold on
    for j=1:length(grid_points)
        data = [jamiesonsCase(j).blade.secprops.data]; % Concatenate results to form 'data'
                plot(data(:, 1), data(:, i), 'b-o');
                hold on
    end
    xlabel(strrep(referenceCase.blade.secprops.labels{1}, '_', '\_'));
    ylabel(strrep(referenceCase.blade.secprops.labels{i}, '_', '\_'));
    hold off
end

%% utility functions

function printStructFieldsToFile(object, objectName, folder)
    % Automatically name the file based on the objectName
    fileName = strcat(objectName, '_structureFields.txt');
    filePath = fullfile(folder, fileName);
    
    % Open the text file for writing
    fid = fopen(filePath, 'w');
    
    % Check if file was successfully opened
    if fid == -1
        error('Failed to open file for writing.');
    end
    
    % Get the field names of the structure
    fieldNames = fieldnames(object);
    
    % Loop over each field and write the field name and its value to the file
    for i = 1:length(fieldNames)
        fieldName = fieldNames{i};
        fieldValue = object.(fieldName);
        
        % Write the field name to the file
        fprintf(fid, '%s: ', fieldName);
        
        % Write the value depending on its type
        if isnumeric(fieldValue)
            fprintf(fid, '%s\n', mat2str(fieldValue));
        elseif ischar(fieldValue)
            fprintf(fid, '%s\n', fieldValue);
        else
            fprintf(fid, '%s\n', 'Unsupported data type');
        end
    end
    
    % Close the file after writing
    fclose(fid);
    
    % Inform the user that the file has been saved
    fprintf('File saved to: %s\n', filePath);
end

function fig = plotSurfaceFromTable(dataTable, xField, yField, zField)
    % plotSurfaceFromTable - Plots a surface plot using x, y, and z from a table
    %
    % Inputs:
    %   dataTable - Table containing the data
    %   xField    - String with the name of the x column
    %   yField    - String with the name of the y column
    %   zField    - String with the name of the z column
    %
    % Example usage:
    %   plotSurfaceFromTable(myTable, 'x', 'y', 'z')

    % Extract x, y, and z data from the table
    x = dataTable.(xField);
    y = dataTable.(yField);
    z = dataTable.(zField);

    % Create a meshgrid from the unique x and y values
    [X, Y] = meshgrid(unique(x), unique(y));

    % Interpolate the z values to fit the grid
    Z = griddata(x, y, z, X, Y);

    % Plot the surface
    fig=figure;
    surf(X, Y, Z);

    % Label the axes and add a title
    xlabel(xField);
    ylabel(yField);
    zlabel(zField);
    title('Surface Plot of ',zField);
    
    % Optional: Add color shading for a better visual effect
    shading interp;
    colorbar;
end

function fig = plotHeatmapFromTable(dataTable, xField, yField, zField)
    % plotHeatmapFromTable - Plots a heatmap using imagesc from a table
    %
    % Inputs:
    %   dataTable - Table containing the data
    %   xField    - String with the name of the x column
    %   yField    - String with the name of the y column
    %   zField    - String with the name of the z column
    %
    % Example usage:
    %   plotHeatmapFromTable(myTable, 'x', 'y', 'z')

    % Extract x, y, and z data from the table
    x = dataTable.(xField);
    y = dataTable.(yField);
    z = dataTable.(zField);

    % Create a meshgrid from the unique x and y values
    [Xq, Yq] = meshgrid(linspace(min(x), max(x), 100), linspace(min(y), max(y), 100));
    
    % Interpolate the z values onto the structured grid
    Zq = griddata(x, y, z, Xq, Yq, 'linear');

    % Plot the heatmap
    fig = figure;
    imagesc([min(x), max(x)], [min(y), max(y)], Zq);
    set(gca, 'YDir', 'normal'); % Fix y-axis direction
    colormap jet;
    colorbar;

    % Label the axes and add a title
    xlabel(xField);
    ylabel(yField);
    title(['Heatmap of ', zField]);
end

%matching baseline root bending moment
function [jinputs,ajam,apjam,jamchord,jamtwist,newhubRad,relWind,a,ap,amids,...
            apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
            ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,mass,crefmoment,blade,D,R,F,L,Ks]=...
            moment_matching...
            (crefjamiesonsCase,crefmoment,wndspeed,a_in,...
            n_in,p_in,crefnewhubRad,numblades,jinputs,parentFolder,airfoils,numel)

%Yeah I know, its a bit iffy to code it this way but im lazy
            %and this works. crefjamiesonsCase is your refBlade. I'm just
            %using that name because its more convenient
            %caseName=getVarName(crefjamiesonsCase);
           caseName = sprintf('jamiesonsCase_%2.4f_%2.4f_%2.4f', a_in, n_in, p_in);
            [jinputs, ajam, apjam, jamchord, jamtwist, newhubRad]...
                =jamieson_v2_03_momentmatch(crefjamiesonsCase,crefmoment,wndspeed,a_in,...
                n_in,p_in,crefnewhubRad,numblades,jinputs,parentFolder,airfoils);

            % Do analysis blocks for proposedR
            [relWind, a, ap, amids, apmids, cpvector, ctvector, rmids, cmvector, cpmids, ...
                ctmids, cmmids, ocp, oct, ocm, dT, dQ, totalpwr, mass, crefmoment, blade, D, R, F, L, Ks] = ...
                analysis_blocks_v2_03(caseName,jinputs, newhubRad, parentFolder, airfoils, numel);
    
            %diagnostic plot
             % figure()
             % plot(crefjamiesonsCase.blade.ispan,a,blade.ispan,ajam)
             % figure()
             % plot(crefjamiesonsCase.blade.ispan,jamchord,jinputs.("span (r) [m]"),jinputs.("chord"))
             % 

end

%bisection method
function [jinputs,ajam,apjam,jamchord,jamtwist,newhubRad,relWind,a,ap,amids,...
            apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
            ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,crefmoment,blade,D,R,F,L,Ks]=...
            bisection_run...
            (crefjamiesonsCase,crefmoment,wndspeed,a_in,...
            n_in,p_in,crefnewhubRad,numblades,inputs,parentFolder,airfoils,numel)

    
            %Yeah I know, its a bit iffy to code it this way but im lazy
            %and this works. crefjamiesonsCase is your refBlade. I'm just
            %using that name because its more convenient
            caseName=getVarName(crefjamiesonsCase);
    %iteration counts
    max_iter = 100; % Maximum iterations to avoid infinite looping
    tolerance = 5*1e-1; % Convergence tolerance
    
    bounds=[0.6 1.15]*(crefjamiesonsCase.blade.ispan(end)+crefnewhubRad);
    % Loop over initial guesses
    
    indicator = Inf; % Set indicator to a large value to start the loop
    iter = 0; % Initialize iteration counter
        
    lb=bounds(1);
    hb=bounds(2);
    
    fc=Inf;
         while abs(fc) > tolerance
            iter = iter + 1;
            if iter > max_iter
                fprintf('Maximum iterations reached for initial guess %f.\n', proposedR);
                break;
            end
            
            c=(hb + lb) / 2;
            % Perform computations for lb
            [jinputshb, ajamhb, apjamhb, jamchordhb, jamtwisthb, newhubRadhb] = jamieson_v2_02_tipdfl(crefjamiesonsCase, ...
                crefmoment, wndspeed, a_in, n_in, p_in, crefnewhubRad, numblades, inputs, ...
                parentFolder, airfoils, hb);
    
            % Perform computations for hb
            [jinputslb, ajamlb, apjamlb, jamchordlb, jamtwistlb, newhubRadlb] = jamieson_v2_02_tipdfl(crefjamiesonsCase, ...
                crefmoment, wndspeed, a_in, n_in, p_in, crefnewhubRad, numblades, inputs, ...
                parentFolder, airfoils, lb);

             % Perform computations for c
            [jinputs, ajam, apjam, jamchord, jamtwist, newhubRad] = jamieson_v2_02_tipdfl(crefjamiesonsCase, ...
                crefmoment, wndspeed, a_in, n_in, p_in, crefnewhubRad, numblades, inputs, ...
                parentFolder, airfoils, c);
    
            %diagnostic plot
            % figure()
            % plot(crefjamiesonsCase.blade.ispan,a,crefjamiesonsCase.blade.ispan,ajam)
            % figure()
            % plot(crefjamiesonsCase.blade.ispan,jamchord,jinputs.("span (r) [m]"),jinputs.("chord"))
            % Analysis blocks for + step
            
            % Do analysis blocks for hb
            [~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~,...
                 Dhb, ~, ~, ~, ~] = ...
                 analysis_blocks_v2_03(caseName,jinputshb, newhubRadhb, parentFolder, airfoils, numel);

            % Do analysis blocks for lb
            [~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~,...
                 Dlb, ~, ~, ~, ~] = ...
                 analysis_blocks_v2_03(caseName,jinputslb, newhubRadlb, parentFolder, airfoils, numel);
    
            % Do analysis blocks for c
            [relWind, a, ap, amids, apmids, cpvector, ctvector, rmids, cmvector, cpmids, ...
                ctmids, cmmids, ocp, oct, ocm, dT, dQ, totalpwr, crefmoment, blade, D, R, F, L, Ks] = ...
                analysis_blocks_v2_03(caseName,jinputs, newhubRad, parentFolder, airfoils, numel);
    
            fhb=Dhb(1,end)-crefjamiesonsCase(1).D(1, end);
            flb=Dlb(1,end)-crefjamiesonsCase(1).D(1, end);
            fc=D(1,end)-crefjamiesonsCase(1).D(1, end);
            if fhb * flb >= 0
                error('f(a) and f(b) must have opposite signs.');
                break;
            end

            if abs(fc) < tolerance  % If f(c) is close to zero, root found
                fprintf('Converged to %f after %d iterations.\n', c, iter);
                break;
            elseif flb * fc > 0 % Root is in [a, c]
                lb = c;
            else  % Root is in [c, b]
                hb = c;
            end
    
         end
end

function varName = getVarName(var)
    varName = inputname(1); % Get the name of the first input argument
end