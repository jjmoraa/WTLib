% a-n-p curve exploration
a0 = 0.316;
n_ref = 4.335;
p_ref = 0.1083;
x = 0:0.01:1;

% Reference curve
a_ref = a0 * (1 - x.^n_ref).^p_ref;

%% Generate heatmap
% Define n and p ranges
n_vals = 0.01:0.01:10;
p_vals = 0.01:0.01:10;
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
x_points = {};
y_points = {};

col = 1;
while col < size(C, 2)
    level = C(1, col);  % Contour level
    num_points = C(2, col);  % Number of (x, y) points

    % Store level and corresponding points
    contour_levels(end + 1) = level;
    x_points{end + 1} = C(1, col + 1 : col + num_points);
    y_points{end + 1} = C(2, col + 1 : col + num_points);
    
    % Move to the next contour segment
    col = col + num_points + 1;
end

% Theres a good chance there's much much more to this and we're just being
% stupid

%% Select a curve to fit
curve = 3;
bound = [cell2mat(x_points(curve))', cell2mat(y_points(curve))'];

% Define the model for a cubic polynomial: p = C1*n^3 + C2*n^2 + C3*n + C4
fitfun = fittype(@(C1, C2, C3, C4, n) C1*n.^3 + C2*n.^2 + C3*n + C4, ...
    'independent', 'n', 'coefficients', {'C1', 'C2', 'C3', 'C4'});

% Initial guess for the coefficients [C1, C2, C3, C4]
startPoint = [0, 0, 0, 0];  % All coefficients start at 0

% Perform the fit with the initial guess
[fitcurve, gof] = fit(bound(:,1), bound(:,2), fitfun, 'StartPoint', startPoint);

% Plot the original data points
figure;
scatter(bound(:,1), bound(:,2), 'b', 'DisplayName', 'Data Points'); % 'b' for blue

% Hold the current plot to overlay the fit
hold on;

% Generate a set of values for n to plot the fitted curve
n_vals = linspace(min(bound(:,1)), max(bound(:,1)), 100);

% Evaluate the fitted curve
fit_vals = feval(fitcurve, n_vals);

% Plot the fitted curve
plot(n_vals, fit_vals, 'r-', 'DisplayName', 'Fitted Curve'); % 'r-' for red line

% Add labels and legend
xlabel('n');
ylabel('p');
legend('show');

% Release the hold on the plot
hold off;