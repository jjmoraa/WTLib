%Variable saving script

function referenceCase =...
    variable_saving(a_in,n_in,p_in,a,ap,amids,apmids,ocp,oct,ocm,cpmids,ctmids,...
    cmmids,dT,dQ,totalpwr,refmoment,mass,blade,rmids,hubRad,D,R,F,L,Ks,COE,AEP,folder,objectName)

    referenceCase(a_in,n_in,p_in).a=a;
    referenceCase(a_in,n_in,p_in).ap=ap;
    referenceCase(a_in,n_in,p_in).amids=amids;
    referenceCase(a_in,n_in,p_in).apmids=apmids;
    referenceCase(a_in,n_in,p_in).ocp=ocp;
    referenceCase(a_in,n_in,p_in).oct=oct;
    referenceCase(a_in,n_in,p_in).ocm=ocm;
    referenceCase(a_in,n_in,p_in).cpmids=cpmids;
    referenceCase(a_in,n_in,p_in).ctmids=ctmids;
    referenceCase(a_in,n_in,p_in).cmmids=cmmids;
    referenceCase(a_in,n_in,p_in).dT=dT;
    referenceCase(a_in,n_in,p_in).dQ=dQ;
    referenceCase(a_in,n_in,p_in).totalpwr=totalpwr;
    referenceCase(a_in,n_in,p_in).blade=blade;
    referenceCase(a_in,n_in,p_in).rmids=rmids;
    referenceCase(a_in,n_in,p_in).hubRad=hubRad;
    referenceCase(a_in,n_in,p_in).D=D;
    referenceCase(a_in,n_in,p_in).R=R;
    referenceCase(a_in,n_in,p_in).F=F;
    referenceCase(a_in,n_in,p_in).L=L;
    referenceCase(a_in,n_in,p_in).Ks=Ks;
    referenceCase(a_in,n_in,p_in).mass=mass;
    referenceCase(a_in,n_in,p_in).moment=refmoment;
    referenceCase(a_in,n_in,p_in).COE=COE;
    referenceCase(a_in,n_in,p_in).AEP=AEP;

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