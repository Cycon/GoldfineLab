function badlist=ChannelListGUI(savename,ChannelList)

%makes a listbox with all the channels and a done button. User selects
%channels to exclude from plotSigFreq with ctrl-click and then press done.
%called by plotSigFreq
%
%created 3/18/10 by AG
%version 2 4/6/10 changed to use mltable instead of listbox
% f=figure('Units','normalized','Position',[0.6 0.2 0.15 0.7]);
% Listbox = uicontrol('Style', 'listbox','Position', [10 90 80 450], 'String', ChannelList,'Max',length(ChannelList),'Value',[]);

uicontrol('Position',[200 5 60 60],'String','Done','Callback',{@Done_callback});
%%
%this uses the code mltable from
%http://www.mathworks.com/matlabcentral/fileexchange/6734-editable-table-in-matlab
%to create a table listing the channels and allowing for selection of 
%starting frequency to block out from sigfreqplot view
%Could change it to have a checkbox that spits out values
table=axes('units','pixels','position',[10 10 140 400]);
defaultValue{1}=0;
% ChannelList={ChannelList};
cell_data=cell(length(ChannelList),2);
cell_data(:,1)=ChannelList;
cell_data(:,2)=repmat(defaultValue,length(ChannelList),1);
columninfo.titles={'Channel','StartFreq'};
columninfo.formats={'%s','%.0f'};
columninfo.weight=[1,1];
columninfo.multipliers=[1,1];
columninfo.isEditable=[0,1];
columninfo.isNumeric=[0,1];
columninfo.rowsFixed=1;
columninfo.withCheck = true; % optional to put checkboxes along left side
columninfo.chkLabel = 'Bad';
rowHeight=16;
gFont.size=9;
gFont.name='Helvetica';

mltable(gcf,table,'CreateTable',columninfo,rowHeight,cell_data,gFont);




uiwait %this command seems necessary to ensure it waits to select channels and press done. it
%stops waiting when window is closed though could also type uiresume
function Done_callback(varargin)
%     index_selected = get(Listbox,'Value');
    info = get(table,'UserData');
    badlist=ChannelList(logical(info.isChecked));
%     badlist=ChannelList(index_selected);
    startingFreqList = info.data(:,2)';
    badlist(2,:)=startingFreqList(logical(info.isChecked));
%     checkval = data.isChecked;
    savename=[savename '_BadChannels'];
    save (savename, 'badlist');
    close(gcf); %other option is uiresume
end

end