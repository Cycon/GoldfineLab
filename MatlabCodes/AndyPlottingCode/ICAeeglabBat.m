function ICAeeglabBat

[setfilenames,pathname]=uigetfile('*.set','Picksetfiles','MultiSelect','on');

for ii=1:length(setfilenames)
    EEG=pop_loadset(fullfile(pathname,setfilenames{ii}));
    EEG = pop_runica(EEG, 'icatype','runica','dataset',1,'options',{'extended' 1},'chanind',[1:EEG.nbchan] );
    EEG = pop_saveset( EEG, 'savemode','resave');
end