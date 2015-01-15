function subplotEeglabSpectraManyBox

%to plot many spectra on one figure as box and wisker plots
%%
%
disp('Note: when picking files, ensure order is accurate.')
savename=input('Savename: ','s');
 PSfiles=uipickfiles('type',{'*PS.mat','PS file(s)'},'prompt','Pick PS.mat file(s). Order matters!');
%  PSfiles={'/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/DataFromNov23_2011/FinalDatasetDec13/patients_lancet_with_chanlocs/imjl_lancet_RIGHTHAND_1_pt5to2_PS.mat','/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/DataFromNov23_2011/FinalDatasetDec13/patients_lancet_with_chanlocs/imjl_lancet_RIGHTHAND_2_pt5to2_PS.mat','/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/DataFromNov23_2011/FinalDatasetDec13/patients_lancet_with_chanlocs/imjl_lancet_RIGHTHAND_3_pt5to2_PS.mat','/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/DataFromNov23_2011/FinalDatasetDec13/patients_lancet_with_chanlocs/imjl_lancet_RIGHTHAND_4_pt5to2_PS.mat','/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/DataFromNov23_2011/FinalDatasetDec13/patients_lancet_with_chanlocs/imjl_lancet_TOES_1_pt5to2_PS.mat','/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/DataFromNov23_2011/FinalDatasetDec13/patients_lancet_with_chanlocs/imjl_lancet_TOES_2_pt5to2_PS.mat','/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/DataFromNov23_2011/FinalDatasetDec13/patients_lancet_with_chanlocs/imjl_lancet_TOES_3_pt5to2_PS.mat','/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/DataFromNov23_2011/FinalDatasetDec13/patients_lancet_with_chanlocs/imjl_lancet_TOES_4_pt5to2_PS.mat'};
if isnumeric(PSfiles) || isempty(PSfiles)
    return
end

sl=input('Use Srivas channel list? (1/0) [0]: ');
if isempty(sl)
    sl=0;
end

pf=input('Plotting Freq Ranges [7 13;13 19;19 25;25 30]: ');
if isempty(pf)
    pf=[7 13;13 19;19 25;25 30];
end

%next give vector for colors
fprintf('%.0f spectra chosen to plot\n',length(PSfiles));
disp('Next type in vector of numbers for colors starting with 1');
disp('e.g. if 6 spectra of two types, [1 1 1 2 2 2]');
colorVec=input('Color vector: ');
if length(colorVec)~=length(PSfiles)
    disp('length of colorVec and number of spectra doesn''t match.');
    return
end

colorVecU=unique(colorVec);

for ps=1:length(PSfiles)
    PS(ps)=load(PSfiles{ps},'S','f','Serr','ChannelList');
end
numChannels=size(PS(1).S,2);

PSFig=figure;
% %make button to hide the error bars if hard to see
% errorButton=uicontrol('parent',PSFig,'style','pushbutton','callback',@errorDisplay,'units','normalized','position',[.05 .95 .1 .05],'string','ErrorBars');

set(PSFig,'name',savename,'toolbar','figure');


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

fshapes={'+','o','*','x','^','v'};%shapes for each frequency range

%this version plots each block in a column
% for pj=1:length(PSfiles) %for each file
%     for nj=1:numChannels %use nl for indexing below except for subplot
%         subplot(numrows,numcols,nj);
%         hold on;
%         if sl %if just list from Cruse et al.
%             nl=SrivasList(nj);
%         else
%             nl=nj;
%         end
%         for ff=1:size(pf,1)%for each frequency range
%             pfr=(PS(pj).f>=pf(ff,1) & PS(pj).f<pf(ff,2));
%             plot(pj,mean(10*log10(PS(pj).S(pfr,nl))),'marker',fshapes{ff},'linestyle','none','markersize',8,'markerfacecolor',colorlist(colorVec(pj),:),'markeredgecolor',colorlist(colorVec(pj),:));
%             text('Units','normalized','Position',[.5 .9],'string',PS(pj).ChannelList{nl},'FontSize',14,'HorizontalAlignment','center');
%             %         title(PS(pj).ChannelList{nj});
%         end
%     end
% end

% %this version plots each frequency range in a column
% %%
% %
% 
% for nj=1:numChannels %use nl for indexing below except for subplot
%     subplot(numrows,numcols,nj);
%     hold on;
%     if sl %if just list from Cruse et al.
%         nl=SrivasList(nj);
%     else
%         nl=nj;
%     end
%     for pj=1:length(PSfiles) %for each file
%         for ff=1:size(pf,1)%for each frequency range
%             xlabel{ff}=[num2str(pf(ff,1)) '-' num2str(pf(ff,2))];
%             pfr=(PS(pj).f>=pf(ff,1) & PS(pj).f<pf(ff,2));
%             plot(ff,mean(10*log10(PS(pj).S(pfr,nl))),'marker','o','linestyle','none','markersize',8,'markerfacecolor',colorlist(colorVec(pj),:),'markeredgecolor',colorlist(colorVec(pj),:));
%             
%             %             text('Units','normalized','Position',[.5 .9],'string',PS(pj).ChannelList{nl},'FontSize',14,'HorizontalAlignment','center');
%             title(PS(pj).ChannelList{nj});
%         end
%     end
%     xlim([0 size(pf,1)+1]);
%     set(gca,'xgrid','on','xtick',0:5,'xticklabel',[' '; xlabel'; ' ']);
% end


%%
%this version does each frequecy range as a box plot
%do two box plots on same axes spaced by small spacing
for nj=1:numChannels %use nl for indexing below except for subplot
    sph(nj)=subplot(numrows,numcols,nj);
    hold on;
    if sl %if just list from Cruse et al.
        nl=SrivasList(nj);
    else
        nl=nj;
    end
    for cc=1:length(colorVecU)%for each type
        PSplot=PS(colorVec==colorVecU(cc));%choose which ones to plot
        for ff=1:size(pf,1)%for each frequency range
            xlabel{ff}=[num2str(pf(ff,1)) '-' num2str(pf(ff,2))];
            for pj=1:sum(colorVec==colorVecU(cc)) %for each file within the type 
                pfr=(PSplot(pj).f>=pf(ff,1) & PSplot(pj).f<pf(ff,2));
                Smean(pj,ff)=mean(10*log10(PSplot(pj).S(pfr,nl)));
                smeanRange(cc,:)=[min(Smean(:)) max(Smean(:))];%to ensure adequate axes
            end
        end
        if cc<length(colorVecU)
            boxplot(sph(nj),Smean,xlabel,'position',cc:3:length(xlabel)*3,'plotstyle','compact','colors',colorlist(cc,:));
            set(gca,'XTickLabel',{' '});
        else
            boxplot(sph(nj),Smean,xlabel,'position',cc:3:length(xlabel)*3,'plotstyle','compact','colors',colorlist(cc,:));
        end
        set(gca,'ylim',[min(smeanRange(:)) max(smeanRange(:))]);   
    %             text('Units','normalized','Position',[.5 .9],'string',PS(pj).ChannelList{nl},'FontSize',14,'HorizontalAlignment','center');
    end
    title(PS(pj).ChannelList{nj});
%     xlim([0 size(pf,1)+1]);
%     set(gca,'xgrid','on','xtick',0:5,'xticklabel',[' '; xlabel'; ' ']);
end

% allowaxestogrow
% saveas(PSFig,savename,'fig');
        
% 
% function errorDisplay(varargin)
% a=get(errorBars(1,1),'visible');
% if strcmpi(a,'on')
%     b='off';
% else
%     b='on';
% end
% for eb=1:numel(errorBars)
%     set(errorBars,'visible',b);
% end
% end
% 
% end