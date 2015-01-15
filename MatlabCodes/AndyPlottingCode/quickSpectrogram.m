function quickSpectrogram
%gets data from the graphs, assuming all same length, and runs spectra on
%them with preset frequency resolution.
%[] Future version can make GUI to vary
%the number of tapers and moving window and frequency range of interest
%(like subplotSpectrogram does). Might be nice to have zoom change the clim
%to fit only the range in the zoom so don't need to redo with a smaller
%range
%version 2 has a GUI so can replot without recalculating
%version 3 8/3/11 added clim to end of the imagesc for the zscored version
%10/7/11 added saving of spectrogram data for calculating total power
%though only for one type of spectrum and saves same name each time
%10/12/11 changed tscore to de-mean following JV's advice for doing this
%with subplotSpectrogram (data already normalized by logging so no need to
%divide by the standard deviation since low SD makes it big and don't necessarily want that)
%also add in fourth plot of the acceleration so
%On 10/14 fixed major bug where was using the selected x range to calculate
%the Hz rather than the spacing between the points.
%10/14/11 version 4 simplify time axis coding and add buttons to plot total
%power over time at selected frequency range.
%10/20/11 version 5 add option to save the data and then reload it so don't need to
%recalculate each time and can vary plotting ranges. Consider automating
%name to have date, start and end times []. Also need to test it [].
%4/4/11 added uipickfiles
%4/26/12 added catch for minimum frequency resolution 2/movingwin(1)
%5/14/12 added option to average together the spectra of all traces. Also
%now initializes the ydata matrix to speed it up. 

%%
%load saved data
if strcmpi(input('Used saved file? (y/n) [n]: ','s'),'y')
%     [SGfilename SGpath]=uigetfile('*quickSG.mat','Pick quickSG file');
    SGpath=uipickfiles('type',{'*quickSG.mat','SG file'},'output','char','prompt','Pick quickSG file');
    if isempty(SGpath) || isnumeric(SGpath)
        return
    end
    SGfile=load(SGpath);
    [path,SGfilename]=fileparts(SGpath);
    Sg=SGfile.Sg;
    tg=SGfile.tg;
    fg=SGfile.fg;
    x=SGfile.x;
    xdata=SGfile.xdata;
    ydata=SGfile.ydata;
    clear SGfile;
    savename=SGfilename(1:end-7);
    if x(1)>1e5 %implying that it's in matlab time units (days)
        %subtract 1 since starts at 1 instead of 0, then convert to days,
        %then add start time from above.
        tplot=(tg-1)/(24*60*60)+x(1);
    else
        tplot=tg;
    end
else
    
    %%
    %defaults
    movingwindow=[5 1];
    freqResolution=1;
    timeDurationLimit=60*60; %limit in seconds at which you get a warning
    fprintf('Running with mw=[%.0f %.0f] and FR=%.0f\n',movingwindow(1),movingwindow(2),freqResolution);
    if strcmpi(input('Change (y/n) [n]? ','s'),'y')
        movingwindow=input('Moving window in seconds (as [window slide]): ');
        fprintf('With that MW, min FR is %.0f/%.0f = %.3f Hz\n',2,movingwindow(1),2/movingwindow(1));
        freqResolution=input('Frequency resolution (put in formula above if want min): ');
    end
    
    savename=input('Savename: ','s');
    %%%%%
    
    disp('select figure of interest then press any key');
    pause
    axes=get(gcf,'Children');%get the figure information
    curves=get(axes,'Children');%get the data from the plots
    if iscell(curves)%added 10/13 since want to look at figure created by timesync and was in cell form. Not good general approach
        c=curves{2};
        clear curves;curves=c;
    end
    
    xdata=get(curves(1),'XData'); %same for each one
    ydata=zeros(length(xdata),length(curves));%initialize
    for i=1:length(curves) %for each curve on the graph      
        ydata(:,i)=get(curves(i),'YData');
    end
    
    if length(curves)>1
        if input('Average together all spectra (1/0) [0]? : ')
            params.trialave=1;
        else
            params.trialave=0;
        end
    end
    
    if input('Use all data? (1/0) [0]: ')
        x=[min(xdata);max(xdata)];
    else
        figure(gcf);
        disp('select start and end times from figure');
        figure(gcf); %make figure the focus
        while 1
            [x]=ginput(2);
            if x(1)>x(2) %meaning user clicked left of the first one by accident
                disp('Second selection before 1st, try again.');
                clear x;
            else
                break
            end
        end
        
    end
    if x(1)>1e5 %implying that it's in matlab time units (days)
        timeduration=(x(2)-x(1))*24*60*60; %convert time into seconds from days
        %Fs is 1/difference between time points in seconds
        params.Fs=1/(mean(diff(xdata))*60*60*24); %use the average spacing to determine the Fs. seems to work best
    else %if x axis is in seconds
        params.Fs=1/mean(diff(xdata));
        timeduration=x(2)-x(1);
    end
    
    if timeduration>timeDurationLimit
        question=sprintf('Warning: %.00f minutes of data selected, may take a long time, \nWant to continue (c), run on first 10 minutes only (f), or abort (a) (c/f/a)[f]? ',timeduration/60);
        answer=input(question,'s');
        switch answer
            case 'a'
                return
            case 'c'
            otherwise
                timeduration=timeDurationLimit;
                if x(1)>1e5
                    x(2)=x(1)+timeduration/(24*60*60);
                else
                    x(2)=x(1)+timeduration;
                end
        end
    end
    
    params.pad=-1;
    params.tapers=[freqResolution/2 movingwindow(1) 1];
    %label with g to distinguish from regular spectra
    
    [Sg,tg,fg]=mtspecgramc(ydata(xdata>=x(1)&xdata<=x(2),:),movingwindow,params);
    if x(1)>1e5 %implying that it's in matlab time units (days)
        %subtract 1 since starts at 1 instead of 0, then convert to days,
        %then add start time from above.
        tplot=(tg-1)/(24*60*60)+x(1);
    else
        tplot=tg;
    end
    
    save([savename '_quickSG.mat'],'Sg','tg','fg','x','xdata','ydata');
end
%%
%plot

%first create control figure in case want to change parameters for plotting
controlFigure=figure;
set(controlFigure,'Name',' Spectrogram Control','Units','normalized','Position',[0.05 0.7 0.15 0.2]);
uicontrol('Parent',controlFigure,'Style','text','String','Frequency Range to plot:','Units','normalized','FontSize',12,'Position',[.1 0.7 0.5 0.15]);
rangeBox1=uicontrol('Parent',controlFigure,'Style','edit','Units','normalized','FontSize',12,'Position',[0.1 0.5 0.2 0.15],'String','0','BackgroundColor',[1 1 1]);
rangeBox2=uicontrol('Parent',controlFigure,'Style','edit','Units','normalized','FontSize',12,'Position',[0.4 0.5 0.2 0.15],'String','40','BackgroundColor',[1 1 1]);
uicontrol('Parent',controlFigure,'Style','text','String','De-mean: ','Units','normalized','FontSize',12,'Position',[0.1 0.9 0.25 0.1]);
detrendit=uicontrol('Style','checkbox','Units','normalized','Position',[0.4 0.9 0.1 0.1]);
uicontrol('Parent',controlFigure,'Style','text','String','+/- Clim (for demean): ','Units','normalized','FontSize',12,'Position',[0.6 0.8 0.4 0.2]);
climRangeBox=uicontrol('Parent',controlFigure,'Style','edit','Units','normalized','FontSize',12,'Position',[.7 .7 .2 .15],'String','5','BackgroundColor',[1 1 1]);
uicontrol('Parent',controlFigure,'Style','text','String','Power range: ','Units','normalized','FontSize',12,'Position',[0.6 0.4 0.4 0.2]);
powerMax=uicontrol('Parent',controlFigure,'Style','edit','Units','normalized','FontSize',12,'Position',[.7 .3 .2 .15],'String','-','BackgroundColor',[1 1 1]);
powerMin=uicontrol('Parent',controlFigure,'Style','edit','Units','normalized','FontSize',12,'Position',[.7 .1 .2 .15],'String','-','BackgroundColor',[1 1 1]);
uicontrol('Parent',controlFigure,'Units','normalized','Position',[.2 .2 .2 .1],'String','Spectra','Callback',{@Done_callback});
uicontrol('Parent',controlFigure,'Units','normalized','Position',[.2 .05 .2 .1],'String','TotalPwr','Callback',{@totalPlot});
uiwait %this command seems necessary to ensure it waits to select channels and press done.
%%

    function Done_callback(varargin)
        plottingFreqStart=str2double(get(rangeBox1,'String'));
        plottingFreqEnd=str2double(get(rangeBox2,'String'));
        detrenddo=get(detrendit,'Value'); %if 1 then plot values with mean removed
        climRange=str2double(get(climRangeBox,'String'));%for clim if detrending to ensure 0 is center and all the same
        powerRange(1)=str2double(get(powerMin,'String'));
        powerRange(2)=str2double(get(powerMax,'String'));
        uiresume
        quickSpectrogramDo(plottingFreqStart,plottingFreqEnd,detrenddo,climRange,powerRange)
    end
%%

    function totalPlot(varargin)
        plottingFreqStart=str2double(get(rangeBox1,'String'));
        plottingFreqEnd=str2double(get(rangeBox2,'String'));
        uiresume
        totalPlotDo(plottingFreqStart,plottingFreqEnd)
    end

%%
%here is actual figure
    function quickSpectrogramDo(plottingFreqStart,plottingFreqEnd,detrenddo,climRange,powerRange)
        
        figureHandle=findobj('name',[savename 'Spectrogram']);
        if isempty(figureHandle)
            figureHandle=figure;
        else
            figure(figureHandle);
            clf(figureHandle);
        end
        figure(figureHandle);
        set(figureHandle,'Name',[savename 'Spectrogram']);
        
        
        pfr=fg>plottingFreqStart & fg<plottingFreqEnd; %plottingFreqRange based on defaults at top
        for j=1:size(Sg,3)+1 %for each spectrogram
            
            if j==size(Sg,3)+1 %the final row plot the actual data within that time range to compare
                sp(j)=subplot(size(Sg,3)+1,1,size(Sg,3)+1);%put at end
                plot(xdata(xdata>=x(1)&xdata<=x(2)),ydata(xdata>=x(1)&xdata<=x(2),:)); dynamicDateTicks;axis tight;
                colorbar;
            else
                sp(j)=subplot(size(Sg,3)+1,1,j);
                if detrenddo
                    %                 ls=log10(Sg(:,pfr,j)); %log spectrum organized as time x freq, makes tscore code not used any more easier
                    imagesc(tplot,fg(pfr),detrend(10*(log10(Sg(:,pfr,j))),'constant')',[-climRange climRange]);%detrend to remove the mean
                else
                    if isnan(powerRange(1)) %if no power range set
                        imagesc(tplot,fg(pfr),10*(log10(Sg(:,pfr,j)))');%convert time to days then to matlab units
                    else
                        imagesc(tplot,fg(pfr),10*(log10(Sg(:,pfr,j)))',powerRange);
                    end
                    %next three lines to save the spectra and plot total power
                    %across the whole range below
                    %                 specSave{j}=10*(log10(Sg(:,pfr,j)))';
                    %                 tSave=((tg-1)/(24*60*60))+x(1);
                    %                 fSave=fg(pfr);
                end
                if x(1)>1e5
                    xlabel('time','FontSize',12);
                end
                axis xy
                colorbar
                if j==1
                    ylabel('x direction','Color','b');
                elseif j==2
                    ylabel('y direction','Color','g');
                else
                    ylabel('z direction','Color','r');
                end
            end
        end
        linkaxes(sp(1:end-1),'x');
        if x(1)>1e5
            %gcf means to apply to whole figure, keeplimits combined with last
            %makes the labels just on bottom
            %             tlabel(gcf,'keeplimits','Whichaxes','last');%to put time in units of minutes and hours
            spxlim=get(sp(1),'xlim');
            dynamicDateTicks(sp(1:end-1),'linked');
            set(sp(1),'xlim',spxlim);
            
            %         dynamicDateTicks(sp(size(Sg,3)+1)); zoom xon; %can't figure out how to link since different x axes
        end
        zoom xon;
        %         specx=get(sp(1),'Xlim');
        %         linkaxes(sp,'x');
        %         set(sp(end),'xlim',[x(1) x(2)]);
        %         set(sp(1:end-1),'xlim',specx);
        %     save('SpecData','specSave','tSave','fSave');
        %below is to plot the total power
        %     total=sum(specSave{1},1)+sum(specSave{2},1)+sum(specSave{3},1);
        %     figure;plot(tSave,total);
        %     dynamicDateTicks; axis tight;
    end

    function totalPlotDo(plottingFreqStart,plottingFreqEnd)
        figureHandle=findobj('name',[savename 'totalPlot']);
        if isempty(figureHandle)
            figureHandle=figure;
        else
            figure(figureHandle);
            clf(figureHandle);
        end
        figure(figureHandle);
        set(figureHandle,'Name',[savename 'totalPlot']);
        
        
        pfr=fg>plottingFreqStart & fg<plottingFreqEnd; %plottingFreqRange based on defaults at top
        for j=1:size(Sg,3)+1 %for each axis
            
            if j==size(Sg,3)+1 %the final row plot the actual data within that time range to compare
                sp(j)=subplot(size(Sg,3)+1,1,size(Sg,3)+1);%put at end
                plot(xdata(xdata>=x(1)&xdata<=x(2)),ydata(xdata>=x(1)&xdata<=x(2),:)); axis tight;
            else
                sp(j)=subplot(size(Sg,3)+1,1,j);
                plot(tplot,squeeze(sum(10*(log10(Sg(:,pfr,j))),2)));axis tight;
                if j==1
                    ylabel('x direction','Color','b');
                elseif j==2
                    ylabel('y direction','Color','g');
                else
                    ylabel('z direction','Color','r');
                end
            end
        end
        linkaxes(sp(1:end-1),'x');
        if x(1)>1e5
            spxlim=get(sp(1),'xlim');
            dynamicDateTicks(sp(1:end-1),'linked');
            set(sp(1),'xlim',spxlim);
            %             xlabel('seconds','FontSize',12);
            
        end
        zoom xon;
        
    end

end