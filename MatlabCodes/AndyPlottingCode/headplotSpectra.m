function headplotSpectra(chanlocs,EGI,fig,spectra)

%modified from headplotEeglabSpectra.
%created 8/16/13 along with headplotLocations.m
%Channels not on head will have xnew=nan so can exclude. Need to figure
%out how to show just subset of channels & remove edge channels.
%
%Takes chanlocs to create xnew and ynew which comes from headplotLocations. Then needs to know 
%if EGI since it needs to be flipped left to right. Then takes in spectra each
%as a structure containing S (frequency x channel), f (vector of
%frequency), and Serr (2,frequency,channel). Spectra is a structure so can have
%multiple entries into it for different spectra (e.g., spectra(1)., spectra(2), etc.).
%Note that it needs a figure
%to be created in so this code doesn't work on own.

[xnew,ynew]=headplotLocations(chanlocs,EGI);

% %next take in the spectra for plotting
% for v=1:length(varargin)
%     spectra(v)=varargin{v};
% end

h.fig=fig;
figure(h.fig);%needs to know ahead of time the figure

  %set default plotting frequency range
        h.pfr1=uicontrol('parent',h.fig,'style','edit','units','normalized','position',[0.01 .01 .05 .05],'string','0');
        h.pfr2=uicontrol('parent',h.fig,'style','edit','units','normalized','position',[0.1 .01 .05 .05],'string','40');

%tried to make it with tabs with uiextras but couldn't control where to
%make the plots. Instead will need to make regular figures and little
%buttons and controls on the plot

%[] Stuff below needs to be incorporated:
%         suppEdge=get(h.edge,'value');
%         %remove edge electrodes if chosen
%         if suppEdge %below based on coherenceDiffMap as of 4/29/12
%             hopts.mont_mode='Laplacian';%use hopts since use opts below
%             hopts.Laplacian_type='HjorthAbsRescaled';
%             hopts.Laplacian_nbrs_interior=5;%so more lines filled in
%             Hjorth=cofl_xtp_makemont(dh.spectra(1).ChannelList',[],hopts);
%             
%             edgeInd=sum(Hjorth<0,2)==3;%gives the indices of the edge channels
%             dh.cv=dh.cv(~edgeInd);%remove the chanlocs of edge channels
%             for j4=1:ns
%                 dh.spectra(j4).S(:,edgeInd)=[];
%                 dh.spectra(j4).Serr(:,:,edgeInd)=[];
%                 dh.spectra(j4).ChannelList(edgeInd)=[];
%             end
%             
%         end
  
%[] this needs to be incorporated
%         adobeExp=get(h.adobe,'Value');%determine if want to export to eps to illustrator
        
%remove non-channels
off=isnan(xnew);
for j3=1:length(spectra)
    spectra(j3).S(:,off)=[];
    spectra(j3).Serr(:,:,off)=[];
    spectra(j3).ChannelList(off)=[];
end
chanlocs(off)=[];
xnew(off)=[];
ynew(off)=[];

%plot the axes by using the radius. Normalize the radii by the maximum one
        %and then make it a little smaller to ensure it stays on the figure (m)
        maxy=max(abs(ynew));
        maxx=max(abs(xnew));
        m=.4;%factor to decrease the total spread (.4 not .8 since center is 0.5 0.5)
        aLC=[0.5-.01 0.5-.01]; %axes location change
%         if suppEdge
%             figsize=[0.1 0.07];
% %             figsize=[0.03 0.03];
%         else

            ns=length(spectra);%number of spectra being plotted on each plot (not number of channels)
            nc=size(spectra(1).S,2);%number of channels
            if nc<25 %added 4/16/13 so that if fewer channels, make them bigger (might want different code for lots of 
                %electrodes, or just remove many of them)
                figsize=[0.15 0.09];%this size worked nice for laplacian channels
                figsize=[0.1 0.1];
            else
                figsize=[0.07 0.07];%size of the the axis on the figure
%             figsize=[0.03 0.03];
            end
        
        
        colorlist={'r','b','g'};
        if ns>length(colorlist)
            errordlg('Only three spectra colors, uncheck hold on and replot')
            return
        end
        h.bcolor=get(h.fig,'color');%background color to hide y-axes
        
        %next need to remove x-axes displayed from previous plots so new
        %doesn't overlap
        chil=get(h.fig,'children');
        chil_ax=chil(strcmp(get(chil,'type'),'axes'));
        if ~isempty(chil_ax) %if there are any
            set(chil_ax,'xtick',[]);
        end
        for kk=1:nc%for each channel
            h.axes(kk).ax=axes('units','normalized','position',[ynew(kk)/maxy*m+aLC(1) xnew(kk)/maxx*m+aLC(2) figsize]);
            hold on;
            %took out CIplot 1/17 since hard to hide error bars otherwise
            for j8=1:ns
                %eb is for error bar
                h.axes(kk).eb(j8)=fill([spectra(j8).f fliplr(spectra(j8).f)],...
                    [10*log10(squeeze(spectra(j8).Serr(1,:,kk))) fliplr(10*log10(squeeze(spectra(j8).Serr(2,:,kk))))],colorlist{j8});
                plot(spectra(j8).f,10*log10(squeeze(spectra(j8).S(:,kk))),colorlist{j8},'LineWidth',2);
                axis tight;
                grid on; %this turns grid on
                %  grid off;
                hold('all'); %this is for the xticks and grid to stay on
            end
            
            
            set([h.axes.eb],'linestyle','none','facealpha',0.2); %to make the fill transparent
            h.t(kk)=title(chanlocs(kk).labels);
            set(gca,'ycolor',h.bcolor);
        end
        % linkaxes(h.ax); %not a good idea since different total power in all.
        % Would need to normalize by DC power or something. Might be better to make
        % a different vertical zoom button.
        % linkzoom(h.ax);
        
        %%
        %modify the plotting based on the GUI information. Below pulls info
        %out of graph since originally graph was created up above.
        
        %         for k = 1:length(h.axes), zoom(h.axes.ax(k),'reset'); end;% to remove linkzoom
        p1=str2double(get(h.pfr1,'string'));
        p2=str2double(get(h.pfr2,'string'));
        set([h.axes.ax],'xlim',[p1 p2],'ylimmode','auto');
        set([h.axes.ax],'ylimmode','auto');
        lines=get([h.axes.ax],'Children'); %cell array of lines and error bars for each channel
        %         lines=[ax.Children];
        yvalues=get([lines{:}],'YData');
        yvalues(2:2:end)=[]; %to remove the error bars leaving ns per channel
        pfr=spectra(1).f>p1 & spectra(1).f<p2;
        j9=1;
        
        for j6=1:ns:length(yvalues) %jump by number of spectra
            if ns==1
                ymax=max(yvalues{j6}(pfr));
                ymin=min(yvalues{j6}(pfr));
            elseif ns==2
                ymax=max([yvalues{j6}(pfr) yvalues{j6+1}(pfr)]);
                ymin=min([yvalues{j6}(pfr) yvalues{j6+1}(pfr)]);
            elseif ns==3
                ymax=max([yvalues{j6}(pfr) yvalues{j6+1}(pfr) yvalues{j6+2}(pfr)]);
                ymin=min([yvalues{j6}(pfr) yvalues{j6+1}(pfr) yvalues{j6+2}(pfr)]);
            end
            set(h.axes(j9).ax,'ylim',[ymin ymax]);
            
            set(gca,'ycolor',h.bcolor);
            j9=j9+1;
        end
        %         linkzoom(h.ax);
        
%%        %controls for the figure except plotting frequency range which is above
        %moved down here 4/29 to give it access to h.axes
        h.errorHide=uicontrol('parent',h.fig,'style','pushbutton','units','normalized','position',[0.01 .15 .1 .05],'string','ErrorBars');
        set(h.errorHide,'callback',{@hideError,h});
        
        %turn off the transparency in case want to save figure for illustrator
        h.alphaSwitch=uicontrol('parent',h.fig,'units','normalized',...
            'position',[0.01 0.10 0.1 0.05],'string','alpha for adobe',...
            'callback',{@alphaOffForAdobe,h});
        
        h.showAxes=uicontrol('parent',h.fig,'units','normalized','position',...
            [0.2 0.01 0.1 0.05],'string','y-axis','callback',{@yaxistoggle,h});
     
        
      
        %function to change the plotting frequency ranges
        set(h.pfr1,'Callback',{@changePFR,h});
        set(h.pfr2,'Callback',{@changePFR,h});
        
        
%% call back functions

    function changePFR(hObject,eventdata,h)
        set([h.axes.ax],'xlim',[str2double(get(h.pfr1,'string')) str2double(get(h.pfr2,'string'))]);
    end
        
    function hideError(hObject,eventdata,h)
        if strcmpi(get(h.axes(1).eb(1),'visible'),'on')
            set([h.axes.eb],'Visible','off');
        else
            set([h.axes.eb],'Visible','on');
        end
    end
    
    function alphaOffForAdobe(hObject,event,h) %to turn off alpha for saving to adobe illustrator
    if get(h.axes(1).eb(1),'facealpha')~=1 %if no transparency
                set([h.axes.eb],'linestyle','none','facealpha',1);%for exporting to illustrator
                %need to turn off allow axes to grow somehow
    else %if was opaque and want to switch back
                set([h.axes.eb],'linestyle','none','facealpha',0.2); %to make the fill transparent
    end
    end

    function yaxistoggle(hObject,event,h) %to show or rehide the y-axes
    if sum(get(h.axes(1).ax(1),'ycolor')==h.bcolor)==3%if set to background color so all three colorspec =1
        set([h.axes.ax],'ycolor',[0 0 0]);%make visible and black
    else
        set([h.axes.ax],'ycolor',h.bcolor);
    end
    end
end

