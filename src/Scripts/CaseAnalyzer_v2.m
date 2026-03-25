%single case analysis
function Mass = CaseAnalyzer_v2(Cases,refCase)%n is the step for the plots
%get number of cases
size=length(Cases);
% Chord and Twist Plot
figure()
% F_mid = conv(F, [0.5 0.5], 'valid')


% Line styles and colors
lineWidth = 2;
fontSize = 14;
cmap = parula(size);  % Generate a colormap with 'numColors' colors
%% Chord plot
figure()
for i=1:size
    chord=smoothdata(Cases(i).blade.ichord, 'movmean', 3);%(Cases(i).blade.ichord(1:end-1) + Cases(i).blade.ichord(2:end)) / 2;
    span=(Cases(i).blade.ispan);%(Cases(i).blade.ispan(1:end-1) + Cases(i).blade.ispan(2:end)) / 2;
    plot(span, chord,...
        'LineWidth', lineWidth, 'Color', cmap(i, :), 'DisplayName', sprintf('Case Chord %d n=%4.2f p=%4.2f', i, ...
        Cases(i).n,Cases(i).p))
    % plot(Cases(i).blade.ispan, Cases(i).blade.ichord, 'LineWidth', lineWidth, 'Color', cmap(i, :), 'DisplayName', sprintf('Case Chord %d n=%4.2f p=%4.2f n/p %4.2f', i, ...
    %     Cases(i).n,Cases(i).p, Cases(i).n/Cases(i).p))
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
for i=1:size
    twist=smoothdata(Cases(i).blade.idegreestwist,'movmean', 3);%(Cases(i).blade.idegreestwist(1:end-1) + Cases(i).blade.idegreestwist(2:end)) / 2;
    span=(Cases(i).blade.ispan);%(Cases(i).blade.ispan(1:end-1) + Cases(i).blade.ispan(2:end)) / 2;
    % plot(Cases(i).blade.ispan, Cases(i).blade.idegreestwist, 'LineWidth', lineWidth, 'Color', cmap(i, :), 'DisplayName', sprintf('Case Twist %d', i))
    plot(span, twist, ...
        'LineWidth', lineWidth, 'Color', cmap(i, :), 'DisplayName', sprintf('Case Twist %d', i))
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

