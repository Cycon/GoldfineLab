function importEeglabAcc

%to import the accelerometer time series to an EEGLAB file ensuring that
%the time and sampling frequency match up. Only meant for continuous .set
%files (code originally called cohEeglabAcc which had options for epochs
%removed).
%
%needs to be done after average referencing so doesn't get included in the
%reference!
%
%may want another version for EMG though don't think necessary
%
%created 12/12/11 AMG

%%
%import and load the data
setfilename=uipickfiles('type',{'*.set','EEGLAB .set file(s)'},'prompt','Pick .set file','num',1,'output','char');
[setpath setname]=fileparts(setfilename);

EEG = pop_loadset('filename',setfilename);
if ndims(EEG.data)==3
    disp('Meant only for continuous EEGLAB files'); %though could be coded otherwise but risky that epochs were removed
    return
end

accfilename=uipickfiles('type',{'*_Acc.mat','accelerometer .mat file'},'prompt','Pick .mat file with accelerometer time series','num',1,'output','char');
% [accpath accname]=fileparts(accfilename);
if isnumeric(accfilename) %if press cancel
    return
end

savename=input('Savename (or return to use .set filename): ','s');
if isempty(savename)
    savename=[setname '_acc'];
end

acc=load(accfilename);


%%
%determine the start time and length
%1. look for EEG.start, if not there then ask user for full start time
%determine start time of original exported file (will be added in in xltekToEeglab from now on)
%2. determine duration
fprintf('Accelerometer starts at %s\n',datestr(acc.tReal(1),31));
if ~isfield(EEG,'start') %if start time not created with xltekToEeglab
    EEG.start=datestr(input('Start date and time for .set file [YYYY MM DD HH MM SS]: '),'mm/dd/yyyy HH:MM:SS');
end
fprintf('EEG file starts at %s\n',datestr(EEG.start));
if ~input('Correct? (enter to continue or 0 to change)')
    EEG.start=datestr(input('Start date and time for .set file [YYYY MM DD HH MM SS]: '),'mm/dd/yyyy HH:MM:SS');
end

if ~isfield(EEG,'end') %created by xltekToEeglab as of 12/11/11 and defines the end time not included in the data
    EEG.end=datenum(EEG.start)+size(EEG.data,2)/EEG.srate/60/60/24; %accurate since 1 less datapoint is a different time
end

%%
%cut out the used time of the accelerometer time series so just have to
%spline it rather than the whole dataset in case large
durationInSec=size(EEG.data,2)/EEG.srate;

%get the data I need from the start time for the full duration, seems to
%work
acc.dataU=acc.data(acc.tReal>=datenum(EEG.start) & acc.tReal<datenum(EEG.end),:);

if size(acc.dataU,1)/acc.SR~=size(EEG.data,2)/EEG.srate
    disp('Seconds of cut out acc time series doesn''t match length of EEG time series.')
    return
end

%resample the accelerometer file to be on the same grid as the EEG file
%with spline.m and add to the bottom of the EEG.data file.
nc=size(EEG.data,1);%number of channels

%note in code below, time doesn't start at 0 since ended up with 1 too many
%data points. Instead start at first sample
for d=1:3
    EEG.data(nc+d,:)=spline(1/acc.SR:1/acc.SR:durationInSec,acc.dataU(:,d),1/EEG.srate:1/EEG.srate:durationInSec);
end

%%
%modify the chanlocs and whatever other variables necessary to be
%internally consistent.
EEG.setname=savename;
EEG.nbchan=size(EEG.data,1);

EEG.chanlocs(nc+1).labels='AccX';
EEG.chanlocs(nc+2).labels='AccY';
EEG.chanlocs(nc+3).labels='AccZ';
%eegp_makechanlocs makes everything it doesn't know a NaN for x,y,z so this
%way consistent with that code. [] Need to ensure that topoplot ignores
%these channels too. And other codes can make use of this information. 
[EEG.chanlocs(nc+1:nc+size(acc.data,2)).X]=deal(NaN); %alternative to deal is making a 1x3 vector of NaN to be assigned
[EEG.chanlocs(nc+1:nc+size(acc.data,2)).Y]=deal(NaN);
[EEG.chanlocs(nc+1:nc+size(acc.data,2)).Z]=deal(NaN);

EEG = pop_saveset(EEG, 'filename',savename,'filepath',pwd);
