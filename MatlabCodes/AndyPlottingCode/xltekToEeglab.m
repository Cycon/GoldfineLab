function xltekToEeglab
%version 1 - 2/10/11
%version 1.1 5/1/11 give option to not use epoch file but instead use the
%first photic marker as the start time or just leave as is
%first make a list of start and end times in excel and save as a text file.
%then export a txt file from xltek
%use this code to cut out the times you want and save as a cut file. Then
%use xtptoeeglabcut
%created 6/22/11 to combine with xtptoeeglab since no reason to keep
%separate.
%
%TO DO:
%[ ] give user option to vary the epoch length or have no epochs in eeglab
%(modify in xtptoeeglabcut or modify here and send to there);
%[ ] consider code to just plot at the end here (eegplot) so don't need to
%run eeglab if not planning to do ICA. Consider moving everything out of
%eeglab.
%version 1.2 10/14/11 AMG made downsampling optional
%version 1.3 1/3/12 AMG made remove line noise optional
%version 1.4 1/5/12 AMG - added option for 30 channels from EKDB-12 with
            %FPz left in. Also added option for 19 channels from 2008
            %datasets with no X1-X10 and no FPz.
%version 2 7/3/12 AMG - make it possible to pull in multiple xltek files
        %along with one epoch list (standard procedure for Mary). Modified saving
        %of start and end time so only works if only one .txt file and one cut. Also,
        %change creation at beginning as cells to structures [] later
        %need to fix other code so doesn't ask for headbox for each one. []
        %also need to fix to make the output in time order and get start
        %and end time of each one into eeglab. Also remove call to eegp_makechanlocs
        %since we no longer like those channel locations (midline channels
        %not at midline)
%version 2.1 11/28/12 AMG found a dataset where photic markers represent
    %two event types, but the code doesn't work because there's an extra "rest"
    %event at the beginning. Now if there are 2 events types and odd number of
    %events, will ask if want to remove the 1st or last event. Also made
    %not removing line noise the default.
%version 2.2 3/7/13 now catches if forget to remove all the non-EEG
    %channels since otherwise don't get a correct chanlocs variable. Also
    %changed default to not reference to common average. 

%first set up defaults
xtp_build_environment; %needed for headbox information, key that it makes its variables global and so do other codes that use them.
% %below lines are to ensure that these parameters can be used especially the
% %headboxes
% global XTP_GLOBAL_PARAMS XTP_CHRONUX_PARAMS XTP_PCA_PARAMS XTP_HEADBOXES XTP_HB_MONTAGES XTP_COHERENCY_PAIRS XTP_CONVERSION_FACTORS XTP_ENVIRONMENT_VERSION XTP_PLOT_LOCATIONS
params.readXLTfile = 1;
params.cutSnippets = 1;
params.units = 'uV';
params.montageData=0;
params.applyHPF=0;
params.applyNotchFilter=0;
params.applyLPF=0;
params.interactive=1;%to choose the headbox number within xtp_readXLTfileWithPhotic

savename=input('Savename: ','s');

%then pull in the epoch txt file
if strcmpi(input('Use txt file from Excel with epochs (y / return cuts automatically)?: ','s'),'y')
    epochList=xtp_readEpochs;%7/6/12 found when making on mac, do as RTF (default) then save as plain text, don't edit plain text since might encode wrong
else
    epochList=0;
end

% the following will allow you to select all of the files to be cut at
% once
[filenames, pathname] = uigetfile('*.txt', 'Select files to preprocess','MultiSelect','on');

rm60=input('Remove line noise? (1/0) [0]: ');
if isempty(rm60)
    rm60=0;
end

if ~iscell(filenames) %since designed to run on many at once need to convert to cell if only one chosen
    filename{1}=filenames;
    clear filenames;
    filenames=filename;
end
numfiles = size(filenames, 2);

%this will read in and cut all the files and save the exports as
%filename.cut. Needs to be run on multiple exported text files.
for i = 1:numfiles
    if i>1 %added 7/6/12 so doesn't ask each time for headbox ID
        disp('More than one file. Assuming all have same headbox');
       params.headboxID=fullXLTEK(1).metadata.headbox.headboxID;
       params.interactive=0;%since headbox now set
    end
    
    fullXLTEK(i)=xtp_readXLTfileWithPhotic(fullfile(pathname,filenames{i}),params); %reads in data and assigns headbox
    
    if ~iscell(epochList) %if no excel epochs used, use first photic to cut start or if no photic then leave as is
        onTimes=find(strcmpi(fullXLTEK(i).data{3},'ON'));%times when photic is on
        if isempty(onTimes) %if no photic, just start with beginning, though may want to modify to start at next beginning
            onTimes=1;
            beforeInPts=0;
        else
            beforeInPts=input('Using first event (photic) to cut. Number of secs before event to start: [0]')*fullXLTEK(1).metadata.srate;
            if isempty(beforeInPts)
                beforeInPts=0;
            end
        end
        for jk=1:3
            fullXLTEK(i).data{jk}=fullXLTEK(i).data{jk}(onTimes(1)-beforeInPts:end,:);
        end
        fullXLTEK(i).photic{1}=strcmpi(fullXLTEK(i).data{3},'ON');
        fullXLTEK(i).time=fullXLTEK(i).data(1);%save time info which would be nice to plot (new as of 5/2/11)
        fullXLTEK(i).data=fullXLTEK(i).data(2);%get rid of other two columns (as I think cutSnippets does)
        fullXLTEK(i).data{1}=fullXLTEK(i).data{1}.*1000;%should work to convert to uV
        fullXLTEK(i).metadata.units='uV';
        cutXLTEK=fullXLTEK;
    else %cut and concatenate all data chosen by epoch file. Assumes won't use 'photic' event markers later to cut
        cutXLTEK(i)=xtp_cutSnippetsWithPhotic(fullXLTEK(i),epochList,params); %converts units mV to uV and cuts data
    end
    % filevar{i} = cat(2,filenames{i}(1:end-4), '_cut');
    % megavar.(filevar{i}) = xtp_readXLTfile([pathname filenames{i}], params);
    % command = cat(2, filevar{i}, ' = xtp_cutSnippets(megavar.', filevar{i}, ', epochList, params)');
    % eval(command);
end

%aggregate the cutXLTEKs together
%though concern is what if each one is a separate experiment and want to
%analyze them separately. Need to give user the option to combine or
%separate them. Could be done later in the import command but keep them
%separate here. For now save here and then aggregate in crxtoeeglabcut
clear XTP*
% save([savename 'xtp_cut'],'cutXLTEK');

%%
%7/5/12 reorder them to be in time order in case epochs from differnet
%files. Problem is that the order is how they were chosen, not the actual
%time order.
%To do this code need to access a nested structure but these can't be put
%into an array directly. Need to move them up to a higher level first
cutXLTEKtemp=[cutXLTEK.metadata];%moving the metadata to a higher level so can access start time
[epochStartTimes timeorderi]=sort({cutXLTEKtemp.start});%get the sort order by sort time
epochEndTimes=sort({cutXLTEKtemp.end});

%[] likely will use timeorderi to sort the data below


%%
%first need to concatenate if multiple text files. Combine them as if it
%was one .txt file but multiple epochs within it. More concatenation below
cutData=cutXLTEK(1);%this gives all the metadata as well as the data of the first one
%which may have multiple cuts that each appear as a cell
if length(cutXLTEK)>1 %if more than one xltek .txt file imported and cut from
    for cd=2:length(cutXLTEK)
        cutData.data=[cutData.data cutXLTEK(cd).data];%each one is a cell and they get stacked next to each other
    end
end

%%
%reorder the data to be in time order if there were multiple snippets
cutData.data=cutData.data(timeorderi);

%%
%here need to concatenate if epoch list pulled multiple snippets out of 
%individual .txt files or if multiple .txt files were combined in previous
%step. The lines below ensure all the same length and remove line noise for
%data using epoch list only (line noise removed otherwise below).
if size(cutData.data,2)>1%cutData.data is a cell so iF multiple snippets, then more then one cell. Below will cut out of data, based on .xls epoch list.
   
    ns=length(cutData.data);%for each snippet
    freqRecorded=cutData.metadata(1).srate;
    %     cutLengthInSecs=input('Cut length (in secs) for data for analysis [3]?');
    %     if isempty(cutLengthInSecs)
    %         cutLengthInSecs=3;
    %     end
    %     CL=cutLengthInSecs*freqRecorded;
    
    params.fpass=[55 65];
    params.pad=4;
    params.Fs=freqRecorded;
    for il=1:ns%Determine shortest snippet length in case of different sizes
        snippetlength(il)=size(cutData.data{il},1);
    end
    data=[];
    for ir=1:ns %for each snippet
        if rm60 %if chosen to remove 60 Hz line noise
            params.tapers=[1 floor(size(cutData.data{ir},1)/freqRecorded) 1];
            cutData.data{ir}=rmlinesc(cutData.data{ir}(1:min(snippetlength),:),params,0.2,'n',60);
            %         %cut data to all same length
            
            %          if size(cutData.data{ir},1)>=CL %CL is cut length in samples; should skip if shorter than cutlength
            %                 numCuts=floor(size(cutData.data{ir},1)/CL);
            %                 for nc=1:numCuts
            %                     numCol=size(data,2); %to get current size of eegData to add on to it (eegData is channel x data)
            %                     data(:,numCol+1:numCol+CL)=cutData.data{ir}(((nc-1)*CL)+1:nc*CL,:)'; %transposes and adds on to previous and removes line noise
            %                 end
            %          end
        else %if no line removal, to ensure all equal snippet lengths
            cutData.data{ir}=cutData.data{ir}(1:min(snippetlength),:);
        end
    end
    data=cell2mat(cutData.data')';%Concantenate
    denoised=1;
    minSnippetLength=min(snippetlength);%used to define the length of each epoch when brought into EEGLAB
else%One continuous data (either from .xls epoch list or directly from XLTek), remove line noise later
    data=cutData.data{1}';
    minSnippetLength=0;
    denoised=0;
end
%%
%
channelList=cutData.metadata(1).headbox.labels;%changed from below 3/17 based on code modificationin xtp_readXLTEfileWithPhotic

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

%here convert and save the data

photic.latency=find(cutData.photic{1});%find produces the indeces where xtpdata.photic{p}==1 (actually, ~=0). Use for eeglab latency info.
%if no photic, then is empty and need to set later code to not cut
%further.

%     data=cutData.data{p};%note only one snippet at a time
data(removelist,:)=[]; %to remove the channels chosen above
freqRecorded=cutData.metadata(1).srate;
%     if length(cutData.data)==1
%     snippetSaveName=[savename '_eegLabFormat'];%since only one file
%     else
%         snippetSaveName=[savename '_' num2str(p) '_eegLabFormat'];%so saves each snippet as a separate file
%     end


%%
%downsample and remove line noise
if freqRecorded==1024
    if strcmpi(input('Data recorded at 1024. Downsample to 256? (y/n) [y]: ','s'),'n');
        
        
        %remove line noise (+/- resample) one segment at a time
        %data come in organized as data x channel
    else
        data=resample(data',1,4)';
        freqRecorded=256;
    end
end
if ~denoised && rm60 %for continuous data, since xtp epoched data denoised above
    params.fpass=[55 65];
    params.pad=4;
    params.tapers=[1 10 1];%tapers(2) determines how much data is used (based on rmlinesc)
    cL=params.tapers(2)*freqRecorded; %chop length for rmlinesc only, in units of data
    params.Fs=freqRecorded;
    
    %may need to add a line to cut data up
    eegData=zeros(floor(size(data,2)/cL)*cL,size(data,1))';
    fprintf('Running rmlinesc, cutting off last %.0f seconds\n',((size(data,2)-size(eegData,2))/freqRecorded));
    for jk=floor(1:size(data,2)/cL) %use only as much data as is divisible by tapers(2). End bit gets cut off
        eegData(:,(jk-1)*cL+1:jk*cL)=rmlinesc(data(:,(jk-1)*cL+1:jk*cL)',params,0.2,'n',60)';%transpose for eeglab
    end
    
else
    eegData=data;
end


%%
%reorder Channels to be like regular order
headboxID=cutData.metadata(1).headbox.headboxID;
switch headboxID
    case {8, 10} %for EMU40 +18 with 37 channels
        ChannelOrder={'FPz','Fp1','Fp2','AF7','AF8','F7','F3','F1','Fz','F2','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CPz','CP2','CP6','T5','P3','Pz','P4','T6','PO7','O1','POz','Oz','O2','PO8'};
    case 1 %for 29 channels from Mobee used early 2009
        if length(channelList)==29
            ChannelOrder={'Fp1','Fp2','AF7','AF8','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CP2','CP6','T5','P3','Pz','P4','T6','O1','O2'};
        elseif length(channelList)==30 %added 1/5/12 since FPz is supposed to be there, though notes state that N1 had FPz as EKG
            ChannelOrder={'FPz','Fp1','Fp2','AF7','AF8','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CP2','CP6','T5','P3','Pz','P4','T6','O1','O2'};
        elseif length(channelList)==19 %added 1/6/12 since in 2008, no FPz and no use of X1-X10.
            ChannelOrder={'Fp1','Fp2','F7','F3','Fz','F4','F8','T3','C3','Cz','C4','T4','T5','P3','Pz','P4','T6','O1','O2'};
        end
    case 9 %for 35 channels, F1 and F2 removed from EMU 40 (used on normal 6 and some patients in 2010)
        ChannelOrder={'FPz','Fp1','Fp2','AF7','AF8','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CPz','CP2','CP6','T5','P3','Pz','P4','T6','PO7','O1','POz','Oz','O2','PO8'};
    case 13 %for 35 channels with AF7 and AF8 removed from EMU 40 (used on IN390)
        ChannelOrder={'FPz','Fp1','Fp2','F7','F3','F1','Fz','F2','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CPz','CP2','CP6','T5','P3','Pz','P4','T6','PO7','O1','POz','Oz','O2','PO8'};
    otherwise
        fprintf('Unable to match number of channels with channel list for reordering')
        eegDataReordered=eegData;
        ChannelOrder=channelList;
end

if ~exist('eegDataReordered','var')
    eegDataReordered=zeros(size(eegData));
    for io=1:length(ChannelOrder)
        orderIndex = strcmpi(ChannelOrder{io},channelList); %gives a logical vector
        if ~sum(orderIndex)
            fprintf('Channel %s removed, and not in default channel list. Aborting...\n',ChannelOrder{io});
            return
        end
        eegDataReordered(io,:)=eegData(orderIndex',:);
        %         chanlocs(io).labels=channelList{orderIndex};
    end;
    
    %fprintf('%s created\n',snippetSaveName);
    %save ([savename '_eegLabFormat'],'eegDataReordered','freqRecorded','ChannelOrder','photic','headboxID','minSnippetLength');
end

detrended=0;
if strcmpi(input('1Hz filter (for ICA) or detrend? (1/d)[1]: ','s'),'d')
    detrended=1;
    eegDataReordered=detrend(eegDataReordered')';%transpose then transpose back
end

%create a chanlocs structure using JVs code and the channel order (no
%channel order saved in older files so need to create it, assuming this
%code otherwise works on older files).
% opts=eegp_defopts_eeglablocs;
% if ~isfield(eeglabFile,'ChannelOrder')
%     switch size(eegDataReordered,1)
%         case 29
%             ChannelOrder={'Fp1','Fp2','AF7','AF8','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CP2','CP6','T5','P3','Pz','P4','T6','O1','O2'};
%         case 37
%             ChannelOrder={'FPz','Fp1','Fp2','AF7','AF8','F7','F3','F1','Fz','F2','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CPz','CP2','CP6','T5','P3','Pz','P4','T6','PO7','O1','POz','Oz','O2','PO8'};
%         case 35
%             if ~strcmpi(input('35 channels. Is this headbox 9 (no F1,F2)? (y/n)[y]: ','s'),'n')
%                 ChannelOrder={'FPz','Fp1','Fp2','AF7','AF8','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CPz','CP2','CP6','T5','P3','Pz','P4','T6','PO7','O1','POz','Oz','O2','PO8'};
%             else
%                 disp('need to add in correct channel order to code or redo with xltekToEeglabNew');
%                 return
%             end
%         otherwise
%             disp('need to add in correct channel order to code or redo with xltekToEeglabNew');
%             return
%     end
% end

%create a chanlocs structure using JVs code and the channel order (no
%channel order saved in older files so need to create it, assuming this
%code otherwise works on older files).
%7/6/12 removed two lines below since no longer using
%eegp_defopts_eeglablocs;
% opts=eegp_defopts_eeglablocs;% ensures usage of newer channel location file.
% chanlocVariable=eegp_makechanlocs(char(ChannelOrder),opts);


chanlocVariable=eegp_makechanlocs(char(ChannelOrder));

%% added 3/7/13 since I didn't remove all the non EEG channels and it didn't crash, but didn't have a chanlocs Variable in the output
if length(chanlocVariable)~=size(eegDataReordered,1)%if extra channels in the data
    disp('There are non-EEG channels and no chanlocs variable will be created');
    if input('Abort to remove more next time? (1/0) [0]')
        return
    end
end

%%
%Create EEGlab file
if minSnippetLength==0 % if continuous data
    EEG = pop_importdata('dataformat','array','data',eegDataReordered,...
        'setname',savename,'srate',freqRecorded,'subject','1','xmin',0,'nbchan',size(eegDataReordered,1),'chanlocs',chanlocVariable);
else%if data came in as multiple snippets with .xls sheet
    EEG = pop_importdata('dataformat','array','data',eegDataReordered,...
        'setname',savename,'srate',freqRecorded,'subject','1','pnts',minSnippetLength,'xmin',0,'nbchan',size(eegDataReordered,1),'chanlocs',chanlocVariable);
end
EEG = eeg_checkset( EEG );
if strcmpi(input('Rereference to common average? (y/n)[n]','s'),'y')
    EEG = pop_reref( EEG, []); %rereferences to common average reference for visualization
end
% EEG = eeg_checkset( EEG );


if ~detrended %if not detrended
    disp('Applying 1Hz LPF');
    EEG = pop_iirfilt( EEG, 1, 0, [], [0]); %this does a 1Hz HPF
else
    disp('1 hz filter off');
end

%12/11/11 add in start and end time of the file, though only if
%one cut. 
EEG.start=[];
EEG.end=[];
epochStartTimes=[];
epochEndTimes=[];
if length(cutXLTEK)==1 && length(cutXLTEK.data)==1 %if only one .txt file and one cut in that file
    EEG.start=cutXLTEK(1).metadata.start;
    EEG.end=cutXLTEK(1).metadata.end; %note this time isn't actually in the data but is the datapoint just afterwards (see xtp_cutSnippetsWithPhotic)
else
    EEG.epochStartTimes=epochStartTimes;
    EEG.epochEndTimes=epochEndTimes;
end

%7/6/12 If multiple cuts (from one or multiple xltek files)


EEG = eeg_checkset( EEG );
savename=[savename '.set'];
if exist(savename,'file')==2 %if this file already exists, don't want to over write since can lose ICA weights, instead allow user to exist without saving
    if ~strcmpi(input('Eeglab file of same name already in path, overwrite? (y or Return to change name): ','s'),'y')
        savename=input('New save name: ','s');
        savename=[savename '.set'];
    end
end

%%
%Checking for photic markers. User gets option to label them.
if isempty(photic.latency) %if no photic events then just save here
    disp('No events (photic) in the file. Can add later with AddEeglabEvents and then run cutEeglab to epoch');
    EEG = pop_saveset( EEG, 'filename',savename);%saves in current path, can add 'pathname' to save in path of file
    return %need to end since no events for remainder of code.
    
else %want to label events here before saving
    %Looking for all the event markers in the dataset
    if strcmpi(input('\n Add event labels from existing mat file (y/return - type in manually)?: ','s'),'y');
        
        [latencyFilename latpathname]=uigetfile('*Latencies.mat','Choose file containing a cell called eventNames');
        load(fullfile(latpathname,latencyFilename),'eventNames');
        fprintf('Number of photic markers found in this dataset = %d \n', length(photic.latency));
        %     fprintf('All event names in this file: \n');
        Enum=length(eventNames);%eventNames is structure in Latencies file.
        %     for a=1:Enum
        %         fprintf('Event Name %d : %s \n', a, EEG.event(a).type);
        %     end
    else %if want to type in manually the event names such as if there are only 2 and want to repeat
        fprintf('Number of photic markers found in this dataset = %d \n', length(photic.latency));
        Enum=input('\nEnter number of different event types in this dataset:  ');
        if mod(length(photic.latency),Enum) %if extra events (added 11/28/12)
            disp('Extra events in dataset (not divisible by number of event types');
            if strcmpi(input('Remove first (f) or last (l) event [f]: ','s'),'l')
                photic.latency=photic.latency(1:end-1);%remove last
            else
                photic.latency=photic.latency(2:end);%remove first
            end
        end
            
        for tnum=1:Enum
            fprintf('For Event No. %d ', tnum);
            eventP=input('enter event label: ','s');
            eventNum{tnum}=eventP;
            eventNum=eventNum';
        end
        fprintf('....Assuming these %d event labels repeat consecutively in the same order....\n',Enum)
        eventNum=repmat(eventNum, length(photic.latency)/Enum, 1);
        eventNames=eventNum;
    end
    
    %here actually add the events to the EEG structure
    %(AMG - moved this out since same for both versions)
    if ~length(eventNames)==length(photic.latency)
        disp('wrong number of event names for number of events (photic). Add events later with AddEeglabevents');
    else
        
        %     e=length(EEG.event);%in case there already are events in place so not to overwrite
        for ii=1:length(photic.latency)
            EEG.event(ii).latency=photic.latency(ii);
            EEG.event(ii).type=eventNames{ii};
        end
    end
    EEG = pop_saveset( EEG, 'filename',savename,'filepath',pwd);
end
cutEeglab(EEG);%Further epoching
end




