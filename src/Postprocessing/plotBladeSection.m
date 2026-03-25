function plotBladeSection(blade,spanwise_position)

bom=blade.bom;
geometry=blade.profiles(:,:,spanwise_position)*blade.ichord(spanwise_position);
%geometry=resamplePolygon(geometry, 2000);
keypoints=blade.keypoints(:,:,spanwise_position);
% plotBladeSection plots a cross-section of the blade at a given spanwise position
%
% Inputs:
%   bom         - Cell array describing the Bill of Materials
%   geometry    - Structure where each field is a region name with its (x,y) coordinates
%   spanStation - Target spanwise position (m) where to plot the section

% Define material list and their corresponding colors

%Extracted from Blade Def
% This method updates the Bill-of-Materials
            % Cell array columns of blade.bom: 
            % 1. Layer #
            % 2. Material ID
            % 3. Component or region name
            % 4. Begin station   (m)
            % 5. End station     (m)
            % 6. Max width       (m)
            % 7. Average width   (m)
            % 8. 3D area         (m^2)
            % 9. Layer thickness (mm)
            % 10. Computed dry layer weight (g)
            %
materialList={};
for j=1:length(blade.materials)
    materialList {j} = blade.materials(j).name;
end


materialColors = parula(length(materialList ));

figure;
hold on;
axis equal;
grid on;
title(sprintf('Blade Cross Section at %.1f%% Span', spanwise_position));
xlabel('x [m]');
ylabel('y [m]');

legendEntries = {};
legendHandles = [];


%parts of the BOM
% BOMparts={};
% BOMparts{1}='hp';BOMparts{2}='lp';BOMparts{3}='sw(1)';BOMparts{4}='sw(2)';
% Loop over BOM to find applicable layers
    for i =1:4
    % Initialize shrunken geometry per region
    shifted_keypoints=keypoints;
    shifted_pts = geometry;  % Copy original geometry to shrink layer by layer

    % Select the correct BOM
        if i==1
            bomPart = bom.hp;
            bomIndices = [blade.bomIndices.hp(:,3)  blade.bomIndices.hp(:,4)];
        elseif i==2
            bomPart = bom.lp;
            bomIndices = [blade.bomIndices.lp(:,3)  blade.bomIndices.lp(:,4)];
        elseif i==3
            bomPart = bom.sw{1}; % <-- sw{1}, not sw(1)
            bomIndices = [3  4];
        elseif i==4
            bomPart = bom.sw{2};
            bomIndices = [3  4];
        else
            error('Unknown BOM part %s', partName);
        end
        
        for j = 1:length(bomPart)
        layerStart = bomPart(j,4); % Begin Station (m)
        layerEnd   = bomPart(j,5);   % End Station (m)
        
            if (blade.ispan(spanwise_position) >= cell2mat(layerStart)) && (blade.ispan(spanwise_position) <= cell2mat(layerEnd))
            matID = bomPart(j,2);
            regionName = bomPart(j,3);  % assuming this is a string or char
                           
                thickness_mm = bomPart(j,9);  % thickness for shifting
                thickness_m = cell2mat(thickness_mm) * 1e-3;     % convert mm -> meters
                
                % Compute inward shifted polygon
                if or(i==3,i==4)
                    [shifted_pts,shifted_keypoints] = shiftPolygonInward(geometry, thickness_m, shifted_keypoints(bomIndices,1:2), shifted_keypoints(:,1:2));
                else 
                    % Get indices
                    start_idx = bomIndices(j,1);
                    end_idx   = bomIndices(j,2);
                    
                    % Initialize start and finish
                    if start_idx == 1
                        start = shifted_pts(1,:);
                    else
                        start = shifted_keypoints(start_idx-1,1:2);
                        %start=start_idx-1;
                    end
                    
                    if end_idx == 13
                        finish = shifted_pts(end,:);
                    else
                        finish = shifted_keypoints(end_idx-1,1:2);
                        %finish=end_idx-1;
                    end


                    [shifted_pts,shifted_keypoints] = shiftPolygonInward(geometry, thickness_m, [start;finish], shifted_keypoints(:,1:2));
                end

                h = plot(shifted_pts(:,1), shifted_pts(:,2), '.', ...
                 'Color', materialColors(cell2mat(matID),:), ...
                 'MarkerFaceColor', materialColors(cell2mat(matID),:), ...
                 'MarkerSize', 6); % you can adjust MarkerSize

                
                % Save for legend
                legendHandles(end+1) = h; %#ok<AGROW>
                legendEntries{end+1} = materialList{cell2mat(matID)}; %#ok<AGROW>
            else
                warning('No geometry found for region "%s". Skipping.', char(regionName));
            end
        end
    end


% Create legend without duplicate entries
[uniqueEntries, idxUnique] = unique(legendEntries, 'stable');
legend(legendHandles(idxUnique), uniqueEntries, 'Location', 'bestoutside');

hold off;

end


function [shifted_pts,shifted_keypoints] = shiftPolygonInward(pts, thickness, interest_keypoints, keypoints)
% Shift polygon pts inward by thickness along normal vectors

% Close the polygon if not already closed
if ~isequal(pts(1,:), pts(end,:))
    pts = [pts; pts(1,:)];
end

% Compute segment midpoints and normals
N = size(pts,1) - 1;
normals = zeros(N,2);

for i = 1:N
    dx = pts(i+1,1) - pts(i,1);
    dy = pts(i+1,2) - pts(i,2);
    len = hypot(dx, dy);
    normals(i,:) = [-dy, dx] / len; % Rotate 90 deg counterclockwise and normalize
end

% Average normals at each vertex
vertexNormals = zeros(N,2);
for i = 1:N
    if i == 1
        prev = normals(end,:);
    else
        prev = normals(i-1,:);
    end
    curr = normals(i,:);
    vertexNormals(i,:) = (prev + curr) / 2;
    vertexNormals(i,:) = vertexNormals(i,:) / norm(vertexNormals(i,:) + 1e-12);
end

% Initialize shifted points as the original ones
shifted_pts = pts(1:end-1,:);

% Find indices closest to the two keypoints
dists1 = vecnorm(shifted_pts - interest_keypoints(1,:), 2, 2);
[~, idx1] = min(dists1);

dists2 = vecnorm(shifted_pts - interest_keypoints(2,:), 2, 2);
[~, idx2] = min(dists2);

% Ensure idx1 <= idx2
if idx1 > idx2
    temp = idx1;
    idx1 = idx2;
    idx2 = temp;
end

% Shift only between idx1 and idx2
shifted_pts(idx1:idx2,:) = shifted_pts(idx1:idx2,:) - thickness * vertexNormals(idx1:idx2,:);

% Shift each keypoint to its closest vertex in original polygon
numKeys = size(keypoints,1);
shifted_keypoints = zeros(numKeys,2);

for k = 1:numKeys
    dists = vecnorm(pts(1:end-1,:) - keypoints(k,:), 2, 2);
    [~, idx] = min(dists);
    shifted_keypoints(k,:) = shifted_pts(idx,:);
end

% Close the shifted polygon
shifted_pts = [shifted_pts; shifted_pts(1,:)];
end


function new_pts = resamplePolygon(pts, n_points)
% Resample a polygon to have n_points equally spaced along arc length

% Close polygon if not already
if ~isequal(pts(1,:), pts(end,:))
    pts = [pts; pts(1,:)];
end

% Compute cumulative arc length
deltas = diff(pts, 1, 1);
segment_lengths = sqrt(sum(deltas.^2, 2));
cum_length = [0; cumsum(segment_lengths)];

% Remove duplicate final point for interpolation
pts_no_repeat = pts(1:end-1,:);
cum_length = cum_length(1:end-1);

% New query points evenly spaced along arc
new_lengths = linspace(0, cum_length(end), n_points);

% Interpolate x and y separately
new_x = interp1(cum_length, pts_no_repeat(:,1), new_lengths, 'linear');
new_y = interp1(cum_length, pts_no_repeat(:,2), new_lengths, 'linear');

new_pts = [new_x', new_y'];
end

