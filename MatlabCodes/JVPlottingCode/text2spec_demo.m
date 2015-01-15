%text2spec_demo
% reads text files, uses Chronux routines to calculate spectra and cross-spectra
% mtspectrumc for spectrum, coherencyc for coherence
%
fn=getinp('file name','s',[],'JV_symm.dat');
fnout=getinp('output file name','s',[],strrep(fn,'.dat','_spec.dat'));
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
t_swatch=getinp('length of time for each swatch','f',[64*dt,(npts-1)*dt],1024*dt);
npts_swatch=round(t_swatch/dt);
nswatch=floor(npts/npts_swatch);
disp(sprintf(' %5.0f swatches, %7.0f points each',nswatch,npts_swatch));
%
f0=1./(npts_swatch*dt);
for iNW=[1 2 3 5 9 17]
    disp(sprintf('param to set frequency resolution... NW=%3.0f -> k= %3.0f, freq res = %8.4f',iNW,2*iNW-1,f0*(2*iNW-1)));
end
NW=getinp('NW','d',[1 round(npts_swatch/4)],3);
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
for iswatch=[1 nswatch] %plot first and last swatches
    subplot(2,1,find(iswatch==[1 nswatch]));
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
figure;
set(gcf,'Position',[100 100 1200 800]);
set(gcf,'Name',cat(2,'spectra for ',fn));
set(gcf,'NumberTitle','off');
%
%calcluate the tapers
params.tapers=dpsschk([NW NW*2-1],npts_swatch,f0); %avoid recalculation; otherwise use params.tapers=[NW 2*NW-1];
params.pad=0;
params.Fs=1/dt;
params.err=[2 0.05]; %jackknife error bars
params.trialave=1;
S=cell(0);
Serr=cell(0);
flim_plot=0.4/dt;
for ic=1:2
    [S{ic},f,Serr{ic}]=mtspectrumc(data_reshaped(:,:,ic),params);
    subplot(2,3,ic);
    semilogy(f,S{ic},'k-');
    xlabel('f (Hz)');
    ylabel(sprintf('pwr, %s ch %1.0f',fn,ic),'Interpreter','none');
    set(gca,'XLim',[0 flim_plot]);
    set(gca,'YLim',[10^-8 10^-1]);
%
    subplot(2,3,3);
    semilogy(f,S{ic},cat(2,cols(ic),'-')); hold on;
    xlabel('f (Hz)');
    ylabel(sprintf('pwr %s',fn),'Interpreter','none');
    set(gca,'XLim',[0 flim_plot]);
    set(gca,'YLim',[10^-8 10^-1]);

end
%calculate cross-spec and coherence
[C,phi,S12,S1,S2,f,confC,phistd,Cerr]=coherencyc(data_reshaped(:,:,1),data_reshaped(:,:,2),params);
%
semilogy(f,abs(S12),'k-');
legend('ch 1','ch 2','amp(cross-spec)');
%
subplot(2,3,4);
plot(f,C,'k-');
xlabel('f (Hz)');
ylabel(sprintf('Coherence, %s',fn),'Interpreter','none');
set(gca,'YLim',[0 1]);
set(gca,'XLim',[0 flim_plot]);
%
subplot(2,3,6);
plot(f,phi/(2*pi),'k.'); hold on;
xlabel('f (Hz)');
ylabel(sprintf('phi/(2pi), %s ch %1.0f',fn),'Interpreter','none');
set(gca,'YLim',[-0.75 0.75]);
set(gca,'XLim',[0 flim_plot]);
%
fid=fopen(fnout,'w');
fprintf(fid,'%8.3g    %12.8g %12.8g %12.8g    %12.8g %12.8g %12.8g    %12.8g %12.8g %12.8g     %12.8g %12.8g \n',...
    [f; S{1}'; Serr{1}; S{2}'; Serr{2};C'; Cerr; phi'; phistd']);
fclose(fid);
