%Fit function for jamiesons fit

function [fitcurve, gof]=jamiesonsFit(referenceCase,rootPct)
% Define the custom fit function
    rootPoints=length(referenceCase.blade.ispan)*rootPct;
    tipPoints=length(referenceCase.blade.ispan)*.70;
    fitfun = fittype(@(a,n,p,x) a.*((1 - x.^n).^(p)), 'independent', 'x', 'coefficients', {'a', 'n', 'p'});
    % Prepare x and y data separately
    x = (referenceCase.blade.ispan(rootPoints:tipPoints) + referenceCase.hubRad)/(referenceCase.blade.ispan(end)+referenceCase.hubRad);  % Independent variable (span + hub radius)
    y = referenceCase.a(rootPoints:tipPoints);  % Dependent variable (a)
    
    % Perform the fit
    [fitcurve, gof] = fit(x(:), y(:), fitfun, 'StartPoint', [mode(y), 10, 0.5]);
    
    % Output the sum of squared errors (SSE)
    fprintf('x01: sse=%.3f\n', gof.sse);
end

