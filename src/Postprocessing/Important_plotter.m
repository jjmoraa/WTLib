function [fig]=Important_plotter(paretoIdx, mod_mod_power_table, a_ref, n_ref, p_ref)
    % Plot all important distributions with n and p values in the legend
    
    % Preallocate important_n and important_p
    important_n = zeros(1, length(paretoIdx));
    important_p = zeros(1, length(paretoIdx));
    
    % Extract n and p values for each Pareto-optimal point
    for i = 1:length(paretoIdx)
        important_n(i) = mod_mod_power_table.("n")(paretoIdx(i));
        important_p(i) = mod_mod_power_table.("p")(paretoIdx(i));
    end

    % Define span
    span = 0:0.01:1;

    % Create figure
    fig=figure();
    hold on
    grid on
    box on

    % Colormap for better distinction
    colors = parula(length(paretoIdx));

    % Initialize legend entries (including extra slot for reference)
    legendEntries = cell(1, length(paretoIdx) + 1);
    
    for i = 1:length(paretoIdx)
        a = a_ref * (1 - span.^important_n(i)).^important_p(i);
        plot(span, a, 'Color', colors(i,:), 'LineWidth', 1.5);
        legendEntries{i} = sprintf('n = %.2f, p = %.2f', important_n(i), important_p(i));
        % legendEntries{i} = sprintf('n = %.2f, p = %.2f, n/p = %.4f', important_n(i), important_p(i), important_n(i)/important_p(i));%
    end
    
    % Reference curve
    a_ref_curve = a_ref * (1 - span.^n_ref).^p_ref;
    plot(span, a_ref_curve, 'k--', 'LineWidth', 2); % Dashed black reference line
    legendEntries{end} = 'Reference'; % Correctly add reference entry


    % Labels and title
    xlabel('Spanwise Position', 'FontSize', 12, 'FontWeight', 'bold')
    ylabel('Parameter a', 'FontSize', 12, 'FontWeight', 'bold')
    title('Pareto Front Solutions', 'FontSize', 14, 'FontWeight', 'bold')

    % Adjust number of legend columns dynamically
    numColumns = ceil(sqrt(length(legendEntries)))-2; % Auto-adjust based on entries
    if numColumns<=0
        numColumns=2;
    end
    legend(legendEntries, 'Location', 'southoutside', 'Orientation', 'horizontal', ...
           'NumColumns', numColumns, 'FontSize', 8)

    % Formatting
    set(gca, 'FontSize', 12, 'LineWidth', 1.2) % Better axis appearance
    set(gca, 'GridAlpha', 0.3, 'MinorGridAlpha', 0.2) % Lighter grid lines

    hold off
end
