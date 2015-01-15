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
%9/3/13 version 8 has a control figure so can plot in different ways
%especially allowing to see just a subset of the channels with the correct
%labels. EEGorig no longer necessary since nested code
%10/25/13 modified display of eegplot to be ceil of 10/epoch length rather
%than floor since with long epochs ended up with 0 length. Only
%disadvantage is if 9 second epochs end up with 2 epochs shown which is 18
%seconds of data.
%1/6/13 fixed bug in choosing from displaed list
%6/11/14 - version 7.1 Sudhin found that when continuous data are switched to epoched, the events aren't 
%displayed so made their latency relative to the start of the epochs
%9/23/14 - version 7.2 add an option for true 10-20 (not just a 10-10 which I had
%before). %[] label bad channels with help of variance, [] save as a new variable and [] use later to exclude from analysis

%to do:
%consider filtering out high frequency artifact (>40 Hz) since want to
%differentiate EMG from beta but would need to do real time with a GUI.
%[] decide if to add in option to plot multiple on one with different
%colors since would need to modify headplotSpectra or rewrite it within
%here.
%[] option to calculate power ratios
%[] option to hide non-head channels from the headplot and topoplot power
%ratios without having to remove them since could be useful to have them in
%the laplacian calculation


pathname=uipickfiles('type',{'*.set','.set file'},'prompt','Pick EEGLAB .set file','out','char');


if isnumeric(pathname) || isempty(pathname) %if user presses cancel output is 0, done with no selection is {}
    return
else
    EEG = pop_loadset(pathname);
    [setfilepath,f.setfilename]=fileparts(pathname);
end


if size(EEG.data,3)==1 %if a continuous dataset / one epoch
    f.continuous=1;%marker for continuous data so can epoch in different lengths
else
    f.continuous=0;%epoched data
end


% creat the spectra figure to be used later but hide it
f.sf=figure;
set(f.sf,'Visible','off');

%% create control panel
f.cf=figure;
set(f.cf,'Name',[f.setfilename ' Control'],'Tag','0');%tag to track number of spectra plotted
%for colors, not currently used []

f.tab=uiextras.TabPanel('Parent',f.cf);%make it a tabbed control figure

%first tab for plotting (second can be for spectraGUI)
f.plotTab=uiextras.HBox('Parent',f.tab);

%first column is names of plotting options
f.plotTab_c1=uiextras.VBox('Parent',f.plotTab);
uicontrol('style','text','string',...
    'Montage for EEG and Spec. (uses all channels): ','Parent',f.plotTab_c1);
uicontrol('style','text','string','Channels to plot: ',...
    'Parent',f.plotTab_c1);
uicontrol('style','text','string','Filter: ',....
    'Parent',f.plotTab_c1);
f.prevOptBox=uibuttongroup('Parent',f.plotTab_c1);
uicontrol('style','radiobutton','parent',f.prevOptBox,'string',...
    'No prev selections','units','normalized','position',[0 0.8 1 0.21]);%first option so is the default);
f.dispPrevList=uicontrol('style','radiobutton','parent',f.prevOptBox,...
    'string','Choose from list','units','normalized','position',[0 0.5 1 0.21]);
f.dispPrevExp=uicontrol('style','radiobutton','parent',f.prevOptBox,...
    'string','Choose from prev. exported','units','normalized','position',[0 0.2 1 0.21]);
% f.EEGdispPrev=uicontrol('style','checkbox','string','choose from Prev Exp Epochs',...
%     'value',0,'Parent',f.plotTab_c1);
f.EEGplot=uicontrol('style','pushbutton','string','Plot','Parent',...
    f.plotTab_c1);
set(f.plotTab_c1,'Sizes',[-1 -1 -1 -1 -1]);

%second column contains lists (or could be radio buttons)
f.plotTab_c2=uiextras.VBox('Parent',f.plotTab);
f.EEGmontage=uicontrol('style','listbox','string',...
    {'As Saved','Laplacian','Bipolar','Com. Avg.'},'Max',1,'Parent',f.plotTab_c2);
f.EEGchannels=uicontrol('style','listbox','string',...
    {'All','10-10 for EGI','10-20 for EGI'},'Max',1,'Parent',f.plotTab_c2);
f.EEGfilter=uicontrol('style','listbox','string',...
    {'None','60 Hz','0.1 Hz HPF','60 & 0.1'},'Max',1,'Parent',f.plotTab_c2);
uicontrol('style','text','string','Saved selections:','Parent',f.plotTab_c2);
if ~isfield(EEG,'eegplotChooseSelections') 
    EEG.eegplotChooseSelections(1).names=' ';
    EEG.eegplotChooseSelections(1).epochs=[];%no chosen epochs
end
f.PrevSelectList=uicontrol('style','listbox','Parent',f.plotTab_c2,...
    'string',{EEG.eegplotChooseSelections.names},'Max',1);
if f.continuous %variable defined above, and to allow user to make arbitrary epoch lengths
    uicontrol('style','text','string','Epoch length in seconds: ','Parent',f.plotTab_c2);
    f.epochLength=uicontrol('style','edit','string','3','Parent',f.plotTab_c2);
else %if data came in cut, then don't want to recut since don't know if continuous
    uicontrol('style','text','string',' ','enable','off','Parent',f.plotTab_c2);%spacer
    uicontrol('style','text','string',' ','enable','off','Parent',f.plotTab_c2);%spacer
end
set(f.plotTab_c2,'Sizes',[-1 -1 -1 -.2 -.8 -.2 -.8]);

%third column for exporting data
f.plotTab_c3=uiextras.VBox('Parent',f.plotTab); 
f.keepData=uicontrol('style','pushbutton',...
    'string','Export Chosen','Parent',f.plotTab_c3);
f.cutData=uicontrol('style','pushbutton',...
    'string','Export Not Chosen','Parent',f.plotTab_c3);
uicontrol('style','text','string','Append name: ',...
    'Parent',f.plotTab_c3);
f.appendName=uicontrol('style','edit','string','cut',...
    'Parent',f.plotTab_c3,'backgroundcolor','w');
f.DeleteSelection=uicontrol('style','pushbutton',...
    'string','Delected Chosen Saved Selec.','Parent',...
    f.plotTab_c3);
f.SaveSelection=uicontrol('style','pushbutton',...
    'string','Save Selections','Parent',f.plotTab_c3);
set(f.plotTab_c3,'Sizes',[-1 -1 -0.2 -0.5 -1 -1]);%to set relative size of uicontrols in column

%fourth column of list of channels to exclude (save field of bad Electrodes)
%Need to ensure variable is saved and that they are excluded from laplacian
%calculation and display and that later ICA code doesn't use them

f.plotTab_c4=uiextras.VBox('Parent',f.plotTab);%() remember to make this one thinner!
uicontrol('Parent',f.plotTab_c4,'style','text','string','Exclude:');
%determine if there is already a bad electrode list in the data
f.badElectrodeIndices=uicontrol('Parent',f.plotTab_c4,... %this is the channel list
    'style','listbox','string',{EEG.chanlocs.labels},'min',0,'Max',length({EEG.chanlocs.labels})-1);
%set list to none or whatever was in the file (has to be done after list
%was created
if isfield(EEG,'badElectrodeIndices') %it needs to be a vector with the indices of the bad electrodes
    set(f.badElectrodeIndices,'value',EEG.badElectrodeIndices);
else
    set(f.badElectrodeIndices,'value',[]);
end
f.varButton=uicontrol('Parent',f.plotTab_c4,'style','pushbutton','string','Var');
f.clearBadElectrodes=uicontrol('Parent',f.plotTab_c4,'style','pushbutton','string','Clear');
f.saveBadElectrodes=uicontrol('Parent',f.plotTab_c4,'style','pushbutton','string','Save','enable','off');%starts off until you change the list
set(f.plotTab_c4,'Sizes',[-.1 -1 -.2 -.2 -.2]);



%set overal sizes of columns
set(f.plotTab,'Sizes',[-1 -1 -1 -0.5]);





%second tab will need to access only selected epochs from below and then
%run spectra on the original data. Will need option to plot only subset (no
%edge, just 10-20 for example)
f.spectraTab=uiextras.HBox('Parent',f.tab);

%first column
f.spectraTab_c1=uiextras.VBox('Parent',f.spectraTab);
uicontrol('style','text','string','Epochs to use: ',...
    'Parent',f.spectraTab_c1);
uicontrol('style','text','string','# of Tapers: ',...
    'Parent',f.spectraTab_c1);
 uicontrol('style','text','string',' ','enable','off',...
     'Parent',f.spectraTab_c1);%spacer

%9/6/13 removed error bars since typically want them and would require
%modifying headplotSpectra to allow to not take in Serr. May want to do in
%future.
% f.errorBars=uicontrol('style','checkbox','Value',1,...
%     'Parent',f.spectraTab_c1,'string','Error Bars');

%second column
f.spectraTab_c2=uiextras.VBox('Parent',f.spectraTab);
f.epochsForSpectra=uicontrol('style','listbox',...
    'string',{'Highlighted','All','Not Highlighted'},...
    'Parent',f.spectraTab_c2,'Max',1);
f.tapers=uicontrol('style','edit','string','1',...
    'Parent',f.spectraTab_c2,'backgroundcolor','w');
f.holdSpectraPlots=uicontrol('style','checkbox','string','hold on',...
     'Parent',f.spectraTab_c2,'value',1);%to hold spectra so can plot more on top of it versus clear


%third column
f.spectraTab_c3=uiextras.VBox('Parent',f.spectraTab);
uicontrol('style','text','string',' ','enable','off',...
    'Parent',f.spectraTab_c3);%spacer
if f.continuous
    epochLength=str2double(get(f.epochLength,'string'));%in seconds
else
    epochLength=size(EEG.data,2)/EEG.srate;
end
fres=sprintf('FR is %.2f Hz',...
    (str2double(get(f.tapers,'string'))+1)/epochLength);
f.freqRes=uicontrol('style','text','string',fres,...
    'Parent',f.spectraTab_c3);
f.plotSpectra=uicontrol('string','plot spectra',...
    'Parent',f.spectraTab_c3);
f.plotIndSpectra=uicontrol('string','plot indiv. spectra',...
    'Parent',f.spectraTab_c3,'enable','off');%still need to write code for this


%Callbacks
set(f.EEGplot,'Callback',{@plotEEG,EEG,f});
set(f.keepData,'Callback',{@chooseData,EEG,f,1});%to keep data in new file
set(f.cutData,'Callback',{@chooseData,EEG,f,0});%to cut selection and use remainder
set(f.tapers,'Callback',{@tapers_callback,EEG,f});%to calculate and display FR
set(f.plotSpectra,'Callback',{@plotSpectra_Callback,EEG,f});
set(f.plotIndSpectra,'Callback',{@plotIndSpectra_Callback,EEG,f});
set(f.DeleteSelection,'Callback',{@deleteSavedSelection_Callback,EEG,f});
set(f.SaveSelection,'Callback',{@saveSelections_Callback,EEG,f});
set(f.badElectrodeIndices,'Callback',{@badElectrodeIndices_Callback,f,0});
set(f.clearBadElectrodes,'Callback',{@badElectrodeIndices_Callback,f,1});%just updates the list and change save to red
set(f.saveBadElectrodes,'Callback',{@saveBadElectrodes_Callback,EEG,f});%saves it to the file and uses it below
set(f.varButton,'Callback',{@varButton_Callback,EEG});

f.tab.TabNames={'Plot','Spectra'};
f.tab.SelectedChild=1;

%% calculate freq res for display
    function tapers_callback(hObject,eventdata,EEG,f)
        if f.continuous
            epochLength=str2double(get(f.epochLength,'string'));%in seconds
        else
            epochLength=size(EEG.data,2)/EEG.srate;
        end
        %it's 2TW-1 for # of tapers with W as 1/2 the freq resolution
        %so want to display 2W
        fr=(str2double(get(f.tapers,'string'))+1)/epochLength;
        frText=sprintf('FR is %.2f Hz',fr);
        set(f.freqRes,'string',frText);
    end

%% plot EEG with selected options from above

    function plotEEG(hObject,eventdata,EEG,f)
        EEG.badElectrodeIndices=get(f.badElectrodeIndices,'value');%default is []
        %montage and relabel data using code below
        EEG=montageAndRelabel(EEG,f);
        
        %epoch data if continuous
        if f.continuous %then convert to epoched
            EEG=epochData(EEG,f);
%             epochLength=str2double(get(f.epochLength,'string'));%in seconds
%             EL=epochLength*EEG.srate; %epoch length in data points
%             
%             %first cut off data at end that isn't divisible by epoch length
%             if mod(size(EEG.data,2),EL)>0 %if not divisible
%                 fprintf('Removing last %.2f seconds\n',...
%                     mod(size(EEG.data,2),EL)/EEG.srate);
%                 EEG.data=EEG.data(:,1:end-mod(size(EEG.data,2),EL));   
%             end
%             EEG.data=reshape(EEG.data,size(EEG.data,1),EL,[]);
%             %fix all the relevant EEGLAB values to be consistent with epoched
%             %data, though not sure if necessary. Based on cutEeglab code
%             EEG.pnts=size(EEG.data,2);%this represents number of points in each epoch now
%             EEG.trials=size(EEG.data,3);
%             EEG.xmin=0;
%             EEG.xmax=epochLength-1/EEG.srate;%since starts at 0 then one point less
%             EEG.times=0:EEG.xmax*1000;%in ms
%             for e=1:length(EEG.event) %need to move them all into epochs now
%                 EEG.event(e).epoch=ceil(EEG.event(e).latency/EL);
%             end
        end
        
        %sort display order front to back which is the X variable
        [sorted,sortInd]=sort([EEG.chanlocs.X],2,'descend');
        EEG.data=EEG.data(sortInd,:,:);
        EEG.chanlocs=EEG.chanlocs(sortInd);
        
        %filter
        origSize=size(EEG.data);
        filterChoice=get(f.EEGfilter,'Value');
        if filterChoice==2 || filterChoice==4 %run 60 Hz
            eegtemp=zeros(size(EEG.data,1),size(EEG.data,2)*size(EEG.data,3));
            [b,a]=butter(8,[57/(EEG.srate/2) 63/(EEG.srate/2)],'stop');
            for i=1:size(EEG.data,1)
                eegtemp(i,:)=filtfilt(b,a,double(reshape(squeeze(EEG.data(i,:,:)),1,[])));%requires one vector at a time and as a double
            end
            EEG.data=reshape(eegtemp,origSize);
        end
        
        if filterChoice==3
            [b,a]=butter(5,0.1/(EEG.srate/2),'high');%try 5th order which is used in the EEGLAB filter
            eegtemp=zeros(size(EEG.data,1),size(EEG.data,2)*size(EEG.data,3));
            for i=1:size(eegtemp,1)
                eegtemp(i,:)=filtfilt(b,a,double(reshape(squeeze(EEG.data(i,:,:)),1,[])));
                
            end
            EEG.data=reshape(eegtemp,origSize);
        end
        
        %% load in previously selected epochs from a cut out .set file
         preselec=[];%default
        
        %new option to choose from saved values in this EEG file;
        prevEpochName=[];%to use to label EEG plot with name of previously chosen values if chosen below
        if get(f.dispPrevList,'value')
            preselec=EEG.eegplotChooseSelections(get(f.PrevSelectList,'Value')).epochs;
            prevEpochName=['(' cell2char(get(f.PrevSelectList,'String')) ' prev chosen displayed)'];
            if isempty(EEG.eegplotChooseSelections(1).epochs) %if empty since user shouldn't have clicked this option
                errordlg('No saved selections');
                return
            end
            preselec=[(preselec-1).*EEG.pnts preselec.*EEG.pnts repmat([0 1 0],size(preselec,1),1) zeros(size(preselec,1),EEG.nbchan)];
        
        elseif get(f.dispPrevExp,'Value')%old option to choose values from a cut out file which will
        %overwrite the one from the prev select list above
            pathnameOld=uipickfiles('type',{[f.setfilename '_*.set'],'.set file'},'prompt','Pick EEGLAB .set file with cut out data','out','char');
            [pathOld,prevEpochName]=fileparts(pathnameOld);
            prevEpochName=['(' prevEpochName ' prev chosen displayed)'];
            if isnumeric(pathnameOld) || isempty(pathnameOld) %if user presses cancel output is 0, done with no selection is {}
            else
                EEGOld = pop_loadset(pathnameOld);
                %first check to be sure that the chosen file was previously cut out
                %of the open one
                if ~isfield(EEGOld,'Source')
                    errordlg('Chosen previous set was not created by eegplotEpochChoose so can''t use.');
                    return
                end
                if ~strcmp(f.setfilename,EEGOld.Source.setname)
                    warndlg('WARNING: Chosen previous set name different from current. May be bug and not real error.');
                    %return
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
        
        

        %% plot data
        %if there's accelerometer data in the last 3, plot in a separate window so
        %it doesn't interfere with the view of the main data. Link them too.
        
        if strcmpi(EEG.chanlocs(end).labels,'AccZ') %&& ~filt %if already ran a HPF, may be no need to do this, though does help
            disp('Running diff.m on accelerometer channels as a fast HPF.');
            %     eegplot(permute(diff(permute(EEG.data(end-2:end,:,:),[2 1 3])),[2 1 3]),'srate',EEG.srate,'eloc_file',EEG.chanlocs(end-2:end),'events',EEG.event,'tag','acceegplot','winlength',10);
            %     accHandle=gcf;
            %     eegplot(EEG.data(1:end-3,:,:),'srate',EEG.srate,'eloc_file',EEG.chanlocs(1:end-3),'children',accHandle,'events',EEG.event,'title',['Choose ' appendname ' Press Enter when done (don''t close window)'],'winrej',preselec,'winlength',10);
            %note that zeros are because you lose one with the diff
            eegplotAndy([EEG.data(1:end-3,:,:) ; permute(diff(permute(EEG.data(end-2:end,:,:),[2 1 3])),[2 1 3]) zeros(3,1,size(EEG.data,3))],...
                'srate',EEG.srate,'eloc_file',EEG.chanlocs,'events',EEG.event,'title',['Choose epochs. ' prevEpochName]...
                ,'winrej',preselec,'winlength',ceil(10/(size(EEG.data,2)/EEG.srate)),...
                'tag',f.setfilename,'command',[],'butlabel',[]);
        else
            eegplotAndy(EEG.data,'srate',EEG.srate,'eloc_file',EEG.chanlocs,'events',EEG.event,'title',...
                ['Choose epochs. ' prevEpochName],'winrej',preselec,'winlength',ceil(10/(size(EEG.data,2)/EEG.srate)),'tag',f.setfilename,...
                'command',[],'butlabel',[]);
        end
        
        %new version uses eegplot since pop_eegplot didn't work. Found that TMPREJ
        %2nd column is the end time in points of the chosen epochs so just take
        %it and divide by pnts per epoch to get the
        %epoch number for choosing).
    end
        
    function EEG=epochData(EEG,f) %called by code above to plot the data
        epochLength=str2double(get(f.epochLength,'string'));%in seconds
            EL=epochLength*EEG.srate; %epoch length in data points
            
            %first cut off data at end that isn't divisible by epoch length
            if mod(size(EEG.data,2),EL)>0 %if not divisible
                fprintf('Removing last %.2f seconds\n',...
                    mod(size(EEG.data,2),EL)/EEG.srate);
                EEG.data=EEG.data(:,1:end-mod(size(EEG.data,2),EL));   
            end
            EEG.data=reshape(EEG.data,size(EEG.data,1),EL,[]);
            %fix all the relevant EEGLAB values to be consistent with epoched
            %data, though not sure if necessary. Based on cutEeglab code
            EEG.pnts=size(EEG.data,2);%this represents number of points in each epoch now
            EEG.trials=size(EEG.data,3);
            EEG.xmin=0;
            EEG.xmax=epochLength-1/EEG.srate;%since starts at 0 then one point less
            EEG.times=0:EEG.xmax*1000;%in ms
            for e=1:length(EEG.event) %need to move them all into epochs now
                EEG.event(e).epoch=ceil(EEG.event(e).latency/EL);
%                 EEG.event(e).latency=EEG.event(e).latency-(EL*(EEG.event(e).epoch-1));%subtract off how many datapoints are before it
            end
    end

%% choose EEG to export, exporting all including channels chose to remove ([] later codes will need to avoid these!)
    function chooseData(hObject,eventdata,EEG,f,keep)
        userdata=get(findobj('tag', f.setfilename), 'userdata');%get the selection data out of the eegplot
        
        if iscell(userdata) %meaning more than one with the same append name (unlikely but possible)
            errordlg('Multiple eegplots with same name, please close other eegplot window.');
            return
            %         userdatatemp=userdata{end};
            %         clear userdata;
            %         userdata=userdatatemp;
        end
        
        if f.continuous
            EEG=epochData(EEG,f);
        end
        
        savename=[f.setfilename '_' get(f.appendName,'string')];
        epochChoose=userdata.winrej(:,2)/EEG.pnts;
        %in line below used ismember (intersect and setdiff could've worked
        %too) to get index for where values are in the set and then exclude
        %with ~
        if keep
            EEGnew=pop_importdata('dataformat','array','data',EEG.data(:,:,epochChoose),...
                'setname',savename,'srate',EEG.srate,'pnts',EEG.pnts,'xmin',EEG.xmin,...
                'nbchan',EEG.nbchan,'chanlocs',EEG.chanlocs);
            EEGnew.Source.epochskept=epochChoose;
        else %if keep==0 then cut them out
            EEGnew=pop_importdata('dataformat','array','data',EEG.data(:,:,~ismember(1:size(EEG.data,3),epochChoose)),...
                'setname',savename,'srate',EEG.srate,'pnts',EEG.pnts,'xmin',EEG.xmin,...
                'nbchan',EEG.nbchan,'chanlocs',EEG.chanlocs);
            EEGnew.Source.epochscut=epochChoose;
        end
        
        EEGnew.Source.setname=EEG.setname;%just to save the name of the set it came from
        EEGnew.Source.daterun=date;%give the date run so can look at the version of code used
        
        pop_saveset(EEGnew,'filename',savename);
        
    end

%% delete previously saved selection from the list
    function deleteSavedSelection_Callback(hObject,eventdata,EEG,f)
        button=questdlg('Delete selected list?','Selection','Yes','No','No');
        if strcmp(button,'Yes')
            if size(EEG.eegplotChooseSelections,2)==1 %then remove whole thing
                EEG=rmfield(EEG,'eegplotChooseSelections');
            else %just remove the last one
        EEG.eegplotChooseSelections(get(f.PrevSelectList,'value'))=[];
        
            end
            EEG=pop_saveset(EEG,'savemode','resave');
        msgbox('Need to restart to update.');
        else
            return
        end
    end

%% save selections within the file instead of exporting

    function saveSelections_Callback(hObject,eventdata,EEG,f)
        %[] update the list and resave the EEG file to get it in there next
        %time. Might also want a way to delete one with a right click []
          userdata=get(findobj('tag', f.setfilename), 'userdata');%get the selection data out of the eegplot
        
        if iscell(userdata) %meaning more than one with the same append name (unlikely but possible)
            errordlg('Multiple eegplots with same name, please close other eegplot window.');
            return
       
        end
        name=inputdlg('Name of chosen epochs:');
        
        %now that can make from continuous, need to determine epoch length
        if f.continuous
            epochLength=str2double(get(f.epochLength,'string'))*EEG.srate;
        else
            epochLength=EEG.pnts;
        end
        
        if isempty(EEG.eegplotChooseSelections(1).epochs) %if none existing
            
        EEG.eegplotChooseSelections(1).names=name{1};
        EEG.eegplotChooseSelections(1).epochs=userdata.winrej(:,2)/epochLength;
        else
            numEpochs=length(EEG.eegplotChooseSelections);
            EEG.eegplotChooseSelections(numEpochs+1).names=name{1};
            EEG.eegplotChooseSelections(numEpochs+1).epochs=userdata.winrej(:,2)/epochLength;
        end
        
        EEG=pop_saveset(EEG,'savemode','resave');
        msgbox('Need to restart to have saved set displayed in list');
        
        %[] next need to figure out how to get this info into the figure since no where to set
        %the chosen epochs (the names can be in the displayed list) 
        
        
    end
%% plot spectra of 10-20 channels using headplot locations. Needs GUI within
%to change the frequency display range

    function plotSpectra_Callback(hObject,eventdata,EEG,f)
        
        %find or make figure
        try get(f.sf,'Type')%if no figure (has been closed) will give error
        catch %if no figure then create it, otherwise use previous one
            f.sf=figure;
            set(f.sf,'Name',[f.setfilename 'spectra']);
            set(f.cf,'userdata',[]);%if figure closed, then user probably doesn't want to see data again
        end
%         
%         f.sf=figure;
        
        
        %montage and relabel the data using code below. Note that it
        %removes channels if using 10-20 system
        EEG=montageAndRelabel(EEG,f);%removes bad electrodes as of 9/24/14
        
        %epoch the data like above (should be moved out so not repeated!)
        %[]
        
        if f.continuous %then convert to epoched
            epochLength=str2double(get(f.epochLength,'string'));%in seconds
            EL=epochLength*EEG.srate; %epoch length in data points
            
            %first cut off data at end that isn't divisible by epoch length
            if mod(size(EEG.data,2),EL)>0 %if not divisible
                fprintf('Removing last %.2f seconds\n',...
                    mod(size(EEG.data,2),EL)/EEG.srate);
                EEG.data=EEG.data(:,1:end-mod(size(EEG.data,2),EL));   
            end
            EEG.data=reshape(EEG.data,size(EEG.data,1),EL,[]);
            %fix all the relevant EEGLAB values to be consistent with epoched
            %data, though not sure if necessary. Based on cutEeglab code
            EEG.pnts=size(EEG.data,2);%this represents number of points in each epoch now
            EEG.trials=size(EEG.data,3);
            EEG.xmin=0;
            EEG.xmax=epochLength-1/EEG.srate;%since starts at 0 then one point less
            EEG.times=0:EEG.xmax*1000;%in ms
            for e=1:length(EEG.event) %need to move them all into epochs now
                EEG.event(e).epoch=ceil(EEG.event(e).latency/EL);
            end
        end
        
        %calculate the spectra using number of tapers listed above
        params.tapers(1)=(str2double(get(f.tapers,'string'))+1)*size(EEG.data,2)/EEG.srate;
        params.tapers(2)=str2double(get(f.tapers,'string'));
        params.pad=-1;%no padding
        params.trialave=1;
        params.Fs=EEG.srate;
%         if get(f.errorBars,'Value') %if error bars chosen
%             EB=1;
        params.err=[2 0.05];
%         else
%             EB=0;
%             params.err=[0 0.05];%no error calculation
%         end
        
        %initialize spectra outputs to save time
        ns=size(EEG.data,1);%number of spectra
        numFreq=floor(size(EEG.data,2)/2)+1;
        S=zeros(numFreq,ns);
        Serr=zeros(2,size(S,1),size(S,2));
        
        %choose epochs to use
        if get(f.epochsForSpectra,'Value')~=2 %if not All 
        %find chosen epochs to use for spectra
        eplot=get(findobj('tag',f.setfilename));%find the EEG plot
        if length(eplot)>1 %if more than one
            errordlg('Multiple EEG plots. Close non-active one(s)');
            return
        elseif isempty(eplot)
            errordlg('No EEG plots to determine chosen epochs');
            return
        end
        
        if isempty(eplot.UserData.winrej) %if no highlights
            errordlg('No highlighted epochs');
            return
        end
        
        if get(f.epochsForSpectra,'Value')==1 %if Highlighted
            ec=eplot.UserData.winrej(:,2)/size(EEG.data,2);
        elseif get(f.epochsForSpectra,'Value')==3 %if Not Highlighted
            ec=setdiff(1:size(EEG.data,3),eplot.UserData.winrej(:,2)/size(EEG.data,2));
        end
        else % if all
            ec=1:size(EEG.data,3);
        end
        
        %calculate spectra
        for d=1:ns
%             if EB %if EB checked
%                 params.err=[2 0.05];
                [spec.S(:,d),spec.f,spec.Serr(:,:,d)]=mtspectrumc(squeeze(EEG.data(d,:,ec)),params);
%             else
%                 [spec.S(:,d),spec.f]=mtspectrumc(squeeze(EEG.data(d,:,ec)),params);
%             end
        end
        
        %save the spectra so can plot multiple in one figure
        spectra=get(f.cf,'userdata');
        if get(f.holdSpectraPlots,'value')
        spectra=[spectra spec];%combine them
        else
            spectra=spec;%clear the old ones
        end
        set(f.cf,'userdata',spectra);%save the data in case want to plot on it later
            
            
        
        
%         figure(f.sf);
        
%         ct=str2double(get(f.cf,'Tag'));
%         set(f.cf,'Tag',num2str(ct+1));%since adding a plot
        
%         colors={'b','r','g','k'};
        
        %plot like on a headplot
         headplotSpectra(EEG.chanlocs,EEG.EGI,f.sf,spectra)
        
        
    end


%% function to montage and relabel
    function EEG=montageAndRelabel(EEG,f)
        
        %determine if EGI for later headplot
        if ~strcmpi(EEG.chanlocs(1).labels,'E1') %if not EGI
                EEG.EGI=0;%for headplotLocations
            else
                EEG.EGI=1;
                %9/26/14 need to determine which EGI headset since will remove
                %channels so just using the number below not enough
                switch length(EEG.chanlocs)
                        case 33 %if EGI33
                            EEG.EGItype=33;
                        case 129
                            EEG.EGItype=129;
                        case 65
                            EEG.EGItype=65;
                        otherwise
                            errordlg('Wrong number of EGI channels for list');
                            return
                end
        end 
        
        %9/24/14 add removal of bad channels starting here
        if ~isfield(EEG,'badElectrodeIndices')
            EEG.badElectrodeIndices=[];
        end
        EEG.data(EEG.badElectrodeIndices,:,:)=[];
        EEG.chanlocs(EEG.badElectrodeIndices)=[];
        EEG.nbchan=length(EEG.chanlocs);
        
        %montage first so that can display 10-20
        switch get(f.EEGmontage,'Value')
            %if 1, then leave as is
            case 2 %if laplacian
                EEG.data=MakeLaplacian(EEG.data,EEG.chanlocs);
            case 3 %if bipolar
                [EEG.data,chanlist,EEG.chanlocs]=MakeBipolar(EEG.data,EEG.chanlocs);
                EEG.nbchan=length(EEG.chanlocs);%since fewer channels now
            case 4 %if common average ref
                EEG = pop_reref( EEG, []);
        end
        
        
        
        %channels to display
        if get(f.EEGchannels,'Value')>1 %2 is 10-10 and 3 is 10-20 subset for EGI only
            %then rename the EGI channels and only show them.
            
            %rename channels if from EGI
            if ~EEG.EGI %if not EGI
                errordlg('10-20 just for EGI');
            else
                etable=egi_equivtable_Andy;%columns of E65, output, E129, E33
                output=etable(:,2);
                for ee=1:length(EEG.chanlocs)
                    switch EEG.EGItype
                        case 33 %if EGI33
                            EEG.chanlocs(ee).labels=output...
                                {strcmpi(EEG.chanlocs(ee).labels,etable(:,4))};
                        case 129
                            EEG.chanlocs(ee).labels=output...
                                {strcmpi(EEG.chanlocs(ee).labels,etable(:,3))};
                        case 65
                            EEG.chanlocs(ee).labels=output...
                                {strcmpi(EEG.chanlocs(ee).labels,etable(:,1))};
                        otherwise
                            errordlg('Wrong number of EGI channels for list');
                            return
                    end
                end
                %remove non 10-20
                non1020=cellfun('isempty',{EEG.chanlocs.labels});
                EEG.chanlocs=EEG.chanlocs(~non1020);
                EEG.data=EEG.data(~non1020,:,:);
                EEG.nbchan=size(EEG.data,1);
            
                %added 9/23/14
                if get(f.EEGchannels,'Value')==3 %if just the 10-20 and not all of them
                    ten20list={'FP1','FP2','F7','F3','FZ','F4','F8','T3',...
                'C3','CZ','C4','T4','T5','P3','PZ','P4','T6','O1','O2'};
            
                    for t2=1:length(ten20list)
                        uset2(t2)=find(strcmpi(ten20list{t2},{EEG.chanlocs.labels}));%determine the index of the channel we want
                    end
                    EEG.chanlocs=EEG.chanlocs(uset2);
                    EEG.data=EEG.data(uset2,:,:);
                    EEG.nbchan=size(EEG.data,1);
                end
            
            end
            
        end
    end

%% function to update the bad electrode list and save button
function badElectrodeIndices_Callback(hObject,eventdata,f,clear)
    if clear %if chose to clear them
        set(f.badElectrodeIndices,'Value',[]);
    end
    
    set(f.saveBadElectrodes,'enable','on','backgroundcolor',[1 0 0]);%turn red to signify need to save it
end

%% function to save to the file and use the bad electrode list

    function EEG=saveBadElectrodes_Callback(hObject,eventdata,EEG,f)
        
        %first update the active data
        EEG.badElectrodeIndices=get(f.badElectrodeIndices,'value');%default is [], other code above needs to use this
        
        %then update the original file, just adding in this new list
        pop_saveset(EEG,'filename',[f.setfilename]);%could consider adding c to signify bad channels selected
        
        %then make the button unusable to signify that it was saved
        set(f.saveBadElectrodes,'enable','off','backgroundcolor',[0.9294    0.9294    0.9294]);
    end

%% function display IQR of each electrode to help determine bad ones
    function varButton_Callback(hObject,eventdata,EEG)
        %first temporarily rereference to common average reference to
        %eliminate if Cz is bad
        EEG = pop_reref(EEG,[]);
        
        %first calculate the variance of all original channels
        variances=var(EEG.data');%originally did variance but changed
%        since too sensitive to outliers. Then did IQR but not sensitive
%        enough to bad electrodes 
%         IQR=iqr(EEG.data');
        
        %sort and determine an index to use to sort the electrodes
        [varSorted,varSorted_i]=sort(variances);
        
        channelsSortedByVar={EEG.chanlocs(varSorted_i).labels};
        
        for c=1:length(channelsSortedByVar)
            fprintf('%s %.2f\n',channelsSortedByVar{c},varSorted(c));
        end
    end

        

end

