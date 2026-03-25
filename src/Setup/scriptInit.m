% Initialization library
% By: J Mora

% Should I add the "addNumadPaths" and "addFrame3DD" here?

function [inputs,tsr,airfoils]=scriptInit(parentFolder)
    %read inputs
    % Open the text file for reading
    fid = fopen([parentFolder,'\Inputs\Driver.txt'], 'r');
    tsr = fscanf(fid, '%f', 1);fgetl(fid); % Read the tip speed ratio (tsr)
    fgetl(fid);
    airfoils = textscan(fid, '%f %s', 'HeaderLines', 1);
    fclose(fid);
    col1=cell2mat(airfoils(:,1));
    col2=cellfun(@string, airfoils(:,2), 'UniformOutput', false);
    col2 = [col2{:}];
    airfoils = table(col1,col2,'VariableNames',{'airfoil no','name'});
    
    % Open the text file for reading
    fid = fopen([parentFolder,'\Inputs\BladeSectionsv3.dat'], 'r');%CHECK!
    %assign parameters and read comments/discard them
    for i=1:4
        fgetl(fid);
    end
    inputs = textscan(fid, '%f %f %f %f %f %f %f', 'HeaderLines', 2);
    fclose(fid);
end