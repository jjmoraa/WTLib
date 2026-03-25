function [inputs]=jamieson(referenceCase,refmoment,wndspeed,A,n,p,hubRad,blades,inputs,parentFolder,airfoils)

if isa(inputs,'table')
    inputs=table2cell(inputs);
end

dummy=cell2mat(inputs);
refR = dummy(end,1)+hubRad;
refspan = dummy(:,1)+hubRad;
arefspan=refspan/refR;
ltsr = 9*arefspan;
a=A*(1-(arefspan).^n).^p;
a(1:2)=referenceCase.a(1:2);
for i=1:(height(inputs)-1) %If we get the xfoil working (length(blade.ispan)-1)
    amids(i)=(a(i)+a(i+1))/2;
    rmids(i)=(refspan(i)+refspan(i+1))/2;
    rsize(i)=refspan(i+1)-refspan(i);
end
annulusAreas=pi()*((rmids+rsize/2).^2-(rmids-rsize/2).^2);
oa=sum(amids.*annulusAreas)/(pi()*refR^2);%%check
R=((3*refmoment)/(4*1.225*(wndspeed^2)*pi()*oa*(1-oa)))^(1/3);
%ap=-1/2+1/2*sqrt(1+4*a.*(1-a)./ltsr);%%%%Lambda r^2!!!!
span=arefspan*R;
ap=-1/2+1/2*sqrt(1+4*a.*(1-a)./(ltsr.^2));
dummy(:,1)=arefspan*R-hubRad*(R/refR);
relwnd=atan((1-a)./((1-ap).*ltsr));
for j=1:length(dummy)
    airfoilno = dummy(j,7);
    % JJM: Open the text file for reading
    fid = fopen([parentFolder,'\Airfoils\',convertStringsToChars(airfoils{airfoilno,"name"}),'.dat'], 'r');
    for i=1:52
        fgetl(fid);
    end
    data = textscan(fid, '%f %f %f %f', 'HeaderLines', 2);
    fclose(fid); % Close the file
    table = array2table(cell2mat(data),'VariableNames',{'alpha rad','c_l','c_d','c_m'});
    if max(table{:,1})<180
        table{:,1}=table{:,1}*180/3.14;
    end
    table.("cd/cl")=table{:,3}./table{:,2};
    index=find(table{:,2}==max(table{:,2}),1,'last');
    clcd=table{index,5};
    while index>1 && clcd>table{index-1,5}
        index=index-1;
        clcd=table{index,5};
    end
    %index=initindex+1;
    
    aoa(j)=table{index,1};
    cl(j)=table{index,2};
    cd(j)=table{index,3};
    chord(j)=8*sin(relwnd(j))*a(j)*pi()*span(j)/(blades*cl(j)*ltsr(j)*(1+ap(j)));
end
twist=relwnd*180/pi()-aoa';
%dummy(3:end,5)=twist(3:end)';dummy(3:(end-1),6)=chord(3:(end-1))';
inputs = array2table(dummy,'VariableNames',{'span (r) [m]','not used1','not used2','not used3','twist','chord','airfoil no'});
