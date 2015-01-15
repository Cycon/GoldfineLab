%10/25/13 AMG script (runs in workspace) to easily load an eeg file into 
%a variable called eeg. Much faster than loading the whole EEGLAB
%environment

if exist('eeg','var')
    disp('eeg variable already in workspace');
    if ~strcmpi(input('Overwright? (y/n) [n]','s'),'y')
        return
    else
        clear eeg
    end
end

try eeg = pop_loadset(uipickfiles('type',{'*.set','.set file'},'prompt','Pick EEGLAB .set file','out','char'));
catch 
    return
end
