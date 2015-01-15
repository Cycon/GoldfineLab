function cohEeglabAcc

%To run coherence between all channels of an EEGLAB .set file and a .mat
%file containing accelerometer data and time information. If .set file has
%had segments removed, it will also not use those segments of the acc file.
%
%Output needs to
%contain the coherence for each channel and the accelerometer as well as a
%plot of the spectra of the accelerometer. Includes resampling the acc file
%to be on the same frequency grid as the EEG file. Output plottable with
%subplotEeglabCoh.
%
%Also would be nice if worked with EMG file.
%Best would be to bring in the EMG and Acc data in the first place. 
%
%created 12/10/11 AMG

%%
%
disp('Note, this doesn''t work yet if any epochs have been removed with REJECT');

%%
%import and load the data
setfilename=uipickfiles('type',{'*.set','EEGLAB .set file(s)'},'prompt','Pick .set file','num',1,'output','char');
[setpath setname]=fileparts(setfilename);
accfilename=uipickfiles('type',{'*.mat','accelerometer .mat file'},'prompt','Pick .mat file with accelerometer time series','num',1,'output','char');
[accpath accname]=fileparts(accfilename);

savename=input('Savename (or return to use filenames): ','s');
if isempty(savename)
    savename=[setname '_vs_' accname];
end

EEG = pop_loadset('filename',setfilename);
acc=load(accfilename);


%%
%determine the start time and remaining epochs of the .set file (if 
%eegplotEpochKeep use EEG.Source.epochskept otherwise what to do if just rejected normally
%also if reject after eegplotEpockKeep
%assuming used eegplotEpochKeep) so can pull
%the appropriate time out of the acc file.
%1. look for EEG.start, if not there then ask user for full start time
%determine start time of original exported file (should be added in in xltekToEeglab from now on)
%2. determine epoch length, 3. figure out which time ranges were used (some
%could be cut out or only some could be used and then later others cut)
if ~isfield(EEG,'start') %if start time not created with xltekToEeglab
    EEG.start=datestr(input('Start date and time for .set file [YYYY MM DD HH MM SS]: '),'mm/dd/yyyy HH:MM:SS');
end
fprintf('EEG file starts at %s\n',datestr(EEG.start));
if ~input('Correct? (enter to continue or 0 to change)')
    EEG.start=datestr(input('Start date and time for .set file [YYYY MM DD HH MM SS]: '),'mm/dd/yyyy HH:MM:SS');
end

%here figure out the times used. depends if used Reject or eegplotEpochKeep
if ndims(EEG.data)==3 %if epoched
    if isfield(EEG,'Source') %if created from eegplotEpochKeep, though need to figure out if ALSO rejected []
            epochStartTimesInSec=(EEG.Source.epochskept-1)*size(EEG.data,2)/EEG.srate;%starts at 0
            epochEndTimesInSec=(EEG.Source.epochskept)*size(EEG.data,2)/EEG.srate;
            epochRangeInRealDays=([epochStartTimesInSec/60/60/24' epochEndTimesInSec/60/60/24'])+datenum(EEG.start);%add to each one the actual start time
    else %if no epochs removed whether epoched or continuous
            disp('This code meant only if all epochs present or if created with eegplotEpochKeep');
            disp('Does not work yet if epochs removed with Reject button since not easy to know which epochs removed');%[] can use History field
            epochRangeInRealDays=[0 size(EEG.data,2)/EEG.srate*size(EEG.data,3)/60/60/24]+datenum(EEG.start);
    end
else %if continuous data
    epochRangeInRealDays=[0 size(EEG.data,2)/EEG.srate/60/60/24]+datenum(EEG.start);
end

%%
%resample the accelerometer file to be on the same grid as the EEG file
%with spline.m. Ensure in tReal. [] Convert the acc data to 3D like the .set
%file is.
timeS=acc.time(1):1/EEG.srate:acc.time(end); %do with time not tReal since doesn't work with tReal since is datenum and too many trailing digits
for d=1:3
    acc.dataS(:,d)=spline(acc.time,acc.data(:,d),timeS);
end
timeDiff=acc.tReal(1)-acc.time(1)/60/60/24;%to convert to tReal
acc.tRealS=timeS./60/60/24+timeDiff;


%%
%pull out the times from the of the acc file based on times of the .set
%file. %this will have to be a loop or multiple indexing for the multiple
%epochs being used. Transpose so looks like EEG.data with axes x points x
%epochs used
for jj=1:size(epochRangeInRealDays,1)
    acc.dataNew(:,:,jj)=acc.data(acc.tRealS>datenum(epochRangeInRealDays(jj,1)) & acc.tRealS<datenum(epochRangeInRealDays(jj,2)))';
end


%%
%calculate coherence. Ensure output is plottable with subplotEeglabCoh.
%Have to do with each axis of the accelerometer or I guess with the average
%though not ideal. Or can do with the 1st PCA I guess.
