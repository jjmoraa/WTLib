function mom_blade = momMatch_wrapper(refBlade, airfoils, numel, A, n, p)
    
    % --- invariant data from reference ---
    materialsVec = refBlade.materialsVec; componentsVec = refBlade.componentsVec;
    blades = 3; tsr = refBlade.TSR; rated_wndspeed = refBlade.rated_windspeed;
    dataFolder = refBlade.dataFolder; resultsFolder = refBlade.resultsFolder;

    % --- create geometry ---
    [geometryVec_mommat, hubRad_mommat] = jamieson_v4_momentmatch(refBlade, A, n, p);

    % --- create moment matching blade ---
    mom_blade = bladeParam(geometryVec_mommat, materialsVec, componentsVec,...
                hubRad_mommat, blades, tsr, rated_wndspeed, dataFolder, resultsFolder, airfoils, numel);
    
    % --- chord sanity check ---
    if any([geometryVec_mommat.chord] < 0)
        return
    end

    % --- Run calculations ---
    mom_blade.updateBlade; 
    mom_blade.generateBeamModel; 
    mom_blade.showName; 
    mom_blade.operatingPoint;

end