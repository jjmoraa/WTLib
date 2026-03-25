function generate_beamdyn_input(blade, mu_values, output_filename, dT)
% Generates a BeamDyn blade properties input file based on PreComp outputs
% Inputs:
% - precomp_data: A 2D array of dimensions (span_sections x 23), where each row
%   contains PreComp outputs for a blade section.
% - mu_values: A vector of 6 damping coefficients.
% - output_filename: Name of the output file to write the BeamDyn input.

precomp_data=blade.secprops.data;
% Validate inputs
if size(precomp_data, 2) ~= 23
    error('precomp_data must have 23 columns corresponding to PreComp outputs.');
end
if numel(mu_values) ~= 6
    error('mu_values must be a vector with 6 elements.');
end

spanwise_positions=precomp_data(:,1,:);
% calculate the matrices
stiffness_matrix=zeros(size(precomp_data,1),6,6);
mass_matrix=zeros(size(precomp_data,1),6,6);
for i=1:length(spanwise_positions)
    %stiffness matrix build
    stiffness_matrix(i,1,1)=precomp_data(i,5)*1*(10^0);%test dummy value
    stiffness_matrix(i,2,2)=precomp_data(i,5)*1*(10^0);%test dummy value
    stiffness_matrix(i,3,3)=precomp_data(i,7);%EA
    stiffness_matrix(i,4,4)=precomp_data(i,4);%EI_edge
    stiffness_matrix(i,5,5)=precomp_data(i,5);%EI_flap
    stiffness_matrix(i,6,6)=precomp_data(i,6);%GJ

    %mass matrix build
    %diagonal components
    mass_matrix(i,1,1)=precomp_data(i,18);%mass per unit span
    mass_matrix(i,2,2)=precomp_data(i,18);%mass per unit span
    mass_matrix(i,3,3)=precomp_data(i,18);%mass per unit span
    mass_matrix(i,4,4)=precomp_data(i,20);%edge inertia
    mass_matrix(i,5,5)=precomp_data(i,19);%flap inertia
    mass_matrix(i,6,6)=precomp_data(i,20)+precomp_data(i,19);%polar inertia (edge + flap)
    %non diagonal components
    %upper triag
    mass_matrix(i,4,3)=precomp_data(i,18)*precomp_data(i,23);%mass per unit span * y center of mass
    mass_matrix(i,5,3)=-precomp_data(i,18)*precomp_data(i,22);%mass per unit span * x center of mass
    mass_matrix(i,6,1)=-mass_matrix(i,4,3);%mass per unit span * y center of mass
    mass_matrix(i,6,2)=-mass_matrix(i,5,3);%mass per unit span * x center of mass
    mass_matrix(i,5,4)=0;%?? sectional cross product of inertia 
    %lower triag
    mass_matrix(i,3,4)=mass_matrix(i,4,3);%mass per unit span * y center of mass
    mass_matrix(i,3,5)=mass_matrix(i,5,3);%mass per unit span * x center of mass
    mass_matrix(i,1,6)=mass_matrix(i,6,1);%mass per unit span * y center of mass
    mass_matrix(i,2,6)=mass_matrix(i,6,2);%mass per unit span * x center of mass
    mass_matrix(i,4,5)=mass_matrix(i,5,4);%?? sectional cross product of inertia  
end

twist_root=precomp_data(1,3);
dcm=[cosd(twist_root) sind(twist_root) 0; -sind(twist_root) cosd(twist_root) 0; 0 0 1];%director cosine matrix
key_points=[precomp_data(:,14)';precomp_data(:,15)';(spanwise_positions')*blade.ispan(end);precomp_data(:,3)']';

center_points = (spanwise_positions(1:end-1) + spanwise_positions(2:end)) / 2;

    BeamDyn_blade_file(spanwise_positions,mass_matrix,stiffness_matrix, mu_values, output_filename)

    BeamDyn_primary_file(output_filename, length(spanwise_positions)-1, length(spanwise_positions), key_points, 5)

    BeamDyn_driver_file(dcm, center_points, dT, length(spanwise_positions)-1, output_filename)
end

function BeamDyn_driver_file(dcm, eta, dT, num_elements, output_filename)
% Generates a BeamDyn driver input file based on distributed point loads
% Inputs:
% - dT: A vector containing point loads distributed across elements.
% - num_elements: The number of elements (matching the length of dT).
% - output_filename: Name of the output file to write the driver input.

x_bar=0;
for i=1:length(dT)
    x_bar=x_bar+dT(i)*eta(i);
end

x_bar=x_bar/sum(dT);

% for i=1:length(dT)
%     if mean_thrust>dT(i)
%         position=i;
%     end
% end
% Validate inputs
if length(dT) ~= num_elements
    error('The length of dT must match the number of elements.');
end

% Open the file for writing
fid = fopen([output_filename,'_driver_file.inp'], 'w');
if fid == -1
    error('Could not open file for writing: %s', output_filename);
end

try
    % Write the header
    fprintf(fid, '------- BEAMDYN Driver with OpenFAST INPUT FILE --------------------------------\n');
    fprintf(fid, 'Static analysis of a twisted beam\n');
    fprintf(fid, '---------------------- SIMULATION CONTROL --------------------------------------\n');
    fprintf(fid, 'False         DynamicSolve  - Dynamic solve (false for static solve) (-)\n');
    fprintf(fid, '          0   t_initial     - Starting time of simulation (s) [used only when DynamicSolve=TRUE]\n');
    fprintf(fid, '         30   t_final       - Ending time of simulation   (s) [used only when DynamicSolve=TRUE]\n');
    fprintf(fid, '       0.01   dt            - Time increment size         (s) [used only when DynamicSolve=TRUE]\n');
    fprintf(fid, '---------------------- GRAVITY PARAMETER --------------------------------------\n');
    %fprintf(fid, '      9.806   Gx            - Component of gravity vector along X direction (m/s^2)\n');
    fprintf(fid, '          0   Gx            - Component of gravity vector along X direction (m/s^2)\n');
    fprintf(fid, '          0   Gy            - Component of gravity vector along Y direction (m/s^2)\n');
    fprintf(fid, '          0   Gz            - Component of gravity vector along Z direction (m/s^2)\n');
    fprintf(fid, '---------------------- FRAME PARAMETER --------------------------------------\n');
    fprintf(fid, '          0   GlbPos(1)     - Component of position vector of the reference blade frame along X direction (m)\n');
    fprintf(fid, '          0   GlbPos(2)     - Component of position vector of the reference blade frame along Y direction (m)\n');
    fprintf(fid, '          0   GlbPos(3)     - Component of position vector of the reference blade frame along Z direction (m)\n');
    fprintf(fid, '---The following 3 by 3 matrix is the direction cosine matirx ,GlbDCM(3,3), \n');
    fprintf(fid, '---relates global frame to the initial blade root frame \n');
    % fprintf(fid, '%12.7E  %12.7E  %12.7E\n',dcm(1,:));
    % fprintf(fid, '%12.7E  %12.7E  %12.7E\n',dcm(2,:));
    % fprintf(fid, '%12.7E  %12.7E  %12.7E\n',dcm(3,:));
    fprintf(fid, '%12.7E  %12.7E  %12.7E\n',[1 0 0]);
    fprintf(fid, '%12.7E  %12.7E  %12.7E\n',[0 1 0]);
    fprintf(fid, '%12.7E  %12.7E  %12.7E\n',[0 0 1]);
    fprintf(fid, 'T             GlbRotBladeT0 - Reference orientation for BeamDyn calculations is aligned with initial blade root?\n');
    fprintf(fid, '---------------------- ROOT VELOCITY PARAMETER ----------------------------------\n');
    fprintf(fid, '          0   RootVel(4)    - Component of angular velocity vector of the beam root about X axis (rad/s)\n');
    fprintf(fid, '          0   RootVel(5)    - Component of angular velocity vector of the beam root about Y axis (rad/s)\n');
    fprintf(fid, '          0   RootVel(6)    - Component of angular velocity vector of the beam root about Z axis (rad/s)\n');
    fprintf(fid, '---------------------- APPLIED FORCE ----------------------------------\n');
    fprintf(fid, '          0   DistrLoad(1)  - Component of distributed force vector along X direction (N/m)\n');
    fprintf(fid, '          0   DistrLoad(2)  - Component of distributed force vector along Y direction (N/m)\n');
    fprintf(fid, '          0   DistrLoad(3)  - Component of distributed force vector along Z direction (N/m)\n');
    fprintf(fid, '          0   DistrLoad(4)  - Component of distributed moment vector along X direction (N-m/m)\n');
    fprintf(fid, '          0   DistrLoad(5)  - Component of distributed moment vector along Y direction (N-m/m)\n');
    fprintf(fid, '          0   DistrLoad(6)  - Component of distributed moment vector along Z direction (N-m/m)\n');
    fprintf(fid, '          0   TipLoad(1)    - Component of concentrated force vector at blade tip along X direction (N)\n');
    fprintf(fid, '          0   TipLoad(2)    - Component of concentrated force vector at blade tip along Y direction (N)\n');
    fprintf(fid, '          0   TipLoad(3)    - Component of concentrated force vector at blade tip along Z direction (N)\n');
    fprintf(fid, '          0   TipLoad(4)    - Component of concentrated moment vector at blade tip along X direction (N-m)\n');
    fprintf(fid, '          0   TipLoad(5)    - Component of concentrated moment vector at blade tip along Y direction (N-m)\n');
    fprintf(fid, '          0   TipLoad(6)    - Component of concentrated moment vector at blade tip along Z direction (N-m)\n');
    fprintf(fid, '          %d   NumPointLoads - Number of point loads along blade\n', 1);
    fprintf(fid, 'Non-dim blade-span eta   Fx          Fy            Fz           Mx           My           Mz\n');
    fprintf(fid, '(-)                      (N)         (N)           (N)          (N-m)        (N-m)        (N-m)\n');
    
    % Write point loads
    %eta = linspace(0, 1, num_elements); % Normalized span locations
    % for i = 1:num_elements
    %     fprintf(fid, '%12.6E %12.6E 0.000000E+00 0.000000E+00 0.000000E+00 0.000000E+00 0.000000E+00\n', ...
    %         eta(i), dT(i));
    % end

    %For now we will just do concentrated load in load center
    fprintf(fid, '%12.6E %12.6E 0.000000E+00 0.000000E+00 0.000000E+00 0.000000E+00 0.000000E+00\n', ...
             x_bar, sum(dT));

    % Primary input file reference
    fprintf(fid, '---------------------- PRIMARY INPUT FILE --------------------------------------\n');
    fprintf(fid, '"%s_primary_file.inp"           InputFile - Name of the primary BeamDyn input file\n', output_filename);
    fprintf(fid, '----- Output Settings -------------------------------------------------------------------\n');
    fprintf(fid, '          1   WrVTK         - VTK visualization data output: (switch) {0=none; 1=init; 2=animation}\n');
    fprintf(fid, '         15   VTK_fps       - Frame rate for VTK output (frames per second) {will use closest integer multiple of DT} [used only if WrVTK=2]\n');

catch ME
    fclose(fid);
    rethrow(ME);
end

% Close the file
fclose(fid);
end


function BeamDyn_primary_file(output_filename, member_total, kp_total, key_points, order_elem)
% Generates a BeamDyn primary input file for OpenFAST.
% Inputs:
% - output_filename: Name of the output file to write the BeamDyn primary input.
% - member_total: Total number of members (usually 1 for a single blade).
% - kp_total: Total number of key points defining the geometry.
% - key_points: A matrix of key point coordinates and twist [x, y, z, twist] (kp_total x 4).
% - order_elem: Interpolation order for mesh generation (integer, typically 5 or 7).
% - blade_props_file: File name of the beam properties input file (string).

blade_props_file=[output_filename,'_blade_props_file.inp'];
% Validate inputs
if size(key_points, 2) ~= 4
    error('key_points must have 4 columns [x, y, z, twist].');
end
if size(key_points, 1) ~= kp_total
    error('key_points must have kp_total rows.');
end

% Open the file for writing
fid = fopen([output_filename,'_primary_file.inp'], 'w');
if fid == -1
    error('Could not open file for writing: %s', output_filename);
end

try
    % Write the header
    fprintf(fid, '--------- BEAMDYN with OpenFAST INPUT FILE -------------------------------------------\n');
    fprintf(fid, 'Isotropic beam\n');
    fprintf(fid, '---------------------- SIMULATION CONTROL --------------------------------------\n');
    fprintf(fid, 'True          Echo             - Echo input data to "<RootName>.ech"? (flag)\n');
    fprintf(fid, 'False         QuasiStaticInit  - Use quasi-static pre-conditioning with centripetal accelerations in initialization? (flag) [dynamic solve only]\n');
    fprintf(fid, '          0   rhoinf           - Numerical damping parameter for generalized-alpha integrator\n');
    fprintf(fid, '          2   quadrature       - Quadrature method: 1=Gaussian; 2=Trapezoidal (switch)\n');
    fprintf(fid, '          1   refine           - Refinement factor for trapezoidal quadrature (-) [DEFAULT = 1; used only when quadrature=2]\n');
    fprintf(fid, '"DEFAULT"     n_fact           - Factorization frequency for the Jacobian in N-R iteration(-) [DEFAULT = 5]\n');
    fprintf(fid, '0.002     DTBeam           - Time step size (s)\n');
    fprintf(fid, '"DEFAULT"     load_retries     - Number of factored load retries before quitting the simulation [DEFAULT = 20]\n');
    fprintf(fid, '1000          NRMax            - Max number of iterations in Newton-Raphson algorithm (-) [DEFAULT = 10]\n');
    fprintf(fid, '"DEFAULT"     stop_tol         - Tolerance for stopping criterion (-) [DEFAULT = 1E-5]\n');
    fprintf(fid, '"DEFAULT"     tngt_stf_fd      - Use finite differenced tangent stiffness matrix? (flag)\n');
    fprintf(fid, '"DEFAULT"     tngt_stf_comp    - Compare analytical finite differenced tangent stiffness matrix? (flag)\n');
    fprintf(fid, '"DEFAULT"     tngt_stf_pert    - Perturbation size for finite differencing (-) [DEFAULT = 1E-6]\n');
    fprintf(fid, '"DEFAULT"     tngt_stf_difftol - Maximum allowable relative difference between analytical and fd tangent stiffness (-); [DEFAULT = 0.1]\n');
    fprintf(fid, 'True          RotStates        - Orient states in the rotating frame during linearization? (flag) [used only when linearizing] \n');
    
    % Write geometry parameters
    fprintf(fid, '---------------------- GEOMETRY PARAMETER --------------------------------------\n');
    fprintf(fid, '          %d   member_total    - Total number of members (-)\n', 1);
    fprintf(fid, '          %d   kp_total        - Total number of key points (-) [must be at least 3]\n', kp_total);
    fprintf(fid,'       %d        %d                 - Member number; Number of key points in this member\n', 1,kp_total);
    fprintf(fid, '   kp_xr         kp_yr         kp_zr        initial_twist\n');
    fprintf(fid, '   (m)            (m)          (m)            (deg)\n');
        % Write key point coordinates and twists
    for i = 1:kp_total
        %fprintf(fid, '%12.6E  %12.6E  %12.6E  %12.6E\n', key_points(i, :));
        fprintf(fid, '%12.6E  %12.6E  %12.6E  %12.6E\n', 0, 0, key_points(i, 3), key_points(i, 4));
    end
    
    % Write mesh parameters
    fprintf(fid, '---------------------- MESH PARAMETER ------------------------------------------\n');
    fprintf(fid, '          %d   order_elem     - Order of interpolation (basis) function (-)\n', order_elem);
    
    % Write material parameters
    fprintf(fid, '---------------------- MATERIAL PARAMETER --------------------------------------\n');
    fprintf(fid, '"%s"    BldFile - Name of file containing properties for blade (quoted string)\n', blade_props_file);
    
    % Write pitch actuator parameters
    fprintf(fid, '---------------------- PITCH ACTUATOR PARAMETERS -------------------------------\n');
    fprintf(fid, 'False         UsePitchAct - Whether a pitch actuator should be used (flag)\n');
    fprintf(fid, '          0   PitchJ      - Pitch actuator inertia (kg-m^2) [used only when UsePitchAct is true]\n');
    fprintf(fid, '          0   PitchK      - Pitch actuator stiffness (kg-m^2/s^2) [used only when UsePitchAct is true]\n');
    fprintf(fid, '          0   PitchC      - Pitch actuator damping (kg-m^2/s) [used only when UsePitchAct is true]\n');
    
    % Write outputs
    fprintf(fid, '---------------------- OUTPUTS -------------------------------------------------\n');
    fprintf(fid, 'True          SumPrint       - Print summary data to "<RootName>.sum" (flag)\n');
    fprintf(fid, '"ES16.8E2"    OutFmt          - Format used for text tabular output, excluding the time channel.\n');
    %fprintf(fid, '%d            NNodeOuts      - Number of nodes to output to file [0 - 9] (-)\n',kp_total);
    fprintf(fid, '%d            NNodeOuts      - Number of nodes to output to file [0 - 9] (-)\n',0);
    %for i = 1:kp_total
    % for i = 1:9
    %     %i=ceil(j*kp_total/9);
    %     %fprintf(fid, '%12.6E  %12.6E  %12.6E  %12.6E\n', key_points(i, :));
    %     fprintf(fid, '%d ',i);
    %     if mod(i, 10) == 1
    %         fprintf(fid, '\n');
    %     end
    % end
    fprintf(fid, '          OutNd          - Nodes whose values will be output  (-)\n');
    fprintf(fid, '          OutList        - The next line(s) contains a list of output parameters. See OutListParameters.xlsx for a listing of available output channels, (-)\n');
    % for i = 1:8
    %     %i=ceil(j*kp_total/9);
    %     fprintf(fid, '"N%dTDxr, N%dTDyr, N%dTDzr, N%dRDxr, N%dRDyr, N%dRDzr"\n', i, i, i, i, i, i);
    % end
    % fprintf(fid, '"TipTDxr, TipTDyr, TipTDzr, TipRDxr, TipRDyr, TipRDzr"  \n');
    fprintf(fid, 'END of OutList section (the word "END" must appear in the first 3 columns of the last OutList line)\n');
    fprintf(fid, '---------------------- NODE OUTPUTS --------------------------------------------\n');
    fprintf(fid, '50   BldNd_BlOutNd   - Blade nodes on each blade (currently unused)\n');
    fprintf(fid, 'OutList     - The next line(s) contains a list of output parameters.  See OutListParameters.xlsx, BeamDyn_Nodes tab for a listing of available output channels, (-)\n');
    fprintf(fid, '"FxL"       - Sectional force resultants at each node expressed in l    l: a floating coordinate system local to the deflected beam    (N)\n');
    fprintf(fid, '"FyL"       - Sectional force resultants at each node expressed in l    l: a floating coordinate system local to the deflected beam    (N)\n');
    fprintf(fid, '"FzL"       - Sectional force resultants at each node expressed in l    l: a floating coordinate system local to the deflected beam    (N)\n');
    fprintf(fid, '"MxL"       - Sectional moment resultants at each node expressed in l    l: a floating coordinate system local to the deflected beam    (N-m)\n');
    fprintf(fid, '"MyL"       - Sectional moment resultants at each node expressed in l    l: a floating coordinate system local to the deflected beam    (N-m)\n');
    fprintf(fid, '"MzL"       - Sectional moment resultants at each node expressed in l    l: a floating coordinate system local to the deflected beam    (N-m)\n');
    fprintf(fid, '"Fxr"       - Sectional force resultants at each node expressed in r    r: a floating reference coordinate system fixed to the root of the moving beam; when coupled to FAST for blades, this is equivalent to the IEC blade (b) coordinate system    (N)\n');
    fprintf(fid, '"Fyr"       - Sectional force resultants at each node expressed in r    r: a floating reference coordinate system fixed to the root of the moving beam; when coupled to FAST for blades, this is equivalent to the IEC blade (b) coordinate system    (N)\n');
    fprintf(fid, '"Fzr"       - Sectional force resultants at each node expressed in r    r: a floating reference coordinate system fixed to the root of the moving beam; when coupled to FAST for blades, this is equivalent to the IEC blade (b) coordinate system    (N)\n');
    fprintf(fid, '"Mxr"       - Sectional moment resultants at each node expressed in r    r: a floating reference coordinate system fixed to the root of the moving beam; when coupled to FAST for blades, this is equivalent to the IEC blade (b) coordinate system    (N-m)\n');
    fprintf(fid, '"Myr"       - Sectional moment resultants at each node expressed in r    r: a floating reference coordinate system fixed to the root of the moving beam; when coupled to FAST for blades, this is equivalent to the IEC blade (b) coordinate system    (N-m)\n');
    fprintf(fid, '"Mzr"       - Sectional moment resultants at each node expressed in r    r: a floating reference coordinate system fixed to the root of the moving beam; when coupled to FAST for blades, this is equivalent to the IEC blade (b) coordinate system    (N-m)\n');
    fprintf(fid, '"TDxr"      - Sectional translational deflection (relative to the undeflected position) at each node expressed in r    r: a floating reference coordinate system fixed to the root of the moving beam; when coupled to FAST for blades, this is equivalent to the IEC blade (b) coordinate system    (m)\n');
    fprintf(fid, '"TDyr"      - Sectional translational deflection (relative to the undeflected position) at each node expressed in r    r: a floating reference coordinate system fixed to the root of the moving beam; when coupled to FAST for blades, this is equivalent to the IEC blade (b) coordinate system    (m)\n');
    fprintf(fid, '"TDzr"      - Sectional translational deflection (relative to the undeflected position) at each node expressed in r    r: a floating reference coordinate system fixed to the root of the moving beam; when coupled to FAST for blades, this is equivalent to the IEC blade (b) coordinate system    (m)\n');
    fprintf(fid, '"RDxr"      - Sectional angular/rotational deflection Wiener-Milenkovic parameter (relative to the undeflected orientation) at each node expressed in r    r: a floating reference coordinate system fixed to the root of the moving beam; when coupled to FAST for blades, this is equivalent to the IEC blade (b) coordinate system    (-)\n');
    fprintf(fid, '"RDyr"      - Sectional angular/rotational deflection Wiener-Milenkovic parameter (relative to the undeflected orientation) at each node expressed in r    r: a floating reference coordinate system fixed to the root of the moving beam; when coupled to FAST for blades, this is equivalent to the IEC blade (b) coordinate system    (-)\n');
    fprintf(fid, '"RDzr"      - Sectional angular/rotational deflection Wiener-Milenkovic parameter (relative to the undeflected orientation) at each node expressed in r    r: a floating reference coordinate system fixed to the root of the moving beam; when coupled to FAST for blades, this is equivalent to the IEC blade (b) coordinate system    (-)\n');
    fprintf(fid, 'END of input file (the word "END" must appear in the first 3 columns of this last OutList line)\n');
    fprintf(fid, '---------------------------------------------------------------------------------------\n');
catch ME
    fclose(fid);
    rethrow(ME);
end

% Close the file
fclose(fid);
end

function BeamDyn_blade_file(spanwise_positions,mass_matrix,stiffness_matrix, mu_values, output_filename)
% Open the file for writing
fid = fopen([output_filename,'_blade_props_file.inp'], 'w');
if fid == -1
    error('Could not open file for writing: %s', output_filename);
end

try
    % Header
    fprintf(fid, '------- BEAMDYN V1.00.* INDIVIDUAL BLADE INPUT FILE --------------------------\n');
    fprintf(fid, 'Generated from MATLAB script\n');
    fprintf(fid, '---------------------- BLADE PARAMETERS --------------------------------------\n');
    fprintf(fid, '%d   station_total    - Number of blade input stations (-)\n', length(spanwise_positions));
    fprintf(fid, '1   damp_flag        - Damping flag: 0: no damping; 1: damped\n');

    % Damping coefficients
    fprintf(fid, '---------------------- DAMPING COEFFICIENT------------------------------------\n');
    fprintf(fid, '   mu1        mu2        mu3        mu4        mu5        mu6\n');
    fprintf(fid, '   (-)        (-)        (-)        (-)        (-)        (-)\n');
    fprintf(fid, '%12.6E %12.6E %12.6E %12.6E %12.6E %12.6E\n', mu_values);

    % Distributed properties
    fprintf(fid, '---------------------- DISTRIBUTED PROPERTIES---------------------------------\n');
    for i = 1:length(spanwise_positions)
        span = spanwise_positions(i); % Spanwise position

        % Write span position
        fprintf(fid, '%12.6E\n', span);

        % Write stiffness matrix
        for row = 1:6
            fprintf(fid, '%12.6E %12.6E %12.6E %12.6E %12.6E %12.6E\n', stiffness_matrix(i, row, :));
        end

        fprintf(fid,' \n');

        % Write mass matrix
        for row = 1:6
            fprintf(fid, '%12.6E %12.6E %12.6E %12.6E %12.6E %12.6E\n', mass_matrix(i, row, :));
        end
        fprintf(fid,' \n');
    end

catch ME
    fclose(fid);
    rethrow(ME);
end

% Close the file
fclose(fid);
end
