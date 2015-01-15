function removeData

%AMG 3/20/11 to remove a variable from a file for example to save space
[filename pathname]=uigetfile('*Coh.mat','Pick','Multiselect','on');

fieldName=input('Type field name to remove:','s');

for ii=1:length(filename)
    clear filea;
    filea=load(fullfile(pathname,filename{ii}));
    filea=rmfield(filea,fieldName);
    save(fullfile(pathname,filename{ii}),'-struct','*');
end