function secDataUsed
%simple code to load in a PS.mat file and use dataCutByChannel to
%determine how many 3 second snippets are used. Assumes that all snippets
%are 3 seconds.

[PSfiles, pathname] = uigetfile('*PS.mat', 'Select PS files','MultiSelect','on');

if ~iscell(PSfiles)
    PSfiles=cellstr(PSfiles);
end
PSfilesSort=sort(PSfiles);

for i=1:length(PSfilesSort)
    PS=load(fullfile(pathname,PSfilesSort{i}));
    numbSnip=size(PS.dataCutByChannel{1},2);
    fprintf('%s uses %.0f snippets\n',PSfilesSort{i}(1:end-4),numbSnip);
end