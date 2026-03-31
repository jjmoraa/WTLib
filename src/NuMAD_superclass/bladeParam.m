classdef bladeParam < BladeDefmodv2

    properties
        varName
        geometryVec
        materialsVec
        componentsVec
        dataFolder
        resultsFolder
        hubRad
        Blades
        TSR
        deflection
        rated_windspeed
        operating_point
        Cost
        Constraints
        mass
    end
    
    methods
        function obj = bladeParam(geometryVec, materialsVec, componentsVec,...
                hubRad, Blades, TSR, rated_windspeed, dataFolder, resultsFolder, airfoils, numel)
            
            % --- Parent constructor FIRST ---
            obj@BladeDefmodv2();

            % --- Add paths once ---
            persistent pathsAdded
            if isempty(pathsAdded)
                addNumadPaths();
                pathsAdded = true;
            end
            
            obj.dataFolder = dataFolder;
            obj.resultsFolder = resultsFolder;
            obj.geometryVec = geometryVec;
            obj.materialsVec = materialsVec;
            obj.componentsVec = componentsVec;
            obj.hubRad = hubRad;
            obj.Blades = Blades;
            obj.TSR = TSR;
            obj.rated_windspeed = rated_windspeed;
            
            % --- Build blade using your function ---
            blade = buildBladeFromParsed...
                (geometryVec, materialsVec, componentsVec,...
                dataFolder, airfoils, numel);

            % --- Copy blade data into this object ---
            obj = obj.copyFromBlade(blade);
        end
        
        function obj = copyFromBlade(obj,blade)

            % Example — depends on NuMAD structure
            props = properties(blade);

            for k = 1:numel(props)
                try
                    obj.(props{k}) = blade.(props{k});
                catch
                    % ignore properties that don't exist
                end
            end

        end
        
        function result = runBEMPoint(obj, wndspeed)
            nSec = length(obj.ispan);
        
            % Preallocate
            chordVector = zeros(nSec,1);twistVector = zeros(nSec,1);
            span = zeros(nSec,1);       aind = zeros(nSec,1);
            apind = zeros(nSec,1);      aoas = zeros(nSec,1);
            Fs = zeros(nSec,1);         cls = zeros(nSec,1);
            cds = zeros(nSec,1);        cpvector = zeros(nSec,1);
            ctvector = zeros(nSec,1);   cmvector = zeros(nSec,1);
            relwnds = zeros(nSec,1);    ltsrvect = zeros(nSec,1);
            
            R = obj.ispan(end)+obj.hubRad;
            for j = 1:nSec
                r     = obj.ispan(j);
                twist = obj.idegreestwist(j) * pi/180;
                chord = obj.ichord(j);
        
                % ---------- Airfoil lookup ----------
                spanStations = obj.geometryVec.span;
                afIDs        = obj.geometryVec.afID;
                
                if r >= spanStations(end)
                    airfoilno = afIDs(end);
                else
                    k = find(r < spanStations, 1, 'first');
                    airfoilno = afIDs(k-1);
                end
        
                % ---------- Read polar ----------
                polarFile = fullfile(obj.dataFolder,'Airfoils', ...
                    sprintf('IEA-15-240-RWT_AeroDyn15_Polar_%02d.dat',airfoilno-1));
        
                table1 = obj.readPolarFile(polarFile); table1.Properties.VariableNames{'alpha_rad'} = 'alpha rad';
                % ---------- BEM ----------
                [a,ap,cp,ct,cm,F,cl,cd,relWind,aoa,r,R,ltsr] = ...
                    bem_solver_v3_01(obj.Blades,obj.TSR,chord,r+obj.hubRad,R,obj.hubRad,twist,table1);
        
                % ---------- Store ----------
                chordVector(j) = chord; twistVector(j) = twist;
                span(j) = r;            aind(j) = a;
                apind(j) = ap;          aoas(j) = aoa;
                Fs(j) = F;              cls(j) = cl;
                cds(j) = cd;            cpvector(j) = cp;
                ctvector(j) = ct;       cmvector(j) = cm;
                relwnds(j) = relWind;   ltsrvect(j) = ltsr;
        
            end
        
            % ---------- AD Performance ----------
            % variables it prints
            % [amids,apmids,cpmids,ctmids,cmmids,ocp,oct,...
            % ocm,dT,dQ,totalpwr,oopmoment,rsize,rmids]
            [~,~,~,~,~,ocp,oct,ocm,dT,dQ,totalpwr,moment,rsize,rmids] = ...
                AD_performance(chordVector,relwnds,aind,apind,aoas,Fs,cls,cds,...
                               cpvector,wndspeed,ltsrvect,R,span);
        
            % ---------- Output struct ----------
            result.power   = totalpwr;
            result.dT      = dT;
            result.dQ      = dQ;
            result.moment  = moment;
            result.rsize   = rsize;
            result.rmids   = rmids;
            result.span    = span;
            result.a       = aind;
            result.apind   = apind;
            result.aoas    = aoas;
            result.relwnds = relwnds;
            result.ocp     = ocp;
            result.oct     = oct;
            result.ocm     = ocm;
        end
        
        function getMass(obj)
            obj.mass = sum((obj.ispan(2)-obj.ispan(1))*obj.secprops.data(:,18));
        end
        function operating_point = operatingPoint(obj)            
            
            result = runBEMPoint(obj, obj.rated_windspeed);
            [status, cmdout, beamDynOutput] = beamDynAnalysis(obj, result.dT);
            
            % Extract tip deflections
                xDeflection = beamDynOutput(:, ...
                    startsWith(beamDynOutput.Properties.VariableNames, 'N') & ...
                    endsWith(beamDynOutput.Properties.VariableNames, '_TDxr'));
                
                yDeflection = beamDynOutput(:, ...
                    startsWith(beamDynOutput.Properties.VariableNames, 'N') & ...
                    endsWith(beamDynOutput.Properties.VariableNames, '_TDyr'));
                
                D(1,:) = table2array(xDeflection(end,:));
                D(2,:) = table2array(yDeflection(end,:));
            result.deflection = D;
            obj.operating_point = result;
        end

        function table1 = readPolarFile(obj,polarFile)

        fid = fopen(polarFile, 'r');

        % Skip header
        for i = 1:52
            fgetl(fid);
        end

        data = textscan(fid, '%f %f %f %f', 'HeaderLines', 2);
        fclose(fid);

        table1 = array2table( ...
            cell2mat(data), ...
            'VariableNames', {'alpha_rad','c_l','c_d','c_m'} );

        % Convert degrees → radians if needed
        if max(table1.alpha_rad) > pi
            table1.alpha_rad = table1.alpha_rad * pi/180;
        end

    end

        function showName(obj)
            obj.varName = inputname(1);  % gets the name of the first input
            fprintf('The variable name is: %s\n', obj.varName);
        end

        function [status, cmdout, beamDynOutput] = beamDynAnalysis(obj, dT, mu_values)
            %BEAMDYNANALYSIS Generate BeamDyn input and run simulation
            %   Inputs:
            %       dT        - distributed loads along the blade
            %       mu_values - optional, distributed mass values (default: 0.1*ones(1,6))
            %
            %   Outputs:
            %       status - BeamDyn exit code
            %       cmdout - captured command output

            % --- Add BeamDyn path ---
            beamDynPath = addBeamDynPath();
        
            % --- Set default mu_values if not provided ---
            if nargin < 3 || isempty(mu_values)
                mu_values = 0.001 * ones(1,6);
            end
        
            output_filename = obj.varName;  % default to object's name
            % --- Extract folder and base name ---
            [outputDir, baseName, ext] = fileparts(output_filename);
            if isempty(outputDir)
                outputDir = obj.resultsFolder;   % default to current folder
            end
            output_filename = fullfile(outputDir, baseName);  % ensure no extension added
        
            % --- Generate input file ---
            generate_beamdyn_input(obj, mu_values, output_filename, dT);
        
            % --- Run BeamDyn simulation ---
            [status, cmdout] = run_beamdyn(beamDynPath, baseName, outputDir);

            % --- Check for convergence ---
            if contains(cmdout, 'BD_Static:Solution does not converge')
                disp('BeamDyn static solution failed to converge.');
                D = [];  % optionally return empty if failed
            else
                % Read BeamDyn output
                beamDynOutput = read_BeamDyn_out(fullfile(outputDir, baseName));                              
            end
        end
        
        function analyze(obj)
            runAnalysis(obj);
            obj.Cost = obj.computeCost();
        end
        
        function cost = computeCost(obj)
            cost = obj.mass * 10;
        end
        
    end
end