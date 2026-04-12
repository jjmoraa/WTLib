function aoa = determineAoA(span, dataFolder, AoA_method, refBlade)

    %% ---- Handle optional input ----
    if nargin < 4
        refBlade = [];
    end

    needsRef = ismember(AoA_method, {'reference','tableLookup'});

    if needsRef && isempty(refBlade)
        error('refBlade is required for AoA_method = %s', AoA_method);
    end

    %% ---- setup ----
    n = length(span);
    aoa = zeros(1,n);

    %% ---- reference mapping (if available) ----
    if ~isempty(refBlade)
        refSpan = refBlade.geometryVec.span;
        refAF   = refBlade.geometryVec.afID;
    else
        error('refBlade is required for airfoil mapping.');
    end

    airfoilno = zeros(1,n);

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

    %% ------------------- Load polars -------------------
    uniqueAF = unique(airfoilno);
    tables = cell(size(uniqueAF));

    for k = 1:length(uniqueAF)
        filename = sprintf('%s\\Airfoils\\IEA-15-240-RWT_AeroDyn15_Polar_%02d.dat', ...
                           dataFolder, uniqueAF(k)-1);

        table = polarRead(filename);

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
            case 'reverseEngineer'
                refR = refBlade.span(end)+refBlade.hubRad; refspan = refBlade.span+refBlade.hubRad; arefspan = refspan/refR;
                ltsr = refBlade.TSR*arefspan;
                % resample a
                % Original
                y_old = refBlade.operating_point.a;   n_old = length(y_old);
                
                % New size
                n_new = length(span);
                
                % Normalized coordinate (0 → 1)
                s_old = linspace(0,1,n_old);
                s_new = linspace(0,1,n_new);
                
                % Resample (shape-preserving)
                a = interp1(s_old, y_old, s_new, 'pchip')';
                
                ap = -1/2 + 1/2*sqrt(1 + 4*a.*(1-a)./(ltsr.^2));
                relwnd = atan((1-a)./((1-ap).*ltsr));

                twist = refBlade.geometryVec.degreestwist;
                aoa = relwnd - deg2rad(twist);

            case 'constant'
                refR = refBlade.span(end)+refBlade.hubRad; refspan = refBlade.span+refBlade.hubRad; arefspan = refspan/refR;
                ltsr = refBlade.TSR*arefspan;
                % resample a
                % Original
                stations = length(arefspan);
                a_val = mean(refBlade.operating_point.a(round(stations*.30):round(stations*.60)));  
                
                % project into vector
                a = a_val*ones(stations,1);
                
                ap = -1/2 + 1/2*sqrt(1 + 4*a.*(1-a)./(ltsr.^2));
                relwnd = atan((1-a)./((1-ap).*ltsr));

                twist = refBlade.geometryVec.degreestwist;
                aoa = relwnd - deg2rad(twist);

            otherwise
                error('Unknown AoA_method');
        end
  

    %% ------------------- Smooth AoA -------------------
    if ~strcmp(AoA_method, 'optimum')
        aoa = deg2rad(movmean(rad2deg(aoa), 7));
    end

end