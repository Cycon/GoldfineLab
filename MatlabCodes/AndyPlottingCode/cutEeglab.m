function cutEeglab(EEG)
%cutEeglab further cuts epoched or un-epoched data into smaller
%snippets of equal size in eeglab. If the entire data cannot be cut
%perfectly into the specified cut length, the residue is eliminated
%from the modified dataset.
%Can be used for cutting data repeatedly into smaller segments and
%save them separately as .set. The original .set file that is used, is left
%unedited.
%
%Can combine together cuts from multiple event types or sequentially cut
%same range around multiple event types. Needs to be run again if want to
%cut a different range.
%
%Input filetype: .set
%Output filetype: .set
%
%Uses:
%
%For un-epoched data
%Further cut data into smaller snippets for viewing and artifact rejection in eeglab
%
%For data epoched using excel sheet (without event markers)
%Further cut data into smaller snippets for vieweing and artifact rejection in eeglab
%
%For data epoched with event markers (photic)
%Pull out event type(s) and group them together. Choose segments around the
%event type, and pool them into new dataset.
%Furher cut into smaller snippets for viewing and artifact rejection in eeglab
%
%Function is also called by xltekToEeglab.
%
%DThengone - 8/12/11

%9/1/11 AG added creation of EEG.epoch if events exist and epoching (cutting up) dataset
%11/27/11 AG version 2 now it saves with the same file name but an addendum
%rather than asking you for a whole new savename. Also change to
%uipickfiles. Also changed save 'version' to '7.3' (large files). Also at
%end switched the order of loops so cuts all datasets with same cutlengths.
%Also changes .setname as well as the filename.
%4/5/12 fixed bug where savename not created if no events in the data.
%11/28/12 found that the field EEG_ep{1}.epoch needs to be redone when new
    %epochs are created. Not sure how to do this but gives error since not
    %accurate. Just remove it and seems to work fine. per eeg_checkset seems
    %that it's used to combine multiple EEG datasets which we don't do.

if nargin<1
    setFileName=uipickfiles('type',{'*.set','.set file'},'num',1,'prompt','Pick EEGLAB .set file');
    [path,origName]=fileparts(setFileName{1});
%     [setFileName setpathname]=uigetfile('*.set','Choose .set file');
    % If not called by xltekToEeglab, load dataset(.set) into workspace
    if isnumeric(setFileName) || isempty(setFileName) %if none chosen
        return
    end
    EEG=pop_loadset(setFileName{1});
else
    origName=EEG.setname;
end
%
% fprintf('\nNow will define epochs for new .set file(s)\n');
%
%Check to see if dataset contains photic event markers.
if isempty(EEG.event)
    fprintf('\nNo event markers (photic) in this dataset.');
    %Creating new structure EEG_ep for modification, so original stays same.
    EEG_ep{1}=EEG;
    savename{1}=origName;
else %if event markers are found in the dataset, user is given option to pick event types
    if strcmpi(input('Select event type(s) and create new .set files? (y/n) [n]','s'),'y')
        fprintf('\nNote: Each event marker is set at time = 0 sec by default.\n For eg: to analyze segments 1 sec before each event, t = -1');
        %If cutting before event marker, choose t<0
        it=input('\nEnter start time relative to event(t=0) (in sec) = ');
        ft=input('Enter end time relative to event(t=0) (in sec) = ');
        %Creating list with different event types found in structure.
        UniqueEvents=unique({EEG.event.type});
        more=1; %AG update
        while 1
            for a=1:length(UniqueEvents)
                disp('Events (ordered alphabetically:');
                fprintf('Event Type %d : %s \n', a, UniqueEvents{a});%Display the different event types found in data.
            end
            pickEpoch=getinp('event type(s) to epoch (or return if done) (put multiple in []): ', 'd', [0 length(UniqueEvents)], 0);
            if ~pickEpoch==0 %Multiple event types can be chosen for cutting
                EEG_ep{more}=pop_epoch(EEG,UniqueEvents(pickEpoch),[it ft]);
                fprintf('Epoching events labeled %s \n',UniqueEvents{pickEpoch});
                savename{more}=[origName '_' input('Type ending for this dataset name: ','s')];
                EEG_ep{more}.setname=savename{more};
                EEG_ep{more}=pop_saveset(EEG_ep{more},'filename',savename{more});
                more=more+1; %AG update
            else % pickEpoch==0
                break %Original data stays as is, and breaks out of loop.
            end
            %savename here added 11/27 to ensure version without cutting
            %below
           
        end %while
    else
        EEG_ep{1}=EEG;
        savename{1}=origName;
    end
end
%User gets option to specify snippetlength to cut data into smaller snippets using reshape.
%If snippet length is not a factor of the data, residue at the end of data is eliminated.
if ~strcmpi(input('\nCut the dataset(s) into smaller snippets (y/n) [y]?: ','s'),'n');
    for dat=1:length(EEG_ep)
    
        cutLengthInSecs=input('cut length (sec) [3]: ');
        if isempty(cutLengthInSecs)
            cutLengthInSecs=3; %default length
        end
        CL=cutLengthInSecs*EEG_ep{dat}.srate;
        %Checking to see if data length is divisible by the cut length. If
        %not, the residue is deleted from the end of data.
        if mod(size(EEG_ep{dat}.data,2),CL)>0
            EEG_ep{dat}.data(:,floor(size(EEG_ep{dat}.data,2)/CL)*CL+1:end,:)=[];
            fprintf('Removing last %s seconds\n',((size(EEG_ep{dat}.data,2)/CL)*CL+1)/EEG_ep{dat}.srate)
        end
        %If error in reshape code, check to make sure the matrices have the
        %same number of elements.
        EEG_ep{dat}.data=reshape(EEG_ep{dat}.data,size(EEG_ep{dat}.data,1),CL,[]);
        EEG_ep{dat}.pnts=CL;
        EEG_ep{dat}.trials=cutLengthInSecs*EEG_ep{dat}.trials;
        EEG_ep{dat}.xmin=0; %ensure starts at 0
        %Next line checks if EEG.times has values in it. Empty EEG.times
        %implies un-epoched data.
        if isempty(EEG.times)
            EEG_ep{dat}.xmax=EEG.xmax;
        else
            %In epoched data, EEG.times is a nonempty variable. So define
            %xmax and times from these fields.
            EEG_ep{dat}.xmax=CL-(EEG_ep{dat}.times(2)-EEG_ep{dat}.times(1));
            EEG_ep{dat}.times=[0:(EEG_ep{dat}.times(2)-EEG_ep{dat}.times(1)):CL];
        end
        %save the newly cut data as .set file. The original is left
        %unedited.
        
        %9/1/11 added to create an EEG.event.epoch field if events exist
        if ~isempty(EEG_ep{dat}.event) %if events exist
            for ev=1:length(EEG.event)
                EEG_ep{dat}.event(ev).epoch=ceil(EEG_ep{dat}.event(ev).latency/size(EEG_ep{dat}.data,2));%use ceil otherwise first epoch is called 0 but starts at 1
            end
        end
        
        EEG_ep{dat}.setname=[savename{dat} '_' num2str(cutLengthInSecs)];
        
        EEG_ep{dat}.epoch=[];%added 11/28/12
                
        EEG_ep{dat}=pop_saveset(EEG_ep{dat},'filename',EEG_ep{dat}.setname,'version','7.3');
        

        
%         pop_saveset(EEG_ep{dat});
%     else %11/27/11 no longer need this since saved above
%         EEG_ep{dat}=pop_saveset(EEG_ep{dat},'filename',[savename{dat}],'version','7.3');%saving the original dataset without further epochs
    end
end
%Reminder for users.
disp('Note: Run openEeglab to view data');







