function addChanlocsLocations

%simply to add chanlocs X,Y,Z locations if not added. Meant for edf files
%where this information doesn't come in. Could also use this code to remove
%non-EEG channels, though easy to do in the GUI.

fullpathname=uipickfiles('type',{'*.set','.set file'},'prompt','Pick EEGLAB .set file','out','char');
[pathname,fname]=fileparts(fullpathname);

if isnumeric(fullpathname) || isempty(fullpathname) %if user presses cancel output is 0, done with no selection is {}
    return
else
    EEG = pop_loadset(fullpathname);
    [setfilepath setfilename]=fileparts(fullpathname);
end

if ~isempty(EEG.chanlocs(1).X)
    disp('Chanlocs location isn''t empty');
    return
end

LeadList={EEG.chanlocs.labels};%names of channels in a cell array, assume all are EEG
EEG.chanlocs=eegp_makechanlocs(char(LeadList));

pop_saveset(EEG,'filename',fname);
