% xtp_readXLTfileWithPhotic.m
%   function filedata = xtp_readXLTfile(filename, params)
%
% This function, given an XLTek export file, and optionally a number of
% leads to read, generates a matlab structure array (filedata) with the 
% following fields:
%   filedata.metadata is itself a structure with header information from
%   the file:
%    .samprate      sampling frequency
%    .start         start time (format mm/dd/yyyy hh:mm:ss)
%    .end           end time (format mm/dd/yyyy hh:mm:ss)
%    .hbnum         headbox number (corresponds to the order in which
%                   channels are listed)
%    .numleads      number of leads (called 'channels' in the XLTek output 
%                   file) that have been read.
%    .units         voltage units (usually millivolts) in which the eeg
%                   data is recorded
%   filedata.data is a TxL matrix with T samples of L leads
%
% filename must be a valid filename or path/filename.
% numleadstoread must be an integer number of leads. If it is not provided 
% or is more than the number of leads in the file, the function will read
% the number of leads specified in the header of the file.
% ENHANCEMENT FOR THE NEAR FUTURE: I should pass an array of leads to
% ignore (i.e. because they are shorted). I should also pre-read the data
% to filter out the AMPSAT or other text items that might show up. 
% also note if you continue support for the shorter number of channels to
% read, you need to add a command to go to the next line when finished
% reading the channels. else the function picks up reading the second one
% where it left off.
%
% Change log:
% Ver Date          Name            Changes
%     10/17/08      S. Williams     Created.
%     10/19/08      S. Williams     Added ui to select file without entering on
%                                   command line.
% 1.2 10/22/08      S. Williams     always request number of leads to read
%                                   if parameter not specified - allows
%                                   batch processing
% 1.3 10/25/08      S. Williams     reads data in as text first, then
%                                   converts to double (to get rid of
%                                   strings like AMPSAT & SHORT). obsoleted
%                                   the 'numleadstoread' workaround &
%                                   removed storage of unnecessary columns
%                                   by textscan
% 1.4 12/09/08      S. Williams     added 'OFF' to list of ignorestrings
% 1.5 12/10/08      S. Williams     insert call to xtp_checkEOF if the file
%                                   is not read to end.
% 1.6 03/20/09      S. Williams     add option ot specify headboxID, store
%                                   headbox id and labels in metadata
% 1.7 05/15/09      S. Williams     add info field
% 1.8 06/04/09      S. Williams     allow filename to be 0 so as to pass the
%                                   params even when filename is not given
%                                   @ command line.
%withPhotic v1  2/11/11 AG            add in cutting of third cell of
%                                   filedata.data which is photic.
%withPhotic v2 3/17/11 AG           added in cutting out of channels past
%                                   those listed in headbox. Important to shrink file size when not using all
%                                   channels on the 128 lead box
%           v3 8/12/11 AG           Read in data before headbox is assigned
%                                   Number of channels displayed.
% DON'T FORGET TO UPDATE VERSION NUMBER BELOW!!

function filedata = xtp_readXLTfileWithPhotic(filename, params)

global XTP_HEADBOXES XTP_GLOBAL_PARAMS

funcname = 'xtp_readXLTfileWithPhotic';
version = 'v3';

if nargin < 2
    params = XTP_GLOBAL_PARAMS;
end

% if no filename is given to start, open a ui to get it.
% if nargin < 1 || filename == 0 %2/11/11 - getting error here so changed
if nargin < 1 | filename == 0 
    fprintf(1, 'Please select an EEG export txt file to process.\n');
    [fname, pathname, filterindex] = uigetfile('*.txt', 'Please select an XLTek export file to read.');
    filename = [pathname fname];
end

filedata.info.datatype = 'XLTEK FILEDATA';
filedata.info.generatedBy = funcname;
filedata.info.version = version;
filedata.info.source = filename;
filedata.info.rundate = clock;

% make sure you can open the file.
[fid,message] = fopen(filename, 'rt');
if fid == -1
    disp(message)
else

    message = ['Reading file ' filename '...'];
    disp(message);
    filedata.metadata.sourceFile = filename;
    % let's get to reading!
    % first, ignore the first 3 lines
    fgetl(fid);
    fgetl(fid);
    fgetl(fid);
    %now read the file start time, end time and units
    line = fgetl(fid);
    filedata.metadata.start = strread(line, '%*s %*s %*s %*s %*s %19c');
    filedata.metadata.end = strread(line, '%*s %*s %*s %*s %*s %*s %*s %19c');
    line = fgetl(fid);
    tempstring = strread(line, '%*s %*s %s');
    filedata.metadata.units = tempstring{1,1};

    % read the sampling frequency, number of leads and headbox number,
    % ignoring lines in between.
    fgetl(fid);
    fgetl(fid);
    line = fgetl(fid);
    filedata.metadata.srate = strread(line, '%*s %*s %*s %n %*s');
    line = fgetl(fid);
    filedata.metadata.numleads = strread(line, '%*s %*s %d');       %added in v1.3
    % numleadstoread obsolete in v1.3------------>
    %numleadsinfile = strread(line, '%*s %*s %d');

    %if nargin == 2 && numleadstoread <= numleadsinfile
    %    message = ['File contains ' num2str(numleadsinfile) ' leads. Reading ' num2str(numleadstoread) ' leads.'];
    %    filedata.metadata.numleads = numleadstoread;
    %    disp(message);
    %else
    %    %removed in v1.2
    %    %message = ['This file contains ' num2str(numleadsinfile) ' leads. Reading ' num2str(numleadsinfile) ' leads'];
    %    fprintf ('This file contains %d leads. ',numleadsinfile); %added in v1.2
    %    numleadstoread = input('How many would you like to read? ');        %added in v1.2
    %    %filedata.metadata.numleads = numleadsinfile;        %removed in v1.2
    %    filedata.metadata.numleads = numleadstoread;        %added in v1.2
    %end
    % <------------ end numleadstoread 
    fgetl(fid);
    line = fgetl(fid);
    filedata.metadata.hbnum = strread(line, '%*s %*s %*s %n');
  

    % ignore the remaining 4 lines and begin loading data.
    fgetl(fid);
    fgetl(fid);
    fgetl(fid);
    fgetl(fid);

    % next, build the read string based on the number of channels provided
    readstring = '%19c %*d'; %AG this is to read in the date
    for l = 1:filedata.metadata.numleads %AG this is to read in the data
        readstring = [readstring ' %f']; %AG this adds on a %f for each channel
    end
    
    % this is a shameless hack to handle the fact that the last 2 leads in
    % my test file are recorded as SHORT instead of something matlab can
    % read as a number. I suspect I will have to somehow address SHORT 
    % leads in the middle of txt files, but not right now.
    % OBSOLETE IN V1.3
    %for l = filedata.metadata.numleads+1:numleadsinfile
    %    readstring = [readstring ' %s'];
    %end
    %the last column to read is the trigger column.
%     readstring = [readstring ' %*s'];   %added * in v1.3 since this column is not used and I don't want it incorporated in with the data
    %AG the above line adds an %s at the end so it can see the photic info.
    %The * means to ignore it.
    %('ON' or 'OFF')
    
   readstring = [readstring ' %s']; %AG no * here like in v1.2 to allow it to save photic as a 3rd cell. [] what does later code do with it?
    
    
    % now to read the data!
    filedata.data = cell(3);%3 part cell, first is date, second is data, third is photic status.
%     ignorestrings = {'AMPSAT';'SHORT';'--- BREAK IN DATA ---';'OFF'};
    ignorestrings = {'AMPSAT';'SHORT';'--- BREAK IN DATA ---'}; %AG see what it puts last line as then can change to text / data much later
    filedata.data = textscan(fid, readstring, 'TreatAsEmpty',ignorestrings,'CollectOutput', 1);
    % convert all data to numbers, weeding out the strings (like AMPSAT &
    % SHORT)
    %filedata.data{3} = str2double(filedata.data{3});
%%   
    if params.interactive
               fprintf(1,'Please identify the headbox that was used for this recording:\n');
        for hbid = 1:length(XTP_HEADBOXES)
            fprintf(1, 'Enter %d for %s.\n', hbid, XTP_HEADBOXES(hbid).name);
        end
         fprintf('\nNumber of channels in this dataset = %.0f \n\n',filedata.metadata.numleads);
        hbid = input('Choose one: ');
    else
        hbid = params.headboxID;
    end
    fprintf(1, 'Assigning headbox %s to this filedata.\n', XTP_HEADBOXES(hbid).name);   
      filedata.metadata.headbox.headboxID = hbid;
    filedata.metadata.headbox.labels = XTP_HEADBOXES(hbid).lead_list;
    %AG - add in code to only save the channels that are listed in the
    %headbox since others are irrelevant.
    filedata.data{2}=filedata.data{2}(:,1:length(filedata.metadata.headbox.labels));
%     filedata.metadata.numleads=length(filedata.metadata.headbox.labels);
%     %not sure if need or can can do better
    
    % confirm that we made it to the end of the file
    if feof(fid)
        message = 'File read complete.';
        disp(message);
    else
        stopspot = ftell(fid);
        message = ['WARNING: Unable to read all data from this file. Stopped at ' num2str(stopspot)];
        disp(message);
        xtp_checkEOF(filename, stopspot);
    end
    
    fclose(fid);
end

