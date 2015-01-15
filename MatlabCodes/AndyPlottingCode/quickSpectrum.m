function quickSpectrum
%gets data from the graphs, assuming all same length, and runs spectra on
%them with preset frequency resolution. Future version can make GUI to vary
%the number of tapers

%July 19 v2 added option to plot average including error bars and compare
%multiple selections. Requires varycolor for plotting colors.
%12/8/11 changed calculation of Fs to look at average spacing not just
%first one in case they vary
%12/9/11 allow user to click in the wrong order (high x then low x) and it
%switches it.


if strcmpi(input('Spectrum of each line (Rtn) or average (with error bars and multiple allowed) (a)? ','s'),'a')
    plotAvg=1;
    numSpec=input('How many to plot [1]? ');
    if isempty(numSpec)
        numSpec=1;
    end
else
    plotAvg=0;
    numSpec=1;
end

for ii=1:numSpec
    if plotAvg
        if input('Change time zoom (1 or Rtn)? ');
            timeZoom
        end
        [S{ii} f{ii} starttime{ii} Serr{ii}]=getData(plotAvg);       
    else
        [S f starttime]=getData(plotAvg);
    end
end

%plot after getting all the spectra
figure;
colors=varycolor(numSpec);
for j=1:numSpec
    if plotAvg
        errorBars=fill([f{j} fliplr(f{j})],[10*log10(Serr{j}(1,:)) fliplr(10*log10(Serr{j}(2,:)))],colors(j,:),'HandleVisibility','off');
        set(errorBars,'linestyle','none','facealpha',0.2); %to make the fill transparent
        hold on;
        plot(f{j},10*log10(S{j}),'Color',colors(j,:),'LineWidth',2);
        %add legend here ideally with start time (make a starttime matrix
        %and convert to strings!)
    else
        plot(f,10*log10(S));
        legend('x','y','z');
        title(['Spectrum from ',starttime,' to ',endtime]);
    end
end
if plotAvg
    legend(starttime);
end


    function [S f starttime Serr]=getData(plotAvg) %plotAvg is simply a 1 or 0
    disp('select figure of interest then press any key');
    pause
    disp('select start and end times from figure');
    axes=get(gcf,'Children');
    curves=get(axes,'Children');
    if iscell(curves)%added 10/13 since want to look at figure created by timesync and was in cell form. Not good general approach
        c=curves{2};
        clear curves;curves=c;
    end
    for i=1:length(curves) %for each curve on the graph
        xdata=get(curves(i),'XData'); %same for each one
        ydata(:,i)=get(curves(i),'YData');
    end

    [x]=ginput(2);%removed y from output since not used
    %added 12/9/11 since often click and it doesn't take so want to be able
    %to go backwards
    if x(1)>x(2)
        disp('x(1)>x(2) so will switch them.');
        [x(2) x(1)]=deal(x(1),x(2));
    end
    if x(1)>1e5 %implying that it's in matlab time units (days)
        timeduration=(x(2)-x(1))*24*60*60; %convert time into seconds from days
        %Fs is 1/difference between time points in seconds
        params.Fs=1/(mean(diff(xdata))*24*60*60);%new verion 12/8/11 better if irregular but not issue if splined
%          params.Fs=1/((xdata(2)-xdata(1))*24*60*60);%original version but a problem if irregular sampling
        starttime=datestr(x(1),13);
        endtime=datestr(x(2),13);
    else %if x axis is in seconds
        params.Fs=1/(xdata(2)-xdata(1));
        timeduration=x(2)-x(1);
        starttime=num2str(x(1));
        endtime=num2str(x(2));
    end

    %do check to see if >5 minutes since takes a while
    if timeduration>5*60
        question=sprintf('Warning: %.00f minutes of data selected, will take a long time, \nWant to continue (c), run on first 1 minute only (f), or abort (a) (c/f/a)[f]?',timeduration/60);
        answer=input(question,'s');
        switch answer
            case 'a'
                return
            case 'c'
            otherwise
                timeduration=60;%time in seconds
                if x(1)>1e5
                    x(2)=x(1)+timeduration/(24*60*60);%since in units of days
                    endtime=datestr(x(2),13);
                else
                    x(2)=x(1)+timeduration;
                    endtime=num2str(x(2));
                end
        end
    end
    params.pad=-1;
    params.tapers=[.25 floor(timeduration) 1];

    %seemed like a good idea but end up with too tight frequency resolution
    % if timeduration>40
    %     params.tapers(2)=40; %so don't end up with too many tapers
    % end


    %tapers set at a frequency resolution of 1 Hz though if over 40 seconds (?)
    %cut down above so not too many tapers
    %[] may want to do as low resolution and plot this as a GUI so can redo
    %with more tapers

    fprintf('tapers used: %.2f %.0f %.0f\n',params.tapers(1),params.tapers(2),params.tapers(3));
    if plotAvg
        params.err=[2 0.05];
        params.trialave=1;%to get the average of the 3 spectra with proper error calculation (see JV email 7/19)
        [S,f,Serr]=mtspectrumc(ydata(xdata>x(1)&xdata<x(2),:),params);
%         S=sum(S,2); Serr=squeeze(sum(Serr,3));
    else %do separate spectra for each line without error bars
        [S,f]=mtspectrumc(ydata(xdata>x(1)&xdata<x(2),:),params);
    end
    end
end

