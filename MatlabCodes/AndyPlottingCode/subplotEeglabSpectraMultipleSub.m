function subplotEeglabSpectraMultipleSub

%based on subplotEeglabSpectra 
%3/6/12 only meant to plot 1 spectra of 1 channel from multiple subjects
%for easier comparison of them. Also has code for the Cruse et al.
%reanalysis to change subject name.

    figuretitle=input('Figure Title: ','s');
  
    PSfile=uipickfiles('type',{'*PS.mat','spectra from PSeeglab'});
    if isempty(PSfile) || isnumeric(PSfile) %two options in case press cancel or done with no selection
        return; 
    end
    for nss=1:length(PSfile)
        spectra(nss)=load(PSfile{nss});
        [~,filenames{nss}]=fileparts(PSfile{nss});
        filenames{nss}=filenames{nss}(1:end-3);%so matches with SVMsubjectLookup
    end;
    

    numSpec=length(PSfile);
%%
%choose channel to plot for all subject
for fc=1:length(spectra(1).ChannelList)
    fprintf('%.0f. %s\n',fc,spectra(1).ChannelList{fc});
end

chan=input('Which channel number?: ');
EGIchosenFrom=spectra(1).numChannelsOrig;
if chan==37 
    disp('Channel 37 doesn''t have proper match with EGI257');
end

%%

%need to determine if channel numbers are the same since want to compare
%EGI 129 to EGI 257. Use numChannelsOrig
if ~mod(sum([spectra.numChannelsOrig]),spectra(1).numChannelsOrig) %if not zero
    disp('Spectra have different numbers of original channels, will remap EGI129 to 257 only if 25 Cruse list chosen in PSeeglab');
    fprintf('Channel chosen from spectra with %.0f channels.\n',spectra(1).numSpec);
end

%%
%make a remapping code here
%this matrix is 129 first and then 257 in second row
%note this isn't necessary since other than channel 37 / 58 they line up
%nicely so the index is the same
% remapMat=[6    7   13   29   30   31   35   36   37   41   42   54   55   79   80   87   93  103  104  105  106  110  111  112  129;
%           8    9   17   43   44   45   52   53   58   65   66   80   81  131  132  144  164  182  184  185  186  195  197  198  257];

%[]use above to remap for choosing below

%%
%reorder everything
[subjectNumberName,~,orderi,~]=SVMsubjectLookUp(filenames);
spectra=spectra(orderi);
subjectNumberName=subjectNumberName(orderi);

%%
%Defaults 
plottingRange=[0 40]; %range to plot
    fprintf('Plotting range set at %.0f to %.0f Hz\n',plottingRange(1), plottingRange(2));
    if strcmpi(input('Change plotting frequency range? (y or Return): ','s'),'y')
        plottingRange(1)=input('Starting value: ');
        plottingRange(2)=input('Ending value: ');
    end
%11/23/11 make this different for each spectra since not necessarily the
%same if they are from data of different length swatches for example. Needs
%to be in a cell because they can be different lengths

% plottingFreqIndeces=(spectra{1}.f>=plottingRange(1) & spectra{1}.f<=plottingRange(2));%need different one for spectra{2} if from different headbox
for ppp=1:numSpec
    plottingFreqIndeces{ppp}=(spectra(ppp).f>=plottingRange(1) & spectra(ppp).f<=plottingRange(2));
end

numrows=ceil(sqrt(numSpec));
numcols=floor(sqrt(numSpec));
if numrows*numcols<numSpec
    numcols=numcols+1;
end;

PSfigure=figure; 

% set(gcf,'Name',savename, 'Position',[1 1 scrsz(3)*0.8 scrsz(4)*0.9]);
%12/5/11 set to not be visible so won't kill memory. Requires openfig be
%modified so visible='visible';
set(gcf,'Name',[figuretitle ' PS Channel ' num2str(spectra(1).ChannelList{chan})]);
% set(gcf,'Name',[figuretitle ' PS Channel ' num2str(spectra(1).ChannelList{chan})],'Units','normalized','Position',[0 0 .99 .95]);

%%

%plot
%8/26 make for loop for each line calling from color list
% colorlist={'r','b','g'};

% pnum=1;%added since plotindex might not start with 1        
for j = 1:numSpec
%     if EGIchosenFrom==129 && spectra(j).numChannelsOrig==257
%         chanplot=remapMat(2,chan));%originally asked where remapMat(1,:)==chan but chan is the index not the channel number
%     elseif EGIchosenFrom==257 && spectra(j).numChannelsOrig==129
%         chanplot=remapMat(1,chan));
%     end    
    %  for j=16 %to just plot one to blow up and copy for a figure
    subplot(numrows,numcols,j);%note here each one on a different plot not multiple spectra on each subjplot
%     for j=1:numSpec %new 8/26. 11/23/11 added index to plottingFreqIndeces
        fplot=spectra(j).f(plottingFreqIndeces{j});
        hold on;
%         if deriv %if want to plot spectra of derivative of data
%             errorBars(ns)=fill([fplot fliplr(fplot)],[10*log10(spectra(ns).Serr(1,(plottingFreqIndeces{ns}),j).*fplot.^2) fliplr(10*log10(spectra(ns).Serr(2,(plottingFreqIndeces{ns}),j).*fplot.^2))],colorlist{ns},'HandleVisibility','callback');
%             plot(fplot,10*log10(spectra(ns).S((plottingFreqIndeces{ns}),j).*fplot'.^2),colorlist{ns},'LineWidth',2); %f is not normalized unlike with browser
%         else
            errorBars(j)=fill([fplot fliplr(fplot)],[10*log10(spectra(j).Serr(1,(plottingFreqIndeces{j}),chan)) fliplr(10*log10(spectra(j).Serr(2,(plottingFreqIndeces{j}),chan)))],'b','HandleVisibility','callback');
            plot(fplot,10*log10(spectra(j).S((plottingFreqIndeces{j}),chan)),'b','LineWidth',2); %f is not normalized unlike with browser
%         end
%         set(gca,'xtick',[plottingRange(1):5:plottingRange(2)],'FontSize',12); %this sets the xticks every 5
        %     set(gca,'xtick',[plottingRange(1):3:plottingRange(2)],'FontSize',32,'Ylim',[10 40],'Xlim',plottingRange); %for paper figure
%         ylimPlot=ylim; %ylim here can be reset below to ensure negative TGT results are off the screen
        grid on; %this turns grid on
        %  grid off; %JUNE 30 FOR MARY
        hold('all'); %this is for the xticks and grid to stay on
%     end
    set(errorBars,'linestyle','none','facealpha',0.3); %to make the fill transparent
   
 
               title(subjectNumberName{j},'FontSize',16);

    axis tight; %in case don't plot full range
%     pnum=pnum+1;
end

%%
allowaxestogrow;
saveFigureAs=[figuretitle '_' num2str(spectra(1).ChannelList{chan}) '_PS'];
saveFigureAs(saveFigureAs==' ')=[]; % to remove spaces in the filename of the figure
saveas(PSfigure,saveFigureAs,'fig');%to save the figure
