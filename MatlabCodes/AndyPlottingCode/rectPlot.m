function rectPlot(values,channels,showtext)
%give list of values as vector and channels as 1xN cell or chanlocs
%structure. Set showtext=0 if don't want to see channel names and values
%converts value into a gray scale and put into rectangle
%requires JV's code, eegp_makechanlocs to make a chanlocs structure
%contining the channel locations.
%[]put in option for color scaling though would need to be called by a gui
%structure directly

if nargin<3
    showtext=1;
end

if ~length(values)==length(channels)
    disp('In rectPlot, number of values doesn''t match number of channels');
    return
end

% cmap=ColorSpiral(100);%not good since starts at white
 cmap=colormap(hot(70));%make a color map with 100x3 values
 cmap(71:100,:)=repmat(cmap(70,:),30,1);
 
 if ~isstruct(channels)%if you give it a cell (otherwise consider it to be a chanlocs structure like EEG.chanlocs)
    chans=eegp_makechanlocs(char(channels'));
 end
 
rsize=[3 3];%size of ellipses

for jj=1:length(chans)
%     v=values(jj)/sum(values);%fraction of total value for this channel
%     v=values(jj)/max(values);%this way always have max color for max value, "scaled"
%      rectangle('Position',[chans(jj).Y-.5*rsize(1),chans(jj).X-.5*rsize(2),rsize(1),rsize(2)],...
%        'Curvature',1,'FaceColor',cmap(ceil(v*100),:));
%      rectangle('Position',[chans(jj).Y-.5*rsize(1),chans(jj).X-.5*rsize(2),rsize(1),rsize(2)],...
%          'Curvature',1,'EdgeColor','none','FaceColor',cmap(ceil(v*100),:));
    rectangle('Position',[chans(jj).Y-.5*rsize(1),chans(jj).X-.5*rsize(2),rsize(1),rsize(2)],...
         'Curvature',1,'EdgeColor','none','FaceColor',cmap(ceil(values(jj)*100),:));%since values is 0 to 1! 
     %advantage of this version is can compare across studies, but doesn't
     %use all the colors in the display with 100 values in color map. Might
     %be better to use a shorter colormap 
    hold on;
    valuestr=sprintf('%.2f',values(jj));%to make the value as a string for display
    if showtext
        text(chans(jj).Y,chans(jj).X,{channels{jj} valuestr},'HorizontalAlignment','center','FontSize',6);
    end
    %    text(chans(jj).Y,chans(jj).X,num2str(values(jj)),'HorizontalAlignment','center','FontSize',6);
    axis equal
    set(gca,'Xtick',[],'Ytick',[],'Xcolor','w','Ycolor','w');
%     set(gca,'Visible','off')
end