function [fig, mod_mod_power_table, paretoX, paretoY, paretoIdx, globalIdx] = ParetoFront_v3_minmin(powertable, obj1, obj2, obj3)
    % ParetoFront_v3_minmin(table, string, string)
    % This version minimizes both objectives (min-min Pareto front)
    
    % ================================
    % Filter invalid tip deflection values
    % ================================
    if strcmp(obj1, 'tip deflection')
        mod_mod_power_table = powertable(powertable.('tip deflection') > 0.00, :);
    elseif strcmp(obj2, 'tip deflection')
        mod_mod_power_table = powertable(powertable.('tip deflection') > 0.00, :);
    elseif strcmp(obj3, 'tip deflection')
        mod_mod_power_table = powertable(powertable.('tip deflection') >= 0.00, :);
    else
        mod_mod_power_table = powertable;
    end

    % ================================
    % Extract objectives
    % ================================
    Y = mod_mod_power_table.(obj1);  % Objective 1 (minimize)
    X = mod_mod_power_table.(obj2);  % Objective 2 (minimize)
    
    if strcmp(obj3, 'n/p')
        c = mod_mod_power_table.('n') ./ mod_mod_power_table.('p');
    else
        c = mod_mod_power_table.(obj3);
    end

    % ================================
    % Normalize objectives
    % ================================
    X_norm = (X - min(X)) / (max(X) - min(X));
    Y_norm = (Y - min(Y)) / (max(Y) - min(Y));

    % ================================
    % Weighted-sum method (min-min)
    % ================================
    numWeights = 100;
    weights = linspace(0, 1, numWeights);
    paretoIdx = [];

    for w = weights
        % For minimization, lower is better for both terms
        weightedScores = - (w * Y_norm + (1 - w) * X_norm);
        [~, bestIdx] = max(weightedScores); % max because we negated
        paretoIdx = unique([paretoIdx; bestIdx]);
    end

    % ================================
    % Extract and sort Pareto front
    % ================================
    paretoX = X(paretoIdx);
    paretoY = Y(paretoIdx);

    [paretoX, idx] = sort(paretoX);
    paretoY = paretoY(idx);
    sortedParetoIdx = paretoIdx(idx);

    % ================================
    % Get corresponding indices in full table
    % ================================
    globalIdx = zeros(length(paretoIdx), 1);
    for i = 1:length(paretoIdx)
        n_val = mod_mod_power_table.('n')(sortedParetoIdx(i));
        p_val = mod_mod_power_table.('p')(sortedParetoIdx(i));
        globalIdx(i) = find(abs(powertable.('n') - n_val) < 1e-3 & abs(powertable.('p') - p_val) < 1e-3, 1);
    end

    % ================================
    % Color mapping
    % ================================
    if or(strcmp(obj3, 'tip deflection'), strcmp(obj3, 'mass'))
        thresholdValue = 0;
        specialIdx = find(c == thresholdValue);
    elseif strcmp(obj3, 'n/p')
        specialIdx = find(c > 50);
    else
        specialIdx = find(c > 50);
    end
    regularIdx = setdiff(1:length(c), specialIdx);

    % ================================
    % Plot
    % ================================
    fig = figure();
    colormap jet;
    scatter(X(regularIdx), Y(regularIdx), 50, c(regularIdx), 'filled'); hold on;

    if ~isempty(specialIdx)
        scatter(X(specialIdx), Y(specialIdx), 100, 'kx', 'LineWidth', 2);
    end

    scatter(paretoX, paretoY, 60, 'ko');
    plot(paretoX, paretoY, 'r-', 'LineWidth', 2);
    
    colorbar;
    caxis([min(c(regularIdx)) max(c(regularIdx))]);
    xlabel(obj2);
    ylabel(obj1);
    title('Pareto Front (Min–Min) with Color Mapping');
    legend('Regular Solutions', 'Not Converged', 'Pareto Front', 'Location', 'best');
    hold off;
end
