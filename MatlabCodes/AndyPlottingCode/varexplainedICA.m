function varexplainedICA

%calls eeglab's eeg_pvaf to run on a set of components from a .set file,
%give the variance explained by each one and the total.
%can easily modify it to run on many at once and save the results but for
%now just runs on one and spits resuls to command window.


[originalfilename, pathname1] = uigetfile('*.set', 'Select 1st EEG file (Cancel to stop)');
if originalfilename==0
    return
end

[prunedfilename, pathname2] = uigetfile('*.set', 'Select pruned EEG file (Cancel to not use)',pathname1);

EEG1 = pop_loadset('filename',originalfilename,'filepath',pathname1);

comp=input('paste in list of components in [ ] to calculate var explained or Return to skip: ');

if ~isempty(comp)
    fprintf('For %s:\n',originalfilename);
    pvaf=zeros(size(comp));
    for i=1:length(comp)
        pvaf(i)=eeg_pvaf(EEG1,[comp(i)],'plot','off');
        fprintf('Comp %.0f: %.2f%%\n',comp(i),pvaf(i));
    end
    totalVarExp=sum(pvaf);
    fprintf('Total var expl by comp removed=%.2f%%\n',totalVarExp);
end

if ~prunedfilename==0    
    EEG2 = pop_loadset('filename',prunedfilename,'filepath',pathname2);
    fprintf('\nFor %s vs %s:\n',originalfilename,prunedfilename);
    origVar=sum(var(EEG1.data(:,:),0,2)); %0 means default normalization and 2 means along columns
    prunedVar=sum(var(EEG2.data(:,:),0,2));
    percentVarRemaining=prunedVar/origVar;
    perVarExplained=1-percentVarRemaining;
    fprintf('Percent variance remaining in pruned dataset is: %.2f%%\n',percentVarRemaining*100);
    fprintf('Percent variance explained by ICA removed is: %.2f%%\n',perVarExplained*100);
end
