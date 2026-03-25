function dfl_refBlade_prop = tipdflMatch_newton_v2(refBlade, airfoils, numel, A, n, p)  

    % Newton's algorithm parameters
    max_iter = 100; 
    tolerance = 5e-1; 
    step = 1;

    proposedR = 0.9 * refBlade.span(end) + refBlade.hubRad;
    materialsVec = refBlade.materialsVec; 
    componentsVec = refBlade.componentsVec;
    blades = 3; 
    tsr = refBlade.TSR; 
    rated_wndspeed = refBlade.rated_windspeed;
    dataFolder = refBlade.dataFolder; 
    resultsFolder = refBlade.resultsFolder;

    target_dfl = refBlade.operating_point.deflection(1,end);
    iter = 0;

    while iter < max_iter
        iter = iter + 1;

        %% -------- SAFE CENTER EVALUATION WITH R SHRINK --------
        success_center = false;
        shrink_iter = 0;
        max_shrink = 10;

        while ~success_center && shrink_iter < max_shrink
            shrink_iter = shrink_iter + 1;

            try
                [geometryVec_dfl, hubRad_dfl] = jamieson_v3_tipdfl(refBlade, A, n, p, proposedR);

                dfl_refBlade_prop = bladeParam(geometryVec_dfl, materialsVec, componentsVec,...
                    hubRad_dfl, blades, tsr, rated_wndspeed, dataFolder, resultsFolder, airfoils, numel);

                dfl_refBlade_prop.showName; 
                dfl_refBlade_prop.updateBlade; 
                dfl_refBlade_prop.generateBeamModel; 
                dfl_refBlade_prop.operatingPoint; 

                dfl_center = dfl_refBlade_prop.operating_point.deflection(1,end);

                % success if deflection is valid
                if dfl_center ~= 0
                    success_center = true;
                else
                    error('Center deflection is zero');  % force shrink
                end

            catch
                % Shrink proposedR and retry
                proposedR = 0.9 * proposedR;
                fprintf('Center evaluation failed. Shrinking R to %.3f\n', proposedR);
            end
        end

        if ~success_center
            fprintf('Could not find valid starting R after %d shrink attempts\n', max_shrink);
            dfl_refBlade_prop = [];
            break  % stop Newton iteration, but do not use return
        end
        %% ----------------------------------------

        %% -------- + STEP --------     
        [geometryVec_dfl, hubRad_dfl] = jamieson_v3_tipdfl(refBlade, A, n, p, proposedR + step);

        dfl_refBlade = bladeParam(geometryVec_dfl, materialsVec, componentsVec,...
            hubRad_dfl, blades, tsr, rated_wndspeed, dataFolder, resultsFolder, airfoils, numel);

        dfl_refBlade.showName; dfl_refBlade.updateBlade; dfl_refBlade.generateBeamModel;
        dfl_refBlade.operatingPoint;

        dfl_plus = dfl_refBlade.operating_point.deflection(1,end);

        if dfl_plus == 0
            % if forward step fails, shrink radius and retry next Newton iteration
            proposedR = 0.9 * proposedR;
            fprintf('Forward perturbation failed. Shrinking R to %.3f\n', proposedR);
            continue
        end
        %% ----------------------------------------

        %% -------- - STEP --------
        [geometryVec_dfl, hubRad_dfl] = jamieson_v3_tipdfl(refBlade, A, n, p, proposedR - step);

        dfl_refBlade = bladeParam(geometryVec_dfl, materialsVec, componentsVec,...
            hubRad_dfl, blades, tsr, rated_wndspeed, dataFolder, resultsFolder, airfoils, numel);

        dfl_refBlade.showName; dfl_refBlade.updateBlade; dfl_refBlade.generateBeamModel;
        dfl_refBlade.operatingPoint;

        dfl_minus = dfl_refBlade.operating_point.deflection(1,end);

        if dfl_minus == 0
            % if backward step fails, shrink radius and retry next Newton iteration
            proposedR = 0.9 * proposedR;
            fprintf('Backward perturbation failed. Shrinking R to %.3f\n', proposedR);
            continue
        end
        %% ----------------------------------------

        %% -------- DERIVATIVE + UPDATE --------
        dflprime = (dfl_plus - dfl_minus) / (2*step);

        proposedR_new = proposedR - (dfl_center - target_dfl) / dflprime;
        indicator = abs(proposedR_new - proposedR);
        proposedR = proposedR_new;

        if indicator < tolerance
            fprintf('Converged to %f after %d iterations\n', proposedR, iter)
            break;
        end
        %% ----------------------------------------

    end  % end Newton iteration

    if iter >= max_iter
        fprintf('Tip deflection match algorithm did not converge\n')
        dfl_refBlade_prop = [];
    end

end