function jamiesonsWrapper(numParts,folderName)
% Initialize an empty array to hold the parts
reconstructedJamiesonsCase = [];

% Loop through and load each part
for part = 1:numParts
    % Load the part file
    partFilename = [folderName, sprintf('jamiesonsCase_part%d.mat', part)];
    loadedPart = load(partFilename, 'partStruct');
    
    % Append the part to the reconstructed structure
    reconstructedJamiesonsCase = [reconstructedJamiesonsCase, loadedPart.partStruct];
end

% Now `reconstructedJamiesonsCase` holds the full structure

end