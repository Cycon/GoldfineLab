function eegplotWithSpec

%8/23/11 instead of Reject, meant to run mtspectrumc_ULT on the selected
%data. Not a function since meant to run within eeglab for now, though can
%easily change to load in .set file, plot it and then run this. Essential
%to save all information so can recreate dataset (may be even save data
%used for plotting

%first load in dataset

[setfilename pathname]=uigetfile('*.set','Pick .set file to open');

EEG = pop_loadset('filename',setfilename,'filepath',pathname);

%set up params for mtspectrumc_ULT
params.Fs=EEG.srate;
params.pad=-1;
params.err=[2 0.05];
movingwin=[1 1]; %may want to change depending upon length of dataswatches
params.tapers=[2 movingwin(1) 1];%may want to give user option to change

%command called below by button push. Need to change name of button
%[] make new dataset using TMPREJ. Want samples x channels
%[] create sMarkers using TMPREJ
%[] Run mtspectrumc_ULT using params set above
%[] save in format that subplotEeglabSpectra is used to
%[] save dataused, name of EEG file, srate, sMarkers, spectra, f, Serr
buttonCommand=['
    
%plot data with event duration displayed as default though can be turned
%off in UI.

eegplot(EEG.data,'srate',EEG.srate,'eloc_file',EEG.chanlocs,'butlabel','Spectrum','events',EEG.event,'ploteventdur','on','command',buttonCommand);['[EEGTMP LASTCOM] = eeg_eegrej(EEG,eegplot2event(TMPREJ, -1));' ...
'  [ALLEEG EEG CURRENTSET tmpcom] = pop_newset(ALLEEG, EEGTMP, CURRENTSET);' ...
'     eeglab(''redraw'');' ...
'clear EEGTMP tmpcom;']);