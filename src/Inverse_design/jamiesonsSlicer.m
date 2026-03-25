function jamiesonsSlicer(jamiesonsCase,folderName) % Define the number of parts
    % Create the folder if it doesn't exist
    if ~exist(folderName, 'dir')
        mkdir(folderName);
    end

    % Loop through and save each struct separately
    for i = 1:length(jamiesonsCase)
        % Create a filename for each struct
        partFilename = fullfile(folderName, sprintf('jamiesonsCase_part%d.mat', i));

        % Save the current struct
        partStruct = jamiesonsCase(i);
        save(partFilename, 'partStruct', '-v7.3');
        fprintf('Saved part %d to %s\n', i, partFilename); % Print progress
    end
end