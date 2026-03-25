% Simple optimization problem: minimize a quadratic function

% Objective function: f(x) = x1^2 + x2^2
objectiveFunction = @(x) x(1)^2 + x(2)^2;

% Nonlinear constraint: x1^2 + x2^2 <= 1 (this is a circle constraint)
constraintFunction = @(x) deal([], x(1)^2 + x(2)^2 - 1);  % Nonlinear inequality

% Initial guess
x0 = [0.5, 0.5];  % Starting point

% Set optimization options
options = optimoptions('fmincon', ...
    'Display', 'iter', ...             % Display iteration info
    'TolFun', 1e-6, ...                % Function tolerance
    'TolX', 1e-6, ...                  % Step size tolerance
    'MaxIterations', 100, ...          % Maximum number of iterations
    'MaxFunctionEvaluations', 1000);   % Maximum function evaluations

% Define bounds for the variables (e.g., -2 <= x1, x2 <= 2)
lb = [-2, -2];  % Lower bounds
ub = [2, 2];    % Upper bounds

% Call fmincon
[x_opt, f_val, exitflag, output] = fmincon(objectiveFunction, x0, [], [], [], [], lb, ub, constraintFunction, options);

% Display the results
disp('Final optimized values:');
fprintf('x1: %f\n', x_opt(1));
fprintf('x2: %f\n', x_opt(2));
fprintf('Final Objective Value: %f\n', f_val);
disp(output);