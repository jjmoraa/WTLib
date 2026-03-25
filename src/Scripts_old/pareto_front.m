%% Postprocessing script

%plot pareto front  
% figure()
% scatter(powertable.('cpR^2')',powertable.('tip_dfl')')

% Load or create a table (example)
% myTable = table([1; 2; 3; 4; 5], [10; 8; 6; 5; 4], [2; 3; 5; 7; 10], ...
%     'VariableNames', {'ID', 'Objective1', 'Objective2'});

% Extract relevant columns

mod_mod_power_table = powertable(powertable.('tip deflection') > .90, :);

obj1 = mod_mod_power_table.('cpR^2');  % First objective
obj2 = mod_mod_power_table.('tip deflection');  % Second objective

%pareto
[membership, member_value]=find_pareto_frontier([obj2,obj1]);

figure()
scatter(obj2,obj1);
hold on;
scatter(member_value(:,1),member_value(:,2),'r');
legend({'Data','Pareto Frontier'})


function [membership, member_value]=find_pareto_frontier(input)
out=[];
data=unique(input,'rows');
for i = 1:size(data,1)
    
    c_data = repmat(data(i,:),size(data,1),1);
    t_data = data;
    t_data(i,:) = Inf(1,size(data,2));
    smaller_idx = c_data>=t_data;
    
    idx=sum(smaller_idx,2)==size(data,2);
    if ~nnz(idx)
        out(end+1,:)=data(i,:);
    end
end
membership = ismember(input,out,'rows');
member_value = out;
end