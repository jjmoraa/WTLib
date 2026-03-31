function table = polarRead(filename)

    % ---------- Read polar ----------
    fid = fopen(filename,'r');
    for i = 1:52
        fgetl(fid);
    end

    data = textscan(fid,'%f %f %f %f','HeaderLines',2);
    fclose(fid);

    table = array2table(cell2mat(data), ...
        'VariableNames',{'alpha','cl','cd','cm'});

    % ---- Make Cl/Cd and Cl/Cd^-1 ---
    table.cdcl = table.cd ./ table.cl;
    table.clcd = table.cl ./ table.cd;
end