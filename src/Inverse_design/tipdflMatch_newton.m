function dfl_refBlade_prop = tipdflMatch_newton(refBlade, airfoils, numel, A, n, p, AoA_method)
    
    %% if there's no method given for AoA selector
        if nargin < 7 || isempty(AoA_method)
            AoA_method = 'reference';
        end

    % Newton's algorithm parameters
    max_iter = 100; tolerance = 5e-1; step = 1;
    
    proposedR = 1 * refBlade.span(end) + refBlade.hubRad;
    materialsVec = refBlade.materialsVec; componentsVec = refBlade.componentsVec;
    blades = 3; tsr = refBlade.TSR; rated_wndspeed = refBlade.rated_windspeed;
    dataFolder = refBlade.dataFolder; resultsFolder = refBlade.resultsFolder;

    iter = 0; target_dfl = refBlade.operating_point.deflection(1,end);
    while iter < max_iter
        iter = iter + 1;
        [geometryVec_dfl, hubRad_dfl] = jamieson_v4_tipdfl(refBlade, A, n, p, proposedR, AoA_method);

        % center point
        dfl_refBlade_prop = bladeParam(geometryVec_dfl, materialsVec, componentsVec,...
                hubRad_dfl, blades, tsr, rated_wndspeed, dataFolder, resultsFolder, airfoils, numel);

        dfl_refBlade_prop.showName; dfl_refBlade_prop.updateBlade; dfl_refBlade_prop.generateBeamModel; 
        dfl_refBlade_prop.operatingPoint; dfl_center = dfl_refBlade_prop.operating_point.deflection(1,end);

        % + step
        [geometryVec_dfl, hubRad_dfl] = jamieson_v4_tipdfl(refBlade, A, n, p, proposedR + step, AoA_method);
        dfl_refBlade_plus = bladeParam(geometryVec_dfl, materialsVec, componentsVec,...
                hubRad_dfl, blades, tsr, rated_wndspeed, dataFolder, resultsFolder, airfoils, numel);

        dfl_refBlade_plus.showName; dfl_refBlade_plus.updateBlade; dfl_refBlade_plus.generateBeamModel; 
        dfl_refBlade_plus.operatingPoint; dfl_plus = dfl_refBlade_plus.operating_point.deflection(1,end);


        % - step
        [geometryVec_dfl, hubRad_dfl] = jamieson_v4_tipdfl(refBlade, A, n, p, proposedR - step, AoA_method);
        dfl_refBlade_min = bladeParam(geometryVec_dfl, materialsVec, componentsVec,...
                hubRad_dfl, blades, tsr, rated_wndspeed, dataFolder, resultsFolder, airfoils, numel);

        dfl_refBlade_min.showName; dfl_refBlade_min.updateBlade; dfl_refBlade_min.generateBeamModel; 
        dfl_refBlade_min.operatingPoint; dfl_minus = dfl_refBlade_min.operating_point.deflection(1,end);

        % diff and update proposedR
        dflprime = (dfl_plus - dfl_minus) / (2 * step);
        proposedR_new = proposedR - (dfl_center - target_dfl) / dflprime;
        indicator = abs(proposedR_new - proposedR);
        proposedR = proposedR_new;

        if indicator < tolerance
            fprintf('converged to %f after %d iterations \n', proposedR, iter)
            break;
        end
    end

    if iter > max_iter
       fprintf('tip deflection match algorithm id not converge \n')
       dfl_refBlade_prop = [];
    end
end
