function materialCostDatabase = read_material_costs(filename)
%example use:
% read_material_costs("C:\Users\josej\Documents\MATLAB BEM Solver\Inputs\MaterialCostDatabase.txt")
    % Open the file
    fid = fopen(filename, 'r');
    if fid == -1
        error('Cannot open file: %s', filename);
    end

    % Skip header
    headerLine = fgetl(fid);

    % Initialize storage
    MaterialID = [];
    MaterialName = {};
    Cost = [];
    Unit = {};
    Comment = {};

    % Read lines
    while ~feof(fid)
        line = fgetl(fid);
        if isempty(line) || all(isspace(line))
            continue;
        end

        % Split the line (tabs or multiple spaces)
        parts = regexp(strtrim(line), '\t+|\s{2,}', 'split');

        % Handle line based on number of parts
        id = str2double(parts{1});
        name = parts{2};

        % Default missing values
        cost = NaN; unit = ''; comment = '';

        if numel(parts) >= 3 && ~isempty(parts{3})
            cost = str2double(parts{3});
        end
        if numel(parts) >= 4
            unit = parts{4};
        end
        if numel(parts) >= 5
            comment = strjoin(parts(5:end), ' ');
        end

        % Append to arrays
        MaterialID(end+1,1) = id;
        MaterialName{end+1,1} = name;
        Cost(end+1,1) = cost;
        Unit{end+1,1} = unit;
        Comment{end+1,1} = comment;
    end

    fclose(fid);

    % Create table
    materialCostDatabase = table(MaterialID, MaterialName, Cost, Unit, Comment);
end
