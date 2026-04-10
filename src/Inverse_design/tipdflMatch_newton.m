function dfl_refBlade_prop = tipdflMatch_newton(refBlade, airfoils, numel, A, n, p)
    
    % Newton's algorithm parameters
    max_iter = 100; tolerance = 5e-1; step = 1;
    
    proposedR = 1 * refBlade.span(end) + refBlade.hubRad;
    materialsVec = refBlade.materialsVec; componentsVec = refBlade.componentsVec;
    blades = 3; tsr = refBlade.TSR; rated_wndspeed = refBlade.rated_windspeed;
    dataFolder = refBlade.dataFolder; resultsFolder = refBlade.resultsFolder;

    iter = 0; target_dfl = refBlade.operating_point.deflection(1,end);
    while iter < max_iter
        iter = iter + 1;
        [geometryVec_dfl, hubRad_dfl] = jamieson_v4_tipdfl(refBlade, A, n, p, proposedR);

        % center point
        dfl_refBlade_prop = bladeParam(geometryVec_dfl, materialsVec, componentsVec,...
                hubRad_dfl, blades, tsr, rated_wndspeed, dataFolder, resultsFolder, airfoils, numel);

        dfl_refBlade_prop.showName; dfl_refBlade_prop.updateBlade; dfl_refBlade_prop.generateBeamModel; 
        dfl_refBlade_prop.operatingPoint; dfl_center = dfl_refBlade_prop.operating_point.deflection(1,end);

        % + step
        [geometryVec_dfl, hubRad_dfl] = jamieson_v4_tipdfl(refBlade, A, n, p, proposedR + step);
        dfl_refBlade = bladeParam(geometryVec_dfl, materialsVec, componentsVec,...
                hubRad_dfl, blades, tsr, rated_wndspeed, dataFolder, resultsFolder, airfoils, numel);

        dfl_refBlade.showName; dfl_refBlade.updateBlade; dfl_refBlade.generateBeamModel; 
        dfl_refBlade.operatingPoint; dfl_plus = dfl_refBlade.operating_point.deflection(1,end);


        % - step
        [geometryVec_dfl, hubRad_dfl] = jamieson_v4_tipdfl(refBlade, A, n, p, proposedR - step);
        dfl_refBlade = bladeParam(geometryVec_dfl, materialsVec, componentsVec,...
                hubRad_dfl, blades, tsr, rated_wndspeed, dataFolder, resultsFolder, airfoils, numel);

        dfl_refBlade.showName; dfl_refBlade.updateBlade; dfl_refBlade.generateBeamModel; 
        dfl_refBlade.operatingPoint; dfl_minus = dfl_refBlade.operating_point.deflection(1,end);

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
