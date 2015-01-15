function [fileinfo, recstruct, totnumrecs, outdata] = readEDFfile( fname, numrecs )
%
% This EDF reader is provided by Ahmet Omurtag as a courtesy to be used for
% research purposes. It comes with absolutely no guarantees.
%
% INPUTS:
%
% fname: EDF file to be read (full path)
% numrecs: Number of data records to be read.
%               If numrecs=[], all available data returned
%               If numrecs > number of records in the file, all available
%               data returned
%               If numrecs=-1 then only the headers are filled, no data returned
%               If numrecs=0 then only the headers and total number of
%               records are filled, no data returned
%
% OUTPUTS:
%
% fileinfo: generic header fields
% recstruct: signal-specific header fields
% totnumrecs: total number of records
% outdata: data
%
% Explanation of structure RECSTRUCT
%
%   Each element of RECSTRUCT describes one of the signals in
%   the file.  The fields of RECSTRUCT are:
%           label (e.g. EEG Fpz-Cz or Body temp)
%           transducer_type (e.g. AgAgCl electrode)
%           physical_dimension (e.g. uV or degreeC)
%           physical_minimum (e.g. -500 or 34)
%           physical_maximum (e.g. 500 or 40)
%           digital_minimum (e.g. -2048)
%           digital_maximum (e.g. 2047)
%           prefiltering (e.g. HP:0.1Hz LP:75Hz)
%           Number_of_Samples
%           Reserved
%
% EXAMPLE:
%{

filefullpath = 'C:\\EEGDATA\\myeegfile.edf';
NUMRECSTOREAD1 = 5;
[genheadr, sigheadr, totnumrecs, data] = readEDFfile( filefullpath, NUMRECSTOREAD1 ); 
fclose('all');

%}

%% PROCESS INPUT

MAXNUMRECS = 1000000;
if isempty(numrecs), numrecs = MAXNUMRECS; end

%% OPEN FILE FOR READING

fid = fopen(fname,'r');

%% READ FILE HEADER

%This vector gives the number of bytes allocated to each field
fileheaderfmt = [8 ; ... %version of this data format (0)
    80 ; ... %local patient identification (mind item 3 of the additional EDF+ specs)
    80 ; ... %local recording identification (mind item 4 of the additional EDF+ specs)
    8 ; ... %startdate of recording (dd.mm.yy) (mind item 2 of the additional EDF+ specs)
    8 ; ... %starttime of recording (hh.mm.ss)
    8 ; ... %number of bytes in header record
    44 ; ... %reserved
    8 ; ... %number of data records (-1 if unknown, obey item 10 of the additional EDF+ specs)
    8 ; ... %duration of a data record, in seconds
    4] ; %number of signals (ns) in data record

% Read the file header
fhbuf = fread(fid,sum(fileheaderfmt));

% Create a structure containing the file info
fileinfo.nsig = str2double(char(fhbuf(end-3:end))); %Number of signals in each data record
fileinfo.nrecs = str2double(char(fhbuf(end-19:end-12))); %Number of data records
fileinfo.patientID = char(fhbuf(9:88)');
ipos = sum( fileheaderfmt(1:8) ) + 1;
fileinfo.durationrec = str2double(char(fhbuf(  ipos:ipos+7 ) ) );
%Could add more to this structure if information is desired


nsig = fileinfo.nsig; %number of signals per data record
nrecs = fileinfo.nrecs; %number of data records
durationrec = fileinfo.durationrec; % duration of a record

%% READ SIGNAL HEADER

%The data record header is formed by repeating the value for each field
%NSIG times.  For example, if NSIG = 2, the data record woud have 2 x 16
%bytes for label followed by 2 x 80 bytes for transducer type, etc.

%This vector gives the number of bytes used to represent each field
dataheaderfmt1sig = [ 16 ; ... %nsig * label (e.g. EEG Fpz-Cz or Body temp) (mind item 9 of the additional EDF+ specs)
    80 ; ... %nsig * transducer type (e.g. AgAgCl electrode)
    8 ; ... %nsig * physical dimension (e.g. uV or degreeC)
    8 ; ... %nsig * physical minimum (e.g. -500 or 34)
    8 ; ... %nsig * physical maximum (e.g. 500 or 40)
    8 ; ... %nsig * digital minimum (e.g. -2048)
    8 ; ... %nsig * digital maximum (e.g. 2047)
    80 ; ... %nsig * prefiltering (e.g. HP:0.1Hz LP:75Hz)
    8 ; ... %nsig * nr of samples in each data record
    32] ; ... %nsig * reserved

dataheaderfmt = nsig * dataheaderfmt1sig;
dfbuf = fread(fid,sum(dataheaderfmt));

% Create a record structure RECSTRUCT.  Populate it with description for each signal

% RECSTRUCT field labels
dhfields = {'label','transducer','physical_dimension','physical_minimum',...
    'physical_maximum','digital_minimum','digital_maximum','prefiltering',...
    'Number_of_Samples','Reserved'};

% Fill the fields with the header data
for k = 1:length(dataheaderfmt)
    if k == 1
        recstruct = struct(dhfields{1},cellstr(char(reshape(dfbuf(1:dataheaderfmt(1)),dataheaderfmt1sig(1),nsig)')));
    else
        fieldvalue = cellstr(char(reshape(dfbuf(sum(dataheaderfmt(1:k-1))+1:sum(dataheaderfmt(1:k))),dataheaderfmt1sig(k),nsig)'));
        [recstruct.(dhfields{k})] = deal(fieldvalue{:});
    end
end

totnumrecs = [];
outdata = [];

if 0 > numrecs, return; end

%% READ NUMBER OF DATA RECORDS

% how many int16 to read in one record
numtoread = 0; for kkk=1:nsig, numtoread = numtoread + str2num(recstruct(kkk).Number_of_Samples); end

% how many records are in the file
fpos = ftell(fid);
fprintf('Determining total number of records... ');
countrecs = 0;
[databuf0, numdidread] = fread(fid, numtoread, 'bit16');
while numdidread == numtoread & countrecs <= MAXNUMRECS,
    countrecs = countrecs + 1;
    [databuf0, numdidread] = fread(fid, numtoread, 'bit16');
end
fprintf(' %d \n', countrecs);
Tsec = countrecs.*fileinfo.durationrec;
fprintf('Total recording time: %f minutes\n',Tsec./60);

totnumrecs = countrecs;
if 0==numrecs, return; end

%% READ DATA
% allocate space to read data
maxnumtoread = min( countrecs, numrecs );
fprintf('Will read %d records\n',maxnumtoread);
outdata = cell(1,nsig);
for isig = 1:nsig,
    numsamp = str2num(recstruct(isig).Number_of_Samples);
    outdata{isig} = zeros(maxnumtoread.*numsamp, 1);
end

% rewind to beginning of data
fseek(fid, fpos, 'bof');

% read data
fprintf('Done %8.0f%%', 0);
for irec = 1:maxnumtoread,

    if  0==mod(irec, round(maxnumtoread./10)),  % display progress
        fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b');
        fprintf('Done %8.0f%%',  100.*irec./maxnumtoread);
    end

    % read a record
    [databuf0, numdidread] = fread(fid, numtoread, 'bit16');

    if numdidread < numtoread, error('Error reading file %s\n',fname); end

    iend = 0;
    for isig = 1:nsig,
        nsamp = str2num(recstruct(isig).Number_of_Samples);

        ibeg = iend + 1; iend = ibeg + nsamp - 1;
        databuf = databuf0( ibeg : iend );

        ibegn = (irec - 1).*nsamp + 1; iendn = ibegn + nsamp - 1;
        outdata{isig}( ibegn : iendn ) = databuf;
    end

end
fprintf('\n');

fclose(fid);

return;