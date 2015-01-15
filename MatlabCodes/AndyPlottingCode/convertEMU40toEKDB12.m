function convertEMU40toEKDB12

%this simply removes the leads from EMU40 (37) that aren't in EKDB12 (29) so when you
%do a laplacian in PSeeglab or CohEeglab it doesn't bias the results since
%the lead spacings may be different

%might not be good to do this since not sure how to save the resutls since
%won't be able to pull them in to code that looks for eeglab files.

%%
%load data
[setfilename, pathname] = uigetfile('*.set', 'Select EEG file(s) for coherence','MultiSelect','on');

%in case only choose one, make into a cell
if ~iscell(setfilename)
    if setfilename==0; %if press cancel for being done
        return
    end
    setfilename=cellstr(setfilename);
end

for ij=1:length(setfilename)
    runConvert(setfilename{ij},pathname);
end

function runConvert(setfilename,pathname)
    EEG = pop_loadset('filename',setfilename,'filepath',pathname);
    EEG = pop_select( EEG,'nochannel',{'FPz' 'F1' 'F2' 'CPz' 'PO7' 'POz' 'Oz' 'PO8'});
    EEG.setname=sprintf('%s_29',EEG.setname);
    EEG = pop_saveset( EEG, 'filename',EEG.setname,'filepath',pathname); % no pop-up
%                                              
% Inputs:
%   EEG        - EEG dataset structure. May only contain one dataset.
%
% Optional inputs:
%   'filename' - [string] name of the file to save to
%   'filepath' - [string] path of the file to save to
%   'check'    - ['on'|'off'] perform extended syntax check. Default 'off'.
%   'savemode' - ['resave'|'onefile'|'twofiles'] 'resave' resave the 
%                current dataset using the filename and path stored
%                in the dataset; 'onefile' saves the full EEG 
%                structure in a Matlab '.set' file, 'twofiles' saves 
%                the structure without the data in a Matlab '.set' file
%                and the transposed data in a binary float '.dat' file.
%                By default the option from the eeg_options.m file is 
%                used.
%
% Outputs:
%   EEG        - saved dataset (after extensive syntax checks)
    
end
end
