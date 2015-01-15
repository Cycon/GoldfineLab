function newSetFromEvent

%to create a new set file by cutting out entire period of time of a certain
%event (created by AddEeglabEvents). Issue is that the period of time will
%have varied length so needs to cut to shortest length or set a minimum
%length to cut to.
%
%created 5/28/12 AMG
%
%ToDO:
%[] give option to use end time for events that have durations to them
%[] consider making it an option of cutEeglab

%%
path=uipickfiles('type',{'*.set','.set'},'prompt','Pick a continuous .set file with events','output','char');
[pathname filename]=fileparts(path);
eeg=pop_loadset(path);

if ndims(eeg.data)==3
    disp('Only for continuous datasets');
    return
end

appendName=input('Text to append for savename: ','s');
%%
%display event types on the screen
fprintf('Event types in this dataset are: \n');
uniqueEvents=unique({eeg.event.type});
for c=1:length(uniqueEvents)
    fprintf('%.0f. %s\n',c,uniqueEvents{c})
end
% fprintf('%s\n',uniqueEvents{:});

eventNum=input('Event type(s) to keep (use index; put multiple in [ ]): ');

% eventString=input('String to look for in event names (cap doesn''t matter): ','s');

% eventOnsets=strfind(lower({eeg.event.type}),eventString);%look for that string in the event names, can occur anywhere in the name

%%
%first pull out the full range of data between the event markers
n=0;%index for number of epochs chosen 
disp('Seconds after each chosen event: ');
eventData=cell(1,length(eeg.event));
%go through all events each time for each chosen event type
for a=eventNum %for each chosen event type
    for d=1:length(eeg.event) %for each event in the original dataset
        if sum(strcmp(uniqueEvents{a},eeg.event(d).type)) %if a match
            n=n+1;%for event output number
            if d~=length(eeg.event) %the final one is different
                eventData{n}=eeg.data(:,ceil(eeg.event(d).latency):ceil(eeg.event(d+1).latency));%gave error without floor, not sure why
            else %if final one
                eventData{n}=eeg.data(:,ceil(eeg.event(d).latency):end);
            end
        fprintf('%.0f. %.2f\n',n,size(eventData{n},2)/eeg.srate);
        
        end
    end  
end

%remove excess eventData since was initialized too big
eventData(n+1:end)=[];%remove since don't need

%display event lengths to pick which to use as lowest one
CL=input('Choose cut length (in sec) for outputs: ');

%cut out data not divisible by cutlength
dataOut=[];
for b=1:n %for each output event as a cell, transpose up to where divisible by cutlength
    dataOut=[dataOut eventData{b}(:,1:size(eventData{b},2)-mod(size(eventData{b},2),CL*eeg.srate))];%add on up to where divisible by cut length
end

%%
%cut all data to the same length by reshaping
EEGOUT = pop_importdata('setname',[filename '_' appendName '_' num2str(CL)],...
    'data',reshape(dataOut,size(dataOut,1),CL*eeg.srate,[]),'chanlocs',eeg.chanlocs,'nbchan',eeg.nbchan,'srate',eeg.srate,...
    'ref',eeg.ref);

EEGOUT=pop_saveset(EEGOUT,'filename',[filename '_' appendName '_' num2str(CL)],'savemode','onefile');    %save as a .set file for analysis
