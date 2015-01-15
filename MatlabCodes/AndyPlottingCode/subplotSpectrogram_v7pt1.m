function subplotSpectrogram

%code to plot spectrograms calculated by SGeeglab. It displays event
%information that comes in from .set file or directly from
%AddEeglabEvents script. It also allows for
%display of topoplots of the same information.
%[]Add option to plot high and low bound of Serr results.
%[] Add table that displays all the event. Use MLTable so checkbox can
%highlight all the events.
%[] Add option to plot average spectrum or spectrogram around specific events (not accurate so may
%be better to do from original data within eeglab)
%
%8/1/11 version 2 add zscore option and call to topoplotSpectrogram.
%8/3 fixed an error in plotting indexing and modified zscore to be of the
%log10 S rather than of S itself. Changed t from a cell to a vector.
%
%8/4 version 3 added events (also in version 2) plus move topoplotSpectrogram to be within this code
%since will always use in concert and takes too long to send all the data
%to the other code
% 11/10/11 version 4 add option to set the clim for the spectrogram so can see more
% subtle features (previously done in quickSpectrogram). This way don't
% need to worry about cutting out artifacts [] Problem is clims aren't the
% same for all since different electrode spacing so need option in the
% graph (like sliders) to change the window and level for an individual
% graph.
%12/14 version 5 error with eventDispDo so changed to event_selected
%12/19 now topoplot works with EGI 129 and modify to use uipickfiles
%1/19/12 now does baseline subtraction. [] need to modify to run in real
%time by combining with SGeeglab! [] add baseline subtraction to topoplot
%1/22/12 changed title of topoplot so can have 1 decimal point.
%version 6 does baseline subtraction for topoplot
%4/4/12 made eventselected=[] in cases of epochs otherwise was getting an
%error. Made EventBox default empty. Also turned off dynamicdateticks if
%epochs.
%4/16/12 Allow plotting of one value per epoch to have event markers by
%converting into trials, required having SGeeglab save the frequency resolution
%in the params.FR field (new). [] also do for multiple per epoch ; [] may need a
%catch if there are epochs removed since won't be accurate (though a
%warning may suffice). Found that to get the click on events to work need
%display durations on, should fix but in future.
%[] need to overall improve code by only sending down what's necessary and
%make that easier by making things structure handles
%4/27/12 fixed bug where the continuous spectrogram wasn't putting in the
%events properly. Also learned on 4/28 that to do the text_click, need zoom
%off. Also in future if click doesn't work when overlayed on an image,
%set the image HitTest to off.
%4/28/12 version 7 set to allow for mean removed in epoched spectra
%7/6/12 removed call to eegp_defopts_eeglablocsAndy since asymmetric
%7/26/13 version 7.1 if no events won't run code to display event duration
%(was giving error before). Also now can have more topoplots since uses scrollsubplot (though colorbar overlaps and need to fix this). 

% [spectrogramFile, pathname] = uigetfile('*SG.mat', 'Select spectrogram to plot');
spectrogramFile=uipickfiles('type',{'*SG.mat','SG file'},'prompt','Select spectrogram to plot','output','char','num',1);
if isnumeric(spectrogramFile) || isempty(spectrogramFile) %if user presses cancel and it is set to 0
    return
end
[pathname filename]=fileparts(spectrogramFile);
figuretitle=[filename 'Spectrogram'];
spectrogram=load(spectrogramFile);
ChannelList=spectrogram.ChannelList;
t=spectrogram.t{1};%modified 8/3 to assume t is same for each channel so remove cell
S=spectrogram.S;
% Serr=spectrogram.Serr;
f=spectrogram.f;
params=spectrogram.params;
if isfield(spectrogram,'event') && ~isempty(spectrogram.event)
    subjEvents=spectrogram.event;
    uniqueEvents=unique({subjEvents.type});
else %in case no events
    subjEvents.type='';
    uniqueEvents='';
end
% if isfield(spectrogram,'startTime')
if ~strcmp(spectrogram.startTime,'') %in SGEeglab if no startTime just saves it as ''
    startTimeString=[];
    for tt=1:3 %for HH,MM,SS
        startTimeString=[startTimeString num2str(spectrogram.startTime(tt))];%from .set file
        if mod(length(startTimeString),2)%if missing a 0 so therefore odd length
            startTimeString=[startTimeString(1:end-1) '0' startTimeString(end)];
        end
        %     startTimeString(startTimeString==' ')=[]; %remove spaces
    end
else
    startTimeString='';
end
movingwinInSec=spectrogram.movingwinInSec;
if isfield(spectrogram,'epochLength')
    epochLength=spectrogram.epochLength;%added 4/16/12
else
    disp('No epochlength information (created before 4/16/12) so if this is an epoched file, won''t display events.');
    epochLength=0;%so won't display events
end

%%
%choose channels to plot (could also change this to pick BadChannelList
%output of plotSigFreq for channels to suppress)
listboxFigure=figure;
set(listboxFigure,'Name',[figuretitle ' Spectrogram Control'],'Units','normalized','Position',[0.05 0.1 0.3 0.9]);

detrendit=uicontrol('Parent',listboxFigure,'Style','checkbox','Units','normalized','Position',[.5 .9 .1 .1],'Value',0);
uicontrol('Style','text','String','Remove Mean','Units','normalized','FontSize',12,'Position',[.3 0.92 0.2 0.05]);
durationDisp=uicontrol('Parent',listboxFigure,'Style','checkbox','Units','normalized','Position',[.4 .55 .1 .1],'Value',1);
uicontrol('Style','text','String','Display event durations:','Units','normalized','FontSize',12,'Position',[.3 0.62 0.15 0.05]);
Listbox = uicontrol('Parent',listboxFigure,'Style', 'listbox','Units','normalized','Position', [.1 .3 .1 .6], 'String', ChannelList,'Max',length(ChannelList)-1,'Value',[]);
uicontrol('Style','text','String','Frequency Range to plot:','Units','normalized','FontSize',12,'Position',[.3 0.8 0.25 0.05]);
rangeBox1=uicontrol('Parent',listboxFigure,'Style','edit','Units','normalized','FontSize',12,'Position',[0.35 0.75 0.1 0.05],'String','4','BackgroundColor',[1 1 1]);
rangeBox2=uicontrol('Parent',listboxFigure,'Style','edit','Units','normalized','FontSize',12,'Position',[0.45 0.75 0.1 0.05],'String','24','BackgroundColor',[1 1 1]);
uicontrol('Style','text','String','+/- Clim (for mean-removed)','Units','normalized','FontSize',12,'Position',[.7 0.95 0.2 0.05]);
climRange=uicontrol('Parent',listboxFigure,'Style','edit','Units','normalized','FontSize',12,'Position',[0.75 0.9 0.1 0.05],'String','2','BackgroundColor',[1 1 1]);
uicontrol('Style','text','String','+/- Clim for SG:','Units','normalized','FontSize',12,'Position',[.65 0.8 0.25 0.05]);
rangeBoxSpec1=uicontrol('Parent',listboxFigure,'Style','edit','Units','normalized','FontSize',12,'Position',[0.65 0.75 0.1 0.05],'String','','BackgroundColor',[1 1 1]);
rangeBoxSpec2=uicontrol('Parent',listboxFigure,'Style','edit','Units','normalized','FontSize',12,'Position',[0.8 0.75 0.1 0.05],'String','','BackgroundColor',[1 1 1]);

%for topoplot
freqBox=uicontrol('Parent',listboxFigure,'Style','edit','Units','normalized','FontSize',12,'Position',[.75 .55 .1 .05],'String','12','BackgroundColor',[1 1 1]);
freqSpaceBox=uicontrol('Parent',listboxFigure,'Style','edit','Units','normalized','FontSize',12,'Position',[.85 .55 .1 .05],'String','','BackgroundColor',[1 1 1]);
uicontrol('Style','text','String','Freq to topoplot:','Units','normalized','FontSize',12,'Position',[.73 0.62 0.15 0.05]);
uicontrol('Style','text','String','+/-','Units','normalized','FontSize',12,'Position',[.9 0.62 0.05 0.05]);
spacingBox=uicontrol('Parent',listboxFigure,'Style','edit','Units','normalized','FontSize',12,'Position',[.55 .55 .1 .05],'String','1','BackgroundColor',[1 1 1]);
uicontrol('Parent',listboxFigure,'Style','text','String','Time spacing for topoplot:','Units','normalized','FontSize',12,'Position',[.5 0.62 0.2 0.05]);

uicontrol('Parent',listboxFigure,'Style','text','String','Starting time as HHMMSS:','FontSize',12,'Units','normalized','Position',[.35 .35 .2 .05]);

baseSub=uicontrol('Parent',listboxFigure,'Style','checkbox','Units','normalized','Position',[.45 .4 .1 .1],'Value',0);
uicontrol('Style','text','String','Baseline Subtract','Units','normalized','Position',[.38 .48 .2 .03]);
baseLowBox=uicontrol('Parent',listboxFigure,'Style','edit','Units','normalized','FontSize',12,'Position',[.6 .45 .1 .05],'String',num2str(t(1)),'BackgroundColor',[1 1 1]);
baseHighBox=uicontrol('Parent',listboxFigure,'Style','edit','Units','normalized','FontSize',12,'Position',[.8 .45 .1 .05],'String',num2str(t(1)+1),'BackgroundColor',[1 1 1]);

startTime=uicontrol('Parent',listboxFigure,'Style','edit','Units','normalized','FontSize',12,'Position',[.55 .35 .2 .05],'String',startTimeString,'BackgroundColor',[1 1 1]);
%lines of code below aren't good since would be better to just send down
%handles of all variables want to use so the variables don't span the codes
uicontrol('Units','normalized','Position',[.6 .25 .25 .1],'String','Topoplot','Callback',{@Topoplot_callback});
uicontrol('Units','normalized','Position',[.35 .25 .2 .1],'String','Spectrogram','Callback',{@Done_callback});

EventBox=uicontrol('Parent',listboxFigure,'Style', 'listbox','Units','normalized','Position', [.2 .05 .3 .1], 'String', uniqueEvents,'Max',length(uniqueEvents),'Value',[]);
% eventTable=axes('units','normalized','Position',[.35 .05 .4 .3]);
% cell_data=unique({event.type});%give list of types of events
% columninfo.titles={'Type'};
% columninfo.formats={'%s'};
% columninfo.weight=[1];
% columninfo.multipliers=[1];
% columninfo.isEditable=[0];%consider changing
% columninfo.isNumeric=[0];
% columninfo.withCheck=true;
% columninfo.chkLabel='Use';
% rowHeight=16;
% gFont.size=12;
% gFont.name='Helvetica';

% uicontrol('Style','text','String',figuretitle,'Position',[10 10 150 30]);
uiwait %this command seems necessary to ensure it waits to select channels and press done. it

%%
    function Done_callback(varargin)
        plottingRange(1)=str2double(get(rangeBox1,'String'));
        plottingRange(2)=str2double(get(rangeBox2,'String'));
        SGclim1=str2double(get(rangeBoxSpec1,'String'));
        SGclim2=str2double(get(rangeBoxSpec2,'String'));
        if SGclim1>SGclim2
            disp('SG clim 1 needs to be smaller than SG clim 2 so will switch.');
            [SGclim2, SGclim1]=deal(SGclim1,SGclim2);
        end
        index_selected = get(Listbox,'Value');
        if isempty(index_selected)
            disp('No channels selected');
            return
        end
        event_selected=get(EventBox,'Value');%default should be to plot all event types
        detrenddo=get(detrendit,'Value');
        durationDispdo=get(durationDisp,'Value');%to tell code below to display event duration as patches
        goodlist=ChannelList(index_selected);
        cr=str2double(get(climRange,'String'));
        st=get(startTime,'String');
        if ~isempty(st)
            if length(st)~=6
                disp('Time needs 6 digits');%could change to take 12 if need correct date, just need to change instructions below and allow for another option for definig stnum
            end
            stnum=datenum([00,00,00,str2num(st(1:2)),str2num(st(3:4)),str2num(st(5:6))]);%stnum is start time in datenum units (days from year 0)
        else
            stnum=0;
        end
        baseSubDo=get(baseSub,'Value');
        baseLow=str2double(get(baseLowBox,'String'));
        baseHigh=str2double(get(baseHighBox,'String'));
        
        uiresume
        subplotSpec(goodlist,index_selected,plottingRange,detrenddo,stnum,cr,event_selected,durationDispdo,SGclim1,SGclim2,baseSubDo,baseLow,baseHigh)
    end

%%

    function Topoplot_callback(varargin) %in future just have the callback be the code and send over the handle structure of all the uicontrols
        freq=str2double(get(freqBox,'String'));
        freqSpace=str2double(get(freqSpaceBox,'String'));
        timeSpace=str2double(get(spacingBox,'String'));
        detrenddo=get(detrendit,'Value');
        baseSubDo=get(baseSub,'Value');
        baseLow=str2double(get(baseLowBox,'String'));
        baseHigh=str2double(get(baseHighBox,'String'));
        SGclim1=str2double(get(rangeBoxSpec1,'String'));
        SGclim2=str2double(get(rangeBoxSpec2,'String'));
        if detrenddo
            St=S;%initialize
            for i=1:length(S) %for each channel
                St{i}=detrend(log10(S{i}),'constant'); %detrend to send over
            end
        elseif baseSubDo %remove baseline
            St=S; %initialize
            for i2=1:length(S)
                br=t>=baseLow & t<=baseHigh;
                if sum(br)<=1
                    disp('One or fewer time point used for baseline, won''t baseline subtract');
                    return
                end
                base=(S{i2}(br,:));
                mb=mean(base);
                St{i2}=log10(S{i2}./repmat(mb,size(S{i2},1),1));
            end
        else %default
            St=S;
        end
        cr=str2double(get(climRange,'String'));
        st=get(startTime,'String');
        if ~isempty(st)
            stnum=datenum([00,00,00,str2num(st(1:2)),str2num(st(3:4)),str2num(st(5:6))]);%stnum is start time in datenum units (days from year 0)
        else
            stnum=0;
        end
        uiresume
        %         topoplotSpectrogram(St,f{1},t,ChannelList,spectrogramFile(1:end-4),freq,spacing,detrenddo,stnum)
        topoplotSpectrogram(St,f{1},t,ChannelList,filename,freq,freqSpace,timeSpace,detrenddo,stnum,cr,baseSubDo,baseLow,baseHigh,SGclim1,SGclim2)
    end

%%
%plot with subplot command for number of channels don't forget code to
%enlarge. also may want to give user option to zoom on f (so may then
%change batSpectrogram to do all the spectra and decrease the amount you
%see here).
    function subplotSpec(goodlist,index_selected,plottingRange,detrenddo,stnum,cr,event_selected,durationDispdo,SGclim1,SGclim2,baseSubDo,baseLow,baseHigh)
        spectraFigure=figure;
        set(gcf,'Name',figuretitle);
        %commentbox is a uicontrol in the figure itself
        commentbox=uicontrol('Style','text','String','------','Units','normalized','FontSize',12,'Position',[.3 0.93 0.4 0.03],'BackgroundColor',[1 1 1]);
        set(spectraFigure,'Toolbar','figure');%since uicontrols suppress the toolbar, this brings it back
        
        if detrenddo && baseSubDo
            disp('not set to remove mean and baseline subtract')
            return;
        end
        
        for p=1:length(goodlist)
            plottingFreqIndeces=f{index_selected(p)}>plottingRange(1) & f{index_selected(p)}<plottingRange(2);
            specH(p)=subplot(length(goodlist),1,p);
            
            
            
            %               S (spectrum in form time x frequency x channels/trials if trialave=0;
            %               in the form time x frequency if trialave=1)
            %need to put in a fix if only 1 time point per snippet for trialave=0 since
            %it throws it away. Just need to add a 1 in
            if stnum>0
                tplot=t/60/60/24+stnum;%convert to days then add starting time in days
            else
                tplot=t;
            end
            
            
            
            %%
            %plot it
            if ndims(S{1})==2 && length(f{1})==size(S{1},2) %if trialave was on and S is time x frequencies (though transpose in plotting)
                if detrenddo %mean subtracted
                    %                       imagesc(tplot,f{index_selected(p)}(plottingFreqIndeces),zscore(log10(S{index_selected(p)}(:,plottingFreqIndeces)))',[-3 3]); %transpose here
                    imagesc(tplot,f{index_selected(p)}(plottingFreqIndeces),detrend(log10(S{index_selected(p)}(:,plottingFreqIndeces)),'constant')',[-cr cr]);%subtract mean
                elseif baseSubDo
                    br=t>=baseLow & t<=baseHigh;
                    if sum(br)<=1
                        disp('One or fewer times used for baseline, won''t baseline subtract');
                        return
                    end
                    base=(S{index_selected(p)}(br,:));
                    mb=mean(base);
                    SdivB=S{index_selected(p)}./repmat(mb,size(S{index_selected(p)},1),1);
                    if isempty(SGclim1)
                        imagesc(tplot,f{index_selected(p)}(plottingFreqIndeces),10*log10(SdivB(:,plottingFreqIndeces))');
                    else
                        imagesc(tplot,f{index_selected(p)}(plottingFreqIndeces),10*log10(SdivB(:,plottingFreqIndeces))',[SGclim1 SGclim2]);
                    end
                else
                    if isempty(SGclim1) %if no clim set
                        imagesc(tplot,f{index_selected(p)}(plottingFreqIndeces),10*log10(S{index_selected(p)}(:,plottingFreqIndeces))'); %transpose here
                    else
                        imagesc(tplot,f{index_selected(p)}(plottingFreqIndeces),10*log10(S{index_selected(p)}(:,plottingFreqIndeces))',[SGclim1 SGclim2]);%with clims set
                    end
                end
                if p==length(goodlist) && stnum==0 %only for last one and not using real time
                    xlabel('seconds','FontSize',12);
                end
            end
            if length(f{1})==size(S{1},1) %if is organized as freq x trials since trialave=0 but only 1 moving window per trial
                if baseSubDo
                    disp('Can''t do baseline subtraction with 1 moving window per trial');
                    return
                end
                %                 if event_selected
                %                     disp('Can''t display events  with 1 window per trial');
                %                     event_selected=[];
                %                 end
                if detrenddo
                    disp('Not set to do baseline subtraction with multiple trial');
                    return
                    
                end
                if isempty(SGclim1) %if no clim set
                    imagesc([1:size(S{1},2)],f{index_selected(p)}(plottingFreqIndeces),10*log10(S{index_selected(p)}(plottingFreqIndeces,:))); %don't transpose here
                else
                    imagesc([1:size(S{1},2)],f{index_selected(p)}(plottingFreqIndeces),10*log10(S{index_selected(p)}(plottingFreqIndeces,:)),[SGclim1 SGclim2]);
                end
                %        %one trial per column here
                set(gca,'XTick',1:size(S{1},2));
                xlabel('trials','FontSize',12);
            end
            if ndims(S{1})==3 %if trialave was ==0 then is get third dimension of trials need to reshape and mark accordingly.
                %t is only for 1 time point but plotting one after the other to
                %number of trials so need to make new t. Note this
                %artificially puts all trials into one matrix, [] probably
                %better to make them all different and sitting next to each
                %other but not sure how (subplot with no spacing?)
                if baseSubDo
                    disp('Not set to do baseline subtraction with multiple trial');
                    return
                end
                %                 if event_selected
                %                     disp('Can''t display events  with multiple trials');
                %                     event_selected=[];
                %                 end
                
                Splot=permute(S{index_selected(p)},[2 1 3]); %since can't use transpose operator if 3d and permute is the same but more specified
                Splot=(reshape(Splot,size(Splot,1),size(Splot,2)*size(Splot,3)))'; %to combine into one big freq x time matrix then transpose to time x freq like normal
                %         timeAxis=(t{1}(2)-t{1}(1)).*[1:length(t{1})*size(S{1},3)];%need to stack times but increase each time by the spacing
                
                %       %x axis is in trials since size(S{1},3) is number of trials and
                %       divided into number of times per each * total number of
                %       trials. Need to add 1 since runs to end of the final trial.
                newtime=linspace(1,size(S{1},3)+1,length(tplot)*size(S{1},3));
                if detrenddo
                    imagesc(newtime,f{index_selected(p)}(plottingFreqIndeces),detrend(10*log10(Splot(:,plottingFreqIndeces)),'constant')',[-cr cr]);%subtract mean
                elseif isempty(SGclim1) %if no clim set
                    imagesc(newtime,f{index_selected(p)}(plottingFreqIndeces),10*log10(Splot(:,plottingFreqIndeces))');
                else
                    imagesc(newtime,f{index_selected(p)}(plottingFreqIndeces),10*log10(Splot(:,plottingFreqIndeces))',[SGclim1 SGclim2]);
                end
                
                xlabel('trials','FontSize',12);
                set(gca,'XTick',1:size(S{1},3));
                %                 %12/14/11 for Cruse best patient data only:
                %                 %                 endings=[ 15    13    11    15    15     8     7    12];
                %                 endings=[ 15    28    39    54    69    77    84 96];
                %                 bot=min(f{index_selected(p)}(plottingFreqIndeces));
                %                 to=max(f{index_selected(p)}(plottingFreqIndeces));
                %                 %                 yline=repmat([bot;to],1,length(endings));
                %                 hold on;
                %                 for pp=1:length(endings)
                %                     plot([endings(pp) endings(pp)],[bot-1 to+1],'-','linewidth',3,'color','k');
                %                 end
                
            end
            
            axis xy; %ensures x and y start at 0 in the lower left of the plot
            ylabel(goodlist{p},'FontSize',12);
            colorbar;
            if p<length(goodlist) %until last one
                set(gca,'xtick',[]); %added 8/3 to remove xticks from all axes, will add to bottom one below
            end
            
        end
        % Reset the bottom subplot to have xticks
        %         set(gca,'xtickMode', 'auto');
        %         if stnum>0
        %             dynamicDateTicks
        % %             datetick
        %             axis tight;
        %         end
        
        if isfield(params,'FR');
            titlename=sprintf('Spectrogram calculated with NW=%.0f and K=%.0f, pad=%.0f, moving win [%.1f  %.2f], FR %.2f',params.tapers(1),params.tapers(2),params.pad,...
            movingwinInSec(1),movingwinInSec(2),params.FR);
        else % for older created files without FR in place
            titlename=sprintf('Spectrogram calculated with NW=%.0f and K=%.0f, pad=%.0f, moving win [%.1f  %.2f]',params.tapers(1),params.tapers(2),params.pad,...
            movingwinInSec(1),movingwinInSec(2));
        end
        if detrenddo
            titlename=['Mean-removed ' titlename];
        end
        if baseSubDo
            titlename=sprintf('Baseline-removed (%.1f to %.1f) %s',baseLow,baseHigh,titlename);
        end
        annotation(figure(gcf),'textbox','String',titlename,'Units','normalized','Position',[.1 0.95 0.8 0.05],'FontSize',10,...
            'HorizontalAlignment','center','LineStyle','none');
        
        %         zoom xon
        linkaxes;
        zoom xon
        %         allowaxestogrow;
        if stnum>0 &&  ndims(S{1})==2 && length(f{1})==size(S{1},2) %if there's a start time and if not epoched
            dynamicDateTicks(specH,'link');
            %             datetick
            %             axis tight;
        end
        
        %code here to place lines. For now just on bottom figure, later can
        %put on all. Originally wanted different color for each type but
        %not using now.
        %         eventcell=struct2cell(event);
        %         uniqueNames=unique(eventcell(2,:,:));%find the unique event names
        %or from eeglab website could to unique({event.type});
        %         lineColors={'k','b','g','r'};% for use below
        %         short=length(uniqueNames)>length(lineColors);%how many short you are of colors
        %         if short>0
        %             disp('Not enough line colors for different event types, setting remainder to black');
        %             lineColors{length(lineColors)+1:length(lineColors)+short}=repmat({'k'},1,short);
        %         end
        
        
        
        %         if event list isn't empty, then plot events as lines +/- second
        %         lines (patch lead to errors and hid the text below)
        if ~isempty(event_selected)%if there are events to display
            for ee=1:length(subjEvents)
                if sum(strcmpi(subjEvents(ee).type,uniqueEvents(event_selected)))==1%if event is among ones chosen to plot
                    %if epoched, need to divide by Fs and length of each
                    %epoch (at least for 1 per epoch). [] Need to figure out
                    %how to do for if multiple per epoch
                    if ~params.trialave && epochLength && (ndims(S{1})==3 || length(f{1})==size(S{1},1)) %if epoched data and the epochLength field exists
                        
                        if ndims(S{1})==3 %if epoched with multiple per epoch then numbering begins with the beginning of the
                            %first and spacing (e.g. location of 0) depends on moving window
                            latency(ee)=1-(newtime(2)-newtime(1))/2+subjEvents(ee).latency/params.Fs/epochLength;
                        else %if epoched but only one per epoch then add 0.5 since numbering is in middle of each epoch
                            latency(ee)=0.5+subjEvents(ee).latency/params.Fs/epochLength;%add 0.5 since epochs start at 1 (not 0) and the label number appears halfway in
                        end
                    else %if continuous data that went into the spectrogram
                        if stnum>0
                            latency(ee)=subjEvents(ee).latency/params.Fs/60/60/24+stnum;%convert to seconds from samples and then to days and then add start time
                        else
                            latency(ee)=subjEvents(ee).latency/params.Fs;
                        end
                    end
                    %put event names on bottom
                    %                 textTopH(ee)=text('Parent',specH(1),'Position',[latency(ee) plottingRange(2)],'Rotation',90,'String',['-' event(ee).type]);
                    textBottomH(ee)=text('Parent',specH(end),'Position',[latency(ee) plottingRange(1)-.1],'Rotation',270,'String',['-' subjEvents(ee).type]);
                    
                    for pp=1:length(goodlist) %for each subplot
                        lineH(pp,ee)=line([latency(ee) latency(ee)],[plottingRange(1) plottingRange(2)],'Parent',specH(pp),'LineWidth',1,'Color','k');
                        %if also want to plot event duration and particular event has a duration
                        if durationDispdo && ~isnan(subjEvents(ee).endtime)
                            endtime=subjEvents(ee).endtime/params.Fs/60/60/24+stnum;
                            lineEndH(pp,ee)=line([endtime endtime],[plottingRange(1) plottingRange(2)],'Parent',specH(pp),'LineWidth',1,'Color','k','LineStyle','--');
                            %                             if pp==length(goodlist) %for bottom subplot only, just like text, but line won't appear outside of axes so had to put within.
                            %also tried arrow annotation but is tied to figure and
                            %not axes so won't link
                            lineDurationH(pp,ee)=line([latency(ee) endtime],[mean(plottingRange) mean(plottingRange)],'Parent',specH(pp),'LineWidth',1,'Color','k','LineStyle','-.');
                            %                             end
                            % %                           durationH(ee)=patch([latency(ee) endtime endtime latency(ee)],[plottingRange(1) plottingRange(1) plottingRange(2) plottingRange(2)],'k','Parent',specH(pp),'facealpha',0.3,'EdgeColor','none');
                            % % %                            durationH(ee)=fill([latency(ee) endtime endtime latency(ee)],[plottingRange(1) plottingRange(1) plottingRange(2) plottingRange(2)],'k');
                            % % %                           set(durationH(ee),'facealpha',0.2);
                        end
                    end
                    %                 lineH(ee)=line([latency(ee) latency(ee)],[plottingRange(1) plottingRange(2)],'LineWidth',3,'Color',lineColors{strcmpi(event(ee).type,uniqueNames)});
                    %                  set(lineH(ee),'ButtonDownFcn',{@line_click,lineH}); %run
                    %                  function below - hard to click lines to changed to text
                    %                  set(textBottomH(ee),'ButtonDownFcn',{@text_click,textBottomH,commentbox});%doesn't
                    %                  work here since textBottomH isn't known for ones that
                    %                  haven't been created in the future
                    %                  set(textTopH(ee),'ButtonDownFcn',{@text_click,textTopH,textBottomH}); %run function below
                end
                
            end
            
        
        if durationDispdo && ~isnan(subjEvents(ee).endtime)
                set(textBottomH,'ButtonDownFcn',{@text_click,textBottomH,commentbox,lineEndH,subjEvents});
        end
       
        durationDisplay=uicontrol('Parent',spectraFigure,'Style','pushbutton','Units','normalized','Position',[.03 .93 .1 .05],'String','Durations','Callback',{@Duration_callback,lineEndH,lineDurationH});
        end
     
        axis tight
        
        
        
       
        
    end

  %%
        %simple code to spit out event comment in a box on top when click on the
        %text and change color as if to highlight it (and others with same name would be good).
        %[] would be better to have comment and type appear as a bubble.
        function text_click(src,empty,textH,commentbox,lineEndH,subjEvents) %empty should be ~ but doesn't work in old matlab
            %         eventChosen=find(lineH==src);%should give index to line
            %             disp(event(textH==src).comment);
            if isempty(subjEvents(textH==src).comment)
                subjEvents(textH==src).comment='------';
            end
            commentstring=sprintf('%s at %g: %s',subjEvents(textH==src).type,subjEvents(textH==src).latency,subjEvents(textH==src).comment);
            set(commentbox,'String',commentstring);
            %         set(commentbox,'String',[subjEvents(textH==src).type ': ' subjEvents(textH==src).comment]);
            textcolor=get(src,'Color');
            textStrings1=get(textH,'String');%comes out as a cell array
            %             textStrings2=get(othertextH,'String');
            sameText=textH(strcmpi(get(src,'String'),textStrings1));%vector of handles where same text
            sameLine=lineEndH(:,strcmpi(get(src,'String'),textStrings1));
            sameLine(sameLine==0)=[];%since not all have a line and get a 0 which is handle of root
            %             sameText=[sameText othertextH(strcmpi(get(src,'String'),textStrings2))];%for other text
            if sum(textcolor)==0
                set(sameText,'Color',[1 0 0]);%make it red to highlight it
                set(sameLine,'Color',[1 0 0]);
            else
                set(sameText,'Color',[0 0 0]);%make it black again
                set(sameLine,'Color',[0 0 0]);
            end
        end
        
   %%
        function Duration_callback(src,event,lineEndH,lineDurationH) %to turn duration lines on or off
            if strcmpi(get(lineEndH,'Visible'),'on')
                %                 for j=1:length(specH)
                %                     axes(specH(j)
                set(lineEndH,'visible','off');
                set(lineDurationH,'visible','off')
                %                 end
            else
                set(lineEndH,'visible','on');
                set(lineDurationH,'visible','on')
            end
        end


%%
%
    function topoplotSpectrogram(St,f,t,ChannelList,figuretitle,freq,freqSpace,timeSpace,zscored,stnum,cr,baseSubDo,baseLow,baseHigh,SGclim1,SGclim2)
        
        %8/2/11 to show a topoplot every so many seconds as a way of looking at
        %change in power over time across the head. Needs to be able to take in
        %log10 of average spectrogram matrix or zscored version - coming from
        %subplotSpectrogram. Zscored input variable is simply for accurate labeling.
        
        %8/3/11 add in option to display actual time in HHMMSS with stnum which is
        %starttime in datenum format (days)
        %
        %8/4 moved to be subcode of subplotSpectrogram because took too
        %long with big datasets to send data over when it was its own code.
        
%        %defaults:
         matrix=[3 3]; %size of subplot matrix in the figure
         
        
        %make chanlocs variable for plotting below
        if strcmpi(ChannelList{1},'E1') %if EGI 129 system
            chanlocVariable = pop_readlocs('GSN-HydroCel-129.sfp');%12/19/11
            chanlocVariable(1:3)=[];%because first 3 aren't used apparently.
        else
%             opts=eegp_defopts_eeglablocs;
            chanlocVariable=eegp_makechanlocs(char(ChannelList));
        end
        
        
        %convert St into time x frequency x channel
        if iscell(St)
            Stemp=reshape(cell2mat(St),size(St{1},1),size(St{1},2),[]);
            clear St;
            St=Stemp;
            clear Stemp;
        end
        
        if iscell(f)
            ftemp=f{1};
            clear f
            f=ftemp;
        end
        
        if iscell(t)
            ttemp=t{1};
            clear t;
            t=ttemp;
        end
        
        if nargin<8
            stnum=0;
        end
        
%         matrix=[ceil(length(t(end)-t(1))/3) 3];%size of scroll subplot
%         matrix in figure, added 7/26/13, though doesn't work since code
%         isn't to plot all times, just a subset of them based on the
%         requested spacing

        
        fprintf('Time ranges from %.1f to %.1f, spaced by %.2f sec\n',t(1),t(end),t(2)-t(1));
        %         if nargin<6
        %             freq=input('Frequency to plot at: ');
        %         end
        %
        %         if nargin<7
        %             spacing=input('Spacing between topoplots in seconds (optional): ');
        %             if isempty(spacing)
        %                 spacing=(t(end)-t(1))/prod(matrix);
        %             end
        %         end
     
        %below removed 7/26/13 since changing to scroll subplot
%         %determine if won't plot all in matrix size above and cut down
%         if t(end)-t(1)>timeSpace*matrix(1)*matrix(2)
%             fprintf('Too many topoplots for a %.0f x %.0f display.\n',matrix(1),matrix(2));
%             if stnum %if time displayed in clock time, then stnum is start time in days
%                 startingtimedays=datenum([00,00,00 input('Starting time in [HH,MM,SS] (default beginning): ')]);
%                 startingtime=(startingtimedays-stnum)*24*60*60;%convert days to seconds;
%             else
%                 startingtime=input('Starting time in seconds from start (default beginning): ');
%             end
%             %consider changing this code to be actual time if practical to type
%             if isempty(startingtime)
%                 startingtime=t(1);
%             end
%             %     endingtime=input('End time (optional): ');
%             %     if isempty(endingtime)
%             %         endingtime=t(end);
%             %     end
%             St=St(t>startingtime,:,:);
%             t=t(t>startingtime);
%         end
        
        if isempty(freqSpace)
            fspacing=f(2)-f(1);
        else
            fspacing=freqSpace;
        end
        
        %do the plotting
        topoSpecFig=figure;
        % set(topoSpecFig,'Name',figuretitle);
        if zscored
            titletext=sprintf('Topoplots of mean-subtracted sgrams at %.0f Hz of %s',freq,figuretitle);
            scalingLimits=[-cr cr]; %for topoplot with zscoring to be consistent with spectrogram
        elseif baseSubDo %if baseline subtracted
            titletext=sprintf('Topoplots of baseline (%.1f to %.1f)-subtracted sgrams at %.0f +/- %.1fHz of %s',baseLow,baseHigh,freq,fspacing,figuretitle);
        else
            titletext=sprintf('Topoplots of sgrams at %.00f Hz of %s',freq,figuretitle);
        end
        
        %set clim for baseline subtracted and regular
        if ~zscored && ~isempty(SGclim1)
            scalingLimits=[SGclim1 SGclim2];
        else
            scalingLimits='absmax';
        end
        
        set(topoSpecFig,'Name',titletext);
        tspacing=t(2)-t(1);%to determine plotting time
        
        
        
%         for ii=1:prod(matrix)
         ii=1;   
            %below requires taking mean of time and frequency since each may be a
            %range
            while ii*timeSpace+t(1)<=t(end) %don't plot anything
%             else
%                 subplot(matrix(1),matrix(2),ii);
                scrollsubplot(matrix(1),matrix(2),ii);%added 7/26/13
                if ii==1 %for first one need to start at beginning or go into negative time
                    topoplot(squeeze(mean(St(1,f>(freq-fspacing) & f<(freq+fspacing),:),2)),chanlocVariable,'maplimits',scalingLimits,'electrodes','off');
                    colorbar;
                    if stnum>0 %if start time given from subplotSpectrogram
                        title(datestr(round(t(1))/60/60/24+stnum,13));%13 should be HH:MM:SS
                    else
                        titleTime=sprintf('%.1f',t(1));%so can get 1 decimal point. added 1/22/12
                        title(titleTime);
                    end
                else %normal situation
                    topoplot(squeeze(mean(mean(St(t>(ii*timeSpace-tspacing+t(1)) & t<(ii*timeSpace+tspacing+t(1)),f>(freq-fspacing) & f<(freq+fspacing),:),1),2)),chanlocVariable,'maplimits',scalingLimits,'electrodes','off');
                    colorbar;
                    if stnum>0
                        title(datestr(round(mean(t(t>(ii*timeSpace-tspacing+t(1)) & t<(ii*timeSpace+tspacing+t(1)))))/60/60/24+stnum,13));%13 should be HH:MM:SS
                    else
                        titleTime=sprintf('%.1f',mean(t(t>(ii*timeSpace-tspacing+t(1)) & t<(ii*timeSpace+tspacing+t(1)))));
                        title(titleTime);
                        
                    end
                end
                ii=ii+1;
            end
%         end
        %%
    end
end