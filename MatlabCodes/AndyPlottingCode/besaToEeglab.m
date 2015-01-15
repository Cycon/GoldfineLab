function besaToEeglab

%6/11/14 AMG to bring a besa outputted edf file into EEGLAB for Dora. Based
%on egiToEeglab


%% choose file
edfFile=uipickfiles('type',{'*.edf','EDF file'},'prompt','Select besa file as .edf','output','char','num',1);
if isnumeric(edfFile) || isempty(edfFile) %if user presses cancel and it is set to 0
    return
end
[pathname,filename,ext]=fileparts(edfFile);

%replace spaces with underscores since is better coding and works better
%with eegplotEpochChoose
filename=strrep(filename,' ','_');

%% load in with EEGLAB tool
eeg = pop_fileio(edfFile);
eeg.setname=filename;

%this seems to bring in all channels, am not sure what the reference is but
%at least doesn't remove Cz like importing .raw files dose

%Next bring in the channel locations file
%note that pop_readegi brings in an older headset for at least the EGI129 so want to
%bring in the chanlocs manually to ensure the newer EGI headsets.
if size(eeg.chanlocs,1)==33
    eeg.chanlocs=readlocs('GSN-HydroCel-32.sfp');
    eeg.chanlocs=eeg.chanlocs(4:end);%first three aren't real
elseif size(eeg.chanlocs,1)==129
    eeg.chanlocs=readlocs('GSN-HydroCel-129.sfp');
    eeg.chanlocs=eeg.chanlocs(4:end);%first three aren't real
else disp('number of channels not yet coded for');
    return
end

%In egiToEeglab there are options for modifying the events, here events
%are stored in the .edf file.

eeg=eeg_checkset(eeg);

%Events - found that data gets cut up with fake events put in, no idea why!

%make data continuous
disp('Assuming that data is continuous');
eeg.data=reshape(eeg.data,size(eeg.data,1),size(eeg.data,2)*size(eeg.data,3));
eeg.event=[];%remove the events
eeg.trials=1;
eeg.pnts=size(eeg.data,2);
eeg.times=[0:1000/eeg.srate:size(eeg.data,2)*1000/eeg.srate];
eeg.urevent=[];
eeg.epoch=[];


%Need to pull in the events from an Excel spreadsheet!!!
eventFile=uipickfiles('type',{'*.xlsx','Excel file'},'prompt','Select Excel file containing events','output','char','num',1);
if isnumeric(eventFile) || isempty(eventFile) %if user presses cancel and it is set to 0
    return
end
%note this file is stored as
%eventtime(in_micro_s) code TriNo Comment. Need event time and TriNo I think.
%Comment is the only one that is text.

%bring in just the 
eventSheet=xlsread(eventFile);%just bring in the numeric data and ignore the Comment

%convert the type of event to a string
for e=1:size(eventSheet,1) %for each event
    %latency needs to be in units of data points. It starts in microseconds
    %so convert to seconds and then to data points
    eeg.event(e).latency=(eventSheet(e,1)/1000000)*eeg.srate;
    eeg.event(e).type=num2str(eventSheet(e,3));
end
%could have also used below code but then would need another line to conver
%to string
%event=struct('latency',num2cell(eventSheet(:,1)),'type',num2cell(eventSheet(:,3)));


%Data already filtered in BESA so won't do here
% %% detrend it (could add a filter option here too)
% if ~strcmpi(input('1Hz HPF (recommended)? (y/n-detrend) [y])','s'),'n')
%     eeg = pop_iirfilt( eeg, 1);%an eeglab code that calls filtfilt by default
% else %detrend
%     eeg.data=detrend(eeg.data')';
% end

%% run 60 Hz line noise removal copied from xltekToEeglab
if strcmpi(input('Remove 60Hz noise? (y/n) [n]','s'),'y')
    if ndims(eeg.data)==3 %if exported from EGI as epochs
        disp('This is only for continuous data, could be changed');
        return
    end
    filename=[filename '_60'];%to show that it was performed
    params.fpass=[55 65];
    params.pad=4;
    params.tapers=[1 10 1];%since will go in 10 sec chunks
    cL=params.tapers(2)*eeg.srate;%cut length for noise removal
    params.Fs=eeg.srate;
    
    fprintf('%.2f seconds of data cut off of end.\n',...
        mod(size(eeg.data,2),cL)/eeg.srate);
    %then cut off the end of the data
    eeg.data=eeg.data(:,1:end-mod(size(eeg.data,2),cL));
    
    
    denoised=zeros(size(eeg.data));%initialize
    %denoised is now data x channel (transposed from EEG)
    for jk=1:size(eeg.data,2)/cL %number of epochs length of tapers(2)
        denoised(:,(jk-1)*cL+1:jk*cL)=rmlinesc(eeg.data...
            (:,(jk-1)*cL+1:jk*cL)',params,0.2,'n')';%transpose for rmlinesc
        
    end
    eeg.data=denoised;
    %clean up the data structure since cut off end
    eeg.pnts=size(eeg.data,2);
    eeg.times=eeg.times(1:size(eeg.data,2));%times is in ms
    
    %remove events that were in the part cutoff. Latency is in samples
    eeg.event=eeg.event([eeg.event.latency]<=size(eeg.data,2));
end

%%
%save the data
eeg=pop_saveset(eeg,'filename',filename,'filepath',pwd);


