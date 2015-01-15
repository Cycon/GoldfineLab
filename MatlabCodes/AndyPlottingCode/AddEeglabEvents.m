function AddEeglabEvents

%requires a .set file
%optional: a eegLabFormat file containing photic (latency)
%optional: a latency file containing a vector of latency and a cell array
%of eventNames
%version 2 8/4/11 allows use of .xls (not .xlsx on Mac) file instead of .mat for Latencies
%8/5/11 modified so that .xls file has columns of start time, end time,
%type and comment
%[] at the moment will only add on new events to .set file, not setup to
%work on SG file so change if needed. (11/7/11 - not sure if accurate)
%9/1/11 fixed to remove all old events when overwriting (in case new number
%of events smaller than old number) and if epoched, add EEG.event.epoch field
%demarcating the epoch number of each event so it doesn't give error
%messages (need to modify cutEeglab to add same information if dataset
%contains events
%11/7/11 Change from using importdata to xlsread so won't crash if there's
%more than one sheet. xlsread uses the first sheet by default. Also
%required modifying what happens if 2nd and 4th columns of .xls are blank.
%11/13/11 Added startTime to save for SG, not sure where it went.
%11/23/11 changes uigetfile to uipickfiles
%12/21/11 finds start time from EEG file if available
%07/08/13 added fix if run on windows for xls text data

if ~strcmpi(input('Also change a SG.mat file? (y/n) [n]','s'),'y')
    editSG=0;
else
%     [SGFileName SGpathname]=uigetfile('*SG.mat','Choose Spectrogram file');
    SGpathname=uipickfiles('type',{'*.SG.mat','.SG file'},'num',1,'prompt','Pick Spectrogram file');
    SGfile=load(SGpathname{1},'event');%just load event information to modify
    editSG=1;
end

% [setFileName setpathname]=uigetfile('*.set','Choose .set file');
setpathname=uipickfiles('type',{'*.set','.set file'},'num',1,'prompt','Pick EEGLAB .set file');
EEG=pop_loadset('filename',setpathname{1});
%script to add eeg lab event information into eeglab in the workspace

%[] convert hhmmss to datenum to seconds from start (ask for start time)
%then to srate. Need later on to convert back from srate to seconds when
%taking out of .set

%allow to choose from file or paste in
[eeglabFormatFilename pathname]=uigetfile('*Format.mat','Choose eeglab format file if has photic timings in it');
latencyFilename=uipickfiles('refilter','\.xls$|\.mat$','prompt','Choose xls or .mat file containing latencies and/or names (optional)');
    
if eeglabFormatFilename==0
    if strcmpi(latencyFilename{1}(end-2:end),'xls')%if it's an excel file
        [xlsdata.data xlsdata.textdata]=xlsread(latencyFilename{1});
        if ~ismac %windows removes blank columns, but mac leaves them in
            xlsdata.textdata=[cell(size(xlsdata.textdata,1),2) xlsdata.textdata];
        end
%         xlsdata=importdata(fullfile(latpathname,latencyFilename));
        photic.latency=xlsdata.data(:,1);%first column is the start time
        if size(xlsdata.data,2)==1 %if no end times
            eventEnd=nan(size(xlsdata.data));%fill with NaN
        else
            eventEnd=xlsdata.data(:,2);%second column is the end time
        end
        eventNames=xlsdata.textdata(:,3);%since comes in as n,2 matrix
        if size(xlsdata.textdata,2)==3 %if no comments, fill with '-'
            eventComments=repmat({'-'},size(xlsdata.data,1),1);
        else
            eventComments=xlsdata.textdata(:,4); %added 8/5/11
        end
    else
    photic=load(latencyFilename{1},'latency'); %need to create a list in the workspace like latencies =[paste excel here];
    if isempty(fieldnames(photic))
        disp('Error - .mat file chosen for latencies needs to contain a variable called latency');
        return
    end
    end
    
    %determine if in HHMMSS and convert to seconds from start
    if strcmpi(input('Is event time in clock time (y/n-in seconds) [n]','s'),'y') %if in clock time, imports in datenum format
       if isfield(EEG,'start')
           fprintf('Assuming start time from .set file of %s\n',EEG.start);
           startVec=datevec(EEG.start);
           EEG.startTime=startVec(4:6);
       else
        EEG.startTime=input('Start time of file (in [HH,MM,SS]): ');%will save starttime with eeglab file for subplotEeglab
       end
        photic.latency=photic.latency-datenum([0,0,0,EEG.startTime]);
        photic.latency=photic.latency*24*60*60;%to convert to seconds from days
        eventEnd=eventEnd-datenum([0,0,0,EEG.startTime]);
        eventEnd=eventEnd*24*60*60;
    else %leave as is
    end
        
    fraction=input('Fraction to add to latencies? [0]: ');
    if ~isempty(fraction)
        photic.latency=photic.latency+fraction;
    end
    photic.latency=photic.latency*EEG.srate;%this is done automatically in true photic
    eventEnd=eventEnd*EEG.srate;
else
    load(fullfile(pathname,eeglabFormatFilename),'photic');%brings in photic.latency only
end

if ~strcmpi(latencyFilename{1}(end-2:end),'xls')%if it's an excel file since will have event names in it
    if strcmpi(input('Use eventNames from file? (y/n)[y]','s'),'n')
        eventNames=repmat({'event'},length(photic.latency),1);
    else
        load(fullfile(latpathname,latencyFilename{1}),'eventNames');
        if ~length(eventNames)==length(photic.latency)
            disp('wrong number of event names for latency')
            return
        end
    end
end
  
if ~isempty(EEG.event)
    if strcmpi(input('Events exist in dataset. Overwrite? (y/n) [y]','s'),'n')
        e=length(EEG.event);
    else
        e=0;
        EEG.event=[];%to remove all old ones
    end
else
    e=0;
end

for ii=1:length(photic.latency)
    EEG.event(ii+e).latency=photic.latency(ii);
    EEG.event(ii+e).type=eventNames{ii};
    EEG.event(ii+e).comment=eventComments{ii};%added 8/5 to allow comments about event to be more specific
    EEG.event(ii+e).duration=eventEnd(ii)-photic.latency(ii);%in case want to use later
    EEG.event(ii+e).endtime=eventEnd(ii);%in case want to use later. May be NaN if not entered.
    if size(EEG.data,3)>1 %if more than one epoch need to tell it which epoch the event is in to prevent errors with eeg_checkset
        EEG.event(ii+e).epoch=ceil(photic.latency(ii)/size(EEG.data,2));%use ceil otherwise first epoch is called 0 but starts at 1
    end
end
    
% [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET); %to put into the ALLEEG structure
% eeglab redraw % Redraw the main eeglab window
EEG = pop_saveset( EEG,'savemode','resave');

%also modify the SG file loaded in at top
if editSG
    save(fullfile(SGpathname,SGFileName),'-struct','EEG','event','startTime','-append');
end

end