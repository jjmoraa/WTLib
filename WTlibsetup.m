function WTlibsetup(numadPath)
%WTLIBSETUP Add paths for WT library, Design Codes, and NuMAD
%
% Usage:
%   WTlibsetup()
%   WTlibsetup('C:\path\to\NuMAD-3.0')

persistent alreadySetup
if ~isempty(alreadySetup) && alreadySetup
    fprintf('Setup already run. Skipping.\n');
    return
end

%% --- Root of WTLib ---
root = fileparts(mfilename('fullpath'));

%% 1. Add main library paths
addpath(genpath(fullfile(root, 'src')));

%% 2. Add Design Codes
designCodesDir = fullfile(root, 'Design_codes');

if isfolder(designCodesDir)
    addpath(genpath(designCodesDir));
    fprintf('Design codes added.\n');
else
    warning('Design_codes folder not found.');
end

%% 3. Configure external tool paths (NuMAD globals)
global ansysPath bmodesPath precompPath fastPath beamDynPath
global crunchPath turbsimPath iecwindPath mbcPath adamsPath
global numadPath

% Helper to check executable existence

ansysPath   = fullfile(designCodesDir, 'ANSYS',   'ansys.exe');
precompPath = fullfile(designCodesDir, 'PreComp', 'PreComp.exe');
bmodesPath  = fullfile(designCodesDir, 'BModes',  'BModes.exe');
beamDynPath  = fullfile(designCodesDir, 'BeamDyn',  'BeamDyn_Driver_x64.exe');
fastPath    = fullfile(designCodesDir, 'FAST',    'FAST.exe');
crunchPath  = fullfile(designCodesDir, 'Crunch',  'Crunch.exe');
turbsimPath = fullfile(designCodesDir, 'TurbSim', 'TurbSim.exe');
iecwindPath = fullfile(designCodesDir, 'IECWind', 'IECWind.exe');
mbcPath     = fullfile(designCodesDir, 'MBC', 'Source');
adamsPath   = '';

%% 4. Add NuMAD (sibling folder)
if nargin < 1 || isempty(numadPath)
    numadRoot = fullfile(root, '..', 'NuMAD-3.0');
else
    numadRoot = numadPath;
end

numadSrc = fullfile(numadRoot, 'source');

if isfolder(numadSrc)
    addpath(genpath(numadSrc));
    numadPath = numadSrc; % set global
    fprintf('NuMAD loaded from: %s\n', numadSrc);
else
    warning('NuMAD source not found. Expected at: %s', numadSrc);
end

%% 5. Quick sanity report
fprintf('\n--- Setup Summary ---\n');
fprintf('WTLib root: %s\n', root);

checkPrint = @(name, p) fprintf('%-10s: %s\n', name, ternary(~isempty(p), 'OK', 'MISSING'));

checkPrint('ANSYS', ansysPath);
checkPrint('PreComp', precompPath);
checkPrint('BModes', bmodesPath);
checkPrint('BeamDyn', beamDynPath);
checkPrint('FAST', fastPath);
checkPrint('Crunch', crunchPath);
checkPrint('TurbSim', turbsimPath);
checkPrint('IECWind', iecwindPath);

if isfolder(mbcPath)
    fprintf('MBC      : OK\n');
else
    fprintf('MBC      : MISSING\n');
end

fprintf('NuMAD    : %s\n', ternary(isfolder(numadSrc), 'OK', 'MISSING'));
fprintf('----------------------\n\n');

%% 6. Mark as setup done
alreadySetup = true;
fprintf('WTLib setup complete.\n');

end


%% --- Small helper function ---
function out = ternary(cond, a, b)
if cond
    out = a;
else
    out = b;
end
end

function p = getExe(p)
    if exist(p, 'file') ~= 2
        p = '';
    end
end