% coh_demo
% creates examples of time series with relatively narrow spectra (near "alpha") and with 
% different levels of coherence; adapted from surr_test.m
%
coh_list=[0.1 0.5 0.9];
nexamps=1;
dt=0.01;
npts=2000;
%
f=[0:1:ceil(1./(2*dt))];
fctr=10.;
fsig=0.7;
pwr=1+20.*exp(-(f-fctr).^2/(2*fsig^2));
pwr=pwr./(1+f./(2*fctr)).^4;
if (0==0); %for compatibility
    tX_surr=cell(0);
    SX_surr=cell(0);
    fX_surr=cell(0);
    zX_surr=cell(0);
    ouX=cell(0);
    for iset=1:length(coh_list)
        %
        tstring=sprintf('coh %6.2f: npts %6.0f dt %7.4f',coh_list(iset),npts,dt);
        disp(tstring);
        figure;
        set(gcf,'Name',tstring);
        set(gcf,'NumberTitle','off');
        set(gcf,'Position',[100 100 1200 900]);
        S1=pwr;
        S2=pwr;
        S12=pwr*coh_list(iset);
        [tX_surr{iset},SX_surr{iset},fX_surr{iset},zX_surr{iset},ouX{iset}]=...
            surr_corrgau2(S1,S2,S12,f,dt,npts,nexamps,[]);
        for isub=1:2
            mtparams.tapers=[19 37];
            mtparams.Fs=1/dt;
            mtparams.trialave=2-isub; %trial averqage in first figure, not in second
            [Cemp,phiemp,S12emp,S1emp,S2emp,femp]=coherencyc(squeeze(tX_surr{iset}(:,1,:)),squeeze(tX_surr{iset}(:,2,:)),mtparams);
            %S1 and S2
            for ich=1:2
                subplot(2,3,(isub-1)*4+ich);
                if (ich==1)
                    S=S1;
                    Semp=S1emp;
                end
                if (ich==2)
                    S=S2; 
                    Semp=S2emp;
                end
                semilogy(f,S,'k.'); hold on;
                semilogy(fX_surr{iset},SX_surr{iset}(:,ich,ich),'g-'); hold on;
                set(gca,'XLim',[0 max([max(f), max(fX_surr{iset})])]);
                semilogy(femp,Semp,'r-');
                if (isub==1)
                    if (ich==1) title(tstring,'Interpreter','None'); end
                    legend(sprintf('original ch%1.0f',ich),'planned','empiric')
                end %if (isub)
            end
            %S12
            subplot(2,3,(isub-1)*3+3);
            semilogy(f,abs(S12),'k.'); hold on;
            semilogy(fX_surr{iset},abs(SX_surr{iset}(:,1,2)),'g-'); hold on;
            set(gca,'XLim',[0 max([max(f), max(fX_surr{iset})])]);
            semilogy(femp,abs(S12emp),'r-');
            if (isub==1)
                legend('original S12','planned','empiric')
            end %if (isub)
        end %isub
        figure;
        set(gcf,'NumberTitle','off');
        set(gcf,'Position',[100 100 1200 900]);
        tstring=sprintf('tvals for coh %6.2f: npts %6.0f dt %7.4f',coh_list(iset),npts,dt);
        set(gcf,'Name',tstring);
        ptoplot=[300:700];
        for ic=1:2
            subplot(2,1,ic);
            plot(dt*ptoplot,tX_surr{iset}(ptoplot,ic),'k-');
            title(cat(2,sprintf('ch %2.0f',ic),tstring));
            set(gca,'XLim',dt*[min(ptoplot) max(ptoplot)]);
            set(gca,'YLim',[-1 1]*max(abs(tX_surr{iset}(:))));
        end
    end %iset
end
