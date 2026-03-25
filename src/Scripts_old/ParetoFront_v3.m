function [fig,mod_mod_power_table, paretoX, paretoY, paretoIdx, globalIdx] = ParetoFront_v3(powertable, obj1, obj2, obj3)
    % ParetoFront_v2(table, string, string)
    %this will plot a heatmap overlay on with a third parameter
    
    % Filter incorrect tip deflection values
    if strcmp(obj1, 'tip deflection')
        mod_mod_power_table = powertable(powertable.('tip deflection') > 0.00, :);
    elseif strcmp(obj2, 'tip deflection')
        mod_mod_power_table = powertable(powertable.('tip deflection') > 0.00, :);
    elseif strcmp(obj3, 'tip deflection')
        mod_mod_power_table = powertable(powertable.('tip deflection') >= 0.00, :);
    else
        mod_mod_power_table = powertable;
    end



    Y = mod_mod_power_table.(obj1);  % First objective (maximize)
    X = mod_mod_power_table.(obj2);  % Second objective (minimize)
    
    if strcmp(obj3,'n/p')
        c = mod_mod_power_table.('n')./mod_mod_power_table.('p');
    else
        c = mod_mod_power_table.(obj3); % Replace 'thirdParam' with your actual field name
    end

    % Normalize objectives for scalarization
    X_norm = (X - min(X)) / (max(X) - min(X));
    Y_norm = (Y - min(Y)) / (max(Y) - min(Y));

    % Define weight range (e.g., from 0 to 1)
    numWeights = 100;
    weights = linspace(0, 1, numWeights);

    paretoIdx = [];

    % Loop over different weight combinations
    for w = weights
        weightedScores = w * Y_norm - (1 - w) * X_norm;
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
    
    globalIdx = zeros(length(paretoIdx), 1); % Preallocate the index array
    
    for i = 1:length(paretoIdx)
        % Extract the current values from the Pareto table
        n_val = mod_mod_power_table.('n')(sortedParetoIdx(i));
        p_val = mod_mod_power_table.('p')(sortedParetoIdx(i));
        
        % Find the matching row in the full power table
        globalIdx(i) = find(abs(powertable.('n') - n_val) < 1e-3 & abs(powertable.('p') - p_val) < 1e-3, 1);
    end

    % Set the threshold value for obj3 to mark as 'x'
    if or(strcmp(obj3,'tip deflection'),strcmp(obj3,'mass'))
    thresholdValue = 0; % <-- Change this to your desired obj3 value
    specialIdx = find(c == thresholdValue);
    elseif strcmp(obj3,'n/p')
        specialIdx = find(c > 50);
    else
        specialIdx = find(c > 50);
    end
    regularIdx = setdiff(1:length(c), specialIdx);

    % Plot results
    fig = figure();
    colormap jet; % Set the colormap (you can choose 'jet', 'parula', etc.)
    
    % % Scatter plot with color mapping based on the third parameter
    % scatter(X, Y, 50, c, 'filled'); hold on; % Color scale points
    % 
    % % Plot the Pareto front on top with distinct color

    % Scatter plot with color mapping for regular points
    scatter(X(regularIdx), Y(regularIdx), 50, c(regularIdx), 'filled'); hold on;
    
    % Scatter plot for special points with 'x' marker
    if specialIdx~=0
        scatter(X(specialIdx), Y(specialIdx), 100, 'kx', 'LineWidth', 2);
    end

    scatter(paretoX, paretoY, 60, 'ko'); % Pareto front in red
    plot(paretoX, paretoY, 'r-', 'LineWidth', 2); % Connect Pareto points
    
    % Annotate each Pareto-optimal point with its index
    % for i = 1:length(paretoX)
    %     text(paretoX(i), paretoY(i) - 0.02 * (max(Y) - min(Y)), ...
    %         sprintf('n = %.2f\np = %.2f', ...
    %         mod_mod_power_table.('n')(sortedParetoIdx(i)), ...
    %         mod_mod_power_table.('p')(sortedParetoIdx(i))), ...
    %         'FontSize', 8, 'Color', 'black', ...
    %         'HorizontalAlignment', 'center');
    % end
    
    % Add a colorbar to indicate the mapping of the third parameter
    colorbar;
    caxis([min(c(regularIdx)) max(c(regularIdx))]); % Set color axis limits
    xlabel(obj2);
    ylabel(obj1);
    title('Pareto Front with Color Mapping');
    %legend('Regular Solutions', sprintf('Special Points (obj3 = %.2f)', thresholdValue), 'Pareto Front', 'Location', 'best');
    legend('Regular Solutions','not converged', 'Pareto Front', 'Location', 'best');
    hold off;

end