function [inputs,a,ap]=jamieson_v2_00(referenceCase,refmoment,wndspeed,A,n,p,hubRad,blades,inputs,parentFolder,airfoils)

%if isa(inputs,'table')
%    inputs=table2cell(inputs);
%end

refR = referenceCase.blade.span(end)+hubRad;
refspan = referenceCase.blade.ispan+hubRad;
arefspan = refspan/refR;
ltsr = 9*arefspan;
a=A*(1-(arefspan).^n).^p;
a(1:6)=referenceCase.a(1:6);
for i=1:(length(arefspan)-1)
    %If we get the xfoil working (length(blade.ispan)-1)
    amids(i)=(a(i)+a(i+1))/2;
    rmids(i)=(arefspan(i)+arefspan(i+1))/2;
    rsize(i)=arefspan(i+1)-arefspan(i);
end
cp=8*amids.*((1-amids).^2).*(rmids).*rsize;
ct=8*amids.*(1-amids).*(rmids).*rsize;
cm=8*amids.*(1-amids).*(rmids.^2).*rsize;
ocp=sum(cp);
oct=sum(ct);
ocm=sum(cm);
%annulusAreas=pi()*((rmids+rsize/2).^2-(rmids-rsize/2).^2);
%oa=sum(amids.*annulusAreas)/(pi()*refR^2);%%check
R=((refmoment)/(0.5*1.225*(wndspeed^2)*pi()*ocm))^(1/3);
%ap=-1/2+1/2*sqrt(1+4*a.*(1-a)./ltsr);%%%%Lambda r^2!!!!
span=arefspan*R;
ap=-1/2+1/2*sqrt(1+4*a.*(1-a)./(ltsr.^2));
%dummy(:,1)=arefspan*R-hubRad*(R/refR);
relwnd=atan((1-a)./((1-ap).*ltsr));

for j=1:length(arefspan)
    k=1;
        if span(j)==R
        airfoilno(j) = double(inputs{end,"airfoil no"});
        else
            while referenceCase.blade.ispan(j)>=referenceCase.blade.span(k)
                k=k+1;
                airfoilno(j) = double(inputs{k-1,"airfoil no"});
            end
        end
    % JJM: Open the text file for reading
    fid = fopen([parentFolder,'\Airfoils\',convertStringsToChars(airfoils{airfoilno(j),"name"}),'.dat'], 'r');
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
chord(1:6)=referenceCase.blade.ichord(1:6);
chord(end)=referenceCase.blade.ichord(end);
twist=relwnd*180/pi()-aoa;
%twist(1:6)=repmat(twist(5),1,4);
twist(1:6)=referenceCase.blade.idegreestwist(1:6);
dummy=zeros(length(span),size(inputs,2));
dummy(:,1)=span-hubRad;
dummy(:,5)=twist;
dummy(:,6)=chord;
dummy(:,7)=airfoilno;
%dummy(3:end,5)=twist(3:end)';dummy(3:(end-1),6)=chord(3:(end-1))';
inputs = array2table(dummy,'VariableNames',{'span (r) [m]','not used1','not used2','not used3','twist','chord','airfoil no'});
