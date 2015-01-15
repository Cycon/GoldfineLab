function headplotEeglabCoh

%To plot spectra of outputs of Coheeglab with the axes over where the
%channel is on the head. Seems to work better if figure is only
%half of the screen horizontally so it is more like the shape of a head and
%helps to squish peaks up a bit.
%
%here, plot location based on the first one in the list since the second
%will always be the same. Only allow all versus one.
%
%5/30/12 based on headplotEeglabSpectra
%7/6/12 removed call to eegp_defopts_eeglablocsAndy since asymmetric

%%
PSfile=uipickfiles('type',{'*Coh.mat','coherence from Coheeglab'},'prompt','Pick 1, 2 or 3 spectra (Order matters)');
if isempty(PSfile) || isnumeric(PSfile) %two options in case press cancel or done with no selection
    return;
end
ns=length(PSfile);%number of spectra to plot
for j5=1:ns
    [PSfilepath{j5} PSfilename{j5}]=fileparts(PSfile{j5});
end


figuretitle=input('Figure title (or return to use .mat file name)','s');
if isempty(figuretitle)
    if ns==1
        figuretitle=PSfilename{1};
    elseif ns==2
        figuretitle=[PSfilename{1} ' vs. ' PSfilename{2}];
    elseif ns==3
        figuretitle=[PSfilename{1} ' vs. ' PSfilename{2} 'vs' PSfilename{3}];
    end
end

for j1=1:ns
    dh.spectra(j1)=load(PSfile{j1});
end

%later consider adding in check to ensure all are same number of channels,
%etc.

%%
%create the axes and their handles and plot the data from 1 to max. Then code
%below will just change the xlims.
% dh.opts=eegp_defopts_eeglablocsAndy;% ensures usage of newer channel location file. removed 7/6/12 since asymmetric
dh.cv=eegp_makechanlocs(char(dh.spectra(1).ChannelList));

%want to be able to plot coherence with accelerometer so only want to
%remove when the first element is the accelerometer

%remove channels not on the head (location are NaN).
dh.off=zeros(1,length(dh.cv));%initialize
dh.off(isnan([dh.cv.X]))=1;%logical index of channels that aren't on the head.
% for j3=1:ns
%     dh.spectra(j3).S(:,off)=[];
%     dh.spectra(j3).Serr(:,:,off)=[];
%     dh.spectra(j3).ChannelList(off)=[];
% end
dh.off=logical(dh.off);%above code turned it into a vector that's not a logical
dh.cv(dh.off)=[];%remove the chanlocs variables containing accelerometers since won't plot them on headmap

h.fig=figure;
% h.axes=[];

%[] next need to make a control figure listing all the channels
%[] then select a channel and have it plot on the main figure

%%
%set up figure with the frequency ranges and a replot button. Consider a
%slider as well to move through. Code for button will need to access the
%range or the slider will do the same thing.
h.cfig=figure;%for the control figure so can more easily modify the graph figure
set(h.cfig,'position',[18   428   160   379]);
h.pfr1=uicontrol('parent',h.cfig,'style','edit','units','normalized','position',[0.1 .9 .2 .1],'string','0');
h.pfr2=uicontrol('parent',h.cfig,'style','edit','units','normalized','position',[0.6 .9 .2 .1],'string','40');
h.plot=uicontrol('parent',h.cfig,'style','pushbutton','units','normalized','position',[0.1 .8 .6 .1],'string','plot');
uicontrol('parent',h.cfig,'style','text','units','normalized','position',[0.1 0.75,0.6 0.05],'string','Suppress edge: ');
h.edge=uicontrol('parent',h.cfig,'style','checkbox','units','normalized','position',[0.8 0.73 0.1 0.1],'value',0);
uicontrol('parent',h.cfig,'style','text','units','normalized','position',[0.1 0.7,0.5 0.05],'string','For adobe: ');
h.adobe=uicontrol('parent',h.cfig,'style','checkbox','units','normalized','position',[0.8 0.68 0.1 0.1],'value',0);
h.listbox=uicontrol('parent',h.cfig,'style','listbox','string',dh.spectra(1).ChannelList,'Max',1,'Value',1,...
    'units','normalize','position',[0.1 0.1 0.3 0.6]);%set to only be able to choose one
set(h.plot,'callback',{@plotPS,h,ns,dh}); %call backs go in {} if have inputs. important that function has hobject and eventdata first thoug

set(h.fig,'name',figuretitle,'toolbar','figure'); %since ui controls hide it
%%
%Code for pushbutton to plot
    function plotPS(hObject,eventdata,h,ns,dh) %note it sends over h so has access for sure
        figure(h.fig);
        clf; %(in case already plotted)
        set(gcf,'Name',dh.spectra(1).ChannelList{get(h.listbox,'Value')});
        %[] add in edge suppression later but will need to ensure ignoring
        %accelerometer if accelerometer not chosen
        suppEdge=get(h.edge,'value');
        %remove edge electrodes if chosen
        if suppEdge %below based on coherenceDiffMap as of 4/29/12
            hopts.mont_mode='Laplacian';%use hopts since use opts below
            hopts.Laplacian_type='HjorthAbsRescaled';
            hopts.Laplacian_nbrs_interior=5;%so more lines filled in
            Hjorth=cofl_xtp_makemont(dh.spectra(1).ChannelList(~dh.off)',[],hopts,dh.opts);%ignore channels not on the head with ~dh.off
            
            edgeInd=sum(Hjorth<0,2)==3;%gives the indices of the edge channels
             dh.cv=dh.cv(~edgeInd);%remove the chanlocs of edge channels so won't be used in putting axes in the right place
        end%actually remove the data later on
% %             for j4=1:ns
% %                 dh.spectra(j4).S(:,edgeInd)=[];
% %                 dh.spectra(j4).Serr(:,:,edgeInd)=[];
% %                 dh.spectra(j4).ChannelList(edgeInd)=[];
% %             end
%             
%         end
        
        adobeExp=get(h.adobe,'Value');%determine if want to export to eps to illustrator
        
        %%
        %do the primary plotting (this was originally done above)
        %calculate the angle (theta) between all points and the center (Cz)
        for jj=1:length(dh.cv)
            dh.cv(jj).th=atan2(dh.cv(jj).Y,dh.cv(jj).X);
        end
        
        %determine the central channel
        cc=dh.cv(strcmpi({dh.cv.labels},'Cz'));
        
        %calculate the spherical arc length between all points and the center
        for j=1:length(dh.cv)
            d(j) = atan2(norm(cross([dh.cv(j).X dh.cv(j).Y dh.cv(j).Z],[cc.X cc.Y cc.Z])),dot([dh.cv(j).X dh.cv(j).Y dh.cv(j).Z],[cc.X cc.Y cc.Z]));
        end
        
        %calculate new x and y locations using the spherical arc length as the
        %radius. These are vectors for all channels.
        xnew=d.*cos([dh.cv.th]);
        ynew=d.*sin([dh.cv.th]);
        
        %plot the axes by using the radius. Normalize the radii by the maximum one
        %and then make it a little smaller to ensure it stays on the figure (m)
        maxy=max(abs(ynew));
        maxx=max(abs(xnew));
        m=.4;%factor to decrease the total spread (.4 not .8 since center is 0.5 0.5)
        aLC=[0.5-.01 0.5-.01]; %axes location change
%         if suppEdge
%             figsize=[0.1 0.07];
%         else
            figsize=[0.07 0.07];%size of the the axis on the figure
%         end

%decide which coherences to plot and remove those not on the head. Strategy
%is to create the index of channels to remove / keep first (called
%cohToPlot) and then later remove it. Safer than removing some at a time.

            cohToPlot=zeros(length(dh.spectra(1).combinations),1);%initialize
            cohToPlot(dh.spectra(1).combinations(:,1)==get(h.listbox,'value'))=1;%the ones to plot in left column
            cohToPlot(dh.spectra(1).combinations(:,2)==get(h.listbox,'value'))=1;%the ones to plot in right column
            chIndToRemove=find(dh.off);%indices to remove of channels not on the head (like accelerometer channels)
            for ctp=1:sum(dh.off) %for each channel to remove
                cohToPlot(dh.spectra(1).combinations(:,1)==chIndToRemove(ctp))=0;%remove ones not on head
            end
            if suppEdge
                edgeChToRemove=find(edgeInd);%find the channel numbers to remove
                for eii=1:sum(edgeInd)%for each edgeChannelToRemove
                    cohToPlot(dh.spectra(1).combinations(:,1)==edgeChToRemove(eii))=0;
                end
            end
            
            
            cohToPlot=logical(cohToPlot);
            if sum(cohToPlot)==0 %if no channels left
                disp('No channels to plot. Possible that selection is an edge channel');
                return
            end
            for aaa=1:ns
                dh.spectra(aaa).Cerr=dh.spectra(aaa).Cerr(cohToPlot);
                dh.spectra(aaa).C=dh.spectra(aaa).C(cohToPlot);
            end
            

        colorlist={'r','b','g'};
        for kk=1:length(dh.cv)%for each channel since already removed those not on head
            h.axes(kk).ax=axes('units','normalized','position',[ynew(kk)/maxy*m+aLC(1) xnew(kk)/maxx*m+aLC(2) figsize]);
            hold on;
            
            
            %took out CIplot 1/17 since hard to hide error bars otherwise
            for j8=1:ns
                h.axes(kk).eb(j8)=fill([dh.spectra(j8).f fliplr(dh.spectra(j8).f)],[dh.spectra(j8).Cerr{kk}(1,:) fliplr(dh.spectra(j8).Cerr{kk}(2,:))],colorlist{j8});
                hold on;
                plot(dh.spectra(j8).f,squeeze(dh.spectra(j8).C{kk}(:)),colorlist{j8},'LineWidth',2);
                axis tight;
                grid off; %this turns grid on
                %  grid off; %JUNE 30 FOR MARY
                hold('all'); %this is for the xticks and grid to stay on
            end
            
            if adobeExp
                set([h.axes.eb],'linestyle','none');%for exporting to illustrator
            else
                set([h.axes.eb],'linestyle','none','facealpha',0.2); %to make the fill transparent
            end
            
          
            h.t(kk)=title(dh.cv(kk).labels);
%              set(gca,'yticklabel',[],'ytick',[]);
            set(gca,'ylim',[0 1]);
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
        set([h.axes.ax],'xlim',[p1 p2]);
%         set([h.axes.ax],'ylimmode','auto');%not for coherence since want
%         ylim always 0 to 1 likely
%         lines=get([h.axes.ax],'Children'); %cell array of lines and error bars for each channel
%         %         lines=[ax.Children];
%         yvalues=get([lines{:}],'YData');
%         yvalues(2:2:end)=[]; %to remove the error bars leaving ns per channel
%         pfr=dh.spectra(1).f>p1 & dh.spectra(1).f<p2;
%         j9=1;
%         for j6=1:ns:length(yvalues) %jump by number of spectra
%             if ns==1
%                 ymax=max(yvalues{j6}(pfr));
%                 ymin=min(yvalues{j6}(pfr));
%             elseif ns==2
%                 ymax=max([yvalues{j6}(pfr) yvalues{j6+1}(pfr)]);
%                 ymin=min([yvalues{j6}(pfr) yvalues{j6+1}(pfr)]);
%             elseif ns==3
%                 ymax=max([yvalues{j6}(pfr) yvalues{j6+1}(pfr) yvalues{j6+2}(pfr)]);
%                 ymin=min([yvalues{j6}(pfr) yvalues{j6+1}(pfr) yvalues{j6+2}(pfr)]);
%             end
%             set(h.axes(j9).ax,'ylim',[ymin ymax]);
%             set(gca,'yticklabel',[],'ytick',[]);
%             j9=j9+1;
%         end
        %         linkzoom(h.ax);
        
        %moved down here 4/29 to give it access to h.axes
        h.errorHide=uicontrol('parent',h.fig,'style','pushbutton','units','normalized','position',[0.01 .15 .1 .05],'string','ErrorBars');
        set(h.errorHide,'callback',{@hideError,h});
        if ~adobeExp
            allowaxestogrow;
        end
    end

    function hideError(hObject,eventdata,h)
        if strcmpi(get(h.axes(1).eb(1),'visible'),'on')
            set([h.axes.eb],'Visible','off');
        else
            set([h.axes.eb],'Visible','on');
        end
    end

end

