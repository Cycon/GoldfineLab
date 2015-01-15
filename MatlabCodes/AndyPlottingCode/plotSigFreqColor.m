function plotSigFreqColor

%3/9/11 needs to pull in TGToutput and use to make same plot as
%plotSigFreqSimple but with full range of p-values. Options need to be for
%frequency range and CLIM (probably need a gui).
%7/28/13 updated so that p-value is calculated accurately with std instead
%of variance


[TGToutputFilename, pathname] = uigetfile('*List.mat', 'Select TGT output file');
if ~ischar(TGToutputFilename) && TGToutputFilename==0 %if user presses cancel
    return
end
file=load(fullfile(pathname,TGToutputFilename));%gives ChannelList,TGToutput,contiguousMoreThanFR,contiguousSigFreq
TGToutput=file.TGToutput;
ChannelList=file.ChannelList;
%%
%reorder channels and TGToutput as well (copy from plotSifFreqSimple)
%reorder Channels to be left lateral, left medial, medial, right medial, right lateral per JV (previously did it like typical EEG presentation). TGToutput is
%organized as one channel per cell so just need to reorder it (not the
%stuff within it).


[ChannelOrder,spaces]=newOrderChannelsForPlotSigFreq(ChannelList);

TGToutputReordered=cell(size(TGToutput));
ChannelListReordered=cell(size(ChannelList));
for io=1:length(TGToutput) %for each channel
    orderIndex = strcmpi(ChannelOrder{io},ChannelList); %gives a logical vector
    TGToutputReordered{io}=TGToutput{orderIndex};
    ChannelListReordered{io}=ChannelList{orderIndex};
end;

TGToutput=TGToutputReordered;
ChannelList=ChannelListReordered;

%%
%calculate p-values and save as a matrix
for i=1:length(TGToutput) %for each channel
    TGTp{i}=(2*(1-normcdf(abs(TGToutput{i}.dz),0,sqrt(TGToutput{i}.vdz))))';%transpose to be a row
    dz(i,:)=TGToutput{i}.dz;
end
pplot=(-log10(cell2mat(TGTp'))).*sign(dz); %-log of p-value to accentuate low ones then convert - with sign of dz

%%
%open figures
pvalueDifferenceFigHandle=figure;
% set(pvalueDifferenceFigHandle,'Units','normalized','Position',[0.4 0 0.6 0.4]);

%setup control figure
plotFigure=figure;
set(plotFigure,'Name',[TGToutputFilename(1:end-25) ' Topo Map Control'],'Units','normalized','Position',[0 0.5 0.2 0.3]);

uicontrol('Style','text','String','Start Frequency:','Units','normalized','FontSize',12,'Position',[0 0.5 0.3 0.2],'BackgroundColor',[1 1 1]);
freqBoxStart=uicontrol('Style','edit','String','4','Units','normalized','FontSize',12,'Position',[0.3 0.5 0.2 0.1],'BackgroundColor',[1 1 1]);
uicontrol('Style','text','String','End Frequency:','Units','normalized','FontSize',12,'Position',[0 0.3 0.3 0.2],'BackgroundColor',[1 1 1]);
freqBoxEnd=uicontrol('Style','edit','String','40','Units','normalized','FontSize',12,'Position',[0.3 0.3 0.2 0.1],'BackgroundColor',[1 1 1]);
uicontrol('Style','text','String','PS plotting range (+/- CLIM):','Units','normalized','FontSize',12,'Position',[0 0.1 0.3 0.2],'BackgroundColor',[1 1 1]);
pBox=uicontrol('Style','edit','String',3,'Units','normalized','FontSize',12,'Position',[0.3 0.1 0.2 0.1],'BackgroundColor',[1 1 1]);
uicontrol('Units','normalized','Position',[0.7 0.2 0.2 0.2],'String','Plot','FontSize',12,'Callback',{@Done_callback});

uiwait
 
        
function Done_callback(varargin)
    plotFreqStart = str2double(get(freqBoxStart,'String'));
    plotFreqEnd = str2double(get(freqBoxEnd,'String'));
    pRange=str2double(get(pBox,'String'));
    uiresume
    plotSigFreqColorDo(plotFreqStart,plotFreqEnd,pRange)
end

%%

    function plotSigFreqColorDo(plotFreqStart,plotFreqEnd,pRange)
    
    figuretitle=sprintf('%s p-values',TGToutputFilename(1:end-25)); 
    

    %previously wanted to flip color map, but 9/1/10 change to leave it default with red as 
    %"more" in condition 1 and matches plotSigFreq plots
    colormap('default');
    p_cmap=colormap;


     figure(pvalueDifferenceFigHandle); %this makes this figure current
     clf;
     set(pvalueDifferenceFigHandle,'Name',figuretitle);
    
    pfr=TGToutput{1}.f>plotFreqStart & TGToutput{1}.f<plotFreqEnd;
    np=length(spaces)+1; %number of plots
    for s=1:np %for each group of channels to matc plotSigFreqSimple
        subplot(np,1,s);
        if s==1
            imagesc(TGToutput{1}.f(pfr),1:spaces(s)-1,pplot(1:spaces(s)-1,pfr),[-pRange pRange]);
            set(gca,'XTick',[]);
            set(gca,'YTickLabel',ChannelList(1:spaces(s)-1));
        elseif s<np
            imagesc(TGToutput{1}.f(pfr),spaces(s-1):spaces(s)-1,pplot(spaces(s-1):spaces(s)-1,pfr),[-pRange pRange]);
            set(gca,'XTick',[]);
            set(gca,'YTickLabel',ChannelList(spaces(s-1):spaces(s)-1));
        else
            imagesc(TGToutput{1}.f(pfr),spaces(s-1):length(TGToutput),pplot(spaces(s-1):end,pfr),[-pRange pRange]);
            set(gca,'YTickLabel',ChannelList(spaces(s-1):end));
            xlabel('Frequency');
    
%     annotation('textbox',[0.72 0.8 0.15 0.1],'String','More Condition 1');
%     annotation('textbox',[0.72,0.2 0.15 0.1],'String','More Condition 2');

%         colorbar('YTick',[1 2 3],'YTickLabel',{'p=0.1','p=0.01','p=0.001'},'FontSize',12); %designed for 1000 segflips
        end
        allowaxestogrow
    end
    end
end



