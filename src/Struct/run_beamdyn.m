function [status, cmdout] = run_beamdyn(beamdynExe, output_filename, inputDir)
%RUN_BEAMDYN Run BeamDyn in a specific folder
%
% Inputs:
%   output_filename - name of the driver/input file (without _driver_file.inp)
%   inputDir        - folder where the .inp and outputs should go
%
% Outputs:
%   status - system exit code
%   cmdout - captured command output

% Save current folder and ensure return
origDir = pwd;
cleanupObj = onCleanup(@() cd(origDir));

% Switch to folder with input/output files
cd(inputDir);

% Build system command
cmd = sprintf('"%s" %s_driver_file.inp > output.log 2>&1', beamdynExe, output_filename);

% Execute
[status, cmdout] = system(cmd);

end