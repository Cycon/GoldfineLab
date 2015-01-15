function timeZoom

%find all figures and then zoom to the same spot in them, assuming they're
%all time units (do a check). User inputs start time in hours, min, sec and
%a +/- range. Assumes all figures are from the same accelerometer data!

%requires setDateAxes which needs to be run after dynamicDateTicks instead
%of tlabel

%first pick which figures to apply to (so not spectra that are open)
figs=findobj('Type','Figure');
figsuse=[];
xdata=[]; %so can crash out later
for j=1:length(figs)
    axes=get(figs(j),'Children');
    curves=get(axes,'Children');
    if ~isempty(curves) && ~iscell(curves) %in case have a blank figure open by accident or one with cells (spectrum)
        xdata=get(curves(1),'XData'); %get the times
        if iscell(xdata)
            fprintf('X labels are strings for figure %.0f so can''t use',j);
        elseif xdata(1)>1e5 %implying that it's in matlab time units (days)
            figsuse=[figsuse figs(j)]; %new vector of figures that are in days
        end
    end
end
if isempty(xdata)
    return
end
time =datevec(xdata(1)); %gives start time in vector    
%     axes=get(figs(1),'Children');
% curves=get(axes,'Children');
% for i=1:length(curves) %for each curve on the graph
%     xdata=get(curves(i),'XData'); %same for each one
%     ydata(:,i)=get(curves(i),'YData');
% end
% 
fprintf('Time starts at %s\n',datestr(xdata(1)));
disp('Center time to:');
time(4:6)=input('[Hours (24hr day) Min Sec] (in [ ]s): ');

range=(input('+/- range in seconds: '));

for jj=1:length(figsuse)
    figure(figsuse(jj));
    setDateAxes(gca,'Xlim',[datenum(time-[0,0,0,0,0,range]) datenum(time+[0,0,0,0,0,range])]);
end
fprintf('Time ranges from %s to %s\n',datestr(time-[0,0,0,0,0,range]),datestr(time+[0,0,0,0,0,range]));