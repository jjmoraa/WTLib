function [fig, hImg, hScatter, hContour, C] = plotHeatmapFromTable(dataTable, xField, yField, zField)
    % Extract x, y, and z data from the table
    x = dataTable.(xField);
    y = dataTable.(yField);
    z = dataTable.(zField);

    % Create a fine grid for smooth interpolation
    xUnique = linspace(min(x), max(x), 200); % fine resolution
    yUnique = linspace(min(y), max(y), 200);
    [Xq, Yq] = meshgrid(xUnique, yUnique);

    % Interpolate z values onto the structured grid
    Zq = griddata(x, y, z, Xq, Yq, 'natural');  % smooth transitions

    % Replace zeros (or invalid points) with NaN
    Zq(Zq == 0) = NaN;

    %% plotting
    % --- Plot heatmap using imagesc (2D) ---
    fig = figure('Color','w', 'Name', ['Heatmap: ' zField], 'NumberTitle','off');
    
    % Map Zq to grid indices for imagesc and capture handle
    hImg = imagesc(xUnique, yUnique, Zq); 
    set(gca,'YDir','normal');  % correct y-axis direction
    
    % Make NaNs transparent
    set(hImg, 'AlphaData', ~isnan(Zq));  % 1 where data exists, 0 where NaN
    
    % Colormap and colorbar
    colormap(flipud(winter));
    cb = colorbar;   % your colorbar handle is preserved
    zField_ltx = strrep(zField, '_', '\_');
    cb.Label.String = ['$' zField_ltx '$'];
    cb.Label.Interpreter = 'latex';
    cb.FontSize = 11;
    
    % Set color limits
    clim([0 max(Zq(:))]);
    
    % Make NaNs transparent
    set(hImg, 'AlphaData', ~isnan(Zq));  % 1 where data exists, 0 where NaN
    
    axis tight; axis square;
    ax = gca;
    set(ax, 'FontName','Times','FontSize',12,'LineWidth',1,'Box','on', 'TickLabelInterpreter','latex');
    
    xField_ltx = strrep(xField,'\_','\\_'); 
    yField_ltx = strrep(yField,'\_','\\_'); 
    xlabel(['$' xField_ltx '$'], 'Interpreter','latex', 'FontSize',14);
    ylabel(['$' yField_ltx '$'], 'Interpreter','latex', 'FontSize',14);
    
    grid on; ax.GridColor=[0.7 0.7 0.7]; ax.GridAlpha=0.2;
    ax.MinorGridAlpha=0.1; ax.XMinorGrid='on'; ax.YMinorGrid='on';
    
    hold on;
    
    % Scatter points on top
    hScatter = scatter(x, y, 40, [0.4 0.4 0.4], 'o', 'LineWidth',0.8);
    
    % Suppose you want 2 decimals on labels
    numContours = 10;
    levels = round(linspace(0, max(Zq(:)), numContours), 2);  % round to 2 decimals
    
    [C,hContour] = contour(Xq, Yq, Zq, levels, 'k', 'LineWidth', 0.5);
    clabel(C, hContour, 'FontSize', 10, 'Color', 'k', 'Interpreter', 'latex');
    
    hold off;

    % --- Tight layout ---
    set(gca, 'LooseInset', max(get(gca,'TightInset'), 0.02));
    
    %% export out
    % Define the folder two levels up + "results"
    resultsFolder = fullfile('..','..','results/Figures_MDOPaper');
    
    % Make sure folder exists (optional)
    if ~exist(resultsFolder,'dir')
        mkdir(resultsFolder);
    end
    
    % Build the filename
    fileName = sprintf('Heatmap_%s.pdf', zField);  % no colons in filenames
    fullPath = fullfile(resultsFolder, fileName);
    
    % Export
    exportgraphics(fig, fullPath, 'ContentType','vector');
end
