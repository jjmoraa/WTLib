%main
clear
clc

% Get the current working directory (current folder)
currentFolder = pwd;
% Get the parent folder (folder above the current folder)
parentFolder = fileparts(currentFolder);

%read inputs
% Open the text file for reading
fid = fopen([parentFolder,'\Inputs\NREL15MW.txt'], 'r');
%assign parameters and read comments/discard them
fgetl(fid);fgetl(fid);
R = fscanf(fid, '%f', 1);fgetl(fid); %read radius
tsr = fscanf(fid, '%f', 1);fgetl(fid); % Read the tip speed ratio (tsr)
fgetl(fid);fgetl(fid);
chord = fscanf(fid, '%f', 1);fgetl(fid); % Read the chord
twist = fscanf(fid, '%f', 1);fgetl(fid); % Read the twist
r = fscanf(fid, '%f', 1);fgetl(fid); % Read the radius/spanwise position (r)
fclose(fid); % Close the file
% Open the text file for reading
fid = fopen([parentFolder,'\Airfoils\SNL-FFA-W3-500.dat'], 'r');
for i=1:52
    fgetl(fid);
end
data = textscan(fid, '%f %f %f %f', 'HeaderLines', 2);
fclose(fid); % Close the file
table = array2table(cell2mat(data),'VariableNames',{'alpha rad','c_l','c_d','c_m'});

bem_solver_v2_00;