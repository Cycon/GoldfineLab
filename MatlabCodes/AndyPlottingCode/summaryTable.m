function summaryTable

%make summary table with:
%1. Channel Names
%2. If feel should exclude
%3. If any positive freq between 5 and 40 Hz
%4. If any positive freq > 2Hz between 5 and 40 Hz
%5. Fisher two columns of results

[filename, pathname, filterindex] = uigetfile('*List.mat', 'Select subplot output file');
output=load(fullfile(pathname,filename));
  
ChannelList=output.ChannelList;
contiguousMoreThanFR=output.contiguousMoreThanFR;

for ic=1:length(ChannelList)
    if any(any(4<=contiguousMoreThanFR{ic}{1} & contiguousMoreThanFR{ic}{1}<=40) | any(4<=contiguousMoreThanFR{ic}{2} & contiguousMoreThanFR{ic}{2}<=40))
        TGTsigresult{ic}='Y';
    else
        TGTsigresult{ic}=[];
    end
end

[filename2, pathname2, filterindex2] = uigetfile('*Data.mat', 'Select Fisher output file');
fisher=load(fullfile(pathname2,filename2));

p=fisher.p_segflip';
pSig=cell(length(p),1);
for ip=1:length(p)
    if p{ip}<=0.05
        pSig{ip}='<0.05';
    end
end
percentCorrect=fisher.percentCorrectMapbayesSegs';

fprintf('Which channels were excluded from the significant frequency summary plot?\n')
disp(ChannelList);
badlist=input('Enter a cell array of strings like {''Fp1'' ''Fp2''):\n');

for j=1:length(badlist)
    if ~any(strcmp(badlist{j},ChannelList)) %if none of the Channels are spelled the same as one typed in
            fprintf('%s is spelled wrong, start over\n',badlist{j})
            return
    end
end
  
channelsExcluded=cell(length(ChannelList),1);
for il=1:length(ChannelList)
   if any(strcmp(ChannelList{il},badlist))
    channelsExcluded{il}='X';
   end
end

%%
%make table figure

figure('Position',[50 100 500 600]);
columnNames={'Channel' 'Excluded' 'AnySigTGT' '%Correct' 'p-value'};
tableData=ChannelList';
tableData(:,2)=channelsExcluded;
tableData(:,3)=TGTsigresult';
tableData(:,4)=percentCorrect;
tableData(:,5)=pSig;
table=uitable('Data',tableData,'ColumnNames',columnNames,'NumRows',size(tableData,2),'Position',[0 0 450 600]);


beep;
