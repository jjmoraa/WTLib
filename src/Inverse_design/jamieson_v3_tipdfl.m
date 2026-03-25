function [geometryVec, newhubRad] = jamieson_v3_tipdfl(refBlade, A, n, p, R)

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

% --- Enforce radius scaling with guess radius ---
newhubRad=refBlade.hubRad*R/refR;
span=arefspan*R;

% --- Construct reference airfoil locations
refSpan   = refBlade.geometryVec.span;
refAF     = refBlade.geometryVec.afID;

aoa = length(arefspan); cl = length(arefspan); cd = length(arefspan);
chord = length(arefspan); airfoilno = length(arefspan);
for j = 1:length(arefspan)

    r = span(j);   % current radial location
    % ---------- Airfoil lookup ----------
    if r >= refSpan(end)
        airfoilno(j) = refAF(end);
    else
        k = find(r < refSpan, 1, 'first');
        airfoilno(j) = refAF(k-1);
    end

    % ---------- Read polar ----------
    filename = sprintf('%s\\Airfoils\\IEA-15-240-RWT_AeroDyn15_Polar_%02d.dat', ...
                       refBlade.dataFolder, airfoilno(j)-1);

    fid = fopen(filename,'r');
    for i = 1:52
        fgetl(fid);
    end

    data = textscan(fid,'%f %f %f %f','HeaderLines',2);
    fclose(fid);

    table = array2table(cell2mat(data), ...
        'VariableNames',{'alpha','cl','cd','cm'});

    % ---------- Units fix ----------
    if max(table.alpha) < 180
        table.alpha = table.alpha * 180/pi;
    end

    % ---------- Find best CL/CD ----------
    table.clcd = table.cd ./ table.cl;

    index = find(table.cl == max(table.cl),1,'last');

    clcd = table.clcd(index);
    while index > 1 && clcd > table.clcd(index-1)
        index = index - 1;
        clcd  = table.clcd(index);
    end

    % ---------- Extract values ----------
    aoa(j) = table.alpha(index);
    cl(j)  = table.cl(index);
    cd(j)  = table.cd(index);

    % ---------- Chord from BEM relation ----------
    chord(j) = 8 * sin(relwnd(j)) * a(j) * pi * span(j) / ...
               (refBlade.Blades * cl(j) * ltsr(j) * (1 + ap(j)));

end

% --- Keep the chord distribution of the original blade but scalaed to
% match the new blades first determined position ---
chord(1:(frozenPoints+1)) = refBlade.ichord(1:(frozenPoints+1))*(chord(frozenPoints+1)/refBlade.ichord(frozenPoints+1));
chord(chord < refBlade.ichord(end)) = refBlade.ichord(end);
twist = relwnd*180/pi() - aoa';
twist(1:(frozenPoints+1)) = refBlade.idegreestwist(1:(frozenPoints+1));

geometryVec.span = span' - newhubRad; geometryVec.span(1) = 0;
geometryVec.degreestwist = twist';
geometryVec.chord = chord';
end