%%
clear data;
clear dataname;
clear i;
data{1}=zeros(size(jlswim.Snippet_1.Data.modData{1}));
data=repmat(data,1,24);
for i=1:24
dataname=sprintf('jlswim.Snippet_%.0f.Data.modData{1}',i);
data{i}=eval(dataname)';
end
eegData=cell2mat(data);
%then in EEGLAB you load the data and tell it the sampling rate and how
%many per cut

%%
% 
% %to load channel locations
% chanlocs=struct('labels',jlswim.Snippet_1.Data.sensor.labels);
% pop_chanedit(chanlocs);
%%then go to edit channel locations and click read locations

%then run ICA, look at the components, export and plot 2:end, 2:end in
%matlab and plot the power spectra. Probably the ones that go up are
%artifact and an try to remove. 

%Then in EEG lab do file export. Better to click transpose if want to
%replace in crx file. Also uncheck export channel labeles. Not sure about
%time values. Then do load into matlab and save (or end in .mat?). Also
%figure out how to use multitaper PS in eeglab since their power spectra
%routine doesn't work.