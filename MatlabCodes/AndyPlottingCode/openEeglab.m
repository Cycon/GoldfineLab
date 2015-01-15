%script to open eeglab if not open and open a set file
%11/23 modified to use uipickfiles instead of uigetfiles. 
%uipickfiles available from matlab filesharing site.
%12/14/11 allow to open multiple at once.
%1/6/12 fixed so doesn't open eeg twice by accident

clear e 

if ~exist('ALLCOM','var') %if eeglab not open then open it.
    eeglab;
%      ALLEEG=[]; %for eeg_store 
end
% [filename pathname]=uigetfile('*.set','Pick .set file to open');
pathname=uipickfiles('type',{'*.set','.set file'},'prompt','Pick EEGLAB .set file');


if isnumeric(pathname) || isempty(pathname) %if user presses cancel output is 0, done with no selection is {}
    return
end

for e=1:length(pathname)
    [filepath,filename,ext]=fileparts(pathname{e});
    EEGtmp = pop_loadset('filename',[filename ext],'filepath',filepath);

     [ALLEEG, EEG] = eeg_store( ALLEEG, EEGtmp);
         EEG=eeg_checkset(EEG);
%     [ALLEEG, EEG] = eeg_store( ALLEEG, EEGtmp,length(ALLEEG)+1);%9/21/10 this line was 
    %commented out, not sure why and may be cause of it overwriting previously
    %entered dataset with new one when run this code twice
    if numel(size(EEG.data))==3
        wl=size(EEG.data,3); %can modify if don't want to display all the data
    else
        wl=10;%display 10 seconds of continuous data
    end
    if isfield(EEG,'event')
        ev=EEG.event;
    else
        ev=[];
    end
    eegplot(EEG.data,'srate',EEG.srate,'eloc_file',EEG.chanlocs,'winlength',wl,'events',ev)
%     pop_eegplot( EEG, 1, 1, 1);
    set(gcf,'name',EEG.setname);

end

 eeglab rebuild %since added all the EEGs need to have the window show it.
clear pathname e wl ev EEGtmp