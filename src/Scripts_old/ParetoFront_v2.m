function [fig,mod_mod_power_table, paretoX, paretoY, paretoIdx] = ParetoFront_v2(powertable, obj1, obj2)
    % ParetoFront_v2(table, string, string)
    
    % Filter incorrect tip deflection values
    if strcmp(obj1, 'tip deflection')
        mod_mod_power_table = powertable(powertable.('tip deflection') > 0.90, :);
    elseif strcmp(obj2, 'tip deflection')
        mod_mod_power_table = powertable(powertable.('tip deflection') > 0.90, :);
    else
        mod_mod_power_table = powertable;
    end

    X = mod_mod_power_table.(obj1);  % First objective (maximize)
    Y = mod_mod_power_table.(obj2);  % Second objective (minimize)

    % Normalize objectives for scalarization
    X_norm = (X - min(X)) / (max(X) - min(X));
    Y_norm = (Y - min(Y)) / (max(Y) - min(Y));

    % Define weight range (e.g., from 0 to 1)
    numWeights = 100;
    weights = linspace(0, 1, numWeights);

    paretoIdx = [];

    % Loop over different weight combinations
    for w = weights
        weightedScores = w * X_norm - (1 - w) * Y_norm;
        [~, bestIdx] = max(weightedScores); % Find best solution for current weights
        paretoIdx = unique([paretoIdx; bestIdx]); % Store unique Pareto-optimal indices
    end

    % Extract Pareto front
    paretoX = X(paretoIdx);
    paretoY = Y(paretoIdx);

    % Sort Pareto front for plotting
    [paretoX, idx] = sort(paretoX);
    paretoY = paretoY(idx);
    sortedParetoIdx = paretoIdx(idx); % Keep track of sorted indices

    % Plot results
    fig=figure();
    scatter(X, Y, 'bo', 'filled'); hold on; % All points in blue
    scatter(paretoX, paretoY, 'ro', 'filled'); % Pareto front in red
    plot(paretoX, paretoY, 'r-', 'LineWidth', 2); % Connect Pareto points

    % Annotate each Pareto-optimal point with its index
    for i = 1:length(paretoX)
        text(paretoX(i), paretoY(i) - 0.02 * (max(Y) - min(Y)), ...
        sprintf('n = %.2f\np = %.2f', ...
        mod_mod_power_table.( 'n' )(sortedParetoIdx(i)), ...
        mod_mod_power_table.( 'p' )(sortedParetoIdx(i))), ...
        'FontSize', 8, 'Color', 'black', ...
        'HorizontalAlignment', 'center');
    end

    xlabel(obj1);
    ylabel(obj2);
    title('Pareto Front using Weighted Sum Method');
    legend('All Solutions', 'Pareto Front', 'Location', 'best');
    hold off;
end
