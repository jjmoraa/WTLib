%main v4
%Code by Jose Mora @ UMass
%This one allows reading multiple section files
close all
clear
clc
%%
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

%define folder for variable saving and all that
%save the powertable
scriptName = mfilename; % Get the script name
currentDate = datestr(now, 'yyyy-mm-dd_HH-MM-SS'); % Get the current date
filename = sprintf('%s_%s.mat', scriptName, currentDate); % Create the filename
foldername = [parentFolder, '/Results/NAWEA_25_submission/', sprintf('%s_%s/', scriptName, currentDate)]; % Create the filename
if ~isfolder(foldername)
    mkdir(foldername);
end

for count=3
    numel=cases(count);
    referenceCase=struct([]);
    inputs = array2table(cell2mat(inputs),'VariableNames',{'span (r) [m]','not used1','not used2','not used3','twist','chord','airfoil no','not used4','not used5','not used6'});
    
    %% reference case run
    tic
    
    %This runs the analysis blocks
    [relWind,a,ap,amids,apmids,cpvector,ctvector,rmids,cmvector_ref,cpmids,...
    ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,mass,refmoment,blade,D,R,F,L,Ks,COE,AEP]...
    =analysis_blocks_v3_00...
    ('referenceCase',inputs,hubRad,parentFolder,airfoils,numel);
    
    %This saves all the variables of this reference case
    referenceCase =...
    variable_saving(1,1,1,a,ap,amids,apmids,ocp,oct,ocm,cpmids,ctmids,...
    cmmids,dT,dQ,totalpwr,refmoment,mass,blade,rmids,hubRad,D,R,F,L,Ks,COE,AEP,...
    [parentFolder,'\Results\NAWEA_25_submission'],'referenceCase');
    
    %Plotting all the reference case plots
    plottingCase(referenceCase,parentFolder,'NAWEA_25_submission','referenceCase')
    
    time1=toc
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
    saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','RefCase','equivalent fit.jpg'])
    %legend('dT','dQ','Location','Southwest')

%% modified reference case for root moment algorithm
    tic
    [crefjinputs_rootmom,ajam_rootmom,apjam_rootmom,jamchord_rootmom,jamtwist_rootmom,...
    crefnewhubRad_rootmom,relWind_rootmom,a_rootmom,ap_rootmom,amids_rootmom,...
    apmids_rootmom,cpvector_rootmom,ctvector_rootmom,rmids_rootmom,...
    cmvector_rootmom,cpmids_rootmom,ctmids_rootmom,cmmids_rootmom,...
    ocp_rootmom,oct_rootmom,ocm_rootmom,dT_rootmom,dQ_rootmom,totalpwr_rootmom,...
    crefmass_rootmom,crefmoment_rootmom,blade_rootmom,D_rootmom,R_rootmom,...
    F_rootmom,L_rootmom,Ks_rootmom,COE_rootmom,AEP_rootmom]=...
        moment_matching...
    (referenceCase,refmoment,wndspeed,fitcurve.a,...
    fitcurve.n,fitcurve.p,hubRad,3,inputs,parentFolder,airfoils,numel);
    %crefmass=sum(cell2mat(blade.secprops.data(:,18)*(blade.ispan(2)-blade.ispan(1))));
    
    %This saves all the variables of this reference case
    crefjamiesonsCase_rootmom =...
    variable_saving(1,1,1,a_rootmom,ap_rootmom,amids_rootmom,apmids_rootmom,...
    ocp_rootmom,oct_rootmom,ocm_rootmom,cpmids_rootmom,ctmids_rootmom,...
    cmmids_rootmom,dT_rootmom,dQ_rootmom,totalpwr_rootmom,crefmoment_rootmom,...
    crefmass_rootmom,blade_rootmom,rmids_rootmom,crefnewhubRad_rootmom,D_rootmom,...
    R_rootmom,F_rootmom,L_rootmom,Ks_rootmom,COE_rootmom,AEP_rootmom,...
    [parentFolder,'\Results\NAWEA_25_submission'],'crefjamiesonsCase_rootmom');
    
    %Plotting all the reference case plots [not for MDO submission]
        %plottingCase(crefjamiesonsCase,parentFolder,'root_moment_MDO','crefJamiesonsCase')
        
    time2=toc
    % aprox 210 seg or 3:30 min

%% modified reference case for tip deflection algorithm
    tic
    [crefjinputs_tipdfl,ajam_tipdfl,apjam_tipdfl,jamchord_tipdfl,jamtwist_tipdfl,...
    crefnewhubRad_tipdfl,relWind_tipdfl,a_tipdfl,ap_tipdfl,amids_tipdfl,...
    apmids_tipdfl,cpvector_tipdfl,ctvector_tipdfl,rmids_tipdfl,...
    cmvector_tipdfl,cpmids_tipdfl,ctmids_tipdfl,cmmids_tipdfl,...
    ocp_tipdfl,oct_tipdfl,ocm_tipdfl,dT_tipdfl,dQ_tipdfl,totalpwr_tipdfl,...
    crefmass_tipdfl,crefmoment_tipdfl,blade_tipdfl,D_tipdfl,R_tipdfl,...
    F_tipdfl,L_tipdfl,Ks_tipdfl,COE_tipdfl,AEP_tipdfl]=...
        newtons_run...
    (referenceCase,refmoment,wndspeed,fitcurve.a,...
    fitcurve.n,fitcurve.p,hubRad,3,inputs,parentFolder,airfoils,numel);
    
    %This saves all the variables of this reference case
    crefjamiesonsCase_tipdfl =...
    variable_saving(1,1,1,a_tipdfl,ap_tipdfl,amids_tipdfl,apmids_tipdfl,...
    ocp_tipdfl,oct_tipdfl,ocm_tipdfl,cpmids_tipdfl,ctmids_tipdfl,...
    cmmids_tipdfl,dT_tipdfl,dQ_tipdfl,totalpwr_tipdfl,crefmoment_tipdfl,...
    crefmass_tipdfl,blade_tipdfl,rmids_tipdfl,crefnewhubRad_tipdfl,D_tipdfl,...
    R_tipdfl,F_tipdfl,L_tipdfl,Ks_tipdfl,COE_tipdfl,AEP_tipdfl,...
    [parentFolder,'\Results\NAWEA_25_submission'],'crefjamiesonsCase_tipdfl');

    %Plotting all the reference case plots [not for MDO submission]
        %plottingCase(crefjamiesonsCase,parentFolder,'tip_dfl','crefJamiesonsCase')
        
    time3=toc
% aprox 210 seg or 3:30 min

%% save the reference blades

save(foldername,'referenceCase','crefjamiesonsCase_rootmom','crefjamiesonsCase_tipdfl',...
    'crefjinputs_rootmom','crefjinputs_tipdfl'); % Save the reference cases

%% Plotting the comparisson between reobtained reference blades for root moment and tip deflection

    fig=figure('Name', 'BEM Parameters all references');
    plot(crefjamiesonsCase_rootmom.blade.ispan+crefnewhubRad_rootmom,crefjamiesonsCase_rootmom.a,...
        crefjamiesonsCase_rootmom.blade.ispan+crefnewhubRad_rootmom,crefjamiesonsCase_rootmom.ap,...
        crefjamiesonsCase_tipdfl.blade.ispan+crefnewhubRad_tipdfl,crefjamiesonsCase_tipdfl.a,...
        crefjamiesonsCase_tipdfl.blade.ispan+crefnewhubRad_tipdfl,crefjamiesonsCase_tipdfl.ap,...
        'LineWidth',5)
    hold on
    plot(referenceCase.blade.ispan+hubRad,referenceCase.a,...
        referenceCase.blade.ispan+hubRad,referenceCase.ap,...
        'LineWidth',5)
    xlabel('Span [m]')
    ylabel('[-]')
    legend('a_{mom}','ap_{mom}','a_{dfl}','ap_{dfl}','a_{ref}','ap_{ref}','Location','Southwest')
    fontsize(gcf,scale=1.2)
    saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase',...
        'BEM Parameters all references.jpg'])    
    
    %Deflection plots for all references
    fig=figure('Name', 'Deflection all references');
    plot(crefjamiesonsCase_rootmom.blade.ispan,crefjamiesonsCase_rootmom.D(1,:),...
        crefjamiesonsCase_tipdfl.blade.ispan,crefjamiesonsCase_tipdfl.D(1,:),...
        'LineWidth',5)
    hold on
    plot(referenceCase.blade.ispan,referenceCase.D(1,:),'LineWidth',5)
    xlabel('Span [m]')
    ylabel('Deflection [m]')
    legend('dfl_{mom}','dfl_{dfl}','dfl_{ref}','Location','southeast')
    saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase','Deflection all references.jpg'])
    %legend('dT','dQ','Location','Southwest')

    %Moment plots for all references
    fig=figure('Name', 'Moment coefficient all references');
    plot(crefjamiesonsCase_rootmom.blade.ispan,cmvector_rootmom,...
        crefjamiesonsCase_tipdfl.blade.ispan,cmvector_tipdfl,...
        'LineWidth',5)
    hold on
    plot(referenceCase.blade.ispan,cmvector_ref,'LineWidth',5)
    xlabel('Span [m]')
    ylabel('c_m [-]')
    legend('c_{m,mom}','c_{m,dfl}','c_{m,ref}','Location','southeast')
    saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase','Momentcoeff all references.jpg'])
    %legend('dT','dQ','Location','Southwest')


%% jamiesons case for Moment Match
tic
%3 is the isoline im taking as a treshold (30% difference) and 10 the
%resoution of points in x
%function grid_points=JamiesonsBoundGenerator(a0,n_ref,p_ref,curve,n_min,n_max,resolution)
grid_points=JamiesonsBoundGenerator(fitcurve.a,fitcurve.n,fitcurve.p,8,fitcurve.p,6,20);

powertable_rootmom = table([], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], 'VariableNames', {'A','n','p','a','ap','ocp','oct','ocm','total power','cpR^2','blade span', 'tip deflection','moment','mass','COE','AEP'});
fprintf('a_in   n_in    p_in\n')
jamiesonsCaseMomMatch=struct([]);

%Future=parallel.FevalFuture;
index=0;

for index=1:length(grid_points)
%for index=[11,255,278]
    %for n_in=nbounds(1):nbounds(2):nbounds(3) %concave <1 convex
        %for p_in=pbounds(1):pbounds(2):pbounds(3)
            a_in=fitcurve.a;
            n_in=grid_points(index,1);
            p_in=grid_points(index,2);
            fprintf('%4.4f %4.4f %4.4f \n',a_in,n_in,p_in)

            [jinputs,ajam,apjam,jamchord,jamtwist,newhubRad,relWind,a,ap,amids,...
            apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
            ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr, mass, newjammoment,blade,D,R,F,L,Ks,COE,AEP]=...
            moment_matching...
            (crefjamiesonsCase_rootmom,crefmoment_rootmom,wndspeed,a_in,...
            n_in,p_in,crefnewhubRad_rootmom,3,crefjinputs_rootmom,parentFolder,airfoils,numel);
         
            jamiesonsCaseMomMatch(index).n=n_in;
            jamiesonsCaseMomMatch(index).p=p_in;
            jamiesonsCaseMomMatch(index).a=a;
            jamiesonsCaseMomMatch(index).ap=ap;
            jamiesonsCaseMomMatch(index).amids=amids;
            jamiesonsCaseMomMatch(index).apmids=apmids;
            jamiesonsCaseMomMatch(index).ocp=ocp;
            jamiesonsCaseMomMatch(index).oct=oct;
            jamiesonsCaseMomMatch(index).ocm=ocm;
            jamiesonsCaseMomMatch(index).cpmids=cpmids;
            jamiesonsCaseMomMatch(index).ctmids=ctmids;
            jamiesonsCaseMomMatch(index).cmmids=cmmids;
            jamiesonsCaseMomMatch(index).dT=dT;
            jamiesonsCaseMomMatch(index).dQ=dQ;
            jamiesonsCaseMomMatch(index).totalpwr=totalpwr;
            jamiesonsCaseMomMatch(index).blade=blade;
            jamiesonsCaseMomMatch(index).rmids=rmids;
            jamiesonsCaseMomMatch(index).hubRad=newhubRad;
            jamiesonsCaseMomMatch(index).D=D;
            jamiesonsCaseMomMatch(index).R=R;
            jamiesonsCaseMomMatch(index).F=F;
            jamiesonsCaseMomMatch(index).L=L;
            jamiesonsCaseMomMatch(index).Ks=Ks;
            jamiesonsCaseMomMatch(index).mass=mass;
            jamiesonsCaseMomMatch(index).moment=newjammoment;
            jamiesonsCaseMomMatch(index).COE=COE;
            jamiesonsCaseMomMatch(index).AEP=AEP;

            % WARNING WARNING WARNING NORMAILIZING BY REF BLADE
                    % TPDFL FOR ABSTRACT JUST BC OF BUG
     %add case to results table
                newRow={a_in,n_in,p_in,a,ap,ocp,oct,ocm,totalpwr/crefjamiesonsCase_rootmom.totalpwr...
                    ,(ocp*blade.span(end)^2)/(crefjamiesonsCase_rootmom.ocp*crefjamiesonsCase_rootmom.blade.span(end)^2),...
                    jamiesonsCaseMomMatch(index).blade.ispan(end)/crefjamiesonsCase_rootmom.blade.span(end),D(1,end)/referenceCase.D(1,end),newjammoment/crefmoment_rootmom,mass/crefmass_rootmom,COE/referenceCase.COE,AEP/AEP_rootmom};
                %D1=[jamiesonsCase(a_in,n_in,p_in).ocp,jamiesonsCase(a_in,n_in,p_in).oct,jamiesonsCase(a_in,n_in,p_in).ocm,jamiesonsCase(a_in,n_in,p_in).totalpwr,jamiesonsCase(a_in,n_in,p_in).blade.span(end),jamiesonsCase(a_in,n_in,p_in).D(3,end)];
                %D2=[referenceCase.ocp,referenceCase.oct,referenceCase.ocm,referenceCase.totalpwr,referenceCase.blade.span(end),referenceCase.D(3,end)];
                %P=[D1;D2];
                %spider_plot(P,'AxesLabels', {'ocp', 'oct', 'ocm', 'totalpwr', 'R' ,'tipdfl'})
                powertable_rootmom=[powertable_rootmom;newRow];
end
    
save([foldername,'/rootmoment'], 'powertable_rootmom'); % Save the variable

time4=toc
%% jamiesons case for Tip dfl match
tic
%3 is the isoline im taking as a treshold (30% difference) and 10 the
%resoution of points in x
%function grid_points=JamiesonsBoundGenerator(a0,n_ref,p_ref,curve,n_min,n_max,resolution)
%used in MDO Submission: grid_points=JamiesonsBoundGenerator(fitcurve.a,fitcurve.n,fitcurve.p,8,fitcurve.p,5,20);
grid_points=JamiesonsBoundGenerator(fitcurve.a,fitcurve.n,fitcurve.p,8,fitcurve.p,6,10);

grid_points=[grid_points;[5.245 1.465];[5.25 1.475];[5.26 1.48]];
% Define ranges
%n_vals = linspace(5.24, 5.26, 5);  % replace N with how fine you want the grid (e.g., 20)
%p_vals = linspace(1.46, 1.48, 5);

% Create grid
%[NMESH, PMESH] = meshgrid(n_vals, p_vals);

% Stack into N×2 array of [n, p] coordinates
%grid_points = [NMESH(:), PMESH(:)];
% grid_points = [5.25, 1.475];

powertable_tipdfl = table([], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], 'VariableNames', {'A','n','p','a','ap','ocp','oct','ocm','total power','cpR^2','blade span', 'tip deflection','moment','mass','COE','AEP'});
fprintf('a_in   n_in    p_in\n')
jamiesonsCaseTipDfl=struct([]);

%Future=parallel.FevalFuture;
index=0;

% if exist('h','var')
%     close(h)
% end

h = waitbar(0, sprintf('Processing point 1 of %d', length(grid_points)));
bar = waitbar(0, 'counting converged...');  % Create the waitbar
converged=0;
for index=1:length(grid_points)
%for index=3
%for a_in=32
    %for n_in=nbounds(1):nbounds(2):nbounds(3) %concave <1 convex
        %for p_in=pbounds(1):pbounds(2):pbounds(3)
            a_in=fitcurve.a;
            
            % n_in=4.94;
            % p_in=0.76;
            n_in=grid_points(index,1);
            p_in=grid_points(index,2);
            fprintf('%4.4f %4.4f %4.4f \n',a_in,n_in,p_in)

            [jinputs,ajam,apjam,jamchord,jamtwist,newhubRad,relWind,a,ap,amids,...
            apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
            ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,mass,newjammoment,blade,D,R,F,L,Ks,COE,AEP]=...
            modified_false_position_run...
            (crefjamiesonsCase_tipdfl,crefmoment_tipdfl,wndspeed,a_in,...
            n_in,p_in,crefnewhubRad_tipdfl,3,crefjinputs_tipdfl,parentFolder,airfoils,numel);
         
            jamiesonsCaseTipDfl(index).n=n_in;
            jamiesonsCaseTipDfl(index).p=p_in;
            jamiesonsCaseTipDfl(index).a=a;
            jamiesonsCaseTipDfl(index).ap=ap;
            jamiesonsCaseTipDfl(index).amids=amids;
            jamiesonsCaseTipDfl(index).apmids=apmids;
            jamiesonsCaseTipDfl(index).ocp=ocp;
            jamiesonsCaseTipDfl(index).oct=oct;
            jamiesonsCaseTipDfl(index).ocm=ocm;
            jamiesonsCaseTipDfl(index).cpmids=cpmids;
            jamiesonsCaseTipDfl(index).ctmids=ctmids;
            jamiesonsCaseTipDfl(index).cmmids=cmmids;
            jamiesonsCaseTipDfl(index).dT=dT;
            jamiesonsCaseTipDfl(index).dQ=dQ;
            jamiesonsCaseTipDfl(index).totalpwr=totalpwr;
            jamiesonsCaseTipDfl(index).blade=blade;
            jamiesonsCaseTipDfl(index).rmids=rmids;
            jamiesonsCaseTipDfl(index).hubRad=newhubRad;
            jamiesonsCaseTipDfl(index).D=D;
            jamiesonsCaseTipDfl(index).R=R;
            jamiesonsCaseTipDfl(index).F=F;
            jamiesonsCaseTipDfl(index).L=L;
            jamiesonsCaseTipDfl(index).Ks=Ks;
            jamiesonsCaseTipDfl(index).mass=mass;
            jamiesonsCaseTipDfl(index).moment=newjammoment;
            jamiesonsCaseTipDfl(index).COE=COE;
            jamiesonsCaseTipDfl(index).AEP=AEP;
            
            
%%            

            if blade==0
                bladespan=0;
            else
                bladespan=jamiesonsCaseTipDfl(index).blade.ispan(end);
                converged=converged+1;
            end
     %add case to results table
                newRow={a_in,n_in,p_in,a,ap,ocp,oct,ocm,totalpwr/crefjamiesonsCase_tipdfl.totalpwr...
                    ,(ocp*bladespan^2)/(crefjamiesonsCase_tipdfl.ocp*crefjamiesonsCase_tipdfl.blade.span(end)^2)...
                    ,bladespan/crefjamiesonsCase_tipdfl.blade.span(end),D(1,end)/crefjamiesonsCase_tipdfl.D(1,end),newjammoment/crefmoment_tipdfl,mass/crefmass_tipdfl,COE/COE_tipdfl,AEP/AEP_tipdfl};
                %D1=[jamiesonsCase(a_in,n_in,p_in).ocp,jamiesonsCase(a_in,n_in,p_in).oct,jamiesonsCase(a_in,n_in,p_in).ocm,jamiesonsCase(a_in,n_in,p_in).totalpwr,jamiesonsCase(a_in,n_in,p_in).blade.span(end),jamiesonsCase(a_in,n_in,p_in).D(3,end)];
                %D2=[referenceCase.ocp,referenceCase.oct,referenceCase.ocm,referenceCase.totalpwr,referenceCase.blade.span(end),referenceCase.D(3,end)];
                %P=[D1;D2];
                %spider_plot(P,'AxesLabels', {'ocp', 'oct', 'ocm', 'totalpwr', 'R' ,'tipdfl'})

                waitbar(index/length(grid_points), h, sprintf('Processing point %d of %d', index, length(grid_points)));
                waitbar(index/length(grid_points), bar, sprintf('converged %d of %d', converged, length(grid_points)));
                
                powertable_tipdfl=[powertable_tipdfl;newRow];
end

save([foldername,'/tipdfl'], 'powertable_tipdfl'); % Save the variable

time5=toc
close(h)
%% kill parallel
delete(gcp('nocreate'))
%% plots

%For the root bending moment case and tip deflection case, plots are the
%same, except for root bending moment we have tip dfl and for tip dfl we
%have root bending moment

%RBM
fig = plotHeatmapFromTable(powertable_rootmom, 'n','p', 'moment');


fig = plotHeatmapFromTable(powertable_rootmom, 'n','p', 'ocp');
saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase','cpjheatmap_rootmom.jpg'])
fig = plotHeatmapFromTable(powertable_rootmom, 'n','p', 'blade span');
saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase','bladespanjheatmap_rootmom.jpg'])
fig = plotHeatmapFromTable(powertable_rootmom, 'n','p', 'cpR^2');
saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase','cpr2heatmap_rootmom.jpg'])

mod_power_table = powertable_rootmom(powertable_rootmom.('tip deflection') ~= 0, :);

fig = plotHeatmapFromTable(mod_power_table, 'n','p', 'tip deflection');
saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase','tipdflheatmap_rootmom.jpg'])

%%
%TIPDFL
mod_powertable_tipdfl=powertable_tipdfl(powertable_tipdfl.('ocp') ~=0,:);

fig = plotHeatmapFromTable(mod_powertable_tipdfl, 'n','p', 'ocp');
saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase','cpjheatmap_tipdfl.jpg'])
fig = plotHeatmapFromTable(mod_powertable_tipdfl, 'n','p', 'blade span');
saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase','bladespanjheatmap_tipdfl.jpg'])
fig = plotHeatmapFromTable(mod_powertable_tipdfl, 'n','p', 'cpR^2');
saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase','cpr2heatmap_tipdfl.jpg'])
fig = plotHeatmapFromTable(mod_powertable_tipdfl, 'n','p', 'moment');
saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase','momentheatmap_tipdfl.jpg'])

    %surface plots [don't need them for MDO submission]
% fig=plotSurfaceFromTable(powertable_rootmom, 'n','p', 'total power');
% fig.Position = [100, 100, 800, 600];  % [left, bottom, width, height]
% saveas(fig,[parentFolder,'/Results/root_moment_MDO/','CRefCase','totalpowerjsurf.jpg'])
% fig=plotSurfaceFromTable(powertable_rootmom, 'n','p', 'blade span');
% saveas(fig,[parentFolder,'/Results/root_moment_MDO/','CRefCase','radiusjsurf.jpg'])
% fig=plotSurfaceFromTable(powertable_rootmom, 'n','p', 'cpR^2');
% saveas(fig,[parentFolder,'/Results/root_moment_MDO/','CRefCase','cpr2surf.jpg'])
% fig=plotSurfaceFromTable(mod_power_table, 'n','p', 'tip deflection');
% saveas(fig,[parentFolder,'/Results/root_moment_MDO/','CRefCase','tipdfljsurf.jpg'])
end

%% Paretos

[fig,modpowertable,paretoX, paretoY, idx, globalidx]=ParetoFront_v3(powertable_rootmom,'cpR^2','blade span','mass'); %max, min
saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase','ParetoCpr2spanmass.jpg'])
fig=Important_plotter(idx,modpowertable,fitcurve.a,fitcurve.n,fitcurve.p);
saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase','ParetocurvesCpr2spanmass.jpg'])

[fig,modpowertable,paretoX, paretoY, idx, globalidx]=ParetoFront_v3(powertable_rootmom,'cpR^2','blade span','tip deflection'); %max, min
saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase','ParetoCpr2spantipdfl.jpg'])
fig=Important_plotter(idx,modpowertable,fitcurve.a,fitcurve.n,fitcurve.p);
saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase','ParetocurvesCpr2spantipdfl.jpg'])

powertable_rootmom_closeup=powertable_rootmom(powertable_rootmom.('mass')<1.30,:);
%powertable_rootmom_closeup=powertable_rootmom_closeup(powertable_rootmom_closeup.('blade span')<1.15,:);

[fig,modpowertable,paretoX, paretoY, idx, globalidx]=ParetoFront_v3(powertable_rootmom_closeup,'cpR^2','blade span','mass'); %max, min
saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase','ParetoCpr2spanmass_closeup.jpg'])
fig=Important_plotter(idx,modpowertable,fitcurve.a,fitcurve.n,fitcurve.p);
saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase','ParetocurvesCpr2spanmass_closeup.jpg'])

[fig,modpowertable,paretoX, paretoY, idx, globalidx]=ParetoFront_v3(powertable_rootmom,'cpR^2','tip deflection','mass'); %max, min
saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase','ParetoCpr2tipdflmass.jpg'])
fig=Important_plotter(idx,modpowertable,fitcurve.a,fitcurve.n,fitcurve.p);
saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase','ParetocurvesCpr2tipdflmass.jpg'])

[fig,modpowertable,paretoX, paretoY, idx, globalidx]=ParetoFront_v3(mod_powertable_tipdfl,'cpR^2','blade span','mass'); %max, min
saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase','ParetoCpr2spanmass_tipdfl.jpg'])
fig=Important_plotter(idx,modpowertable,fitcurve.a,fitcurve.n,fitcurve.p);
saveas(fig,[parentFolder,'/Results/NAWEA_25_submission/','CRefCase','ParetocurvesCpr2spanmass_tipdfl.jpg'])

% here's how youd locate an index in the big table and consequently on the
% big jamiesons case structure
%% comparisson plots

% powertable=[powertable_rootmom_closeup;powertable_tipdfl];

% find the cases you want to see in powertable using
% rowIndex = find(all(abs([powertable.('n'), powertable.('p')] - [3.7957, 0.87103]) < 1e-3, 2))
% rowIndex = find(all(abs([powertable.('cpR^2'), powertable.('blade span')] - [1.11, 1.12]) < 1e-2, 2))

rowIndex1 = find(all(abs([powertable_rootmom.('blade span'), powertable_rootmom.('cpR^2')] - [1.11756, 1.12245]) < 1e-4, 2)); %index11
% rowIndex2 = find(all(abs([powertable_rootmom.('blade span'), powertable_rootmom.('cpR^2')] - [1.15521, 1.13476]) < 1e-4, 2));
% rowIndex3 = find(all(abs([powertable_rootmom.('blade span'), powertable_rootmom.('cpR^2')] - [1.09598, 1.11248]) < 1e-4, 2));
rowIndex2 = find(all(abs([powertable_rootmom.('blade span'), powertable_rootmom.('cpR^2')] - [1.04741, 1.07117]) < 1e-4, 2));%index 278
%rowIndex4 = find(all(abs([powertable_rootmom.('blade span'), powertable_rootmom.('cpR^2')] - [1.04081, 1.0646]) < 1e-4, 2));
% rowIndex6 = find(all(abs([powertable_tipdfl.('blade span'), powertable_tipdfl.('cpR^2')] - [1.12534, 1.13435]) < 1e-4, 2)); %index 49
rowIndex3 = find(all(abs([powertable_tipdfl.('blade span'), powertable_tipdfl.('cpR^2')] - [1.19768, 1.1764]) < 1e-3, 2)); %index 49
%rowIndex4 = find(all(abs(powertable_tipdfl.('cpR^2') - 1.15561) < 1e-3, 2));

% Cases=[powertable(rowIndex1,:);powertable(rowIndex2,:);powertable(rowIndex3,:)];      
Cases=[jamiesonsCaseMomMatch(rowIndex1),jamiesonsCaseMomMatch(rowIndex2),jamiesonsCaseTipDfl(rowIndex3)];

Mass = CaseAnalyzer_v2(Cases,referenceCase);

%A veeery cool one is n=5.25, p=1.5
%even cooler 5.25 1.48 3.99%
%5.25 1.47 4.41%
% [5.25, 1.475]4.78%
%[5.255, 147] 
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
    %title(['Heatmap of ', zField]);
end

%matching baseline root bending moment
function [jinputs,ajam,apjam,jamchord,jamtwist,newhubRad,relWind,a,ap,amids,...
            apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
            ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,mass,crefmoment,blade,D,R,F,L,Ks,COE,AEP]=...
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
                ctmids, cmmids, ocp, oct, ocm, dT, dQ, totalpwr, mass, crefmoment, blade, D, R, F, L, Ks, COE,AEP] = ...
                analysis_blocks_v3_00(caseName,jinputs, newhubRad, parentFolder, airfoils, numel);
    
            %diagnostic plot
             % figure()
             % plot(crefjamiesonsCase.blade.ispan,a,blade.ispan,ajam)
             % figure()
             % plot(crefjamiesonsCase.blade.ispan,jamchord,jinputs.("span (r) [m]"),jinputs.("chord"))
             % 

end

%newtons method
function [jinputs,ajam,apjam,jamchord,jamtwist,newhubRad,relWind,a,ap,amids,...
            apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
            ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr, crefmass, crefmoment,blade,D,R,F,L,Ks,COE,AEP]=...
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
                ctmids, cmmids, ocp, oct, ocm, dT, dQ, totalpwr, crefmass, crefmoment, blade, D, R, F, L, Ks, COE, AEP] = ...
                analysis_blocks_v3_00(caseName,jinputs, newhubRad, parentFolder, airfoils, numel);
    
            %diagnostic plot
            % figure()
            % plot(crefjamiesonsCase.blade.ispan,a,crefjamiesonsCase.blade.ispan,ajam)
            % figure()
            % plot(crefjamiesonsCase.blade.ispan,jamchord,jinputs.("span (r) [m]"),jinputs.("chord"))
            % Analysis blocks for + step
            [~, ~, ~, ~, ~, ~, ~, ~, ~, ~,...
                ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~,...
                 Dph, ~, ~, ~, ~, ~, ~] = ...
                 analysis_blocks_v3_00(caseName,jinputsph, newhubRadph, parentFolder, airfoils, numel);
    
            % Analysis blocks for - step
            [~, ~, ~, ~, ~, ~, ~, ~, ~, ~,...
                ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~,...
                 Dmh, ~, ~, ~, ~, ~, ~] = ...
                 analysis_blocks_v3_00(caseName,jinputsmh, newhubRadmh, parentFolder, airfoils, numel);
    
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

%modified false position
function [jinputs,ajam,apjam,jamchord,jamtwist,newhubRad,relWind,a,ap,amids,...
            apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
            ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr,mass,crefmoment,blade,D,R,F,L,Ks,COE,AEP]=...
            modified_false_position_run...
            (crefjamiesonsCase,crefmoment,wndspeed,a_in,...
            n_in,p_in,crefnewhubRad,numblades,inputs,parentFolder,airfoils,numel)

    caseName = getVarName(crefjamiesonsCase);
    max_iter = 100;
    tolerance = 5e-1;
    signcheck = true;
    bounds = [0.6 1.2] * (crefjamiesonsCase.blade.ispan(end) + crefnewhubRad);%[0.6 1.15]
    bigger=false;
    smaller=false;
        while and(signcheck,not(smaller*bigger))
            signcheck=false;
            lb = bounds(1);
            hb = bounds(2);
            
            % Evaluate function at initial endpoints
            [jinputslb, ~, ~, ~, ~, newhubRadlb] = jamieson_v2_02_tipdfl(crefjamiesonsCase, ...
                crefmoment, wndspeed, a_in, n_in, p_in, crefnewhubRad, numblades, inputs, ...
                parentFolder, airfoils, lb);
            [jinputshb, ~, ~, ~, ~, newhubRadhb] = jamieson_v2_02_tipdfl(crefjamiesonsCase, ...
                crefmoment, wndspeed, a_in, n_in, p_in, crefnewhubRad, numblades, inputs, ...
                parentFolder, airfoils, hb);
            
            [~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, Dlb, ~, ~, ~, ~, ~, ~] = ...
                analysis_blocks_v3_00(caseName, jinputslb, newhubRadlb, parentFolder, airfoils, numel);
            [~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, Dhb, ~, ~, ~, ~, ~, ~] = ...
                analysis_blocks_v3_00(caseName, jinputshb, newhubRadhb, parentFolder, airfoils, numel);
            
            flb = Dlb(1, end) - crefjamiesonsCase(1).D(1, end);
            fhb = Dhb(1, end) - crefjamiesonsCase(1).D(1, end);
            % flb = 40 - crefjamiesonsCase(1).D(1, end);
            % fhb = 40 - crefjamiesonsCase(1).D(1, end);

            if flb * fhb >= 0
                if Dhb(1, end) <= 0
                    fprintf('BeamDyn did not converge, attempting smaller R')
                    bounds(2) = bounds(2)-0.25;
                    smaller=true;
                else
                    fprintf('f(lb) and f(hb) must have opposite signs attempting larger R');
                    bounds(2) = bounds(2)+0.25;
                    bigger=true;
                end
                signcheck=true;
                if and(smaller,bigger)
                    fprintf('Bounds wont converge');
                end
            end
        end
        
        iter = 0;
        fc = Inf;
        
        if and(smaller,bigger)
            jinputs=0;
            ajam=0;
            apjam=0;
            jamchord=0;
            jamtwist=0;
            newhubRad=0;
            relWind=0;
            a=zeros(1,numel+1);
            ap=zeros(1,numel+1);
            amids=zeros(1,numel);
            apmids=zeros(1,numel);
            cpvector=0;
            ctvector=0;
            rmids=0;
            cmvector=0;
            cpmids=0;
            ctmids=0;
            cmmids=0;
            ocp=0;
            oct=0;
            ocm=0;
            dT=0;
            dQ=0;
            totalpwr=0;
            mass=0;
            newjammoment=0;
            blade=0;
            D=zeros(6,numel+1);
            R=0;
            F=0;
            L=0;
            Ks=0;
        else
            while abs(fc) > tolerance
                iter = iter + 1;
                if iter > max_iter
                    %fprintf('Maximum iterations reached without convergence.\n');
                    break;
                end
                
                % False position formula
                c = hb - fhb * (lb - hb) / (flb - fhb);
                
                [jinputs, ajam, apjam, jamchord, jamtwist, newhubRad] = jamieson_v2_02_tipdfl(crefjamiesonsCase, ...
                    crefmoment, wndspeed, a_in, n_in, p_in, crefnewhubRad, numblades, inputs, ...
                    parentFolder, airfoils, c);
                
                [relWind, a, ap, amids, apmids, cpvector, ctvector, rmids, cmvector, cpmids, ...
                    ctmids, cmmids, ocp, oct, ocm, dT, dQ, totalpwr, mass, crefmoment, blade, D, R, F, L, Ks, COE, AEP] = ...
                    analysis_blocks_v3_00(caseName, jinputs, newhubRad, parentFolder, airfoils, numel);
                
                fc = D(1, end) - crefjamiesonsCase(1).D(1, end);
                % fc = 40 - crefjamiesonsCase(1).D(1, end);
                
                if abs(fc) < tolerance
                    %fprintf('Converged to %f after %d iterations.\n', c, iter);
                    break;
                end
                
                % Illinois modification
                if flb * fc > 0  % Root is in [c, hb]
                    lb = c;
                    flb = fc / 2;  % Reduce f(lb) to prevent stagnation
                else  % Root is in [lb, c]
                    hb = c;
                    fhb = fc / 2;
                end
            end
        end
end

function varName = getVarName(var)
    varName = inputname(1); % Get the name of the first input argument
end