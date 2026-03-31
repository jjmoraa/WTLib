function aoa = determineAoA(span, dataFolder, AoA_method)
    
    %% ---- setup -----
    n = length(span); % problem size
    aoa = zeros(1,n);   cl = zeros(1,n);        cd = zeros(1,n);
    chord = zeros(1,n); airfoilno = zeros(1,n); airfoilno = zeros(1,n);

    %% ------------------- Map span → airfoil -------------------
    for j = 1:n
        r = span(j);
    
        if r >= refSpan(end)
            airfoilno(j) = refAF(end);
        else
            k = find(r < refSpan, 1, 'first');
            airfoilno(j) = refAF(k-1);
        end
    end
    
    %% ------------------- Load polars (unique only) -------------------
    uniqueAF = unique(airfoilno);
    tables = cell(size(uniqueAF));
    
    for k = 1:length(uniqueAF)
        filename = sprintf('%s\\Airfoils\\IEA-15-240-RWT_AeroDyn15_Polar_%02d.dat', ...
                           dataFolder, uniqueAF(k)-1);
    
        table = polarRead(filename);
    
        % Ensure degrees
        if max(table.alpha) < 180
            table.alpha = table.alpha * 180/pi;
        end
    
        tables{k}.alpha = table.alpha;
        tables{k}.cl    = table.cl;
        tables{k}.cd    = table.cd;
    end
    
    %% ------------------- Compute AoA -------------------
    for j = 1:n
    
        idxAF = find(uniqueAF == airfoilno(j));
        table = tables{idxAF};
    
        switch AoA_method
    
            case 'reference'
                aoa(j) = (refBlade.operating_point.aoas(j) + ...
                          refBlade.operating_point.aoas(j+1)) / 2;
    
            case 'tableLookup'
                refBlade_aoa = (refBlade.operating_point.aoas(j) + ...
                                refBlade.operating_point.aoas(j+1)) / 2;
    
                index = determineAoA(table, 'prescribedAoA', refBlade_aoa);
                aoa(j) = table.alpha(index) * pi/180;
    
            case 'optimum'
                index = determineAoA(table, 'maxClminCdCl');
                aoa(j) = table.alpha(index) * pi/180;
    
            otherwise
                error('Unknown AoA_method');
        end
    end
    
    %% ------------------- Smooth AoA (optional) -------------------
    if ~strcmp(AoA_method, 'optimum')
        aoa = deg2rad(movmean(rad2deg(aoa), 7));
    end

end