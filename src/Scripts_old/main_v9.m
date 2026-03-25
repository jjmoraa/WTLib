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
fid = fopen([parentFolder,'\Inputs\BladeSectionsv3.dat'], 'r');%CHECK!
%assign parameters and read comments/discard them
for i=1:4
    fgetl(fid);
end
inputs = textscan(fid, '%f %f %f %f %f %f %f', 'HeaderLines', 2);
fclose(fid); % Close the file
hubRad=4.118878;
wndspeed=10.65;

cases=[10 20 50 100 200];%beam elements can't be smaller than 1m


for count=2
    numel=cases(count);
    referenceCase=struct([]);
    inputs = array2table(cell2mat(inputs),'VariableNames',{'span (r) [m]','not used1','not used2','not used3','twist','chord','airfoil no'});
    
%% reference case run
    [relWind,a,ap,amids,apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
    ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,refmoment,blade,D,R,F,L,Ks]...
    =analysis_blocks_v2_02...
    (inputs,hubRad,parentFolder,airfoils,numel);

    referenceCase(1).a=a;
    referenceCase(1).ap=ap;
    referenceCase(1).amids=amids;
    referenceCase(1).apmids=apmids;
    referenceCase(1).ocp=ocp;
    referenceCase(1).oct=oct;
    referenceCase(1).ocm=ocm;
    referenceCase(1).cpmids=cpmids;
    referenceCase(1).ctmids=ctmids;
    referenceCase(1).cmmids=cmmids;
    referenceCase(1).dT=dT;
    referenceCase(1).dQ=dQ;
    referenceCase(1).totalpwr=totalpwr;
    referenceCase(1).blade=blade;
    referenceCase(1).D=D;
    referenceCase(1).R=R;
    referenceCase(1).F=F;
    referenceCase(1).L=L;
    referenceCase(1).Ks=Ks;
    %topSecProps(count).secprops=blade.secprops.data;
    %ispans(count).ispan=blade.ispan;
    %Dstory(count).D=D;

    printStructFieldsToFile(referenceCase, 'referenceCase', [parentFolder,'\Results'])

    % Define the custom fit function
    fitfun = fittype(@(a,n,p,x) a.*((1 - x.^n).^(p)), 'independent', 'x', 'coefficients', {'a', 'n', 'p'});
    
    % Prepare x and y data separately
    x = (referenceCase(1).blade.ispan(6:(end-1)) + hubRad)/(referenceCase.blade.ispan(end)+hubRad);  % Independent variable (span + hub radius)
    y = referenceCase(1).a(6:(end-1));  % Dependent variable (a)
    
    % Perform the fit
    [fitcurve, gof] = fit(x(:), y(:), fitfun, 'StartPoint', [0.33, 0.5, 0.5]);
    
    % Output the sum of squared errors (SSE)
    fprintf('x01: sse=%.3f\n', gof.sse);
    
    %reference case plots
    figure('Name', 'PreComp Analysis Results');
    data = [blade.secprops.data]; % Concatenate results to form 'data'
    for i = 2:size(data, 2)
        subplot(5, 5, i);
        plot(data(:, 1), data(:, i), 'b-o');
        xlabel(strrep(blade.secprops.labels{1}, '_', '\_'));
        ylabel(strrep(blade.secprops.labels{i}, '_', '\_'));
    end

    fig=figure('Name', 'BEM Parameters');
    plot(blade.ispan+hubRad,referenceCase.a,blade.ispan+hubRad,referenceCase.ap,'LineWidth',5)
    xlabel('Span [m]')
    ylabel('[-]')
    legend('a','ap','Location','Southwest')
    fontsize(gcf,scale=1.2)
    saveas(fig,[parentFolder,'/Results/','RefCase','BEM Parameters.jpg'])    
   
    fig=figure('Name', 'AD Calculations');
    plot(rmids,referenceCase.cpmids,rmids,referenceCase.ctmids,rmids,referenceCase.cmmids,'LineWidth',5)
    xlabel('Span [m]')
    ylabel('[-]')
    legend('cp','ct','cm','Location','Southwest')
    saveas(fig,[parentFolder,'/Results/','RefCase','AD Calculations.jpg'])

    fig=figure('Name', 'Summary of performance calculations');
    plot(rmids,dT,rmids,dQ,'LineWidth',5)
    xlabel('Span [m]')
    ylabel('Force [N], Torque [Nm]')
    legend('dT','dQ','Location','Southwest')
    saveas(fig,[parentFolder,'/Results/','RefCase','Summary of performance calculations.jpg'])

    fig=figure('Name', 'Deflection');
    plot(blade.ispan,D(2,:),'LineWidth',5)
    xlabel('Span [m]')
    ylabel('Deflection [m]')
    saveas(fig,[parentFolder,'/Results/','RefCase','Deflection.jpg'])
    %legend('dT','dQ','Location','Southwest')

    %equivalent fit model
    fig=figure('Name', 'Equivalent fit');
    plot((blade.ispan+hubRad)/(blade.ispan(end)+hubRad),referenceCase.a,...
        0:0.01:1,fitcurve.a*(1-(0:0.01:1).^fitcurve.n).^fitcurve.p,'LineWidth',5)
    xlabel('Span [m]')
    ylabel('axial induction')
    legend('Calculated induction','Fit Curve','Location','south')
    saveas(fig,[parentFolder,'/Results/','RefCase','equivalent fit.jpg'])
    %legend('dT','dQ','Location','Southwest')
%% modified reference case
    [crefjinputs,crefajam,crefapjam,crefjamchord,crefjamtwist,crefnewhubRad]...
                =jamieson_v2_01(referenceCase,refmoment,wndspeed,fitcurve.a,...
                fitcurve.n,fitcurve.p,hubRad,3,inputs,parentFolder,airfoils);

    %topSecProps=struct;
            %ispans=struct;
            %Dstory=struct;
                
                %Future(index)=parfeval(@analysis_blocks,13,jinputs,hubRad,parentFolder,airfoils,numel);
                [relWind,a,ap,amids,apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
                    ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,crefmoment,blade,D,R,F,L,Ks]...
                    =analysis_blocks_v2_02...
                    (crefjinputs,crefnewhubRad,parentFolder,airfoils,numel);
                %topSecProps(count).secprops=blade.secprops.data;
                %ispans(count).ispan=blade.ispan;
                %Dstory(count).D=D;
                
                crefjamiesonsCase(1).hubrad=crefnewhubRad;
                crefjamiesonsCase(1).a=a;
                crefjamiesonsCase(1).ap=ap;
                crefjamiesonsCase(1).amids=amids;
                crefjamiesonsCase(1).apmids=apmids;
                crefjamiesonsCase(1).cpmids=cpmids;
                crefjamiesonsCase(1).ctmids=ctmids;
                crefjamiesonsCase(1).cmmids=cmmids;
                crefjamiesonsCase(1).ocp=ocp;
                crefjamiesonsCase(1).oct=oct;
                crefjamiesonsCase(1).ocm=ocm;
                crefjamiesonsCase(1).dT=dT;
                crefjamiesonsCase(1).dQ=dQ;
                crefjamiesonsCase(1).totalpwr=totalpwr;
                crefjamiesonsCase(1).blade=blade;
                crefjamiesonsCase(1).D=D;
                crefjamiesonsCase(1).R=R;
                crefjamiesonsCase(1).F=F;
                crefjamiesonsCase(1).L=L;
                crefjamiesonsCase(1).Ks=Ks;
                %D1=[jamiesonsCase(a_in,n_in,p_in).ocp,jamiesonsCase(a_in,n_in,p_in).oct,jamiesonsCase(a_in,n_in,p_in).ocm,jamiesonsCase(a_in,n_in,p_in).totalpwr,jamiesonsCase(a_in,n_in,p_in).blade.span(end),jamiesonsCase(a_in,n_in,p_in).D(3,end)];
                %D2=[referenceCase.ocp,referenceCase.oct,referenceCase.ocm,referenceCase.totalpwr,referenceCase.blade.span(end),referenceCase.D(3,end)];
                %P=[D1;D2];
                %spider_plot(P,'AxesLabels', {'ocp', 'oct', 'ocm', 'totalpwr', 'R' ,'tipdfl'})

    printStructFieldsToFile(crefjamiesonsCase, 'crefjamiesonsCase', [parentFolder,'\Results'])
                %reference case plots
    figure('Name', 'PreComp Analysis Results');
    data = [blade.secprops.data]; % Concatenate results to form 'data'
    for i = 2:size(data, 2)
        subplot(5, 5, i);
        plot(data(:, 1), data(:, i), 'b-o');
        xlabel(strrep(blade.secprops.labels{1}, '_', '\_'));
        ylabel(strrep(blade.secprops.labels{i}, '_', '\_'));
    end
    
    %corrected reference plots
    fig=figure('Name', 'BEM Parameters');
    plot(blade.ispan+crefnewhubRad,crefjamiesonsCase.a,blade.ispan+crefnewhubRad,crefjamiesonsCase.ap,'LineWidth',5)
    xlabel('Span [m]')
    ylabel('[-]')
    legend('a','ap','Location','Southwest')
    fontsize(gcf,scale=1.2)
    saveas(fig,[parentFolder,'/Results/','CRefCase','BEM Parameters.jpg'])    
   
    fig=figure('Name', 'AD Calculations');
    plot(rmids,crefjamiesonsCase.cpmids,rmids,crefjamiesonsCase.ctmids,rmids,crefjamiesonsCase.cmmids,'LineWidth',5)
    xlabel('Span [m]')
    ylabel('[-]')
    legend('cp','ct','cm','Location','Southwest')
    saveas(fig,[parentFolder,'/Results/','CRefCase','AD Calculations.jpg'])

    fig=figure('Name', 'Summary of performance calculations');
    plot(rmids,dT,rmids,dQ,'LineWidth',5)
    xlabel('Span [m]')
    ylabel('Force [N], Torque [Nm]')
    legend('dT','dQ','Location','Southwest')
    saveas(fig,[parentFolder,'/Results/','CRefCase','Summary of performance calculations.jpg'])

    fig=figure('Name', 'Deflection');
    plot(blade.ispan,D(2,:),'LineWidth',5)
    xlabel('Span [m]')
    ylabel('Deflection [m]')
    saveas(fig,[parentFolder,'/Results/','CRefCase','Deflection.jpg'])
    %legend('dT','dQ','Location','Southwest')

%% jamiesons case

powervector=zeros(50,50,50);

%newRow={a_in,n_in,p_in,a,ap,ocp,oct,ocm,totalpwr,blade.span(end),D(2,end)};
powertable = table([], [], [], [], [], [], [], [], [], [], [], [], 'VariableNames', {'A','n','p','a','ap','ocp','oct','ocm','total power','cpR^2','blade span', 'tip deflection'});
fprintf('a_in   n_in    p_in\n')
jamiesonsCase=struct([]);

%Future=parallel.FevalFuture;
index=0;
for a_in=33
    for n_in=10:10:60 %concave <1 convex
        for p_in=10:10:60
            index=index+1;
            fprintf('%4.4f %4.4f %4.4f \n',a_in,n_in,p_in)
            [jinputs,ajam,apjam,jamchord,jamtwist,newhubRad]...
                =jamieson_v2_01(crefjamiesonsCase,crefmoment,wndspeed,a_in/100,...
                n_in/100,p_in/100,crefnewhubRad,3,crefjinputs,parentFolder,airfoils);
            
            %topSecProps=struct;
            %ispans=struct;
            %Dstory=struct;
                
                %Future(index)=parfeval(@analysis_blocks,13,jinputs,hubRad,parentFolder,airfoils,numel);
                [relWind,a,ap,amids,apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
                    ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,moment,blade,D,R,F,L,Ks]...
                    =analysis_blocks_v2_02...
                    (jinputs,newhubRad,parentFolder,airfoils,numel);
                %topSecProps(count).secprops=blade.secprops.data;
                %ispans(count).ispan=blade.ispan;
                %Dstory(count).D=D;
                
                jamiesonsCase(a_in,n_in,p_in).hubRad=newhubRad;
                jamiesonsCase(a_in,n_in,p_in).a=a;
                jamiesonsCase(a_in,n_in,p_in).ap=ap;
                jamiesonsCase(a_in,n_in,p_in).amids=amids;
                jamiesonsCase(a_in,n_in,p_in).apmids=apmids;
                jamiesonsCase(a_in,n_in,p_in).cpmids=cpmids;
                jamiesonsCase(a_in,n_in,p_in).ctmids=ctmids;
                jamiesonsCase(a_in,n_in,p_in).cmmids=cmmids;
                jamiesonsCase(a_in,n_in,p_in).ocp=ocp;
                jamiesonsCase(a_in,n_in,p_in).oct=oct;
                jamiesonsCase(a_in,n_in,p_in).ocm=ocm;
                jamiesonsCase(a_in,n_in,p_in).dT=dT;
                jamiesonsCase(a_in,n_in,p_in).dQ=dQ;
                jamiesonsCase(a_in,n_in,p_in).totalpwr=totalpwr;
                jamiesonsCase(a_in,n_in,p_in).blade=blade;
                jamiesonsCase(a_in,n_in,p_in).D=D;
                jamiesonsCase(a_in,n_in,p_in).R=R;
                jamiesonsCase(a_in,n_in,p_in).F=F;
                jamiesonsCase(a_in,n_in,p_in).L=L;
                jamiesonsCase(a_in,n_in,p_in).Ks=Ks;
                newRow={a_in/100,n_in/100,p_in/100,a,ap,ocp,oct,ocm,totalpwr/crefjamiesonsCase.totalpwr...
                    ,(ocp*(blade.span(end)+newhubRad)^2)/(crefjamiesonsCase.ocp*(crefjamiesonsCase.blade.span(end)+crefnewhubRad)^2)...
                    ,blade.span(end)/crefjamiesonsCase.blade.span(end),D(2,end)/crefjamiesonsCase.D(2,end)};
                %D1=[jamiesonsCase(a_in,n_in,p_in).ocp,jamiesonsCase(a_in,n_in,p_in).oct,jamiesonsCase(a_in,n_in,p_in).ocm,jamiesonsCase(a_in,n_in,p_in).totalpwr,jamiesonsCase(a_in,n_in,p_in).blade.span(end),jamiesonsCase(a_in,n_in,p_in).D(3,end)];
                %D2=[referenceCase.ocp,referenceCase.oct,referenceCase.ocm,referenceCase.totalpwr,referenceCase.blade.span(end),referenceCase.D(3,end)];
                %P=[D1;D2];
                %spider_plot(P,'AxesLabels', {'ocp', 'oct', 'ocm', 'totalpwr', 'R' ,'tipdfl'})
                powertable=[powertable;newRow];
        end
    end
% individual graphs
fig=figure('Name','Total power heatmap');
title('power')
heatmap(powertable,'n','p','ColorVariable','total power')
saveas(fig,[parentFolder,'/Results/','CRefCase','totalpowerj.jpg'])
fig=figure('Name','R heatmap');
title('radius')
heatmap(powertable,'n','p','ColorVariable','blade span')
saveas(fig,[parentFolder,'/Results/','CRefCase','radiusj.jpg'])
fig=figure('Name','Tip deflection heatmap');
title('tip dfl')
heatmap(powertable,'n','p','ColorVariable','tip deflection')
saveas(fig,[parentFolder,'/Results/','CRefCase','tipdflj.jpg'])
fig=figure('Name','Energy capture heatmap');
title('cpR^2')
heatmap(powertable,'n','p','ColorVariable','cpR^2')
saveas(fig,[parentFolder,'/Results/','CRefCase','cpr2.jpg'])
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
    saveas(fig,[parentFolder,'/Results/','CRefCase','BEM Parameters both references.jpg'])    
   
    %yeah im cheating a little with this one
    fig=figure('Name', 'AD Calculations both references');
    plot(crefjamiesonsCase.blade.ispan(1:end-1),crefjamiesonsCase.cpmids,crefjamiesonsCase.blade.ispan(1:end-1),crefjamiesonsCase.ctmids,crefjamiesonsCase.blade.ispan(1:end-1),crefjamiesonsCase.cmmids,'LineWidth',5)
    hold on
    plot(referenceCase.blade.ispan(1:end-1),referenceCase.cpmids,referenceCase.blade.ispan(1:end-1),crefjamiesonsCase.ctmids,referenceCase.blade.ispan(1:end-1),crefjamiesonsCase.cmmids,'LineWidth',5)
    xlabel('Span [m]')
    ylabel('[-]')
    legend('cp_corr','ct_corr','cm_corr','cp_ref','ct_ref','cm_ref','Location','Southwest')
    saveas(fig,[parentFolder,'/Results/','CRefCase','AD Calculations both references.jpg'])

    fig=figure('Name', 'Summary of performance calculations for both blades');
    plot(crefjamiesonsCase.blade.ispan(1:end-1),crefjamiesonsCase.dT,crefjamiesonsCase.blade.ispan(1:end-1),crefjamiesonsCase.dQ,'LineWidth',5)
    hold on
    plot(referenceCase.blade.ispan(1:end-1),referenceCase.dT,referenceCase.blade.ispan(1:end-1),referenceCase.dQ,'LineWidth',5)
    xlabel('Span [m]')
    ylabel('Force [N], Torque [Nm]')
    legend('dT_corr','dT_ref','dQ_corr','dQ_ref','Location','Southwest')
    saveas(fig,[parentFolder,'/Results/','CRefCase','Summary of performance calculations both references.jpg'])

    fig=figure('Name', 'Deflection both references');
    plot(crefjamiesonsCase.blade.ispan,crefjamiesonsCase.D(2,:),'LineWidth',5)
    hold on
    plot(referenceCase.blade.ispan,referenceCase.D(2,:),'LineWidth',5)
    xlabel('Span [m]')
    ylabel('Deflection [m]')
    legend('dfl_corr','dfl_ref','Location','southeast')
    saveas(fig,[parentFolder,'/Results/','CRefCase','Deflection both references.jpg'])
    %legend('dT','dQ','Location','Southwest')

    %surface plots
fig=plotSurfaceFromTable(powertable, 'n','p', 'total power');
fig.Position = [100, 100, 800, 600];  % [left, bottom, width, height]
saveas(fig,[parentFolder,'/Results/','CRefCase','totalpowerjsurf.jpg'])
fig=plotSurfaceFromTable(powertable, 'n','p', 'blade span');
saveas(fig,[parentFolder,'/Results/','CRefCase','radiusjsurf.jpg'])
fig=plotSurfaceFromTable(powertable, 'n','p', 'cpR^2');
saveas(fig,[parentFolder,'/Results/','CRefCase','cpr2surf.jpg'])
fig=plotSurfaceFromTable(powertable, 'n','p', 'tip deflection');
saveas(fig,[parentFolder,'/Results/','CRefCase','tipdfljsurf.jpg'])

%Pareto plots
end
delete(gcp('nocreate'))
end

%% comparisson plots
figure('Name', 'PreComp Analysis Results Jamiesons');
for i = 2:size(jamiesonsCase(a_in,n_in,p_in).blade.secprops.data, 2)
    subplot(5, 5, i);
    data = [referenceCase.blade.secprops.data]; % Concatenate results to form 'data'
    plot(data(:, 1), data(:, i), 'r-*');
    hold on
        for n_in=10:10:60 %concave <1 convex
            for p_in=10:10:60
                data = [jamiesonsCase(a_in,n_in,p_in).blade.secprops.data]; % Concatenate results to form 'data'
                plot(data(:, 1), data(:, i), 'b-o');
                hold on
            end
        end
    xlabel(strrep(jamiesonsCase(a_in,n_in,p_in).blade.secprops.labels{1}, '_', '\_'));
    ylabel(strrep(jamiesonsCase(a_in,n_in,p_in).blade.secprops.labels{i}, '_', '\_'));
    hold off
end

%figure

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

function fig=plotSurfaceFromTable(dataTable, xField, yField, zField)
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

function fig=plotPareto(dataTable,n_in)
    for i=1:(n_in/10)
        filteredValues = powertable(powertable.n == 0.6, :);
    end
end