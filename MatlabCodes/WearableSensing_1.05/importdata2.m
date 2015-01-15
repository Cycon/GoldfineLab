function S = importdata2(file_str)
%IMPORTDATA2   Read a CSV file and extract its information.
%   S = importdata2(file_str) reads the csv file with the path file_str and
%   returns parameter headers text as a cell column vector S.textdata, column headers
%   as a cell row vector S.colheaders and data matrix as S.data.
%
%Author: Umut Orhan
%Copyright: QUASAR 2011

fid=fopen(file_str,'r');
line_cnt=1;
istextline=1;
while(istextline)
    tline = fgets(fid);
    istextline=any(isletter(tline));
    headers{line_cnt}=tline;   
    line_cnt=line_cnt+1;
end
fclose(fid);
S.data=csvread(file_str,line_cnt-2);

colheader_locs=findstr(headers{line_cnt-2},',');

if(length(colheader_locs)+1==size(S.data,2))
    S.colheaders=cell(1,length(colheader_locs)+1);
    extended_colheader_locs=[0 colheader_locs length(headers{line_cnt-2})-1];
    for(ii=1:length(colheader_locs)+1)
        S.colheaders{ii}=headers{line_cnt-2}(extended_colheader_locs(ii)+1:extended_colheader_locs(ii+1)-1);
    end
    header_end=line_cnt-3;
else
    header_end=line_cnt-2;
end

S.textdata=headers(1:header_end)';