%runs ICA on two datasets after combining them, saves the datasets, opens
%the scroll of the components as well as the components and starts program
%to run powerspectra on them. This code runs in the workspace with eeglab
%opened and requires only two datasets be open (could be modified, but
%safer this way). 

%To do:
%[] make so runs as a function on selected datasets, though would then be a
%lot more work to code up the selecting and removing of the components (or
%user would need to do manually)

%June 25 removed fpart creation, not sure why it's there since PSeeglab
%does it too.
%version 2 4/7/13 clean up code, check to make sure only 2 open, and run
%with them concatenated (rather than previous version which required they
%have the same subject number). 

if length(ALLEEG)>2
    disp('More or fewer than 2 datasets in memory, this code requires only 2 present and will run ICA on both)');
    return
end
% Looks like this sets the current dataset to be the first one
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'retrieve',[1 2] ,'study',0); 
EEG = eeg_checkset( EEG );

% EEG = pop_runica(EEG, 'icatype','runica','concatcond','on','options',{'extended' 1});%old version
%below line modified 4/7/13
EEG = pop_runica(EEG,'dataset',[1 2], 'icatype','runica','concatenate','on','options',{'extended' 1});
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%looks like next few lines save each dataset with the ICA information
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, [1 2] ,'retrieve',1,'study',0); 
EEG = pop_saveset( EEG, 'savemode','resave');
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'retrieve',2,'study',0); 
EEG = pop_saveset( EEG, 'savemode','resave');
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%now move back to the first dataset
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, [1 2] ,'retrieve',1,'study',0);

%% This section is to set up for choosing and later removing ICA componenets.
%first plots the ICA componenets from the first dataset, 
%[] need to change to eegplot and display only first 10 components and only
%10 seconds of data
pop_eegplot( EEG, 0, 1, 1);

%next display components as topoplots for rejection
pop_selectcomps(EEG, [1:length(EEG.icachansind)] );
eeglab redraw

%sets up to run power spectra
disp('Next will setup to run and save file of powerspectra of ICA. Choose ''i'' ');
PSeeglabWorkspace; %runs automatically from above two lines, savename name comes from alleeg.setname
disp('Need to run subplotEeglabSpectra and choose the ICA to plot it if want to see it');
clear alleeg eegorica figuretitle
disp('Next use the eeglab tool bar to choose to remove components');