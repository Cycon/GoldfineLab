function doxtptoeeglabPhotic(xtpdata,savename) %this is meant to run on one
%snippet at a time and save photic data. Saves each snippet as a separate
%file as if they are separate experiments. Ideally run on a big chunk of
%data containing an order of experiments.

%first create list of channels to use at all, then use as index below
channelList=xtpdata.metadata(1).headbox.labels;%changed from below 3/17 based on code modificationin xtp_readXLTEfileWithPhotic
% channelList=xtpdata.metadata(1).headbox.labels(1:xtpdata.metadata(1).numleads);%this is a cell array
%it contains extra channels on the end so only want to use as many as
%actual leads exported.
%version 2 5/20/11 change to use rmlinesc since does better job than with
%movingwindow (at least in N6 where even short swatches did better since
%less of overlap). Only disadvantage is lose data at the end for sure. Also
%seems to work better with fewer tapers though need to confirm.
%
%[] would be good to combine with xtptoeeglabPhotic as one code! Just give
%options here or in the next code as to what type of data this is

%%
%give option to not use a couple channels (EMG for instance), just make
%sure that chanlocs is accurate
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
      if length(removenumber)>1 || isempty(removenumber)
          removelist=removenumber;
%       elseif isempty(removenumber)
           more=0;
      else
          removelist(channelNumber)=removenumber;%making a list to remove
          channelNumber=channelNumber+1;
      end
    end
end

channelList(removelist,:)=[];
  
%here convert and save the data
for p=1:length(xtpdata.data) %for each snippet from xltek
    photic.latency=find(xtpdata.photic{p});%find produces the indeces where xtpdata.photic{p}==1 (actually, ~=0). Use for eeglab latency info.
    if length(xtpdata.data)==1
        snippetSaveName=[savename '_eegLabFormat'];%since only one file
    else
        snippetSaveName=[savename '_' num2str(p) '_eegLabFormat'];%so saves each snippet as a separate file
    end
    data=xtpdata.data{p};%note only one snippet at a time
    data(:,removelist)=[]; %to remove the channels chosen above
    freqRecorded=xtpdata.metadata(1).srate;

    %%
    %downsample and remove line noise

    params.fpass=[55 65];
    params.pad=4;
    params.tapers=[1 10 1];%tapers(2) determines how much data is used (based on rmlinesc)
    cL=params.tapers(2)*freqRecorded; %chop length for rmlinesc only, in units of data
    params.Fs=freqRecorded;

    if freqRecorded==1024
       fprintf('Downsampling 1024 Hz data to 256Hz\n'); 


%remove line noise (+/- resample) one segment at a time
%data come in organized as data x channel

       data=resample(data,1,4); 
    end
    
    %may need to add a line to cut data up
    eegData=zeros(floor(size(data,1)/cL)*cL,size(data,2))';
    
    fprintf('Running rmlinesc, cutting off last %.1f seconds\n',((size(data,1)-size(eegData,2))/freqRecorded));
    for jk=floor(1:size(data,1)/cL) %use only as much data as is divisible by tapers(2). End bit gets cut off
     eegData(:,(jk-1)*cL+1:jk*cL)=rmlinesc(data((jk-1)*cL+1:jk*cL,:),params,0.2,'n')';%transpose for eeglab
     %note p value is meaningless since no f0 set so it resets the p-value!
    end

%         disp('running rmlinesmovingwinc, may lose some data at the end');
%         eegData=rmlinesmovingwinc(data,[params.tapers(2) 1],10,params,0.2,'n')';%bigger moving window will do a better job but don't want to move too much or lose data

%below is for data of patient with DBS with 50 and 100 Hz artifact
       %though doesn't work well
%     params.fpass=[45 55];
%     disp('running rmlinesmovingwinc for 50Hz, may lose some data at the end');
%         eegData=rmlinesmovingwinc(eegData',[params.tapers(2) 2],10,params,0.2,'n')';
%      params.fpass=[95 105];   
%         disp('running rmlinesmovingwinc for 100Hz, may lose some data at the end');
%         eegData=rmlinesmovingwinc(eegData',[params.tapers(2) 2],10,params,0.2,'n')';

    %%
    %reorder Channels to be like regular order
    headboxID=xtpdata.metadata.headbox.headboxID;
    switch headboxID
        case {8, 10} %for EMU40 +18 with 37 channels
            ChannelOrder={'FPz','Fp1','Fp2','AF7','AF8','F7','F3','F1','Fz','F2','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CPz','CP2','CP6','T5','P3','Pz','P4','T6','PO7','O1','POz','Oz','O2','PO8'};
        case 1 %for 29 channels from Mobee used early 2009
            ChannelOrder={'Fp1','Fp2','AF7','AF8','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CP2','CP6','T5','P3','Pz','P4','T6','O1','O2'};
        case 9 %for 35 channels, F1 and F2 removed from EMU 40 (used on normal 6 and some patients in 2010)
            ChannelOrder={'FPz','Fp1','Fp2','AF7','AF8','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CPz','CP2','CP6','T5','P3','Pz','P4','T6','PO7','O1','POz','Oz','O2','PO8'};
        otherwise
            fprintf('Unable to match number of channels with channel list for reordering')
            return
    end

    eegDataReordered=zeros(size(eegData));
    for io=1:length(ChannelOrder)
        orderIndex = strcmpi(ChannelOrder{io},channelList); %gives a logical vector
        eegDataReordered(io,:)=eegData(orderIndex',:);
%         chanlocs(io).labels=channelList{orderIndex};
    end;

    fprintf('%s created\n',snippetSaveName);
   
    save (snippetSaveName,'eegDataReordered','freqRecorded','photic','ChannelOrder','headboxID'); %need photic to be in eeglab format or at least with latencies and can attach type later or type here

end
end