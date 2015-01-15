function blockSrivasData

%to create new .set files from the .set data from Cruse et al. where all
%are concatenated and some epochs removed.

setFiles=uipickfiles('type',{'*.set','.set file(s)'},'prompt','pick .set file(s)');

for sf=1:length(setFiles)
    [setpath setname]=fileparts(setFiles{sf});
    EEG=pop_loadset(setFiles{sf});
    
    %how many blocks are there?
    nb=(size(EEG.urevent,2)-1)/15
    
    %make new .set file for each event type
    types=unique({EEG.event(1:end).type})
    num=1:length(EEG.event); %to index the events
        for b=1:nb
            if b<=nb/2 %first half
                newsetname=[setname '_' types{1} '_' num2str(b)];
                OUT=pop_select(EEG,'trial',[num([EEG.event.urevent]>15*(b-1) & [EEG.event.urevent]<15*b+1)]);
            else %for foot need to add 1 to urevent because of the boundary between them
                newsetname=[setname '_' types{2} '_' num2str(b-nb/2)];
                OUT=pop_select(EEG,'trial',[num([EEG.event.urevent]>15*(b-1)+1 & [EEG.event.urevent]<15*b+2)]);
            end
            OUT.setname=newsetname;
            OUT=pop_saveset(OUT,'filename',newsetname);
        end
end