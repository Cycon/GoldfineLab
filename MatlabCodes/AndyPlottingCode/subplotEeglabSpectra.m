function subplotEeglabSpectra(figuretitle,spectra1label,spectra2label,PS1,pathname1,PS2,pathname2,SigFreqLegend)

%based on subplotSpectra (look there for previous versions)
%version 2 6/15/10 add option to plot 3 spectra
%version 3 6/29/10 allow to plot 29 vs 37 channels (only plot the 29)
%version 4 9/1/10 allow for calling fully from another code for batching
%and switch colors. Add Fisherpathname and Fisherfilename to be
%used by plotSigFreq. SigFreqLegend is to send to plotSigFreq plot
%version 5 8/26/11 change error bars to shading and call colors from a list
%and replace spectra1 with spectra{1} for shorter coding
%11/23/11 fixed issue where data have different frequency grids so need
%individualized plottingFreqRange
%11/25/11 changed uigetfile to uipickfiles
%12/5/11 Version 6 - [] Set it run code of calcDifferenceMap and save the
%output in the TGT file then modify plotDifferenceMap to open TGTfile first
%and if this is present run, if not then do the calculation in it;
%[] make modified version of this to plot the
%single spectra like the
%PowerPoint version so don't need two codes. Also remove References to
%Fisher since not used anymore. [x] Removed ccadata
%12/5/11 set figure to not be visible so won't kill memory. Requires openfig be
%modified (new version created in my folder on top of path) where: visible='visible';
%12/16/11 fixed errror in loading previous TGToutput where is was comging
%in as a structure
%12/17/11 version 7 code written below to plot spectra of derivative of data (simply multiply
%by f.^2).
%12/22/11 version 8 now calls calcDifferenceMap and saves output
%in the TGT file which can be called by plotDifferenceMap. []
%Figure out if can save TGT without SigFreq plot (right now output
%of Sig Freq plot required to create variables to save)
%5/9/12 version 9 allow to change xlim with a gui in the figure so don't
%need to decide ahead of time. Later fixed error where crash if no
%significant difference in a channel by detecting handles=0 and skipping
%them (see subfunction).
%5/28/12 bug where if only one spectra (or 3) then no TGTplot so put if
%statement to catch this in x-axis modification part of code
%6/8/13 fixed bug where if 29 channels in one and 37 in other, if picked
%the 37 channel one first it didn't work. Now ensures plots the same 29
%channels for both.

deriv=0;
if nargin<4 %don't if batch mode
    numSpec=input('How many spectra to plot (1,2,3)?: ');
    if isempty(numSpec)
        disp('Need to type in number of spectra to plot');
        return
    end
    deriv=input('Plot spectra of derivative (multiply by f^2) (1/0) [0]?: ');
end

if strcmpi(input('Use Cruse et al. channels only? (y/n) [n]: ','s'),'y')
    useCruse=1;
else
    useCruse=0;
end

plotsigfreq=1;
if nargin<1 && numSpec==2
    if ~isequal(input('Plot Sig Freq plot? (y-yes, otherwise no)','s'),'y')
        plotsigfreq=0;
    end
end

spectra{2}=[];
spectra{3}=[];
if nargin<3
    figuretitle=input('Figure Title (or return to use .mat file name(s)): ','s');
    if numSpec>1 && plotsigfreq %since only use legend in sigfreq plot
        spectra1label=input('Spectra 1 label (optional): ','s');
        spectra2label=input('Spectra 2 label (optional): ','s');
        if numSpec==3
            spectra3label=input('Spectra 3 label (optional): ','s');
        end
    end
end

if nargin<4 %9/1/10: only for batching of 2 spectra for now
    for nss=1:numSpec
        prompttext=sprintf('Select spectra %.0f',nss);
        if nss==1 %for first one
            PSfile(nss)=uipickfiles('type',{'*PS.mat','spectra from PSeeglab'},'num',1,'prompt',prompttext);
        else %for further ones go to same folder as first by default
            PSfile(nss)=uipickfiles('type',{'*PS.mat','spectra from PSeeglab'},'num',1,'prompt',prompttext,'FilterSpec',fileparts(PSfile{1}));
        end
        %     [PS1, pathname1] = uigetfile('*PS.mat', 'Select First Spectra');
        %if load none, it appears as a 0 so this tells the program to end
        if isempty(PSfile) || isnumeric(PSfile) %two options in case press cancel or done with no selection
            return;
        else
            spectra{nss}=load(PSfile{nss});
        end;
    end
    
    for ppp=1:length(PSfile) %since uipickfile gives all as one variable
        [pathname{ppp},PSfilename{ppp}]=fileparts(PSfile{ppp});
    end
    %     if numSpec>1
    %         [PS2, pathname2] = uigetfile('*PS.mat', 'Select Second Spectra');
    %         spectra{2}=load(fullfile(pathname2,PS2));
    %         if numSpec==3
    %             [PS3,pathname3]=uigetfile('*PS.mat', 'Select Third Spectra');
    %             spectra{3}=load(fullfile(pathname3,PS3));
    %         end
    %     end
    
    if isempty(figuretitle) %give file name if not entered above
        if numSpec==1
            figuretitle=PSfilename{1}(1:end-3);
        elseif numSpec==2
            figuretitle=[PSfilename{1}(1:end-3) 'vs' PSfilename{2}(1:end-3)];
        elseif numSpec==3
            figuretitle=[PSfilename{1}(1:end-3) 'vs' PSfilename{2}(1:end-3) 'vs' PSfile{3}(1:end-3)];
        end
    end
    
    %added 11/25/11 when changed from uigetfile to uipickfiles
    pathname1=pathname{1};%to get the pathname out of it
else %if running in batch mode with all variables sent to this code
    spectra{1}=load(fullfile(pathname1,PS1));
    spectra{2}=load(fullfile(pathname2,PS2));
    numSpec=2; %if running in batch mode
end

if deriv
    figuretitle=[figuretitle '_deriv'];
end
%%

%need to determine if channel numbers are the same and eventually program
%ways to plot matching channels
numChannels=spectra{1}.numChannels;
unequal=0; % to manually turn off TGT when set to 1
ChannelList=spectra{1}.ChannelList; %this is the default
if numSpec==2
    if ~isequal(spectra{1}.numChannels,spectra{2}.numChannels)
        unequal=1; %used to turn off TGT (later figure out how to do this since they have different frequency recorded)
        numChannels=min([spectra{1}.numChannels,spectra{2}.numChannels]);%added 6/8/13
        disp('Different number of channels in the spectra, will change the one with 37 to be 29 like the other, may not be accurate if Laplacian');
        if spectra{1}.numChannels==29 %spectra{1} is "correct" so reorder spectra{2}
            spectra{2}.numChannels=29;
            ChannelList=spectra{1}.ChannelList;
            for io=1:length(spectra{1}.ChannelList) %for each channel in wrong one, ChannelList is 1x29
                orderIndex=strcmpi(spectra{1}.ChannelList{io},spectra{2}.ChannelList); %gives logical vector, may need to transpose below
                spectra{2}.S_ro(:,io)=spectra{2}.S(:,orderIndex); %dataxchannel
                spectra{2}.Serr_ro(:,:,io)=spectra{2}.Serr(:,:,orderIndex); %2xdataxchannel
                spectra{2}.dataCutByChannel_ro{io}=spectra{2}.dataCutByChannel{orderIndex}; %cell, not used yet, will need to modify batTGT
            end
            spectra{2}.S=spectra{2}.S_ro;
            spectra{2}.Serr=spectra{2}.Serr_ro;
            spectra{2}.dataCutByChannel=spectra{2}.dataCutByChannel_ro;
        else %if spectra{2} is 29 channels (correct one)
            spectra{1}.numChannels=29;
            ChannelList=spectra{2}.ChannelList;
            for io=1:length(spectra{2}.ChannelList) %for each channel in wrong one, ChannelList is 1x29
                orderIndex=strcmpi(spectra{2}.ChannelList{io},spectra{1}.ChannelList); %gives logical vector, need to transpose below
                spectra{1}.S_ro(:,io)=spectra{1}.S(:,orderIndex); %dataxchannel
                spectra{1}.Serr_ro(:,:,io)=spectra{1}.Serr(:,:,orderIndex); %2xdataxchannel
                spectra{1}.dataCutByChannel_ro{io}=spectra{1}.dataCutByChannel{orderIndex}; %cell
            end
            spectra{1}.S=spectra{1}.S_ro;
            spectra{1}.Serr=spectra{1}.Serr_ro;
            spectra{1}.dataCutByChannel=spectra{1}.dataCutByChannel_ro;
        end
        %         disp('Different number of channels in the spectra')
        %         fprintf('%.0f in spectra{1}, %.0f in spectra{2}',spectra{1}.numChannels,spectra{2}.numChannels);
        %     return
    end
end

if numSpec==3
    if ~isequal(spectra{1}.numChannels,spectra{2}.numChannels,spectra{3}.numChannels) %assume spectra 1 has 29 channels
        unequal=1; %used to turn off TGT (later figure out how to do this since they have different frequency recorded)
         numChannels=min([spectra{1}.numChannels,spectra{2}.numChannels,spectra{3}.numChannels]);%added 6/8/13
        disp('Different number of channels in the spectra, will change the one with 37 to be 29 like the other');
        if spectra{2}.numChannels==37 %spectra{1} is "correct" so reorder spectra{2}
            spectra{2}.numChannels=29;
            ChannelList=spectra{1}.ChannelList;
            for io=1:length(spectra{2}.ChannelList) %for each channel in wrong one, ChannelList is 1x29
                orderIndex=strcmpi(spectra{1}.ChannelList{io},spectra{2}.ChannelList); %gives logical vector, may need to transpose below
                spectra{2}.S_ro(:,io)=spectra{2}.S(:,orderIndex); %dataxchannel
                spectra{2}.Serr_ro(:,:,io)=spectra{2}.Serr(:,:,orderIndex); %2xdataxchannel
                spectra{2}.dataCutByChannel_ro{io}=spectra{2}.dataCutByChannel{orderIndex}; %cell, not used yet, will need to modify batTGT
            end
            spectra{2}.S=spectra{2}.S_ro;
            spectra{2}.Serr=spectra{2}.Serr_ro;
            spectra{2}.dataCutByChannel=spectra{2}.dataCutByChannel_ro;
        end
        if spectra{3}.numChannels==37
            spectra{3}.numChannels=29;
            ChannelList=spectra{1}.ChannelList;
            for io=1:length(spectra{2}.ChannelList) %for each channel in wrong one, ChannelList is 1x29
                orderIndex=strcmpi(spectra{1}.ChannelList{io},spectra{3}.ChannelList); %gives logical vector, need to transpose below
                spectra{3}.S_ro(:,io)=spectra{3}.S(:,orderIndex); %dataxchannel
                spectra{3}.Serr_ro(:,:,io)=spectra{3}.Serr(:,:,orderIndex); %2xdataxchannel
                spectra{3}.dataCutByChannel_ro{io}=spectra{3}.dataCutByChannel{orderIndex}; %cell
            end
            spectra{3}.S=spectra{3}.S_ro;
            spectra{3}.Serr=spectra{3}.Serr_ro;
            spectra{3}.dataCutByChannel=spectra{3}.dataCutByChannel_ro;
        end
        %         disp('Different number of channels in the spectra')
        %         fprintf('%.0f in spectra{1}, %.0f in spectra{2}',spectra{1}.numChannels,spectra{2}.numChannels);
        %     return
    end
end
%%

if numSpec==1 && isfield(spectra{1},'ChannelList')
    ChannelList=spectra{1}.ChannelList;
else
    %put line in here to create it or change code
end
% end


%%
%Defaults
% plottingRange=[0 40]; %range to plot
% if nargin<8 %if not in batch mode
%     fprintf('Plotting range set at %.0f to %.0f Hz\n',plottingRange(1), plottingRange(2));
%     if strcmpi(input('Change plotting frequency range? (y or Return): ','s'),'y')
%         plottingRange(1)=input('Starting value: ');
%         plottingRange(2)=input('Ending value: ');
%     end
% end
%11/23/11 make this different for each spectra since not necessarily the
%same if they are from data of different length swatches for example. Needs
%to be in a cell because they can be different lengths

% plottingFreqIndeces=(spectra{1}.f>=plottingRange(1) & spectra{1}.f<=plottingRange(2));%need different one for spectra{2} if from different headbox
% for ppp=1:numSpec
%     plottingFreqIndeces{ppp}=(spectra{ppp}.f>=plottingRange(1) & spectra{ppp}.f<=plottingRange(2));
% end




%%
if numSpec==2 && ~unequal %so doesn't run if just 1 spectra or if different channel numbers
    if nargin<4
        useTGT=input('Use file with previous TGToutput (y - yes or Return)?','s');
        if strcmpi(useTGT,'y')
            %             [filename4, pathname4] = uigetfile('*List.mat', 'Select file with TGToutput:');
            TGTfilename=uipickfiles('type',{'*List.mat','TGToutput'},'num',1,'prompt','Select file with TGToutput:');
            load(TGTfilename{1},'TGToutput');%modified 11/29/11
            %             TGToutput=previousResult.TGToutput;
        else
            TGToutput=[];
        end
    else
        TGToutput=[]; %since want to calculate in batch mode
    end
end

%Run two group test to obtain Adz. Runs only if 2 spectra
%Just below this uses output to calculate and display contiguous
%significant differences > a set value
saveresults=0;
if numSpec==2 && ~unequal %to ensure only runs if 2 spectra
    if iscell(TGToutput)%if TGT entered as variable, don't rerun
        saveresults=0;
    else
        TGToutput=batTGT(spectra{1},spectra{2});
        %add call to calcDiffMap Here
        if plotsigfreq %because saves output from plotSigFreqSimple!
            saveresults=1; %save the results of TGT and avgdiff
        end
        
    end
end;
%%
%run separate plot of significant frequencies, can add column vactor to end to
%change plotting range
if plotsigfreq %can be turned off at beginning of this code
    if numSpec==2 && ~unequal %to ensure only runs if 2 spectra, cant use for ica now
        
        if nargin<8 %if legend option not send in from calling command
            if isequal(input('Want legend in SigFreqPlot? (y-yes, otherwise no)','s'),'y')
                SigFreqLegend=1;
            else
                SigFreqLegend=0;
            end
        end
        %2/24/11 set to always use Simple though need to put spaces in it
        [contiguousMoreThanFR,contiguousSigFreq]=plotSigFreqSimple(figuretitle,spectra1label, spectra2label,TGToutput, ChannelList,pathname1,SigFreqLegend);
        %
        %         if numChannels==35 || Fisherpathname==0
        %             [contiguousMoreThanFR,contiguousSigFreq]=plotSigFreqSimple(figuretitle,spectra1label, spectra2label,TGToutput, ChannelList,pathname1,SigFreqLegend);
        %         else
        %             [contiguousMoreThanFR,contiguousSigFreq]=plotSigFreq(figuretitle,spectra1label, spectra2label,TGToutput, ChannelList,pathname1,Fisherpathname,Fisherfilename,SigFreqLegend);
        %             %1 or 0 at end determines if legend on or off in plotSigFreq
        %             %pathname1 is to save summary results in folder of spectra{1}
        %         end
    end
end

%%
%subplot the spectra with appropriate titles
if size(spectra{1}.S,2)==129
    CruseList=[6    7   13   29   30   31   35   36   37   41   42   54   55   79 80   87   93  103  104  105  106  110  111  112  129];
elseif size(spectra{1}.S,2)==257
    CruseList=[8    9   17   43   44   45   52   53   58   65   66   80   81  131  132  144  164  182  184  185  186  195  197  198  257];
end
if useCruse
    numChannels=length(CruseList);
end
numrows=ceil(sqrt(numChannels));
numcols=floor(sqrt(numChannels));
if numrows*numcols<numChannels
    numcols=numcols+1;
end;

% scrsz = get(0,'ScreenSize'); %for defining the figure size
PSfigure=figure;

% set(gcf,'Name',savename, 'Position',[1 1 scrsz(3)*0.8 scrsz(4)*0.9]);
%12/5/11 set to not be visible so won't kill memory. Requires openfig be
%modified so visible='visible';
set(gcf,'Name',[figuretitle '_PS'],'Units','normalized','Position',[0 0 .99 .95]);
if nargin >4 %if in batch mode
    set(gcf,'visible','off');
end

%%

%plot
%8/26 make for loop for each line calling from color list
colorlist={'r','b','g'};
if useCruse
    plotindex=CruseList;
else
    plotindex=1:numChannels;
end
pnum=1;%added since plotindex might not start with 1
for j = plotindex
    
    %  for j=16 %to just plot one to blow up and copy for a figure
    h.spectraPlot(pnum)=subplot(numrows,numcols,pnum);
    for ns=1:numSpec %new 8/26.
        fplot=spectra{ns}.f;%5/9/12 now plot all but can change later
        hold on;
        if deriv %if want to plot spectra of derivative of data
            errorBars(ns)=fill([fplot fliplr(fplot)],[10*log10(spectra{ns}.Serr(1,:,j).*fplot.^2) fliplr(10*log10(spectra{ns}.Serr(2,:,j).*fplot.^2))],colorlist{ns},'HandleVisibility','callback');
            plot(fplot,10*log10(spectra{ns}.S((plottingFreqIndeces{ns}),j).*fplot'.^2),colorlist{ns},'LineWidth',2); %f is not normalized unlike with browser
        else
            errorBars(ns)=fill([fplot fliplr(fplot)],[10*log10(spectra{ns}.Serr(1,:,j)) fliplr(10*log10(spectra{ns}.Serr(2,:,j)))],colorlist{ns},'HandleVisibility','callback');
            plot(fplot,10*log10(spectra{ns}.S(:,j)),colorlist{ns},'LineWidth',2); %f is not normalized unlike with browser
        end
        %[] may want to restore the x-spacing later 5/9/12
        %         set(gca,'xtick',[plottingRange(1):5:plottingRange(2)],'FontSize',12); %this sets the xticks every 5
        %     set(gca,'xtick',[plottingRange(1):3:plottingRange(2)],'FontSize',32,'Ylim',[10 40],'Xlim',plottingRange); %for paper figure
        %         ylimPlot=ylim; %ylim here can be reset below to ensure negative TGT results are off the screen
        grid on; %this turns grid on
        %  grid off; %JUNE 30 FOR MARY
        hold('all'); %this is for the xticks and grid to stay on
    end
    set(errorBars,'linestyle','none','facealpha',0.3); %to make the fill transparent
    
    
    if spectra{1}.icadata
        title(sprintf('ICA %.0f',pnum),'FontSize',14);
    else %here can modify if title appears above or within the subplot
        %                title(spectra{1}.ChannelList(j),'FontSize',16);
        text('Units','normalized','Position',[.5 .9],'string',spectra{1}.ChannelList(j),'FontSize',14,'HorizontalAlignment','center');
    end
    %      legend(spectra1label); %can change to turn off legend
    
    %%
    %plot TGT results
    %5/9/12 [] determine the bottom of the y-axis and then plot there -
    %once can change the pfr, need to also change the y-location property
    %of these so need a handle for them!
    plotTGT=1; %so can suppress TGT tresults
    if numSpec==2 && ~unequal
        if plotTGT
            %here plot results of JK sig test from two group test
            %             TGTplottingFreqIndeces=(plottingRange(1)<=TGToutput{j}.f & TGToutput{j}.f<=plottingRange(2));
            %         TGToutput{j}.AdzJK(TGToutput{j}.AdzJK==0)=-10; %so doesn't appear on the graph but needs to be out of Ylim determined earlier
            SigTGTPlot=TGToutput{j}.f(TGToutput{j}.f<=max(spectra{1}.f) & (TGToutput{j}.AdzJK==1)'); %frequencies where TGT is significant for plotting (this way only have + values)
            %and added in the <max(spectra{1}.f since otherwise it goes to twice that value
            
            %         if ~sum(SigTGTPlot)==0 && min(SigTGTPlot)<plottingRange(2) && max(SigTGTPlot)>plottingRange(1) %to ensure that some exist and are between plotting Range
            if ~sum(SigTGTPlot)==0 %to ensure that some exist
                h.TGTplot(pnum)=plot(SigTGTPlot,repmat(min(get(h.spectraPlot(pnum),'ylim')),1,length(SigTGTPlot)),'k*','MarkerSize',12); %plot at bottom of y-axis
            end
            %         plot(TGToutput{j}.f(TGTplottingFreqIndeces),TGToutput{j}.AdzJK(TGTplottingFreqIndeces)*(minvalue-5),'k*','MarkerSize',12);
            %         plot(TGToutput{j}.f(TGTplottingFreqIndeces),TGToutput{j}.AdzJK(TGTplottingFreqIndeces)*10,'k*','MarkerSize',12);
            %         set(gca,'ytick',(5:5:50),'FontSize',20); %added this and below 6/8/10 for paper
            %         axis([plottingRange(1) plottingRange(2) 5 50]);
        end;
        %         set(gca,'Ylim',ylimPlot); %from above
    end
    axis tight; %in case don't plot full range
    pnum=pnum+1;%this is the plot number
end

%%
% allowaxestogrow;

%%
%GUI to determine x-limits and then move the TGT results to the bottom of
%the y-axis
uicontrol('style','edit','units','normalized','position',[0.01 .9 .03 .03],'string','2','callback',{@modXlim1,h});
uicontrol('style','edit','units','normalized','position',[0.03 .9 .03 .03],'string','40','callback',{@modXlim2,h});

%GUI to hide the TGT results (per J Bardin request 5/9/12)
uicontrol('style','checkbox','units','normalized','position',[0.01 .85 .06 .03],'string','TGT','Value',1,'callback',{@hideTGT,h});
set(PSfigure,'toolbar','figure');

%%
saveFigureAs=[figuretitle '_PS'];
saveFigureAs(saveFigureAs==' ')=[]; % to remove spaces in the filename of the figure
saveas(PSfigure,saveFigureAs,'fig');%to save the figure

%%
%save results of TGT calculations and run calcSpecDifference
if saveresults %if previous TGToutput not entered, then save its results
    %     if plotsigfreq %since variables not created if no sigFreq plot
    [actualDiff,f,f_pvalue,p_value,params]=calcSpecDifference(spectra,TGToutput);
    %note that as of 8/12/13 calcSpecDifference produces differences in
    %units of dB not just log10.
    savename=[figuretitle '_TGToutput & contiguousList'];
    save(savename,'actualDiff','f','f_pvalue','p_value','contiguousMoreThanFR','contiguousSigFreq','ChannelList','TGToutput','params');
    %     end
end

%%
%figure subcode here to modify the x limits and the y-location of the
%TGTplot just in case it shifts a little
    function modXlim1(src,event,h)
        currentYlim=cell2mat(get(h.spectraPlot,'Ylim'));%just want the first column
        currentXlim=get(h.spectraPlot,'Xlim');
        if isfield(h,'TGTplot')
            currentTGTstate=get(h.TGTplot,'visible');%in case have them hidden, dont want to reappear now
            set(h.TGTplot,'visible','off');%so not used in determination of yaxis
        end
        set(h.spectraPlot,'Xlim',[str2double(get(src,'string')) currentXlim{1}(2)],'YLimMode','auto');
        %then ensure that the TGTplot appears on the x-axis. The h.TGTplot
        %ydata and h.spectraPlot ylim come as cells.
        newYlim=cell2mat(get(h.spectraPlot,'Ylim'));
        if isfield(h,'TGTplot')
            validTGTplotIndex=find(h.TGTplot);%determine where it's not zero since might be no significant difference
            
            %the cellfun runs on the cell output of ydata, then uses an
            %anonymous function to add each cell's value to the difference of
            %the Ylims to shift it. Uniformoutput is false since all different
            %lengths. Would have worked but adding a different value to each
            %one so using a for loop instead.
            %         set(h.TGTplot,'ydata',cellfun(@(x) x+newYlim(:,1)-currentYlim(:,1),get(h.TGTplot,'ydata'),'uniformoutput',0));
            %         currentYdata=get(h.TGTplot,'ydata');
            for yy=validTGTplotIndex
                set(h.TGTplot(yy),'ydata',get(h.TGTplot(yy),'ydata')+newYlim(yy,1)-currentYlim(yy,1),'visible',currentTGTstate{yy});
            end
        end
    end

    function modXlim2(src,event,h)
        currentYlim=cell2mat(get(h.spectraPlot,'Ylim'));%just want the first column
        currentXlim=get(h.spectraPlot,'Xlim');
        if isfield(h,'TGTplot')
            currentTGTstate=get(h.TGTplot,'visible');%in case have them hidden, dont want to reappear now
            set(h.TGTplot,'visible','off');%so not used in determination of yaxis
        end
        set(h.spectraPlot,'Xlim',[currentXlim{1}(1) str2double(get(src,'string'))],'YLimMode','auto');
        newYlim=cell2mat(get(h.spectraPlot,'Ylim'));
        if isfield(h,'TGTplot')
            validTGTplotIndex=find(h.TGTplot);%determine where it's not zero since might be no significant difference
            %         currentYdata=get(h.TGTplot(h.TGTplot~=0),'ydata');%does same
            %         thing as above, but note the output is shorter than the original
            %         so won't use it
            for yy=validTGTplotIndex %just to the ones that exist
                set(h.TGTplot(yy),'ydata',get(h.TGTplot(yy),'ydata')+newYlim(yy,1)-currentYlim(yy,1),'visible',currentTGTstate{yy});
            end
        end
    end

%to hide the TGT results for making a figure for display
    function hideTGT(src,event,h)
        if get(src,'value')==1
            set(h.TGTplot,'visible','on')
        else
            set(h.TGTplot,'visible','off');
        end
    end


end