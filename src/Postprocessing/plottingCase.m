%plotting scripts

function plottingCase(referenceCase,parentFolder,mode,caseName)
%reference case plots
    blade=referenceCase.blade;
    hubRad=referenceCase.hubRad;
    rmids=referenceCase.rmids;
    figure('Name', 'PreComp Analysis Results');
    data = [blade.secprops.data]; % Concatenate results to form 'data'
    for i = 2:size(data, 2)
        subplot(5, 5, i);
        plot(data(:, 1), data(:, i), 'b-o');
        xlabel(strrep(blade.secprops.labels{1}, '_', '\_'));
        ylabel(strrep(blade.secprops.labels{i}, '_', '\_'));
    end

    fig=figure('Name', 'BEM Parameters');
    plot(blade.ispan+hubRad,referenceCase.a,blade.ispan+hubRad,referenceCase.ap,'LineWidth',5)
    xlabel('Span [m]')
    ylabel('[-]')
    legend('a','ap','Location','Southwest')
    fontsize(gcf,scale=1.2)
    saveas(fig,[parentFolder,'/Results/',mode,'/',caseName,'BEM Parameters.jpg'])    
   
    fig=figure('Name', 'AD Calculations');
    plot(rmids,referenceCase.cpmids,rmids,referenceCase.ctmids,rmids,referenceCase.cmmids,'LineWidth',5)
    xlabel('Span [m]')
    ylabel('[-]')
    legend('cp','ct','cm','Location','Southwest')
    saveas(fig,[parentFolder,'/Results/',mode,'/',caseName,'AD Calculations.jpg'])

    fig=figure('Name', 'Summary of performance calculations');
    plot(rmids,referenceCase.dT,rmids,referenceCase.dQ,'LineWidth',5)
    xlabel('Span [m]')
    ylabel('Force [N], Torque [Nm]')
    legend('dT','dQ','Location','Southwest')
    saveas(fig,[parentFolder,'/Results/',mode,'/',caseName,'Summary of performance calculations.jpg'])

    fig=figure('Name', 'Deflection');
    plot(blade.ispan,referenceCase.D(1,:),'LineWidth',5)
    xlabel('Span [m]')
    ylabel('Deflection [m]')
    saveas(fig,[parentFolder,'/Results/',mode,'/',caseName,'Deflection.jpg'])
    legend('dT','dQ','Location','Southwest')
end
