function bladeComparison(blades, labels)
%% bladeComparison
% Compare multiple blades (cell array of blade objects)

nBlades = numel(blades);

% --- Auto-generate labels from blade.varName ---
if nargin < 2 || isempty(labels)
    labels = cell(1, nBlades);
    for i = 1:nBlades
        if isfield(blades{i}, 'varName') || isprop(blades{i}, 'varName')
            labels{i} = blades{i}.varName;
        else
            labels{i} = sprintf('Blade %d', i);
        end
    end
end

% --- colormap ---
cmap = flipud(winter(nBlades));

% --- figure ---
fig = figure('Name','Blade Comparison','NumberTitle','off');
tlo = tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

%% -------------------- Axial Induction --------------------
ax1 = nexttile;
hold(ax1,'on')

for i = 1:nBlades
    b = blades{i};
    plot(ax1, b.ispan, b.operating_point.a, ...
        'Color', cmap(i,:), 'LineWidth', 1.8);
end

ylabel(ax1,'Axial Induction','Interpreter','latex','FontSize',12)
legend(ax1, labels, 'Interpreter','none','Location','best')
grid(ax1,'on')
ax1.GridColor=[0.7 0.7 0.7]; ax1.GridAlpha=0.2;

%% -------------------- Chord --------------------
ax2 = nexttile;
hold(ax2,'on')

for i = 1:nBlades
    b = blades{i};
    plot(ax2, b.ispan, b.ichord, ...
        'Color', cmap(i,:), 'LineWidth', 1.8);
end

ylabel(ax2,'Chord','Interpreter','latex','FontSize',12)
legend(ax2, labels, 'Interpreter','none','Location','best')
grid(ax2,'on')
ax2.GridColor=[0.7 0.7 0.7]; ax2.GridAlpha=0.2;

%% -------------------- Twist --------------------
ax3 = nexttile;
hold(ax3,'on')

for i = 1:nBlades
    b = blades{i};
    plot(ax3, b.ispan, b.idegreestwist, ...
        'Color', cmap(i,:), 'LineWidth', 1.8);
end

ylabel(ax3,'Twist [deg]','Interpreter','latex','FontSize',12)
legend(ax3, labels, 'Interpreter','none','Location','best')
grid(ax3,'on')
ax3.GridColor=[0.7 0.7 0.7]; ax3.GridAlpha=0.2;

%% -------------------- Deflection --------------------
ax4 = nexttile;
hold(ax4,'on')

for i = 1:nBlades
    b = blades{i};
    plot(ax4, b.ispan, b.operating_point.deflection(1,:), ...
        'Color', cmap(i,:), 'LineWidth', 1.8);
end

xlabel(ax4,'$\mathrm{Spanwise\ Position}$','Interpreter','latex','FontSize',12)
ylabel(ax4,'Deflection','Interpreter','latex','FontSize',12)
legend(ax4, labels, 'Interpreter','none','Location','best')

grid(ax4,'on')
ax4.GridColor=[0.7 0.7 0.7]; ax4.GridAlpha=0.2;

end