function AddQEvents

%to add events from an excel spreadsheet to a Qsensor file for display and
%analysis. Excel sheet to have event starts and ends as HH:MM:SS format.
%End time is optional. Assumes time sync has already occurred.

[eventFilename eventpathname]=uigetfile({'*.xls'},'Choose .xls file containing events');
eventdata=importdata(fullfile(eventpathname,eventFilename));
eventStart=datevec(eventdata.data(:,1)); %first column is start
eventEnd=datevec(eventdata.data(:,2)); %second column is end
eventNames=eventdata.textdata(:,3);
eventComments=eventdata.textdata(:,4);


[Qfilename Qpathname]=uigetfile('*Qdata.mat','Choose Qdata file.');
qdata=load(fullfile(Qpathname,Qfilename));

%next put events in days then save file along with event start and end
%variables
startTimeVec=datevec(qdata.startTime);%YYYY,MM,DD,HH,MM,SS from qdata file
eventStart=repmat([startTimeVec(1:3) 0,0,0],size(eventStart,1),1)+eventStart;
eventEnd=repmat([startTimeVec(1:3) 0,0,0],size(eventEnd,1),1)+eventEnd;
eventStart=datenum(eventStart);
eventEnd=datenum(eventEnd);
save(fullfile(Qpathname,Qfilename),'eventStart','eventEnd','eventNames','eventComments','-append');

%%
%next make new figure with events displayed
figureH=figure;
fig(1)=subplot(2,1,1);
plot(qdata.time,qdata.accdata);
set(gca,'xtick',[]);%so don't show time for top plot
fig(2)=subplot(2,1,2);
plot(qdata.time,qdata.gsrdata);
hold on;
if ~isempty(qdata.qEventTimes) %to plot lines for events if not empty matrix
    text(qdata.qEventTimes,repmat(-.2,size(qdata.qEventTimes),1),'Qevent','rotation',-90);
end
text(eventStart,repmat(-.2,length(eventStart),1),eventNames(1:length(eventStart)),'rotation',-90);%8/17 added to length eventStart incase blank names at end
linkaxes(fig,'x');
saveas(figureH,[Qfilename 'Events.fig']);%save the figure before running dynamicDateTicks
dynamicDateTicks(gca,'link');
axis tight;
zoom xon;

