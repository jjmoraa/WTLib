function [fig]=Important_plotter(paretoIdx, mod_mod_power_table, a_ref, n_ref, p_ref, suffix)
    % Plot all important distributions with consistent formatting
    
    if nargin < 6 || isempty(suffix)
        suffix = '';
    else
        suffix = [' - ' char(suffix)];
    end

    %% --- Extract n and p values ---
    important_n = zeros(1, length(paretoIdx));
    important_p = zeros(1, length(paretoIdx));
    
    for i = 1:length(paretoIdx)
        important_n(i) = mod_mod_power_table.("n")(paretoIdx(i));
        important_p(i) = mod_mod_power_table.("p")(paretoIdx(i));
    end

    %% --- Define span ---
    span = 0:0.01:1;

    %% --- Create figure ---
    fig = figure( ...
    'Name', ['Pareto Front Distributions' suffix], ...
    'NumberTitle', 'off');
    hold on

    %% --- Colormap (match other plots) ---
    cmap = flipud(winter);                      % full colormap
    colors = interp1( ...
        linspace(0,1,size(cmap,1)), ...
        cmap, ...
        linspace(0,1,length(paretoIdx)) ...
    );

    %% --- Plot Pareto curves ---
    legendEntries = cell(1, length(paretoIdx) + 1);

    for i = 1:length(paretoIdx)
        a = a_ref * (1 - span.^important_n(i)).^important_p(i);
        plot(span, a, ...
            'Color', colors(i,:), ...
            'LineWidth', 1.5);

        legendEntries{i} = sprintf('$n = %.2f,\\; p = %.2f$', ...
            important_n(i), important_p(i));
    end

    %% --- Reference curve ---
    a_ref_curve = a_ref * (1 - span.^n_ref).^p_ref;
    hRef = plot(span, a_ref_curve, ...
        'k--', ...
        'LineWidth', 2);

    legendEntries{end} = '$\mathrm{Reference}$';

    %% --- Axes formatting ---
    ax = gca;
    set(ax, ...
        'FontName', 'Times', ...
        'FontSize', 12, ...
        'LineWidth', 1, ...
        'Box', 'on', ...
        'Layer', 'top', ...
        'TickLabelInterpreter', 'latex');

    xlabel('$\mathrm{Spanwise\ Position}$', ...
        'Interpreter','latex','FontSize',14);

    ylabel('$a$', ...
        'Interpreter','latex','FontSize',14);

    % title('$\mathrm{Pareto\ Front\ Distributions}$', ...
    %     'Interpreter','latex','FontSize',14);

    %% --- Grid ---
    grid on;
    ax.GridColor = [0.7 0.7 0.7];
    ax.GridAlpha = 0.2;
    ax.MinorGridAlpha = 0.1;
    ax.XMinorGrid = 'on';
    ax.YMinorGrid = 'on';

    %% --- Legend ---
    numColumns = ceil(sqrt(length(legendEntries)));
    if numColumns <= 1
        numColumns = 2;
    end

    legend(legendEntries, ...
        'Location','southoutside', ...
        'Orientation','horizontal', ...
        'NumColumns', numColumns, ...
        'Interpreter','latex', ...
        'FontSize', 10);

    hold off
end