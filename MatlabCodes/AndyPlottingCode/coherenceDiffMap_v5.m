function coherenceDiffMap

%call JV's eegp_wireframe and eegp_wireframe_data to plot coherence values.
%uses TGT p-value as a threshold to decide which lines to plot. Then
%thickness is determined by the difference (range of difference is 0 to 1
%so multiplies by 10)
%[] redo original code so no cell arrays so this code runs faster
%- power spectra comparison button for new figure
%10/20/11 version 2 - modified creation of Hjorth matrix so uses actual
%channel list and not assuming based on number of channels.
%11/16/11 modified so creates chanlocs from channel list and not from a
%pre-saved file for the topoplot option. Also hid suppress nearest neighbor
%since doesn't work and modify legen figure to just have labels and not
%useless lines.
%12/1/11 modified to use uipickfiles instead
%12/22/11 version 3 now need to remove non-head channels (like accelerometers)
%also modified coherenceMap. Also modify the default spacing to be the FR and the
%window to be 1/2 the FR
%12/23/11 modify PS difference to call the TGToutput and Diff file since no
%longer using Diff file.
%4/17/12 version 4 add option to suppress edge channels from the display (helps to
%remove effects of eye blink and muscle and also these channels aren't as
%accurate from the laplacian). Also turned all variables into
%handles so they don't overlap codes but instead pass them down (did three
%handles h,dh,fh though not sure if this was worth it to do so many).
%5/9/12 version 5 use scrollsubplot instead so can look at more at once
%7/6/12 removed call to eegp_opts=eegp_defopts_eeglablocsAndy because
        %channel locations aren't symmetric.

%ToDo:
%[] at some point need to modify to use EGI cap (chanlocs needs to load
%.sfp and probably want to average channels or do only on subset).


%%
% [TGTandDifffilename,pathname]=uigetfile('*TGTandDiff.mat','Choose TGT and Diff File');
TGTandDifffilename=uipickfiles('type',{'*CohTGTandDiff.mat','Coh TGT output file'},'num',1,'prompt','Choose Coh TGT and Diff File');
if isnumeric(TGTandDifffilename) || isempty(TGTandDifffilename) %if user presses cancel
    return
end
dh.TGTandDiff=load(TGTandDifffilename{1});%dh is data handle while h is handle of control figure information
[path dh.dispname]=fileparts(TGTandDifffilename{1});

% [PS_DiffFileName,pathname2]=uigetfile('*_Diff.mat','Choose PS Diff File (optional)');
% PS_DiffFileName=uipickfiles('type',{'*_Diff.mat','PS Diff File'},'num',1,'prompt','Choose PS Diff File (optional - press cancel)');
dh.PS_DiffFileName=uipickfiles('type',{'*List.mat','TGToutput'},'num',1,'prompt','Select file with TGToutput (optional - press cancel)','output','char');

if isnumeric(dh.PS_DiffFileName) || isempty(dh.PS_DiffFileName) %if user presses cancel
    
else
    dh.Diff=load(dh.PS_DiffFileName,'ChannelList','f','actualDiff');%12/23/11 to only import needed variables for plotting
    %     numChannels=size(Diff.ChannelList,2);
%     eegp_opts=eegp_defopts_eeglablocsAndy;%uses eeglab channel list to
%     get lead locations; my version in case want to do EGI some day.
%     removed 7/6/12
%     dh.chanlocVariable=eegp_makechanlocs(char(dh.Diff.ChannelList),eegp_opts);
    dh.chanlocVariable=eegp_makechanlocs(char(dh.Diff.ChannelList));
    %ignores the accelerometer channels so no need to change the code.
    fh.PSfigure=figure;%fh for figure handle
end

%%
%make matrix for the wireframe based on the Hjorth Laplacian montage
dh.hopts.mont_mode='Laplacian';%use hopts since use opts below
dh.hopts.Laplacian_type='HjorthAbsRescaled';
dh.eegp_opts=eegp_defopts_eeglablocsAndy;
dh.hopts.Laplacian_nbrs_interior=5;%so more lines filled in
dh.Hjorth=cofl_xtp_makemont(dh.TGTandDiff.ChannelList,[],dh.hopts,dh.eegp_opts);

%%
%remove the accelerometer aspects of the structure here. Use the Hjorth to
%figure it out because gives 0s where channels don't exist
chremove=find(diag(dh.Hjorth)==0);%list of channels to remove
fprintf('Removing results from channels: %s.\n',dh.TGTandDiff.ChannelList{chremove});
dh.Hjorth(chremove,:)=[];%remove them from the wiremap rows
dh.Hjorth(:,chremove)=[];%remove them from the wiremap columns
indremove=zeros(size(dh.TGTandDiff.channelPairs)); %will be number of combinations x 2 where channel to remove in either column
for ch=1:length(chremove)
    indremove=indremove+ strcmpi(dh.TGTandDiff.channelPairs,dh.TGTandDiff.ChannelList(chremove(ch)));
end
indremove=sum(indremove,2)>0;%make vector of 1s since want to remove if in either column
dh.TGTandDiff.TGToutput=dh.TGTandDiff.TGToutput(~indremove);
dh.TGTandDiff.differenceCoh1minusCoh2=dh.TGTandDiff.differenceCoh1minusCoh2(~indremove);
dh.TGTandDiff.channelPairs=dh.TGTandDiff.channelPairs(~indremove,:);
dh.TGTandDiff.ChannelList(chremove)=[];%remove the acc channel names

%%
%determine which are edge channels and remove them. Looks like the Hjorth
%matrix gets its columns combined (three others in the same row as FPz but
%only 2 in its column so its columns get combined for final output)

%convert it to 1s and 0s by <0 (all the off diagnols are <0), so easy to determine count
dh.edgeInd=sum(dh.Hjorth<0,2)==3;%gives the indices of the edge channels after acc removed



% %%
% %determine which are neighbors to suppress in plot if want to, assumes that
% %matrix above has all neighbors in it. [] Not working yet!
% [rowI,colI]=find(Hjorth);
% neighborChannels=TGTandDiff.ChannelList([rowI,colI]);%gives the channel names that are neighbors
% sameChan=strcmp(neighborChannels(:,1),neighborChannels(:,2)); %gives index of which ones are the same
% neighborChannels(sameChan,:)=[];%so now only neighbors and not the same


%%
%put in one with all the labels and no data as a legend and
%the rest don't have labels since will be messy
fh.wireframeFigure=figure;
set(fh.wireframeFigure,'Name',[dh.dispname(1:end-14) 'Coh'],'Units','normalized','Position',[0.15 0.1 .8 .8]);


%%
%set up control figure and call below as a code
plotFigure=figure;
set(plotFigure,'Name',[dh.dispname(1:end-14) ' Coh Map Control'],'Units','normalized','Position',[0 0.5 0.1 0.4]);

FR=2*dh.TGTandDiff.params.tapers(1)/(length(dh.TGTandDiff.TGToutput{1}.dz)/dh.TGTandDiff.params.Fs);
% uicontrol('Style','text','String','Suppress neighbors:','Units','normalized','FontSize',12,'Position',[0 0.9 0.2 0.15],'BackgroundColor',[1 1 1]);
% neighborCheck=uicontrol('Style','checkbox','Units','normalized','Position',[0.3 0.9 0.2 0.1]);
uicontrol('Style','text','String','Suppress edge channels:','Units','normalized','FontSize',12,'Position',[0 0.9 0.4 0.1],'BackgroundColor',[1 1 1]);
h.suppEdge=uicontrol('Style','checkbox','Units','normalized','FontSize',12,'Position',[0.4 0.9 0.2 0.1],'BackgroundColor',[1 1 1]);
uicontrol('Style','text','String','TGT p-value cutoff:','Units','normalized','FontSize',12,'Position',[0 0.7 0.4 0.15],'BackgroundColor',[1 1 1]);
h.alphaValue=uicontrol('Style','edit','String','0.05','Units','normalized','FontSize',12,'Position',[0.4 0.7 0.3 0.1],'BackgroundColor',[1 1 1]);
uicontrol('Style','text','String','Starting Frequency:','Units','normalized','FontSize',12,'Position',[0 0.5 0.4 0.15],'BackgroundColor',[1 1 1]);
h.freqBox=uicontrol('Style','edit','String','3','Units','normalized','FontSize',12,'Position',[0.4 0.5 0.2 0.1],'BackgroundColor',[1 1 1]);
% freqBox=uicontrol('Style','edit','Units','normalized','FontSize',12,'Posi
% tion',[0.3 0.5 0.2 0.1],'BackgroundColor',[1 1 1]);
uicontrol('Style','text','String','+/-','Units','normalized','FontSize',12,'Position',[0.6 0.5 0.1 0.1],'BackgroundColor',[1 1 1]);
h.rangeBox=uicontrol('Style','edit','String',num2str(FR/2),'Units','normalized','FontSize',12,'Position',[0.7 0.5 0.2 0.1],'BackgroundColor',[1 1 1]);
uicontrol('Style','text','String','Freq btwn images:','Units','normalized','FontSize',12,'Position',[0 0.3 0.4 0.15],'BackgroundColor',[1 1 1]);
h.spaceBox=uicontrol('Style','edit','String',num2str(FR),'Units','normalized','FontSize',12,'Position',[0.4 0.3 0.2 0.1],'BackgroundColor',[1 1 1]);
uicontrol('Style','text','String','3D:','Units','normalized','FontSize',12,'Position',[0 0 0.2 0.1],'BackgroundColor',[1 1 1]);
h.checkBox=uicontrol('Style','checkbox','Units','normalized','Position',[0.3 0 0.2 0.1]);
% SliderButton=uicontrol('Value',4,'Style','slider','Units','normalized','Position',[0 0.1 0.5 0.2],'Callback',{@Slider_callback},'Min',0,'Max',100,'SliderStep',[0.01 0.05]);
if ~dh.PS_DiffFileName==0 %to put a window on the power spectra plots
    %add iff here and:
    uicontrol('Style','text','String','PS plotting window:','Units','normalized','FontSize',12,'Position',[0 0.1 0.4 0.2],'BackgroundColor',[1 1 1]);
    h.psBox=uicontrol('Style','edit','String',3,'Units','normalized','FontSize',12,'Position',[0.4 0.1 0.2 0.1],'BackgroundColor',[1 1 1]);
end

%4/18/12 - important that this done code is last so all the handles are created first
uicontrol('Units','normalized','Position',[0.7 0.2 0.3 0.1],'String','Plot','FontSize',12,'Callback',{@Done_callback,h,dh,fh});




% uiwait %4/18/12 able to get rid of this now that everything in a handle
% and variables don't span functions

    function Done_callback(src,eventdata,h,dh,fh)
        %         currentValue=num2str(get(SliderButton,'Value'));
        %         set(freqBox,'String',currentValue);
        alpha=str2double(get(h.alphaValue,'String'));
        startFreq = str2double(get(h.freqBox,'String'));
        range=str2double(get(h.rangeBox,'String'));
        spacing=str2double(get(h.spaceBox,'String'));
        plot3D=get(h.checkBox,'Value'); %if 1 then plot in 3d, default is 0
        %         suppNeighbors=get(neighborCheck,'Value');%if 1 suppress neighbors
        %         uiresume
        
        %4/18/12 added option to remove edge. By doing it here, should be
        %reversible
        removeEdge=get(h.suppEdge,'Value');
        if removeEdge
            dh.Hjorth=cofl_xtp_makemont(dh.TGTandDiff.ChannelList(~dh.edgeInd),[],dh.hopts,dh.eegp_opts);%to redo a nicer frame with just relevant channels
%             dh.Hjorth(dh.edgeInd,:)=[];%remove them from the wiremap rows
%             dh.Hjorth(:,dh.edgeInd)=[];%remove them from the wiremap columns
            %create the eindremove since need to find the channels to
            %remove in the channel pairs
            edgeCh=dh.TGTandDiff.ChannelList(dh.edgeInd);
            eindremove=zeros(size(dh.TGTandDiff.channelPairs)); 
            for ch1=1:length(edgeCh)
                eindremove=eindremove+ strcmpi(dh.TGTandDiff.channelPairs,edgeCh(ch1));
            end
            eindremove=sum(eindremove,2)>0;%make vector of 1s since want to remove if in either column
            dh.TGTandDiff.TGToutput=dh.TGTandDiff.TGToutput(~eindremove);
            dh.TGTandDiff.differenceCoh1minusCoh2=dh.TGTandDiff.differenceCoh1minusCoh2(~eindremove);
            dh.TGTandDiff.channelPairs=dh.TGTandDiff.channelPairs(~eindremove,:);
            dh.TGTandDiff.ChannelList(dh.edgeInd)=[];%remove the acc channel names
        end
        plotCohMapDo(startFreq,range,spacing,plot3D,alpha,fh,dh)
        
        
        if ~dh.PS_DiffFileName==0 %if a PS diff file also chosen
            psRange=str2double(get(h.psBox,'String'));
            plotPSDifferences(startFreq,range,psRange,spacing,dh,fh)
        end
    end
%%
    function plotCohMapDo(startFreq,range,spacing,plot3D,alpha,fh,dh)
        %make the wireframes, one for each frequency range unless just do one and
        %scroll through ranges. Can send all at once as a column list to
        %eegp_wireframe_data.
        
        % clear opts;%since values set below get stored in the figure! 11/16/11
        if plot3D
            opts.headmap_style=1;%plot 3D
        else
            opts.headmap_style=0;%plot 2D
        end
        
        figure(fh.wireframeFigure);
        clf; %to clear previous version in case redoing it
        set(fh.wireframeFigure,'Name',dh.dispname(1:end-14));
        
        %first put a legend figure in the upper left
        legendFrame=scrollsubplot(3,3,1);%modified to scrollsubplot 5/9/12
        opts.font_size=10;%for the channel labels
        eegp_wireframe(dh.Hjorth,dh.TGTandDiff.ChannelList,opts);%11/16/11 this code puts labels on by default
        set(gca,'YTickLabel',[],'XTickLabel',[]);
        % %have the legend put a green line at each connection tested
        % wireframe_data.pairlabel=TGTandDiff.channelPairs;
        % wireframe_data.paircolor=repmat([0 1 0],size(TGTandDiff.channelPairs,1),1); %make same size as number of labels
        % wireframe_data.pairwidth=repmat(10,size(TGTandDiff.channelPairs,1),1);
        % eegp_wireframe_data(wireframe_data,opts); %to put the lines on
        title('legend');
        
        clear wireframe_data; %so can use below
        opts.headmap_iflabel=0; %to turn the lead labels off
        for i=2:18%modified 5/9/12 for scrollsubplot
            cohPlot(i)=scrollsubplot(3,3,i);
            freqRange=[startFreq-range+(i-2)*spacing startFreq+range+(i-2)*spacing];
            titleText=sprintf('%.1f to %.1f Hz',freqRange(1),freqRange(2));
            eegp_wireframe(dh.Hjorth,dh.TGTandDiff.ChannelList,opts);
            hold on;
            title(titleText,'fontsize',20);
            set(gca,'YTickLabel',[],'XTickLabel',[]); %so no labels
            for j=1:size(dh.TGTandDiff.channelPairs,1) %for each channel pair
                wireframe_data.pairlabel=dh.TGTandDiff.channelPairs(j,:);
                
                difference=mean(dh.TGTandDiff.differenceCoh1minusCoh2{j}(dh.TGTandDiff.differenceF>freqRange(1) & dh.TGTandDiff.differenceF<freqRange(2))); %mean difference between range
                p_value=mean(dh.TGTandDiff.TGToutput{j}.p(dh.TGTandDiff.TGToutput{j}.f>freqRange(1) & dh.TGTandDiff.TGToutput{j}.f<freqRange(2)));
                if difference>0
                    wireframe_data.paircolor=[1 0 0]; %red
                else
                    wireframe_data.paircolor=[0 0 1]; %blue
                end
                wireframe_data.pairwidth=abs(difference*10);
                if p_value<=alpha %required to show a connection, uses TGT p-value
                    eegp_wireframe_data(wireframe_data,opts);
                end
            end
            
        end
        if ~plot3D %since want to be able to rotate
%             allowaxestogrow;%turned off 5/30 to allow for export to adobe
disp('allowaxestogrow off for export to adobe');
        else
            %     linkaxes([cohPlot(1) cohPlot(2)]); %crashed on 3/13 and don't think
            %     worked anyhow
        end
    end

    function plotPSDifferences(startFreq,range,psRange,spacing,dh,fh)
        
        
        figure(fh.PSfigure);
        set(fh.PSfigure,'name',dh.PS_DiffFileName(1:end-9));
        clf;
        for ps=2:9
            subplot(3,3,ps)
            freqRange=[startFreq-range+(ps-2)*spacing startFreq+range+(ps-2)*spacing];
            titleText=sprintf('%.0f to %.0f Hz',freqRange(1),freqRange(2));
            hold on;
            title(titleText);
            %need to reset pFR to be different for each subplot
            pFR=[dh.Diff.f>freqRange(1) & dh.Diff.f<freqRange(2)]; %index for plotting Frequency range (2hz since is 2W, or could calculate)
            %             powerfiguretitle=sprintf('%s power difference %2.2f +/- %.0fHz',DiffFilename(1:end-9), plotFreq,range);
            %             pvaluefiguretitle=sprintf('%s pvalue %2.0f +/- %.0fHz',DiffFilename(1:end-9), plotFreq,range);
            
            
            %calculate average difference around plotting frequency
            for pd=1:length(dh.Diff.actualDiff) %for each channel
                diffValue(pd)=mean(dh.Diff.actualDiff{pd}(pFR));
                %consider adding in code to look at TGT result though first need to
                %incorporate that into original file! []
            end
            
            %previously wanted to flip color map, but 9/1/10 change to leave it default with red as
            %"more" in condition 1 and matches plotSigFreq plots
            colormap('default');
            PScmap=colormap;
            %     pcmap=colormap(bone);
            topoplot(diffValue,dh.chanlocVariable,'maplimits',[-psRange psRange],'colormap',(PScmap),'electrodes','labels'); %runs code from eeglab
            %     topoplot(diffValue,ChanlocsFullfile,'maplimits',[-psRange psRange],'colormap',flipud(PScmap),'electrodes','labels'); %runs code from eeglab
            %the one below uses pvalue for contour vals but confusing
            %     topoplot(diffValue,ChanlocsFullfile,'maplimits',[-psRange psRange],'contourvals',-log10(diffPvalue),'colormap',flipud(PScmap)); %runs code from eeglab
            %             colorbar;
            %             annotation('textbox',[0.72 0.8 0.15 0.1],'String','More Condition 1');
            %             annotation('textbox',[0.72,0.2 0.15 0.1],'String','More Condition 2');
            
            
        end
    end



end