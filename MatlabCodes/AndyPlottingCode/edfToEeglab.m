function data=edfToEeglab

%11/28/12 for imported edf files based on readedf.m but adds option to
%remove non-EEG channels, doesn't add in epochs uncorrectly, saves as a
%.set file.

filename=uipickfiles('type',{'*.edf','EDF file'},'prompt','Pick .set file','out','char');


% readedf() - read eeg data in EDF format.
%
% Usage: 
%    >> [data,header] = readedf(filename);
%
% Input:
%    filename - file name of the eeg data
% 
% Output:
%    data   - eeg data in (channel, timepoint)
%    header - structured information about the read eeg data
%      header.length - length of header to jump to the first entry of eeg data
%      header.records - how many frames in the eeg data file
%      header.duration - duration (measured in second) of one frame
%      header.channels - channel number in eeg data file
%      header.channelname - channel name
%      header.transducer - type of eeg electrods used to acquire
%      header.physdime - details
%      header.physmin - details
%      header.physmax - details
%      header.digimin - details
%      header.digimax - details
%      header.prefilt - pre-filterization spec
%      header.samplerate - sampling rate
    
fp = fopen(filename,'r','ieee-le');
if fp == -1,
  error('File not found ...!');
  return;
end

hdr = setstr(fread(fp,256,'uchar')');
header.length = str2num(hdr(185:192));
header.records = str2num(hdr(237:244));
header.duration = str2num(hdr(245:252));
header.channels = str2num(hdr(253:256));
header.channelname = setstr(fread(fp,[16,header.channels],'char')');
header.transducer = setstr(fread(fp,[80,header.channels],'char')');
header.physdime = setstr(fread(fp,[8,header.channels],'char')');
header.physmin = str2num(setstr(fread(fp,[8,header.channels],'char')'));
header.physmax = str2num(setstr(fread(fp,[8,header.channels],'char')'));
header.digimin = str2num(setstr(fread(fp,[8,header.channels],'char')'));
header.digimax = str2num(setstr(fread(fp,[8,header.channels],'char')'));
header.prefilt = setstr(fread(fp,[80,header.channels],'char')');
header.samplerate = str2num(setstr(fread(fp,[8,header.channels],'char')'));

fseek(fp,header.length,-1);
data = fread(fp,'int16');
fclose(fp);

data = reshape(data,header.duration*header.samplerate(1),header.channels,header.records);%data organized as 3 seconds then channels then next 3 seconds

%reorganize the data to be channels by data x epoch (though not actually
%any epochs). Could be done with permute instead
temp = [];
for i=1:header.records,
  temp = [temp data(:,:,i)'];
end
%reorganize the data removing the epochs which don't really exist
data = reshape(temp,header.channels,[]);

%remove channels that aren't EEG
disp('Channels:');
for ic=1:length(channelList)
    fprintf('%.0f. %s\n',ic,channelList{ic})
end
removelist=[]; %in case none selected the variable needs to exist.
if ~strcmp(input('Remove any channels (y/n) [y]?','s'),'n')
    more=1;
    channelNumber=1;
    while more
        if channelNumber==1
            inputQuestion=sprintf('Channel %.0f(s) to remove (or series like 36:42):',channelNumber);
        else
            inputQuestion=sprintf('Channel %.0f to remove (Return to end):',channelNumber);
        end
        removenumber=input(inputQuestion);
        if length(removenumber)>1
            removelist=removenumber;
            %       elseif isempty(removenumber)
            more=0;
        else
            if isempty(removenumber)
                break
            end
            removelist(channelNumber)=removenumber;%making a list to remove
            channelNumber=channelNumber+1;
        end
    end
end
disp('Removing channels: ')
for rm=1:length(removelist)
    fprintf('%s\n',channelList{removelist(rm),:});
end
channelList(removelist,:)=[];


%remove the epochs s