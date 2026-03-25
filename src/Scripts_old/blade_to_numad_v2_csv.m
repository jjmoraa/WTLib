function blade_to_numad_v2_csv(blade_filename, output_filename)
    % Read the blade file
    blade = blade_filename; % NuMAD v3 .blade files are JSON
    
    % Flags (hard-coded for now)
    flags = ["T", "CW", "F"];
    
    % Preallocate
    nStations = numel(blade.stations);
    span = zeros(nStations,1);
    twist = zeros(nStations,1);
    chord = zeros(nStations,1);
    airfoil = strings(nStations,1);
    
    % Loop through stations
    for i = 1:nStations
        station = blade.stations(i);
        span(i) = station.spanlocation; % eta = normalized span position
        twist(i) = station.degreestwist;
        chord(i) = station.chord;
        pct_thick(i) = station.percentthick;
        xoffset(i) = station.coffset;
        %if isfield(station, 'airfoil')
            airfoil(i) = station.airfoil.name;
        %else
        %    airfoil(i) = ""; % or 'circular'
        %end
    end
    
    % Assume default values for missing fields
    %pct_thick = 100 * ones(nStations,1);  % dummy, can be refined
    %xoffset = zeros(nStations,1);          % zero offset
    aero_center = 0.275 * ones(nStations,1); % typical
    
    % Build output table
    T = table(span, twist, chord, pct_thick', xoffset', aero_center, span, airfoil, ...
        'VariableNames', {'Span_m', 'Twist_deg', 'Chord_m', 'Pct_Thick', 'XOffset', 'AeroCenter', 'Span2_m', 'AirfoilFile'});
    
    % Write to file
    writetable(T, output_filename);
    
    % Also write header manually (version, flags)
    fid = fopen(output_filename, 'r+');
    oldContent = fread(fid);
    frewind(fid);
    fprintf(fid, 'Compatible with version v2013-07-25\n');
    fprintf(fid, 'Flags:\t%s\tUse natural offset\n', flags(1));
    fprintf(fid, '\t%s\tDirection rotor spins\n', flags(2));
    fprintf(fid, '\t%s\tTwist shear webs\n\n', flags(3));
    fwrite(fid, oldContent);
    fclose(fid);
    
    fprintf('Blade file converted successfully!\n');
end
