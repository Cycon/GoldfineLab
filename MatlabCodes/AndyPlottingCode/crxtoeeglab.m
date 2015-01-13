function chanlocs = crxtoeeglab

%converts data from crx to format that can be pulled into eeglab (need to
%tell eeg lab the length of epochs and frequency recorded). Also removes
%the 60Hz line noise automatically (though not perfectly).

[crxfile, pathname] = uigetfile('*.crx', 'Select crx files to analyze','MultiSelect','on');
%  if ischar(crxfile) %in case only load one at a time
%      crxfilename=crxfile;
%      clear crxfile;
%      crxfile{1}=crxfilename;
%      
%  end

 if ischar(crxfile) %in case only one chosen
     crxdata=load(fullfile(pathname,crxfile),'-mat');
     chanlocs=docrxtoeeglab(crxdata,crxfile);
     disp('Don''t forget crxtoeeglab can do many at once');
 else
    for cx=1:length(crxfile)
        crxdata=load(fullfile(pathname,crxfile{cx}),'-mat');
        chanlocs=docrxtoeeglab(crxdata,crxfile{cx});
    end
 end

    function chanlocs=docrxtoeeglab(crxdata,crxfile)
    
    ns=crxdata.Info.Count; %number of snippets
    freqRecorded=crxdata.Snippet_1.Hdr.Common.Fs;
    numSecsPerSnippet=crxdata.Snippet_1.Data.SamplesRead/freqRecorded; %num seconds in first snippet

    %%
    %determine shortest segment length (all have to be the same for eeglab)
    for i = 1:ns
        command=sprintf('crxdata.Snippet_%.0f.Data.SamplesRead',i);
        snippetLength{i}=eval(command);
    end
    minSnippetLength=min(cell2mat(snippetLength));
    fprintf('%s snippets range %.0f to %.0f datapoints.\n',crxfile,minSnippetLength,max(cell2mat(snippetLength)));

    %%
    %first initialize matrices for below
    data{1}=zeros(size(crxdata.Snippet_1.Data.modData{1}(1:minSnippetLength,:)));
    data=repmat(data,1,ns);
    if freqRecorded==1024
        resampled=1; %use as a flag for later
        dataResampled{1}=zeros(size(crxdata.Snippet_1.Data.modData{1}(1:minSnippetLength/4,:)));
        dataResampled=repmat(dataResampled,1,ns);
        eegData{1}=dataResampled{1}';
        dataRmLine=dataResampled;
    else
        resampled=0;
        dataRmLine=data;
        eegData{1}=data{1}';
    end
    eegData=repmat(eegData,1,ns);
    %%
    %set up params for removing 60Hz noise
    params.fpass=[55 65];
    params.pad=4;
    params.tapers=[3 5];
    params.Fs=freqRecorded;
    %remove line noise here on each cell

    for i=1:ns
        dataname=sprintf('crxdata.Snippet_%.0f.Data.modData{1}(1:minSnippetLength,:)',i);
        data{i}=eval(dataname); 
    %     [dataRmLine{i} datafit{i}]=rmlinesmovingwinc(data{i},[0.5
    %     0.1],10,params,0.01,'n',60); %this version decreased the length of
    %     the data so use version below.
        if freqRecorded==1024
            dataResampled{i}=resample(data{i},1,4); %downsample after low pass filtering
            params.Fs=256;
            fprintf('Downsampling 1024 Hz data to 256Hz\n');
            dataRmLine{i}=rmlinesc(dataResampled{i},params,0.1,'n'); %set p to 0.1 and seems to work with f0 off (proved it worked by graphing 'y')
        else
            %dataRmLine{i}=rmlinesc(data{i},params,0.1,'n'); %set p to 0.1 and seems to work with f0 off (proved it worked by graphing 'y')
            disp('rmlinesc off')
            dataRmLine{i}=data{i};
        end
        eegData{i}=dataRmLine{i}'; %transposed for eeglab
    end

    
    
%%
    eegData=cell2mat(eegData);
    channelList=crxdata.Snippet_1.Data.sensor.labels;
    % chanlocs=struct('labels',crxdata.Snippet_1.Data.sensor.labels);
    %%
    %give option to not use a couple channels (EMG for instance), just make
    %sure that chanlocs is accurate
    disp('Channels:');
    for ic=1:size(eegData,1)
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
                for ic=1:size(eegData,1)           
                     fprintf('%.0f. %s\n',ic,channelList{ic})
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
    else
        fprintf('Unable to match number of channels with preset lists for reordering')
        if strcmpi(input('Continue leaving order unchanged? (y-yes or Return to cancel out)','s'),'y');
            eegDataReordered=eegData;
            skipreorder=1;
        else
        return
        end
    end

    if ~skipreorder
        eegDataReordered=zeros(size(eegData));
        for io=1:length(ChannelOrder)
            orderIndex = strcmpi(ChannelOrder{io},channelList); %gives a logical vector
            eegDataReordered(io,:)=eegData(orderIndex',:);
            chanlocs(io).labels=channelList{orderIndex};
        end;
    end

    %%

    savename=sprintf('%s_eegLabFormat.mat',crxfile(1:end-4));

    %eventually save other info for automatic opening.
    fprintf('%s created\n',savename);

    if resampled
        %need to redetermine minlength if resampled
        for rs = 1:length(dataRmLine)
            snippetLengthRS{rs}=size(dataRmLine{rs},1);
        end
        minSnippetLength=min(cell2mat(snippetLengthRS));
        freqRecorded=freqRecorded/4;
        fprintf('Frequency Recorded is %.0f\n',freqRecorded);
        fprintf('Number of seconds in original first snippet is %.0f\n',minSnippetLength/freqRecorded); 
        fprintf('Number of samples in original exported snippets is %.0f\n',minSnippetLength);
    else
        fprintf('Frequency Recorded is %.0f\n',freqRecorded);
        fprintf('Number of seconds in original first snippet is %.0f\n',minSnippetLength/freqRecorded); 
        fprintf('Number of samples in original exported snippets is %.0f\n',minSnippetLength);

    end
    save (savename,'eegDataReordered','freqRecorded','minSnippetLength');
    fprintf('Number of samples after removing 60Hz noise is %.0f\n',size(dataRmLine{1},1));
    end

% pop_chanedit(chanlocs); %after running them all then make chanlocs file:
% don't need as of 6/18/10 as long as use ChannelOrder above. If change,
% need to make new list and code to determine the order (can use JV's code
% to dynamically make chanlocs variable).
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