function [Z, n_unique, p_unique] = buildBladeParamGrid(grid_points, blades, fieldName)
%BUILDMOMENTGRID Convert blade results into (n,p) grid matrix
%
% Inputs
%   grid_points : [N x 2] matrix → [n p]
%   blades      : cell array of blade objects
%   fieldName   : string specifying quantity:
%                 'deflection'  → tip deflection
%                 'power'       → power
%
% Outputs
%   Z           : matrix of requested quantity on (n,p) grid
%   n_unique    : unique n values (rows)
%   p_unique    : unique p values (cols)

    n_vals = grid_points(:,1);
    p_vals = grid_points(:,2);

    n_unique = unique(n_vals);
    p_unique = unique(p_vals);

    Z = nan(length(n_unique), length(p_unique));

    for idx = 1:length(grid_points)

        n = grid_points(idx,1);
        p = grid_points(idx,2);

        i = find(n_unique == n);
        j = find(p_unique == p);

        blade = blades{idx};
        
        if isempty(blade)
            continue
        end
        switch lower(fieldName)

            case 'deflection'
                value = blade.operating_point.deflection(1,end);

            case 'power'
                value = blade.operating_point.power;

            otherwise
                error('Unknown fieldName: %s', fieldName)

        end

        Z(i,j) = value;
    end
end