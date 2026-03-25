%Variable saving script

function CaseName =...
    variable_saving_v2(a_in,n_in,p_in,a,ap,amids,apmids,ocp,oct,ocm,cpmids,ctmids,...
    cmmids,dT,dQ,totalpwr,refmoment,mass,blade,rmids,hubRad,D,R,F,L,Ks,folder,objectName)

    CaseName.a=a;
    CaseName.ap=ap;
    CaseName.amids=amids;
    CaseName.apmids=apmids;
    CaseName.ocp=ocp;
    CaseName.oct=oct;
    CaseName.ocm=ocm;
    CaseName.cpmids=cpmids;
    CaseName.ctmids=ctmids;
    CaseName.cmmids=cmmids;
    CaseName.dT=dT;
    CaseName.dQ=dQ;
    CaseName.totalpwr=totalpwr;
    CaseName.blade=blade;
    CaseName.rmids=rmids;
    CaseName.hubRad=hubRad;
    CaseName.D=D;
    CaseName.R=R;
    CaseName.F=F;
    CaseName.L=L;
    CaseName.Ks=Ks;
    CaseName.mass=mass;
    CaseName.moment=refmoment;

    printStructFieldsToFile(referenceCase, objectName, folder)

end

function printStructFieldsToFile(object, objectName, folder)
    % Automatically name the file based on the objectName
    fileName = strcat(objectName, '_structureFields.txt');
    filePath = fullfile(folder, fileName);
    
    % Open the text file for writing
    fid = fopen(filePath, 'w');
    
    % Check if file was successfully opened
    if fid == -1
        error('Failed to open file for writing.');
    end
    
    % Get the field names of the structure
    fieldNames = fieldnames(object);
    
    % Loop over each field and write the field name and its value to the file
    for i = 1:length(fieldNames)
        fieldName = fieldNames{i};
        fieldValue = object.(fieldName);
        
        % Write the field name to the file
        fprintf(fid, '%s: ', fieldName);
        
        % Write the value depending on its type
        if isnumeric(fieldValue)
            fprintf(fid, '%s\n', mat2str(fieldValue));
        elseif ischar(fieldValue)
            fprintf(fid, '%s\n', fieldValue);
        else
            fprintf(fid, '%s\n', 'Unsupported data type');
        end
    end
    
    % Close the file after writing
    fclose(fid);
    
    % Inform the user that the file has been saved
    fprintf('File saved to: %s\n', filePath);
end