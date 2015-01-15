function SGeeglab
%this does spectrogram on eeglab data. 

%this is a script so can pull ALLEEG from the system
%set defaults
% Set params for mtspecgramc 
%8/3/11 version 2 added check to crash out if <1 taper and added saving of
%event info
%1/19/12 version 3 modified event so that if doing average spectrum, just
%use the event information from the first one, assuming they're all the
%same.
%3/5/12 version 4 add option to just do channels from Cruse et al. if using
%the EGI system just to save memory. [] future give uilist for user to pick
%subset of channels to use. Also removed a for loop to speed it up and
%switched to uipickfiles.
%4/4/12 changed savename to come from the filename and not from the
%setname.
%4/16/12 version 5 changed to store frequency resolution so in
%subplotSpectrogram can display it and store epoch length
%for display of events in epoched data.
%5/14/12 added catch to ensure that moving window isn't longer than epoch
%length
%9/6/12 add saving of Serr so can plot it in a line graph. Also removed
%setting of fpass and will just let it default to nyquist.
%9/8/13 added catch that if alleeg.event is empty won't crash but "event"
%will be empty at the end

% [setfilename, pathname] = uigetfile('*.set', 'Select EEG file');
setfilename=uipickfiles('type',{'*.set','EEGLAB file '},'prompt','Select EEG file','num',1,'output','char');
        
if isempty(setfilename) || isnumeric(setfilename); %if press cancel for being done
    return
end
alleeg = pop_loadset('filename',setfilename);
%         

[path savename]=fileparts(setfilename);
if strcmpi(input('Use laplacian? (y-yes or Return): ','s'),'y')
    alleeg.data=MakeLaplacian(alleeg.data,alleeg.chanlocs);
    savename=[savename '_Lap'];
end

%list below is left then middle (6 129 55) then right channels
CruseList=[13 29 35 7 30  36 41 31 37 42 54 6 129 55 112 111 110 106 105 104 103 80 87 93 79];
%choose subset of channels. [] add GUI for user to choose subset
if strcmpi(alleeg.chanlocs(1).labels,'E1') && length(alleeg.chanlocs)==129
    if strcmpi(input('EGI129 system. Use 25 channels from Cruse et al.? (y/n) [n]','s'),'y');
        alleeg.data=alleeg.data(CruseList,:,:);
        alleeg.chanlocs=alleeg.chanlocs(CruseList);
    end
end
 


%  params.tapers=[3 5];
 frequencyResolution=3;
%  fpassInHz=[0 100];
 params.pad=-1;
 params.Fs=alleeg.srate; %need to define this from data later in code
%  params.err=[1 0.05];
 params.trialave=0; %can change to 0 to look at one snippet at a time.
 %if 0, then output S is time points x frequencies x trials.
 %if 1, then output S is time points x spectrograms. Important to know for plotting
 %if movingwin is the length of each snippet then time points =1!
 movingwinInSec=[1 .1];

 disp('Would you like to use default parameters for mtspecgram?');
 fprintf('Frequency Resolution %.0f Hz\n',frequencyResolution);
 disp(params);
%  fprintf('    fpass (in Hz): [%.0f %.0f]\n',fpassInHz(1), fpassInHz(2));
 fprintf('    movingwin (in sec): [%.2f %.2f]\n',movingwinInSec(1), movingwinInSec(2));
 default = input('Return for yes (or n for no): ','s');
 if strcmp(default,'y') || isempty(default)
     params.FR=frequencyResolution;
 else
     disp('define params (Return leaves as default)');
     p.pad=input('pad:');
     if ~isempty(p.pad)
         params.pad=p.pad;
     end
%      fpass1=input('starting frequency of fpass:');
%      if ~isempty(fpass1)
%          fpassInHz(1)=fpass1;
%      end
%      fpass2=input('ending frequency of fpass:');
%      if ~isempty(fpass2)
%          fpassInHz(2)=fpass2;
%      end
     p.mwinsec=input('moving win (in seconds in brackets like [1 0.1]):');
     if ~isempty(p.mwinsec)
         movingwinInSec=p.mwinsec;
         if movingwinInSec(1)>size(alleeg.data,2)/alleeg.srate
             disp('Moving window longer than epoch length.');
             movingwinInSec=input('moving win (in seconds in brackets like [1 0.1]):');
         end
     end
     fprintf('Minimum freq res is %.1f Hz\n',2/movingwinInSec(1));
     params.FR=input('Frequency Resolution: ');
     if isempty(params.FR)
         params.FR=frequencyResolution;
     end
     if params.FR<2/movingwinInSec(1)
         disp('Frequency resolution too low for width of moving window');
         return
     end
     if strcmpi(input('Average trials? (y-yes or Return for no)','s'),'y');
         params.trialave=1;
     end
     fprintf('\nparams are now:\n');
     disp(params);
     fprintf('movingwin (in sec): [%.2f %.2f]\n',movingwinInSec(1), movingwinInSec(2));
     fprintf('Frequency Resolution: %.2f Hz\n',params.FR);
 end
 
 params.tapers(1)=params.FR/2*movingwinInSec(1);
 params.tapers(2)=params.tapers(1)*2-1;
 if params.tapers(2)<1
     disp('<1 taper, won''t work.');
     return
 end
 
 params.err=[2 0.05];


%
%[] need to take data organized as dataxchannelxsnippet and reorganize to
%be dataxsnippet so can average across them and then do one channel at a
%time

% params.fpass=fpassInHz;

%change to be data x snippet with each channel in a cell
numChan=size(alleeg.data,1);
% numSnip=size(alleeg.data,3);
ChannelList={alleeg.chanlocs.labels};
% for i=1:numChan
%     for j=1:numSnip
%         dataByChannel{i}(:,j)=alleeg.data(i,:,j); %organized as dataxsnippet (dataxtrial in chronux terms)
%     end
%     ChannelList{i}=alleeg.chanlocs(i).labels;
% end

% %to change length of snippet, assumes each one is 3 seconds long
% dataByChannelLongerTrials=cell(size(dataByChannel));
% nSC=5; %numberOfSnippetsToCombine
% fprintf('Converting snippets to length %.0f seconds\n',nSC*size(alleeg.data,2)/alleeg.srate);
% for i2=1:numChan
%     for j2=1:numSnip/nSC
%         dataByChannelLongerTrials{i2}=[dataByChannelLongerTrials{i2} reshape(dataByChannel{i2}(:,(nSC*(j2-1)+1):nSC*(j2-1)+nSC),(size(dataByChannel{i2},1)*nSC),1)];
%     end
% end  
% dataByChannel=dataByChannelLongerTrials;
    
%initialize
S=cell(1,numChan);
t=cell(1,numChan);
f=cell(1,numChan);

for ij=1:numChan
    [S{ij},t{ij},f{ij},Serr{ij}]=mtspecgramc(squeeze(alleeg.data(ij,:,:)),movingwinInSec,params);%added 3/5/12 so don't need for loop above
%     [S{ij},t{ij},f{ij}]=mtspecgramc(dataByChannel{ij},movingwinInSec,params);
%     [S{ij},t{ij},f{ij},Serr{ij}]=mtspecgramc(dataByChannel{ij},movingwinInSec,params);
end
   
epochLength=size(alleeg.data,2)/alleeg.srate;

% end
if exist([savename '_SG.mat'])==2
    savename=input('Savename already exists, new name: ','s');
end
if params.trialave && ~isempty(alleeg.event)
    event=alleeg.event(1);
else
    event=alleeg.event;%want to save event information for displaying in spectrograms
end
if isfield(alleeg,'startTime')
    startTime=alleeg.startTime;
else
    startTime='';
end
save([savename '_SG.mat'],'S','t','f','params','movingwinInSec','ChannelList','event','startTime','epochLength','Serr')
% save([savename
% '_SG.mat'],'S','t','f','Serr','params','movingwinInSec','ChannelList')
end

