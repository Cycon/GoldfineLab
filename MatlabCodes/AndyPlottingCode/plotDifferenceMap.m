function plotDifferenceMap

%takes output of calcDifferenceMap and makes two figures. One is actual
%difference and other is p-value.
%
%[]button to save figure and save at frequency value
%version 2 uses dynamic chanlocs
%version 3 7/27/11 uses accurate f for the p-value plot
%version 4 8/3/11 fixes issue of 0 for p-value since can't plot it
%12/22/11 small modification to calculate the frequency resolution and use
%it to set defaults of slider spacing and width.
%12/23/11 version 5 %set to ask for TGTDiffFile first and if contains the difference info
%then plot it. Then if not, load the spectra, call calcSpecDifference, and append the result to the
%diff file. It seems to ignore the accelerometer channels (NaN location) so
%no need to change the code. 
%3/7/12 version 6 make one contour for one p-value cutoff appear on the main plot and represent
%p-values. Give user choice of p-value. Remove the Done
%callback and just send the handles to the main plot code below
%3/30/12 fixed the slider since handle issue didn't work. Also set the
%small step to be ~1 Hz and the big step to be whatever the frequency
%resolution is (might be a bug if FR<1 but rarely happens)
%[] next give option for normalization
%by subtracting off power at another range. 
%7/6/12 removed call to eegp_defopts_eeglablocsAndy since asymmetric
%8/9/13 added option for EGI 33 channel 
%8/12/13 added note that difference now in dB rather than just log to be
%consistent with spectra. the change was made in calcDifference Map not
%here.

%%
%load TGT file
TGTfullfilename=uipickfiles('type',{'*List.mat','TGToutput'},'num',1,'prompt','Select file with TGToutput:','output','char');
if isnumeric(TGTfullfilename) || isempty(TGTfullfilename) %if user presses cancel and it is set to 0
    return
end
[~,h.TGTfilename]=fileparts(TGTfullfilename);
TGT=load(TGTfullfilename);%modified 11/29/11

%%
%Determine if calcSpecDifference was run (since not run on all previous
%versions)
if ~isfield(TGT,'actualDiff')
    disp('This TGT File does not contain difference. Will need to calculate.');
    PS1name=uipickfiles('type',{'*PS.mat','PS file'},'num',1,'Prompt','Pick first PS file','output','char');
    PS2name=uipickfiles('type',{'*PS.mat','PS file'},'num',1,'Prompt','Pick second PS file','output','char');
    spectra{1}=load(PS1name);
    spectra{2}=load(PS2name);
    [TGT.actualDiff,TGT.f,TGT.f_pvalue,TGT.p_value,TGT.params]=calcSpecDifference(spectra,TGT.TGToutput);
    save(TGTfullfilename,'-struct','TGT','actualDiff','f','f_pvalue','p_value','params','-append');
end

%%
%
numChannels=size(TGT.ChannelList,2);
headbox=0;%only used if 35 channels
if numChannels==35
    if ~strcmpi(input('35 channels. Is this headbox 9 (no F1,F2)? (y/n)[y]: ','s'),'n')
        headbox=9;
    end
end

if strcmpi(TGT.ChannelList{1},'E1')
    if length(TGT.ChannelList)==33
        h.chanlocVariable = pop_readlocs('GSN-HydroCel-32.sfp');
    else
        h.chanlocVariable = pop_readlocs('GSN-HydroCel-129.sfp');%12/19/11
    end
    h.chanlocVariable(1:3)=[];%because first 3 aren't used apparently.
    %     eegpopts='EGI129';
else
    eegpopts=[];
%     opts=eegp_defopts_eeglablocs(eegpopts);%uses eeglab channel list to get lead locations
    h.chanlocVariable=eegp_makechanlocs(char(TGT.ChannelList));
end
% [chanlocFilename, pathname2] = uigetfile('*.ced', 'Select channel
% location file');

%open figures
h.topoDifferenceFigHandle=figure;
set(h.topoDifferenceFigHandle,'Units','normalized','Position',[0.4 0.5 0.6 0.4]); %Left Bottom Width Height

h.pvalueDifferenceFigHandle=figure;
set(h.pvalueDifferenceFigHandle,'Units','normalized','Position',[0.4 0 0.6 0.4]);

%%
%setup control figure
plotFigure=figure;
set(plotFigure,'Name',[h.TGTfilename(1:end-27) ' Topo Map Control'],'Units','normalized','Position',[0 0.5 0.2 0.3]);

%calculate FR to determine spacing. To determine swatch length (assuming no
%padding) then use fact that (length(f)-1)*2/Fs is the number of seconds
FR=2*TGT.params.tapers(1) / ((length(TGT.f)-1)*2/TGT.params.Fs);

uicontrol('Style','text','String','Channels on: ','Units','normalized','FontSize',12,'Position',[0 0.85 0.2 .1],'BackgroundColor',[1 1 1]);
h.Channels=uicontrol('Style','checkbox','Value',1,'Units','normalized','Position',[0.3 0.85 0.1 0.1]);

uicontrol('Style','text','String','p-value contour cutoff: ','Units','normalized','FontSize',12,'Position',[0 0.7 0.3 0.1],'BackgroundColor',[1 1 1]);
h.pcutBox=uicontrol('Style','edit','String','.05','Units','normalized','FontSize',12,'Position',[0.3 0.7 0.2 0.1],'BackgroundColor',[1 1 1]);

uicontrol('Style','text','String','Frequency to plot:','Units','normalized','FontSize',12,'Position',[0 0.5 0.3 0.1],'BackgroundColor',[1 1 1]);
h.freqBox=uicontrol('Style','edit','String','4','Units','normalized','FontSize',12,'Position',[0.3 0.5 0.2 0.1],'BackgroundColor',[1 1 1]);
% freqBox=uicontrol('Style','edit','Units','normalized','FontSize',12,'Posi
% tion',[0.3 0.5 0.2 0.1],'BackgroundColor',[1 1 1]);
uicontrol('Style','text','String','+/-','Units','normalized','FontSize',12,'Position',[0.5 0.5 0.1 0.1],'BackgroundColor',[1 1 1]);
h.rangeBox=uicontrol('Style','edit','String',num2str(FR/2),'Units','normalized','FontSize',12,'Position',[0.6 0.5 0.2 0.1],'BackgroundColor',[1 1 1]);
uicontrol('Style','text','String','PS plotting range (in dB for those created after 8/12/13):','Units','normalized','FontSize',12,'Position',[0 0.25 0.3 0.15],'BackgroundColor',[1 1 1]);
h.psBox=uicontrol('Style','edit','String',3,'Units','normalized','FontSize',12,'Position',[0.3 0.3 0.2 0.1],'BackgroundColor',[1 1 1]);
h.SliderButton=uicontrol('Value',4,'Style','slider','Units','normalized','Position',[0 0.05 0.5 0.2],'Callback',{@Slider_callback,h,TGT},'Min',0,'Max',TGT.f(end),'SliderStep',[1/TGT.f(end) FR/TGT.f(end)]);
uicontrol('Units','normalized','Position',[0.7 0.2 0.2 0.2],'String','Plot','FontSize',12,'Callback',{@plotDifferenceMapDo,h,TGT});


% uiwait

    function Slider_callback(hObject,~,h,TGT)
        currentValue=num2str(get(hObject,'Value'));
        set(h.freqBox,'String',currentValue);
        plotDifferenceMapDo(0,0,h,TGT)%not sure if 0,0 are right but seems to work
    end

%     function Done_callback(varargin)
%         %         currentValue=num2str(get(SliderButton,'Value'));
%         %         set(freqBox,'String',currentValue);
%         plotFreq = str2double(get(freqBox,'String'));
%         range=str2double(get(rangeBox,'String'));
%         psRange=str2double(get(psBox,'String'));
%         uiresume
%         plotDifferenceMapDo(plotFreq,range,psRange)
%     end


% plotFreq=input('Frequency to plot at: ');
    function plotDifferenceMapDo(~,~,h,TGT)
        plotFreq = str2double(get(h.freqBox,'String'));
        range=str2double(get(h.rangeBox,'String'));
        psRange=str2double(get(h.psBox,'String'));
        pcut=str2double(get(h.pcutBox,'String'));
        channelShowVal=get(h.Channels,'Value');
        if channelShowVal
            elect='labels';
        else
            elect='off';
        end
        
        pFR=TGT.f>(plotFreq-range) & TGT.f<(plotFreq+range); %index for plotting Frequency range (2hz since is 2W, or could calculate)
        %f_pvalue used since TGT output is twice the length (includes
        %imaginary)
        pFR_pvalue=[TGT.f_pvalue>(plotFreq-range) & TGT.f_pvalue<(plotFreq+range)];
        powerfiguretitle=sprintf('%s power difference %2.2f +/- %.0fHz',h.TGTfilename(1:end-27), plotFreq,range);
        pvaluefiguretitle=sprintf('%s pvalue %2.0f +/- %.0fHz',h.TGTfilename(1:end-27), plotFreq,range);
        
        %%
        %calculate average difference around plotting frequency
        for pd=1:length(TGT.actualDiff) %for each channel
            diffValue(pd)=mean(TGT.actualDiff{pd}(pFR));
            diffPvalue(pd)=mean(TGT.p_value{pd}(pFR_pvalue));
            %if p value is 0, need to change to 1/numShuffles since can't do
            %-log10(0) below for plotting.
            % if diffPvalue(pd)==0
            %    diffPvalue(pd)=1/size(TGT.shuffledDiff{1},2);
            %end
        end
        diffPvalue(diffPvalue==0)=min(diffPvalue(diffPvalue>0)*.1);
        
        
        %%
        
        
        %previously wanted to flip color map, but 9/1/10 change to leave it default with red as
        %"more" in condition 1 and matches plotSigFreq plots
        colormap('default');
        PScmap=colormap;
        pcmap=colormap(bone);
        
        figure(h.topoDifferenceFigHandle); %this makes this figure current
        clf; %aded 9/6 since wasn't clearing the lines, possibly because of new eeglab version installed
        set(h.topoDifferenceFigHandle,'Name',powerfiguretitle);
%         topoplot(diffValue,chanlocVariable,'maplimits',[-psRange psRange],'colormap',(PScmap),'electrodes','labels'); %runs code from eeglab
        %Version below is to plot p-values on main plot as contours, though
        %want them to only appear if significant so need to convert them to
        %bins (if < certain value then get in the bin)
        %1. come up with cutoffs
        %2. move through them and assign 1,2,3 whatever for the different
        %cutoffs to a new variable.
        %3. modify the topoplot code so right number of cutoffs
%         pvalsForContours=
        topoplot(diffValue,h.chanlocVariable,'maplimits',[-psRange psRange],'colormap',(PScmap),'electrodes',elect,'contourvals',+(diffPvalue<pcut),'numcontour',1);%make contours only for selected p 
        %     topoplot(diffValue,ChanlocsFullfile,'maplimits',[-psRange psRange],'colormap',flipud(PScmap),'electrodes','labels'); %runs code from eeglab
        %the one below uses pvalue for contour vals but confusing
        %     topoplot(diffValue,ChanlocsFullfile,'maplimits',[-psRange psRange],'contourvals',-log10(diffPvalue),'colormap',flipud(PScmap)); %runs code from eeglab
        colorbar;
        annotation('textbox',[0.72 0.8 0.15 0.1],'String','More Condition 1');
        annotation('textbox',[0.72,0.2 0.15 0.1],'String','More Condition 2');
        
        %topoplot of p-values at each channel (-log10 so accentuates
        %differences at low values)
        figure(h.pvalueDifferenceFigHandle); %this makes this figure current
        clf;
        set(h.pvalueDifferenceFigHandle,'Name',pvaluefiguretitle);
        topoplot(-log10(diffPvalue),h.chanlocVariable,'maplimits',[0 3],'colormap',pcmap);
        
        colorbar('YTick',[1 2 3],'YTickLabel',{'p=0.1','p=0.01','p=0.001'},'FontSize',12); %designed for 1000 segflips
    end






end