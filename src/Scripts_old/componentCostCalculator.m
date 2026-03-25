%Cost calculator

function component_cost=componentCostCalculator(component,material_table)

component_cost=0;%this is in $
layers=size(component,1);
for i=1:layers
    layer_material=cell2mat(component(i,2));
    layer_weight=cell2mat(component(i,10))/1000;
    cost_per_weight=table2array(material_table(layer_material,3));
    cost_per_layer=layer_weight*cost_per_weight;
    component_cost=component_cost+cost_per_layer;
end



