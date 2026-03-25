%Fit function for jamiesons fit

function [fitcurve, gof]=jamiesonsFitv2(refBlade,rootPct)
% Define the custom fit function
    rootPoints=length(refBlade.ispan)*rootPct;
    tipPoints=length(refBlade.ispan)*(.7);
    fitfun = fittype(@(a,n,p,x) a.*((1 - x.^n).^(p)), 'independent', 'x', 'coefficients', {'a', 'n', 'p'});
    % Prepare x and y data separately
    x = (refBlade.ispan(rootPoints:tipPoints) + refBlade.hubRad)/(refBlade.ispan(end)+refBlade.hubRad);  % Independent variable (span + hub radius)
    y = refBlade.operating_point.a(rootPoints:tipPoints);  % Dependent variable (a)
    
    % Perform the fit
    [fitcurve, gof] = fit(x(:), y(:), fitfun, 'StartPoint', [mode(y), 10, 0.5]);
    
    % Output the sum of squared errors (SSE)
    fprintf('x01: sse=%.3f\n', gof.sse);
end

