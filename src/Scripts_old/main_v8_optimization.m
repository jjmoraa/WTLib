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
    =analysis_blocks_v2_01...
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

    %reference case plots
    figure('Name', 'PreComp Analysis Results');
    data = [blade.secprops.data]; % Concatenate results to form 'data'
    for i = 2:size(data, 2)
        subplot(5, 5, i);
        plot(data(:, 1), data(:, i), 'b-o');
        xlabel(strrep(blade.secprops.labels{1}, '_', '\_'));
        ylabel(strrep(blade.secprops.labels{i}, '_', '\_'));
    end

    figure('Name', 'BEM Parameters');
    plot(blade.ispan+hubRad,referenceCase.a,blade.ispan+hubRad,referenceCase.ap)
    hold on
    plot(rmids,referenceCase.cpmids,rmids,referenceCase.ctmids,rmids,referenceCase.cmmids)
    xlabel('Span [m]')
    ylabel('[-]')
    legend('a','ap','cp','ct','cm','Location','Southwest')

    figure('Name', 'Summary of performance calculations');
    plot(rmids,dT,rmids,dQ)
    xlabel('Span [m]')
    ylabel('Force [N], Torque [Nm]')
    legend('dT','dQ','Location','Southwest')

    figure('Name', 'Deflection');
    plot(blade.ispan,D(2,:))
    xlabel('Span [m]')
    ylabel('Deflection [m]')
    %legend('dT','dQ','Location','Southwest')

%% Define the optimization problem 
 % Initial guess for the optimization variables
    x=[0.3,0.5,0.5];
    step_size = 0.01; % Finite difference step size
    tol = 1e-6; % Convergence tolerance
    max_iter = 1000; % Maximum number of iterations
    h = 1e-6;   
    learning_rate=1e-6;
    x_min = [0.1, 0.1, 0.1];
    x_max = [1/3, 1, 1];

    [jinputs,ajam,apjam,jamchord,jamtwist,newhubRad]...
                =jamieson_v2_01(referenceCase,refmoment,wndspeed,x(1),...
                x(2),x(3),hubRad,3,inputs,parentFolder,airfoils);
    
    [relWind,a,ap,amids,apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
                    ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,moment,blade,D,R,F,L,Ks]...
                    =analysis_blocks_v2_01...
                    (jinputs,newhubRad,parentFolder,airfoils,numel);
    f_opt=totalpwr;

    for iter=1:max_iter
        grad(iter,:)=finite_difference_gradient(x,h,referenceCase,refmoment,wndspeed,...
            hubRad,3,inputs,parentFolder,airfoils,numel);

    % Update the variables using gradient descent
        x_new = x - learning_rate * grad(iter,:);

    % Evaluate the new pragoint
    
        % [jinputs_new,ajam_new,apjam_new,jamchord_new,jamtwist_new,newhubRad_new]...
        %         =jamieson_v2_01(referenceCase,refmoment,wndspeed,x_new(1),...
        %         x_new(2),x_new(3),hubRad,3,inputs,parentFolder,airfoils);
        % 
        % [relWind_new,a_new,ap_new,amids_new,apmids_new,cpvector_new,ctvector_new,rmids_new,cmvector_new,cpmids_new,...
        %             ctmids_new,cmmids_new,ocp_new,oct_new,ocm_new,dT_new,dQ_new,totalpwr_new,moment_new,blade_new,D_new,R_new,F_new,L_new,Ks_new]...
        %             =analysis_blocks_v2_01...
        %             (jinputs,newhubRad,parentFolder,airfoils,numel);

        % f_new = totalpwr_new;
        % Apply bounds using projection
        x_new = max(min(x_new, x_max), x_min);

        % Check for convergence
        if norm(x_new - x) < tol
            break;
        end
        
        % Update variables for next iteration
        x = x_new;
        fprintf('ITERATION %d \n',iter)
        disp(x)
        pause(0.1)
    end
    
    x_opt = x;
end



delete(gcp('nocreate'))




function grad=finite_difference_gradient(x,h,referenceCase,refmoment,wndspeed,...
            hubRad,blades,inputs,parentFolder,airfoils,numel)
    grad=zeros(1,3);
    n=length(grad);
    % Create a matrix where each column is x with a small step in one dimension
    e = eye(n) * h; % Identity matrix scaled by h
    x_forw=x+e;

        %forward finite difference
        [jinputs,ajam,apjam,jamchord,jamtwist,newhubRad]...
                =jamieson_v2_01(referenceCase,refmoment,wndspeed,x(1),...
                x(2),x(3),hubRad,blades,inputs,parentFolder,airfoils);
    
        [relWind,a,ap,amids,apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
                    ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,moment,blade,D,R,F,L,Ks]...
                    =analysis_blocks_v2_01...
                    (jinputs,newhubRad,parentFolder,airfoils,numel);

        for i=1:n
        % Create a matrix where each column is x with a small step in one dimension
            e = eye(n) * h; % Identity matrix scaled by h
            x_forw=x+e(i,:);
            x_back=x-e(i,:);
        [jinputs_forw,ajam_forw,apjam_forw,jamchord_forw,jamtwist_forw,newhubRad_forw]...
                =jamieson_v2_01(referenceCase,refmoment,wndspeed,x_forw(1),...
                x_forw(2),x_forw(3),hubRad,blades,inputs,parentFolder,airfoils);
    
        [relWind_forw,a_forw,ap_forw,amids_forw,apmids_forw,cpvector_forw,ctvector_forw,rmids_forw,cmvector_forw,cpmids_forw,...
                    ctmids_forw,cmmids_forw,ocp_forw,oct_forw,ocm_forw,dT_forw,dQ_forw,totalpwr_forw,moment_forw,blade_forw,D_forw,R_forw,F_forw,L_forw,Ks_forw]...
                    =analysis_blocks_v2_01...
                    (jinputs_forw,newhubRad_forw,parentFolder,airfoils,numel);

        [jinputs_back,ajam_back,apjam_back,jamchord_back,jamtwist_back,newhubRad_back]...
                =jamieson_v2_01(referenceCase,refmoment,wndspeed,x_back(1),...
                x_back(2),x_back(3),hubRad,blades,inputs,parentFolder,airfoils);
    
        [relWind_back,a_back,ap_back,amids_back,apmids_back,cpvector_back,ctvector_back,rmids_back,cmvector_back,cpmids_back,...
                    ctmids_forw,cmmids_forw,ocp_forw,oct_forw,ocm_forw,dT_forw,dQ_forw,totalpwr_back,moment_forw,blade_forw,D_forw,R_forw,F_back,L_back,Ks_back]...
                    =analysis_blocks_v2_01...
                    (jinputs_forw,newhubRad_forw,parentFolder,airfoils,numel);

        f_x_forw = totalpwr_forw;
        f_x_back = totalpwr_back;
        f_x= totalpwr;
        grad(i)=(f_x_forw - f_x_back)/(2*h);
        end
end