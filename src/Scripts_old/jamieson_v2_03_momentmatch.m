function [inputs,a,ap,chord,twist,newhubRad]=...
    jamieson_v2_03_momentmatch...
    (referenceCase,refmoment,wndspeed,A,n,p,hubRad,blades,inputs,parentFolder,airfoils)

%if isa(inputs,'table')
%    inputs=table2cell(inputs);
%end

problemSize=length(referenceCase.blade.ispan);
refR = referenceCase.blade.span(end)+hubRad;
refspan = referenceCase.blade.ispan+hubRad;
frozenPoints=ceil((.30)*problemSize);
arefspan = refspan/refR;
ltsr = 9*arefspan;
rotspeed=ltsr(end).*wndspeed/refR;
a=A*(1-(arefspan).^n).^p;
a(1:frozenPoints)=referenceCase.a(1:frozenPoints)*(a(frozenPoints)/referenceCase.a(frozenPoints));
%im scaling the frozen point distribution to make sure they match
ap=-1/2+1/2*sqrt(1+4*a.*(1-a)./(ltsr.^2));
relwnd=atan((1-a)./((1-ap).*ltsr));
for i=1:(length(arefspan)-1)
    %If we get the xfoil working (length(blade.ispan)-1)
    amids(i)=(a(i)+a(i+1))/2;
    apmids(i)=(ap(i)+ap(i+1))/2;
    relwndmids(i)=(relwnd(i)+relwnd(i+1))/2;
    rmids(i)=(arefspan(i)+arefspan(i+1))/2;
    rsize(i)=arefspan(i+1)-arefspan(i);
end
cpmids=8*amids.*((1-amids).^2).*(rmids).*rsize;
Fmids=(2/pi)*acos(exp(-(2.5*(1-rmids))./(rmids.*sin(relwndmids))));
dT=Fmids.*1.225*(wndspeed^2)*4.*amids.*(1-amids)*pi.*rmids.*rsize;
%dQ=Fmids.*4.*apmids.*(1-amids).*1.225*wndspeed.*rotspeed*pi().*(rmids.^3).*rsize;
%totalpwr=sum(dpower(2:end));
thrust=sum(dT(2:end));


cntrThr=sum((dT.*rmids)/sum(dT));%center of thrust

oopmoment=cntrThr*thrust;

ocm=oopmoment/((1/2)*1.225*pi()*(1^3)*(wndspeed^2));


R=((refmoment)/(0.5*1.225*(wndspeed^2)*pi()*ocm))^(1/3);


newhubRad=hubRad*R/refR;
span=arefspan*R;

for j=1:length(arefspan)
    k=1;
        if span(j)==(R)
        airfoilno(j) = double(inputs{end,"airfoil no"});
        else
            while referenceCase.blade.ispan(j)>=referenceCase.blade.span(k)
                k=k+1;
                airfoilno(j) = double(inputs{k-1,"airfoil no"});
            end
        end
    % JJM: Open the text file for reading
    filename=sprintf('%s\\Airfoils\\IEA-15-240-RWT_AeroDyn15_Polar_%02d.dat', ...
                 parentFolder,airfoilno(j)-1);
    fid = fopen(filename, 'r');
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
chord(1:frozenPoints)=referenceCase.blade.ichord(1:frozenPoints)*(chord(frozenPoints)/referenceCase.blade.ichord(frozenPoints));
chord(chord < referenceCase.blade.ichord(end)) = referenceCase.blade.ichord(end);
twist=relwnd*180/pi()-aoa;
%twist(1:6)=repmat(twist(5),1,4);
twist(1:frozenPoints)=referenceCase.blade.idegreestwist(1:frozenPoints);
dummy=zeros(length(span),size(inputs,2));
dummy(:,1)=span-newhubRad;dummy(1,1)=0;
dummy(:,5)=twist;
dummy(:,6)=chord;
dummy(:,7)=airfoilno;

finaldummy(1,:)=dummy(1,:);
k=1;
i=2;
while dummy(i,7)==dummy(i-1,7)
    i=i+1;
end
    k=k+1;
    finaldummy(k,:)=dummy(i-1,:);

for j=(i-1):length(span)
    if dummy(j,7)~=dummy(j-1,7)
    k=k+1;
    finaldummy(k,:)=dummy(j,:);
    end
end

finaldummy=dummy;
inputs = array2table(finaldummy,'VariableNames',{'span (r) [m]','not used1','not used2','not used3','twist','chord','airfoil no','not used4','not used5','not used6'});

%[~, firstIdx] = unique(inputs.("airfoil no"), 'stable');

% Keep only the first occurrences
%inputs = inputs(firstIdx, :);

%%%%%%% THIS IS A TEMPORARY FIX (Actually maybe permanent, or someone
%%%%%%% else's problem :)

inputs(2, :) = [];  % Removes the second row