function cutEeglabBat
%12/14/11 AMG runs the first part of cutEeglab on multiple files (cuts around markers
%but not into smaller pieces)
%2/1/12 version 2 modify to allow cutting of a variety of types, automatically
%cutting from each event type and autocreating the save name. Can run on
%multiple files at once too.
%

fprintf('Code designed to cut multiple .set files and automatically name them');

    setFileName=uipickfiles('type',{'*.set','.set file'},'prompt','Pick EEGLAB .set file(s)');
    
%     [setFileName setpathname]=uigetfile('*.set','Choose .set file');
    % If not called by xltekToEeglab, load dataset(.set) into workspace
    if isnumeric(setFileName) || isempty(setFileName) %if none chosen
        return
    end
    
    if length(setFileName)>1
        disp('Multiple selected, assuming they have the same event types');
    end
    
        fprintf('\nNote: Each event marker is set at time = 0 sec by default.\n To analyze segments 1 sec before and 2 sec after each event, t = [-1 2]\n');
        %If cutting before event marker, choose t<0
        it=input('\nStart time(s) (as [ ] if multiple): ');
        duration=input('Enter duration of cuts: ');
        ft=it+duration;
        %Creating list with different event types found in structure.
        
        for ed=1:length(setFileName)
             EEG=pop_loadset(setFileName{ed});
            [~,origName]=fileparts(setFileName{ed});
            if isempty(EEG.event)
                fprintf('\nNo event markers in %s.',origName);
            else
                UniqueEvents=unique({EEG.event.type});
                for ee=1:length(UniqueEvents)% for each event type
                    for ef=1:length(it) %for each cut
                        %below asks if the start time is less than the
                        %first event from the beginning or if the end time
                        %in sampls is greater than the total number of
                        %samples in the data
                        if it(ef) < -EEG.event(1).latency/EEG.srate || ft(ef)*EEG.srate+EEG.event(end).latency>size(EEG.data,2)*size(EEG.data,3)
                            fprintf('Start time of %g is outside of range available\n',it(ef));
                        else%if the event is outside the range available
                        savename=[origName '_' UniqueEvents{ee} num2str(it(ef)) 'to' num2str(ft(ef))];
                        savename(savename=='.')='p';%since can't have . in a filename
                        EEG_ep=pop_epoch(EEG,UniqueEvents(ee),[it(ef) ft(ef)],'newname',savename,'epochinfo','yes');
    %                     fprintf('Epoching events labeled %s \n',UniqueEvents{pickEpoch});                 
    %                     EEG_ep.setname=savename{more};
                        EEG_ep=pop_saveset(EEG_ep,'filename',savename);
                        clear EEG_ep; 
                        end
                    end

                end
            end
        end
end



