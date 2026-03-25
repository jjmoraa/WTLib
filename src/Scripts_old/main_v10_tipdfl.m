%main v4
%Code by Jose Mora @ UMass
%This one allows reading multiple section files
close all
clear
clc

parallel=0;
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

    %This runs the analysis blocks
    [relWind,a,ap,amids,apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
    ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,refmoment,blade,D,R,F,L,Ks]...
    =analysis_blocks_v2_03...
    ('referenceCase',inputs,hubRad,parentFolder,airfoils,numel);

    %This saves all the variables of this reference case
    referenceCase =...
    variable_saving(a,ap,amids,apmids,ocp,oct,ocm,cpmids,ctmids,...
    cmmids,dT,dQ,totalpwr,blade,rmids,hubRad,D,R,F,L,Ks,[parentFolder,'\Results'],'referenceCase');

    %Plotting all the reference case plots
    plottingCase(referenceCase,parentFolder)

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
    saveas(fig,[parentFolder,'/Results/','RefCase','equivalent fit.jpg'])
    %legend('dT','dQ','Location','Southwest')

%% modified reference case

[crefjinputs,ajam,apjam,jamchord,jamtwist,crefnewhubRad,relWind,a,ap,amids,...
            apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
            ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,crefmoment,blade,D,R,F,L,Ks]=...
            newtons_run...
            (referenceCase,refmoment,wndspeed,fitcurve.a,...
            fitcurve.n,fitcurve.p,hubRad,3,inputs,parentFolder,airfoils,numel);

%This saves all the variables of this reference case
    crefjamiesonsCase =...
    variable_saving(a,ap,amids,apmids,ocp,oct,ocm,cpmids,ctmids,...
    cmmids,dT,dQ,totalpwr,blade,rmids,hubRad,D,R,F,L,Ks,[parentFolder,'\Results'],'crefjamiesonsCase');

%Plotting all the reference case plots
    plottingCase(crefjamiesonsCase,parentFolder)
    
%% jamiesons case

powervector=zeros(50,50,50);

%newRow={a_in,n_in,p_in,a,ap,ocp,oct,ocm,totalpwr,blade.span(end),D(2,end)};
powertable = table([], [], [], [], [], [], [], [], [], [], [], [], 'VariableNames', {'A','n','p','a','ap','ocp','oct','ocm','total power','cpR^2','blade span', 'tip deflection'});
fprintf('a_in   n_in    p_in\n')
jamiesonsCase=struct([]);

%Future=parallel.FevalFuture;
index=0;
for a_in=33
    for n_in=10:10:100 %concave <1 convex
        for p_in=10:10:100
            index=index+1;
            fprintf('%4.4f %4.4f %4.4f \n',a_in,n_in,p_in)

            [jinputs,ajam,apjam,jamchord,jamtwist,newhubRad,relWind,a,ap,amids,...
            apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
            ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,newrefmoment,blade,D,R,F,L,Ks]=...
            newtons_run...
            (crefjamiesonsCase,crefmoment,wndspeed,a_in/100,...
            n_in/100,p_in/100,crefnewhubRad,3,crefjinputs,parentFolder,airfoils,numel);
         
            variable_saving(a,ap,amids,apmids,ocp,oct,ocm,cpmids,ctmids,...
     cmmids,dT,dQ,totalpwr,blade,rmids,hubRad,D,R,F,L,Ks,[parentFolder,'\Results'],'jamiesonsCase');

     %add case to results table
                newRow={a_in/100,n_in/100,p_in/100,a,ap,ocp,oct,ocm,totalpwr/crefjamiesonsCase.totalpwr...
                    ,(ocp*blade.span(end)^2)/(crefjamiesonsCase.ocp*crefjamiesonsCase.blade.span(end)^2)...
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
end
delete(gcp('nocreate'))
end

toc

%% comparisson plots
figure('Name', 'PreComp Analysis Results Jamiesons');
for i = 2:size(jamiesonsCase(a_in,n_in,p_in).blade.secprops.data, 2)
    subplot(5, 5, i);
    data = [referenceCase.blade.secprops.data]; % Concatenate results to form 'data'
    plot(data(:, 1), data(:, i), 'r-*');
    hold on
        for n_in=10:5:50 %concave <1 convex
            for p_in=10:5:50
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

%newtons method
function [jinputs,ajam,apjam,jamchord,jamtwist,newhubRad,relWind,a,ap,amids,...
            apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
            ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,crefmoment,blade,D,R,F,L,Ks]=...
            newtons_run...
            (crefjamiesonsCase,crefmoment,wndspeed,a_in,...
            n_in,p_in,crefnewhubRad,numblades,jinputs,parentFolder,airfoils,numel)

            step=1;
    
            caseName=getVarName(crefjamiesonsCase);
    % Define a list of initial guesses
    %initial_guesses = [0.8, 0.9, 1, 1.1, 1.5]*(crefjamiesonsCase.blade.ispan(end)+crefnewhubRad); % Replace with appropriate guesses
    initial_guesses = [0.90, 1, 1.1]*(crefjamiesonsCase.blade.ispan(end)+crefnewhubRad); % Replace with appropriate guesses
    max_iter = 100; % Maximum iterations to avoid infinite looping
    current_guess_index = 1; % Index for initial_guesses
    tolerance = 1e-1; % Convergence tolerance
    
    % Loop over initial guesses
    while current_guess_index <= length(initial_guesses)
        proposedR = initial_guesses(current_guess_index);
        indicator = Inf; % Set indicator to a large value to start the loop
        iter = 0; % Initialize iteration counter
        
        while indicator > tolerance
            iter = iter + 1;
            if iter > max_iter
                fprintf('Maximum iterations reached for initial guess %f.\n', proposedR);
                break;
            end
    
            % Perform computations for current proposedR
            [jinputs, ajam, apjam, jamchord, jamtwist, newhubRad] = jamieson_v2_02_tipdfl(crefjamiesonsCase, ...
                crefmoment, wndspeed, a_in, n_in, p_in, crefnewhubRad, numblades, jinputs, ...
                parentFolder, airfoils, proposedR);
    
            % Perform computations for + step
            [jinputsph, ajamph, apjamph, jamchordph, jamtwistph, newhubRadph] = jamieson_v2_02_tipdfl(crefjamiesonsCase, ...
                crefmoment, wndspeed, a_in, n_in, p_in, crefnewhubRad, numblades, jinputs, ...
                parentFolder, airfoils, proposedR + step);
    
            % Perform computations for - step
            [jinputsmh, ajammh, apjammh, jamchordmh, jamtwistmh, newhubRadmh] = jamieson_v2_02_tipdfl(crefjamiesonsCase, ...
                crefmoment, wndspeed, a_in, n_in, p_in, crefnewhubRad, numblades, jinputs, ...
                parentFolder, airfoils, proposedR - step);
    
            % Do analysis blocks for proposedR
            [relWind, a, ap, amids, apmids, cpvector, ctvector, rmids, cmvector, cpmids, ...
                ctmids, cmmids, ocp, oct, ocm, dT, dQ, totalpwr, crefmoment, blade, D, R, F, L, Ks] = ...
                analysis_blocks_v2_03(caseName,jinputs, newhubRad, parentFolder, airfoils, numel);
    
            %diagnostic plot
            % figure()
            % plot(crefjamiesonsCase.blade.ispan,a,crefjamiesonsCase.blade.ispan,ajam)
            % figure()
            % plot(crefjamiesonsCase.blade.ispan,jamchord,jinputs.("span (r) [m]"),jinputs.("chord"))
            % Analysis blocks for + step
            [~, ~, ~, ~, ~, ~, ~, ~, ~, ~,...
                ~, ~, ~, ~, ~, ~, ~, ~, ~, ~,...
                 Dph, ~, ~, ~, ~] = ...
                 analysis_blocks_v2_03(caseName,jinputsph, newhubRadph, parentFolder, airfoils, numel);
    
            % Analysis blocks for - step
            [~, ~, ~, ~, ~, ~, ~, ~, ~, ~,...
                ~, ~, ~, ~, ~, ~, ~, ~, ~, ~,...
                 Dmh, ~, ~, ~, ~] = ...
                 analysis_blocks_v2_03(caseName,jinputsmh, newhubRadmh, parentFolder, airfoils, numel);
    
            % Compute the derivative and update proposedR
            dflprime = (Dph(1, end) - Dmh(1, end)) / (2 * step);
            proposedRnew = proposedR - (D(1, end) - crefjamiesonsCase(1).D(1, end)) / dflprime;
    
            % Check for divergence (inf or NaN)
            if ~isfinite(proposedRnew)
                fprintf('Divergence detected (proposedRnew is %f) for initial guess %f.\n', proposedRnew, proposedR);
                break; % Exit the inner loop to retry with a new guess
            end
    
            % Update convergence indicator
            indicator = abs(proposedRnew - proposedR);
    
            % Update proposedR for the next iteration
            proposedR = proposedRnew;
        end
    
        % Check if a valid solution was found
        if indicator <= tolerance
            fprintf('Converged to %f after %d iterations.\n', proposedR, iter);
            break; % Exit the outer loop
        end
    
        % Increment to the next initial guess
        current_guess_index = current_guess_index + 1;
    end
    
    % Check if no solution was found
    if current_guess_index > length(initial_guesses)
        error('Newton-Raphson failed to converge with all initial guesses.');
    end

end

%bisection method
function [jinputs,ajam,apjam,jamchord,jamtwist,newhubRad,relWind,a,ap,amids,...
            apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
            ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,crefmoment,blade,D,R,F,L,Ks]=...
            bisection_run...
            (crefjamiesonsCase,crefmoment,wndspeed,a_in,...
            n_in,p_in,crefnewhubRad,numblades,jinputs,parentFolder,airfoils,numel)

            step=1;
    
            %Yeah I know, its a bit iffy to code it this way but im lazy
            %and this works. crefjamiesonsCase is your refBlade. I'm just
            %using that name because its more convenient
            caseName=getVarName(crefjamiesonsCase);
    %iteration counts
    max_iter = 100; % Maximum iterations to avoid infinite looping
    tolerance = 1e-1; % Convergence tolerance
    
    bounds=[0.5 1.5]*(crefjamiesonsCase.blade.ispan(end)+crefnewhubRad);
    % Loop over initial guesses
    
    indicator = Inf; % Set indicator to a large value to start the loop
    iter = 0; % Initialize iteration counter
        
    a=bounds(1);
    b=bounds(2);
         while (a - b) / 2 > tolerance
            iter = iter + 1;
            if iter > max_iter
                fprintf('Maximum iterations reached for initial guess %f.\n', proposedR);
                break;
            end
            
            c=(a - b) / 2;
            % Perform computations for lb
            [jinputshb, ajamhb, apjamhb, jamchordhb, jamtwisthb, newhubRadhb] = jamieson_v2_02_tipdfl(crefjamiesonsCase, ...
                crefmoment, wndspeed, a_in, n_in, p_in, crefnewhubRad, numblades, jinputs, ...
                parentFolder, airfoils, a);
    
            % Perform computations for hb
            [jinputslb, ajamlb, apjamlb, jamchordlb, jamtwistlb, newhubRadlb] = jamieson_v2_02_tipdfl(crefjamiesonsCase, ...
                crefmoment, wndspeed, a_in, n_in, p_in, crefnewhubRad, numblades, jinputs, ...
                parentFolder, airfoils, b);

             % Perform computations for c
            [jinputs, ajam, apjam, jamchord, jamtwist, newhubRad] = jamieson_v2_02_tipdfl(crefjamiesonsCase, ...
                crefmoment, wndspeed, a_in, n_in, p_in, crefnewhubRad, numblades, jinputs, ...
                parentFolder, airfoils, b);
    
            %diagnostic plot
            % figure()
            % plot(crefjamiesonsCase.blade.ispan,a,crefjamiesonsCase.blade.ispan,ajam)
            % figure()
            % plot(crefjamiesonsCase.blade.ispan,jamchord,jinputs.("span (r) [m]"),jinputs.("chord"))
            % Analysis blocks for + step
            
            % Do analysis blocks for hb
            [~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~,...
                 Dhb, ~, ~, ~, ~] = ...
                 analysis_blocks_v2_03(caseName,jinputslb, newhubRadlb, parentFolder, airfoils, numel);

            % Do analysis blocks for lb
            [~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~,...
                 Dlb, ~, ~, ~, ~] = ...
                 analysis_blocks_v2_03(caseName,jinputslb, newhubRadlb, parentFolder, airfoils, numel);
    
            % Do analysis blocks for lb
            [relWind, a, ap, amids, apmids, cpvector, ctvector, rmids, cmvector, cpmids, ...
                ctmids, cmmids, ocp, oct, ocm, dT, dQ, totalpwr, crefmoment, blade, D, R, F, L, Ks] = ...
                analysis_blocks_v2_03(caseName,jinputs, newhubRad, parentFolder, airfoils, numel);
    
            fhb=Dhb(1,end)-crefjamiesonsCase(1).D(1, end);
            flb=Dlb(1,end)-crefjamiesonsCase(1).D(1, end);
            fc=D(1,end)-crefjamiesonsCase(1).D(1, end);
            if fhb * flb >= 0
                error('f(a) and f(b) must have opposite signs.');
            end

            if abs(fc) < tolerance  % If f(c) is close to zero, root found
                fprintf('Converged to %f after %d iterations.\n', c, iter);
                break;
            elseif f(a) * fc < 0 % Root is in [a, c]
                b = c;
            else  % Root is in [c, b]
                a = c;
            end
    
         end
end

function varName = getVarName(var)
    varName = inputname(1); % Get the name of the first input argument
end