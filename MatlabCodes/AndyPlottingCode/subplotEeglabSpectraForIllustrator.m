function subplotEeglabSpectraForIllustrator(~,spectra1label,spectra2label,PS1,pathname1,PS2,pathname2,Fisherpathname,Fisherfilename,SigFreqLegend)

%based on subplotEeglabSpectra (look there for previous versions)
%version 1 Created to plot 1 spectra at at time. figuretitle created
%automatically so replaced above with ~
%10/2/11 modified so doesn't automatically pick the name of the TGT in case
%name was changed from just the two original files placed next to each
%other.
%6/2/13 modified from subplotEeglabSpectraForPowerPoint to not have
%transparancy (add back in illustrator)

disp('This plots one spectra at a time for pasting into power point');
disp('Requires already having TGToutput to use and knowing ylimits');

if nargin<4 %don't if batch mode
    numSpec=input('How many spectra to plot (1,2,3)?: ');
end

%can likely replace these [] since can use numSpec below

% spectra2=[];
% spectra3=[];
if nargin<3
%     figuretitle=input('Figure Title: ','s');
    if numSpec>1
       spectra1label=input('Spectra 1 label (default - swim): ','s');
       if isempty(spectra1label)
           spectra1label='swim';
       end
       spectra2label=input('Spectra 2 label (default - stop): ','s');
       if isempty(spectra2label)
           spectra2label='stop';
       end
       if numSpec==3
          spectra3label=input('Spectra 3 label: ','s'); 
       end
    end
end

if nargin<4 %9/1/10: only for batching of 2 spectra for now
    [PS1, pathname1] = uigetfile('*PS.mat', 'Select First Spectra');
    %if load none, it appears as a 0 so this tells the program to end
    if PS1==0;
        return; 
    else
        spectra1=load(fullfile(pathname1,PS1));
    end;

    if numSpec>1
        [PS2, pathname2] = uigetfile([PS1(1:2) '*PS.mat'], 'Select Second Spectra');
        %PS1(1:2) narrows it to ones with same 1st 2 letters
        spectra2=load(fullfile(pathname2,PS2));
        if numSpec==3
            [PS3,pathname3]=uigetfile('*PS.mat', 'Select Third Spectra');
            spectra3=load(fullfile(pathname3,PS3));
        end
    end
else %if running in batch mode
    spectra1=load(fullfile(pathname1,PS1));
    spectra2=load(fullfile(pathname2,PS2));
    numSpec=2; 
end
%%

%need to determine if channel numbers are the same and eventually program
%ways to plot matching channels
numChannels=spectra1.numChannels;
unequal=0;
ChannelList=spectra1.ChannelList; %this is the default
if numSpec==2
    if ~isequal(spectra1.numChannels,spectra2.numChannels)
        unequal=1; %used to turn off TGT (later figure out how to do this since they have different frequency recorded)
        disp('Different number of channels in the spectra, will change the one with 37 to be 29 like the other');
        if spectra1.numChannels==29 %spectra1 is "correct" so reorder spectra2
            spectra2.numChannels=29;
            ChannelList=spectra1.ChannelList;
            for io=1:length(spectra1.ChannelList) %for each channel in wrong one, ChannelList is 1x29
                orderIndex=strcmpi(spectra1.ChannelList{io},spectra2.ChannelList); %gives logical vector, may need to transpose below
                spectra2.S_ro(:,io)=spectra2.S(:,orderIndex); %dataxchannel
                spectra2.Serr_ro(:,:,io)=spectra2.Serr(:,:,orderIndex); %2xdataxchannel
                spectra2.dataCutByChannel_ro{io}=spectra2.dataCutByChannel{orderIndex}; %cell, not used yet, will need to modify batTGT
            end
            spectra2.S=spectra2.S_ro;
            spectra2.Serr=spectra2.Serr_ro;
            spectra2.dataCutByChannel=spectra2.dataCutByChannel_ro;
        else %if spectra2 is 29 channels (correct one)
            spectra1.numChannels=29;
            ChannelList=spectra2.ChannelList;
            for io=1:length(spectra2.ChannelList) %for each channel in wrong one, ChannelList is 1x29
                orderIndex=strcmpi(spectra2.ChannelList{io},spectra1.ChannelList); %gives logical vector, need to transpose below
                spectra1.S_ro(:,io)=spectra1.S(:,orderIndex); %dataxchannel
                spectra1.Serr_ro(:,:,io)=spectra1.Serr(:,:,orderIndex); %2xdataxchannel
                spectra1.dataCutByChannel_ro{io}=spectra1.dataCutByChannel{orderIndex}; %cell
            end
            spectra1.S=spectra1.S_ro;
            spectra1.Serr=spectra1.Serr_ro;
            spectra1.dataCutByChannel=spectra1.dataCutByChannel_ro;
        end
%         disp('Different number of channels in the spectra')
%         fprintf('%.0f in spectra1, %.0f in spectra2',spectra1.numChannels,spectra2.numChannels);
%     return
    end
end

if numSpec==3
    if ~isequal(spectra1.numChannels,spectra2.numChannels,spectra3.numChannels) %assume spectra 1 has 29 channels
        unequal=1; %used to turn off TGT (later figure out how to do this since they have different frequency recorded)
        disp('Different number of channels in the spectra, will change the one with 37 to be 29 like the other');
        if spectra2.numChannels==37 %spectra1 is "correct" so reorder spectra2
            spectra2.numChannels=29;
            ChannelList=spectra1.ChannelList;
            for io=1:length(spectra2.ChannelList) %for each channel in wrong one, ChannelList is 1x29
                orderIndex=strcmpi(spectra1.ChannelList{io},spectra2.ChannelList); %gives logical vector, may need to transpose below
                spectra2.S_ro(:,io)=spectra2.S(:,orderIndex); %dataxchannel
                spectra2.Serr_ro(:,:,io)=spectra2.Serr(:,:,orderIndex); %2xdataxchannel
                spectra2.dataCutByChannel_ro{io}=spectra2.dataCutByChannel{orderIndex}; %cell, not used yet, will need to modify batTGT
            end
            spectra2.S=spectra2.S_ro;
            spectra2.Serr=spectra2.Serr_ro;
            spectra2.dataCutByChannel=spectra2.dataCutByChannel_ro;
        end
        if spectra3.numChannels==37
            spectra3.numChannels=29;
            ChannelList=spectra1.ChannelList;
            for io=1:length(spectra2.ChannelList) %for each channel in wrong one, ChannelList is 1x29
                orderIndex=strcmpi(spectra1.ChannelList{io},spectra3.ChannelList); %gives logical vector, need to transpose below
                spectra3.S_ro(:,io)=spectra3.S(:,orderIndex); %dataxchannel
                spectra3.Serr_ro(:,:,io)=spectra3.Serr(:,:,orderIndex); %2xdataxchannel
                spectra3.dataCutByChannel_ro{io}=spectra3.dataCutByChannel{orderIndex}; %cell
            end
            spectra3.S=spectra3.S_ro;
            spectra3.Serr=spectra3.Serr_ro;
            spectra3.dataCutByChannel=spectra3.dataCutByChannel_ro;
        end
%         disp('Different number of channels in the spectra')
%         fprintf('%.0f in spectra1, %.0f in spectra2',spectra1.numChannels,spectra2.numChannels);
%     return
    end
end
%%

if ~isfield(spectra1,'ccadata') %for data cleaned with cca tool, likely will remove
    spectra1.ccadata=0;
end

% if ~spectra1.icadata && ~spectra1.ccadata %june 6
if numSpec==1 && isfield(spectra1,'ChannelList')
    ChannelList=spectra1.ChannelList;
else
%put line in here to create it or change code
end
    % end


%%
%Defaults 
plottingRange(1)=input('Beginning of plotting range: ');
plottingRange(2)=input('End of plotting range: ');
ylimits(1)=input('Lower limit for y axis: ');
ylimits(2)=input('Upper limit for y axis: ');
% plottingRange=[0 100]; %range to plot
plottingFreqIndeces=(spectra1.f>=plottingRange(1) & spectra1.f<=plottingRange(2));%need different one for spectra2 if from different headbox



%%
%Run the TGT
% if spectra1.icadata || spectra1.ccadata %removed june 6
%     useTGT=[];
%     TGToutput=[]; %new June 6
% else
if numSpec==2 && ~unequal %so doesn't run if just 1 spectra or if different channel numbers
    if nargin<4
%         useTGT=input('Use file with previous TGToutput (y - yes or Return)?','s');
        useTGT='y';
        if strcmpi(useTGT,'y')
%             [filename4, pathname4] = uigetfile([PS1(1:5) '*List.mat'], 'Select file with TGToutput:');
%             previousResult=load(fullfile(pathname4,filename4));       
            if ~exist(fullfile(pathname1,[PS1(1:end-6) 'TGToutput & contiguousList.mat']),'file')
                [TGTfilename, TGTpathname] = uigetfile('*List.mat', 'Select file with TGToutput:');
                previousResult=load(fullfile(TGTpathname,TGTfilename));
            else
                previousResult=load(fullfile(pathname1,[PS1(1:end-6) 'TGToutput & contiguousList.mat']));
            end
            TGToutput=previousResult.TGToutput;
        else
            TGToutput=[];
        end
    else
        TGToutput=[]; %since want to calculate in batch mode
    end
end

%%
%Run two group test to obtain Adz. Runs only if 2 spectra
%Just below this uses output to calculate and display contiguous
%significant differences > a set value
saveresults=0;
    if numSpec==2 && ~unequal %to ensure only runs if 2 spectra
        if iscell(TGToutput)%if TGT entered as variable, don't rerun
            saveresults=0;
        else
            TGToutput=batTGT(spectra1,spectra2);
            saveresults=1; %save the results of TGT and avgdiff
        end
    end;
% %%
% %run separate plot of significant frequencies, can add column vactor to end to
% %change plotting range
% if numSpec==2 && ~unequal %to ensure only runs if 2 spectra, cant use for ica now
%     
%     if nargin<8
%         [Fisherfilename, Fisherpathname] = uigetfile('*FisherData.mat', 'Select Fisher Output');
%     end
%     if nargin<10 %if legend option not send in from calling command
%         if isequal(input('Want legend in SigFreqPlot? (y-yes, otherwise no)','s'),'y')
%             SigFreqLegend=1;
%         else
%             SigFreqLegend=0;
%         end
%     end
%         [contiguousMoreThanFR,contiguousSigFreq]=plotSigFreq(figuretitle,spectra1label, spectra2label,TGToutput, ChannelList,pathname1,Fisherpathname,Fisherfilename,SigFreqLegend);
%         %1 or 0 at end determines if legend on or off in plotSigFreq
%         %pathname1 is to save summary results in folder of spectra1
% end

 

%%
%plot
for ic=1:length(spectra1.ChannelList)
    fprintf('%.0f: %s\n',ic,spectra1.ChannelList{ic});
end
plotNumber=input('Choose channel number to plot: ');
figuretitle=[PS1(1:end-4) '_' spectra1.ChannelList{plotNumber}];

%%
%subplot the spectra with appropriate titles
numrows=ceil(sqrt(numChannels));
numcols=floor(sqrt(numChannels));
if numrows*numcols<numChannels
    numcols=numcols+1;
end;

PSfigure=figure;
% set(gcf,'Name',savename, 'Position',[1 1 scrsz(3)*0.8 scrsz(4)*0.9]);
set(gcf,'Name',[figuretitle],'Units','normalized','Position',[0 0 .99 .95]);

%%
for j = plotNumber
%  for j=16 %to just plot one to blow up and copy for a figure
%   subplot(numrows,numcols,j);

%new with fill. You fill([xaxis fliplr(xaxis)],[yconfi1 fliplry(confi2)])
%assuming both are row vectors. or can do (end:-1:1) instead of fliplr
   fpFI1=spectra1.f(plottingFreqIndeces); %just to make coding of fill easier, means frequencies at plotting freq indeces for spectra1
%    reversepFI=fliplr(plottingFreqIndeces);
   errorBars1=fill([fpFI1 fpFI1(end:-1:1)],[10*log10(spectra1.Serr(1,(plottingFreqIndeces),j)) fliplr(10*log10(spectra1.Serr(2,(plottingFreqIndeces),j)))],'r','HandleVisibility','off');
%    set(errorBars1,'linestyle','none','facealpha',0.3); %to make the fill transparent
   set(errorBars1,'linestyle','none');
   hold on;
   plot(spectra1.f(plottingFreqIndeces),10*log10(spectra1.S((plottingFreqIndeces),j)),'r','LineWidth',2); %f is not normalized unlike with browser 
%    plot(spectra1.f(plottingFreqIndeces),10*log10(spectra1.Serr(:,(plottingFreqIndeces),j)),'r-.','HandleVisibility','off'); 
%   set(gca,'xtick',[plottingRange(1):5:plottingRange(2)],'FontSize',12); %this sets the xticks every 5
    set(gca,'xtick',[plottingRange(1):4:plottingRange(2)],'FontSize',32,'Ylim',ylimits,'Xlim',plottingRange); %for paper figure
   ylimPlot=ylim; %ylim here can be reset below to ensure negative TGT results are off the screen 
%   grid on; %this turns grid on
  grid off; %

  hold('all'); %this is for the xticks and grid to stay on
  if numSpec>1
      plottingFreqIndeces2=(spectra2.f>=plottingRange(1) & spectra2.f<=plottingRange(2));%since different from spectra1 possibly
      fpFI2=spectra2.f(plottingFreqIndeces); 
      errorBars2=fill([fpFI2 fpFI2(end:-1:1)],[10*log10(spectra2.Serr(1,(plottingFreqIndeces2),j)) fliplr(10*log10(spectra2.Serr(2,(plottingFreqIndeces2),j)))],'b','HandleVisibility','off');
%       set(errorBars2,'linestyle','none','facealpha',0.3); %to make the fill transparent 
      set(errorBars2,'linestyle','none');
      plot(spectra2.f(plottingFreqIndeces2),10*log10(spectra2.S((plottingFreqIndeces2),j)),'b-.','LineWidth',2);
%       plot(spectra2.f(plottingFreqIndeces2),10*log10(spectra2.Serr(:,(plottingFreqIndeces2),j)),'b-.','HandleVisibility','off');
        legend(spectra1label,spectra2label); %can change to turn off legend
      if numSpec==3
         plottingFreqIndeces3=(spectra3.f>=plottingRange(1) & spectra3.f<=plottingRange(2));%since different from spectra1 possibly
         plot(spectra3.f(plottingFreqIndeces3),10*log10(spectra3.S((plottingFreqIndeces3),j)),'g','LineWidth',2);
         plot(spectra3.f(plottingFreqIndeces3),10*log10(spectra3.Serr(:,(plottingFreqIndeces3),j)),'g-.','HandleVisibility','off');
         legend(spectra1label,spectra2label,spectra3label); %can change to turn off legend
      end
  end
  
  if spectra1.icadata
      title(sprintf('ICA %.0f',j),'FontSize',14);
  elseif spectra1.ccadata
      EMGrange=(spectra1.f>=15 & spectra1.f<=100);
      EEGrange=(spectra1.f>=0 & spectra1.f<=15);
      minvalue = min(10*log10(spectra1.S(plottingFreqIndeces,j)));
      ratio=(mean(10*log10(spectra1.S(EMGrange,j)))-minvalue)./(mean(10*log10(spectra1.S(EEGrange,j)))-minvalue);
      title(sprintf('CCA %.0f %.2f',j,ratio),'FontSize',14);
  else
       title(spectra1.ChannelList(j),'FontSize',32);
  end
  
%%
%plot TGT results
  plotTGT=1; %so can suppress TGT tresults
    if numSpec==2 && ~unequal
        if plotTGT
        %here plot results of JK sig test from two group test
        TGTplottingFreqIndeces=(plottingRange(1)<=TGToutput{j}.f & TGToutput{j}.f<=plottingRange(2));
%         TGToutput{j}.AdzJK(TGToutput{j}.AdzJK==0)=-10; %so doesn't appear on the graph but needs to be out of Ylim determined earlier
        SigTGTPlot=TGToutput{j}.f(TGToutput{j}.AdzJK==1); %frequencies where TGT is significant for plotting (this way only have + values)
        minvalueS=min([10*log10(spectra1.S(plottingFreqIndeces2,j))' 10*log10(spectra2.S(plottingFreqIndeces2,j))']); %for plotting it in a good spot, below lowest value
        if ~sum(SigTGTPlot)==0 && min(SigTGTPlot)<plottingRange(2) && max(SigTGTPlot)>plottingRange(1) %to ensure that some exist and are between plotting Range
            plot(SigTGTPlot(plottingRange(1)<=SigTGTPlot & SigTGTPlot<=plottingRange(2)),(minvalueS-1),'k*','MarkerSize',12); %plot it in range desired, 5 below min value
        end
%         plot(TGToutput{j}.f(TGTplottingFreqIndeces),TGToutput{j}.AdzJK(TGTplottingFreqIndeces)*(minvalue-5),'k*','MarkerSize',12); 
%         plot(TGToutput{j}.f(TGTplottingFreqIndeces),TGToutput{j}.AdzJK(TGTplottingFreqIndeces)*10,'k*','MarkerSize',12);
%         set(gca,'ytick',(5:5:50),'FontSize',20); %added this and below 6/8/10 for paper
%         axis([plottingRange(1) plottingRange(2) 5 50]);
        end;
%         set(gca,'Ylim',ylimPlot); %from above
    end
end     

%%
% allowaxestogrow;
saveFigureAs=[figuretitle '_PS'];
saveFigureAs(saveFigureAs==' ')=[]; % to remove spaces in the filename of the figure
saveas(PSfigure,saveFigureAs,'fig');%to save the figure
% print(PSfigure,'-dpng','-r0',[pathname1 '/' saveFigureAs]); %to save the figure as a png file
%%
%save results of TGT calculations
if saveresults %if previous TGToutput not entered, then save its results
        savename=[figuretitle '_TGToutput & contiguousList'];
        save(savename,'contiguousMoreThanFR','contiguousSigFreq','ChannelList','TGToutput');
end