function importQsensor

%8/12/11 to import .csv out of Qsensor. Needs to get real time from device
%but allow for changing of time. Might be best to put in display time of
%click and actual time of click and then adjust with a subtraction.
%8/15 found out that events appear as blank rows which are read as NaN.
%8/15 to do: [] put in option to sync with accelerometer trace
%[] write additional code to add events from excel sheet and add them to the
%code and the plotting routine.
%[] code to do anaoysis of pre-post events

[qfilename qpathname]=uigetfile('*','Pick exported .csv file');

qdata=importdata(fullfile(qpathname,qfilename));%creates data and textdata variables
qHeader=qdata.textdata;
data=qdata.data;
sampleRate=str2double(qHeader{5}(16));
eventIndices=find(isnan(data(:,1)));%gives the rows where event button pushed

data(eventIndices,:)=[];%remove rows of events
accdata=data(:,1:3);
gsrdata=data(:,6);

startTimeQ=datenum(qHeader{6}(13:31),'yyyy-mm-dd HH:MM:SS');%default start time from q sensor
YMD=datevec(startTimeQ);
YMD(4:6)=[];%now have year, month date of study
eventTimes=[]; %as default
fprintf('Start time stored as %s\n',qHeader{6}(13:31));
if strcmpi(input('Use time from Qsensor? (y/n - sync with XLTEK) [n]','s'),'y')
    startTime=startTimeQ;%in days
    if ~isempty(eventIndices)
        qEventTimes=eventIndices/sampleRate/60/60/24+startTimeQ;%gives event times in days
    end
elseif ~isempty(eventIndices) && ~strcmpi(input('Use button pushes to sync? (y/n - use acc) [y]','s'),'n')
        qEventTimes=eventIndices/sampleRate/60/60/24+startTimeQ;%gives event times in days
        disp('Button pushes occurred at: ');
    for et=1:length(qEventTimes)
        fprintf('%.0f. %s\n',et,datestr(qEventTimes(et,:)));
    end
    eTS=input('Type which event to use to sync: ');
    actualTime=datenum([YMD,input('Actual time of same event as seen in XLTEK (as [HH,MM,SS]): ')]);
    startTime=startTimeQ+(actualTime-qEventTimes(eTS));%in days, need to check the math here[]
    qEventTimes=qEventTimes+(actualTime-qEventTimes(eTS));
else %use accelerometer to sync 
    dataplot=figure;
    time=[1:size(data,1)]/sampleRate/60/60/24+startTimeQ;%then need to convert to actual time and to divide by srate and then put into days
    plot(time,accdata);
    dynamicDateTicks;
    axis tight;
    dcm=datacursormode(dataplot);
    set(dcm,'DisplayStyle','datatip',...
    'SnapToDataVertex','on','Enable','on')
    disp('select a point, press any key when done');
    figure(dataplot); %to make it the current figure
    pause;
    cursorinfo=getCursorInfo(dcm);
    actualTime=datenum([YMD,input('Actual time of same event as seen in XLTEK (as [HH,MM,SS]): ')]);
    startTime=startTimeQ+(actualTime-cursorinfo.Position(1));
    if ~isempty(eventIndices) 
        qEventTimes=eventIndices/sampleRate/60/60/24+startTimeQ;%gives event times in days
        qEventTimes=qEventTimes+(actualTime-cursorinfo.Position(1));
    end
    close(dataplot);
end    




time=[1:size(data,1)]/sampleRate/60/60/24+startTime;%then need to convert to actual time and to divide by srate and then put into days

figureH=figure;
fig(1)=subplot(2,1,1);
plot(time,accdata);
set(gca,'xtick',[]);%so don't show time for top plot
fig(2)=subplot(2,1,2);
plot(time,gsrdata);
hold on;
if ~isempty(qEventTimes) %to plot lines for events if not empty matrix
    text(qEventTimes,repmat(-.2,size(qEventTimes),1),'Qevent','rotation',-90)
end
linkaxes(fig,'x');
saveas(figureH,[qfilename '.fig']);%save the figure before running dynamicDateTicks
dynamicDateTicks(gca,'link');
axis tight;
zoom xon;

save([qfilename 'Qdata'],'accdata','gsrdata','sampleRate','startTime','time','qHeader','qEventTimes');