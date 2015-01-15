%parse_specgram_demo
% reads text files, uses Chronux routines to calculate spectrorgrams and coherograms
% and attempt to parse them into state.
%
% c/w text2specgram_demo:  tries lots of params for spectral estimation, does pca
% but does not do error bars.  Defaults to a single epoch, JV_switch.dat;
% plots up to Nyquist (no flim_plot); window overlap=1
%
%  may need to add tests of significance
%
% mtspecgramc for spectrum, cohgramc for coherogram
%
%   See also:  PHACOLOR, SURR_CORRGAU2, TEXT2SPECGRAM_DEMO.
%
min_pwr=10^-10; %minimum nonzero power
nchans=2;
color_list=['r','g','b','m']; %for traces and histos
font_size=6;
nrows=6;
ncols=2;
%
fn=getinp('file name','s',[],'JV_switch.dat');
fid=fopen(fn,'r');
fdata=fscanf(fid,'%f %f %f');
fdata=reshape(fdata,3,length(fdata)/3)';
fclose(fid);
%
%check time list
npts=size(fdata,1);
tvals=fdata(:,1);
data=fdata(:,[2 3]);
dt=(tvals(end)-tvals(1))/(npts-1);
dterr=max(dt-abs(tvals(2:end)-tvals(1:end-1)));
disp(sprintf(' %8.0f data points, dt=%8.4f sec (tol=%8.4f) from t=%8.4f to %8.4f',...
    npts,dt,dterr,tvals(1),tvals(end)));
%
%establish segment length and frequency resolution
t_swatch=getinp('length of time for each swatch','f',[64*dt,npts*dt],npts*dt);
npts_swatch=round(t_swatch/dt);
nswatch=floor(npts/npts_swatch); %but we will only analyze first and last swatch, and not trial average
swatchlist=(sort(unique([1 round(nswatch/2) nswatch])));
disp(sprintf(' %5.0f swatches, %7.0f points each',nswatch,npts_swatch));
winsize_list=getinp('window size (sec), one or more values','f',[32*dt,floor(npts/2)*dt],128*dt);
winstep_list=getinp('window step (fraction of window size), one or more values','f',[0 1],1);
%
f0min=1/max(winsize_list);
f0max=1/min(winsize_list);
for iNW=[1 2 3 4 5 7 9]
    disp(sprintf('param to set frequency resolution... NW=%3.0f -> k= %3.0f, freq res = %8.4f to %8.4f',iNW,2*iNW-1,[f0min f0max]*(2*iNW-1)));
end
NW_list=getinp('NW (one or more, a value of 1 forces abs(C)=1 and therefore useless)','d',[1 min(round(winsize_list/dt/4))],2);
%
pca_submean=getinp('1 to subtract mean before calculating PC''s','d',[0 1],1);
pca_maxfreq=getinp('maximum frequency to use in PC calculations','f',[0 0.5/dt],0.4/dt);
pca_minfreq=getinp('minimum frequency to use in PC calculations','f',[0 pca_maxfreq],0);
pca_ntoplot=getinp('number of PC''s to plot','d',[1 4],3); %number of pc's to plot
%
ifsurr=getinp('1 to create and use surrogate data','d',[0 1],0);
if (ifsurr)
    %create surrogate data from data, taken as one swatch
    %subtract mean from each channel
    for ic=1:nchans
        data_demean(:,ic)=data(:,ic)-mean(data(:,ic));
    end
    disp('creating surrogate dataset');
    params.tapers=[NW_list(end) NW_list(end)*2-1];
    params.pad=0;
    params.Fs=1/dt;
    params.err=[1 .05];
    winparams=[winsize_list(end) winsize_list(end)];
    [C,phi,S12,S1,S2,t,f]=cohgramc(data_demean(:,1),data_demean(:,2),winparams,params);
    data_surr=surr_corrgau2(mean(S1),mean(S2),mean(S12),f,dt,npts*2);
    data_use=data_surr(round(npts/2)+[1:npts],:);
    fn_aug=cat(2,fn,' surr');
else
    data_use=data;
    fn_aug=fn;
end
%
for NW_ptr=1:length(NW_list)
    NW=NW_list(NW_ptr);
    for winsize_ptr=1:length(winsize_list)
        winsize=winsize_list(winsize_ptr);
        for winstep_ptr=1:length(winstep_list)
            winstep=winstep_list(winstep_ptr);
            npts_win=round(winsize/dt);
            winparams=[winsize winsize*winstep];
            f0=1./winsize;
            df=f0*(2*NW-1);
            pstring_p=sprintf('dt%5.1f df%4.2f NW%3.0f step %4.2f',winsize,df,NW,winstep);
            disp(pstring_p);
            %
            params.tapers=[NW NW*2-1];
            params.pad=0;
            params.Fs=1/dt;
            params.err=[0 .05]; %no error bars calculated
            params.trialave=0;
            %
            %reshape data array to (time points, trials, channel)
            data_reshaped=reshape(data_use(1:npts_swatch*nswatch,:),npts_swatch,nswatch,nchans);
            %subtract mean from each channel
            for ic=1:nchans
                data_reshaped(:,:,ic)=data_reshaped(:,:,ic)-mean(mean(data_reshaped(:,:,ic)));
            end
            %calculate spectra across all swatches, to get a uniform maximum
            SG=[];
            for iswatch=swatchlist
                for ic=1:size(data_reshaped,3)
                    [SG(:,:,ic,iswatch),t,f]=mtspecgramc(data_reshaped(:,iswatch,ic),winparams,params);
                end
            end
            SGrange=[floor(min(log10(max(SG(:),min_pwr)))) ceil(max(log10(SG(:))))];
            for iswatch=swatchlist
                plist=[1:npts_swatch]+(iswatch-1)*npts_swatch;
                pstring_d=sprintf('%s sw%3.0f',fn_aug,iswatch);
                tstring=cat(2,pstring_d,': ',pstring_p);
                %
                %calclate the coherograms and cross-spectrogram
                %
                [C,phi,S12,S1,S2]=cohgramc(data_reshaped(:,iswatch,1),data_reshaped(:,iswatch,2),winparams,params);
                %
                %now do some PCA for the right column(s)
                %
                pca_datatypes=12; %number of kinds of pca analysis
                u=cell(1,pca_datatypes);
                s=cell(1,pca_datatypes);
                v=cell(1,pca_datatypes);
                for ipca=1:pca_datatypes
                    fsample=[NW:(2*NW-1):length(f)];
                    fsample=intersect(intersect(fsample,find(f<=pca_maxfreq)),find(f>=pca_minfreq)); %restrict frequencies if requested
                    pca_subsets=cell(0);
                    %
                    %begin the plots
                    %
                    figure;
                    set(gcf,'Position',[50 50 1400 900]);
                    set(gcf,'Name',tstring);
                    set(gcf,'NumberTitle','off');
                    %
                    %plot the raw data
                    %
                    hrawax=subplot(nrows,ncols,1);
                    for ic=1:nchans
                        plot(tvals(plist),data_reshaped(:,iswatch,ic),cat(2,color_list(ic),'-'));hold on;
                    end
                    xlabel('t (sec)','FontSize',font_size);
                    title(tstring,'Interpreter','none','FontSize',font_size);
                    legend('ch 1','ch 2');
                    set(gca,'XLim',[tvals(plist(1))-dt,tvals(plist(end))]);
                    set(gca,'YLim',[min(data_reshaped(:)),max(data_reshaped(:))])
                    set(gca,'FontSize',font_size);
                    %
                    %plot the spectrograms
                    %
                    for ic=1:nchans
                        subplot(nrows,ncols,1+ncols*ic);
                        t_start=tvals(1+(iswatch-1)*npts_swatch);
                        imagesc(t-dt+t_start,f,(log10(SG(:,:,ic,iswatch)))',SGrange);set(gca,'YDir','normal');
                        hspect=gca;
                        title(sprintf('log spectrogram, ch %1.0f',ic),'FontSize',font_size);
                        %xlabel('t (sec)','FontSize',font_size)
                        ylabel('f (Hz)','FontSize',font_size);
                        set(gca,'XLim',[tvals(plist(1))-dt,tvals(plist(end))]);
                        set(gca,'YLim',[0 max(f)]);
                        set(gca,'CLim',get(gca,'CLim')*[1 -0.1;0 1.1]); %make sure that last 10% of color range is not used so phacol can be used
                        hc=colorbar;set(hc,'YLim',get(hc,'YLim')*[1 0.1;0 0.9]);
                        set(gca,'FontSize',font_size);
                    end
                    set(hrawax,'Position',get(hrawax,'Position').*[0 1 0 1]+get(hspect,'Position').*[1 0 1 0]); %adjust x-axis fo raw traces
                    %
                    %plot cross-spectrogram
                    %
                    subplot(nrows,ncols,1+ncols*(nchans+1));
                    imagesc(t-dt+t_start,f,log10(max(abs(S12'),min_pwr)),SGrange);set(gca,'YDir','normal');
                    title('log cross-spectrogram amplitude','FontSize',font_size);
                    %xlabel('t (sec)','FontSize',font_size)
                    ylabel('f (Hz)','FontSize',font_size);
                    set(gca,'XLim',[tvals(plist(1))-dt,tvals(plist(end))]);
                    set(gca,'YLim',[0 max(f)]);
                    set(gca,'CLim',get(gca,'CLim')*[1 -0.1;0 1.1]); %make sure that last 10% of color range is not used so phacol can be used
                    hc=colorbar;set(hc,'YLim',get(hc,'YLim')*[1 0.1;0 0.9]);
                    set(gca,'FontSize',font_size);
                    %
                    %plot coherence amplitude
                    %
                    subplot(nrows,ncols,1+ncols*(nchans+2));
                    imagesc(t-dt+t_start,f,C',[0 1]);set(gca,'YDir','normal');
                    title('coherence amplitude','FontSize',font_size);
                    %xlabel('t (sec)','FontSize',font_size)
                    ylabel('f (Hz)','FontSize',font_size);
                    set(gca,'XLim',[tvals(plist(1))-dt,tvals(plist(end))]);
                    set(gca,'YLim',[0 max(f)]);
                    set(gca,'CLim',get(gca,'CLim')*[1 -0.1;0 1.1]); %make sure that last 10% of color range is not used so phacol can be used
                    hc=colorbar;set(hc,'YLim',get(hc,'YLim')*[1 0.1;0 0.9]);
                    set(gca,'FontSize',font_size);
                    %
                    %plot coherence phase
                    %
                    subplot(nrows,ncols,1+ncols*(nchans+3));
                    imagesc(t-dt+t_start,f,phi'/(2*pi),[-0.5 0.5]);set(gca,'YDir','normal');
                    %the color map messes up the others unless the ranges are compressed (see phacolor.m)
                    colormap(phacolor(size(colormap,1))); %set up color map for phase
                    title('coherence phase/(2*pi)','FontSize',font_size);
                    %xlabel('t (sec)','FontSize',font_size)
                    ylabel('f (Hz)','FontSize',font_size);
                    set(gca,'XLim',[tvals(plist(1))-dt,tvals(plist(end))]);
                    set(gca,'YLim',[0 max(f)]);
                    colorbar;
                    set(gca,'FontSize',font_size);
                    %
                    %set up the data for pca
                    %
                    pca_subsets=cell(0);
                    ntimes=size(SG,1);
                    switch ipca
                         case {1,2}
                            x=log10(max(SG(:,fsample,ipca,iswatch),min_pwr));
                            pca_subsets{1}=sprintf('S%1.0f',ipca);
                        case 3
                            x=log10(max(SG(:,fsample,:,iswatch),min_pwr));
                            x=reshape(x,size(x,1),size(x,2)*size(x,3));
                            pca_subsets{1}='S1';
                            pca_subsets{2}='S2';
                        case 11
                            x=C(:,fsample);
                            pca_subsets{1}='Coh';
                        case 12
                            x=atanh(C(:,fsample));
                            pca_subsets{1}='ZCoh';
                        case 4
                            x=log10(max(abs(S12(:,fsample)),min_pwr));
                            pca_subsets{1}='abs(S12)';
                        case 5
                            x=log10(max(SG(:,fsample,:,iswatch),min_pwr));
                            x=reshape(x,size(x,1),size(x,2)*size(x,3));
                            x=[x,log10(max(abs(S12(:,fsample)),min_pwr))];
                            pca_subsets{1}='S1';
                            pca_subsets{2}='S2';
                            pca_subsets{3}='abs(S12)';
                        case {6,7} %normalized, one channel
                            ich=ipca-5;
                            x=SG(:,fsample,ich,iswatch)./repmat(mean(SG(:,fsample,ich,iswatch),1),[ntimes 1]);
                            pca_subsets{1}=sprintf('NormS%1.0f',ich);
                        case {8,9,10} %normalized, both channels, possibly with cross-spectra
                            xn1=mean(SG(:,fsample,1,iswatch),1);
                            xn2=mean(SG(:,fsample,2,iswatch),1);
                            xnx=sqrt(xn1.*xn2);
                            if (ipca==8) | (ipca==10)
                                x1=[SG(:,fsample,1,iswatch)./repmat(xn1,[ntimes 1])];
                                x2=[SG(:,fsample,2,iswatch)./repmat(xn2,[ntimes 1])];
                                pca_subsets{1}='NS1';
                                pca_subsets{2}='NS2';
                                x=[x1,x2];
                            end
                            if (ipca==9) | (ipca==10)
                                xr=real(S12(:,fsample))./repmat(xnx,[ntimes 1]);
                                xi=imag(S12(:,fsample))./repmat(xnx,[ntimes 1]);
                            end
                            if (ipca==9)
                                x=[xr,xi];
                                pca_subsets{1}='reNS12';
                                pca_subsets{2}='imNS12';
                            end
                            if (ipca==10)
                                x=[x1,x2,xr,xi];
                                pca_subsets{3}='reNS12';
                                pca_subsets{4}='imNS12';
                            end
                    end
                    %set up labeling for each range of data used for pca
                    pcalabel=pca_subsets{1};
                    for ip=2:length(pca_subsets)
                        pcalabel=cat(2,pcalabel,' ',pca_subsets{ip});
                    end
                    %subtract mean if requested
                    if (pca_submean==1)
                        x=x-repmat(mean(x,1),size(x,1),1);
                        pcalabel=cat(2,pcalabel,' msub');
                    end
                    %note that size(x,2)=length(fsample)*length(pca_subsets)
                    fvals=repmat(f(fsample),1,length(pca_subsets)); %frequency values 
                    if (size(x,1)<=size(x,2))
                        disp(sprintf(' pca on %20s not done because dim(x)= %4.0f %4.0f',pcalabel,size(x)));
                    else
                        %
                        %do PCA
                        %
                        [u{ipca},s{ipca},v{ipca}]=svd(x,0);
                        %u{ipca}(:,k) contains timecourse of kth principal component
                        %v{ipca}(:,k) contains frequency-dependence of kth principal component
                        ds=diag(s{ipca});
                        ds=ds(1:length(fsample));
                        disp(sprintf(' pca on %20s done.            dim(x)= %4.0f %4.0f',pcalabel,size(x)));
                        %
                        %align PC's so that the frequency-dependence is declining
                        %
                        ifinvert=-sign(fvals*v{ipca});
                        v{ipca}=v{ipca}.*repmat(ifinvert,size(v{ipca},1),1);
                        u{ipca}=u{ipca}.*repmat(ifinvert,size(u{ipca},1),1);
                        %
                        selpos=find(u{ipca}(:,1)>=0);
                        selneg=find(u{ipca}(:,1)<0);
                        %
                        set(gcf,'Name',cat(2,tstring,' ',pcalabel));
                        %
                        %scree plot
                        subplot(nrows,3*ncols,4);
                        semilogy([1:length(fsample)],max(ds,min_pwr)/sum(diag(s{ipca})),'k.-');hold on;
                        title(sprintf('pca on %s',pcalabel),'FontSize',font_size);
                        set(gca,'XLim',[1 length(fsample)]);
                        set(gca,'YLim',[10^-4,1]);
                        set(gca,'FontSize',font_size);
                        %
                        %plot first pca_ntoplot PC's as lines and colormap
                        %
                        subplot(nrows,3*ncols,5);
                        for ip=1:pca_ntoplot
                            plot(-0.5+[1:size(x,2)],v{ipca}(:,ip),cat(2,color_list(ip),'.-'));hold on;
                        end
                        set(gca,'YLim',[-1 1]*max(abs(get(gca,'YLim'))));
                        set(gca,'XLim',[0 size(x,2)]);
                        for ip=2:length(pca_subsets)
                            plot((ip-1)*length(fsample)*[1 1],get(gca,'YLim'),'k-');
                        end
                        set(gca,'XTick',length(fsample)*[1:length(pca_subsets)]);
                        set(gca,'XTickLabel',sprintf('%4.1f',fvals(length(fsample)))); %matlab will repeat the label as needed
                        set(gca,'FontSize',font_size);
                        %
                        subplot(nrows,3*ncols,6);
                        vconsol=v{ipca}(:,[1:pca_ntoplot]); %rearrange v so that strips show each pc, then each subset
                        vconsol=reshape(vconsol,[length(fsample) length(pca_subsets) pca_ntoplot]);
                        vconsol=permute(vconsol,[1 3 2]);
                        vconsol=reshape(vconsol,[length(fsample) pca_ntoplot*length(pca_subsets)]);
                        imagesc(vconsol);;set(gca,'YDir','normal');hold on;
                        set(gca,'CLim',get(gca,'CLim')*[1 -0.1;0 1.1]); %make sure that last 10% of color range is not used so phacol can be used
                        %
                        for ip=2:length(pca_subsets)
                            plot([1 1]*(0.5+(ip-1)*pca_ntoplot),get(gca,'YLim'),'k-');
                        end
                        set(gca,'XTick',0.5+pca_ntoplot*([1:length(pca_subsets)]-0.5));
                        set(gca,'XTickLabel',pca_subsets);
                        colorbar off;
                        set(gca,'FontSize',font_size);
                        %
                        %plot first pca_ntoplot PC's as function of time
                        %
                        pcm=max(max(abs(u{ipca}(:,1:min(3,pca_ntoplot)))));
                        subplot(nrows,ncols,ncols+2);
                        for ip=1:pca_ntoplot
                            plot(t-dt+t_start,pcm*(ip-(pca_ntoplot+1)/2)+u{ipca}(:,ip),cat(2,color_list(ip),'-'));hold on;
                            plot([tvals(plist(1))-dt,tvals(plist(end))],pcm*(ip-(pca_ntoplot+1)/2)*[1 1],'k-');hold on;
                        end
                        xlabel('t (sec)','FontSize',font_size);
                        set(gca,'XLim',[tvals(plist(1))-dt,tvals(plist(end))]);
                        set(gca,'Position',get(gca,'Position').*[1 1 0 1]+get(hspect,'Position').*[0 0 1 0]); %adjust x-axis fo raw traces
                        set(gca,'FontSize',font_size);
                        %
                        % plot histograms of time series of PC's
                        %
                        for ip=1:min(3,pca_ntoplot)
                            subplot(nrows,3*ncols,6*ncols+3+ip);
                            hcounts=hist(u{ipca}(:,ip),pcm*[-0.95:.1:0.95]);
                            hb=bar(pcm*[-0.95:.1:0.95],hcounts,1);
                            set(hb,'FaceColor',color_list(ip));
                            hold on;
                            xlabel(sprintf('pc%1.0f',ip),'FontSize',font_size);
                            set(gca,'XLim',[-pcm pcm]);
                            set(gca,'FontSize',font_size);
                        end
                        %
                        % plot projections into coordinate planes of time series of PC's
                        %
                        ip=0;
                        for ip1=2:min(3,pca_ntoplot)
                            for ip2=1:ip1-1
                                ip=ip+1;
                                subplot(nrows,3*ncols,9*ncols+3+ip);
                                plot(u{ipca}(selpos,ip1),u{ipca}(selpos,ip2),'r.'); hold on;
                                plot(u{ipca}(selneg,ip1),u{ipca}(selneg,ip2),'k.'); hold on;
                                xlabel(sprintf('pc%1.0f',ip1),'FontSize',font_size);
                                ylabel(sprintf('pc%1.0f',ip2),'FontSize',font_size);
                                set(gca,'XLim',[-pcm pcm]);
                                set(gca,'YLim',[-pcm pcm]);
                                axis equal;
                                axis square;
                                set(gca,'FontSize',font_size);
                            end
                        end
                        %
                        % 3d
                        %
                        if (pca_ntoplot>=3)
                            ip1=1;
                            ip2=2;
                            ip3=3;
                            subplot(nrows/2,ncols,(nrows/2-1)*ncols+2);
                            plot3(u{ipca}(selpos,ip1),u{ipca}(selpos,ip2),u{ipca}(selpos,ip3),'r.'); hold on;
                            plot3(u{ipca}(selneg,ip1),u{ipca}(selneg,ip2),u{ipca}(selneg,ip3),'k.'); hold on;
                            xlabel(sprintf('pc%1.0f',ip1),'FontSize',font_size);
                            ylabel(sprintf('pc%1.0f',ip2),'FontSize',font_size);
                            zlabel(sprintf('pc%1.0f',ip3),'FontSize',font_size);
                            set(gca,'XLim',[-pcm pcm]);
                            set(gca,'YLim',[-pcm pcm]);
                            set(gca,'ZLim',[-pcm pcm]);
                            axis equal;
                            axis vis3d;
                            set(gca,'FontSize',font_size);
                        end
                    end
                end %ipca
            end %iswatch
        end %winstep_ptr
    end %winsize_ptr
end %NW_ptr
