function coherenceMap

%call JV's eegp_wireframe and eegp_wireframe_data to plot coherence values.
%meant for single coherence files (not differences). Need to set a
%threshold to plot to try to look at networks if possible. Similar code for
%comparing two coherences is coherenceDiffMap.
%10/20/11 version 2 Updated so it makes the dh.Hjorth matrix from the channel list of
%the file not just assuming based on number of channels
%11/7/11 version 3 modified to create all lines before sending to
%eegp_wireframe_data since running in a for loop takes forever
%12/22/11 version 4 it now removes channels not on the head (e.g. accelerometer
% channels and [] consider an option to show coherence with the accelerometer
%channels as a topomap
%using color to show coherence with a particular channel. Also switch to
%uipickfiles. Also calculates FR to determine spacing
%4/18/12 version 5 option to remove edge channels from display. Also
%converted everything to handles. Also fixed error that occured if no data.
%7/6/12 removed call to eegp_defopts_eeglablocsAndy since asymmetric

%Todo:
%[] give option to plot power spectra topoplots and with option to do
%relative power (to a specific frequency).

%%

% [CohFilename,pathname]=uigetfile('*Coh.mat','Choose Coherence File');
CohFileMatName=uipickfiles('type',{'*Coh.mat','Coh file'},'prompt','Choose Coherence File','output','char');
if isnumeric(CohFileMatName) %if user presses cancel
    return
end

dh.Cohfile=load(CohFileMatName);
[pathname CohFilename]=fileparts(CohFileMatName);



%%
%make matrix for the wireframe based on the dh.Hjorth Laplacian montage
dh.hopts.mont_mode='Laplacian';
dh.hopts.Laplacian_type='HjorthAbsRescaled';
dh.hopts.Laplacian_nbrs_interior=5;
% dh.eegp_opts=eegp_defopts_eeglablocsAndy;%removed 7/6/12. Will need to
% modify if want to use EGI and to fix FC5 and FC6
dh.Hjorth=cofl_xtp_makemont(dh.Cohfile.ChannelList,[],dh.hopts);%to ensure different than opts below

%%
%remove the accelerometer aspects of the structure here. Use the dh.Hjorth to
%figure it out because gives 0s where channels don't exist
chremove=find(diag(dh.Hjorth)==0);%list of channels to remove
fprintf('Removing results from channels: %s.\n',dh.Cohfile.ChannelList{chremove});
dh.Cohfile.ChannelList(chremove)=[];%remove the acc channel names
dh.Hjorth(chremove,:)=[];%remove them from the wiremap
dh.Hjorth(:,chremove)=[];
indremove=zeros(size(dh.Cohfile.combinations)); %will be number of combinations x 2 where channel to remove in either column
for ch=1:length(chremove)
    indremove=indremove+ (dh.Cohfile.combinations==chremove(ch));
end
indremove=sum(indremove,2)>0;%make vector of 1s since want to remove if in either column
dh.Cohfile.C=dh.Cohfile.C(~indremove);
dh.Cohfile.Cerr=dh.Cohfile.Cerr(~indremove);
dh.Cohfile.combinations=dh.Cohfile.combinations(~indremove,:);
dh.Cohfile.pairs=dh.Cohfile.pairs(~indremove,:);

%%
%determine which are edge channels and later remove them. Looks like the dh.Hjorth
%matrix gets its columns combined (three others in the same row as FPz but
%only 2 in its column so its columns get combined for final output)

%convert it to 1s and 0s by <0 (all the off diagnols are <0), so easy to determine count
dh.edgeInd=sum(dh.Hjorth<0,2)==3;%gives the indices of the edge channels after acc removed


%%
%put in one with all the labels and no data as a legend and
%the rest don't have labels since will be messy
fh.wireframeFigure=figure;
set(fh.wireframeFigure,'Name',[CohFilename(1:end-3) 'Coh'],'Units','normalized','Position',[0 0 .95 .9]);


%%
%set up control figure and call below as a code
plotFigure=figure;
set(plotFigure,'Name',[CohFilename(1:end-3) ' Coh Map Control'],'Units','normalized','Position',[0 0.5 0.2 0.3]);

FR=(2*dh.Cohfile.params.tapers(1))/((length(dh.Cohfile.f)-1)/dh.Cohfile.params.fpass(2));%if get rid of fpass, use Fs/2

uicontrol('Style','text','String','Suppress edge channels:','Units','normalized','FontSize',12,'Position',[0 0.9 0.4 0.1],'BackgroundColor',[1 1 1]);
h.suppEdge=uicontrol('Style','checkbox','Units','normalized','FontSize',12,'Position',[0.4 0.9 0.2 0.1],'BackgroundColor',[1 1 1]);
uicontrol('Style','text','String','Starting Frequency:','Units','normalized','FontSize',12,'Position',[0 0.5 0.3 0.2],'BackgroundColor',[1 1 1]);
h.freqBox=uicontrol('Style','edit','String','3','Units','normalized','FontSize',12,'Position',[0.3 0.5 0.2 0.1],'BackgroundColor',[1 1 1]);
% freqBox=uicontrol('Style','edit','Units','normalized','FontSize',12,'Posi
% tion',[0.3 0.5 0.2 0.1],'BackgroundColor',[1 1 1]);
uicontrol('Style','text','String','+/-','Units','normalized','FontSize',12,'Position',[0.5 0.5 0.1 0.1],'BackgroundColor',[1 1 1]);
h.rangeBox=uicontrol('Style','edit','String',num2str(FR/2),'Units','normalized','FontSize',12,'Position',[0.6 0.5 0.2 0.1],'BackgroundColor',[1 1 1]);
uicontrol('Style','text','String','Freq btwn images:','Units','normalized','FontSize',12,'Position',[0 0.3 0.3 0.2],'BackgroundColor',[1 1 1]);
h.spaceBox=uicontrol('Style','edit','String',num2str(FR),'Units','normalized','FontSize',12,'Position',[0.3 0.3 0.2 0.1],'BackgroundColor',[1 1 1]);
uicontrol('Style','text','String','Threshold Range:','Units','normalized','FontSize',12,'Position',[0 0.8 0.3 0.1],'BackgroundColor',[1 1 1]);
h.thresholdLow=uicontrol('Style','edit','String',0,'Units','normalized','FontSize',12,'Position',[0.3 0.7 0.2 0.1],'BackgroundColor',[1 1 1]);
h.thresholdHigh=uicontrol('Style','edit','String',1,'Units','normalized','FontSize',12,'Position',[0.6 0.7 0.2 0.1],'BackgroundColor',[1 1 1]);
uicontrol('Style','text','String','3D:','Units','normalized','FontSize',12,'Position',[0 0 0.2 0.1],'BackgroundColor',[1 1 1]);
h.checkBox=uicontrol('Style','checkbox','Units','normalized','Position',[0.3 0 0.2 0.1]);
uicontrol('Units','normalized','Position',[0.7 0.2 0.2 0.2],'String','Plot','FontSize',12,'Callback',{@Done_callback,h,dh,fh});

% SliderButton=uicontrol('Value',4,'Style','slider','Units','normalized','Position',[0 0.1 0.5 0.2],'Callback',{@Slider_callback},'Min',0,'Max',100,'SliderStep',[0.01 0.05]);

% uiwait

    function Done_callback(src,eventdata,h,dh,fh)
        %         currentValue=num2str(get(SliderButton,'Value'));
        %         set(freqBox,'String',currentValue);
        startFreq = str2double(get(h.freqBox,'String'));
        range=str2double(get(h.rangeBox,'String'));
        spacing=str2double(get(h.spaceBox,'String'));
        threshold(1)=str2double(get(h.thresholdLow,'String'));
        threshold(2)=str2double(get(h.thresholdHigh,'String'));
        plot3D=get(h.checkBox,'Value'); %if 1 then plot in 3d, default is 0
        %         uiresume
        removeEdge=get(h.suppEdge,'Value');
        if removeEdge
            dh.Hjorth=cofl_xtp_makemont(dh.Cohfile.ChannelList(~dh.edgeInd),[],dh.hopts);%to redo a nicer frame with just relevant channels

%             dh.Hjorth(dh.edgeInd,:)=[];%remove them from the wiremap rows
%             dh.Hjorth(:,dh.edgeInd)=[];%remove them from the wiremap columns
            dh.Cohfile.ChannelList(dh.edgeInd)=[];
            %create the eindremove since need to find the channels to
            %remove in the channel pairs
%             edgeCh=dh.Cohfile.ChannelList(dh.edgeInd);
            edgeChNum=find(dh.edgeInd);
            eindremove=zeros(size(dh.Cohfile.combinations));
            for ch1=1:length(edgeChNum)
                %4/18/12 had problem because initially no parenthesis
                %around the part on the right and it did the addition
                %before the ==
                eindremove=eindremove+(dh.Cohfile.combinations==edgeChNum(ch1));
            end
            eindremove=sum(eindremove,2)>0;%make vector of 1s since want to remove if in either column
            dh.Cohfile.C=dh.Cohfile.C(~eindremove);
            dh.Cohfile.Cerr=dh.Cohfile.Cerr(~eindremove);
            dh.Cohfile.combinations=dh.Cohfile.combinations(~eindremove,:);
            dh.Cohfile.pairs=dh.Cohfile.pairs(~eindremove,:);
        end
        
        plotCohMapDo(startFreq,range,spacing,threshold,plot3D,dh,fh)
    end
%%
    function plotCohMapDo(startFreq,range,spacing,threshold,plot3D,dh,fh)
        %make the wireframes, one for each frequency range unless just do one and
        %scroll through ranges. Can send all at once as a column list to
        %eegp_wireframe_data.
        
        % clear opts; %11/16/11 realized figure saves opts from below and if replot matters
        if plot3D
            opts.headmap_style=1;%plot 3D
        else
            opts.headmap_style=0;%plot 2D
        end
        
        figure(fh.wireframeFigure);
        clf; %to clear previous version in case redoing it
        %first put a legend figure in the upper left
        legendFrame=subplot(3,3,1);
        eegp_wireframe(dh.Hjorth,dh.Cohfile.ChannelList,opts);
        set(gca,'YTickLabel',[],'XTickLabel',[]);
        
        %have the legend put a black line at each connection tested
        % wireframe_data.pairlabel=dh.Cohfile.pairs;
        % wireframe_data.paircolor=repmat([0 1 0],size(dh.Cohfile.pairs,1),1); %make same size as number of labels
        % wireframe_data.pairwidth=repmat(10,size(dh.Cohfile.pairs,1),1);
        % eegp_wireframe_data(wireframe_data,opts); %to put the lines on
        % title('legend - coherences tested');
        title('legend - channels tested');%stopped showing all since no point
        
        wireframe_data=[]; %so can use below
        opts.headmap_iflabel=0;
        for i=2:9
            cohPlot{i}=subplot(3,3,i);
            freqRange=[startFreq-range+(i-2)*spacing startFreq+range+(i-2)*spacing];
            titleText=sprintf('%.1f to %.1f Hz',freqRange(1),freqRange(2));
            eegp_wireframe(dh.Hjorth,dh.Cohfile.ChannelList,opts);
            hold on;
            title(titleText);
            set(gca,'YTickLabel',[],'XTickLabel',[]); %so no labels
            plotNum=1;
            for j=1:size(dh.Cohfile.pairs,1) %for each channel pair
                cohValue=mean(dh.Cohfile.C{j}(dh.Cohfile.f>=freqRange(1) & dh.Cohfile.f<=freqRange(2)));
                if cohValue>=threshold(1) && cohValue<=threshold(2) %can use threshold to choose range of coherences
                    wireframe_data.pairlabel(plotNum,:)=dh.Cohfile.pairs(j,:);
                    %[] coherence values, mean over range
                    %[] threshold for plotting
                    %             wireframe_data.paircolor(j,:)=[1 0.5 0]; %blue
                    wireframe_data.pairwidth(plotNum)=cohValue*10;
                    %             eegp_wireframe_data(wireframe_data,opts);
                    plotNum=plotNum+1;
                end
            end
            if ~isempty(wireframe_data) %added 4/18/12
                wireframe_data.paircolor=repmat([1 0.5 0],length(wireframe_data.pairwidth),1);
                eegp_wireframe_data(wireframe_data,opts);%run from the for loop just above
            end
        end
        
        allowaxestogrow;
    end

end