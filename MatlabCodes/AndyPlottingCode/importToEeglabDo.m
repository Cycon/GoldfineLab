function [savename pathname]=importToEeglabDo

%version 2 Jun 6, 2011 for 128 channel headbox

[eeglabFilename, pathname] = uigetfile('*eegLabFormat.mat', 'Select converted file to import to eeglab');
eeglabFile=load(fullfile(pathname,eeglabFilename));
detrended=0;
if strcmpi(input('1Hz filter (for ICA) or detrend? (1/d)[1]','s'),'d')
    detrended=1;
    eeglabFile.eegDataReordered=detrend(eeglabFile.eegDataReordered')';%transpose then transpose back
end


%this is new version that uses eeglab channel locations and dynamically
%gives channel locations
opts=eegp_defopts_eeglablocs;%uses eeglab channel list to get lead locations
chanlocVariable=eegp_makechanlocs(char(eeglabFile.ChannelOrder),opts);
% [chanlocFilename, pathname2] = uigetfile('*.ced', 'Select channel location file');


dataname=eeglabFilename(1:end-17);

%added 2/18 for putting in photic as events as a quick fix, need to modify
%to allow decision on naming.
if isfield(eeglabFile,'photic')
    EEG = pop_importdata('dataformat','array','data',eeglabFile.eegDataReordered,...
    'setname',dataname,'srate',eeglabFile.freqRecorded,'subject','1','xmin',0,'nbchan',0,'chanlocs',chanlocVariable);

%     %could put line in here for user to choose text file with events listed
%     for i=1:length(photic.latency)
%     EEG.event(i).latency=photic.latency(i);
%     EEG.event(i).type='event';
%     end
    
else %if no photic and want cut into epochs (like for original imagery analysis)

    EEG = pop_importdata('dataformat','array','data',eeglabFile.eegDataReordered,...
     'setname',dataname,'srate',eeglabFile.freqRecorded,'subject','1','pnts',eeglabFile.minSnippetLength,'xmin',0,'nbchan',0,'chanlocs',chanlocVariable);
end

EEG = eeg_checkset( EEG );
EEG = pop_reref( EEG, []);
% EEG = eeg_checkset( EEG );
disp('1 hz filter off');

if ~detrended %if not detrended
    disp('Applying 1Hz LPF');
    EEG = pop_iirfilt( EEG, 1, 0, [], [0]); %this does a 1Hz HPF
end
EEG = eeg_checkset( EEG );


savename=[dataname '.set'];
if exist(savename,'file')==2 %if this file already exists, don't want to over write since can lose ICA weights, instead allow user to exist without saving
    if ~strcmpi(input('Eeglab file of same name already in path, continue to save? (y or Return to cancel): ','s'),'y')
        return
    end
end       
EEG = pop_saveset( EEG, 'filename',savename,'filepath',pathname);
EEG = eeg_checkset( EEG );
eeglab redraw
end