function qEventDisplay

[qfilename qpathname]=uigetfile('*Qdata.mat','Select q data file');

qdata=load(fullfile(qpathname,qfilename));

events=unique(qdata.eventNames);
disp('Events in dataset are:');
for i=1:length(events)
    fprintf('%.0f. %s\n',i,events{i});
end
eplot=input('Type event number to plot: ');

tbefore=input('How much time before in secs [5]');
if isempty(tbefore)
    tbefore=5;
end
tafter=input('How much time after in secs [10]');
if isempty(tafter)
    tafter=10;
end

%give index for event type to plot
eindex=find(strcmpi(events{eplot},qdata.eventNames));

%figure out size of matrix for subplot
nr=ceil(sqrt(length(eindex)));
nc=floor(sqrt(length(eindex)));
if nr*nc<length(eindex)
    nc=nc+1;
end;

eFigureH=figure;
for ee=1:length(eindex)
    subplot(nr,nc,ee);
    plottingRange=qdata.time>(qdata.eventStart(eindex(ee))-tbefore/60/60/24) & qdata.time<(qdata.eventStart(eindex(ee))+tafter/60/60/24);
    %xaxis needs to reflect fraction of a second that each point represents
    plot(1/qdata.sampleRate:1/qdata.sampleRate:sum(plottingRange)/qdata.sampleRate,qdata.gsrdata(plottingRange));
%         plot(1:1/8:tbefore+tafter,qdata.gsrdata(plottingRange));
    yrange=get(gca,'YLim');
    line([tbefore tbefore],[yrange(1) yrange(2)],'Color','k');
    axis tight;
    title(qdata.eventComments{eindex(ee)});
end
end