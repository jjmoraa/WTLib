%% Helper function to parse inputs into structs
function [geometryVec, materialsVec, componentsVec] = parseInputs(inputs, filename)
% Parse your Excel and inputs into structured vectors for optimization

MPa_to_Pa = 1e6;

%% Geometry
geometryVec.span         = table2array(inputs(:,1));
geometryVec.degreestwist = table2array(inputs(:,5)); 
geometryVec.chord        = table2array(inputs(:,6));
geometryVec.chordoffset  = zeros(size(geometryVec.span));
geometryVec.sweep        = zeros(size(geometryVec.span));
geometryVec.prebend      = zeros(size(geometryVec.span));
geometryVec.percentthick = 100*ones(size(geometryVec.span));
geometryVec.aerocenter   = [ones(1,2), repmat(0.275,1,length(geometryVec.span)-2)];
geometryVec.afID         = table2array(inputs(:,7)); % airfoil ID for each station

%% Components
[compNum, compTxt, compRaw] = xlsread(filename,'Components');

N = size(compNum,1)-7; % adjust as needed
componentsVec = struct([]);
for k = 0:N
    comp.group       = compNum(7+k,1);
    comp.name        = compTxt{7+k,2};
    comp.materialid  = compNum(7+k,3);
    comp.fabricangle = readnumlist(compRaw{7+k,4});
    comp.hpextents   = readstrlist(compTxt{7+k,5});
    comp.lpextents   = readstrlist(compTxt{7+k,6});
    comp.cp          = readnumlist(compRaw{7+k,7});
    comp.cp(:,2)     = readnumlist(compRaw{7+k,8});%this is the number of layers
    comp.imethod     = compTxt{7+k,9};
    componentsVec = [componentsVec; comp];fprintf('%s \n',comp.name)
end

componentsVec(N+2).sparcapwidth  = compNum(2,3);
componentsVec(N+2).leband        = compNum(3,3);
componentsVec(N+2).teband        = compNum(4,3);

% ble: <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
componentsVec(N+2).sparcapoffset = compNum(5,3);
if isnan(componentsVec(N+2).sparcapoffset), componentsVec(N+2).sparcapoffset = 0; end
% ble: >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>



%% Materials
[matNum, matTxt] = xlsread(filename,'Materials');

% ==== SETTINGS ====
datarow1 = 4;  % first row of material data (after headers)
MPa_to_Pa = 1e6;
N = size(matNum,1) - datarow1;

materialsVec = struct([]);

for k = 0:N
    row = datarow1 + k;

    % --- Basic fields ---
    mat.name           = matTxt{row, 2};
    mat.type           = matTxt{row, 3};
    mat.layerthickness = matNum(row, 4);
    mat.ex             = MPa_to_Pa * matNum(row, 5);
    mat.prxy           = matNum(row, 11);
    mat.density        = matNum(row, 14);
    mat.drydensity     = matNum(row, 15);
    mat.uts            = MPa_to_Pa * matNum(row, 16);
    mat.ucs            = MPa_to_Pa * matNum(row, 17);
    mat.reference      = matTxt{row, 18};

    % --- Conditional fields for orthotropic materials ---
    if strcmpi(mat.type, 'orthotropic')
        mat.ey   = MPa_to_Pa * matNum(row, 6);
        mat.ez   = MPa_to_Pa * matNum(row, 7);
        mat.gxy  = MPa_to_Pa * matNum(row, 8);
        mat.gyz  = MPa_to_Pa * matNum(row, 9);
        mat.gxz  = MPa_to_Pa * matNum(row, 10);
        mat.pryz = matNum(row, 12);
        mat.prxz = matNum(row, 13);
    else
        % Leave empty for isotropic — will be filled in below
        mat.ey = []; mat.ez = [];
        mat.gxy = []; mat.gyz = []; mat.gxz = [];
        mat.pryz = []; mat.prxz = [];
    end

    % --- Fallbacks for missing values ---
    if isempty(mat.ey),   mat.ey   = mat.ex; end
    if isempty(mat.ez),   mat.ez   = mat.ey; end
    if isempty(mat.gxy),  mat.gxy  = mat.ex / (2*(1+mat.prxy)); end  % isotropic shear
    if isempty(mat.gyz),  mat.gyz  = mat.gxy; end
    if isempty(mat.gxz),  mat.gxz  = mat.gyz; end
    if isempty(mat.pryz), mat.pryz = mat.prxy; end
    if isempty(mat.prxz), mat.prxz = mat.prxy; end

    % --- Append ---
    materialsVec = [materialsVec; mat];
end


end

%% Helper functions for reading strings/numbers
function numv = readnumlist(str)
    if isnumeric(str), numv = str; return; end
    str = strrep(str,'[',''); str = strrep(str,']',''); str = strrep(str,',',' ');
    numv = cell2mat(textscan(str,'%f'));
end

function strv = readstrlist(str)
    str = strrep(str,'[',''); str = strrep(str,']',''); str = strrep(str,',',' ');
    if isempty(str), str = ' '; end
    strvcell = textscan(str,'%s');
    strv = transpose(strvcell{1});
end
