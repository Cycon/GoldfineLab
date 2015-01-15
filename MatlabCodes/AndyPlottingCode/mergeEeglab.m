function mergeEeglab

%simple function to call pop_mergeset on two datasets to combine them.
%Final name is up to user but setname comes from original files
%
%5/28/12 AMG

%%
paths=uipickfiles('type',{'*.set','.set'},'prompt','Pick files to merge, order matters');

outname=input('Name of output .set file: ','s');

for a=1:length(paths)
    eeg(a)=pop_loadset(paths{a});
end

%%
EEGOUT=pop_mergeset(eeg,[1:length(eeg)]);
EEGOUT.setname=eeg(1).setname;%so that starts off correctly and not with a _
for b=2:length(paths)
     EEGOUT.setname=[EEGOUT.setname '_' eeg(b).setname];
end
EEGOUT=pop_saveset(EEGOUT,'filename',outname,'savemode','onefile');    %save as a .set file for analysis
