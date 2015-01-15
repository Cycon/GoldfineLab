function [contiguousMoreThanFR,contiguousSigFreq]=plotSigFreqSimpleSudhin(figuretitle,spectra1label, spectra2label,TGToutput, ChannelList,TGTpathname,legendon)

%based on plotSigFreq but want to get rid of Fisher and spacings
%based on plotSigFreqSimpleSrivas which is based on plotSigFreqSimple

            
%%
%If called directly, need to get data from subplotSpectra output
if nargin<3
    figuretitle=input('figuretitle:','s');
    if strcmpi(input('Place legend and title? (y-yes or Return)','s'),'y')
        legendon=1;
        spectra1label=input('label for spectra 1:','s');
        spectra2label=input('label for spectra 2:','s');
    else
        legendon=0;
    end
end
if nargin<4
    [filename2, TGTpathname] = uigetfile('*List.mat', 'Select TGTOutput');
    TGToutputContigList=load(fullfile(TGTpathname,filename2));
    TGToutput=TGToutputContigList.TGToutput;
    ChannelList=TGToutputContigList.ChannelList;
end;
    
if nargin>=4 %from subplotEeglabSpectra; changed from ==4 on 9/1/10
    TGTpathname=pwd; %where to save the figures
end
plotInsigResults=1; %make =1 to plot * for sig freq not over 2W Hz

%%
%define defaults
numChannels=length(TGToutput);
f=TGToutput{1}.f;
frequencyRecorded=max(f);
sampleLength=length(f)/max(f);%length of cuts (moving window)
plotFDR=0;
plottingRange=[7 30];
plottingFreqIndeces=(f>=plottingRange(1) & f<=plottingRange(2));
notPlottingFreq=~(plottingFreqIndeces);%used to suppress results outside of plotting Range

%7/8/10 JV and Hemant say that 2W is actually only 6 since each f value
%really starts half below and ends half above it. So 0 is -.5 and 6 is 6.5
%with a difference of 7=2Hz. So set a difference of frequency resolution to
%be 2W-(f(2)-f(1)). (8/5/10- after looking at JVs notes, could also just
%take tapers(2) and multiply it by f(2)-f(1) since that's how many tapers
%you can fit in the window).
frequencyResolution2W=TGToutput{1}.NW/sampleLength*2; 
frequencyResolution=frequencyResolution2W-(f(2)-f(1));%2W Hz is an allowed frequency Resolution
%Consider changing frequencyResolution manually in the graphic

%%
% Give user option to input results from a Fisher analysis and plot to left
% of each channel label. Important that the Fisher information is available
% as an annotation above (Fisher 2 to 24 by 2 / % x-val correct, p-val of
% within/total variance vs shuffles). If this occurs, set a flag so that in
% the plotting code there is a new section for displaying this information
% and putting another annotation. Also will need to move current annotation
% to the top. Also consider putting slope information in.

% plotFisherResults=0; %commented out 9/30/10 since not being used

%%
%reorder TGToutput, p_value and ChannelList but make sure
%there's one version to match topoplot below.

 %%
    %reorder Channels to be left lateral, left medial, medial, right medial, right lateral per JV (previously did it like typical EEG presentation). TGToutput is
    %organized as one channel per cell so just need to reorder it (not the
    %stuff within it).
    
    %first select 25 channels 
%     SrivasList=[6    7   13   29   30   31   35   36   37   41   42   54   55   79 80   87   93  103  104  105  106  110  111  112  129]; 
    %put left then center then right
    ChannelOrder=[33 45 58 22 24 36 52 70 11 129 62 9 124 104 92 83 122 108 96 ];
    spaces=[4 9 12 17 20];%indices for above where you want a space before that index    
    %put in option first that if just numbers (like ICA components) then
%     %skip below and put in order:
%     if ~isnan(str2double(ChannelList{1})) %if the 1st channel is text that's not a number (always starts as string so testing with str2double)
%         ChannelListReordered=ChannelList;
%         spaces=[];
%     else
%         [ChannelOrder,spaces]=newOrderChannelsForPlotSigFreq(ChannelList);

        TGToutputReordered=TGToutput(ChannelOrder);
        ChannelListReordered=ChannelList(ChannelOrder);
%         for io=1:length(TGToutput) %for each channel
%             orderIndex = strcmpi(ChannelOrder{io},ChannelList); %gives a logical vector
%             TGToutputReordered{io}=TGToutput{orderIndex};
%             ChannelListReordered{io}=ChannelList{orderIndex};
%         end;

        TGToutput=TGToutputReordered;
        numChannels=length(ChannelListReordered);
%     end


%%
%calculate frequencies that have contiguous significant results > 2W Hz
% and only look at ones between plottingRange and differentiate based on
% which condition is higher
%want to display this to the left of the graph or only plot this (would be
%nice to dynamically change frequencyResolution from the graph).
%

for i=1:length(TGToutput) %for each channel
 
    for j=1:2 %for each condition, 1 is condition 1 and 2 is condition 2
        
        %first set all values below and above plottingRange to be 0 since
        %pretending we didn't test for those values. This will keep away rectangles
        %that continue off the page.
        TGToutput{i}.AdzJKC{j}(notPlottingFreq)=0;
        
        
        contiguousMoreThanFROnes{i}{j}=zeros(1,length(f)); %set it to be all 0s at first
        if any(TGToutput{i}.AdzJKC{j}(plottingFreqIndeces))%to ensure it only runs if there is a 1 or else contiguous.m may crash        
            contiguousAdzJKOnes{i}{j}=contiguous(TGToutput{i}.AdzJKC{j},1);
%             contiguousAdzJKOnes{i}{j}=contiguous(TGToutput{i}.AdzJKC{j}(plottingFreqIndeces),1); %show contiguous sig freq
            %between plottingRange only, though may not need this since
            %only plot those in that range below!
            contiguousSigFreq{i}{j}=f(contiguousAdzJKOnes{i}{j}{2}); %uses f to get contig in units of freq
            cSFcolumn2{i}{j}=contiguousSigFreq{i}{j}(:,2);%gives the second column only, useful for end freq value below
            indexMoreThanFR{i}{j}=(contiguousSigFreq{i}{j}(:,2)-contiguousSigFreq{i}{j}(:,1))>frequencyResolution;
            %gives index of where contiguous 1s are over more than
            %frequencyResolution number of frequencies
            if any(indexMoreThanFR{i}{j}) %in case no spots with contiguous 1s
                contiguousMoreThanFR{i}{j}=contiguousSigFreq{i}{j}(indexMoreThanFR{i}{j});%gives starting frequencies where continues more than 2W
                contiguousMoreThanFR{i}{j}(:,2)=cSFcolumn2{i}{j}(indexMoreThanFR{i}{j});%gives the end frequencies
                for k=1:size(contiguousMoreThanFR{i}{j},1)
                    contiguousMoreThanFROnes{i}{j}(f>=contiguousMoreThanFR{i}{j}(k,1) & f<=contiguousMoreThanFR{i}{j}(k,2))=1;
                    %set it equal to 1 where the contiguous frequencies are
                    %more than the frequency resolution
                end
            else
                contiguousMoreThanFR{i}{j}=[];
            end
        else
            contiguousMoreThanFR{i}{j}=[];
        end
    end
end

%%
%calculate TGT p-value for FDR correction calculation of independent values
%based on email from Hemant 4/30/10 the formula is p=2*(1-normcdf(dz,0,1))
%but can replace 1 with vdz since the variance is not normal and vdz is a
%better estimate of the variance from jackknife. Only issue is seems like
%it needs abs of dz with negative values are where rest>task.

%if making new plot will need to know which is higher, but for now just aim
%to put circle around significant ones so don't worry about it and just
%calculate p-value and FDR correction.

clear i; %so can reuse
TGTAll_p=[]; %initialize
for i=1:length(TGToutput) %for each channel
    TGTpAll{i}=(2*(1-normcdf(abs(TGToutput{i}.dz),0,TGToutput{i}.vdz)))';%transpose to be a row, Added All on 3/9/11
    TGTp{i}=TGTpAll{i}(plottingFreqIndeces); %so just calculating within plotting Range
%     TGTp{i}=TGTp{i}(1:TGToutput{i}.K:length(TGTp{i})); %only independent
%     values; removed 8/9/10
    TGTAll_p=[TGTAll_p TGTp{i}]; %one long list of p's for all channels
end
    
    TGTp_f=f(plottingFreqIndeces);
%     TGTp_f=TGTp_f(1:TGToutput{i}.K:length(TGTp_f)); %create a new f for
%     TGTp for plotting; removed 8/9/10
    [TGTp_FDR pN]=AnitaFDR(TGTAll_p,0.05); %gives the overall p-value threshold, a single value, often []
%     [TGTp_FDR{i} pN]=AnitaFDR(TGTp{i},0.05); %gives the p-value
%     threshold, a single value, often [], used by channel
if isempty(TGTp_FDR) %in case AnitaFDR finds no significant corrected p-values, it makes it [] which crashes
    TGTp_FDR=0;
end
 
for ifd=1:length(TGToutput) %for each channel
%     if isempty(TGTp_FDR{i})
%         TGTp_Sig{i}=zeros(size(TGTp{i}));
%     else
        TGTp_Sig{ifd}=TGTp{ifd}<=TGTp_FDR; %put 1s where significant, use to plot circles below
%     end
end

%%
    
    function [pID, pN] = AnitaFDR(p,q)
        %This is Anita's fdr code. Put here to ensure it gets used and not
        %eeglab FDR. 
        % pt = fdr(p,q) does the false discovery rate adjustment
        % p - vector of p-values
        % q - False Discovery Rate level
        %
        % pID - p-value threshold based on independence or positive dependence
        % pN - nonparametric p-value threshold

        p = sort(p(:))';
        V = length(p);
        I = (1:V);

        cVID = 1;
        cVN = sum(1./(1:V));

        pID = p(max(find(p<=I/V*q/cVID)));
        pN = p(max(find(p<I/V*q/cVN)));
    end

%%

sigFreqFigureHandle=figure('Units','normalized','Position',[0 0 1 1]);
% sigFreqFigureHandle=figure('Position',[1 scrsz(4) scrsz(3) scrsz(4)]);



%%
%below plots starting with the front of the head but plotting it at a value equal to the number of channels
%so appears at the top of the plot.

titletext=sprintf('Two group test calculated with p-value: %.2f and 2W Frequency Resolution = %.0f Hz, \nfrom  %.0f to %.0f Hz',TGToutput{1}.p,frequencyResolution, plottingRange(1),plottingRange(2));

set(gcf,'Name',[figuretitle ' - Sig Freq']);
% annotation(figure(gcf),'textbox','String',annotationtext,'FitBoxToText','on','FontSize',9,...
%     'Position',[0.01635 0.5581 0.07671 0.3851]); %this uses normalized
%     units.

%initialize total number of values to save and spit out
totalSigTGT=0;
totalFDRTGT=0;

%below lines added 11/28/11 to only plot a subset of channels for Cruse et
%al. Analysis.
 
 numPlotLines=numChannels+length(spaces);

%  numPlotLines=numChannels+length(spaces);
ir=1;
for ic=1:numChannels %use to get data  
% 
%      %modified for Srivas data 11/28/11
% for id=1:length(SrivasList)
%     ic=SrivasList(id);
    if sum(ic==spaces)==1 %if reached any of the channels that want a space above it
        ir=ir+1;
    end
    for rr1=1:size(contiguousMoreThanFR{ic}{1},1) %for each range of differences
        rectangle('Position',[contiguousMoreThanFR{ic}{1}(rr1,1)-0.15 (numPlotLines-ir+0.6) (contiguousMoreThanFR{ic}{1}(rr1,2)-contiguousMoreThanFR{ic}{1}(rr1,1)+0.3) 0.8],'EdgeColor','r','LineWidth',1);
    end
    for rr2=1:size(contiguousMoreThanFR{ic}{2},1)
        rectangle('Position',[contiguousMoreThanFR{ic}{2}(rr2,1)-0.15 (numPlotLines-ir+0.6) (contiguousMoreThanFR{ic}{2}(rr2,2)-contiguousMoreThanFR{ic}{2}(rr2,1)+0.3) 0.8],'EdgeColor','b','LineWidth',1);
    end
    %        p1=plot(f(plottingFreqIndeces),(numChannels-ic+1).*(contiguousMoreThanFROnes{ic}{1}(plottingFreqIndeces)),'bs');
    hold on;
    %        p2=plot(f(plottingFreqIndeces),(numChannels-ic+1).*(contiguousMoreThanFROnes{ic}{2}(plottingFreqIndeces)),'rs');
    if plotInsigResults %previously would hide these but not doing anymore (8/5/10)
    %           hasbehavior(p1,'legend',false); %this hides the legend of boxes above
    %           hasbehavior(p2,'legend',false);
      p3=plot(f(plottingFreqIndeces),(numPlotLines-ir+1).*(TGToutput{ic}.AdzJKC{1}(plottingFreqIndeces)),'ro','MarkerSize',7,'MarkerFaceColor','r');
      p4=plot(f(plottingFreqIndeces),(numPlotLines-ir+1).*(TGToutput{ic}.AdzJKC{2}(plottingFreqIndeces)),'bo','MarkerSize',7);
      totalSigTGT=totalSigTGT+sum(TGToutput{ic}.AdzJKC{1}(plottingFreqIndeces))+sum(TGToutput{ic}.AdzJKC{2}(plottingFreqIndeces));
    %           p4=plot(f(plottingFreqIndeces),(ic+1).*(TGToutput{ic}.AdzJKC{2}(plottingFreqIndeces)),'ks','MarkerSize',7,'MarkerFaceColor',[.5 .5 .5]);
    end
    %plot FDR corrected independent values where significant as an
    %ellipse
    if any(TGTp_Sig{ic}) %if any significant values
       xlocations=TGTp_f(TGTp_Sig{ic}); %ellipse x location determined by where TGTp_Sig{i} = 1 if it acts as logical
       totalFDRTGT=totalFDRTGT+sum(xlocations>0);
       %below circles suppressed as of 8/12/10
       if plotFDR
        for ifdr=1:length(xlocations)
         rectangle('Position',[xlocations(ifdr)-f(2)/2 (numPlotLines-ir+0.5) f(2) 1],'Curvature',[1],'EdgeColor','k','LineWidth',2.5); %f(2) is spacing between points
        end
       end
    end
    
    line([plottingRange(1) plottingRange(2)],[numPlotLines-ir+1 numPlotLines-ir+1],'LineStyle',':','Color','k'); %put in grid lines manually so can hide ones where there is a space
    %the labels plot from the bottom so flip the order
    if numChannels>100
        yaxisFS=12;
    else
        yaxisFS=18;
    end
    %[] consider replacing the channel names with just text saying left
    %, central , right.
    text('Position',[plottingRange(1)-.1,numPlotLines-ir+1],'String',ChannelListReordered{ic},'HorizontalAlignment','right','FontSize',yaxisFS); %manual ylabel to allow for different fontsize from xlabels
    ir=ir+1;
end
    if legendon
    legend(spectra1label, spectra2label,'Location','NorthEastOutside')

    end

    %%
    %8/12/10 - put in code to spit out and save:
    %[]total number of positive values
    %[]total number of values tested 
    %[]number of positive values with FDR positive.
    totalValues=sum(plottingFreqIndeces)*numChannels;
    percentSig=totalSigTGT/totalValues*100;
    percentSigFDR=totalFDRTGT/totalSigTGT*100;
    fprintf('For %s\n',figuretitle);
    fprintf('Total Significant TGT are %.0f of %.0f total values tested\n',totalSigTGT,totalValues);
    fprintf('Total TGT FDR positive are %.0f (%.2f%%)\n',totalFDRTGT,percentSigFDR);
    saveDataAs=figuretitle;
    saveDataAs(saveDataAs==' ')=[];
    save ([TGTpathname '/' saveDataAs '_Numbers'],'totalValues','totalSigTGT','totalFDRTGT','percentSig','percentSigFDR','TGTpAll');

    %%
    %setting for overall graph and put lines in for bargraph
    % set(gca,'YLim',[0.5 numPlot+0.5],'YTick',[1:numPlot],'YTickLabel',yLabels,...
    %     'XTick',[6:3:24],'XLim',[2 plottingRange(2)],'TickDir','out','TickLength',[0.005 0.005],'fontsize',28);
     set(gca,'YLim',[0.5 ir-.5],'YTick',[],'YTickLabel',[],'XTick',[plottingRange(1):4:plottingRange(2)],'XLim',[plottingRange(1) plottingRange(2)],'TickDir','out','TickLength',[0.005 0.005],'fontsize',28);
%      set(gca,'YLim',[0.5 ir-1],'YTick',[1:ir-1],'YTickLabel',[],'XTick',[plottingRange(1):4:plottingRange(2)],'XLim',[plottingRange(1) plottingRange(2)],'TickDir','out','TickLength',[0.005 0.005],'fontsize',28);


    if legendon
        title(titletext,'FontSize',10);
    end
%     grid on;
     set(gca,'YGrid','off','XGrid','on'); %since want manual x grid lines above
    %%
    if legendon
    else %if legend is off, make the figure fill the screen
        set(gca,'units','normalized','Position',[.04 .07 .94 .9])
    end
    %%
    %save in same location as files
    if plotFDR
        saveFigureAs=[figuretitle '_FDRSigFreq'];
    else
        saveFigureAs=[figuretitle '_SigFreq'];
    end
    saveFigureAs(saveFigureAs==' ')=[]; % to remove spaces in the filename of the figure
    saveas(sigFreqFigureHandle,[TGTpathname '/' saveFigureAs],'fig');
    % saveas(sigFreqFigureHandle,saveFigureAs,'jpg');
    %%
    set(sigFreqFigureHandle,'PaperPositionMode','auto'); %to export the figure the same size as on the screen (full size)
    print(sigFreqFigureHandle,'-dpng','-r0',[TGTpathname '/' saveFigureAs]); %to save the figure as a png file for power point (jpeg works too). -r0 means screen resolution

    %%
    %make topoplot of -logpvalues of fisher
    %need to recreate pdisplay here so is in original order



end