function subplotEeglabSpectraMany

%to plot many spectra on one figure with variable number of colors
%version 2 - 3/1/12 has option to make all the y-axes the same so easier to
%compare the subplots. Fixed
%error bar hiding to work even on saved figures by sending it the handle
%to the errorbars (patch objects) and ensuring that was done after error 
%bars were created. [] might want to modify this as a GUI but can only
%think of doing this by a button that plots with error bars and one that
%plots without them once the y-axis is decided upon. 
%
%version 3 3/3/12 - JV would like me to add an error "I" in the lower left hand
%corner. [] calculate average (for all frequencies displayed and all 
%spectra) distance between the error bars [] consider
%displaying low and high value to see if this is a good idea. [] JV also
%wants the y-axes to be all the same so will set to the min and max of all
%of them so they all appear in the middle and not off the edges.

disp('Note: when picking files, ensure order is accurate.')
savename=input('Savename: ','s');
    PSfiles=uipickfiles('type',{'*PS.mat','PS file(s)'},'prompt','Pick PS.mat file(s). Order matters!');
    if isempty(PSfiles)
        return
    end

% %testing
% PSfiles={'/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/LancetPaper/FinalControlDatasetJan23/Analysis/DD/ByBlockFR3/imagDD_imag_lancet_RIGHTHAND_1_RIGHTHAND-1p5to0_PS.mat','/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/LancetPaper/FinalControlDatasetJan23/Analysis/DD/ByBlockFR3/imagDD_imag_lancet_RIGHTHAND_2_RIGHTHAND-1p5to0_PS.mat','/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/LancetPaper/FinalControlDatasetJan23/Analysis/DD/ByBlockFR3/imagDD_imag_lancet_RIGHTHAND_3_RIGHTHAND-1p5to0_PS.mat','/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/LancetPaper/FinalControlDatasetJan23/Analysis/DD/ByBlockFR3/imagDD_imag_lancet_RIGHTHAND_4_RIGHTHAND-1p5to0_PS.mat','/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/LancetPaper/FinalControlDatasetJan23/Analysis/DD/ByBlockFR3/imagDD_imag_lancet_RIGHTHAND_5_RIGHTHAND-1p5to0_PS.mat','/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/LancetPaper/FinalControlDatasetJan23/Analysis/DD/ByBlockFR3/imagDD_imag_lancet_RIGHTHAND_6_RIGHTHAND-1p5to0_PS.mat','/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/LancetPaper/FinalControlDatasetJan23/Analysis/DD/ByBlockFR3/imagDD_imag_lancet_TOES_1_TOES-1p5to0_PS.mat','/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/LancetPaper/FinalControlDatasetJan23/Analysis/DD/ByBlockFR3/imagDD_imag_lancet_TOES_2_TOES-1p5to0_PS.mat','/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/LancetPaper/FinalControlDatasetJan23/Analysis/DD/ByBlockFR3/imagDD_imag_lancet_TOES_3_TOES-1p5to0_PS.mat','/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/LancetPaper/FinalControlDatasetJan23/Analysis/DD/ByBlockFR3/imagDD_imag_lancet_TOES_4_TOES-1p5to0_PS.mat','/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/LancetPaper/FinalControlDatasetJan23/Analysis/DD/ByBlockFR3/imagDD_imag_lancet_TOES_5_TOES-1p5to0_PS.mat','/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/LancetPaper/FinalControlDatasetJan23/Analysis/DD/ByBlockFR3/imagDD_imag_lancet_TOES_6_TOES-1p5to0_PS.mat'};
% savename='test';

sl=input('Use Srivas channel list? (1/0) [0]: ');
if isempty(sl)
    sl=0;
end

pf=input('Plotting Freq Range [0 40]: ');
if isempty(pf)
    pf=[0 40];
end

yrange=input('Y range for all plots (or ''m'' for maximum, or return for auto): ');
%if it's empty will look for that below

%next give vector for colors
fprintf('%.0f spectra chosen to plot\n',length(PSfiles));
disp('Next type in vector of numbers for colors starting with 1');
disp('e.g. if 6 spectra of two types, [1 1 1 2 2 2]');
colorVec=input('Color vector: (return for half and half)');
if isempty(colorVec)
    if mod(length(PSfiles),1) %if a fraction so something left over
        disp('Not an even number of files');
        return
    end
    colorVec=[ones(1,length(PSfiles)/2) 2*ones(1,length(PSfiles)/2)];
end
if length(colorVec)~=length(PSfiles)
    disp('length of colorVec and number of spectra doesn''t match.');
    return
end

for ps=1:length(PSfiles)
    PS(ps)=load(PSfiles{ps},'S','f','Serr','ChannelList');
end
numChannels=size(PS(1).S,2);

PSFig=figure;
%make button to hide the error bars if hard to see



%to plot just channels in Cruse et al.
SrivasList=[6    7   13   29   30   31   35   36   37   41   42   54   55   79 80   87   93  103  104  105  106  110  111  112  129]; 
if sl
    numChannels=length(SrivasList);
    savename=[savename '_S'];
end

%subplot the spectra with appropriate titles
numrows=ceil(sqrt(numChannels));
numcols=floor(sqrt(numChannels));
if numrows*numcols<numChannels
    numcols=numcols+1;
end;

if size(unique(colorVec))<4
    colorlist=[1 0 0; 0 0 1; 0 1 0]; %red, blue, green
else
    colorlist=varycolor(size(unique(colorVec)));
end

serrdiff=zeros(length(PSfiles),numChannels);%initialize it
errorBars=serrdiff;
sploth=zeros(1,numChannels);

for pj=1:length(PSfiles) %for each file
    pfr=(PS(pj).f>=pf(1) & PS(pj).f<=pf(2));
    for nj=1:numChannels %for each channel to plot
        sploth(nj)=subplot(numrows,numcols,nj);
        if sl
            nl=SrivasList(nj);%nl represents the original channel #
        else
            nl=nj;
        end
        %calculate mean error bar for each channel and for each file within
        %relevant frequency range
        serrdiff(pj,nj)=mean(10*log10(PS(pj).Serr(2,pfr,nl))-10*log10(PS(pj).Serr(1,pfr,nl)));
        
        %plot
        errorBars(pj,nj)=fill([PS(pj).f(pfr) fliplr(PS(pj).f(pfr))],[10*log10(PS(pj).Serr(1,(pfr),nl)) fliplr(10*log10(PS(pj).Serr(2,(pfr),nl)))],colorlist(colorVec(pj),:));
        hold on;
        plot(PS(pj).f(pfr),10*log10(PS(pj).S(pfr,nl)),'color',colorlist(colorVec(pj),:));
        grid on;
        axis tight;
        if ~isempty(yrange) && isnumeric(yrange) %if not it does the auto scaling
            ylim(yrange);
        end
        
        %below can switch between channel name in the figure (text) or above
        %(title).
%         text('Units','normalized','Position',[.5 .9],'string',PS(pj).ChannelList{nl},'FontSize',14,'HorizontalAlignment','center');
         title(PS(pj).ChannelList{nl});
        grid off;%so can see the I better
    end  
end
set(errorBars,'linestyle','none','facealpha',0.3); 

if ischar(yrange)
    yrangeall=zeros(numChannels,2); %initialize
    for yy=1:numChannels
        yrangeall(yy,:)=get(sploth(yy),'ylim');
    end
end
%plot the error "I" on the subplots using the subplot handle
Iwidth=2;
for nsp=1:numChannels
    %determine the y-axis range
    if isempty(yrange)  %if set as auto 
        yrange=get(sploth(nsp),'ylim');
    end
    if ischar(yrange)%if chose 'max' change it to actual values here
        yrange=[min(yrangeall(:,1)) max(yrangeall(:,2))];
    end
    %plot the mean error of all spectra    
    plot(sploth(nsp),[9 9],[yrange(1)+2 yrange(1)+2+mean(serrdiff(:,nsp))],'linewidth',Iwidth,'color','k');
    plot(sploth(nsp),[8.5 9.5],[yrange(1)+2 yrange(1)+2],'linewidth',Iwidth,'color','k');
    plot(sploth(nsp),[8.5 9.5],[yrange(1)+2+mean(serrdiff(:,nsp)) yrange(1)+2+mean(serrdiff(:,nsp))],'linewidth',Iwidth,'color','k');
    set(sploth(nsp),'ylim',yrange);
end
    


%make a GUI to hide the error bars
uicontrol('parent',PSFig,'style','pushbutton','callback',{@errorDisplay,errorBars},'units','normalized','position',[.03 .95 .08 .05],'string','ErrorBars');
%reset the figure to be able to see the controls on top
set(PSFig,'name',savename,'toolbar','figure');


% allowaxestogrow
saveas(PSFig,savename,'fig');
        

function errorDisplay(~,~,errorBars)
a=get(errorBars(1,1),'visible');
if strcmpi(a,'on')
    b='off';
else
    b='on';
end
for eb=1:numel(errorBars)
    set(errorBars,'visible',b);
end
end

end