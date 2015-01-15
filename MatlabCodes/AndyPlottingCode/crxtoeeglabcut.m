function crxtoeeglabcut

%converts data from crx to format that can be pulled into eeglab (need to
%tell eeg lab the length of epochs and frequency recorded). Also removes
%the 60Hz line noise automatically (though not perfectly).
%
%based on crxtoeeglab
%version 1 to allow for cutting of segments to all be same length.
%[] remove minsnippetlength code that cuts them to same length
%[] copy in code from batCrxSpectra to cut them all to same legnth
%version 2 remove chanlocs creation since not needed and make sure rmline
    %is on cut segments to save memory

[crxfile, pathname] = uigetfile('*.crx', 'Select crx files to analyze','MultiSelect','on');
if ~iscell(crxfile) && crxfile==0
    return
end
 if ischar(crxfile) %in case only one chosen
     crxdata=load(fullfile(pathname,crxfile),'-mat');
     docrxtoeeglabcut(crxdata,crxfile);
     disp('Don''t forget crxtoeeglab can do many at once');
 else
    for cx=1:length(crxfile)
        crxdata=load(fullfile(pathname,crxfile{cx}),'-mat');
        docrxtoeeglabcut(crxdata,crxfile{cx});
    end
 end
%%

    function docrxtoeeglabcut(crxdata,crxfile)
    
    ns=crxdata.Info.Count; %number of snippets
    freqRecorded=crxdata.Snippet_1.Hdr.Common.Fs;
    cutLengthInSecs=3;
    CL=cutLengthInSecs*freqRecorded; %cut length in datapoints
    %set up params for removing 60Hz noise
    params.fpass=[58 62];
    params.pad=5;
    params.tapers=[3 5];
    params.Fs=freqRecorded;
    %remove line noise here on each cell
    
   
%     numSecsPerSnippet=crxdata.Snippet_1.Data.SamplesRead/freqRecorded; %num seconds in first snippet

    %%
    %determine snippet lengths
    for is = 1:ns
        command=sprintf('crxdata.Snippet_%.0f.Data.SamplesRead',is);
        snippetLength{is}=eval(command); %can use this to determine appropriate length
    end
    
%%

    %%
    %first initialize matrices for below (doesn't work if all different
    %lengths!)
%     data{1}=zeros(size(crxdata.Snippet_1.Data.modData{1}(1:minSnippetLength,:)));
%     data=repmat(data,1,ns);
    if freqRecorded==1024
        resampled=1; %use as a flag for later
        CL=cutLengthInSecs*256; %since resample before cutting
%         dataResampled{1}=zeros(size(crxdata.Snippet_1.Data.modData{1}(1:minSnippetLength/4,:)));
%         dataResampled=repmat(dataResampled,1,ns);
%         eegData{1}=dataResampled{1}';
%         dataRmLine=dataResampled;
    else
        resampled=0;
%         dataRmLine=data;
%         eegData{1}=data{1}';
    end
%     eegData=repmat(eegData,1,ns);
%%

    eegData=[]; %so starts out as size 0.
    
    for i=1:ns % for each snippet
        dataname=sprintf('crxdata.Snippet_%.0f.Data.modData{1}',i);
        data=eval(dataname);
        if freqRecorded==1024
%             dataResampled=resample(data,1,4); %downsample after low pass filtering
            data=resample(data,1,4); %downsample after low pass filtering
            params.Fs=256;
            fprintf('Downsampling 1024 Hz data to 256Hz\n');
            
%             dataRmLine=rmlinesc(dataResampled,params,0.2,'n'); %set p to 0.1 and seems to work with f0 off (proved it worked by graphing 'y')
            %6/23 changed p to 0.2 so hopefully works better
        else
%             dataRmLine=rmlinesc(data,params,0.2,'n'); %set p to 0.1 and seems to work with f0 off (proved it worked by graphing 'y')
        end 
%%
%cut data to all same length. dataRmLine is sample x channels
        if size(data,1)>=CL %CL is cut length in samples; should skip if shorter than cutlength
            numCuts=floor(size(data,1)/CL);
            for nc=1:numCuts
                numCol=size(eegData,2); %to get current size of eegData to add on to it (eegData is channel x data)
                eegData(:,numCol+1:numCol+CL)=rmlinesc(data(((nc-1)*CL)+1:nc*CL,:),params,0.2,'n')'; %transposes and adds on to previous and removes line noise
%                 eegData(:,numCol+1:numCol+CL)=dataRmLine(((nc-1)*CL)+1:nc*CL,:)'; %transposes and adds on to previous
            end
        end
        
    end
    
    
%%
    channelList=crxdata.Snippet_1.Data.sensor.labels;
    % chanlocs=struct('labels',crxdata.Snippet_1.Data.sensor.labels);
    %%
    %give option to not use a couple channels (EMG for instance), just make
    %sure that chanlocs is accurate
    disp('Channels:');
    for ic=1:size(eegData,1) %for each channel
        fprintf('%.0f. %s\n',ic,channelList{ic})
    end
    if strcmp(input('Remove any channels (y-yes, Return-no)?','s'),'y')
        more=1;
        while more
          removenumber=input('Channel # to remove (Return to end):');
          if isempty(removenumber)
              more=0;
          else
              eegData=[eegData(1:removenumber-1,:);eegData(removenumber+1:end,:)];
              channelList=[channelList(1:removenumber-1) channelList(removenumber+1:end)];
              disp('new channel list');
                for id=1:size(eegData,1)           
                     fprintf('%.0f. %s\n',id,channelList{id})
                end
          end
        end
    end

    %%
    %reorder Channels to be like regular order
    skipreorder=0;
    if length(channelList)==37
        ChannelOrder={'FPz','Fp1','Fp2','AF7','AF8','F7','F3','F1','Fz','F2','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CPz','CP2','CP6','T5','P3','Pz','P4','T6','PO7','O1','POz','Oz','O2','PO8'};
    elseif length(channelList)==29
        ChannelOrder={'Fp1','Fp2','AF7','AF8','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CP2','CP6','T5','P3','Pz','P4','T6','O1','O2'};
    elseif length(channelList)==35
        ChannelOrder={'FPz','Fp1','Fp2','F7','F3','F1','Fz','F2','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CPz','CP2','CP6','T5','P3','Pz','P4','T6','PO7','O1','POz','Oz','O2','PO8'};
    else
        fprintf('Unable to match number of channels with channel list for reordering')
        skipreorder=1;
        eegDataReordered=eegData;
    end

    if ~skipreorder
         eegDataReordered=[];
         ei=1; %need an index in case any channels not there.
        for io=1:length(ChannelOrder)
            orderIndex = strcmpi(ChannelOrder{io},channelList); %gives a logical vector
            if ~sum(orderIndex)==0 %if that channel is found (code added 11/3/10 because of modified montage with chin channels)
                eegDataReordered(ei,:)=eegData(orderIndex',:);
                ei=ei+1;
            end %so in case where AF7 is C1 (IN316W visit4) then will end up with fewer channels
    %         chanlocs(io).labels=channelList{orderIndex}; %don't need this
    %         anymore as of June 2010
        end;
    end

    %%

    savename=sprintf('%s_eegLabFormat.mat',crxfile(1:end-4));

    %eventually save other info for automatic opening.
    fprintf('%s created\n',savename);

    if resampled
        freqRecorded=freqRecorded/4;
        fprintf('Frequency Recorded is %.0f\n',freqRecorded);
        fprintf('Number of samples per snippet is %.0f\n',CL); 
    else
        fprintf('Frequency Recorded is %.0f\n',freqRecorded);
        fprintf('Number of samples per snippet is %.0f\n',CL); 

    end
    minSnippetLength=CL; %for importEeglab
    save (savename,'eegDataReordered','freqRecorded','minSnippetLength');
    end

% pop_chanedit(chanlocs); %after running them all then make chanlocs file
end

%then in EEGLAB you load eegData and tell it the sampling rate and how
%many per cut
%[] use eeglab in coding to be better


%%
% 
% %to load channel locations
% pop_chanedit(chanlocs);
%then save as a channelloc file and then need to read it in.
%%then go to edit channel locations and click read locations

%then run ICA, look at the components, export and plot 2:end, 2:end in
%matlab and plot the power spectra. Probably the ones that go up are
%artifact and an try to remove. 

%Then in EEG lab do file export. Better to click transpose if want to
%replace in crx file. Also uncheck export channel labeles. Not sure about
%time values. Then do load into matlab and save (or end in .mat?). Also
%figure out how to use multitaper PS in eeglab since their power spectra
%routine doesn't work.