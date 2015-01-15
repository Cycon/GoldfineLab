function spectraGUI(EEG,tag)
%
%5/6/12 AMG - code to run and instanly plot spectra of data from an eegplot
%window. Primarily designed for eegplotEpochChoose where the eegplot may be
%a filtered version of the original data, but want the spectra to reflect
%the underlying data. Future version will also allow for running on any
%eegplot window. Input is an EEG structure file which needs chanlocs info
%for channel labels. Tag is the optional label of the eegplot so it knows which one
%to pull the highlighted epoch information from.
%
%To do:
%[] make option to get the data from an eegplot
%[] make option to hide plots so don't need to recalculate including
%putting checkboxes on side with label of order
%[] Need to test on continuous data since not set for it now.
%[] Add in other montages
%version 2 5/7/12 add in additional plot option for a figure that plots the average
%spectra and on top of it spectra from all blocks but initially invisibly
%and then can make appear from a list box with a plot button
%5/8/12 change for individual spectra plot to use scrollsubplot since hard
%to see otherwise.
%6/5/12 now when zooming in on plot for selected epochs, the y-axis auto
%changes
%6/15/12 kat pointed out bug in visualization and turns out the laplacian
%calculation wasn't happening
%12/2/12 put in option to visualize as bipolar. Required montaging before
%determining number of spectra (bipolar reduces number by 1)

%%
%not for continuous data
if ndims(EEG.data)==2
    disp('not tested for continuous data yet');
    return
end

%%
%determine which epochs are highlighted in case just want spectra on
%highlighted or nonhighlighted epochs.
if nargin==1
    tag='EEGPLOT';%the default, though multiple windows could have this
end

h.tag=tag;




%%
%make control figure (used GUIDE exported code to help with the positions)
h.controlFig = figure(...
    'Units','characters',...
    'Color',[0.929411764705882 0.929411764705882 0.929411764705882],...
    'Colormap',[0 0 0.5625;0 0 0.625;0 0 0.6875;0 0 0.75;0 0 0.8125;0 0 0.875;0 0 0.9375;0 0 1;0 0.0625 1;0 0.125 1;0 0.1875 1;0 0.25 1;0 0.3125 1;0 0.375 1;0 0.4375 1;0 0.5 1;0 0.5625 1;0 0.625 1;0 0.6875 1;0 0.75 1;0 0.8125 1;0 0.875 1;0 0.9375 1;0 1 1;0.0625 1 1;0.125 1 0.9375;0.1875 1 0.875;0.25 1 0.8125;0.3125 1 0.75;0.375 1 0.6875;0.4375 1 0.625;0.5 1 0.5625;0.5625 1 0.5;0.625 1 0.4375;0.6875 1 0.375;0.75 1 0.3125;0.8125 1 0.25;0.875 1 0.1875;0.9375 1 0.125;1 1 0.0625;1 1 0;1 0.9375 0;1 0.875 0;1 0.8125 0;1 0.75 0;1 0.6875 0;1 0.625 0;1 0.5625 0;1 0.5 0;1 0.4375 0;1 0.375 0;1 0.3125 0;1 0.25 0;1 0.1875 0;1 0.125 0;1 0.0625 0;1 0 0;0.9375 0 0;0.875 0 0;0.8125 0 0;0.75 0 0;0.6875 0 0;0.625 0 0;0.5625 0 0],...
    'IntegerHandle','off',...
    'InvertHardcopy',get(0,'defaultfigureInvertHardcopy'),...
    'MenuBar','none',...
    'Name',tag,...
    'NumberTitle','off',...
    'PaperPosition',get(0,'defaultfigurePaperPosition'),...
    'Position',[5 50 30 25],...
    'Visible','on' );

% %    'Position',[103.833333333333 43.0833333333333 22.8333333333333 18.4166666666667]


h.sf=figure;%spectra figure
set(h.sf,'Tag','0','Visible','off');%for number of plots so can count them

uicontrol(...
    'Parent',h.controlFig,...
    'Units','normalized',...
    'Position',[.05 .85 .8 .1],...
    'String','EpochsToPlot:',...
    'Style','text');

h.highlight = uicontrol(...
    'Parent',h.controlFig,...
    'Units','normalized',...
    'Position',[.01 .8 .9 .1],...
    'String',{  'All'; 'Highlighted'; 'Not-highlighted' },...
    'Style','popupmenu',...
    'Value',2);

h.FR = uicontrol(...
    'Parent',h.controlFig,...
    'Units','normalized',...
    'FontSize',10,...
    'Position',[.5 .7 .3 .1],...
    'String',num2str(2/(size(EEG.data,2)/EEG.srate)),...%default is minimum FR
    'Style','edit');

uicontrol(...
    'Parent',h.controlFig,...
    'Units','normalized',...
    'FontSize',10,...
    'Position',[.1 .7 .2 .1],...
    'String','Fr Res',...
    'Style','text');

h.montage=uicontrol(...
    'Parent',h.controlFig,...
    'Units','normalized',...
    'FontSize',10,...
    'Position',[.05 .5 .8 .1],...
    'String',{'Laplacian'; 'Original';'Bipolar'},...
    'Style','popupmenu',...
    'Value',1);

h.EB = uicontrol(...
    'Parent',h.controlFig,...
    'Units','normalized',...
    'FontSize',10,...
    'Position',[.05 .3 .8 .1],...
    'String','ErrorBars',...
    'Style','checkbox',...
    'Tag','checkbox1');

%button to plot the spectra of chosen epochs
uicontrol(...
    'Parent',h.controlFig,...
    'Units','normalized',...
    'Callback',{@spectra_Callback,EEG,h},...
    'FontSize',10,...
    'Position',[.05 .2 .8 .1],...
    'String','PlotChosenEpochs');

%button to plot mean and 1 chosen epoch
uicontrol(...
    'Parent',h.controlFig,...
    'Units','normalized',...
    'Callback',{@spectra_epoch_Callback,EEG,h},...
    'FontSize',10,...
    'Position',[.05 .05 .8 .1],...
    'String','PlotIndividualEpochs');


%%
% --- Executes on button press in pushbutton1.
    function spectra_Callback(hObject, eventdata,EEG,h)
        %[] put in here the gets from the h's to choose which data to use
        %         params.tapers=[2 3];
        FR=str2double(get(h.FR,'String'));
        if FR<2/(size(EEG.data,2)/EEG.srate) %if less than minimum
            beep
            fprintf('Minimum frequency resolution is %.2f',2/(size(EEG.data,2)/EEG.srate));
            return
        end
        params.tapers(1)=ceil(EEG.pnts/EEG.srate*FR/2);
        params.tapers(2)=params.tapers(1)*2-1;
        params.pad=-1;
        params.trialave=1;
        
        params.Fs=EEG.srate;
        EB=get(h.EB,'Value');
        %         prev=get(h.hold,'Value');%whether to plot on previous or make a new figure
        
        %montage
        %[] if make common average or bipolar need to not include accelerometers
%         if h.montage==1 %laplacian montage %his is an error found 6/15/12
        if get(h.montage,'value')==1 %if laplacian montage
            EEG.data=MakeLaplacian(EEG.data,EEG.chanlocs);
        elseif get(h.montage,'value')==3 %if bipolar montage
            [EEG.data,chanlistNotUsed,EEG.chanlocs]=MakeBipolar(EEG.data,EEG.chanlocs);
        end
        
        ns=size(EEG.data,1);%number of spectra
        %initialize
        numFreq=floor(size(EEG.data,2)/2)+1;
        S=zeros(numFreq,ns);
        Serr=zeros(2,size(S,1),size(S,2));
        
        eplot=get(findobj('tag',h.tag));%find the relevant eegplot for determination of highlighted
        %([] in future use to find all of the open ones or user can click on one)
        if length(eplot)>1 %if multiple standard EEGPLOT windows or multiple with same tag (less likely)
            beep
            disp('No tag sent and multiple plots so not sure which to use');
            return
        end
        
        if isempty(eplot)
            beep
            disp('No eegplot windows opened');
            return
        end
        
        
        
        %for detection of which are highlighted / not depending on
        %what user chose from GUI before.
        highlight=get(h.highlight,'value');
        if highlight==1
            ec=1:size(EEG.data,3);
        elseif isempty(eplot.UserData.winrej) %if no highlights
            beep
            disp('No highlighted epochs');
            return %so doesn't add to the number of plots
        elseif highlight==2 %higlighted
            ec=eplot.UserData.winrej(:,2)/size(EEG.data,2);
        elseif highlight==3 %non-highlighted
            ec=setdiff(1:size(EEG.data,3),eplot.UserData.winrej(:,2)/size(EEG.data,2));
        end
        
        for d=1:ns
            if EB %if EB checked
                params.err=[2 0.05];
                [S(:,d) f Serr(:,:,d)]=mtspectrumc(squeeze(EEG.data(d,:,ec)),params);
            else
                [S(:,d) f]=mtspectrumc(squeeze(EEG.data(d,:,ec)),params);
            end
        end
        
        %%
        %make figure
        figure(h.sf);
        
        ct=str2double(get(h.sf,'Tag'));%get current number of plots, starts at 0 from above code
        
        set(h.sf,'Tag',num2str(ct+1));%add 1 for new total number
        
        colors={'b' 'r' 'g' 'k'};%[]consider later option to hide specific ones
        %         if prev %if want to plot on the previous one
        %             color='r';
        %         else
        %             color='b';
        %             clf(h.sf);
        %         end
        
        %         set(specfig,'position',[18   687   128   120]);
        
        [nr,nc]=subplotNumCalc(ns);%determine grid size
        eb=zeros(1,ns);%initialize
        for e=1:ns
            h.s(e)=subplot(nr,nc,e);
            
            hold on;
            if EB
                eb(e)=fill([f fliplr(f)],[10*log10(squeeze(Serr(1,:,e))) fliplr(10*log10(squeeze(Serr(2,:,e))))],colors{ct+1},'HandleVisibility','callback');
                %                 hold on;
                plot(f,10*log10(S(:,e)),colors{ct+1},'LineWidth',2);
            else
                plot(f,10*log10(S(:,e)),colors{ct+1},'LineWidth',1);
            end
            axis tight;
            text('Units','normalized','Position',[.5 .9],'string',EEG.chanlocs(e).labels,'FontSize',12,'HorizontalAlignment','center');
        end
        if EB
            set(eb,'linestyle','none','FaceAlpha',0.3);
        end
        %         allowaxestogrow;
        
        
        %modify the x-axes (note use of callback in the function)
        uicontrol('style','edit','units','normalized','position',[0.01 .9 .05 .05],'string','0','callback',{@modXlim1,h.s});
        uicontrol('style','edit','units','normalized','position',[0.05 .9 .05 .05],'string','40','callback',{@modXlim2,h.s});
        %later add in checkbox to suppress edge electrodes or consider to
        %use the headplot style code here
        %         uicontrol('parent',specfig,'style','text','units','normalized','position',[0.05 0.4,0.7 0.2],'string','Suppress edge: ');
        %         h.edge=uicontrol('parent',specfig,'style','checkbox','units','normalized','position',[0.4 0.2 0.2 0.2],'value',0);
%         h.plot=uicontrol('style','pushbutton','units','normalized','position',[0.01 .85 .08 .05],'string','plot','callback',{@modXlim,h});
        %[] make a simple code to simple change the xaxis displayed for all the
        %subplots
        
        %clear figure
        uicontrol('style','pushbutton','units','normalized','position',[0.01 .8 .08 .05],'string','clear','callback',{@clearSpecFig,h});
        
        
    end


%%
%figure subcode here to modify the x limits
    function modXlim1(src,event,subplotHandle)
        currentXlim=get(subplotHandle,'Xlim');
        set(subplotHandle,'Xlim',[str2double(get(src,'string')) currentXlim{1}(2)],'ylimmode','auto');
    end

    function modXlim2(src,event,subplotHandle)
        currentXlim=get(subplotHandle,'Xlim');
        set(subplotHandle,'Xlim',[currentXlim{1}(1) str2double(get(src,'string'))],'ylimmode','auto');
    end

%%
%subcode to clear
    function clearSpecFig(src,event,h)
        clf(h.sf);
        set(h.sf,'Tag','0');%back to zero plots for coloring next one
    end

%%
%subcode for figure that plots spectra of individual epochs
    function spectra_epoch_Callback(src,event,EEG,h)
        
        FR=str2double(get(h.FR,'String'));
        if FR<2/(size(EEG.data,2)/EEG.srate) %if less than minimum
            beep
            fprintf('Minimum frequency resolution is %.2f',2/(size(EEG.data,2)/EEG.srate));
            return
        end
        params.tapers(1)=ceil(EEG.pnts/EEG.srate*FR/2);
        params.tapers(2)=params.tapers(1)*2-1;
        params.pad=-1;
        params.traialve=0;%note this is different from above
        ns=size(EEG.data,1);%number of spectra
        params.Fs=EEG.srate;
        %         EB=get(h.EB,'Value');
        %         prev=get(h.hold,'Value');%whether to plot on previous or make a new figure
        
        %%
        %added 6/15/12 
        if get(h.montage,'value')==1 %if laplacian montage
            EEG.data=MakeLaplacian(EEG.data,EEG.chanlocs);
        end
        
        %%
        %calculate spectra for each block and later average it. No error
        %bars here to save time. Hopefully still useful
        
        %initialize
        numFreq=floor(size(EEG.data,2)/2)+1;
        S=zeros(numFreq,size(EEG.data,3),ns);
        %         Serr=zeros(2,size(S,1),size(S,2));
        Sm=zeros(numFreq,ns);
        for d=1:ns
            %             %S is frequency by epoch by channel
            [S(:,:,d) f]=mtspectrumc(squeeze(EEG.data(d,:,:)),params);%find spectra
            Sm(:,d)=mean(S(:,:,d),2);
            %             end
        end
        
        %%
        %next plot them and have plot with hidden spectra then can unhide
        %later
        h.indFig=figure;
         [nr,nc]=subplotNumCalc(ns);%determine grid size
        for e=1:ns
%             h.sa(e)=subplot(nr,nc,e);
            h.sa(e)=scrollsubplotAndy(4,4,e);%added 5/8/12
            
            hold on;
            plot(f,10*log10(Sm(:,e)),'k','LineWidth',1);%plot mean
            %next line plots all of them at once and gives all the handles
            h.si(:,e)=plot(f,10*log10(squeeze(S(:,:,e))),'b','LineWidth',1,'Visible','off');%plot individual
            axis tight;
            text('Units','normalized','Position',[.5 .9],'string',EEG.chanlocs(e).labels,'FontSize',12,'HorizontalAlignment','center');
        end
       
        
        %listbox to show a specific epoch's spectra
        uicontrol('parent',h.indFig,'style','listbox','string',num2cell(1:size(EEG.data,3)),...
            'units','normalized','position',[.01 .1 .07 .8],...
            'callback',{@revealSpectra,h})
         
        
        %buttons to modify the plotting frequency range
        uicontrol('style','edit','units','normalized','position',[0.01 .9 .05 .05],'string','0','callback',{@modXlim1,h.sa});
        uicontrol('style','edit','units','normalized','position',[0.05 .9 .05 .05],'string','40','callback',{@modXlim2,h.sa});
        
    end

    function revealSpectra(hObject,eventdata,h)
        set(h.si,'visible','off');%in case any made visible before
        set(h.si(get(hObject,'value'),:),'visible','on');%epochs represented in rows, channels in columns
    end

end