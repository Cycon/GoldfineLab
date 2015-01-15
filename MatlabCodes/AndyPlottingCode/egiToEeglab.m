function egiToEeglab

%8/7/13 AMG to automate required processes for importing egi to EEGLAB.
%10/30/13 add option to import .mat files exported from EGI. These don't
%remove the Cz channel, but also don't automatically create a chanlocs
%file. Advantage is they keep separate events marked at time of recording
%and later on. Code puts a '-o' at the end of all events marked at time of
%recording meaning original.
%1/22/14 if importing a .raw, replaces the chanlocs file since the
%automated import uses an older version at least for the EGI129


%% choose file
egiFile=uipickfiles('refilter','\.raw$|\.mat$','prompt','Select EGI file as .raw','output','char','num',1);
if isnumeric(egiFile) || isempty(egiFile) %if user presses cancel and it is set to 0
    return
end
[pathname,filename,ext]=fileparts(egiFile);

%replace spaces with underscores since is better coding and works better
%with eegplotEpochChoose
filename=strrep(filename,' ','_');
%% load in with EEGLAB tool
if strcmp(ext,'.raw')
    eeg=pop_readegi(egiFile);
    
    
    %% tool above removes Cz which has no data in it so need to put back in as 0s
    %so that the laplacian and average references will work.
    eeg.data(end+1,:)=zeros(1,size(eeg.data,2));
    eeg.chanlocs(end+1)=eeg.chaninfo.nodatchans(end);
    
    fprintf('Adding channel %s back to data\n',...
        eeg.chaninfo.nodatchans(end).labels);
    
    eeg.chaninfo.nodatchans=eeg.chaninfo.nodatchans(1:end-1);%remove it otherwise
    %gives warning of multiple channels with same name
    
    eeg.nbchan=eeg.nbchan+1;
    
    %note that pop_readegi brings in an older headset for at least the EGI129 so want to
    %bring in the chanlocs manually to ensure the newer EGI headsets.
    if size(eeg.chanlocs)==33 
        eeg.chanlocs=readlocs('GSN-HydroCel-32.sfp');
        eeg.chanlocs=eeg.chanlocs(4:end);%first three aren't real
    elseif size(eeg.eeg.chanlocs)==129
        eeg.chanlocs=readlocs('GSN-HydroCel-129.sfp');
        eeg.chanlocs=eeg.chanlocs(4:end);%first three aren't real
    else disp('number of channels not yet coded for');
        return
    end
    
elseif strcmp(ext,'.mat');
    matdata=load(egiFile);
    %this contains the data which is the same name as the file and is
    %channel x time; samplingRate, Impedances_0 (a matrix or possibly a
    %cell); Marks (a 4xsomething cell); Tech_Markup (a 4xsomething cell)
    
    %the load process replaces spaces in the fieldname with underscores so
    %can't use the variable filename to get at the data field. Will try
    %assuming that it's always the first field.
    matfields=fieldnames(matdata);
    
    %need to create all the eeglab structure information manually next:
    if size(matdata.(matfields{1}),1)==33
        chanlocs=readlocs('GSN-HydroCel-32.sfp');
        chanlocs=chanlocs(4:end);%first three aren't real
    elseif size(matdata.(matfields{1}),1)==129
        chanlocs=readlocs('GSN-HydroCel-129.sfp');
        chanlocs=chanlocs(4:end);%first three aren't real
    else disp('number of channels not yet coded for');
        return
    end
    
    
    % create the EEG file with no events
    eeg = pop_importdata('dataformat','array','data',matdata.(matfields{1}),...%filename in parenthesis since this turns the text into a variable name
        'setname',matfields{1},'srate',matdata.samplingRate,'subject','1','nbchan',size(matdata.(matfields{1}),1),'chanlocs',chanlocs);
    
    
    % create and modify the events. Not allowed for .egi since unable to differentiate
    %between original marks and tech markup in the .raw file and they are
    %stored in two different .xml files. This could be done if modify the code
    %to detect the timings of the events in the .xml files but
    %need to figure out where that is stored.
    
    %if have any comments manually entered, want to replace with the xml
    %file
    if strcmpi(input('Want to replace original events with those in xml file? (y/n) [n]','s'),'y')
        desc=eventsFromxml;
        if length(desc)~=size(matdata.Marks,2)
            disp('Different number of events in xml than eeg, may have chosen wrong xml');
            return
        else
            for mm=1:size(matdata.Marks,2) %for each originally entered event
                matdata.Marks{1,mm}=desc{mm};
            end
        end
    end
    
    %modify the original events to have an o at the end
    for ee=1:size(matdata.Marks,2)%for each event
        matdata.Marks{1,ee}=[matdata.Marks{1,ee} '-o'];
    end
    
    if strcmpi(input('Want to replace Tech Markup events with those in xml file? (y/n) [n]','s'),'y')
        desc=eventsFromxml;
        if length(desc)~=size(matdata.Tech_Markup,2)
            disp('Different number of events in xml than eeg, may have chosen wrong xml');
            return
        else
            for mm=1:size(matdata.Tech_Markup,2) %for each tech entered event
                matdata.Tech_Markup{1,mm}=desc{mm};
            end
        end
    end
    
    
    %create an event structure so can be imported or add it manually below
    %   event     - [ 'filename'|array ] Filename of a text file, or name of
    %               Matlab array in the global workspace containing an
    %               array of events in the folowing format: The first column of
    %               the cell array is the type of the event, the second the latency.
    %               The others are user-defined. The function can read
    %               either numeric or text entries in ascii files.
    
    %next reorder the events to be sequential
    matevent=[matdata.Marks(1,:)' matdata.Marks(4,:)'];
    matevent=[matevent; matdata.Tech_Markup(1,:)' matdata.Tech_Markup(4,:)'];
    [sorted,sortind]=sort([matevent{:,2}]);
    matevent=matevent(sortind,:);
    for e=1:size(matevent,1)
        eeg.event(e).type=matevent{e,1};
        eeg.event(e).latency=matevent{e,2};
    end
    %     eventstruct=importevent(event,[],eeg.srate,'fields',{'type','latency'});%this
    %     code doesn't work so doing manually as above
    %     eeg.event=eventstruct;
    
    eeg=eeg_checkset(eeg);
    %[] need to check if above works correctly, I'm sure I figured this out
    %before!
    
    %[] also need to figure out below how to bring in the comments
    %correctly when using a mat file.
end


%% detrend it (could add a filter option here too)
if ~strcmpi(input('1Hz HPF (recommended)? (y/n-detrend) [y])','s'),'n')
%     eeg = pop_iirfilt( eeg, 1);%an eeglab code that calls filtfilt by default
    EEG = pop_eegfiltnew(EEG, [], 1, 1650, true);%new code as of 12/30/14 
else %detrend
    eeg.data=detrend(eeg.data')';
end

%% remove electrodes on face and below ear (optional)
% if strcmpi(input('Remove electrodes on face and below ears (EGI 33 only)? (y/n) [n]','s'),'y')
%     
%     eeg.data(remove,:)=[];
%     eeg.nbchan=size(eeg.data,1);
%     eeg.chanlocs(remove)=[];
% end
remove=[];%default for below
rr=input('Remove face and cheek (1) or all but central (2)? (1/2/otherwise keep all): ');
if rr==1 
    remove=[26 24 22 32 30 18 29 31 21 23 25];
elseif rr==2 
    remove=[26 24 22 32 30 18 29 31 21 23 25 1 27 2 11 12 13 14 15 16 9 20 10];
%this should just keep F3 (3), Fz (17), F4 (4), FCz (28), C3 (5), Cz,
%C4 (6), P3 (7), Pz (19), P4 (8)
%     otherwise
%         remove=[];
end
eeg.data(remove,:)=[];
eeg.nbchan=size(eeg.data,1);
eeg.chanlocs(remove)=[];



%% run 60 Hz line noise removal copied from xltekToEeglab
if strcmpi(input('Remove 60Hz noise? (y/n) [n]','s'),'y')
    if ndims(eeg.data)==3 %if exported from EGI as epochs
        disp('This is only for continuous data, could be changed');
        return
    end
    filename=[filename '_60'];%to show that it was performed
    params.fpass=[55 65];
    params.pad=4;
    params.tapers=[1 10 1];%since will go in 10 sec chunks
    cL=params.tapers(2)*eeg.srate;%cut length for noise removal
    params.Fs=eeg.srate;
    
    fprintf('%.2f seconds of data cut off of end.\n',...
        mod(size(eeg.data,2),cL)/eeg.srate);
    %then cut off the end of the data
    eeg.data=eeg.data(:,1:end-mod(size(eeg.data,2),cL));
    
    
    denoised=zeros(size(eeg.data));%initialize
    %denoised is now data x channel (transposed from EEG)
    for jk=1:size(eeg.data,2)/cL %number of epochs length of tapers(2)
        denoised(:,(jk-1)*cL+1:jk*cL)=rmlinesc(eeg.data...
            (:,(jk-1)*cL+1:jk*cL)',params,0.2,'n')';%transpose for rmlinesc
        
    end
    eeg.data=denoised;
    %clean up the data structure since cut off end
    eeg.pnts=size(eeg.data,2);
    eeg.times=eeg.times(1:size(eeg.data,2));%times is in ms
    
    %remove events that were in the part cutoff. Latency is in samples
    eeg.event=eeg.event([eeg.event.latency]<=size(eeg.data,2));
end

%%
%save the data
eeg=pop_saveset(eeg,'filename',filename,'filepath',pwd);

%% nested code to get events out of xml file
    function desc=eventsFromxml
        xmlFile=uipickfiles('type',{'*.xml','EGI Event Marks xml file'},'prompt','Select EGI event Marks xml file','output','char','num',1);
        if isnumeric(xmlFile) || isempty(xmlFile) %if user presses cancel and it is set to 0
            %if cancel then don't do this code
        else
            eventStruct=parseXML(xmlFile);%bring in the xml file as a structure
            event=eventStruct.Children;
            a=1;
            for i=1:length(event) %some contain nothing and starting at 6 they contain the events
                if ~isempty(event(i).Children) %if some info in it
                    if isfield(event(i),'Children') && length(event(i).Children)>1
                        if ~isempty(event(i).Children(10)) &&...
                                ~isempty(event(i).Children(10).Children)
                            %this is for when the event description is typed in
                            desc{a}=event(i).Children(10).Children.Data;
                        else
                            %this is the label from clicking an option
                            desc{a}=event(i).Children(6).Children.Data;
                        end
                        a=a+1;
                    end
                end
            end
        end
    end

%at one point this used to run on .raw and if want to do again note
%below:
%         if strcmp(ext,'.raw') %if .raw data then events already in EGI dataset
%             if length(desc)~=length(eeg.event)
%                 disp('Different number of events in xml than eeg, please fix code');
%             return
%             end
%
%             for e=1:length(eeg.event)
%                 eeg.event(e).type=desc{e};
%             end
%         else %if .mat data

end%end code

