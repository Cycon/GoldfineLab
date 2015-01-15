%to run on one dataset. Will need to modify for different numbers of
%channels.

%created 2/23/11
%updated 12/15/11 for opts in runEeglabSpectra
%1/22/14 updated number of ICAs to be accurate since using length gives
%total number of channels, but may be one less if the reference channel is
%included.

EEG = pop_runica(EEG, 'icatype','runica','dataset',1,'options',{'extended' 1},'chanind',1:EEG.nbchan );
EEG = pop_saveset( EEG, 'savemode','resave');
% pop_eegplot( EEG, 0, 1, 1);
eegplot(EEG.icaact,'srate',EEG.srate,'winlength',3,'dispchans',5);%5/9/11
pop_selectcomps(EEG, [1:size(EEG.icaact,1)] );
eeglab redraw
opts.eegorica='i';
runEeglabSpectra(EEG,opts);