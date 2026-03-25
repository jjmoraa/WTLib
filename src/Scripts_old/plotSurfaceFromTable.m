function fig=plotSurfaceFromTable(dataTable, xField, yField, zField)
    % plotSurfaceFromTable - Plots a surface plot using x, y, and z from a table
    %
    % Inputs:
    %   dataTable - Table containing the data
    %   xField    - String with the name of the x column
    %   yField    - String with the name of the y column
    %   zField    - String with the name of the z column
    %
    % Example usage:
    %   plotSurfaceFromTable(myTable, 'x', 'y', 'z')

    % Extract x, y, and z data from the table
    x = dataTable.(xField);
    y = dataTable.(yField);
    z = dataTable.(zField);

    % Create a meshgrid from the unique x and y values
    [X, Y] = meshgrid(unique(x), unique(y));

    % Interpolate the z values to fit the grid
    Z = griddata(x, y, z, X, Y);

    % Plot the surface
    fig=figure;
    surf(X, Y, Z);

    % Label the axes and add a title
    xlabel(xField);
    ylabel(yField);
    zlabel(zField);
    title('Surface Plot of ',zField);
    
    % Optional: Add color shading for a better visual effect
    shading interp;
    colorbar;
end
