function [geometryVec, newhubRad] = jamieson_v3_momentmatch(refBlade, A, n, p, AoA_method)
    
    %% if there's no method given for AoA selector
    if nargin < 5 || isempty(AoA_method)
        AoA_method = 'reference';
    end

    %% Implement jamiesons to get axial induction distribution
    % initialize geometry vector
    geometryVec = refBlade.geometryVec;
    problemSize=length(refBlade.span); frozenPoints=ceil((.30)*problemSize);
    
    refR = refBlade.span(end)+refBlade.hubRad; refspan = refBlade.span+refBlade.hubRad; arefspan = refspan/refR;
    ltsr = refBlade.TSR*arefspan;
    rotspeed = ltsr(end).*refBlade.rated_windspeed/refR;
    
    % define axial induction vector
    a = A*(1-(arefspan).^n).^p;
    
    % --- Force frozen region to zero ---
    a(1:frozenPoints) = 0;
    
    % --- Continue normally ---
    ap = -1/2 + 1/2*sqrt(1 + 4*a.*(1-a)./(ltsr.^2));
    relwnd = atan((1-a)./((1-ap).*ltsr));
    
    %% calculate parameters of interest in midpoints of spanwise elements
    amids = length(problemSize); apmids = length(problemSize);
    relwndmids = length(problemSize); rmids = length(problemSize); rsize = length(problemSize);
    for i = 1:(problemSize-1)
        amids(i)      = (a(i)+a(i+1))/2;
        apmids(i)     = (ap(i)+ap(i+1))/2;
        relwndmids(i) = (relwnd(i)+relwnd(i+1))/2;
        rmids(i)      = (arefspan(i)+arefspan(i+1))/2;
        rsize(i)      =  arefspan(i+1)-arefspan(i);
    end
    
    % BEM calculations
    cpmids = 8*amids.*((1-amids).^2).*rmids.*rsize;
    Fmids = (2/pi)*acos(exp(-(2.5*(1-rmids))./(rmids.*sin(relwndmids))));
    dT = Fmids.*1.225*(refBlade.rated_windspeed^2)*4.*amids.*(1-amids)*pi.*rmids.*rsize;
    
    %% get integrated quantities from AD
    % integrated quantities from actuator disk
    thrust = sum(dT(2:end));
    cntrThr=sum((dT.*rmids)/sum(dT));%center of thrust
    oopmoment=cntrThr*thrust;
    
    % moment coefficient
    ocm=oopmoment/((1/2)*1.225*pi()*(1^3)*(refBlade.rated_windspeed^2));
    
    %% radius determination and hub scaling
    R=((refBlade.operating_point.moment)/(0.5*1.225*(refBlade.rated_windspeed^2)*pi()*ocm))^(1/3);
    newhubRad=refBlade.hubRad*R/refR;
    span=arefspan*R;
    
    %% determine AoA for span using prescribed method
    if strcmp(AoA_method, 'reference')
        % Original
        y_old = refBlade.operating_point.aoas;   n_old = length(y_old);
        
        % New size
        n_new = length(span);
        
        % Normalized coordinate (0 → 1)
        s_old = linspace(0,1,n_old);
        s_new = linspace(0,1,n_new);
        
        % Resample (shape-preserving)
        aoa = interp1(s_old, y_old, s_new, 'pchip')';
        % aoa (end) = aoa (end - 1);
    else
        aoa = determineAoA(span, refBlade.dataFolder, AoA_method, refBlade);

        % Convert AoA to degrees
        % aoa_deg = rad2deg(aoa);
        
        % Smooth in degrees
        % aoa_deg_smooth = movmean(aoa_deg, 7);
        
        % Convert back to radians
        % aoa = deg2rad(aoa);
    end
    %% ------------------- Precompute: map span → airfoil -------------------

    refSpan   = refBlade.geometryVec.span;
    refAF     = refBlade.geometryVec.afID;

    airfoilno = zeros(size(arefspan));
    
    for j = 1:length(arefspan)
        r = span(j);
    
        % --- Airfoil lookup based on reference span ---
        if r >= refSpan(end)
            airfoilno(j) = refAF(end);
        else
            k = find(r < refSpan, 1, 'first');
            airfoilno(j) = refAF(k-1);
        end
    end
    
    uniqueAF = unique(airfoilno);
    
    % --- Load polars once per unique airfoil ---
    tables = cell(size(uniqueAF));
    for k = 1:length(uniqueAF)
        filename = sprintf('%s\\Airfoils\\IEA-15-240-RWT_AeroDyn15_Polar_%02d.dat', ...
                           refBlade.dataFolder, uniqueAF(k)-1);
        table = polarRead(filename);
        
        if max(table.alpha) < 180
            table.alpha = table.alpha * 180/pi;
        end
    
        % Only keep necessary fields to save memory
        tables{k}.alpha = table.alpha;
        tables{k}.cl    = table.cl;
        tables{k}.cd    = table.cd;
    end
    
    %% ------------------- Interpolate Cl/Cd and compute chord -------------------
    cl   = zeros(size(arefspan));
    cd   = zeros(size(arefspan));
    chord = zeros(size(arefspan));
    F = zeros(size(arefspan));
    
    aoa = rad2deg(aoa); %tables will be in degrees
    for j = 1:length(arefspan)
        idxAF = find(uniqueAF == airfoilno(j));
        table  = tables{idxAF};
    
        % Interpolate Cl/Cd using smoothed AoA
        cl(j) = interp1(table.alpha, table.cl, aoa(j), 'pchip');
        cd(j) = interp1(table.alpha, table.cd, aoa(j), 'pchip');
        
        F(j)=(2/pi)*acos(exp(-(2.5*(1-arefspan(j)/arefspan(end)))/...
            (arefspan(j)*sin(relwnd(j))/arefspan(end))));

        % Chord from BEM relation
        chord(j) = 8 * sin(relwnd(j)) * a(j) * F(j) * pi * span(j) / ...
                   (refBlade.Blades * cl(j) * ltsr(j) * (1 + ap(j)));
    end
    
    chord(1:(frozenPoints+1)) = refBlade.ichord(1:(frozenPoints+1))*(chord(frozenPoints+1)/refBlade.ichord(frozenPoints+1));
    
    % chord correction
    chord_min = refBlade.geometryVec.chord(end);   % minimum allowable chord

    if any(chord(1:end - 1) < chord_min)
        chord(end) = chord(end - 1);
    else
        chord(end) = chord_min;
    end



    twist = relwnd*180/pi() - aoa;
    twist_scale = refBlade.idegreestwist(frozenPoints+1) / twist(frozenPoints+1);     % Compute scaling factor
    twist(1:(frozenPoints+1)) = refBlade.idegreestwist(1:(frozenPoints+1)) * twist_scale;
    twist(end) = twist (end - 1);

    geometryVec.span = span - newhubRad; geometryVec.span(1) = 0;
    geometryVec.degreestwist = twist;
    geometryVec.chord = chord;
    % geometryVec.afID = airfoilno;
    % geometryVec.chordoffset = [geometryVec.chordoffset geometryVec.chordoffset(end)];
    % geometryVec.sweep = [geometryVec.sweep, geometryVec.sweep(end)];
    % geometryVec.prebend = [geometryVec.prebend, geometryVec.prebend(end)];
    % geometryVec.percentthick = [geometryVec.percentthick, geometryVec.percentthick(end)];
    % geometryVec.aerocenter = [geometryVec.aerocenter, geometryVec.aerocenter(end)];

end