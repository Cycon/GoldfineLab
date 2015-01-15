function renamefiles
%AMG - simple tool to rename many file names within a folder at once.
%version 2 if .set file included should automatically rename EEG.setname
%and resave with the EEGLAB file save command

%%
matFigPng=input('Run on .mat / .fig (1) or .set files (0) [1]?');
if isempty(matFigPng)
    matFigPng=1;
end

% extension=input('Extension name to select from (like .fig, Return for * (all files)): ','s');
if matFigPng
    extension={'*.mat','.mat';'*.fig','.fig';'*.png','.png'};
else
    extension={'*.set','.set'};
end
remove=input('Number of characters to remove from beginning ([0]: ');
if isempty(remove)
    remove=0;
end
new=input('New characters to put at beginning: ','s');

%%
filenames=uipickfiles('type',extension,'prompt','Pick files');
% [filenames, pathname] = uigetfile(extension, 'Select files to modify','MultiSelect','on');

for f=1:length(filenames)
    [paths{f} names{f} ext{f}]=fileparts(filenames{f});
end
%%
for i=1:length(filenames)
    if i==1
        fprintf('First file will be renamed to: %s\n',[new names{i}(remove+1:end)]);
        if strcmpi(input('Okay (Return to continue, n to stop)? ','s'),'n')
            return
        end
    end
   
    if matFigPng
        movefile(filenames{i},fullfile(paths{i},[new names{i}(remove+1:end) ext{i}]));
    else
        EEG=pop_loadset('filename',filenames{i});
        EEG=pop_editset(EEG,'setname',[new names{i}(remove+1:end)]);
        EEG=pop_saveset(EEG,'filename',[new names{i}(remove+1:end)],'savemode','onefile');
    end
end
