%main v4
%Code by Jose Mora @ UMass
%This one allows reading multiple section files
% close all
% clear
% clc

parallel=1;
if parallel
    if isempty(gcp('nocreate'))
        parpool(5)
    end
end
%% initiation
%JJM: Very important to check these scripts and set your paths correctly!
addNumadPaths

% Get the current working directory (current folder)
currentFolder = pwd;
% Get the parent folder (folder above the current folder)
parentFolder = fileparts(currentFolder);

%read inputs function
[inputs,airfoils]=scriptInit_v2(parentFolder);


%define hub radius and wind speed (this can be included in inputs later)
% tsr=9;
% hubRad=4.118878;
wndspeed=10.65;

%rootmomindices=[6,11]
%tipdflindices=[52]

creftipdfl=crefjamiesonsCase.D(1,end);
[jamiesonsCaseMoment,jamiesonsCaseTipdfl] =...
post_processing_results...
    (powertable_rootmom,rootmomindices,powertable_tipdfl,tipdflindices,...
    crefjamiesonsCaseMoment,crefjamiesonsCaseTipdfl,crefjinputsmoment,crefjinputstipdfl,...
    parentFolder,airfoils,numel,wndspeed);

% rowIndex = find(all(abs([powertable.('A'), powertable.('n'), powertable.('p')] - [0.31605, 3.7957, 0.87103]) < 1e-3, 2))
CaseAnalyzer_v2([jamiesonsCaseMoment,jamiesonsCaseTipdfl],referenceCase)%n is the step for the plots

%Post Processing Results

function [jamiesonsCaseMoment,jamiesonsCaseTipdfl] = post_processing_results...
    (powertable_rootmom,rootmomindices,powertable_tipdfl,tipdflindices,...
    crefmoment,creftipdfl,crefjinputsmoment,crefjinputstipdfl,...
    parentFolder,airfoils,numel,wndspeed)


%for the important cases in the root moment case

jamiesonsCaseMoment=struct([]);
for index=1:length(rootmomindices)
    a_in=powertable_rootmom(rootmomindices(index),:).('A');
    n_in=powertable_rootmom(rootmomindices(index),:).('n');
    p_in=powertable_rootmom(rootmomindices(index),:).('p');

    fprintf('%4.4f %4.4f %4.4f \n',a_in,n_in,p_in)

            [jinputs,ajam,apjam,jamchord,jamtwist,newhubRad,relWind,a,ap,amids,...
            apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
            ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr, mass, newjammoment,blade,D,R,F,L,Ks]=...
            moment_matching...
            (crefmoment,crefmoment.moment,wndspeed,a_in,...
            n_in,p_in,crefmoment.hubRad,3,crefjinputsmoment,parentFolder,airfoils,numel);
         
            jamiesonsCaseMoment(index).n=n_in;
            jamiesonsCaseMoment(index).p=p_in;
            jamiesonsCaseMoment(index).a=a;
            jamiesonsCaseMoment(index).ap=ap;
            jamiesonsCaseMoment(index).amids=amids;
            jamiesonsCaseMoment(index).apmids=apmids;
            jamiesonsCaseMoment(index).ocp=ocp;
            jamiesonsCaseMoment(index).oct=oct;
            jamiesonsCaseMoment(index).ocm=ocm;
            jamiesonsCaseMoment(index).cpmids=cpmids;
            jamiesonsCaseMoment(index).ctmids=ctmids;
            jamiesonsCaseMoment(index).cmmids=cmmids;
            jamiesonsCaseMoment(index).dT=dT;
            jamiesonsCaseMoment(index).dQ=dQ;
            jamiesonsCaseMoment(index).totalpwr=totalpwr;
            jamiesonsCaseMoment(index).blade=blade;
            jamiesonsCaseMoment(index).rmids=rmids;
            jamiesonsCaseMoment(index).hubRad=newhubRad;
            jamiesonsCaseMoment(index).D=D;
            jamiesonsCaseMoment(index).R=R;
            jamiesonsCaseMoment(index).F=F;
            jamiesonsCaseMoment(index).L=L;
            jamiesonsCaseMoment(index).Ks=Ks;
            jamiesonsCaseMoment(index).mass=mass;
            jamiesonsCaseMoment(index).moment=newjammoment;
end



%for the important cases in the tip deflection case
jamiesonsCaseTipdfl=struct([]);


for index=1:length(tipdflindices)
    a_in=powertable_tipdfl(tipdflindices(index),:).('A');
    n_in=powertable_tipdfl(tipdflindices(index),:).('n');
    p_in=powertable_tipdfl(tipdflindices(index),:).('p');

    fprintf('%4.4f %4.4f %4.4f \n',a_in,n_in,p_in)

            [jinputs,ajam,apjam,jamchord,jamtwist,newhubRad,relWind,a,ap,amids,...
            apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
            ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr, mass, newjammoment,blade,D,R,F,L,Ks]=...
            moment_matching...
            (creftipdfl,creftipdfl.moment,wndspeed,a_in,...
            n_in,p_in,creftipdfl.hubRad,3,crefjinputstipdfl,parentFolder,airfoils,numel);
         
            jamiesonsCaseTipdfl(index).n=n_in;
            jamiesonsCaseTipdfl(index).p=p_in;
            jamiesonsCaseTipdfl(index).a=a;
            jamiesonsCaseTipdfl(index).ap=ap;
            jamiesonsCaseTipdfl(index).amids=amids;
            jamiesonsCaseTipdfl(index).apmids=apmids;
            jamiesonsCaseTipdfl(index).ocp=ocp;
            jamiesonsCaseTipdfl(index).oct=oct;
            jamiesonsCaseTipdfl(index).ocm=ocm;
            jamiesonsCaseTipdfl(index).cpmids=cpmids;
            jamiesonsCaseTipdfl(index).ctmids=ctmids;
            jamiesonsCaseTipdfl(index).cmmids=cmmids;
            jamiesonsCaseTipdfl(index).dT=dT;
            jamiesonsCaseTipdfl(index).dQ=dQ;
            jamiesonsCaseTipdfl(index).totalpwr=totalpwr;
            jamiesonsCaseTipdfl(index).blade=blade;
            jamiesonsCaseTipdfl(index).rmids=rmids;
            jamiesonsCaseTipdfl(index).hubRad=newhubRad;
            jamiesonsCaseTipdfl(index).D=D;
            jamiesonsCaseTipdfl(index).R=R;
            jamiesonsCaseTipdfl(index).F=F;
            jamiesonsCaseTipdfl(index).L=L;
            jamiesonsCaseTipdfl(index).Ks=Ks;
            jamiesonsCaseTipdfl(index).mass=mass;
            jamiesonsCaseTipdfl(index).moment=newjammoment;
end






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

%matching baseline tip deflection
function [jinputs,ajam,apjam,jamchord,jamtwist,newhubRad,relWind,a,ap,amids,...
            apmids,cpvector,ctvector,rmids,cmvector,cpmids,...
            ctmids,cmmids,ocp,oct,ocm,dT,dQ,totalpwr, crefmass, crefmoment,blade,D,R,F,L,Ks]=...
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
                ctmids, cmmids, ocp, oct, ocm, dT, dQ, totalpwr, crefmass, crefmoment, blade, D, R, F, L, Ks] = ...
                analysis_blocks_v2_03(caseName,jinputs, newhubRad, parentFolder, airfoils, numel);
    
            %diagnostic plot
            % figure()
            % plot(crefjamiesonsCase.blade.ispan,a,crefjamiesonsCase.blade.ispan,ajam)
            % figure()
            % plot(crefjamiesonsCase.blade.ispan,jamchord,jinputs.("span (r) [m]"),jinputs.("chord"))
            % Analysis blocks for + step
            [~, ~, ~, ~, ~, ~, ~, ~, ~, ~,...
                ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~,...
                 Dph, ~, ~, ~, ~] = ...
                 analysis_blocks_v2_03(caseName,jinputsph, newhubRadph, parentFolder, airfoils, numel);
    
            % Analysis blocks for - step
            [~, ~, ~, ~, ~, ~, ~, ~, ~, ~,...
                ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~,...
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