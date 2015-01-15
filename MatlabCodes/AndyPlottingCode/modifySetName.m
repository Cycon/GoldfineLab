function modifySetName

%created 12/1 to easily modify setnames of EEGLAB .set files without having
%to use EEGLAB to open them.

setfilenames=uipickfiles('type',{'*.set','.set file'},'prompt','Pick .set file');

for j=1:length(setfilenames)
    EEG=pop_loadset('filename',setfilenames{j});
    fprintf('Setname is %s\n',EEG.setname);
    ns=input('New setname: ','s');
    EEG=pop_editset(EEG,'setname',ns);
    EEG=pop_saveset(EEG,'filename',setfilenames{j},'savemode','onefile');
end