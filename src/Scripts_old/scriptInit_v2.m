% Initialization library
% By: J Mora

% Should I add the "addNumadPaths" and "addFrame3DD" here?

function [inputs,airfoils]=scriptInit_v2(parentFolder)
    %read inputs
    % Open the text file for reading
    % fid = fopen([parentFolder,'\Inputs\Driver.txt'], 'r');
    % fgetl(fid);
    % airfoils = textscan(fid, '%f %s', 'HeaderLines', 1);
    % fclose(fid);
    % col1=cell2mat(airfoils(:,1));
    % col2=cellfun(@string, airfoils(:,2), 'UniformOutput', false);
    % col2 = [col2{:}];
    % Open the text file for reading
    fid = fopen([parentFolder,'\Inputs\IEA-15-240-RWT_AeroDyn15_blade.dat'], 'r');%CHECK!
    %assign parameters and read comments/discard them
    for i=1:4
        fgetl(fid);
    end
    inputs = textscan(fid, '%f %f %f %f %f %f %f %f %f %f', 'HeaderLines', 2);
    fclose(fid);

    dummy=cell2mat(inputs(end,7));
    for i=1:dummy(end)
        col1(i)=i;
        col2(i)=i-1;
    affile=sprintf('%s\\Airfoils\\IEA-15-240-RWT_AF%02d_Coords.txt', ...
                 parentFolder,i-1);
        rewriteAirfoilFile(affile)
    end
    airfoils = table(col1',col2','VariableNames',{'airfoil no','name'});
    
end

function rewriteAirfoilFile(filename)
    % Read the file as lines
    fid = fopen(filename, 'r');
    lines = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
    fclose(fid);
    lines = lines{1};
    
    % Check if the file is already formatted correctly
    if any(contains(lines, '<reference>')) && any(contains(lines, '<coords>'))
        fprintf('File "%s" is already correctly formatted. No changes made.\n', filename);
        return;
    end
    
    % Extract reference coordinate (assumed to be after "x/c y/c" heading)
    refIndex = find(contains(lines, 'x/c        y/c'), 1) + 1;
    referenceCoord = strtrim(lines{refIndex});
    
    % Extract coordinates (everything after the reference coordinate)
    coords = lines(refIndex + 2:end); % Skipping blank/comment lines
    coords = coords(~contains(coords, '!')); % Remove comment lines if any
    
    % Write the new formatted file
    fid = fopen(filename, 'w');
    fprintf(fid, '<reference>\n%s\n</reference>\n', referenceCoord);
    fprintf(fid, '<coords>\n');
    for i = 1:length(coords)
        fprintf(fid, '%s\n', coords{i});
    end
    fprintf(fid, '</coords>\n');
    fclose(fid);
    
    fprintf('File "%s" has been reformatted successfully.\n', filename);
end
