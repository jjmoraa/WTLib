function [geometryVec, newhubRad] = jamieson_v3_momentmatch(refBlade, A, n, p)

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

% integrated quantities from actuator disk
thrust = sum(dT(2:end));
cntrThr=sum((dT.*rmids)/sum(dT));%center of thrust
oopmoment=cntrThr*thrust;

% moment coefficient
ocm=oopmoment/((1/2)*1.225*pi()*(1^3)*(refBlade.rated_windspeed^2));

% radius determination and hub scaling
R=((refBlade.operating_point.moment)/(0.5*1.225*(refBlade.rated_windspeed^2)*pi()*ocm))^(1/3);
newhubRad=refBlade.hubRad*R/refR;
span=arefspan*R;

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

chord(1:(frozenPoints+1)) = refBlade.ichord(1:(frozenPoints+1))*(chord(frozenPoints+1)/refBlade.ichord(frozenPoints+1));
chord(chord < refBlade.ichord(end)) = refBlade.ichord(end);
twist = relwnd*180/pi() - aoa';
twist(1:(frozenPoints+1)) = refBlade.idegreestwist(1:(frozenPoints+1));

geometryVec.span = span' - newhubRad; geometryVec.span(1) = 0;
geometryVec.degreestwist = twist';
geometryVec.chord = chord';
% geometryVec.afID = airfoilno;
% geometryVec.chordoffset = [geometryVec.chordoffset geometryVec.chordoffset(end)];
% geometryVec.sweep = [geometryVec.sweep, geometryVec.sweep(end)];
% geometryVec.prebend = [geometryVec.prebend, geometryVec.prebend(end)];
% geometryVec.percentthick = [geometryVec.percentthick, geometryVec.percentthick(end)];
% geometryVec.aerocenter = [geometryVec.aerocenter, geometryVec.aerocenter(end)];

end