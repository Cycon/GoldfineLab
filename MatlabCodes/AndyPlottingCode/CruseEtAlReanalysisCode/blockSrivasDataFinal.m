function blockSrivasDataFinal

%to create new .set files from the .set data from Cruse et al. for their
%final Lancet dataset where blocks are denoted by EEG.event.bnum and no way to know which
%trials from original dataset were removed. %3/25/12 added catch in case a
%specific block type doesn't exist

setFiles=uipickfiles('type',{'*.set','.set file(s)'},'prompt','pick .set file(s)');

for sf=1:length(setFiles)
    [~,setname]=fileparts(setFiles{sf});
    EEG=pop_loadset(setFiles{sf});
    numBlocks=max([EEG.event.bnum]);
    type={'RIGHTHAND' 'TOES'};
    %make new .set file for each event type
        for b=1:2 %for each event type
            for n=1:numBlocks
                if max([EEG.event.bnum]==n & strcmpi({EEG.event.type},type{b}))
                OUT=pop_select(EEG,'trial',find([EEG.event.bnum]==n & strcmpi({EEG.event.type},type{b})));
                OUT.setname=[setname '_' type{b} '_' num2str(n)];
                OUT=pop_saveset(OUT,'filename',OUT.setname);
                end
            end
        end
end