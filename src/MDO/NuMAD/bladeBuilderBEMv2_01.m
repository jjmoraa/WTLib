%Blade Builder
function [blade]=bladeBuilderBEMv2_01(inputs,parentFolder,airfoils,filename,numel)

MPa_to_Pa = 1e6;
%Prepare data for numad model
ChordOffset=zeros(1,height(inputs));
blade=BladeDefmodv2();
blade.span=table2array(inputs(:,1));
blade.degreestwist=table2array(inputs(:,5));%*180/pi
blade.chord=table2array(inputs(:,6));
blade.chordoffset=ChordOffset;
blade.sweep        = zeros(size(blade.span));
blade.prebend      = zeros(size(blade.span));
blade.percentthick = 100*ones(size(blade.span));
blade.aerocenter=[ones(1,2),repmat(0.275,1,height(inputs)-2)];

prop = {'degreestwist','chord','percentthick','chordoffset','aerocenter'};

k=1;
afspan(k)=table2array(inputs(1,1));
affile=[parentFolder,'\Airfoils\',convertStringsToChars(airfoils{k,"name"}),'.txt'];
%here is the method
blade.addStation(affile,afspan(k));
for j=2:height(inputs)
    %if table2array(inputs(j-1,7))==table2array(inputs(j,7))
    %else
        k=k+1;
        afspan(k)=table2array(inputs(j,1));
        affile=[parentFolder,'\Airfoils\',convertStringsToChars(airfoils{k,"name"}),'.txt'];
        blade.addStation(affile,afspan(k));
        %blade.percentthick(j)=100*max(blade.stations(j).airfoil.coordinates(:,2));
    %end
end

for j=1:height(inputs)
    blade.percentthick(j)=2*100*max(blade.stations(table2array(inputs(j,7))).airfoil.coordinates(:,2));
end
    
%Interpolation module
for k=1:length(prop)
        % For each of the input properties, interpolate where ever values
        % are missing.
        ind = isnan(blade.(prop{k}));
        if any(ind)
            if ~isequal(prop{k},'percentthick')
            blade.(prop{k})(ind) = interp1(blade.span(~ind),...
                                            blade.(prop{k})(~ind),...
                                            blade.span( ind),...
                                            'pchip');
            else
                % jcb: note that blade.chord must be interpolated before
                % blade.percentthick
                absthick = blade.percentthick .* blade.chord / 100;
                iabsthick = interp1(blade.span(~ind),...
                                    absthick(~ind),...
                                    blade.span( ind),...
                                    'pchip');
                blade.percentthick(ind) = iabsthick ./ blade.chord(ind) * 100;
            end
            % The next two lines report when a property has been
            % interpolated.
%             rowstr = sprintf('%d,',find(ind==1));
%             fprintf('Interpolating "%s" on rows [%s]\n',props{k},rowstr(1:end-1))
        end
end

afdb = [blade.stations.airfoil];
    afdb.resample(175,'cosine');
    blade.ispan      = (0:(1/numel):1)*table2array(inputs(end,1));%jjm: specify for some desired output interval
    %blade.ispan      = num(xls.geom.datarow1:end, xls.geom.ispan);
    lastrow = find(isfinite(blade.ispan)==1,1,'last');
    blade.ispan = blade.ispan(1:lastrow);

% Read the Components tab of the xls file
    xls.cmpt.paramcol  = 3;
    xls.cmpt.paramrow1 = 2;
    xls.cmpt.datarow1 = 7;
    xls.cmpt.group    = 1;   
    xls.cmpt.name     = 2;
    xls.cmpt.matid    = 3;
    xls.cmpt.angle    = 4;
    xls.cmpt.hpext    = 5;
    xls.cmpt.lpext    = 6;
    xls.cmpt.cpspan   = 7;
    xls.cmpt.cpnlay   = 8;
    xls.cmpt.imethod  = 9;
    [num, txt, raw] = xlsread(filename,'Components');
    blade.sparcapwidth  = num(xls.cmpt.paramrow1 + 0,xls.cmpt.paramcol);
    blade.leband        = num(xls.cmpt.paramrow1 + 1,xls.cmpt.paramcol);
    blade.teband        = num(xls.cmpt.paramrow1 + 2,xls.cmpt.paramcol);
    % ble: <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    blade.sparcapoffset = num(xls.cmpt.paramrow1 + 3,xls.cmpt.paramcol);
    if isnan(blade.sparcapoffset), blade.sparcapoffset = 0; end
    % ble: >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    N = size(num,1) - xls.cmpt.datarow1;
    for k=0:N
        comp.group        =             num(xls.cmpt.datarow1+k,xls.cmpt.group);
        comp.name         =             txt{xls.cmpt.datarow1+k,xls.cmpt.name};
        comp.materialid   =             num(xls.cmpt.datarow1+k,xls.cmpt.matid);
        comp.fabricangle  = readnumlist(raw{xls.cmpt.datarow1+k,xls.cmpt.angle});
        comp.hpextents    = readstrlist(txt{xls.cmpt.datarow1+k,xls.cmpt.hpext});
        comp.lpextents    = readstrlist(txt{xls.cmpt.datarow1+k,xls.cmpt.lpext});
        comp.cp           = readnumlist(raw{xls.cmpt.datarow1+k,xls.cmpt.cpspan});
        comp.cp(:,2)      = readnumlist(raw{xls.cmpt.datarow1+k,xls.cmpt.cpnlay});
        comp.imethod      =             txt{xls.cmpt.datarow1+k,xls.cmpt.imethod};
        if ~any(length(comp.hpextents) == [0,1,2])
            error('xlsBlade: component #%d, length of hpextents must be 0, 1, or 2',k+1)
        end
        if ~any(length(comp.lpextents) == [0,1,2])
            error('xlsBlade: component #%d, length of lpextents must be 0, 1, or 2',k+1)
        end
        %Here is the method
        blade.addComponent(comp);
    end

    % Read the Materials tab of the xls file
    xls.mtrl.datarow1   = 4;
    xls.mtrl.id         = 1;
    xls.mtrl.name       = 2;
    xls.mtrl.type       = 3;
    xls.mtrl.thickness  = 4;
    xls.mtrl.ex         = 5;
    xls.mtrl.ey         = 6;
    xls.mtrl.ez         = 7;    
    xls.mtrl.gxy        = 8;    
    xls.mtrl.gyz        = 9;    
    xls.mtrl.gxz        = 10;    
    xls.mtrl.prxy       = 11;    
    xls.mtrl.pryz       = 12;    
    xls.mtrl.prxz       = 13;
    xls.mtrl.density    = 14;
    xls.mtrl.drydensity = 15; 
    xls.mtrl.uts        = 16;
    xls.mtrl.ucs        = 17;
    xls.mtrl.reference  = 18;
    [num,txt] = xlsread(filename,'Materials');
    N = size(num,1) - xls.mtrl.datarow1;
    for k=0:N
        mat.name           =           txt{xls.mtrl.datarow1+k,xls.mtrl.name};
        mat.type           =           txt{xls.mtrl.datarow1+k,xls.mtrl.type};
        mat.layerthickness =           num(xls.mtrl.datarow1+k,xls.mtrl.thickness);
        mat.ex             = MPa_to_Pa*num(xls.mtrl.datarow1+k,xls.mtrl.ex);
        mat.prxy           =           num(xls.mtrl.datarow1+k,xls.mtrl.prxy);
        mat.density        =           num(xls.mtrl.datarow1+k,xls.mtrl.density);
        mat.drydensity     =           num(xls.mtrl.datarow1+k,xls.mtrl.drydensity);
        mat.uts            = MPa_to_Pa*num(xls.mtrl.datarow1+k,xls.mtrl.uts);
        mat.ucs            = MPa_to_Pa*num(xls.mtrl.datarow1+k,xls.mtrl.ucs);
        mat.reference      =           txt{xls.mtrl.datarow1+k,xls.mtrl.reference};
        
        if isequal(mat.type,'orthotropic')
        mat.ey             = MPa_to_Pa*num(xls.mtrl.datarow1+k,xls.mtrl.ey);
        mat.ez             = MPa_to_Pa*num(xls.mtrl.datarow1+k,xls.mtrl.ez);
        mat.gxy            = MPa_to_Pa*num(xls.mtrl.datarow1+k,xls.mtrl.gxy);
        mat.gyz            = MPa_to_Pa*num(xls.mtrl.datarow1+k,xls.mtrl.gyz);
        mat.gxz            = MPa_to_Pa*num(xls.mtrl.datarow1+k,xls.mtrl.gxz);
        mat.pryz           =           num(xls.mtrl.datarow1+k,xls.mtrl.pryz);
        mat.prxz           =           num(xls.mtrl.datarow1+k,xls.mtrl.prxz);

        else
        mat.ey   = [];
        mat.ez   = [];
        mat.gxy  = [];
        mat.gyz  = [];
        mat.gxz  = [];
        mat.pryz = [];
        mat.prxz = [];
        end
        
        if isempty(mat.ez),   mat.ez   = mat.ey; end
        if isempty(mat.gyz),  mat.gyz  = mat.gxy; end
        if isempty(mat.gxz),  mat.gxz  = mat.gyz; end
        if isempty(mat.pryz), mat.pryz = mat.prxy; end
        if isempty(mat.prxz), mat.prxz = mat.prxy; end
        %Here is the method
        blade.addMaterial(mat);
    end

end

function strout = strreps(strin,oldsubstrcell,newsubstrcell)
    assert(numel(oldsubstrcell)==numel(newsubstrcell),...
        'Lengths of substring cell arrays must be equal.');
    strout = strin;
    for k=1:numel(oldsubstrcell)
        strout = strrep(strout,oldsubstrcell{k},newsubstrcell{k});
    end
end

function numv = readnumlist(str)
    % read a list of numeric values
    if isnumeric(str)
        numv = str;
        return;
    end
    str = strreps(str,{'[',']',','},{'','',' '});
    numv = cell2mat(textscan(str,'%f'));
end

function strv = readstrlist(str)
    % read a list of string values
    str = strreps(str,{'[',']',','},{'','',' '});
    if isempty(str)
        str = ' ';
    end
    strvcell = textscan(str,'%s');
    strv = transpose(strvcell{1});
end
