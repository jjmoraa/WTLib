function dataTable = read_BeamDyn_out(output_filename)
    % Reads a BeamDyn output file and organizes it into a table with nodal outputs side by side.

    filename=[output_filename,'_driver_file.out'];
    % Open the file
    fid = fopen(filename, 'r');
    if fid == -1
        error('Could not open the file: %s', filename);
    end

    % Read lines until we find the column headers
    headerLine = '';
    while ischar(headerLine)
        headerLine = fgetl(fid);
        if contains(headerLine, 'Time')  % Find the header row
            columnNames = strsplit(strtrim(headerLine)); % Extract headers
            break;
        end
    end

    % Read the data
    data = [];
    while ~feof(fid)
        line = fgetl(fid);
        if ischar(line)
            data = [data; str2double(strsplit(strtrim(line)))];
        end
    end

    fclose(fid);

    % Convert to table
    dataTable = array2table(data, 'VariableNames', columnNames);
    
    % Display first few rows
    disp(dataTable(end, :));  % Preview first 5 rows
end
