function importAccData
%2/9/11 designed to select a bunch of csv files from one session, convert
%to matlab format and combine to one datafile. Also makes time cumuluative
%since it starts over in each CSV file surprisingly.
%[] consider adding code to change time to real time (may need to sync with
%a shake rather than the start time since start time not known)
%8/1/11 added option to cut off time though not sure if works with start
%time
%10/14/11 discovered that sometimes time stamp is less than previous time
%which is nuts and not clear how it affects the data. See evernote 10/14/11 
%12/7/11 version 2 uses spline to interpolate the datapoints assuming that
%the time stamps (other than those that go backwards in time) are accurate.
%Then resample at the frequency it's supposed to be at. Also learned today
%that jumps and irregular spacing in time is accurate, only the backwards
%in time is in error. But need to resample to have equal spacing. 

[CSVFilenames,pathname]=uigetfile('.CSV','Select CSV file(s) to import and combine (will be sorted by name)','Multiselect','on');
if isnumeric(CSVFilenames) %if the user presses cancel is equals 0 which is numeric
    return
end

savename=input('SaveName (use date and time): ','s');
savename=[savename '_Acc'];


if ischar(CSVFilenames) %in case only one chosen
   accData=importdata(fullfile(pathname,CSVFilenames));
else %if multiple selected, assumes that they're all from same session
    CSVFilenames=sort(CSVFilenames); %to be 100% sure they're in number order
    for ci=1:length(CSVFilenames)
        if ci==1
          accData=importdata(fullfile(pathname,CSVFilenames{ci}));
        else %to add subsequent on to previous ones to make one long file
          clear temp
          temp=importdata(fullfile(pathname,CSVFilenames{ci}));
          temp.data(:,1)=temp.data(:,1)+accData.data(end,1);
          accData.data=cat(1,accData.data,temp.data);
        end
    end
end

time=accData.data(:,1);
data=accData.data(:,2:4);
header=accData.textdata;

%10/14/11 add lines to fix time stamp when it decreases in time (though
%this won't fix other errors where there are jumps in time!)
timeD=diff(time);
time(find(timeD<0)+1)=mean([time(find(timeD<0)) time(find(timeD<0)+2)],2);
%find lets you add to it without having to put logical 0s before hand

%%
%12/7/11 use spline to interpolate and ensure an even grid for spectral
%calculation. Can do one version which is at the frequency rate it's
%supposed to be and another optional one for EEG coherence
SRfile=header{7}(end-4:end-3); %works if sampling rate is double digits
fprintf('Sampling rate is %s\n',SRfile);
SR=input('Sampling rate?: (if above innaccurate)');
if isempty(SR)
    SR=str2double(SRfile);
end

%[] make a new time variable here and use it below
timeS=time(1):1/SR:time(end);
dataS=zeros(length(timeS),size(data,2)); %dataS is different size than data
for dd=1:size(data,2) %for each axis of accelerometer
    dataS(:,dd)=spline(time,data(:,dd),timeS);
end
data=dataS;
time=timeS';

%[] note this works when done with time but not with tReal below so in
%later code need to run with time and convert back.

% SRhigh=0; %so can decide not to run it
% if input('Do you also want to resample the data at a different frequency?')
%     SRhigh=input('Other frequency: ');
% end

%[]Will need code later to run EEG Accelerometer coherence and this code
%should resample to whatever frequency is necessary!


%%
%8/1/11 add in line to allow to cut off some of the data
figure;
plot(time,data);zoom xon;
if strcmpi(input('Want to cut off some data (y/n)[n]? ','s'),'y')
    startpoint=input('Start time point (default is current start): ');
    if isempty(startpoint)
        startpoint=time(1);
    end
    endpoint=input('End time point (defaults is current end): ');
    if isempty(endpoint)
        endpoint=time(end);
    end
    time=time(time>startpoint & time<endpoint);
    data=data(time>startpoint & time<endpoint,:);
end


%2/17/11 stop using detrend since ended up with NaN. 
% 
% % dataDet=detrend(accData.data(:,2:4));
% dataDer=diff(data);%the derivative of the data
% dataDer(end+1,:)=[0 0 0]; %so ends up the same length

%run time sync which creates and saves figure and gives a new time variable
%in real time synced to whatever sync time placed from xltec
if strcmpi(input('Want to do time sync now?','s'),'y')
    tReal=acctimesync(time,data,savename);
    save([pwd filesep savename],'data','SR','header','time','tReal');
else
    save([pwd filesep savename],'data','SR','header','time');
end


end