function tReal=acctimesync(time,data,savename)
%sync time between accelerometer data and xltek time for an event. This
%code converts time to matlab time (in days since 1/1/0000) and plots it
%and saves the plot. Created 2/9/11.

%modified July 18. Now requires dynamicDateTicks

dataplot=figure; 

plot(time,data);zoom xon;axis tight;

disp('First time from xltek:')
year=input('year: ');
month=input('month: ');
date=input('date: ');
hour=input('hour: ');
minute=input('minute: ');
second=input('second: ');
realTimeSyncInSerial=datenum(year,month,date,hour,minute,second);

finished=0;
while ~finished
   [dataplotreal,tReal]=syncAndConvert;
   figure(dataplotreal);
   if strcmpi(input('Happy with new x-axis (y/n) [y]','s'),'n')
        close(dataplotreal);
       [dataplotreal,tReal]=syncAndConvert;
   else
       close(dataplot);
       finished=1;
   end
end

%save the figure with x-axis in matlab units so can run tlabel later
figureToSave=figure;
plot(tReal,data);
axis tight; %so no white space on either end
saveas(figureToSave,savename,'fig'); %save figure using name from importAccData
close(figureToSave);

%this function gives a figure and a variable of time in actual time
function [dataplotreal,tReal]=syncAndConvert

    figure(dataplot); %to make it the current figure
    disp('zoom on figure until ready to select a point then press any key');
    pause;
%     [acctime accvalue]=ginput(1);%but ginput doesn't give a value that necessarily exists in x axis
    dcm=datacursormode(dataplot);
    set(dcm,'DisplayStyle','datatip',...
    'SnapToDataVertex','on','Enable','on')
    disp('select a point, press any key when done');
    figure(dataplot); %to make it the current figure
    pause;
    %   input('Press Enter when happy with selected point');
    cursorinfo=getCursorInfo(dcm);
    

    %convert time to dateunits as well. need to convert to a 6 column matrix
    %with the time in seconds values in the 6th column and the rest 0
    timeInSerial=datenum([zeros(length(time),5) time]); 

    %take the original time add on the actual time but subtract off how far in
    %the sync (x) is. 
    tReal=timeInSerial+(realTimeSyncInSerial-timeInSerial(time==cursorinfo.Position(1)));

    %replot with new time
    dataplotreal=figure;
    plot(tReal,data);
    axis tight; %so no white space
%     set(gca,'XTick',linspace(min(tReal),max(tReal),10));%helps if using
%     datetick
    dynamicDateTicks %modification July 18 instead of tlabel since allows for xlim via timeZoom

%     tlabel; % a better version of datetick that allows for zooming in and other options
    %(likely want to use it for spectrograms with subplot can set to just
    %be at the bottom)
%     datetick('x',13);
end

end
        