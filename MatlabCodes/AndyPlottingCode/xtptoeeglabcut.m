function xtptoeeglabcut(varargin)
%need to supply an aggregated or single xtpfile.
%
%2/10/11 version 2 - takes in cut xtp files (not aggregated ones anymore,
%though not much difference). Gives user option to combine all snippets and
%cut them to shorter lengths OR make each snippet a separate file without
%any further cutting but keeping the photic point markers.
%5/1/11 version 2.1 has default to remove channels after 37
%6/22/11 version 2.2 saves channel order (like the one on Jon Bardin's
%computer).
%
%created 6/28/10 based on xtptoeeglab and crxtoeeglabcut
%
%created 6/11/10 for importing xtp files that have been preprocessed
%without a montage into eeglab format. Need to aggregate them and save as a
%mat file containing only aggregated data.
%
%these are mat files containing a structure with metadata, info and data.
%
%[]determine if always the same bad channels and remove them automatically
%[] could modify code to run on many at once but need a standard variable
%name for the aggregated file to load in



 
%[] give user option of not aggregating and run on each separately, mainly for those using photic markers.
%also need to put in code to pass on photic marker information and
%convert to eeglab event file 'latency' and add in 'type'
[cutXLTEKfilename,pathname]=uigetfile('*cut.mat','Choose cut XTP .mat file');
%to import file of unknown name use importdata. Other thought is to use who
%the files here have a structure variable containing the data and don't
%want to end up with a structure inside a structure which is what load
%does
cutXLTEKfile=load(fullfile(pathname,cutXLTEKfilename));
cutData=cutXLTEKfile.cutXLTEK{1}; %to make easier later
savename=cutXLTEKfilename(1:end-11);
if strcmpi(input('Combine all snippets (assuming no use of photic event markers) (y/n)[y]?','s'),'n')
    %here have it run separately on each cut and convert photic markers to
    %latencies and import a list of names
    disp('Will save each snippet as a separate file and allow use of photic event markers.');

         doxtptoeeglabPhotic(cutData,savename) 
         
else
    %only need to aggregate separately if combining data from different
    %files. Not usually done with my type of analysis. Can do on own if
    %want.
    
%     aggregatedXTPdata=xtp_aggregateCell(cutData); %modified from Shawniqua's version

    
    doxtptoeeglabcut(cutData,savename);
end

function doxtptoeeglabcut(xtpdata,savename) %note can change savename to the name of the 
    %file if want to automatically create a savename
    %This code divides each snippet to cut length and throws away any
    %remainder then puts them all together.

data=xtpdata.data;
ns=size(data,2); %number of snippets
freqRecorded=xtpdata.metadata(1).srate;
cutLengthInSecs=3;
cutString=sprintf('Default cut length is %.0f sec, keep (Return) or change (n)?',cutLengthInSecs);
if strcmpi(input(cutString,'s'),'n')
    cutLengthInSecs=input('New cut length in seconds: ');
end
CL=cutLengthInSecs*freqRecorded;

%%
%1. downsample and remove line noise

params.fpass=[55 65];
params.pad=4;
params.tapers=[2 cutLengthInSecs 1];
params.Fs=freqRecorded;

 if freqRecorded==1024
       fprintf('Downsampling 1024 Hz data to 256Hz\n');
       CL=cutLengthInSecs*256; 
 end


%remove line noise (+/- resample) one segment at a time
%data come in organized as data x channel

%1st initialize matrices, [] need to confirm this!
% xtpdataRS{1}=zeros(size(xtpdata.data{1}));
% xtpdataRS=repmat(xtpdataRS,1,ns);
% xtpdataF=xtpdataRS;

eegData=[]; %so starts out as size 0

for ir=1:ns
    if freqRecorded==1024
       data{ir}=resample(data{ir},1,4);
       CL=cutLengthInSecs*256; 
    end

  
    %%
    %cut data to all same length
     if size(data{ir},1)>=CL %CL is cut length in samples; should skip if shorter than cutlength
            numCuts=floor(size(data{ir},1)/CL);
            for nc=1:numCuts
                numCol=size(eegData,2); %to get current size of eegData to add on to it (eegData is channel x data)
                eegData(:,numCol+1:numCol+CL)=rmlinesc(data{ir}(((nc-1)*CL)+1:nc*CL,:),params,0.2,'n')'; %transposes and adds on to previous and removes line noise
            end
     end
end


%%
if isfield('channelNames',xtpdata.info)%since doesn't appear when coming from xltekToEEGLAB probably since no montage ran
    channelList=xtpdata.info.channelNames(1:size(eegData,1))'; %need to transpose here to be like crx so works below
else
    channelList=xtpdata.metadata(1).headbox.labels(1:size(eegData,1))';%this is a cell array
end
%also there may be extra channels at the end without eeg in them so this
%removes them
    %%
    %give option to not use a couple channels (EMG for instance), just make
    %sure that chanlocs is accurate
    disp('Channels:');
    for ic=1:size(eegData,1)
        fprintf('%.0f. %s\n',ic,channelList{ic})
    end
    removeCh=input('Remove any channels (y-yes, Return-[38:46],n-no)?','s');
    if strcmp(removeCh,'y')
        more=1;
        while more
          removenumber=input('Channel # to remove (Return to end):');
          if isempty(removenumber)
              more=0;
          else
              eegData=[eegData(1:removenumber-1,:);eegData(removenumber+1:end,:)];
              channelList=[channelList(1:removenumber-1) channelList(removenumber+1:end)];
              disp('new channel list');
                for ic2=1:size(eegData,1)           
                     fprintf('%.0f. %s\n',ic2,channelList{ic2})
                end
          end
        end
    elseif strcmpi(removeCh,'') %this is default to keep 37 channels
        eegData=eegData(1:37,:);
        channelList=channelList(1:37);
    else %if no, leave as is
    end
    

    %%
    %reorder Channels to be like regular order
    if length(channelList)==37
        ChannelOrder={'FPz','Fp1','Fp2','AF7','AF8','F7','F3','F1','Fz','F2','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CPz','CP2','CP6','T5','P3','Pz','P4','T6','PO7','O1','POz','Oz','O2','PO8'};
    elseif length(channelList)==29
        ChannelOrder={'Fp1','Fp2','AF7','AF8','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CP2','CP6','T5','P3','Pz','P4','T6','O1','O2'};
    else
        fprintf('Unable to match number of channels with channel list for reordering, will leave as is')
        ChannelOrder=channelList;
    end

    eegDataReordered=zeros(size(eegData));
    for io=1:length(ChannelOrder)
        orderIndex = strcmpi(ChannelOrder{io},channelList); %gives a logical vector
        eegDataReordered(io,:)=eegData(orderIndex',:);
%         chanlocs(io).labels=channelList{orderIndex};
    end;

    %%
    %to make a savename need to import a .mat file rather than a variable
    %so below line is turned off
%     savename=sprintf('%s_eegLabFormat.mat',xtpfile(1:end-4));

    %eventually save other info for automatic opening.
    fprintf('%s created\n',savename);

%     minSnippetLength=size(data{1},1);
    minSnippetLength=CL;
    if freqRecorded==1024
        %need to redetermine minlength if resampled
%         for rs = 1:length(dataRmLine)
%             snippetLengthRS{rs}=size(dataRmLine{rs},1);
%         end
%         minSnippetLength=size(xtpdataRS,1);
        minSnippetLength=CL;
        freqRecorded=freqRecorded/4;
        fprintf('Frequency Recorded after resampling is %.0f\n',freqRecorded);
        fprintf('Number of seconds in first snippet is %.0f\n',minSnippetLength/freqRecorded); 
        fprintf('Number of samples in exported snippets is %.0f\n',minSnippetLength);
    else
        fprintf('Frequency Recorded is %.0f\n',freqRecorded);
        fprintf('Number of seconds in first snippet is %.0f\n',minSnippetLength/freqRecorded); 
        fprintf('Number of samples in exported snippets is %.0f\n',CL);

    end
    save ([savename '_eegLabFormat'],'eegDataReordered','freqRecorded','minSnippetLength','ChannelOrder');
%     fprintf('Number of samples after removing 60Hz noise is
%     %.0f\n',size(dataRmLine{1},1));
end
end