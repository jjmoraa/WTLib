function plotBladeParamHeatmap(Z, n_unique, p_unique, plotTitle)

    if nargin < 4
        plotTitle = 'Heatmap';
    end

    % Original grid
    [P,N] = meshgrid(p_unique, n_unique);

    % Remove NaN points
    valid = ~isnan(Z);

    p_valid = P(valid);
    n_valid = N(valid);
    z_valid = Z(valid);

    % Interpolant (no extrapolation)
    F = scatteredInterpolant(p_valid, n_valid, z_valid, 'natural', 'none');

    % Fine grid
    p_fine = linspace(min(p_unique), max(p_unique), 150);
    n_fine = linspace(min(n_unique), max(n_unique), 150);
    [P_fine,N_fine] = meshgrid(p_fine, n_fine);

    Z_fine = F(P_fine, N_fine);

    % Plot
    figure('Name', plotTitle)

    imagesc(n_fine, p_fine, Z_fine)
    set(gca,'YDir','normal')

    xlabel('p')
    ylabel('n')
    title(plotTitle)

    colormap(parula)
    colorbar
end