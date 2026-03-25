% a-n-p curve exploration

function grid_points=JamiesonsBoundGenerator(a0,n_ref,p_ref,curve,n_min,n_max,resolution)

addpath('C:\Users\josej\Documents\MATLAB BEM Solver\Scripts\distmesh\');
x = 0:0.01:1;

% Reference curve
a_ref = a0 * (1 - x.^n_ref).^p_ref;

%% Generate heatmap
% Define n and p ranges
n_vals = 0.01:0.1:10;
p_vals = 0.01:0.1:10;
num_n = length(n_vals);
num_p = length(p_vals);

% Preallocate matrix
mean_shift = zeros(num_n, num_p);

% Loop through n and p values
for i = 1:num_n
    for j = 1:num_p
        n = n_vals(i);
        p = p_vals(j);
        a_try = a0 * (1 - x.^n).^p;
        shift = (a_ref(1:end-1) - a_try(1:end-1)) ./ a_ref(1:end-1);
        mean_shift(i, j) = mean(shift);
    end
end

%Heatmap visualization
figure()
imagesc(n_vals, p_vals, mean_shift);
colormap jet;
colorbar;
xlabel('n');
ylabel('p');
title('Mean Shift Heatmap with Contours');
set(gca, 'YDir', 'normal');

% Overlay contour lines to show regions with the same mean shift
hold on;
[C, h] = contour(p_vals, n_vals, mean_shift, 'k', 'LineWidth', 2);  % No level input = auto levels
hold off;

%% separate the lines from the plot
contour_levels = [];
n_points = {};
p_points = {};

col = 1;
while col < size(C, 2)
    level = C(1, col);  % Contour level
    num_points = C(2, col);  % Number of (x, y) points

    % Store level and corresponding points
    contour_levels(end + 1) = level;
    n_points{end + 1} = C(1, col + 1 : col + num_points);
    p_points{end + 1} = C(2, col + 1 : col + num_points);
    
    % Move to the next contour segment
    col = col + num_points + 1;
end

% Theres a good chance there's much much more to this and we're just being
% stupid

%% Select a curve to fit
bound = [cell2mat(n_points(curve))', cell2mat(p_points(curve))'];

% Define the model for a cubic polynomial: p = C1*n^3 + C2*n^2 + C3*n + C4
fitfun = fittype(@(C1, C2, C3, C4, n) C1*n.^3 + C2*n.^2 + C3*n + C4, ...
    'independent', 'n', 'coefficients', {'C1', 'C2', 'C3', 'C4'});

% Initial guess for the coefficients [C1, C2, C3, C4]
startPoint = [0, 0, 0, 0];  % All coefficients start at 0

% Perform the fit with the initial guess
[fitcurve, gof] = fit(bound(:,1), bound(:,2), fitfun, 'StartPoint', startPoint);

% Plot the original data points
figure();
scatter(bound(:,1), bound(:,2), 'b', 'DisplayName', 'Data Points'); % 'b' for blue

% Hold the current plot to overlay the fit
hold on;

% Generate a set of values for n to plot the fitted curve
n_vals = linspace(min(bound(:,1)), max(bound(:,1)), 100);

% Evaluate the fitted curve
fit_vals = feval(fitcurve, n_vals);

% Plot the fitted curve
plot(n_vals, fit_vals, 'r-', 'DisplayName', 'Fitted Curve'); % 'r-' for red line
clabel(C, h, 'FontSize', 10, 'LabelSpacing', 9999);  % Large spacing = effectively one label
% Add labels and legend
xlabel('n');
ylabel('p');
legend('show');

% Release the hold on the plot
hold off;

%% map aerea bounded by fit

grid_points=[];
% Define cubic function and upper boundary (y = C)
c1=fitcurve.C1;
c2=fitcurve.C2;
c3=fitcurve.C3;
c4=fitcurve.C4;
f = @(n) c1*n.^3 + c2*n.^2 + c3*n + c4;  % Cubic function

% define x points in which evaluation must occurr
n_points=linspace(n_min,n_max,resolution);  

step_size = (n_max - n_min) / (resolution - 1);

% Define the constant upper boundary y = c
p_min = n_min;
p_max = feval(f,n_points);  % Example: Upper boundary at y = 10 (adjust as needed)

% define y points in which evaluation must occurr
for i=1:length(p_max)
    p_points=p_min:step_size:p_max(i);
    % fix this later
    grid_points=[grid_points;[repmat(n_points(i),size(p_points))' ,p_points']];
    %grid_points=[grid_points;[p_points',repmat(n_points(i),size(p_points))']];
end

%filter negative values
%grid_points = grid_points(:, all(grid_points > 0, 2));
grid_points = grid_points(all(grid_points > 0, 2), :);

% Plot the result
figure()
scatter(grid_points(:,1),grid_points(:,2))
title('2D Mesh of the Region');
xlabel('n');
ylabel('p');
axis equal;
end