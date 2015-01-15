function ERDEeglab

%calculate power on set intervals of an EEGLAB dataset(s) with one being
%baseline. Then subtract the baseline off (need to figure out if subtract
%before or after logging it). Then average together the differences across
%trials. Then plot and topoplot the difference images.
%
%This code doesn't actually run all the way through. Meant to run in parts.

%%
%
savename=input('Savename: ','s');

    


%%
%load files
setfiles=uipickfiles('type',{'*.set','.set'},'prompt','Pick .set file(s)');

for s=1:length(setfiles)
    [path{s} setname{s}]=fileparts(setfiles{s});
    EEG(s)=pop_loadset('filename',setfiles{s});
end

channelsCell=struct2cell(EEG(1).chanlocs);
chan=squeeze(channelsCell(1,1,:));%names of channels in a cell array

%%
%Laplacian montage
if (input('Convert data to Laplacian (1/0) [0]?: '))
    lap=1;
else
    lap=0;
end

%%
%figure out if multiple event types and which one to do comparison around
eventTypes=unique({EEG.event.type});
if length(eventTypes)>1
    disp('Multiple event types present.');
    for et=1:length(eventTypes)
        fprintf('%.0f. %s\n',et,eventTypes{et});
    end
    eventUse=eventTypes{input('Which one would you like to use (type number)? ')};
else
    eventUse=eventTypes{1};%if only one event type
end



%%
%input ranges for baseline and task. Put in same variable for easier
%indexing
range(1,:)=input('Time range for baseline e.g. [-.5 0]: ');
range(2,:)=input('Time range for task e.g. [1 1.5]: ');
if diff(range(2,:))~=diff(range(1,:))
    disp('Warning, base and task ranges aren''t equal');
end

%%
%for testing
range=[-.5 0;1 1.5];

%%
%cut out sections for baseline and task for event chosen.
%Use reshape to make 2D matrix so that EEG.event.latency has meaning. Need
%to do for each EEG file and concatenate them (though would be nice to do
%both for individual and all combined). Each trial is a "page".
for ee=1:length(EEG)
    data=reshape(EEG(ee).data,size(EEG.data,1),[]);%make 2D matrix
    if lap
        data=MakeLaplacian(data,EEG.chanlocs);
    end
    eventLat=[EEG(ee).event(strcmpi({EEG(ee).event.type},eventUse)).latency];
    baseEEG(ee).data=zeros(size(EEG(ee).data,1),diff(range(1,:))*EEG(ee).srate,length(eventLat));
    taskEEG(ee).data=zeros(size(EEG(ee).data,1),diff(range(2,:))*EEG(ee).srate,length(eventLat));
    for el=1:length(eventLat) %since can't figure out multiple range indexing
        baseEEG(ee).data(:,:,el)=data(:,eventLat(el)+range(1,1)*EEG(ee).srate:eventLat(el)+range(1,2)*EEG(ee).srate-1);
        taskEEG(ee).data(:,:,el)=data(:,eventLat(el)+range(2,1)*EEG(ee).srate:eventLat(el)+range(2,2)*EEG(ee).srate-1);
    end
end

%%
%calculate spectrum on each trial (page of the data) but keep separate for
%block at this point. The output here is the average of the difference in
%power so can use the power at the end.
params.pad=-1;
%no error bars since not sure what to do with them and complicated matrix
%output
params.trialave=0;
params.Fs=EEG(1).srate;
%minimum frequency resolution (with 1 taper) is 2/data length
minFR=2/min(diff(range(2,:)),diff(range(1,:)));
FR=input(sprintf('Frequency resolution? (minimum and default is %.2f Hz): ',minFR));
if isempty(FR)
    FR=minFR;
end


for eg=1:length(EEG) %for each block if bring in multiple blocks
    params.tapers=[FR/2 diff(range(1,:)) 1];
    for c=1:size(baseEEG(eg).data,1) %for each channel where output is freq x trial x channel)
        [baseEEG(eg).S(c,:,:) baseEEG(eg).f]=mtspectrumc(squeeze(baseEEG(eg).data(c,:,:)),params);
        params.tapers(2)=diff(range(2,:));
        [taskEEG(eg).S(c,:,:) taskEEG(eg).f]=mtspectrumc(squeeze(taskEEG(eg).data(c,:,:)),params);
    end
    diffEEG{eg}=log10(taskEEG(eg).S)-log10(baseEEG(eg).S);%difference of log power
end

%%
%to see the spectra
figure;
plotf=[2 35];
pfr=baseEEG(1).f>plotf(1) & baseEEG(1).f<plotf(2);
SrivasList=[6    7   13   29   30   31   35   36   37   41   42   54   55   79 80   87   93  103  104  105  106  110  111  112  129];

for j=1:length(SrivasList)
subplot(5,5,j)
plot(baseEEG(1).f(pfr),10*log10(squeeze(mean(baseEEG.S(SrivasList(j),pfr,:),3))));
hold on;
plot(baseEEG(1).f(pfr),10*log10(squeeze(mean(taskEEG.S(SrivasList(j),pfr,:),3))),'r');
axis tight
title(chan(SrivasList(j)));
end

%%
%save output. Don't forget to use eventUse in the name. Save differences
%for each block. Then in plotting code can plot the average differences for
%each run and overall

% save([savename '_Diff.mat'],'params','actualDiff','f','f_pvalue','freqRecorded','p_value','ChannelList')
%[] consider just save in diff format so can run plotDifference plotting
%code

%%
%temporary code: plot each run and overall difference with topoplot. 
plotf=[2 35];
pfr=baseEEG(1).f>plotf(1) & baseEEG(1).f<plotf(2);
SrivasList=[6    7   13   29   30   31   35   36   37   41   42   54   55   79 80   87   93  103  104  105  106  110  111  112  129];
figure;
for j=1:length(SrivasList)
    subplot(5,5,j)
    plot(baseEEG(1).f(pfr),squeeze(mean(diffEEG{1}(SrivasList(j),pfr,:),3)));
    axis tight;
end

%%
%this below is temporary
plotf=[7 9;8 10;9 11;10 12;11 13;12 14;13 15;14 16;15 17;16 18];
chanlocVariable = pop_readlocs('GSN-HydroCel-129.sfp');%12/19/11
chanlocVariable(1:3)=[];%because first 3 aren't used apparently.
figure;
for pf=1:size(plotf,1)
    subplot(4,3,pf);
    pfr=baseEEG(1).f>plotf(pf,1) & baseEEG(1).f<plotf(pf,2);
    topoplot(mean(diffEEG{1}(:,pfr,:),3),chanlocVariable);
    colorbar 
    title(num2str(plotf(pf,:)));
end
