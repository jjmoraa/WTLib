function blade = buildBladeFromParsed(geometryVec, materialsVec, componentsVec, parentFolder, airfoils, numel)
% Build a NuMAD blade using parsed vectors
%
% geometryVec: struct with fields span, degreestwist, chord, chordoffset, etc.
% materialsVec: array of structs with material properties
% componentsVec: array of structs with component properties
% parentFolder: path to airfoil files
% airfoils: table with airfoil names
% numel: number of interpolated span points

MPa_to_Pa = 1e6;
blade = BladeDefmodv2();

%% Set geometry
blade.span        = geometryVec.span;
blade.degreestwist= geometryVec.degreestwist;
blade.chord       = geometryVec.chord;
blade.chordoffset = geometryVec.chordoffset;
blade.sweep       = geometryVec.sweep;
blade.prebend     = geometryVec.prebend;
blade.percentthick= geometryVec.percentthick;
blade.aerocenter  = geometryVec.aerocenter;

prop = {'degreestwist','chord','percentthick','chordoffset','aerocenter'};

%% Add airfoil stations
k = 1;
afspan(k) = geometryVec.span(1);
affile = sprintf('%s\\Airfoils\\IEA-15-240-RWT_AF%02d_Coords.txt', parentFolder, airfoils{k, "name"});
blade.addStation(affile, afspan(k));

for j = 2:length(geometryVec.span)
    if geometryVec.afID(j-1) ~= geometryVec.afID(j)
        k = k + 1;
    end
    afspan(j) = geometryVec.span(j);
    affile = sprintf('%s\\Airfoils\\IEA-15-240-RWT_AF%02d_Coords.txt', parentFolder, airfoils{k, "name"});
    blade.addStation(affile, afspan(j));
end

%% Interpolate missing geometry
for k = 1:length(prop)
    ind = isnan(blade.(prop{k}));
    if any(ind)
        if ~strcmp(prop{k}, 'percentthick')
            blade.(prop{k})(ind) = interp1(blade.span(~ind), blade.(prop{k})(~ind), blade.span(ind), 'pchip');
        else
            absthick = blade.percentthick .* blade.chord / 100;
            iabsthick = interp1(blade.span(~ind), absthick(~ind), blade.span(ind), 'pchip');
            blade.percentthick(ind) = iabsthick ./ blade.chord(ind) * 100;
        end
    end
end

%% Resample airfoils and define blade.ispan using numel
afdb = [blade.stations.airfoil];
afdb.resample(175,'cosine');
blade.ispan = (0:(1/numel):1) * blade.span(end);
lastrow = find(isfinite(blade.ispan)==1, 1, 'last');
blade.ispan = blade.ispan(1:lastrow);

%% Add components
for k = 1:length(componentsVec)
    blade.addComponent(componentsVec(k));
end

%% Add materials
for k = 1:length(materialsVec)
    mat = materialsVec(k);
    if strcmp(mat.type,'orthotropic')
        % fill any missing fields if needed
        if isempty(mat.ez),   mat.ez   = mat.ey; end
        if isempty(mat.gyz),  mat.gyz  = mat.gxy; end
        if isempty(mat.gxz),  mat.gxz  = mat.gyz; end
        if isempty(mat.pryz), mat.pryz = mat.prxy; end
        if isempty(mat.prxz), mat.prxz = mat.prxy; end
    end
    blade.addMaterial(mat);
end

end