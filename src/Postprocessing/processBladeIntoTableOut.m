function out = processBladeIntoTableOut(blade, n, p)

    if isempty(blade)
        out = [];
        return
    end

   % blade.operatingPoint

    cp = blade.operating_point.ocp;
    cm = blade.operating_point.ocm;
    ct = blade.operating_point.oct;
    aeq = blade.operating_point.aeq;

    R = blade.ispan(end) + blade.hubRad;

    mean_twst = mean(blade.idegreestwist(round(0.3*end):round(0.6*end)));
    tip_chord = mean(blade.ichord(round(0.7*end):end));

    flap_freq = blade.modeFreqs(1);

    cpR2 = cp * R^2;
    power = blade.operating_point.power;

    defl = blade.operating_point.deflection;
    oop = defl(1,end);
    ip  = defl(2,end);
    ax  = defl(3,end);

    moment = blade.operating_point.moment;

    blade.getMass
    mass = blade.mass;

    out = struct( ...
        'n', n, 'p', p, ...
        'cp', cp, 'cm', cm, 'ct', ct, 'aeq', aeq, ...
        'R', R, 'cpR2', cpR2, 'power', power, ...
        'oop', oop, 'ip', ip, 'ax', ax, ...
        'mass', mass, 'moment', moment, ...
        'mean_twst', mean_twst, ...
        'flap_freq', flap_freq, ...
        'eq_stiff', mass * flap_freq^2, ...
        'tip_chord', tip_chord ...
    );
end