%%
function importToEeglabNew


%CHeck to see if set file has already been created, if not create one (need
%to fix to have it save with the events in it).
if ~strcmpi(input('Use existing set file (y/return to create new)?: ','s'),'y')
    [eeglabFilename, pathname] = uigetfile('*eegLabFormat.mat', 'Select converted file to import to eeglab');
    eeglabFile=load(fullfile(pathname,eeglabFilename));
    detrended=0;
    if strcmpi(input('1Hz filter (for ICA) or detrend? (1/d)[1]: ','s'),'d')
        detrended=1;
        eeglabFile.eegDataReordered=detrend(eeglabFile.eegDataReordered')';%transpose then transpose back
    end

    %create a chanlocs structure using JVs code and the channel order (no
    %channel order saved in older files so need to create it, assuming this
    %code otherwise works on older files).
    opts=eegp_defopts_eeglablocs;
    if ~isfield(eeglabFile,'ChannelOrder')
        switch size(eeglabFile.eegDataReordered,1)
            case 29
                eeglabFile.ChannelOrder={'Fp1','Fp2','AF7','AF8','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CP2','CP6','T5','P3','Pz','P4','T6','O1','O2'};
            case 37
                eeglabFile.ChannelOrder={'FPz','Fp1','Fp2','AF7','AF8','F7','F3','F1','Fz','F2','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CPz','CP2','CP6','T5','P3','Pz','P4','T6','PO7','O1','POz','Oz','O2','PO8'};
            case 35
                if ~strcmpi(input('35 channels. Is this headbox 9 (no F1,F2)? (y/n)[y]: ','s'),'n')
                    eeglabFile.ChannelOrder={'FPz','Fp1','Fp2','AF7','AF8','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CPz','CP2','CP6','T5','P3','Pz','P4','T6','PO7','O1','POz','Oz','O2','PO8'};
                else
                    disp('need to add in correct channel order to code or redo with xltekToEeglabNew');
                    return
                end
            otherwise
                disp('need to add in correct channel order to code or redo with xltekToEeglabNew');
                return
        end
    end
                
    chanlocVariable=eegp_makechanlocs(char(eeglabFile.ChannelOrder),opts);

    %%
    %import data with no epoching and rereference and filter and save
    dataname=eeglabFilename(1:end-17);
    if eeglabFile.minSnippetLength==0
        EEG = pop_importdata('dataformat','array','data',eeglabFile.eegDataReordered,...
        'setname',dataname,'srate',eeglabFile.freqRecorded,'subject','1','xmin',0,'nbchan',size(eeglabFile.eegDataReordered,1),'chanlocs',chanlocVariable);
    else
         EEG = pop_importdata('dataformat','array','data',eeglabFile.eegDataReordered,...
         'setname',dataname,'srate',eeglabFile.freqRecorded,'subject','1','pnts',eeglabFile.minSnippetLength,'xmin',0,'nbchan',size(eeglabFile.eegDataReordered,1),'chanlocs',chanlocVariable);
    end
    EEG = eeg_checkset( EEG );
    EEG = pop_reref( EEG, []); %rereferences to common average reference for visualization
    % EEG = eeg_checkset( EEG );


    if ~detrended %if not detrended
        disp('Applying 1Hz LPF');
        EEG = pop_iirfilt( EEG, 1, 0, [], [0]); %this does a 1Hz HPF
    else
        disp('1 hz filter off');
    end
    EEG = eeg_checkset( EEG );
    savename=[dataname '.set'];
    if exist(savename,'file')==2 %if this file already exists, don't want to over write since can lose ICA weights, instead allow user to exist without saving
        if ~strcmpi(input('Eeglab file of same name already in path, continue to save? (y or Return to cancel): ','s'),'y')
            return
        end
    end       
    
    if ~isfield(eeglabFile,'photic') || isempty(eeglabFile.photic.latency) %if no photic events then just save here
        disp('No events (photic) in the file. Can add later with AddEeglabEvents and then run code again to epoch');
        EEG = pop_saveset( EEG, 'filename',savename);%saves in current path, can add 'pathname' to save in path of file
        return %need to end since no events for remainder of code.
        
    else %want to add events here before saving
        %Looking for all the event markers in the dataset
        if strcmpi(input('\n Add event labels from existing mat file (y/return - type in manually)?: ','s'),'y');

            [latencyFilename latpathname]=uigetfile('*Latencies.mat','Choose file containing a cell called eventNames');
               load(fullfile(latpathname,latencyFilename),'eventNames');
            fprintf('Number of photic markers found in this dataset = %d \n', length(eeglabFile.photic.latency));
        %     fprintf('All event names in this file: \n');
             Enum=length(eventNames);
        %     for a=1:Enum
        %         fprintf('Event Name %d : %s \n', a, EEG.event(a).type);
        %     end
        else %if want to type in manually the event names such as if there are only 2 and want to repeat
            fprintf('Number of photic markers found in this dataset = %d \n', length(eeglabFile.photic.latency));
            Enum=input('\nEnter number of different event types in this dataset:  ');
            for tnum=1:Enum
                fprintf('For Event No. %d ', tnum);
                eventP=input('enter event label: ','s');
                eventNum{tnum}=eventP;
                eventNum=eventNum';
            end
            fprintf('....Assuming these %d event labels repeat consecutively in the same order....\n',Enum)
            eventNum=repmat(eventNum, length(eeglabFile.photic.latency)/Enum, 1);
            eventNames=eventNum;
        end
        
        %here actually add the events to the EEG structure
        %(AMG - moved this out since same for both versions)
        if ~length(eventNames)==length(eeglabFile.photic.latency)
            disp('wrong number of event names for number of events (photic)');
            return
        end
        e=length(EEG.event);%in case there already are events in place so not to overwrite
        for ii=1:length(eeglabFile.photic.latency)
            EEG.event(ii+e).latency=eeglabFile.photic.latency(ii);
            EEG.event(ii+e).type=eventNames{ii};
        end

        EEG = pop_saveset( EEG, 'filename',savename,'filepath',pathname);
    end

else % if set file already exists
    [setFileName setpathname]=uigetfile('*.set','Choose .set file');
    savename=setFileName;
    %load in the data
    EEG=pop_loadset(fullfile(setpathname,savename));
end

%%
%Epoch Selections and sub-epoching. Creates new set files with just the
%epochs in them.
% for a=1:Enum %for each event type
%     fprintf('Event Type %d : %s \n', a, EEG.event(a).type);
% end
% pickEpoch=1; %to initialize
% getinp('event type(s) to epoch or return if done: ', 'd', [0 Enum], 0);
disp('Now will define epochs for new .set file(s)');
it=input('\nStart time relative to event (in sec)= ');
ft=input('End time relative to event (in sec) = ');
while 1
    for a=1:Enum %display all events with a number
        fprintf('Event Type %d : %s \n', a, EEG.event(a).type);
    end
    pickEpoch=getinp('event type to epoch or (return) if done: ', 'd', [0 Enum], 0);
    if pickEpoch==0
        break
    end
    [EEG_ep]=pop_epoch(EEG,{EEG.event(pickEpoch).type},[it ft]);
    fprintf('Epoching events labeled %s \n',EEG.event(pickEpoch).type);
    
    %Further cut data into snippets using reshape command
    if ~strcmpi(input('\nCut the data into smaller snippets (y/n) [y]?: ','s'),'n');
        cutLengthInSecs=input('cut length (sec) [3]: ');
        if isempty(cutLengthInSecs)
            cutLengthInSecs=3; %default length
        end
        CL=cutLengthInSecs*EEG_ep.srate;
        EEG_ep.data=reshape(EEG_ep.data,size(EEG_ep.data,1),CL,[]);
        EEG_ep.pnts=CL;
        EEG_ep.trials=cutLengthInSecs*EEG_ep.trials;
        EEG_ep.xmin=0; %ensure starts at 0
        EEG_ep.xmax=CL-(EEG_ep.times(2)-EEG_ep.times(1));
        EEG_ep.times=[0:(EEG_ep.times(2)-EEG_ep.times(1)):CL];
        pop_saveset(EEG_ep);
%         temp=pop_saveset(EEG_ep,'filename',[savename cat(2,{EEG.event(pickEpoch).type})]); %popup for user to choose savename, would be better to automate
    else
        pop_saveset(EEG_ep);%saving the original dataset without further epochs
    end
%     subepoch_eeglab;%Calls subepoch_eeglab to further cut epochs
        
end

    
     
  