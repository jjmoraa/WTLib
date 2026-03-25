function optimize_section(geometryVec, materialsVec, componentsVec)
    %% 1. Define number of variables
    nVars = length(componentsVec)-1;               % we are going to optimize the number of layers on each object
    x0 = ones(nVars,1);      % initial guess (column vector)

    %% 2. Bounds on each variable
    lb = zeros(nVars,1);     % lower bounds (example: 0 for all)
    ub = 5*ones(nVars,1);    % upper bounds (example: 5 for all)

    %% 3. Linear constraints (optional)
    A = []; b = [];
    Aeq = []; beq = [];

    %% 4. Nonlinear constraints (optional)
    nonlcon = @(x) myConstraints(x);

    %% 5. Call fmincon
    options = optimoptions('fmincon', ...
        'Display','iter', ...
        'Algorithm','sqp', ...
        'FiniteDifferenceType','central');

    [x_opt, fval] = fmincon(@(x) myBlackBox(x), x0, ...
                             A, b, Aeq, beq, lb, ub, nonlcon, options);

    %% 6. Display results
    disp('Optimal design variables:');
    disp(x_opt)
    disp('Objective value:');
    disp(fval)
end

%% ---- Black-box objective function ----
function y = myBlackBox(x)
    % x is a vector of any length
    % Example: sum of squares problem (minimum at [0,0,...])
    y = sum((x - 2).^2);
end

%% ---- Nonlinear constraint function ----
function [c, ceq] = myConstraints(x)
    % Example: inequality constraint
    % sum(x) <= 6  --> c = sum(x) - 6 <= 0
    c = sum(x) - 6;
    
    % No equality constraints in this example
    ceq = [];
end
