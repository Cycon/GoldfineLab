% xtp_readEpochs.m
%
% This function reads a list of start times & end times into a 2 column cell array.
% times are assumed to be in the following format: 'mm/dd/yyyy HH:MM:SS'
%
% EXAMPLE: epochList = xlt_readEpochs ([filename])
%   if the filename argument is left blank, the user is prompted to select
%   it via a GUI window.
%

% Change Log:
% Ver Date      Person      Change
% 1.0 10/24/08  S. Williams Created
% 1.1 12/06/08  S. Williams replace tabs with spaces if it hasn't already
%                           been done.
% 1.2 03/11/09  S. Williams Modify UI prompts to clarify what is being done
%                           Replace tabs with spaces wo prompting
%1.3 5/1/11 5/1/11 AMG make option to press cancel to not use. For
                            %xltekToEeglab

function epochList = xtp_readEpochs (filename)

fprintf(1, '\nReading epoch list...\n');

% if no filename is given to start, open a ui to get it.
if nargin < 1
    [fname, pathname] = uigetfile('*.txt', 'Select epoch list file or Cancel to not use.');
    if fname==0
        epochList=0;
        return
    end   
    filename = [pathname fname];
end

[fid,message] = fopen(filename, 'rt');
if fid == -1
    disp(message)
    epochList = [];
    return
end
message = ['Reading file ' filename '...'];
disp(message);

epochList = textscan(fid, '%19c %19c');
if feof(fid)
    message = 'Successfully read epoch list file.';
else
    message = ['ERROR: Unable to read all data from this file. Stopped at ' num2str(ftell(fid))];
end

for epoch = 1:size(epochList{1},1)
    epochList{1}(epoch,:) = regexprep(epochList{1}(epoch,:),'\t',' ');
    epochList{2}(epoch,:) = regexprep(epochList{2}(epoch,:),'\t',' ');
end
disp(message);
fclose(fid);

end


