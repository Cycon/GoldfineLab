%text2specgram_demo
% reads text files, uses Chronux routines to calculate spectrorgrams and coherograms
% mtspecgramc for spectrum, cohgramc for coherogram
%
% other differences c/w text2spec_demo:  different defaults, no data
% written, analyzes first 1/3, middle 1/3, end 1/3
%
%   See also:  PHACOLOR.
%
fn=getinp('file name','s',[],'JV_symm.dat');
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
t_swatch=getinp('length of time for each swatch','f',[64*dt,(npts-1)*dt],floor(npts/3)*dt);
npts_swatch=round(t_swatch/dt);
nswatch=floor(npts/npts_swatch); %but we will only analyze first and last swatch, and not trial average
disp(sprintf(' %5.0f swatches, %7.0f points each',nswatch,npts_swatch));
winsize=getinp('window size (sec)','f',[32*dt,floor(npts/2)*dt],256*dt);
npts_win=round(winsize/dt);
winstep=getinp('window step (fraction of window size)','f',[0 1],.5);
winparams=[winsize winsize*winstep];
%
f0=1./winsize;
for iNW=[1 2 3 4 5 7 9]
    disp(sprintf('param to set frequency resolution... NW=%3.0f -> k= %3.0f, freq res = %8.4f',iNW,2*iNW-1,f0*(2*iNW-1)));
end
NW=getinp('NW','d',[1 round(npts_win/4)],7);
%
%de-mean and reshape the data: data_reshaped(time,swatch,channel)
data_reshaped=reshape(data(1:npts_swatch*nswatch,:),npts_swatch,nswatch,2);
for ic=1:size(data_reshaped,3)
    data_reshaped(:,:,ic)=data_reshaped(:,:,ic)-mean(mean(data_reshaped(:,:,ic)));
end
%
cols=['r','b'];
%
figure;
set(gcf,'Position',[100 100 1000 800]);
set(gcf,'Name',cat(2,'time series for ',fn));
set(gcf,'NumberTitle','off');
swatchlist=(sort(unique([1 round(nswatch/2) nswatch])));
for iswatch=swatchlist %plot first and last swatches
    subplot(length(swatchlist),1,find(iswatch==swatchlist));
    plist=[1:npts_swatch]+(iswatch-1)*npts_swatch;
    for ic=1:2
        plot(tvals(plist),data_reshaped(:,iswatch,ic),cat(2,cols(ic),'-'));hold on;
    end
    xlabel('t');
    ht=title(sprintf('%s swatch %4.0f',fn,iswatch));
    set(ht,'Interpreter','none');
    legend('ch 1','ch 2');
    set(gca,'XLim',[tvals(plist(1)),tvals(plist(end))]);
    set(gca,'YLim',[min(data_reshaped(:)),max(data_reshaped(:))])
end
%
params.tapers=[NW NW*2-1];
params.pad=0;
params.Fs=1/dt;
params.err=[2 0.05]; %jackknife error bars
params.trialave=0;
SG=cell(0);
SGerr=cell(0);
flim_plot=0.4/dt;
for ic=1:2
    figure;
    tstring=sprintf('spectrograms for %s ch %2.0f',fn,ic);
    set(gcf,'Position',[100 100 1200 800]);
    set(gcf,'Name',tstring);
    set(gcf,'NumberTitle','off');
    for iswatch=swatchlist
        [SG{ic,iswatch},t,f,SGerr{ic,iswatch}]=mtspecgramc(data_reshaped(:,iswatch,ic),winparams,params);
        subplot(length(swatchlist),1,find(iswatch==swatchlist));
        t_start=tvals(1+(iswatch-1)*npts_swatch);
        imagesc(t+t_start,f,log10(SG{ic,iswatch})',[-7 +1]);colorbar;set(gca,'YDir','normal');
        title(cat(2,'log ',tstring,sprintf(' swatch %2.0f',iswatch)),'Interpreter','none');
        xlabel('t')
        ylabel('f');
        set(gca,'XLim',[min(t) max(t)]+t_start);
        set(gca,'YLim',[0 flim_plot]);
    end
end
C=cell(0);
phi=cell(0);
phistd=cell(0);
Cerr=cell(0);
%[C,phi,S12,S1,S2,t,f,confC,phistd,Cerr]=cohgramc(data1,data2,movingwin,params)
figure;
tstring=sprintf('coherograms for %s',fn);
set(gcf,'Position',[100 100 1200 800]);
set(gcf,'Name',tstring);
set(gcf,'NumberTitle','off');
%calculate and plot coherograms
for iswatch=swatchlist
    [C{iswatch},phi{iswatch},S12,S1,S2,t,f,confC,phistd{iswatch},Cerr{iswatch}]=...
        cohgramc(data_reshaped(:,iswatch,1),data_reshaped(:,iswatch,2),winparams,params);
    subplot(length(swatchlist),1,find(iswatch==swatchlist));
    t_start=tvals(1+(iswatch-1)*npts_swatch);
    imagesc(t+t_start,f,C{iswatch}',[0 1]);colorbar;set(gca,'YDir','normal');
    title(cat(2,tstring,sprintf(' swatch %2.0f',iswatch)),'Interpreter','none');
    xlabel('t')
    ylabel('f');
    set(gca,'XLim',[min(t) max(t)]+t_start);
    set(gca,'YLim',[0 flim_plot]);
end
figure;
tstring=sprintf('phase (/2pi) of coherograms for %s',fn);
set(gcf,'Position',[100 100 1200 800]);
set(gcf,'Name',tstring);
set(gcf,'NumberTitle','off');
%plot phase
for iswatch=swatchlist
    subplot(length(swatchlist),1,find(iswatch==swatchlist));
    t_start=tvals(1+(iswatch-1)*npts_swatch);
    imagesc(t+t_start,f,phi{iswatch}'/(2*pi),[-.5 .5]);colorbar;set(gca,'YDir','normal');
    colormap(phacolor(size(colormap,1))); %set up color map for phase
    title(cat(2,tstring,sprintf(' swatch %2.0f',iswatch)),'Interpreter','none');
    xlabel('t')
    ylabel('f');
    set(gca,'XLim',[min(t) max(t)]+t_start);
    set(gca,'YLim',[0 flim_plot]);
end
  
