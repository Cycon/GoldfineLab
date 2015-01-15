function [contiguousMoreThanFR,contiguousSigFreq]=plotSigFreq(figuretitle,spectra1label, spectra2label,TGToutput, ChannelList,TGTpathname,Fisherpathname,Fisherfilename,legendon)

%Can be run on own by typing plotSigFreq('figuretitle','spectra 1
%label','spectra 2 label') and then will popup windows for TGT output. Also
%is called from subplotSpectra via subplotSpectraUI. Also called by
%subplotEeglabSpectra and batplotSigFreq.
%
%plots on one graph the areas of significant difference between spectra 1
%and spectra 2 as calculated by the two group test from batTGT.
%exports frequencies that are significant as well as a list of those
%greater than 2W (in boxes). Also Plots Fisher discriminants on the left.
%
% version 1.1 2/26 added option to type in channels that shouldn't be
         % plotted, appears as black line and ensure that spelling is
         % correct. Added legend.
%version 1.2 3/3 give user otpiont to pull in Fisher results and display to
             %left of each channel label. Consider putting slope in as
             %well.
%version 1.3 3/22 calls ChannelListGUI to allow user to choose list of
            %channels to exclude (creates a string of bad channels). Best is to open
            %the subplot PS and then run this program so can have the badlist chooser
            %displayed alongside the plots. Also gives option to use
            %previous saved Badlist (saved by ChannelListGUI)
%version 1.4 3/26/10 puts horizontal bars on the left representing the
            %p-value
%version 1.5 4/6/10 ChannelGUI changed to have table allowing user to select starting frequencies
            %for bad channels. This code needs to take this value and plot
            %x's starting at that value
%version 1.6 6/13/10 [] Put in code to change order of channels to be more
            %like typical eeg (L then R medial then lateral and midline at the end) []
            %put spaces between each group. On 6/15/10 made lots of changes
            %to look including orders
%version 1.7 put spaces between groups as well as add in more input
            %variables so can run in batch mode with batplotSigFreq.
%version 1.8 put in code to plot only independent values of TGT and run FDR and show sig ones
            %needs to 1. have p-value for TGT results, 2. determine which
            %ones are independent, 3. FDR correct and show sig ones, 4.
            %either make new graph or put circles around sig values (or range?) in
            %current graph.
%version 1.9 9/1/10 switched colors red to blue to that red is "more" in
            %task and changed the fishers to start at 0 instead of at 2
            %(previously at 2 so less space but now starting TGT results at
            %4 Hz). Modified save commands to ensure doesn't go to higher
            %directory
%version 2 9/30/10 put star for Fisher results that are 0.05 after FDR.
           %10/26/10 put back option to turn off Fisher results

            
%%
%If called directly, need to get data from subplotSpectra output
if nargin<3
    disp('Next time type plotSigFreq(''figuretitle'',''spectra1label'',''spectra2label''');
    figuretitle=input('figuretitle:','s');
    spectra1label=input('label for spectra 1:','s');
    spectra2label=input('label for spectra 2:','s');
end
if nargin<4
    legendon=1; %so makes legends
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
plotFDR=1; %to turn off FDR circles

plottingRange=[4 24];
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
ChanlocsFile=[]; %so won't plot unless selected
if 1 %changed 6/9/10 to automatically use
% if strcmpi(input('Would you like to display results of Fisher test (y - yes)?','s'),'y')
if nargin>3 && nargin<7 %from subplotEeglabSpectra
    [Fisherfilename, Fisherpathname] = uigetfile('*FisherData.mat', 'Select Fisher Output');
    legendon=1;
elseif nargin <4 %in case calling plotSigFreq on its own
    [Fisherfilename, Fisherpathname] = uigetfile('*FisherData.mat', 'Select Fisher Output or press cancel',TGTpathname);
    legendon=1;
end

if Fisherfilename==0 %if user presses cancel
    plotFisherResults=0;
else
    fisherOutput=load(fullfile(Fisherpathname,Fisherfilename));
    plotFisherResults=1;
end
    
%     [ChanlocsFile, ChanlocsPathname] = uigetfile('*.ced', 'Select Chanlocs file for topoplot or Cancel to not plot','../');
[ChanlocsFile, ChanlocsPathname] = ChanlocsLocation(numChannels); %program that gives location of premade Chanlocs.ced
% ChanlocsFile=0; %turned off for batplotSigFreq
end

%%
%reorder TGToutput, p_value and ChannelList but make sure
%there's one version to match topoplot below.

 %%
    %reorder Channels to be left lateral, left medial, medial, right medial, right lateral per JV (previously did it like typical EEG presentation). TGToutput is
    %organized as one channel per cell so just need to reorder it (not the
    %stuff within it).
    
    if length(ChannelList)==37
        ChannelOrder={'AF7','F7','FC5','T3','CP5','T5','PO7','Fp1', 'F3','F1','FC1','C3','CP1','P3','O1','FPz','Fz','Cz','CPz','Pz','POz','Oz','Fp2','F4','F2','FC2','C4','CP2','P4','O2','AF8','F8','FC6','T4','CP6','T6','PO8'};
            
%         ChannelOrder={'FPz','Fp1','Fp2','AF7','AF8','F7','F3','F1','Fz','F2','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CPz','CP2','CP6','T5','P3','Pz','P4','T6','PO7','O1','POz','Oz','O2','PO8'};
    elseif length(ChannelList)==29
        ChannelOrder={'AF7','F7','FC5','T3','CP5','T5','Fp1','F3','FC1','C3','CP1','P3','O1','Fz','Cz','Pz','Fp2','F4','FC2','C4','CP2','P4','O2','AF8','F8','FC6','T4','CP6','T6'};
%         ChannelOrder={'Fp1','Fp2','AF7','AF8','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CP2','CP6','T5','P3','Pz','P4','T6','O1','O2'};
    else
        fprintf('Unable to match number of channels with channel list for reordering')
        return
    end

    TGToutputReordered=cell(size(TGToutput));
    ChannelListReordered=cell(size(ChannelList));
    if plotFisherResults
        p_orig=fisherOutput.p_segflip;
        p_reordered=cell(size(p_orig));
    end
    for io=1:length(TGToutput) %for each channel
        orderIndex = strcmpi(ChannelOrder{io},ChannelList); %gives a logical vector
        TGToutputReordered{io}=TGToutput{orderIndex};
        ChannelListReordered{io}=ChannelList{orderIndex};
        if plotFisherResults
            p_reordered{io}=p_orig{orderIndex};
        end
    end;

    TGToutput=TGToutputReordered;
    if plotFisherResults
        p_orig=p_reordered;
        pdisplay={0};%initialize it here and below for use later
    end
%     ChannelList=ChannelListReordered;
    if numChannels==37
        ChannelList=cell(1,37+4);
        ChannelList(1:7)=ChannelListReordered(1:7);
        ChannelList(9:16)=ChannelListReordered(8:15);
        ChannelList(18:24)=ChannelListReordered(16:22);
        ChannelList(26:33)=ChannelListReordered(23:30);
        ChannelList(35:41)=ChannelListReordered(31:37);
        if plotFisherResults
            pdisplay=repmat(pdisplay,1,37+4);
        end
    elseif numChannels==29
        ChannelList=cell(1,29+4);
        ChannelList(1:6)=ChannelListReordered(1:6);
        ChannelList(8:14)=ChannelListReordered(7:13);
        ChannelList(16:18)=ChannelListReordered(14:16);
        ChannelList(20:26)=ChannelListReordered(17:23);
        ChannelList(28:33)=ChannelListReordered(24:29);
        if plotFisherResults
            pdisplay=repmat(pdisplay,1,37+4);
        end
    end
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
    TGTp{i}=(2*(1-normcdf(abs(TGToutput{i}.dz),0,TGToutput{i}.vdz)))';%transpose to be a row
    TGTp{i}=TGTp{i}(plottingFreqIndeces); %so just calculating within plotting Range
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

%%% make FDR p-value for Fisher new alpha
if plotFisherResults
    %try first to change p-values of 0 to p-values of 0.001 (1/ numshuffles)
    for ipv=1:length(p_orig)
        p_origModified{ipv}=p_orig{ipv};
        if p_origModified{ipv}==0
            p_origModified{ipv}=1/length(fisherOutput.results{1}.segflip.segflips);
        end
    end

    fisherFDRalpha=AnitaFDR(cell2mat(p_origModified),0.05);
    if isempty(fisherFDRalpha) %if empty, won't work with counting how many or with -log10
        fisherFDRalpha=0;%if empty, makes -log of it infinite so none get * (above change 0s to 1/numflips like 0.001)
    %     fisherFDRalpha=1/length(fisherOutput.results{1}.segflip.segflips); %assign to 1/# of flips which is lowest possible, same as if p=0
    end
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
%to set channels to not plot
badlist={0};
%this part below is in one if loop so none of it runs if press Return
% exclude=input('Would you like to exclude bad channels from summary plot (y - yes, p-use previous, Return-skip)?','s');
%don't use:
exclude=[]; %this feature turned off June 2010 but could turn back on with code line above and remove this line
if strcmpi(exclude,'y')
        badlist=ChannelListGUI(figuretitle,ChannelList);
elseif strcmpi(exclude,'p')
    [filename, pathname] = uigetfile('*BadChannels.mat', 'Select Bad Channel List');
    load(fullfile(pathname,filename)); %this loads previous one and is already called badlist
    if isempty(badlist) %goes on to non GUI method if user selects none from GUI
        badlist=inputbadlist;
        %determine if any in the list typed in don't match spelling correctly
        reruninputbadlist=0;
        for j=1:length(badlist)
            if isempty(badlist{j}) %end when reach an empty cell at end of list
            elseif ~any(strcmp(badlist{j},ChannelList)) %if none of the Channels are spelled the same as one typed in
                fprintf('%s is spelled wrong, start over\n',badlist{j})
                reruninputbadlist=1;
            end
        end
        %if spelling wrong, redo list entry
        if reruninputbadlist
            badlist=inputbadlist;
        end
    end


end

%below for user to input channels they don't want to plot
function badlist=inputbadlist

    fprintf('Which channels would you like to exclude from the significant frequency summary plot?\n')
    disp(ChannelList);
    badlist=input('Enter a cell array of strings like {''Fp1'' ''Fp2''), or press Return to enter one at a time:\n');
    if isempty(badlist)
        disp('Enter 1 at a time, ensure capitilization the same');
        morechannels=1;
        i=1;
        while morechannels
            badlist{i}=input('channel (or Return to stop):','s');
            if isempty(badlist{i});
                morechannels=0;
            end
            i=i+1;
        end
    end    

end

%%
%fisher stuff moved up here so can relocate bars using ir below

%put here if statement for Fisher and then change ChannelLabels. Make new
%variable for Y Labels that by default is flipped ChannelList but changes
%to Fisher Results and then Channel List.
% set(0,'Units','pixels'); %since normalized units
% scrsz = get(0,'ScreenSize');
sigFreqFigureHandle=figure('Units','normalized','Position',[0 0 1 1]);
% sigFreqFigureHandle=figure('Position',[1 scrsz(4) scrsz(3) scrsz(4)]);
yLabels=fliplr(ChannelList); %[] do i need this line?
    
if plotFisherResults
%    percentCorrectXvalid=fliplr(fisherOutput.percentCorrectMapbayesSegs); %not used
%    pvalue=fliplr(fisherOutput.p_segflip);
   pvalue=fliplr(p_orig); %p_orig has been reordered
   ChannelNames=fliplr(ChannelList);
   for iy=1:length(ChannelList)
       if any(strcmp(ChannelNames{iy},badlist(1,:))) %suppress * sign if channel is x'd out
           yLabels{iy}=ChannelNames{iy};
%        elseif pvalue{iy}<=0.05 %turned off 6/16/10 because putting * to right of bar
%            yLabels{iy}=['* ' ChannelNames{iy}];
%        elseif pvalue{iy}<=0.1
%            yLabels{iy}=['* ' ChannelNames{iy}];
       else
           yLabels{iy}=ChannelNames{iy};
%        yLabels{iy}=sprintf('%.2f\t%.2f\t%s',percentCorrectXvalid{iy}, pvalue{iy}, ChannelNames{iy});
       end
   end
   if legendon
    annotationtext=sprintf('* Fisher result p<=0.05 \n using %.0f to %.0f Hz',min(fisherOutput.fpart(1)),max(fisherOutput.fpart(:,2)));
%    annotationtext=sprintf('Fisher Results %.0f to %.0f: \nXvalid%%  p-value',min(fisherOutput.fpart(1)),max(fisherOutput.fpart(:,2)));
    annotation('textbox','FitBoxToText','on','Position',[0.01836 0.9 0.2289 0.055],'String',annotationtext,'FontSize',12);
   end

%%
    %bar graph for significance level. Do -log10 to make it positive and
    %accentuate very small values.
    for ip=1:length(pvalue) %pvalue is flipped p_orig
        if any(strcmp(ChannelNames{ip},badlist(1,:))) %suppress p-value display if channel is x'd out. Note ChannelNames is ChannelList flipped
           pvalue{ip}=1;
        elseif pvalue{ip}==0 %don't want it equal to 0 since will -> inf. So make it smallest non-zero by dividing by # of flips
            pvalue{ip}=1/length(fisherOutput.results{1}.segflip.segflips);
        end
%         pdisplay{ip}=-log10(pvalue{ip})+2; %shouldn't this be in the if loop as a 2nd else? No because it's pdisplay not pvalue.
%         if pvalue{ip}<=0.05
%             text(pdisplay{ip}+.2,ip-.3,'*','FontSize',22)
%         end
    end
%     barh(cell2mat(pdisplay)); %makes horizontal bars at each y level.

end


%%
%below plots starting with the front of the head but plotting it at a value equal to the number of channels
%so appears at the top of the plot.
%futher channels plot at progressively smaller values by subtracting larger
%i's.
% sigFreqFigureHandle=figure;
titletext=sprintf('Two group test calculated with p-value: %.2f and 2W Frequency Resolution = %.0f Hz, \nfrom  %.0f to %.0f Hz',TGToutput{1}.p,frequencyResolution, plottingRange(1),plottingRange(2));

set(gcf,'Name',[figuretitle ' - Sig Freq']);
% annotation(figure(gcf),'textbox','String',annotationtext,'FitBoxToText','on','FontSize',9,...
%     'Position',[0.01635 0.5581 0.07671 0.3851]); %this uses normalized
%     units.

%initialize total number of values to save and spit out
totalSigTGT=0;
totalFDRTGT=0;

%code below is to put spaces between groups of channels
for ic=1:numChannels %use to get data
    %here put in spaces
    numPlot=numChannels+4; %add 4 rows
    ir=ic;    %ir will represent number of plotting lines, use to plot vertically
    if numChannels==37
        if ic>7 && ic<16
            ir=ic+1;
        elseif ic>15 && ic<23
            ir=ic+2;
        elseif ic>22 && ic<31
            ir=ic+3;
        elseif ic>30
            ir=ic+4;
        end
    elseif numChannels==29
        if ic>6 && ic < 14
            ir=ic+1;
        elseif ic>13 && ic<17
            ir=ic+2;
        elseif ic>16 && ic<24
            ir=ic+3;
        elseif ic>23
            ir=ic+4;
        end
    end
    badlistCheck=strcmp(ChannelList{ic},badlist(1,:)); %gives logical of location of ChannelList in badlist if present
    if any(badlistCheck); %if the particular channel matches any channel in the badlist (strcmp produces a vector so need 'any')
        badStartFreq=badlist{2,badlistCheck}; %gets the value of starting freq
        %need to change to only plot x's based on 1st row for old version
        %and new version of badlist has 2nd row with starting frequencies
        %(default to 0). Also need to change to plot this on top of the
        %regular data! So need to plot the regular data first and plot this
        %as well, not instead of. Set the plotting range of x's, to start at
        %plottingRange(1) if if badlist is there or below and to start at
        %badlist if is higher. Set x's to end at plottingRange(2); then
        %need code to plot the actual values from plottingRange(1) to lower
        %bound of badlist ONLY if x's start higher (make a flag).
       
       %next plot clean data below where the x's start (8/5/10 - not sure
       %if this code will work without updating)
       if badStartFreq>plottingRange(1)
           plottingFreqIndecesForXs=(f>=badStartFreq & f<=plottingRange(2));
           plot(f(plottingFreqIndecesForXs),(numChannels-ic+1).*(ones(1,sum(plottingFreqIndecesForXs))),'x','color',[112 138 144]./255,'HandleVisibility','off'); %put ones for all locations, using sum to get 1:150 or whatever
           hold on;
           plottingFreqIndecesForCleanData=(f>=plottingRange(1) & f<=badStartFreq);
           plot(f(plottingFreqIndecesForCleanData),(numChannels-ic+1).*(contiguousMoreThanFROnes{ic}{1}(plottingFreqIndecesForCleanData)),'bs');
           plot(f(plottingFreqIndecesForCleanData),(numChannels-ic+1).*(contiguousMoreThanFROnes{ic}{2}(plottingFreqIndecesForCleanData)),'rs');
            if plotInsigResults
                plot(f(plottingFreqIndecesForCleanData),(numChannels-ic+1).*(TGToutput{ic}.AdzJKC{1}(plottingFreqIndecesForCleanData)),'bo');
                hold on;
                plot(f(plottingFreqIndecesForCleanData),(numChannels-ic+1).*(TGToutput{ic}.AdzJKC{2}(plottingFreqIndecesForCleanData)),'rx');
            end
       else
           plot(f(plottingFreqIndeces),(numChannels-ic+1).*(ones(1,sum(plottingFreqIndeces))),'x','color',[112 138 144]./255,'HandleVisibility','off');
           hold on;
       end
       
    else %***here plot if all channels clean (like with ICA Analysis)***
        
    
        for rr1=1:size(contiguousMoreThanFR{ic}{1},1) %for each range of differences
            rectangle('Position',[contiguousMoreThanFR{ic}{1}(rr1,1)-0.15 (numPlot-ir+0.6) (contiguousMoreThanFR{ic}{1}(rr1,2)-contiguousMoreThanFR{ic}{1}(rr1,1)+0.3) 0.8],'EdgeColor','r','LineWidth',1);
        end
        for rr2=1:size(contiguousMoreThanFR{ic}{2},1)
            rectangle('Position',[contiguousMoreThanFR{ic}{2}(rr2,1)-0.15 (numPlot-ir+0.6) (contiguousMoreThanFR{ic}{2}(rr2,2)-contiguousMoreThanFR{ic}{2}(rr2,1)+0.3) 0.8],'EdgeColor','b','LineWidth',1);
        end
%        p1=plot(f(plottingFreqIndeces),(numChannels-ic+1).*(contiguousMoreThanFROnes{ic}{1}(plottingFreqIndeces)),'bs');
       hold on;
%        p2=plot(f(plottingFreqIndeces),(numChannels-ic+1).*(contiguousMoreThanFROnes{ic}{2}(plottingFreqIndeces)),'rs');
       if plotInsigResults %previously would hide these but not doing anymore (8/5/10)
%           hasbehavior(p1,'legend',false); %this hides the legend of boxes above
%           hasbehavior(p2,'legend',false);
          p3=plot(f(plottingFreqIndeces),(numPlot-ir+1).*(TGToutput{ic}.AdzJKC{1}(plottingFreqIndeces)),'ro','MarkerSize',7,'MarkerFaceColor','r');
          p4=plot(f(plottingFreqIndeces),(numPlot-ir+1).*(TGToutput{ic}.AdzJKC{2}(plottingFreqIndeces)),'bo','MarkerSize',7);
          totalSigTGT=totalSigTGT+sum(TGToutput{ic}.AdzJKC{1}(plottingFreqIndeces))+sum(TGToutput{ic}.AdzJKC{2}(plottingFreqIndeces));
%           p4=plot(f(plottingFreqIndeces),(numPlot-ir+1).*(TGToutput{ic}.AdzJKC{2}(plottingFreqIndeces)),'ks','MarkerSize',7,'MarkerFaceColor',[.5 .5 .5]);
       end
       %plot FDR corrected independent values where significant as an
       %ellipse
       if any(TGTp_Sig{ic}) %if any significant values
           xlocations=TGTp_f(TGTp_Sig{ic}); %ellipse x location determined by where TGTp_Sig{i} = 1 if it acts as logical
           totalFDRTGT=totalFDRTGT+sum(xlocations>0);
           %below circles suppressed as of 8/12/10
           if plotFDR
            for ifdr=1:length(xlocations)
             rectangle('Position',[xlocations(ifdr)-f(2)/2 (numPlot-ir+0.5) f(2) 1],'Curvature',[1],'EdgeColor','k','LineWidth',2.5); %f(2) is spacing between points
            end
           end
       end
       if legendon
        legend(spectra1label, spectra2label,'Location','NorthEastOutside')
    
       end
    end
    if plotFisherResults
        pdisplay{ir}=-log10(pvalue{ic}); %originally +2 until 9/1/10***shifted over two so less space between bars and sig freq plot
%     rectangle('Position',[0 1 plottingRange(1)-.2
%     numPlot+.5],'FaceColor','w','EdgeColor','w'); %need this plotted before * and before bar to hide rectangles
    end
     line([plottingRange(1) plottingRange(2)],[ir ir],'LineStyle',':','Color','k'); %put in grid lines manually so can hide them for the fisher pvalue
     text('Position',[-.1,ir],'String',yLabels{ir},'HorizontalAlignment','right','FontSize',18); %manual ylabel to allow for different fontsize from xlabels
end

%%
%8/12/10 - put in code to spit out and save:
%[]total number of positive values
%[]total number of values tested 
%[]number of positive values with FDR positive.
totalValues=sum(plottingFreqIndeces)*numChannels;
percentSig=totalSigTGT/totalValues*100;
percentSigFDR=totalFDRTGT/totalSigTGT*100;
if plotFisherResults
    totalFD_FDRSig=sum(cell2mat(p_orig)<=fisherFDRalpha);
end
fprintf('For %s\n',figuretitle);
fprintf('Total Significant TGT are %.0f of %.0f total values tested\n',totalSigTGT,totalValues);
fprintf('Total TGT FDR positive are %.0f (%.2f%%)\n',totalFDRTGT,percentSigFDR);
if plotFisherResults
    fprintf('Number of Channels with significant Fisher after FDR corrected alpha of %.3f is: %.0f\n',fisherFDRalpha,totalFD_FDRSig);
end
saveDataAs=figuretitle;
saveDataAs(saveDataAs==' ')=[];
if plotFisherResults
    save ([TGTpathname '/' saveDataAs '_Numbers'],'totalValues','totalSigTGT','totalFDRTGT','percentSig','percentSigFDR','totalFD_FDRSig');
else 
    save ([TGTpathname '/' saveDataAs '_Numbers'],'totalValues','totalSigTGT','totalFDRTGT','percentSig','percentSigFDR');
end


%%
if plotFisherResults
    %put stars on plots for significant Fishers
    %modify 9/30 for p<FDR corrected 0.05 done above near AnitaFDR
    for ipd=1:length(pdisplay)
        if pdisplay{ipd}>=-log10(fisherFDRalpha) %is 1.3 if 0.05 is p-value or dynamically calculate with FDR, earlier code added 2 to this to align right
            text(pdisplay{ipd}+.2,ipd-.3,'*','FontSize',22)
        end
    end

    barh(cell2mat(pdisplay),'FaceColor',[.2 .2 .2]); %makes horizontal bars at each y level.
end


%%
%put lines in two separate chains of channels so clear, need different for
%EMU40 and EKDB12.

if length(TGToutput)==37
    line([0 plottingRange(2)], [8 8], 'Color','k');
    line([0 plottingRange(2)], [17 17], 'Color','k');
    line([0 plottingRange(2)], [25 25], 'Color','k');
    line([0 plottingRange(2)], [34 34], 'Color','k');
elseif length(TGToutput)==29
    line([0 plottingRange(2)], [7 7], 'Color','k');
    line([0 plottingRange(2)], [15 15], 'Color','k');
    line([0 plottingRange(2)], [19 19], 'Color','k');
    line([0 plottingRange(2)], [27 27], 'Color','k');
end
    



%%
%setting for overall graph and put lines in for bargraph
% set(gca,'YLim',[0.5 numPlot+0.5],'YTick',[1:numPlot],'YTickLabel',yLabels,...
%     'XTick',[6:3:24],'XLim',[2 plottingRange(2)],'TickDir','out','TickLength',[0.005 0.005],'fontsize',28);
set(gca,'YLim',[0.5 numPlot+0.5],'YTick',[1:numPlot],'YTickLabel',[],...
    'XTick',[4:4:24],'XLim',[0 plottingRange(2)],'TickDir','out','TickLength',[0.005 0.005],'fontsize',28);


line([1 1],[0 numPlot+.5],'LineStyle',':','Color','k')
line([2 2],[0 numPlot+.5],'LineStyle',':','Color','k')
line([3 3],[0 numPlot+.5],'LineStyle',':','Color','k')
if plotFisherResults
    text(0.6,-.5,'Fisher p =','FontSize',16,'FontAngle','italic','HorizontalAlignment','right')
    text(1,-.8,'.1','FontSize',20,'HorizontalAlignment','center','FontAngle','italic');
    text(2,-.8,'.01','FontSize',20,'HorizontalAlignment','center','FontAngle','italic');
    text(3,-.8,'.001','FontSize',20,'HorizontalAlignment','center','FontAngle','italic');
end
% text(1,0,'-p=0.1','Rotation',-90,'FontSize',14);
% text(2,0,'-p=0.01','Rotation',-90,'FontSize',14);
% text(3,0,'-p=0.001','Rotation',-90,'FontSize',14);
% set(gca,'YLim',[0.5 numChannels+0.5],'YTick',[1:numChannels],'YTickLabel',yLabels,...
%     'XTick',[5:5:plottingRange(2)+(5-mod(plottingRange(2),5))],'XLim',[0 plottingRange(2)+(5-mod(plottingRange(2),5))],'fontsize',14);
if legendon
    title(titletext);
end
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

if ~legend on %if not in batch mode then consider plotting these
    if isempty(input('Plot Fisher topo plot? (Return - no, y-yes): ','s'))
        %don't plot Fisher topo
    else
        ptopo=(fisherOutput.p_segflip);
        for ipt=1:length(ptopo)
            if ptopo{ipt}==0 %don't want it equal to 0 since will -> inf. So make it smallest non-zero by dividing by # of flips
               ptopodisplay{ipt}=1/length(fisherOutput.results{1}.segflip.segflips);
            else
               ptopodisplay{ipt}=-log10(ptopo{ipt});
            end
        end

        if plotFisherTopo
            topoFigHandle=figure;
            set(gcf,'Name',[figuretitle ' - Fisher Topomap']);
            ChanlocsFullfile=fullfile(ChanlocsPathname,ChanlocsFile);
        %     topoplot(fliplr(cell2mat(pdisplay)),ChanlocsFullfile,'maplimits',[0 3]); %runs code from eeglab
            topoplot(cell2mat(ptopodisplay),ChanlocsFullfile,'maplimits',[0 3]); %runs code from eeglab
            %note pdisplay is in flipped order from above so flipped back.
            colorbar('YTick',[1 2 3],'YTickLabel',{'p=0.1','p=0.01','p=0.001'},'FontSize',12); %designed for 1000 segflips
            saveTopoFigureAs=[figuretitle '_FisherTopo'];
            saveTopoFigureAs(saveTopoFigureAs==' ')=[]; % to remove spaces in the filename of the figure
            saveas(topoFigHandle,[TGTpathname '/' saveTopoFigureAs],'fig');
        end
    end
end

end
