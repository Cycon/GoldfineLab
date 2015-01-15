function headplotEeglabSpectra

%To plot spectra of outputs of PSeeglab with the axes over where the
%channel is on the head. Seems to work better if figure is only
%half of the screen horizontally so it is more like the shape of a head and
%helps to squish peaks up a bit.
%
%[] Later on add in option for two figures and for TGT results, though
%summary figure works well obviously for this.
%[] Add option to hide the edge channels and replot everything bigger
%[] Add button to hide titles
%[] Add option to turn off edge electrodes and possibly some squished in
%ones (manually typed in list of electrodes to hide I guess) and
%then do it (but note it needs to be from the beginning since will change
%the x and y max and can use bigger electrode sides)
%[] consider option to auto run the topoplotDiffMap
%Written 1/12/12 AMG
%version 2 4/29/12 clean up and option to remove edge channels
%5/30/12 increase size if edge suppressed
%5/30/12 version 3 - made button for saveas eps for illustrator which turns
%off allowaxestogrow and makes error bars have no facealpha
%7/6/12 removed call to eegp_defopts_eeglablocsAndy since asymmetric
%12/10/12 updated to allow to use an EGI dataset with all channels
%displayed. Also put an option to show only the 1020 system in the EGI by default. [] Also need to add
%option in the control window to change the size of the plots.
%4/16/13 make spectra bigger if <25 channels

%%
PSfile=uipickfiles('type',{'*PS.mat','spectra from PSeeglab'},'prompt','Pick 1, 2 or 3 spectra (Order matters)');
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
% dh.opts=eegp_defopts_eeglablocsAndy;% ensures usage of newer channel
% location file. Removed since uses an inaccurate location list. better to
% use the default, though FC5 and FC6 are wrong and won't work for EGI
if strcmpi(dh.spectra(1).ChannelList{1},'E1')%if an EGI file
    dh.cv=pop_readlocs('GSN-HydroCel-129.sfp');
    dh.cv=dh.cv(4:end);%because first 3 aren't used apparently.
    %     eegpopts='EGI129';
else
    dh.cv=eegp_makechanlocs(char(dh.spectra(1).ChannelList));
end

%remove channels not on the head (location are NaN).
off=isnan([dh.cv.X]);
for j3=1:ns
    dh.spectra(j3).S(:,off)=[];
    dh.spectra(j3).Serr(:,:,off)=[];
    dh.spectra(j3).ChannelList(off)=[];
end
dh.cv(off)=[];

h.fig=figure;
% h.axes=[];


%%
%set up figure with the frequency ranges and a replot button. Consider a
%slider as well to move through. Code for button will need to access the
%range or the slider will do the same thing.
h.cfig=figure;%for the control figure so can more easily modify the graph figure
set(h.cfig,'position',[18   687   128   120]);
h.pfr1=uicontrol('parent',h.cfig,'style','edit','units','normalized','position',[0.1 .75 .2 .2],'string','0');
h.pfr2=uicontrol('parent',h.cfig,'style','edit','units','normalized','position',[0.6 .75 .2 .2],'string','40');
h.plot=uicontrol('parent',h.cfig,'style','pushbutton','units','normalized','position',[0.1 .6 .8 .2],'string','plot');
uicontrol('parent',h.cfig,'style','text','units','normalized','position',[0.1 0.4,0.7 0.15],'string','Suppress edge: ');
h.edge=uicontrol('parent',h.cfig,'style','checkbox','units','normalized','position',[0.4 0.2 0.2 0.2],'value',0);
uicontrol('parent',h.cfig,'style','text','units','normalized','position',[0.1 0.1,0.6 0.15],'string','For adobe: ');
h.adobe=uicontrol('parent',h.cfig,'style','checkbox','units','normalized','position',[0.8 0.1 0.2 0.2],'value',0);
set(h.plot,'callback',{@plotPS,h,ns,dh}); %call backs go in {} if have inputs. important that function has hobject and eventdata first thoug

set(h.fig,'name',figuretitle,'toolbar','figure'); %since ui controls hide it
%%
%Code for pushbutton to plot
    function plotPS(hObject,eventdata,h,ns,dh) %note it sends over h so has access for sure
        
%         %12/10/12 add in subset of EGI channels to use.
%         EGI_1020=[21    23    35    51    70    33    46    58    10   118   105    93    83   116   102    96    11    80    67 129];
%         if strcmpi(dh.spectra(1).ChannelList{1},'E1')%if an EGI file (assuming 129 electrodes)
%             for j4=1:ns
%             dh.spectra(j4).S=dh.spectra(j4).S(:,EGI_1020);
%             dh.spectra(j4).Serr=dh.spectra(j4).Serr(:,:,EGI_1020);
%             dh.spectra(j4).ChannelList=dh.spectra(j4).ChannelList(EGI_1020);
%             end
%             dh.cv=dh.cv(EGI_1020);%outside for loop since only runs once.
%         end
%     
        figure(h.fig);
        clf; %(in case already plotted)
        suppEdge=get(h.edge,'value');
        %remove edge electrodes if chosen
        if suppEdge %below based on coherenceDiffMap as of 4/29/12
            hopts.mont_mode='Laplacian';%use hopts since use opts below
            hopts.Laplacian_type='HjorthAbsRescaled';
            hopts.Laplacian_nbrs_interior=5;%so more lines filled in
            Hjorth=cofl_xtp_makemont(dh.spectra(1).ChannelList',[],hopts);
            
            edgeInd=sum(Hjorth<0,2)==3;%gives the indices of the edge channels
            dh.cv=dh.cv(~edgeInd);%remove the chanlocs of edge channels
            for j4=1:ns
                dh.spectra(j4).S(:,edgeInd)=[];
                dh.spectra(j4).Serr(:,:,edgeInd)=[];
                dh.spectra(j4).ChannelList(edgeInd)=[];
            end
            
        end
        
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
        if suppEdge
            figsize=[0.1 0.07];
%             figsize=[0.03 0.03];
        else
            if length(dh.cv)<25 %added 4/16/13 so that if fewer channels, make them bigger (might want different code for lots of 
                %electrodes, or just remove many of them)
                figsize=[0.15 0.09];
            else
                figsize=[0.07 0.07];%size of the the axis on the figure
%             figsize=[0.03 0.03];
            end
        end
        
        colorlist={'r','b','g'};
        for kk=1:length(dh.cv)
            h.axes(kk).ax=axes('units','normalized','position',[ynew(kk)/maxy*m+aLC(1) xnew(kk)/maxx*m+aLC(2) figsize]);
            hold on;
            %took out CIplot 1/17 since hard to hide error bars otherwise
            for j8=1:ns
                h.axes(kk).eb(j8)=fill([dh.spectra(j8).f fliplr(dh.spectra(j8).f)],[10*log10(squeeze(dh.spectra(j8).Serr(1,:,kk))) fliplr(10*log10(squeeze(dh.spectra(j8).Serr(2,:,kk))))],colorlist{j8});
                plot(dh.spectra(j8).f,10*log10(squeeze(dh.spectra(j8).S(:,kk))),colorlist{j8},'LineWidth',2);
                axis tight;
                grid on; %this turns grid on
                %  grid off; %JUNE 30 FOR MARY
                hold('all'); %this is for the xticks and grid to stay on
            end
            
            if adobeExp
                set([h.axes.eb],'linestyle','none');%for exporting to illustrator
            else
                set([h.axes.eb],'linestyle','none','facealpha',0.2); %to make the fill transparent
            end
            
            %     %CIplotPS wants one channel from one or multiple trials
            %     if ns==1
            %         [h.lines(kk)=CIplotPS(spectra(1).f,squeeze(spectra(1).S(:,kk)),squeeze(spectra(1).Serr(:,:,kk)));
            %     elseif ns==2
            %         h.lh(kk)=CIplotPS(spectra(1).f,spectra(1).S(:,kk),spectra(1).Serr(:,:,kk),spectra(2).S(:,kk),spectra(2).Serr(:,:,kk));
            %     elseif ns==3
            %         h.lines(kk).lh=CIplotPS(spectra(1).f,spectra(1).S(:,kk),spectra(1).Serr(:,:,kk),spectra(2).S(:,kk),spectra(2).Serr(:,:,kk),spectra(3).S(:,kk),spectra(3).Serr(:,:,kk));
            %     end
            h.t(kk)=title(dh.spectra(1).ChannelList{kk});
            set(gca,'yticklabel',[],'ytick',[]);
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
        pfr=dh.spectra(1).f>p1 & dh.spectra(1).f<p2;
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
            set(gca,'yticklabel',[],'ytick',[]);
            j9=j9+1;
        end
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

