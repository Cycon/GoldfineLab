function displaySortResults(ChannelList,avgdiff5to100)

%sorts channels by approximate derivative (average of differences)of
%spectrum from 5 to 100 Hz. Higher values suggest more artifact.
[filename, pathname, filterindex] = uigetfile('*List.mat', 'Select subplot output file');
output=load(fullfile(pathname,filename));
  
ChannelList=output.ChannelList;
avgdiff5to100=output.avgdiff5to100;

ad=cell2mat(avgdiff5to100); %convert to matrix so can sort
[avgDiffSorted ix]=sort(ad); %obtain sorting index ix
CLSortedByEMG=ChannelList(ix);

disp('Channels sorted by amount of artifact (flatness of spectrum 5-100Hz)')
% for i=1:length(ChannelList)
%     fprintf('%s  %.3f\n',CLSortedByEMG{i},avgDiffSorted(i))
% end;

CLSortedByEMG=CLSortedByEMG';
CLSortedByEMG(:,2)=num2cell(avgDiffSorted');
%%
%make a table popup with the results
figure('Position',[50 100 200 500]);
columnNames={'Channel' 'deriv0to100'};
% figure;
table=uitable('Data',CLSortedByEMG,'ColumnNames',columnNames,'NumRows',size(CLSortedByEMG,2),'Position',[0 0 250 500]);

save sortedByArtifact CLSortedByEMG

