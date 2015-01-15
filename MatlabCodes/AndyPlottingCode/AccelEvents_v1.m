function AccelEvents
%Use excel sheet to pull out selected regions of interest from the
%accelerometer data.
%
%Format of Excel Sheet containing events:
%StartTime    EndTime     EventType(eg. WeMoveHim, HeMoves etc)   Comments
%
%Accelerometer file must have the structures: time, accdata
%Code checks to make sure they exist
%
%DT-9/21/2011
%
[opts.eventFilename opts.eventpathname]=uigetfile({'*.xls'},'Choose .xls file containing events');
opts.eventdata=importdata(fullfile(opts.eventpathname,opts.eventFilename));
eventStart=datevec(opts.eventdata.data(:,1)); %first column is start
eventEnd=datevec(opts.eventdata.data(:,2)); %second column is end
opts.EventNames=opts.eventdata.textdata(:,3);
opts.EventComments=opts.eventdata.textdata(:,4);

%Choose Acc data.
[Accfilename Accpathname]=uigetfile('*.mat','Choose Accelerometer data file.');
load(fullfile(Accpathname,Accfilename));
if ~exist('accdata')&&~exist('time')
    fprintf('\nERROR!! VARIABLE(S) DO NOT EXIST.\n')
    fprintf('Assign values to structures: accdata and time\n\n')
else
    timeInDays=datevec(time);%YYYY,MM,DD,HH,MM,SS from accdata file
    timeInMatUnits=datenum(timeInDays);%Matlab Units
    EventTimesStart=repmat([timeInDays(1,1:3) 0,0,0],size(eventStart,1),1)+eventStart;
    %Uses the first date in the time structure for the entire dataset. need to
    %fix this later. For now, make sure the events are from the same day.
    EventTimesEnd=repmat([timeInDays(1,1:3) 0,0,0],size(eventEnd,1),1)+eventEnd;
    opts.EventTimesAll(:,1)=datenum(EventTimesStart);
    opts.EventTimesAll(:,2)=datenum(EventTimesEnd);
    save(fullfile(Accpathname,Accfilename),'timeInDays','timeInMatUnits','opts','-append');
    %
    %List of Events
    opts.EventTypes=unique(opts.EventNames);
    more=1;
    while more==1
        fprintf('\nEvent Types found in the Excel Sheet\n')
        for et=1:length(opts.EventTypes)
            fprintf('Event Type %d : %s \n', et, opts.EventTypes{et});%Display the different event types found in data.
        end
        pickAccEvent=getinp('event type to plot (or return if done): ', 'd', [0 length(opts.EventTypes)], 0);
        if ~pickAccEvent==0
            Eloc=find(strcmpi(opts.EventNames,opts.EventTypes(pickAccEvent))==1);
            numrows=ceil(sqrt(length(Eloc)));
            numcols=floor(sqrt(length(Eloc)));
            if numrows*numcols<length(Eloc)
                numcols=numcols+1;
            end
            figure;
            for sp=1:length(Eloc)
                if opts.EventTimesAll(Eloc(sp),1)>opts.EventTimesAll(Eloc(sp),2)
                    fprintf('\nERROR!! Row %1.0f of Excel sheet. Check to make sure values exist and increment with time.\n',Eloc(sp));%End time > Start time??
                    close gcf
                else
                    EventIndex{sp}=timeInMatUnits>opts.EventTimesAll(Eloc(sp),1)&timeInMatUnits<opts.EventTimesAll(Eloc(sp),2);
                    if sum(EventIndex{sp})>0
                        subplot(numrows,numcols,sp)
                        plot(timeInMatUnits(EventIndex{sp}),accdata(EventIndex{sp},:))
                        title(opts.EventComments(Eloc(sp)));
                  %   dynamicDateTicks
                          axis tight
                        saveas(gcf,[opts.eventFilename(1:end-4),'_',opts.EventTypes{pickAccEvent}],'fig')
                        saveas(gcf,[opts.eventFilename(1:end-4),'_',opts.EventTypes{pickAccEvent}],'png')
                    else
                        fprintf('\nERROR!! Row %1.0f of Excel sheet. Check to make sure values exist and increment with time.\n',Eloc(sp));%End time > Start time??
                        close gcf
                    end
                end %if opts.EventTimesAll(Eloc(sp),1)>opts.EventTimesAll(Eloc(sp),2)
            end %for sp=length(Eloc)
        end %pickAccEvent==0
        more=getinp( '(Return) to plot other events, or 1 to exit: ','d',[0 1],0);
        more=more+1;
    end %more>1
end
end





