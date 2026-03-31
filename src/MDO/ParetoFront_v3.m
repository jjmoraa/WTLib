function [fig,mod_mod_power_table, paretoX, paretoY, paretoIdx, globalIdx] = ParetoFront_v3(powertable, obj1, obj2, obj3)
% ParetoFront_v3(table, string, string)
% This will plot a heatmap overlay with a third parameter and mark zero-deflection points as X

%% --- Keep all points (do not filter) ---
mod_mod_power_table = powertable;

%% --- Extract variables ---
Y = mod_mod_power_table.(obj1);  % maximize
X = mod_mod_power_table.(obj2);  % minimize

if strcmp(obj3, 'n/p')
    c = mod_mod_power_table.('n') ./ mod_mod_power_table.('p');
else
    c = mod_mod_power_table.(obj3);
end

%% --- Identify zero points for obj3 (for coloring and plotting) ---
if strcmp(obj3, 'Deflection')
    zeroIdx = (c == 0);         % logical index of zeros
    regularIdx = ~zeroIdx;      % all other points
else
    zeroIdx = false(size(c));
    regularIdx = true(size(c));
end

% Prepare color values for scatter (NaN so zeros don't affect colormap)
c_for_color = c;
c_for_color(zeroIdx) = NaN;

%% --- Normalize objectives for scalarization ---
X_norm = (X - min(X)) / (max(X) - min(X));
Y_norm = (Y - min(Y)) / (max(Y) - min(Y));

%% --- Compute Pareto front via scalarization ---
weights = linspace(0, 1, 100);
paretoIdx = [];

for w = weights
    [~, bestIdx] = max(w * Y_norm - (1 - w) * X_norm);
    paretoIdx = unique([paretoIdx; bestIdx]);
end

%% --- Extract and sort Pareto front ---
paretoX = X(paretoIdx);
paretoY = Y(paretoIdx);

[paretoX, idx] = sort(paretoX);
paretoY = paretoY(idx);
sortedParetoIdx = paretoIdx(idx);

%% --- Map back to global indices ---
globalIdx = zeros(length(paretoIdx), 1);
for i = 1:length(paretoIdx)
    n_val = mod_mod_power_table.('n')(sortedParetoIdx(i));
    p_val = mod_mod_power_table.('p')(sortedParetoIdx(i));
    
    globalIdx(i) = find( ...
        abs(powertable.('n') - n_val) < 1e-3 & ...
        abs(powertable.('p') - p_val) < 1e-3, 1);
end

%% --- Figure setup ---
figName = ['Pareto: ' obj1 ' vs ' obj2 ' | colored by ' obj3];
fig = figure('Color','w','Name', figName,'NumberTitle','off');
colormap(flipud(winter));
hold on;

%% --- Plot regular points ---
hReg = scatter(X(regularIdx), Y(regularIdx), ...
    40, ...
    c_for_color(regularIdx), ...
    'filled', ...
    'MarkerFaceAlpha', 0.8, ...
    'MarkerEdgeColor', 'w', ...
    'LineWidth', 0.3);

%% --- Plot zero-deflection points as X ---
if any(zeroIdx)
    hZero = scatter(X(zeroIdx), Y(zeroIdx), ...
        70, ...
        'k', ...
        'x', ...
        'LineWidth', 1.5);
end

%% --- Pareto front ---
hParetoPts = scatter(paretoX, paretoY, 60, 'k', 'filled');
hParetoLine = plot(paretoX, paretoY, '-', 'Color', [0.85 0.1 0.1], 'LineWidth', 2);
uistack(hParetoPts, 'top');

%% --- Colorbar ---
cb = colorbar;
cb.FontSize = 11;
obj3_ltx = strrep(obj3, '_', '\_');
cb.Label.String = ['$' obj3_ltx '$'];
cb.Label.Interpreter = 'latex';
clim([min(c(regularIdx)) max(c(regularIdx))]);

%% --- Axes formatting ---
ax = gca;
set(ax, 'FontName', 'Times', 'FontSize', 12, 'LineWidth', 1, ...
    'Box', 'on', 'Layer', 'top', 'TickLabelInterpreter', 'latex');
xlabel(['$' strrep(obj2,'_','\_') '$'], 'Interpreter','latex','FontSize',14);
ylabel(['$' strrep(obj1,'_','\_') '$'], 'Interpreter','latex','FontSize',14);

%% --- Grid ---
grid on;
ax.GridColor = [0.7 0.7 0.7];
ax.GridAlpha = 0.2;
ax.MinorGridAlpha = 0.1;
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';

%% --- Legend ---
if any(zeroIdx)
    legend([hReg, hZero, hParetoLine], {'Converged Solutions','Zero Deflection','Pareto Front'}, ...
        'Location','best','Interpreter','latex');
else
    legend([hReg, hParetoLine], {'Converged Solutions','Pareto Front'}, ...
        'Location','best','Interpreter','latex');
end

hold off;
end