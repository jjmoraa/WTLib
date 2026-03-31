%modified false position
function dfl_c = tipdflmatch_modfalsep(refBlade, airfoils, numel, A, n, p)
   
    % physical parameters from reference turbine
    materialsVec = refBlade.materialsVec; componentsVec = refBlade.componentsVec;
    hubRad = refBlade.hubRad; blades = refBlade.Blades;
    tsr =refBlade.TSR; rated_wndspeed = refBlade.rated_windspeed;
    d_ref = refBlade.operating_point.deflection(1, end);
    dataFolder = refBlade.dataFolder; resultsFolder = refBlade.resultsFolder;

    % false position algorithm parameters
    max_iter = 100;    tolerance = 5e-1;    bounds = [0.9*refBlade.span(end) 1.1*refBlade.span(end)];
    signcheck = true; bigger = false;    smaller = false;

    while and(signcheck, not(smaller*bigger))
        signcheck = false; lb = bounds(1); hb = bounds(2);

        % evaluate function at initial endpoints
        % lb
        [geometryVec_lb, hubRad_lb] = jamieson_v3_tipdfl(refBlade, A, n, p, bounds(1));
        dfl_lb = bladeParam(geometryVec_lb, materialsVec, componentsVec,...
            hubRad_lb, blades, tsr, rated_wndspeed, dataFolder, resultsFolder, airfoils, numel);

        dfl_lb.showName; dfl_lb.updateBlade; dfl_lb.generateBeamModel; dfl_lb.operatingPoint; 
        
        % hb
        [geometryVec_hb, hubRad_hb] = jamieson_v3_tipdfl(refBlade, A, n, p, bounds(2));
        dfl_hb = bladeParam(geometryVec_hb, materialsVec, componentsVec,...
            hubRad_hb, blades, tsr, rated_wndspeed, dataFolder, resultsFolder, airfoils, numel);
        
        dfl_hb.showName; dfl_hb.updateBlade; dfl_hb.generateBeamModel; dfl_hb.operatingPoint; 
        
        d_lb = dfl_lb.operating_point.deflection(1, end); d_hb = dfl_hb.operating_point.deflection(1, end);
        % flb/hb
        flb = d_lb - d_ref;
        fhb = d_hb - d_ref;

        if flb * fhb >= 0
            if d_hb <= 0
                fprintf('BeamDyn did not converge, attempting smaller R')
                bounds(2) = bounds(2)-0.1;
                smaller=true;
            else
                fprintf('f(lb) and f(hb) must have opposite signs attempting larger R');
                bounds(2) = bounds(2)+0.1;
                bigger=true;
            end
            signcheck=true;
            if and(smaller,bigger)
                fprintf('Bounds wont converge');
            end
        end
    end

    if and(smaller,bigger)
        dfl_c = [];
    else

        % initialize false position 
        iter = 0;
        fc = Inf;
        while abs(fc) > tolerance
            iter = iter + 1;
            if iter > max_iter
                %fprintf('Maximum iterations reached without convergence.\n');
                break;
            end
            
            % False position formula
            c = hb - fhb * (lb - hb) / (flb - fhb);
            
            % center
            [geometryVec_c, hubRad_c] = jamieson_v3_tipdfl(refBlade, A, n, p, c);
            dfl_c = bladeParam(geometryVec_c, materialsVec, componentsVec,...
                hubRad_c, blades, tsr, rated_wndspeed, dataFolder, resultsFolder, airfoils, numel);
            
            dfl_c.showName; dfl_c.updateBlade; dfl_c.generateBeamModel; dfl_c.operatingPoint; 
        
            d_c = dfl_c.operating_point.deflection(1,end);
            fc = d_c - d_ref + 1;

            if abs(fc) < tolerance
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

