%%
%once you bring

a=1;
for i=1:length(eventStruct.Children)
if ~isempty(eventStruct.Children(i).Children)
    if isfield(eventStruct.Children(i).Children,'Children') &&...
            length(eventStruct.Children(i).Children)>1 &&...
            isfield(eventStruct.Children(i).Children(10),'Children')
desc{a}=eventStruct.Children(i).Children(10).Children.Data;
a=a+1;
    end
end
end