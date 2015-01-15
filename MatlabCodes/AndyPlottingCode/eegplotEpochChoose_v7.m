function eegplotEpochChoose

%two codes that run with EEGLAB running, one to plot the data with no reject but instead save the
%selected epochs as a logical vector. Second code to make and save a new
%dataset with those epochs.
%[] need to figure out how to save the event information so visible in
%saved .set files
%
%eegplotEpochKeep created 8/24/11 with some notes in IN370 analysis
%1/6/12 modified to allow to view as Laplacian so more accurate view of
%artifact. Also change to not be in workspace so is more flexible. Tried to
%have the REJECT button run the code but the figure doesn't have access to
%EEG unless it's in the workspace so instead user needs to select all then
%press return on the keyboard.
%1/7/12 add option to load in a previous one and highlight previously
%selected epochs
%3/27/12 put in a catch to close program if already have an EEGLAB plot
%window opened since worried code will use the wrong one.
%4/16/12 added statement to transpose old selected epochs since found an
%old dataset where they were in a row vector but in newer dataset it's in a
%column vector, not sure why they changed but this fixes the issue
%4/16/12 version 2 plots the diff (as a fast LPF) accelerometer data in a
%different window so can see it easier. Problem was that the selected
%epochs need to be the correct number of channels but it doesn't see the
%accelerometer channels. Might be better all in one window but with the
%diff of the accelerometer so at least doesn't go all over the place.
%4/27/12 version 3 give option to filter the data first for easier
%visualization, doesn't change the underlying data at all.
%5/1/12 version 4 gives option to cut the data instead of keep it (so don't
%need to use the EEGLAB GUI for this purpose). Don't close figure at end. 
%Changed name from eegplotEpochKeep. Created unique tag so don't need to
%close other windows on off chance want to compare. Now runs the command by
%clicking the button in the figure, though requires using the slightly
%modified eegplotAndy rather than eegplot so doesn't run the commands
%inherent in eegplot.
%5/4/12 version 5 calls spectraGUI to create spectra of the selected (or
%non-selected) epochs using the original data.
%5/7/12 HPF now at 0.1 and will not HPF on epoched data since doesn't
%make sense, though does 60 Hz.
%5/8/12 if display previously chosen epochs, if those were cut out will
%display in red, if those were kept, will display in green.
%5/9/12 version 6 5/9/12 found bug that this was converting data to laplacian before saving,
%so later power spectra calculation was doing second laplacian which
%changed result. Also fixed bug that wasn't detecting actual continuous
%data that has been cut, so now assumes it's continuous if no date field.
%Also made code stop if two eegplot windows with same tag because it didn't
%accurately pick out the new one (luckily).
%5/12/12 Added a catch in case want to display previously cut / kept data,
%to ensure that the old data was created from the current one. 
%6/3/12 changed the version that runs on data without accelerometers to
%also use eegplotAndy rather than eegplot. This should have been fixed
%earlier.
%11/27/12 found bug where if didn't apply a filter, then it just used the
%original data, ignoring the application of the montage!
%12/2/12 found bug where if use bipolar, gave error in the chanlocs because
%bipolar chanlocs doesn't match the original one when saving. Changed code
%so that save with original chanlocs. Also changed default number of epochs
%to be approximately 10 seconds instead of 10 epochs.
%8/9/13 version 7 define the append name after making the selection so can
%choose different things each time. Also this way don't need to type it at
%the beginning which is annoying if not planning to use it. Also allow for
%replotting the data. Also replaced data with EEG.data so now EEG is the
%modified one and EEGorig is the old (and no need for an additional "data"
%variable).

%to do:
%consider filtering out high frequency artifact (>40 Hz) since want to
%differentiate EMG from beta but would need to do real time with a GUI.
%[] for previously chosen, only choose ones that are a subset of this one


pathname=uipickfiles('type',{'*.set','.set file'},'prompt','Pick EEGLAB .set file','out','char');


if isnumeric(pathname) || isempty(pathname) %if user presses cancel output is 0, done with no selection is {}
    return
else
    EEG = pop_loadset(pathname);
    [setfilepath setfilename]=fileparts(pathname);
end


if size(EEG.data,3)==1 %if a continuous dataset / one epoch
    disp('Designed for epoched data, this dataset appears to be continuous');
    return
end
%reinitialize rejected epochs so can make new selections (more for earlier
%version when ran in the workspace)
EEG.reject.rejmanual=[];
EEG.reject.rejmanualE=[];

%%
mont=input('View as laplacian (l), bipolar (b) or as current montage (c)? (l/b/c) [c]: ','s');
%convert to data here so that the EEG.data remains untouched by montaging
%and filtering
EEGorig=EEG;%to use for spectra and later saving of the original chanlocs
if strcmpi(mont,'l')
    EEG.data=MakeLaplacian(EEG.data,EEG.chanlocs);
elseif strcmpi(mont,'b')
    [EEG.data,chanlist,EEG.chanlocs]=MakeBipolar(EEG.data,EEG.chanlocs);
    EEG.nbchan=length(EEG.chanlocs);%since fewer channels now
else
    EEG.data=EEG.data;
end

%%
%filter
filterType=input('Visualization filter: 0.1Hz and 60Hz notch (2); 60Hz notch only (1); or none (Rtn)? ');

if ~isempty(filterType)
    %60 Hz filter first
        eegtemp=zeros(size(EEG.data,1),size(EEG.data,2)*size(EEG.data,3));
        [b,a]=butter(8,[57/(EEG.srate/2) 63/(EEG.srate/2)],'stop');
        for i=1:size(EEG.data,1)
            eegtemp(i,:)=filtfilt(b,a,double(reshape(squeeze(EEG.data(i,:,:)),1,[])));%requires one vector at a time and as a double
        end
        
  if filterType==2
      %0.1 Hz HPF, not sure if 8th order is good but Keith once recommended
      %it
        [b,a]=butter(5,0.1/(EEG.srate/2),'high');%try 5th order which is used in the EEGLAB filter
        for i=1:size(eegtemp,1)
            eegtemp(i,:)=filtfilt(b,a,eegtemp(i,:));
        end
  end
        EEG.data=reshape(eegtemp,size(EEG.data));
% else 
%     data=EEG.data; %this is an error! removed 11/27/12
end


    
    
    
%%
% appendname=input('Save append name: ','s');
% if isempty(appendname)
%     appendname='cut';
% end
% savename=[setfilename '_' appendname];

preselec=[];%holder for epochs selected previously that want to display
if strcmpi(input('Display selected epochs from previous cut dataset (y/n) [n]?: ','s'),'y')
    pathnameOld=uipickfiles('type',{[setfilename '_*.set'],'.set file'},'prompt','Pick EEGLAB .set file with cut out data','out','char');


    if isnumeric(pathnameOld) || isempty(pathnameOld) %if user presses cancel output is 0, done with no selection is {}
    else
       EEGOld = pop_loadset(pathnameOld);
        %first check to be sure that the chosen file was previously cut out
        %of the open one
        if ~isfield(EEGOld,'Source')
            disp('Chosen previous set was not created by eegplotEpochChoose so can''t use.');
            return
        end
        if ~strcmp(setfilename,EEGOld.Source.setname)
            disp('Chosen previous set was not created from the current .set file so can''t use.');
            return
        end
        
        
            %below is for winrej of eegplot
            
            %need to be able to use cut or kept data from prior for
            %visualization
            if isfield(EEGOld.Source,'epochskept')
                disp('Displaying previously kept data.');
                prevData=EEGOld.Source.epochskept;
                prevColor=[0 1 0];%display in green if were previously kept
            else %if was from cut out data
                disp('Displaying previously cut data');
                prevData=EEGOld.Source.epochscut;
                prevColor=[1 0 0];%display in red if were previously cut
            end
            
            %if statement below added 4/16/12
            if size(prevData,1)==1 %if 1 row which found in an older one
                prevData=prevData';
            end
            preselec=[(prevData-1)*EEG.pnts prevData*EEG.pnts repmat(prevColor,length(prevData),1) zeros(length(prevData),EEG.nbchan)];
        
    end
end

%%
%allow for quick spectra visualization of original data (can be montaged in
%the GUI)
spectraGUI(EEGorig,setfilename);%send original data and tag

%%
%plot data
%if there's accelerometer data in the last 3, plot in a separate window so
%it doesn't interfere with the view of the main data. Link them too.
figtag=setfilename;%in case have others open, might help to make unique
if strcmpi(EEG.chanlocs(end).labels,'AccZ') %&& ~filt %if already ran a HPF, may be no need to do this, though does help
    disp('Running diff.m on accelerometer channels as a fast HPF.');
%     eegplot(permute(diff(permute(EEG.data(end-2:end,:,:),[2 1 3])),[2 1 3]),'srate',EEG.srate,'eloc_file',EEG.chanlocs(end-2:end),'events',EEG.event,'tag','acceegplot','winlength',10);
%     accHandle=gcf;
%     eegplot(EEG.data(1:end-3,:,:),'srate',EEG.srate,'eloc_file',EEG.chanlocs(1:end-3),'children',accHandle,'events',EEG.event,'title',['Choose ' appendname ' Press Enter when done (don''t close window)'],'winrej',preselec,'winlength',10);
    %note that zeros are because you lose one with the diff
    eegplotAndy([EEG.data(1:end-3,:,:) ; permute(diff(permute(EEG.data(end-2:end,:,:),[2 1 3])),[2 1 3]) zeros(3,1,size(EEG.data,3))],...
        'srate',EEG.srate,'eloc_file',EEG.chanlocs,'events',EEG.event,'title',['Choose epochs. '...
        'Press button when done (don''t close window)'],'winrej',preselec,'winlength',round(10/(size(EEG.data,2)/EEG.srate)),...
        'tag',figtag,'command',{@chooseData,EEG,figtag,setfilename,EEGorig,preselec},'butlabel','Keep / Cut');
else
    eegplotAndy(EEG.data,'srate',EEG.srate,'eloc_file',EEG.chanlocs,'events',EEG.event,'title',...
        ['Choose epochs. Press button when done (don''t close window)'],'winrej',preselec,'winlength',round(10/(size(EEG.data,2)/EEG.srate)),'tag',figtag,...
        'command',{@chooseData,EEG,figtag,setfilename,EEGorig,preselec},'butlabel','Keep / Cut');
end
    

% pop_eegplot(EEG,1,0,0);%plots the data with at end just marking the epochs to cut, but doesn't seem to work not in workspace

%new version uses eegplot since pop_eegplot didn't work. Found that TMPREJ
%2nd column is the end time in points of the chosen epochs so just take
%it and divide by pnts per epoch to get the
%epoch number for choosing). 

%this command gets run at the end once click the Keep button.
% command=['epochKeep=TMPREJ(:,2)/EEG.pnts;'...
% 'EEGnew=pop_importdata(''dataformat'',''array'',''data'',EEG.data(:,:,epochKeep),''setname'',savename,''srate'',EEG.srate,''pnts'',EEG.pnts,''xmin'',EEG.xmin,'...
% '''nbchan'',EEG.nbchan,''chanlocs'',''EEG.chanlocs'');'...
% 'EEGnew.Source.epochskept=epochKeep;'...
% 'EEGnew.Source.setname=EEG.setname;'...%just to save the name of the set it came from
% 'EEGnew.Source.daterun=date;'...%give the date run
% 'pop_saveset(EEGnew,''filename'',savename);'];

% command=['a=TMPREJ'];


% eegplot(EEG.data,'srate',EEG.srate,'eloc_file',EEG.chanlocs,'events',EEG.event,'title',['Choose ' appendname ' Press Enter when done']);

% eegplot(EEG.data,'srate',EEG.srate,'eloc_file',EEG.chanlocs,'events',EEG.event,'command','epochKeep=TMPREJ(:,2)/EEG.pnts','butlabel','Keep');';

% disp('press any key when selected epochs to use for new .set file');
%  input('Press enter to continue');
% figure(gcf); %doesn't work since 'input' waites for input

% userdata=get(gcf,'userdata');%use the findobj on the off chance I change
% to a different figure.

function chooseData(src,event,EEG,figtag,setfilename,EEGorig,preselec)
    userdata=get(findobj('tag', figtag), 'userdata');
    if iscell(userdata) %meaning more than one with the same append name (unlikely but possible)
        disp('Multiple eegplots with same name, please close other eegplot window.');
        return
%         userdatatemp=userdata{end};
%         clear userdata;
%         userdata=userdatatemp;
    end
    
    appendname=input('Save append name: ','s');
    if isempty(appendname)
        appendname='cut';
    end
    savename=[setfilename '_' appendname];

    epochChoose=userdata.winrej(:,2)/EEG.pnts;

    if strcmpi(input('Keep selections or cut them out? (k/c) [k]: ','s'),'c')
        %in line below used ismember (intersect and setdiff could've worked
        %too) to get index for where values are in the set and then exclude
        %with ~
        EEGnew=pop_importdata('dataformat','array','data',EEGorig.data(:,:,~ismember(1:size(EEGorig.data,3),epochChoose)),...
        'setname',savename,'srate',EEG.srate,'pnts',EEG.pnts,'xmin',EEG.xmin,...
        'nbchan',EEG.nbchan,'chanlocs',EEGorig.chanlocs);
        EEGnew.Source.epochscut=epochChoose;
    else
        EEGnew=pop_importdata('dataformat','array','data',EEGorig.data(:,:,epochChoose),...
            'setname',savename,'srate',EEG.srate,'pnts',EEG.pnts,'xmin',EEG.xmin,...
            'nbchan',EEG.nbchan,'chanlocs',EEGorig.chanlocs);
        EEGnew.Source.epochskept=epochChoose;
    end
    % EEGnew.Source.epochskept=find(EEG.reject.rejmanual);%to save the epochs to keep
    EEGnew.Source.setname=EEG.setname;%just to save the name of the set it came from
    EEGnew.Source.daterun=date;%give the date run so can look at the version of code used

    pop_saveset(EEGnew,'filename',savename);
    
    % allow for plotting clean set of EEG for making new selections
    if strcmpi(input('Clear selections? (y/n) [n]','s'),'y')
       figHand=findobj('tag',figtag);%close existing figure
       close(figHand);
       
       %then plot a new one just like above
    if strcmpi(EEG.chanlocs(end).labels,'AccZ') %&& ~filt %if already ran a HPF, may be no need to do this, though does help
        disp('Running diff.m on accelerometer channels as a fast HPF.');
        eegplotAndy([EEG.data(1:end-3,:,:) ; permute(diff(permute(EEG.data(end-2:end,:,:),[2 1 3])),[2 1 3]) zeros(3,1,size(EEG.data,3))],...
            'srate',EEG.srate,'eloc_file',EEG.chanlocs,'events',EEG.event,'title',['Choose epochs. '...
            'Press button when done (don''t close window)'],'winrej',preselec,'winlength',round(10/(size(EEG.data,2)/EEG.srate)),...
            'tag',figtag,'command',{@chooseData,EEG,figtag,setfilename,EEGorig},'butlabel','Keep / Cut');
    else
        eegplotAndy(EEG.data,'srate',EEG.srate,'eloc_file',EEG.chanlocs,'events',EEG.event,'title',...
            ['Choose epochs. Press button when done (don''t close window)'],'winrej',preselec,'winlength',round(10/(size(EEG.data,2)/EEG.srate)),'tag',figtag,...
            'command',{@chooseData,EEG,figtag,setfilename,EEGorig},'butlabel','Keep / Cut');
    end
       
    end
end
end