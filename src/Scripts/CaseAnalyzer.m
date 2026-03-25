%single case analysis
function Mass = CaseAnalyzer(Cases,powertable,globalidx,refCase,n)%n is the step for the plots
%get number of cases
size=length(Cases);
% Chord and Twist Plot
figure()

% Line styles and colors
lineWidth = 2;
fontSize = 14;
cmap = parula(size);  % Generate a colormap with 'numColors' colors
%% Chord plot
figure()
for i=1:n:size
    plot(Cases(i).blade.ispan, Cases(i).blade.ichord, 'LineWidth', lineWidth, 'Color', cmap(i, :), 'DisplayName', sprintf('Case Chord %d n=%4.2f p=%4.2f n/p %4.2f', i, ...
        powertable(globalidx(i),:).('n'),powertable(globalidx(i),:).('p'), powertable(globalidx(i),:).('n')/powertable(globalidx(i),:).('p')))
    hold on
end
plot(refCase.blade.ispan, refCase.blade.ichord, '--', 'LineWidth', lineWidth, 'Color', 'k', 'DisplayName', 'Reference Chord')
xlabel('Spanwise Position (m)', 'FontSize', fontSize)
ylabel('Chord Length (m)', 'FontSize', fontSize)
title('Blade Chord Distribution', 'FontSize', fontSize + 2, 'FontWeight', 'bold')
legend('Location', 'best', 'FontSize', fontSize - 2)
grid on
set(gca, 'FontSize', fontSize)
hold off

% Twist plot
figure()
for i=1:n:size
    plot(Cases(i).blade.ispan, Cases(i).blade.idegreestwist, 'LineWidth', lineWidth, 'Color', cmap(i, :), 'DisplayName', sprintf('Case Twist %d', i))
    hold on
end
plot(refCase.blade.ispan, refCase.blade.idegreestwist, '--', 'LineWidth', lineWidth, 'Color', 'k', 'DisplayName', 'Reference Twist')
xlabel('Spanwise Position (m)', 'FontSize', fontSize)
ylabel('Twist Angle (deg)', 'FontSize', fontSize)
title('Blade Twist Distribution', 'FontSize', fontSize + 2, 'FontWeight', 'bold')
legend('Location', 'best', 'FontSize', fontSize - 2)
grid on
set(gca, 'FontSize', fontSize)
hold off
%get mass of the blade

for i=1:size
    dMass(i,:)=Cases(i).blade.secprops.data(:,18)*(Cases(i).blade.ispan(2)-Cases(i).blade.ispan(1));
    Mass(i)=sum(dMass(i,:));
end

