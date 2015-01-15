% surr_test
%  tests surr_gau, surr_corrgau2 (and thereby, surr_corrgau)
% requires surr_test.mat, a data file.
%
%   See also: COH_DEMO.
%
d=load('surr_test.mat'); %data from text2spec_demo, ran on JV_WTA with other params defaults
%
npts_list=[10000 40000 40000];
dt_list=[0.01 0.003 0.03];
nexamps=5;
%
if_gau=getinp('1 to test surr_gau','d',[0 1]);
if_corrgau2=getinp('1 to test surr_corrgau2','d',[0 1]);
%
if (if_gau)
    t_surr=cell(0);
    S_surr=cell(0);
    f_surr=cell(0);
    z_surr=cell(0);
    ou=cell(0);
    for iset=1:length(npts_list)
        npts=npts_list(iset);
        dt=dt_list(iset);
        for ich=1:2
            if (ich==1) S=d.S1; end
            if (ich==2) S=d.S2; end
            tstring=sprintf('surr_gau: %s, npts %6.0f dt %7.4f ich %2.0f',d.fn,npts,dt,ich);
            disp(tstring);
            [t_surr{iset,ich},S_surr{iset,ich},f_surr{iset,ich},z_surr{iset,ich},ou{iset,ich}]=...
                surr_gau(S,d.f,dt,npts,nexamps,[]);
            figure;
            set(gcf,'Name',tstring);
            set(gcf,'NumberTitle','off');
            set(gcf,'Position',[100 100 1200 900]);
            for isub=1:2
                subplot(1,2,isub);
                semilogy(d.f,S,'k.'); hold on;
                semilogy(f_surr{iset,ich},S_surr{iset,ich},'g-'); hold on;
                set(gca,'XLim',[0 max([max(d.f), max(f_surr{iset,ich})])]);
                mtparams.tapers=[19 37];
                mtparams.Fs=1/dt;
                mtparams.trialave=2-isub; %trial averqage in first figure, not in second
                [Semp,femp]=mtspectrumc(t_surr{iset,ich},mtparams);
                semilogy(femp,Semp,'r-');
                if (isub==1)
                    title(tstring,'Interpreter','None');
                    legend('original','planned','empiric')
                end %if (isub)
            end %isub
        end %ich
    end %iset
end %if_gau
%
if (if_corrgau2)
    tX_surr=cell(0);
    SX_surr=cell(0);
    fX_surr=cell(0);
    zX_surr=cell(0);
    ouX=cell(0);
    for iset=1:length(npts_list)
        npts=npts_list(iset);
        dt=dt_list(iset);
        %
        tstring=sprintf('surr_corrgau2: %s, npts %6.0f dt %7.4f',d.fn,npts,dt);
        disp(tstring);
        figure;
        set(gcf,'Name',tstring);
        set(gcf,'NumberTitle','off');
        set(gcf,'Position',[100 100 1200 900]);
        [tX_surr{iset},SX_surr{iset},fX_surr{iset},zX_surr{iset},ouX{iset}]=...
            surr_corrgau2(d.S1,d.S2,d.S12,d.f,dt,npts,nexamps,[]);
        for isub=1:2
            mtparams.tapers=[19 37];
            mtparams.Fs=1/dt;
            mtparams.trialave=2-isub; %trial averqage in first figure, not in second
            [Cemp,phiemp,S12emp,S1emp,S2emp,femp]=coherencyc(squeeze(tX_surr{iset}(:,1,:)),squeeze(tX_surr{iset}(:,2,:)),mtparams);
            %S1 and S2
            for ich=1:2
                subplot(2,4,(isub-1)*4+ich);
                if (ich==1)
                    S=d.S1;
                    Semp=S1emp;
                end
                if (ich==2)
                    S=d.S2; 
                    Semp=S2emp;
                end
                semilogy(d.f,S,'k.'); hold on;
                semilogy(fX_surr{iset},SX_surr{iset}(:,ich,ich),'g-'); hold on;
                set(gca,'XLim',[0 max([max(d.f), max(fX_surr{iset})])]);
                semilogy(femp,Semp,'r-');
                if (isub==1)
                    if (ich==1) title(tstring,'Interpreter','None'); end
                    legend(sprintf('original ch%1.0f',ich),'planned','empiric')
                end %if (isub)
            end
            %S12
            subplot(2,4,(isub-1)*4+3);
            semilogy(d.f,abs(d.S12),'k.'); hold on;
            semilogy(fX_surr{iset},abs(SX_surr{iset}(:,1,2)),'g-'); hold on;
            set(gca,'XLim',[0 max([max(d.f), max(fX_surr{iset})])]);
            semilogy(femp,abs(S12emp),'r-');
            if (isub==1)
                legend('original S12','planned','empiric')
            end %if (isub)
            %phase
            subplot(2,4,(isub-1)*4+4);
            plot(d.f,d.phi/(2.*pi),'k.'); hold on;
            plot(fX_surr{iset},phase_reduced(SX_surr{iset}(:,1,2))/(2.*pi),'g-'); hold on;
            semilogy(femp,phase_reduced(S12emp)/(2.*pi),'r-'); hold on;
            set(gca,'XLim',[0 max([max(d.f), max(fX_surr{iset})])]);
            set(gca,'YLim',[-0.5 0.5]);
            if (isub==1)
                legend('phase12/2pi','planned','empiric')
            end %if (isub)
            
        end %isub
    end %iset
end %if_corrgau2



