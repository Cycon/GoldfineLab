function SGEeglabPlot
%
%7/30/13 AMG to create and plot spectrograms on the fly of data in .set format.
%11/6/13 v2 to allow for comparison to second EEG, do from beginning so can
%have two variables. The first one will be the primary and the second will
%only be available in the comparison image (could modify but would need a
%switch in the first page to choose which one). 
%[] need a plotting routine to show only sections of the spectrograms where
%they appear on the head and then drag with slider to earlier or later
%times.
%[] Convert to object programming to make cleaner and easier to store the
%variables (rather than in the GUI).
%[] Sudhin wants a topoplot showing where things are significant (with
%different topoplot for each time point I guess and showing only one
%frequency)
 
%%
%choose file to use and load it
setfilename=uipickfiles('type',{'*.set','EEGLAB file '},'prompt','Select 1 or 2 EEG file(s)','num',[1 2]);

if isempty(setfilename{1}) || isnumeric(setfilename{1}); %if press cancel for being done
    return
end
for ss=1:length(setfilename)
    eeg(ss) = pop_loadset('filename',setfilename{ss});
    [pathname,f.filename{ss}]=fileparts(setfilename{ss});%for labeling figures to help keep straight.
end

%ensure that the channel numbers match (no guarantee on the channel names
%though!
if length(eeg)==2
    if eeg(1).nbchan~=eeg(2).nbchan
        disp('Different number of channels in the EEG files');
        return
    end
    
    if size(eeg(1).data,2)~=size(eeg(2).data,2)
        disp('Different epoch sizes in the EEG files');
        return
    end
end

%for testing
% eeg=pop_loadset('filename','IN316W_HandRun3_start-2to13.set');


%below isn't being used:
% %here is a default list of favorite channels to use, need to have set list
% %depending on headbox possibly.
% f.channelFav.names={'None','Central'};
% f.channelFav.numbers={[];[3:8 19 33]};%[] eventually use actual channel names and a lookup list

%% relable the EGI channels so more useful below
if strcmpi(eeg(1).chanlocs(1).labels,'E1') %if  EGI
    etable=egi_equivtable_Andy;%columns of E65, output, E129, E33
    output=etable(:,2);
    for ee=1:length(eeg(1).chanlocs)
        switch length(eeg(1).chanlocs)
            case 33 %if EGI33
                if sum(strcmpi(eeg(1).chanlocs(ee).labels,etable(:,4)))%if channel in the list
                eeg(1).chanlocs(ee).labels=output...
                    {strcmpi(eeg(1).chanlocs(ee).labels,etable(:,4))};
                end
            case 129
                if sum(strcmpi(eeg(1).chanlocs(ee).labels,etable(:,3)))
                eeg(1).chanlocs(ee).labels=output...
                    {strcmpi(eeg(1).chanlocs(ee).labels,etable(:,3))};
                end
            case 65
                if sum(strcmpi(eeg(1).chanlocs(ee).labels,etable(:,1)))
                eeg(1).chanlocs(ee).labels=output...
                    {strcmpi(eeg(1).chanlocs(ee).labels,etable(:,1))};
                end
            otherwise
                errordlg('Wrong number of EGI channels for list');
                return
        end
    end
    %                 %remove non 10-20
    %                 non1020=cellfun('isempty',{eeg.chanlocs.labels});
    %                 eeg.chanlocs=eeg.chanlocs(~non1020);
    %                 eeg.data=eeg.data(~non1020,:,:);
    %                 eeg.nbchan=size(eeg.data,1);
    
    if length(eeg)==2
        eeg(2).chanlocs=eeg(1).chanlocs;%relabel the other one as well
    end
    
end

f.ChannelList={eeg(1).chanlocs.labels};%easier to use

%%
%set up GUI based on subplotSpectrogram. Add in options for the spectrogram
%(though trialave is set to off). Don't forget laplacian versus default
%ref. Could add in preset channel lists [].
f.cf=figure;%f is handle for all figures, cf is control figure
set(f.cf,'Name',[f.filename{1} ' Control']);
%set(f.cf,'Name',[eeg.filename(1:end-4) 'Control'],'units','normalized',...
%  'position',[0.05 0.1 0.3 0.9]);

%this tab is for the spectrogram settings
f.tab=uiextras.TabPanel('Parent',f.cf);
f.sgtab=uiextras.HBox('Parent',f.tab);
f.sgtab_c1=uiextras.VBox('Parent',f.sgtab);%first vertical column
uicontrol('style','text','string','MW Width','Parent',f.sgtab_c1);
uicontrol('style','text','string','MW Step','Parent',f.sgtab_c1);
uicontrol('style','text','string','Number of tapers','Parent',f.sgtab_c1);
f.lap=uicontrol('Parent',f.sgtab_c1,'style',...
    'checkbox','string','Laplacian','value',1);
if length(eeg)==2
    uicontrol('style','text','string','Comparison EEG is: ','Parent',...
        f.sgtab_c1);
end

f.sgtab_c2=uiextras.VBox('Parent',f.sgtab);%second column
f.mw_w=uicontrol('style','edit','string','','Parent',f.sgtab_c2,...
    'BackgroundColor','w');
f.mw_s=uicontrol('style','edit','string','','Parent',f.sgtab_c2,...
    'BackgroundColor','w');
f.tapers=uicontrol('style','edit','string','1','Parent',f.sgtab_c2,...
    'BackgroundColor','w');
% fres_default=sprintf('Freq Res is %.2f Hz',...
%     (str2double(get(f.tapers,'string'))+1)/str2double(get(f.mw_w,'string')));
f.fr=uicontrol('style','text','string','Freq Res is  Hz','Parent',f.sgtab_c2);
if length(eeg)==2
    uicontrol('style','text','string',f.filename{2},'background','w',...
        'Parent',f.sgtab_c2);
end


%next tab for actually plotting the spectrogram
%[] consider adding favorites list of channels esp for EGI
f.plottab=uiextras.HBox('Parent',f.tab);%horizotal for long list
f.plottab_v0=uiextras.VBox('Parent',f.plottab);
f.channels=uicontrol('Parent',f.plottab_v0,... %this is the channel list
    'style','listbox','string',f.ChannelList,'Max',length(f.ChannelList)-1);
f.ten20=uicontrol('Parent',f.plottab_v0,'style',...
    'checkbox','string','Plot 10-20 channels');%to select and plot 10-20
%below list of channels used so can copy and paste into another window.
uicontrol('Parent',f.plottab_v0,'style','text','string','Channels used:')
f.channelsSelected=uicontrol('Parent',f.plottab_v0,...
    'style','edit','string','1');
% f.channelFavList=uicontrol('Parent',f.plottab_v0,... %this is the channel list
%     'style','listbox','string',f.channelFav.names,'Max',length(f.ChannelList)-1,'value',1);
f.calculate=uicontrol('Parent',f.plottab_v0,...
    'string','Calculate SG');%set callback later
set(f.plottab_v0,'Sizes',[-4 -0.25 -0.25 -0.5 -1]);%to set relative size of uicontrols in column

%next column for the different types of plots on a vertical box
f.plottab_v1=uiextras.VBox('Parent',f.plottab);
f.plotAvg=uicontrol('Parent',f.plottab_v1,'style','checkbox',...
    'string','Plot Avg SG','value',1);%if not will plot each trial separately
% f.meansub=uicontrol('Parent',f.plottab_v1,'style','checkbox','value',0,...
%     'string','Subt Mean');
% f.basesub=uicontrol('Parent',f.plottab_v1,'style','checkbox','value',...
%     0,'string','Sub Baseline');%for baseline subtract. Also has a callback for TGT
f.subTypeBox=uibuttongroup('Parent',f.plottab_v1);%box to contain mutually exclusive radio buttons
    uicontrol('Parent',f.subTypeBox,'style','radiobutton','string',...
        'No subtraction','units','normalized','position',[0 0.8 1 0.15]);%first option so is the default
    f.meansub=uicontrol('Parent',f.subTypeBox,'style','radiobutton',...
        'string','Subt Mean','units','normalized','position',[0 0.6 1 0.15]);%for Subtract the mean (= full baseline)
    f.basesub=uicontrol('Parent',f.subTypeBox,'style','radiobutton','value',...
        0,'string','Sub Baseline','units','normalized','position',[0 0.4 1 0.15]);%for baseline subtract.
    f.matchedsub=uicontrol('Parent',f.subTypeBox,'style','radiobutton','value',...
        0,'string','Sub Second Half','units','normalized','position',[0 0.2 1 0.15]);%For subtracting the matched time from 2nd half
    f.othereegsub=uicontrol('Parent',f.subTypeBox,'style','radiobutton','value',...
        0,'string','Sub Second EEG','units','normalized','position',[0 0 1 0.15]);%For subtracting the matched time from 2nd half
uicontrol('Parent',f.plottab_v1,'style','text','string','Baseline range:');
f.baselineTimes=uicontrol('Parent',f.plottab_v1,'style','text','string','');%for displaying
uicontrol('Parent',f.plottab_v1,'style','text',...
    'string','Freq Range:');%could set command allowing another tab to appear!
f.sg_plot_button=uicontrol('Parent',f.plottab_v1,'style','pushbutton',...
    'string','PlotSpecgram','enable','off');%callback set later. Not enabled
%until sg is run
set(f.plottab_v1,'Sizes',[-0.8 -1.2 -.5 -0.5 -1 -1]);

%third column
f.plottab_v2=uiextras.VBox('Parent',f.plottab);%3rd column
uicontrol('Parent',f.plottab_v2,'style','text','string','0 time:');
uicontrol('Parent',f.plottab_v2,'style','text','string','+/- Clim for base and mean sub:');
f.BaselineStart=uicontrol('style','edit','string',' ','Parent',f.plottab_v2,...
    'BackgroundColor','w');
f.FRangeStart=uicontrol('style','edit','string','4','Parent',f.plottab_v2,...
    'BackgroundColor','w');
uicontrol('Parent',f.plottab_v2,'style','text','enable','off');%just a spacer

%fourth column
f.plottab_v3=uiextras.VBox('Parent',f.plottab);%fourth column'
f.zeroTime=uicontrol('Parent',f.plottab_v3,'style','edit',...
    'backgroundcolor','w','string','');%time set to be 0
f.clim_Mean_Base=uicontrol('Parent',f.plottab_v3,'style','edit',...
    'string',10,'backgroundcolor','w');
f.BaselineEnd=uicontrol('style','edit','string',' ','Parent',f.plottab_v3,...
    'BackgroundColor','w');
f.FRangeEnd=uicontrol('style','edit','string','24','Parent',f.plottab_v3,...
    'BackgroundColor','w');
uicontrol('Parent',f.plottab_v3,'style','text','enable','off');%just a spacer

%third tab for the two group test calculation and 2 plotting options
%(p-values and baseline subtracted spectrogram with non-sig transparent) as
%well as option for p-value cutoff (could be a slider?).
f.TGTtab=uiextras.HBox('Parent',f.tab,'Enable','off');%horizotal

%first column
f.TGTtab_c1=uiextras.VBox('Parent',f.TGTtab);%%first column
f.calculateTGT=uicontrol('Parent',f.TGTtab_c1,'string',...
    'Calculate TGT');%button for calculating TGT and saving in figure
uicontrol('Parent',f.TGTtab_c1,'style','text',...
    'string','Freq for topoplot:');
f.topoFreq=uitcontrol('Parent',f.TGTtab_c1,'style','edit',...
    'backgroundcolor','w');
set(f.TGTtab_c1,'Sizes',[-0.7 -0.15 -0.15]);

%second column
f.TGTtab_c2=uiextras.VBox('Parent',f.TGTtab);%second column
% uicontrol('Parent',f.TGTtab_c2,'style','text','string',...
%     'Use FDR by channel:');
uicontrol('Parent',f.TGTtab_c2,'style','text','string',...
    '-log10 max p for p-value plot (sign reflects direction):');
f.prange=uicontrol('Parent',f.TGTtab_c2,'style','edit','string','4');
uicontrol('Parent',f.TGTtab_c2,'style','text','string','','Enable','off');%spacer
uicontrol('Parent',f.TGTtab_c2,'style','text','string','Chosen p-cutoff:');
f.p_cutoff=uicontrol('Parent',f.TGTtab_c2,'style','edit','string',...
    '0.05','backgroundcolor','w');
f.plotSpec_WithTGTChoose=uicontrol('Parent',f.TGTtab_c2,'string',...
    'plotSpec with Chosen Cutoff','enable','off');%****%
f.plotTopo_WithTGTChoose=uicontrol('Parent',f.TGTtab_c2,'string',...
    'Topoplot with Chosen Cutoff','enable','off');
set(f.TGTtab_c2,'Sizes',[-.25 -.75 -1 -.25 -.75 -1 -1]);

f.TGTtab_c3=uiextras.VBox('Parent',f.TGTtab);%third column
% f.choosePcutoff=uicontrol('Parent',f.TGTtab_c3,'style','checkbox',...
%     'value',0);
%below is to plot the TGT p-values as the -log10 on an imagesc
f.plotTGTp=uicontrol('Parent',f.TGTtab_c3,'string',...
    'Plot p-values','enable','off');
f.baseInFDR=uicontrol('Parent',f.TGTtab_c3,'style','checkbox',...
    'string','Use baseline in FDR','Value',0);%to use baseline p-values in FDR calculation
uicontrol('Parent',f.TGTtab_c3,'style','text','string',...
    'Overall FDR alpha 0.05:');%[] calculate and place to right the overall FDR p
f.overallTGTp_pt05=uicontrol('Parent',f.TGTtab_c3,'style',...
    'text','string',' ','backgroundcolor','w');%gets set once run
f.plotSpec_WithTGTFDR=uicontrol('Parent',f.TGTtab_c3,'string',...
    'plotSpec with Individual FDR Cutoff','enable','off');
f.plotTopo_WithTGTFDR=uicontrol('Parent',f.TGTtab_c3,'string',...
    'Topoplot with FDR Cutoff','enable','off');
set(f.TGTtab_c3,'Sizes',[-1 -1 -.25 -.75 -1 -1]);


%set callbacks here so that all other handles available:
set(f.mw_w,'callback',{@calculateFRandBase,f,eeg(1)});
set(f.mw_s,'callback',{@calculateFRandBase,f,eeg(1)});
set(f.tapers,'callback',{@calculateFRandBase,f,eeg(1)});
set(f.calculate,'callback',{@calculateSG,f,eeg});
% set(f.mw_w,'Callback',{@setFR_Callback,f});%not necessary any more
set(f.channels,'callback',{@channels_Callback,f});
set(f.ten20,'callback',{@channels_Callback,f});%so if choose 10-20 will set them
% set(f.channelFavList,'callback',{@channels_Callback,f});
set(f.sg_plot_button,'Callback',{@plotSG,f});
set(f.baseInFDR,'Callback',{@calculateOverallFDR,f})
set(f.calculateTGT,'Callback',{@calculateTGT,f});
set(f.plotTGTp,'Callback',{@plotTGTp,f});
set(f.plotSpec_WithTGTFDR,'Callback',{@plotSpec_WithTGT,eeg(1).chanlocs,f,0,0});%First flag for FDR, second for topoplot
set(f.plotSpec_WithTGTChoose,'Callback',{@plotSpec_WithTGT,eeg(1).chanlocs,f,1,0});
set(f.plotTopo_WithTGTChoose,'Callback',{@plotSpec_WithTGT,eeg(1).chanlocs,f,0,1});
set(f.plotTopo_WithTGTFDR,'Callback',{@plotSpec_WithTGT,eeg(1).chanlocs,f,1,1});

set(f.TGTtab,'Enable','off');%done at end since may have been enabled by adding stuff

%name tabs
f.tab.TabNames={'SGparams','SGplot','TGTplot'};
f.tab.SelectedChild=1;


%use enable to enable the plotting only once sg is run
%% function to calculate the frequency resolution based on MW and tapers.
%also calculates the baseline to show user potential values
    function calculateFRandBase(hObject,eventdata,f,eeg) %just gets eeg(1)
        fres=sprintf('Freq Res is %.2f Hz',...
            (str2double(get(f.tapers,'string'))+1)/str2double(get(f.mw_w,'string')));
        set(f.fr,'string',fres);
        
        %calculate the range of potential baselines based on mtspecgramc
        %requires that mw step set
        if ~isempty(str2double(get(f.mw_s,'string'))) && ~isempty(str2double(get(f.mw_w,'string')))
            Nwin=round(eeg.srate*str2double(get(f.mw_w,'string')));%number of samples in window
            Nstep=round(str2double(get(f.mw_s,'string'))*eeg.srate);
            winstart=1:Nstep:size(eeg.data,2)-Nwin+1;
            winmid=winstart+round(Nwin/2);
            t=winmid/eeg.srate;%this is the time steps
            baselineTimesString=sprintf('(range %.3g to %.3g sec)',t(1),t(end));
            set(f.baselineTimes,'string',baselineTimesString);
        end
    end



%% small function to set baseline start (initially to set freq res now off).
%     function setFR_Callback(hObject,eventdata,f)%event data not used
%         %this uses the moving window to set the  start of
%         %the baseline. %modify to show error if FR too small
%         width=str2double(get(hObject,'string'));
%         if isnan(width)
%             errordlg('MW Width needs a numeric value','Bad Input','modal');
%             uicontrol(hObject);%to go back to that edit input
%             return
%         end
% %         set(f.fr,'string',num2str(2/width));%minimum based on length
%         set(f.BaselineStart,'string',num2str(width/2));
%     end
%% function to turn off plotting once new channels chosen and select channels
    function channels_Callback(hObject,eventdata,f)
        if get(f.ten20,'value')%if 10-20 chosen
            ten20list={'FP1','FP2','F7','F3','FZ','F4','F8','T3',...
                'C3','CZ','C4','T4','T5','P3','PZ','P4','T6','O1','O2'};
            
            
            
            s=1;%for indexing in loop below
            for in=1:length(ten20list) %go through channels and look for matches
                if sum(strcmpi(ten20list{in},f.ChannelList))%if a match
                    selectedCh(s)=find(strcmpi(ten20list{in},f.ChannelList));%produces index of match
                    s=s+1;
                end
            end
            set(f.channels,'value',selectedCh);
        end
        %if change channels chosen, then force recalculate before plot
        set(f.sg_plot_button,'enable','off');
        set(f.TGTtab,'Enable','off');
        set(f.plotTGTp,'enable','off');
        set(f.plotSpec_WithTGTFDR,'enable','off');
        set(f.plotSpec_WithTGTChoose,'enable','off');
        set(f.channelsSelected,'string',num2str(get(f.channels,'value')));%put in the list below the channels
    end



%% Function for calculating spectrogram
%need to decide if to rerun each time or run once and then save the output
%in the figure using guihandles and then guidata
    function calculateSG(hObject,eventdata,f,eeg)
        %set up parameters for the calculation
        if isempty(str2double(get(f.mw_w,'string'))) || isempty(str2double(get(f.mw_s,'string')))%if no mw set
            errordlg('Need to set moving window')
            f.tab.SelectedChild=1;
            return
        end
        mw(1)=str2double(get(f.mw_w,'string'));
        mw(2)=str2double(get(f.mw_s,'string'));
        if mw(2)>mw(1) %wouldn't make sense to have the step bigger than the window
            errordlg('Step size bigger than window, likely error');
            f.tab.SelectedChild=1;
            return
        end
        params.tapers(2)=str2double(get(f.tapers,'string'));
        params.tapers(1)=params.tapers(1)*2+1;
        %         if get(f.channelFavList,'value')==1 %if 'none' favorite list
        channels=str2double(get(f.channelsSelected,'string'));%use the selected channels
        %         else
        %             channels=f.channelFav.numbers{get(f.channelFavList,'value')};
        %             set(f.channels,'value',channels);%so see which channels were chosen and code below works
        %         end
        
        params.trialave=0;
        params.Fs=eeg(1).srate;
        params.pad=-1;
        
        for e2=1:length(eeg) %since might be two to run on 
            if get(f.lap,'value')%if laplacian chosen
                eeg(e2).data=MakeLaplacian(eeg(e2).data,eeg(e2).chanlocs);
            end
        
        %run the spectrogram and plot, assuming this is fast
        
            for c=1:length(channels)
                %Sg is time x freq x trialxchannel
                %             fighandles=guihandles(f.cf);%handles for the control figure
                %then store the data in the figure itself
                [spec(e2).Sg(:,:,:,c),spec(e2).t,spec(e2).freq]=mtspecgramc(squeeze(eeg(e2).data(channels(c),:,:))...
                    ,mw,params);

            end
        %         guidata(f.cf,fighandles);
        
        %save variables for plotting and TGT calculations
        spec(e2).mw=mw;
        spec(e2).params=params;
        
        %save the results in the gui (better to switch to object [])
        set(f.cf,'userdata',spec);
        %           set(f.calculate,'backgroundcolor','r');
        %           pause(0.25)
        %           set(f.calculate,'backgroundcolor','b');
        end
        set(f.sg_plot_button,'enable','on');
        
        set(f.TGTtab,'Enable','on') %but not the codes within until TGT calculated
        set(f.plotTGTp,'enable','off');
        set(f.plotSpec_WithTGTFDR,'enable','off');
        set(f.plotSpec_WithTGTChoose,'enable','off');
    end

%% plot SG
    function plotSG(hObject,eventdata,f)
        %         %check to ensure okay
        %         if get(f.meansub,'value') && get(f.basesub,'value')
        %             errordlg('Can''t do both base sub and mean sub');
        %             return
        %         end
        
        sgfig=figure;
        set(sgfig,'Name',[f.filename{1} ' Spectrogram']);
        channels=str2double(get(f.channelsSelected,'string'));
        %next determine the plotting frequency range
        spec=get(f.cf,'userdata');%spec will be 1x2 if two datasets
        Sg=spec(1).Sg; %Sg is time x freq x trial x channel (4 dimensions!)
        freq=spec(1).freq; t=spec(1).t;
        
        cLimMandB=str2double(get(f.clim_Mean_Base,'string'));%clim for mean and base subtracted
        cLimMandB=[-cLimMandB cLimMandB];
        
        zeroTime=str2double(get(f.zeroTime,'string'));
        if isempty(zeroTime)%if no time placed then leave as default
            zeroTime=0;
        end
        t_plot=t-zeroTime;
        
        %plot the data based on the chosen options
        for c=1:size(Sg,4)%only plotting from channels chosen before
            pfr=(freq>=str2double(get(f.FRangeStart,'string'))) & (freq<=str2double(get(f.FRangeEnd,'string')));
            
            subplot(length(channels),1,c);
            if get(f.plotAvg,'value') %if plot avg, otherwise baseline subtractions not programmed though could be
                if get(f.meansub,'value') %if mean subtract
                    imagesc(t_plot,freq(pfr),detrend...
                        (squeeze(10*log10(mean(Sg(:,pfr,:,c),3))),'constant')',...
                        cLimMandB);%note need to remove mean after
                    %transposing so that you're removing the mean across
                    %time
                    xlabelText='Seconds (Mean subtracted)';
                    
                elseif get(f.basesub,'value') %if want to do baseline subt
                    %btr is baseline time range
                    bStart=str2double(get(f.BaselineStart,'string'));
                    bEnd=str2double(get(f.BaselineEnd,'string'));
                    btr=t>=bStart &  t<=bEnd;
                    if ~sum(btr) %if no values between range
                        errordlg('No times within baseline range');
                    end
                    meanBaseline=mean(Sg(btr,:,:,c),1);%[]check this!
                    meanBaseline=mean(meanBaseline,3);%next mean across trials
                    meanBaseline=repmat(meanBaseline,size(Sg,1),1);%make a 2D matrix
                    %Next take mean first to conver to 2D then divide by
                    %baseline (same as subtracting the logs)
                    SgBaseCorr=squeeze(mean(Sg(:,:,:,c),3))./meanBaseline;%dividing by power is same as subtracting log
                    %[]then need to repmat it to be correct length
                    %then need log of it before subtracting
                    imagesc(t_plot,freq(pfr),10*log10(SgBaseCorr(:,pfr))',cLimMandB);
                    titleText=sprintf('(Baseline (%.2f to %.2f sec) subtracted)',bStart,bEnd);
                    xlabelText=['Seconds ' titleText];
                    
                elseif get(f.matchedsub,'value') %if want to subtract matching time range from second half of the trial
                    %split data in half and subtract second half from first
                    if mod(length(t_plot),2)%first determine if even or odd number of times, and make even
                        t_plot=t_plot(1:end-1);
                        Sg=Sg(1:end-1,:,:,:);
                    end
                    halfpt=length(t_plot)/2;%halfway point in time
                    %Next plot 1st half minus second half
                    imagesc(t_plot(1:halfpt),freq(pfr),10*log10(mean(Sg(1:halfpt,pfr,:,c),3)./...
                        mean(Sg(halfpt+1:end,pfr,:,c),3))',cLimMandB);
                    xlabelText='Seconds (Second half subtracted off of first)';
                elseif get(f.othereegsub,'value')
                    imagesc(t_plot,freq(pfr),10*log10(mean(Sg(:,pfr,:,c),3)./...
                        mean(spec(2).Sg(:,pfr,:,c),3))',cLimMandB);
                    xlabelText='Seconds (Second EEG subtracted off of first)';
                else %if standard
                    imagesc(t_plot,freq(pfr),squeeze(10*log10(mean(Sg(:,pfr,:,c),3))'));
                    xlabelText='Seconds (Average Spectrogram)';
                end
                if c==size(Sg,4)
                    xlabel(xlabelText,'fontsize',12);
                end
            else %plot against trial number
                
                %if not using averaging, turn off baseline subt and subt mean
                set(f.meansub,'value',0);
                set(f.basesub,'value',0);
                newtime=linspace(1,size(Sg,3)+1,length(t)*size(Sg,3));
                Splot=squeeze(Sg(:,:,:,c));
                Splot=permute(Splot,[2 1 3]);
                Splot=reshape(Splot,size(Splot,1),size(Splot,2)*size(Splot,3))';
                imagesc(newtime,freq(pfr),10*log10(Splot(:,pfr)'));
                if c==size(Sg,4)
                    xlabel('trials (non-averaged Spectrogram)','FontSize',12);
                end
            end
            
            axis xy;
            colorbar
            ylabel(f.ChannelList(channels(c)));
            if c<size(Sg,4) %if not the bottom one
                set(gca,'xtick',[]);
            end
        end
    end

%% Function for calculating TGT
    function calculateTGT(hObject,eventdata,f)
        
        %first, load in the spectrogram results
        spec=get(f.cf,'userdata');%if two datasets will be size 1x2
         %spec.Sg is time x freq x trial x channel with only the chosen
        %channels. Also contains spec.t, spec.freq, spec.mw, spec.params
        
        %initialize p-values as freq x time x channel
            spec(1).tgtp_value=zeros(size(spec(1).Sg,2),size(spec(1).Sg,1),size(spec(1).Sg,4));
            spec(1).dz=spec(1).tgtp_value;
            
        %if comparing to baseline (default behavior)
        if ~get(f.matchedsub,'value') && ~get(f.othereegsub,'value')
            %first make sure that baseline values are selected
            baseStart=str2double(get(f.BaselineStart,'string'));
            baseEnd=str2double(get(f.BaselineEnd,'string'));
            if isnan(baseStart) || isnan(baseEnd)
                errordlg('First set baseline range');
                f.tab.SelectedChild=2;%move back to second tab
                return
            end

            %next determine the baseline
            if ~sum(spec(1).t<baseStart | spec(1).t>baseEnd) %if nothing outside baseline
                errordlg('No data outside of baseline');
                f.tab.SelectedChild=2;
            end
            firstTimeIndex=find(spec(1).t>=baseStart,1,'first');
            lastTimeIndex=find(spec(1).t<=baseEnd,1,'last');
            
            for c=1:size(spec(1).Sg,4) %for each channel

                %create mean baseline with non-overlapping windows by moving by mw width
                %divided by mw step (note this gives you how many indices of time
                %to move, not actual time to move) so not to use any overlaps.
                %base is now freq x sample
                base=squeeze(mean(spec(1).Sg(firstTimeIndex:spec(1).mw(1)/spec(1).mw(2):...
                    lastTimeIndex,:,:,c),1));

                for tp=1:size(spec(1).Sg,1) %for each time point including those in baseline
                    %dz, vdz and adz are all #of freq x 1

                    %in below code, both inputs are freq x trial
                    [spec(1).dz(:,tp,c),vdz]=tgt_spectrum_input(squeeze(spec(1).Sg...
                        (tp,:,:,c)),base,0.05);%save dz for plotting its
                    %sign later. Note that base is second so that
                    %get same sign of dz as doing a baseline subtraction.
                    spec(1).tgtp_value(:,tp,c)=2*(1-normcdf(abs(spec(1).dz(:,tp,c)),0,sqrt(vdz)));%calculate the p-value
                end
            end
            
            %next is version if comparing two spectrograms (or first to
            %second half)
        else 
            if get(f.matchedsub,'value') %if comparing first to second half.
            %first need to ensure length of data is even (if two spectra
            %will need to ensure they're equal length [])
                if mod(length(spec(1).t),2)
                    spec(1).t=spec(1).t(1:end-1);
                    spec(1).Sg=spec(1).Sg(1:end-1,:,:,:);
                end
            
                %first need to reinitialize spec.dz and spec.tgtp_value to be
                %half the time length
                spec(1).tgtp_value=zeros(size(spec(1).Sg,2),size(spec(1).Sg,1)/2,size(spec(1).Sg,4));
                spec(1).dz=spec(1).tgtp_value;
                   
                %divide it up to two datasets
                Sg1=spec(1).Sg(1:length(spec(1).t)/2,:,:,:);
                Sg2=spec(1).Sg(((length(spec(1).t)/2)+1):end,:,:,:);
            else %if comparing two different datasets
                Sg1=spec(1).Sg;
                Sg2=spec(2).Sg;
            end
            
            for c=1:size(Sg1,4) %for each channel
                for tp=1:size(Sg1,1) %for each time point
                    [spec(1).dz(:,tp,c),vdz]=tgt_spectrum_input(squeeze(Sg1...
                        (tp,:,:,c)),squeeze(Sg2(tp,:,:,c)),0.05);%saving dz
                    spec(1).tgtp_value(:,tp,c)=2*(1-normcdf(abs(spec(1).dz(:,tp,c)),0,sqrt(vdz)));%calculate the p-value
                end
            end
               
        end
        
        set(f.cf,'userdata',spec);%overwrite to add on the TGT results (only spec(1) will have them)
        set(f.plotTGTp,'enable','on');
        set(f.plotSpec_WithTGTFDR,'enable','on');
        set(f.plotSpec_WithTGTChoose,'enable','on');
        set(f.plotTopo_WithTGTChoose,'enable','on');
        set(f.plotTopo_WithTGTFDR,'enable','on');
        
        
        calculateOverallFDR(hObject,eventdata,f)
    end

%% function to calculate overall FDR
    function calculateOverallFDR(hObject,eventdata,f)
        
        
        spec=get(f.cf,'userdata');%if two datasets will be size 1x2
        %next calculate the overall FDR as a guide and place in the control
        %figure
        pfr=(spec(1).freq>=str2double(get(f.FRangeStart,'string'))) & (spec(1).freq<=str2double(get(f.FRangeEnd,'string')));
        if get(f.baseInFDR,'value') || get(f.matchedsub,'value')%if want to use the baseline in FDR in case baseline is large or if no baseline
            pvaluesInPFR=spec(1).tgtp_value(pfr,:,:);%just pvalues within the plotting frequency range
        else %don't use the baseline
            baseStart=str2double(get(f.BaselineStart,'string'));
            baseEnd=str2double(get(f.BaselineEnd,'string'));
            pvaluesInPFR=spec(1).tgtp_value(pfr,spec(1).t<baseStart | spec(1).t>baseEnd,:);%doesn't include those in baseline
        end
        overallFDRalpha0pt05=Anitafdr(pvaluesInPFR(:),0.05);
        if isempty(overallFDRalpha0pt05)%if no p-values below the corrected alpha of 0.05
            set(f.overallTGTp_pt05,'string','No p below FDR cutoff');
        else
            set(f.overallTGTp_pt05,'string',sprintf('%.g',overallFDRalpha0pt05));
        end
    end

%% Function for plotting the -log10 of the TGT p-values only
    function plotTGTp(hObject,eventdata,f)
        spec=get(f.cf,'userdata'); %then want to use spec.tgtp_value
        %which is organized as freq x time point x channel
        pval=spec(1).tgtp_value; %for easier coding
        prange=str2double(get(f.prange,'string'));%the clim range inputted by user
        figure;
        if ~get(f.matchedsub,'value') && ~get(f.othereegsub,'value') %if not comparing EEGs
            set(gcf,'Name',[f.filename{1} ' TGT p-values']);
        elseif get(f.matchedsub,'value')
            set(gcf,'Name',[f.filename{1} ' TGT p-values 1st vs 2nd half']);
        elseif get(f.othereegsub,'value')
            set(gcf,'Name',['TGT p ' f.filename{1} ' vs ' f.filename{2}]);
        end
        channels=str2double(get(f.channelsSelected,'string'));
        
        zeroTime=str2double(get(f.zeroTime,'string'));
        if isempty(zeroTime)%if no time placed then leave as default
            zeroTime=0;
        end
        t_plot=spec(1).t-zeroTime;
        if get(f.matchedsub,'value')%**[] remove this when converting this to comparing two different spectra
                t_plot=t_plot(1:length(t_plot)/2);
        end
        for c=1:size(pval,3) %for each channel;
            pfr=(spec(1).freq>=str2double(get(f.FRangeStart,'string'))) & (spec(1).freq<=str2double(get(f.FRangeEnd,'string')));
            subplot(length(channels),1,c);
            %in line below, multiply by sign of dz to show direction of
            %change
            imagesc(t_plot,spec(1).freq(pfr),squeeze(sign(spec(1).dz(pfr,:,c)).*-log10(pval(pfr,:,c))),[-prange,prange]);
            axis xy
            colorbar
            if c==size(pval,3) %if the final plot on the bottom show the x-axis
                xlabel('Seconds','fontsize',12);
            else
                set(gca,'xtick',[]);
            end
            ylabel(f.ChannelList(channels(c)));
        end
    end

%% Function for plotting the spectrogram or topoplot with non significant values hidden
    function plotSpec_WithTGT(~,~,chanlocs,f,FDR,topo)
        %code based on the spectrogram plotting code above but suppress
        %non-significant TGT values
        
        sgfig=figure;
        if ~get(f.matchedsub,'value') && ~get(f.othereegsub,'value') %if not comparing EEGs
            set(sgfig,'Name',[f.filename{1} 'Sig. Spectrogram']);
        elseif get(f.matchedsub,'value')
            set(sgfig,'Name',[f.filename{1}, 'Sig. Sgram 1st vs 2nd half']);
        elseif get(f.othereegsub,'value')
            set(sgfig,'Name',['Sig. Sgram ' f.filename{1} ' vs ' f.filename{2}]);
        end
        
        channels=str2double(get(f.channelsSelected,'string'));
        %next determine the plotting frequency range
        spec=get(f.cf,'userdata');
        Sg=spec(1).Sg; freq=spec(1).freq; t=spec(1).t;
        pval=spec(1).tgtp_value;%frequency x time point x channel
        
        cLimMandB=str2double(get(f.clim_Mean_Base,'string'));%clim for base subtracted
        cLimMandB=[-cLimMandB cLimMandB];
        
        zeroTime=str2double(get(f.zeroTime,'string'));
        if isempty(zeroTime)%if no time placed then leave as default
            zeroTime=0;
        end
        t_plot=t-zeroTime;
        if get(f.matchedsub,'value')%since only plotting first half of data (remove if convert this to comparing two spectra
            if mod(length(t_plot),2)%first determine if even or odd number of times, and make even
                    t_plot=t_plot(1:end-1);
                    Sg=Sg(1:end-1,:,:,:);
            end
            t_plot=t_plot(1:(length(t_plot)/2));%use only the first half of time
        end
        
        %plot the data based on the chosen options
        for c=1:size(Sg,4)%only plotting from channels chosen before
            pfr=(freq>=str2double(get(f.FRangeStart,'string'))) & (freq<=str2double(get(f.FRangeEnd,'string')));
            
            %Here calculate the local FDR cutoff. Can choose if to
            %include baseline in the calculation
            if get(f.baseInFDR,'value') || get(f.matchedsub,'value') || get(f.othereegsub,'value') %if want to use the baseline or baseline isn't used here
                pvaluesInPFR=pval(pfr,:,c);%for the PFR and channel
            else %if want to ignore the baseline in the local FDR calculation
                baseStart=str2double(get(f.BaselineStart,'string'));
                baseEnd=str2double(get(f.BaselineEnd,'string'));
                if isnan(baseStart) || isnan(baseEnd)
                    errordlg('First set baseline range');
                    f.tab.SelectedChild=2;%move back to second tab
                    return
                end
                pvaluesInPFR=pval(pfr,t<baseStart | t>baseEnd,c);%just the plotted frequency range, time after baseline and channel
            end
            
            if FDR %use FDR cutoff chosen by user
                local_Pcut=str2double(get(f.p_cutoff,'string'));%the value chosen by user
            else %use the local FDR cutoff
                local_Pcut=Anitafdr(pvaluesInPFR(:),0.05);%FDR just for each channel and PFR
                if isempty(local_Pcut)
                    local_Pcut=NaN;
                end
            end
            %
            subplot(length(channels),1,c);
            
            if get(f.meansub,'value')
                errordlg('Mean subtraction selected, change to another option');
                return
            end
            
            if get(f.basesub,'value') %if baseline subtraction used
                %btr is baseline time range
                %[] need to then take average and subtract off
                btr=t>=str2double(get(f.BaselineStart,'string')) & ...
                    t<=str2double(get(f.BaselineEnd,'string'));
                if ~sum(btr) %if no values between range
                    errordlg('No times within baseline range');
                end
                meanBaseline=mean(Sg(btr,:,:,c),1);%mean of all times
                meanBaseline=mean(meanBaseline,3);% mean across trials
                meanBaseline=repmat(meanBaseline,size(Sg,1),1);%make a 2D matrix same size as rest of data
                %Next take mean first to conver to 2D then divide by
                %baseline (same as subtracting the logs)
                SgBaseCorr=squeeze(mean(Sg(:,:,:,c),3))./meanBaseline;
            elseif get(f.matchedsub,'value') %if subtracting second half from first half (note cut in half above)              
%                     halfpt=length(t_plot)/2;%halfway point in time, but
%                     keeps getting cut in half each time through!
                    %Next plot 1st half minus second half
                    SgBaseCorr=squeeze(mean(Sg(1:length(t_plot),:,:,c),3))./...
                        squeeze(mean(Sg(length(t_plot)+1:end,:,:,c),3));
            elseif get(f.othereegsub,'value') %if subtracting second EEG from first
                SgBaseCorr=squeeze(mean(Sg(:,:,:,c),3))./...
                    squeeze(mean(spec(2).Sg(:,:,:,c),3));
            end
                
            
            
           
            %set alpha
            if isnan(local_Pcut) %if no significant values
                alpha=repmat(0.2,sum(pfr),size(pval,2));
            else
                alpha=(pval(pfr,:,c)>local_Pcut)*0.2;%find the non-significant values and set to be transparent
                alpha(alpha==0)=1;%set significant valuse to be 1
            end
            
            
            %plot          
            imag=imagesc(t_plot,freq(pfr),10*log10(SgBaseCorr(:,pfr))',cLimMandB);
            set(imag,'AlphaData',alpha);%alpha set on the image object
            if c==size(Sg,4)
                xlabel('Seconds','fontsize',12);
            end
            axis xy;
            colorbar
            pcutAsString=sprintf('%0.2e',local_Pcut);
            ylabel([f.ChannelList(channels(c)) pcutAsString]);
            if c<size(Sg,4) %if not the bottom one
                set(gca,'xtick',[]);
            end
        end
    end

% %% function for plotting topoplots with significant channels circled
%     function topoplot_WithTGT(~,~,chanlocs,f,FDR)
%         topofig=figure;
%         if ~get(f.matchedsub,'value') && ~get(f.othereegsub,'value') %if not comparing EEGs
%             set(topofig,'Name',[f.filename{1} 'Sig. Topoplots']);
%         elseif get(f.matchedsub,'value')
%             set(topofig,'Name',[f.filename{1}, 'Sig. Topoplots 1st vs 2nd half']);
%         elseif get(f.othereegsub,'value')
%             set(topofig,'Name',['Sig. Topoplots ' f.filename{1} ' vs ' f.filename{2}]);
%         end
%         
%         channels=str2double(get(f.channelsSelected,'string'));%numbers representing the channels
%         spec=get(f.cf,'userdata');
%         f.topoFreq%neded to determine the frequency
%         %will need to know which channels were selected for the locations
%         
    end
        
end%whole function
