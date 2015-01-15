function dataStructure = xtp_aggregateCell(cutXLTEK)
%below modified from xtp_aggregate to take in a cell array rather than a
%list of files. Though realized it doesn't do anything. Mainly designed to
%put together separate files, not snippets from the same file.
%crxtoeeglabcut deals with multiple snippets in one file.

%compiles one big data structure by sequentially adding the datastructures
%the given datastructures to the base one. This function handles
%datastructures containing multiple epochs, whereas xtp_aggregate only
%support aggregating multiple datastructures each containing a single
%epoch.

funcname = 'xtp_aggregateCell';

%  dataStructure = cutXLTEK{1};
dataStructure = cutXLTEK;%above code gets rid of the cell aspect.
numsnippets = size(dataStructure.data, 2);
% there should be no updating of datatype - it should come directly from
% the source data and if it doesn't exist then xtp_aggregate is not going
% to make it up.
dataStructure.info.generatedBy = funcname;
dataStructure.info.rundate = clock;
dataStructure.info.source = inputname(1);

for dsnum = 2:size(cutXLTEK.data,2)
    dataStructure.metadata = [dataStructure.metadata cutXLTEK{dsnum}.metadata];
    for s = 1:size(cutXLTEK{dsnum}.data,2)
        if isfield(dataStructure.info, 'sMarkers')      % this must be ULT data
            dataStructure.data{1} = [dataStructure.data{1}; varargin{dsnum}.data{1}];
            dataStructure.info.sMarkers = cat(1,dataStructure.info.sMarkers,varargin{dsnum}.info.sMarkers+dataStructure.info.sMarkers(end,2));
        else
            dataStructure.data{numsnippets+s} = cutXLTEK{dsnum}.data{s};
        end
    end
    if size(dataStructure.metadata, 2) ~= size(dataStructure.data,2)
        fprintf(1,'ERROR: appending %s to the data structure yields unequal amounts of data & metadata.\n',inputname(dsnum+1));
        return;
    end
    numsnippets = size(dataStructure.data, 2);
end