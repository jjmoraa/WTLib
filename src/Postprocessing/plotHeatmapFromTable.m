function fig = plotHeatmapFromTable(dataTable, xField, yField, zField)
    % Extract x, y, and z data from the table
    x = dataTable.(xField);
    y = dataTable.(yField);
    z = dataTable.(zField);

    % Create a fine grid for smooth interpolation
    xUnique = linspace(min(x), max(x), 200); % fine resolution
    yUnique = linspace(min(y), max(y), 200);
    [Xq, Yq] = meshgrid(xUnique, yUnique);

    % Interpolate z values onto the structured grid
    Zq = griddata(x, y, z, Xq, Yq, 'cubic');  % smooth transitions

    % Plot heatmap using surf
    fig = figure;
    hSurf = surf(Xq, Yq, Zq, 'EdgeColor', 'none', 'FaceAlpha', 0.85); % slightly transparent
    view(2);  % top-down view
    colormap(parula);  % perceptually uniform colormap
    colorbar;
    axis tight;
    xlabel(xField, 'FontWeight','bold');
    ylabel(yField, 'FontWeight','bold');
    title(['Heatmap of ', zField], 'FontWeight','bold');

    % Overlay actual data points
    hold on;
    hScatter = scatter(x, y, 25, 'k', '+', 'LineWidth',0.5); 
    uistack(hScatter, 'top'); % ensure crosses are on top
    hold off;

    % Optional: add grid and adjust font
    set(gca, 'FontSize', 12, 'GridColor', [0.8 0.8 0.8], 'GridAlpha', 0.3);
    grid on;
end
