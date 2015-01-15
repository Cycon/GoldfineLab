% cofl_anal_demo
%
% further analysis (pca, Hartigan, kurtosis, stats, plotting) on results
% of cofl_xfp_anal
%
% run in cleard workspace after loading results or results{k} from
% cofl_xtp_anal.
%
% if auto is defined, then runs automatically, taking defaults that are not supplied in auto.*
%    auto.filename must be part of auto, since this is used to read in the data
%
% basic plotting routines are modified from parse_specgram_demo
% plots are 10*log10(pwr) [dB scale], rather than log10(pwr), but no raw traces shown
%
% TO DO:
% * look at surrogate routine:  could the matches be better?
%   test dataset 1:  surrogates appear off by a factor; unequal seg test:  appear to be OK
%   note the flat-topped spectra at low freqs for cofl_xtp_demo_test_dataedits.mat
% * option to plot special points at the independent spectral ests (separated by chronux k param)
% * make use of alternative surrogates for quantitites that involve only one
%   electrode of a pair (for statistics and for plotting)
% * modularize the headmap plotting
%
%   See also:  COFL_XTP_DEMO, COFL_XTP_SETDEF, COFL_ANAL_STATS, EEGP_DEFOPTS,
%     COFL_ANAL_AUTO_DEMO, COFL_ANAL_AUTO_DEMOC.
%
if ~exist('auto')
    ifauto=0;
    auto=[];
end
%if there is at least one non-default field, make sure others are filled in
%with sensible defaults
if ~isempty(auto)
    ifauto=1;
    auto=filldefault(auto,'cell_choice',1);
    auto=filldefault(auto,'plot_anal_choice',2);
    auto=filldefault(auto,'filename','');
end
if ~exist('stat_opts')
    stat_opts=[];
end
stat_opts=filldefault(stat_opts,'names',{'skew','kurt','dip'});
stat_opts=filldefault(stat_opts,'Hartigan_boot',100);
if ~exist('eegp_opts')
    eegp_opts=[];
end
eegp_opts=eegp_defopts(eegp_opts);
%
%set up defaults for non-automode
% these headmap params are shared by all modules that draw headmaps
if ~exist('headmap_labels_justthese'); headmap_labels_justthese={}; end %if non-empty, this restricts the locations of labels on headplots
if ~exist('headmap_wires_ondata') headmap_wires_ondata=1; end %to draw wireframe on headmaps with data
if ~exist('headmap_wires_onkey') headmap_wires_onkey=1; end %to draw wireframe on headmaps with key
if ~exist('headmap_narc') headmap_narc=10; end %number of ponts in an arc for the headmap
if ~exist('headmap_colormap') headmap_colormap='jet'; end
if ~exist('headmap_linewidths') headmap_linewidths=[2 3 4 6]; end % line widths corresponding to each significance level
if ~exist('headmap_linewidths_sig') headmap_linewidths_sig=[1 3 3 3]; end % standard line width if significance is only indicated by color
if ~exist('headmap_siglevels') headmap_siglevels=[1 .1 .05 .01]; end %signficicance levels, 1=insig
if ~exist('headmap_sigcolors') headmap_sigcolors=[0 0 0; 1 1 0; 1 0.5 0; 1 0 0]; end %colors for signficance levels, if "discrete color" mode
if ~exist('headmap_view') headmap_view=0; end %can specify azimuth  and elevation instead
if ~exist('headmap_abscissa_frac') headmap_abscissa_frac=0.15; end %fraction of head taken up by abscissa for line plots
if ~exist('headmap_ordinate_frac') headmap_ordinate_frac=0.075; end %fraction of head taken up by abscissa for line plots
if ~exist('headmap_yz') headmap_yz=2; end % 1 to plot ordinate on y axis, 2 on z-axis
%
% these are private to each module
if ~exist('headmap_iffig') headmap_iffig=0; end
if ~exist('headmap_ifps') headmap_ifps=0; end
if ~exist('headmap_infix') headmap_infix=''; end
if ~exist('cohplots_iffig') cohplots_iffig=0; end
if ~exist('cohplots_ifps') cohplots_ifps=0; end
if ~exist('cohplots_infix') cohplots_infix=''; end
if ~exist('bandplots_iffig') bandplots_iffig=0; end
if ~exist('bandplots_ifps') bandplots_ifps=0; end
if ~exist('bandplots_infix') bandplots_infix=''; end
%
plot_anal_choices=cell(0);
plot_anal_choices{1}.desc='show spectrograms, coherograms, PCA, and stats for individual channels and pairs';
plot_anal_choices{1}.desc_short='basic plot and stats for indiv channels and pairs';
plot_anal_choices{1}.pair_list=[]; %need a list of pairs
plot_anal_choices{1}.ipca_list=[];  %need a list of pca modes
plot_anal_choices{1}.surr_list=[]; %need a list of surrogates
%
plot_anal_choices{2}.desc='fluctuations of spectrograms, coherograms via PCA stats, compared with surrogates, on a headmap';
plot_anal_choices{2}.desc_short='fluctuations stats on a headmap';
plot_anal_choices{2}.pair_list=[]; %need a list of pairs
plot_anal_choices{2}.ipca_list=[]; %need a list of pca modes
plot_anal_choices{2}.surr_list=0; %do not need a list of surrogates
%
plot_anal_choices{3}.desc='coherences on a headmap, by band';
plot_anal_choices{3}.desc_short='coherences on a headmap, by band';
plot_anal_choices{3}.pair_list=[]; %need a list of pairs
plot_anal_choices{3}.ipca_list=1; %do not need a list of pca modes
plot_anal_choices{3}.surr_list=0; %do not need a list of surrogates
%
band_stat=[];
band_stat{1}.desc='coherence';
band_stat{1}.ylabel='C';
band_stat{1}.mergetype=1; %1->it is a cross-channel quantity
band_stat{1}.lims=[0 1]; %has absolute limits
band_stat{1}.suff='coh';
%
band_stat{2}.desc='10log10(cross-spectrum) (dB)';
band_stat{2}.ylabel='cross-spec (dB)';
band_stat{2}.mergetype=1; %1->it is a cross-channel quantity
band_stat{2}.lims=[]; %does not have absolute limits
band_stat{2}.suff='xspec';
%
band_stat{3}.desc='10log10(spectrum) (dB)';
band_stat{3}.ylabel='spec (dB)';
band_stat{3}.mergetype=2; %2->it is NOT a cross-channel quantity
band_stat{3}.lims=[]; %does not have absolute limits
band_stat{3}.suff='spec';
%
if ~exist('plot_anal_choice') plot_anal_choice=1; end
%
if ifauto
    filename=auto.filename;
    s=load(filename);
    results=getfield(s,'results');
    clear s;
    if (iscell(results))
        r=results{auto.cell_choice};
    else
        r=results;
    end
else
    if getinp('1 to load results from file','d',[0 1],1-double(exist('r')));
        filename=getinp('file name','s',[ ],'cofl_xtp_demo_test1.mat');
        s=load(filename);
        results=getfield(s,'results');
        clear s
        if iscell (results)
            for k=1:length(results)
                disp(sprintf('set %3.0f  file %s field %s',k,results{k}.filename,results{k}.fieldname));
                disp(sprintf('  %4.0f segs, %4.0f chans recorded, %4.0f chans analyzed, %4.0f surrogates',...
                    results{k}.nsegs,...
                    results{k}.nchans_recorded,results{k}.nchans_analyzed,length(results{k}.cohgram_surrogates)));
            end
            cell_choice=getinp('choice','d',[1 length(results)]);
            r=results{cell_choice};
        else
            r=results;
        end
    end
end
clear results;
%
filebase=strrep(filename,'\','/');
filebase=filebase([1+max([0 (find(filebase=='/'))]):end]);
filebase=strrep(filebase,'.mat','');
%
disp('plot and analysis choices')
for k=1:length(plot_anal_choices)
    disp(sprintf('%2.0f->%s',k,plot_anal_choices{k}.desc));
end
%
% get what to plot or analyze
%
if ifauto
    plot_anal_choice=auto.plot_anal_choice;
    disp(sprintf('choice=%2.0f',plot_anal_choice));
else
    plot_anal_choice=getinp('choice of type of pca to analyze','d',[1 length(plot_anal_choices)],plot_anal_choice);
end
pair_list=plot_anal_choices{plot_anal_choice}.pair_list;
ipca_list=plot_anal_choices{plot_anal_choice}.ipca_list;
surr_list=plot_anal_choices{plot_anal_choice}.surr_list;
%
% these override the above defaults in auto mode
%
auto=filldefault(auto,'global_range',1);
auto=filldefault(auto,'global_minmax',[-60 0]);
auto=filldefault(auto,'if_sppoints',1);
auto=filldefault(auto,'if_segbars',1);
auto=filldefault(auto,'pca_ntoplot_max',3);
auto=filldefault(auto,'pca_ntostat_max',6);
auto=filldefault(auto,'pca_headmap_max',2);
auto=filldefault(auto,'headmap_style',2);
auto=filldefault(auto,'headmap_sigstyle',0);
auto=filldefault(auto,'quantiles',[0.025 0.05 0.95 0.975]);
auto=filldefault(auto,'headmap_iffig',1);
auto=filldefault(auto,'headmap_ifps',1);
auto=filldefault(auto,'headmap_infix','');
auto=filldefault(auto,'headmap_view',0);
auto=filldefault(auto,'cohplots_iffig',1);
auto=filldefault(auto,'cohplots_ifps',1);
auto=filldefault(auto,'cohplots_infix','');
auto=filldefault(auto,'bandplots_iffig',1);
auto=filldefault(auto,'bandplots_ifps',1);
auto=filldefault(auto,'bandplots_infix','');
%
auto=filldefault(auto,'bandplots_bands',[1 4.5;4.5 8.5;8.5 12.5;12.5 25.5;25.5 50]); %interval closed on bottom, open on top
%
if ~exist('global_range') | (ifauto==1) global_range=auto.global_range; end
if ~exist('global_minmax') | (ifauto==1) global_minmax=auto.global_minmax;end
if ~exist('if_sppoints') | (ifauto==1) if_sppoints=auto.if_sppoints; end
if ~exist('if_segbars') | (ifauto==1) if_segbars=auto.if_segbars; end
if ~exist('pca_ntoplot_max') | (ifauto==1) pca_ntoplot_max=auto.pca_ntoplot_max; end
if ~exist('pca_ntostat_max') | (ifauto==1) pca_ntostat_max=auto.pca_ntostat_max; end
if ~exist('pca_headmap_max') | (ifauto==1) pca_headmap_max=auto.pca_headmap_max; end
if ~exist('headmap_style') | (ifauto==1) headmap_style=auto.headmap_style; end
if ~exist('headmap_sigstyle') | (ifauto==1) headmap_sigstyle=auto.headmap_sigstyle; end
if ~exist('quantiles') | (ifauto==1) quantiles=auto.quantiles; end
if ~exist('headmap_iffig') | (ifauto==1) headmap_iffig=auto.headmap_iffig; end
if ~exist('headmap_ifps') | (ifauto==1) headmap_ifps=auto.headmap_ifps; end
if ~exist('headmap_infix') | (ifauto==1) headmap_infix=auto.headmap_infix; end
if ~exist('headmap_view') | (ifauto==1) headmap_view=auto.headmap_view; end
if ~exist('cohplots_iffig') | (ifauto==1) cohplots_iffig=auto.cohplots_iffig; end
if ~exist('cohplots_ifps') | (ifauto==1) cohplots_ifps=auto.cohplots_ifps; end
if ~exist('cohplots_infix') | (ifauto==1) cohplots_infix=auto.cohplots_infix; end
if ~exist('bandplots_iffig') | (ifauto==1) bandplots_iffig=auto.bandplots_iffig; end
if ~exist('bandplots_ifps') | (ifauto==1) bandplots_ifps=auto.bandplots_ifps; end
if ~exist('bandplots_infix') | (ifauto==1) bandplots_infix=auto.bandplots_infix; end
if ~exist('bandplots_bands') | (ifauto==1) bandplots_bands=auto.bandplots_bands; end
%
if (ismember(plot_anal_choice,[1 3])) & (ifauto==0)
    global_range=getinp('1 for a global range for spectral plots','d',[0 1],global_range);
    if (global_range)
        global_minmax(1)=getinp('min dB scale','f',[-200,200],global_minmax(1));
        global_minmax(2)=getinp('max dB scale','f',[global_minmax(1),200],global_minmax(2));
    end
end
if (plot_anal_choice==1) & (ifauto==0)
    if_sppoints=getinp('1 for points to indicate independent values on spectral plots','d',[0 1],if_sppoints);
    if_segbars=getinp('1 for lines to demarcate segments on spectrogram plots','d',[0 1],if_segbars);
    pca_ntoplot_max=getinp('number of PC''s to plot','d',[1 4],pca_ntoplot_max); %number of pc's to plot
    pca_ntostat_max=getinp('number of PC''s to calculate stats on','d',[pca_ntoplot_max Inf],pca_ntostat_max); %number of pc's to plot
end
if (ismember(plot_anal_choice,[2])) & (ifauto==0)
    pca_ntostat_max=getinp('number of PC''s to calculate stats on','d',[pca_ntoplot_max Inf],pca_ntostat_max); %number of pc's to plot
    quantiles=getinp('quantiles','f',[0 1],quantiles);
    pca_headmap_max=getinp('number of PC''s for headmap (0 for none)','d',[0 pca_ntostat_max],pca_headmap_max); %number of pc's for headmap
end
if (ismember(plot_anal_choice,[2 3])) & (ifauto==0)
    if (pca_headmap_max>0)
        headmap_style=getinp('headmap style as 0->2d, 1->3d, 2->3d with chords for interhemispheric','d',[0 2],headmap_style);
        disp('significance styles (NB: on value plots, significance always shown by thickness');
        disp('headmap styles for signficance plots (thickness always indicates significance on data plots)')
        disp('0->  significance shown by continuous coloring and thickness');
        disp('1->  significance shown by   discrete coloring and thickness');
        disp('2->  significance shown by   discrete coloring, uniform thickness');
        disp('3->  significance shown by   discrete coloring, uniform thickness, no wireframe or labels');
        headmap_sigstyle=getinp('your choice','d',[0 3],headmap_sigstyle);
    end
    if (plot_anal_choice==2)
        headmap_iffig=getinp('1 to save figures as fig files','d',[0 1],headmap_iffig);
        headmap_ifps=getinp('1 to save figures as ps','d',[0 1],headmap_ifps);
        if (headmap_iffig>0) | (headmap_ifps>0)
            disp(sprintf('file name base is %s',filebase));
            headmap_infix=getinp('infix','s',headmap_infix);
        end
    end
    if (plot_anal_choice==3)
        bandplots_iffig=getinp('1 to save figures as fig files','d',[0 1],bandplots_iffig);
        bandplots_ifps=getinp('1 to save figures as ps','d',[0 1],bandplots_ifps);
        if (bandplots_iffig>0) | (bandplots_ifps>0)
            disp(sprintf('file name base is %s',filebase));
            bandplots_infix=getinp('infix','s',bandplots_infix);
        end
    end
end
if (ifauto==1)
    disp(auto)
end
if isempty(pair_list)
    npairs=size(r.cohgram.labels,2);
    if ~exist('pair_list_def') pair_list_def=[1:npairs]; end
    for ipair=1:npairs
        disp(sprintf('ipair %3.0f->%s',ipair,r.cohgram.labels{ipair}))
    end
    if (ifauto)
        if isfield(auto,'pair_list')
            pair_list=auto.pair_list;
        else
            pair_list=[1:npairs];
        end
        disp('pair list used');
        disp(pair_list);
    else
        pair_list=getinp('choice of channel pair','d',[1 npairs],pair_list_def);
    end
    pair_list_def=pair_list;
end
if isempty(ipca_list)
    npca=size(r.cohgram.pca,2);
    ipca_list_avail=[];
    for ipca=1:npca
        if ~isempty(r.cohgram.pca{1,ipca})
            disp(sprintf('ipca %3.0f->%s',ipca,r.cohgram.pca{1,ipca}.pca_label))
            ipca_list_avail=[ipca_list_avail,ipca];
        end
    end
    if (ifauto)
        if isfield(auto,'ipca_list')
            ipca_list=auto.ipca_list;
        else
            ipca_list=[1:npca];
        end
        ipca_list=intersect(ipca_list_avail,ipca_list);
        disp('ipca_list used');
        disp(ipca_list);
    else
        if ~exist('ipca_list_def') ipca_list_def=[1:npca]; end
        ipca_list=intersect(ipca_list_avail,getinp('choice of pca type','d',[1 npca],intersect(ipca_list_def,ipca_list_avail)));
    end
    ipca_list_def=ipca_list;
end
nsurrs=size(r.cohgram_surrogates,2);
if isempty(surr_list)
    if (ifauto)
        if isfield(auto,'surr_list')
            surr_list=auto.surr_list;
        else
            surr_list=0;
        end
        disp('surr list used')
        disp(surr_list);
    else
        if ~exist('surr_list_def') surr_list_def=[0:min(nsurrs,1)]; end
        surr_list=getinp('true data (0) and list of surrogates (>=1)','d',[0 nsurrs],surr_list_def);
        surr_list_def=surr_list;
    end
end
%
wireframe_opts=[];
wireframe_opts.eegp_opts=eegp_opts;
wireframe_opts.fontsize=7;
wireframe_opts.headmap_narc=headmap_narc;
wireframe_opts.headmap_style=headmap_style;
wireframe_opts.headmap_view=headmap_view;
wireframe_opts.headmap_iflabel=1;
%
% compile a list of the leads that are actually used, for headmaps with data
%
headmap_labels=[];
for kpair_ptr=1:length(pair_list)
    kpair=pair_list(kpair_ptr);
    lead1=r.montage_analyzed{r.cohgram.pairs(kpair,1)};
    lead2=r.montage_analyzed{r.cohgram.pairs(kpair,2)};
    headmap_labels=strvcat(headmap_labels,lead1,lead2);
end
headmap_labels=unique(headmap_labels,'rows');
if isempty(headmap_labels_justthese)
    headmap_labels_use=headmap_labels;
else
    headmap_labels_use=[];
    for ill=1:length(headmap_labels)
        if ~isempty(strmatch(deblank(headmap_labels(ill,:)),headmap_labels_justthese,'exact'));
            headmap_labels_use=strvcat(headmap_labels_use,headmap_labels(ill,:));
        end
    end
end
%
% initialize some quantities
%
% for plot_anal_choice=2: to collect statistics and quantiles
stats_head=[];
quantiles_head=[];
% for plot_anal_choice=3: to collect values across all pairs
Sallpair=cell(0); %spectra, accumulated by pairs, so that each pair corresponds to an S12
Sallpair{1}=[];
Sallpair{2}=[];
S12allpair=[];
Sall=[]; %this collects spectra, independent of whehther the channel was the first or the second in the pair
Sall_count=zeros(1,length(headmap_labels));
%
% entries in order of headmap_labels
%
if (ismember(plot_anal_choice,[2 3]))
    font_size=7;
    lap_coefs=cofl_xtp_makemont(r.montage_recorded,r.montage_recorded,setfield([],'mont_mode','Laplacian'));
end
for ipca_ptr=1:length(ipca_list)
    for ipair_ptr=1:length(pair_list)
        for isurr_ptr=1:length(surr_list)
            ipair=pair_list(ipair_ptr);
            ipca=ipca_list(ipca_ptr);
            isurr=surr_list(isurr_ptr);
            min_pwr=r.xtp_opts.min_pwr; %typically 10^-10; %minimum nonzero power
            dt=1./r.metadata_recorded(1).srate;
            cohgram_plotstruct=r.cohgram;
            dstring='data';
            if (isurr>0)
                cohgram_plotstruct=r.cohgram_surrogates{isurr};
                dstring=sprintf('surr %3.0f',isurr);
            end
            pca_struct=cohgram_plotstruct.pca{ipair,ipca};
            cohgram_freqs=r.cohgram.freqs;
            pca_ntostat=min(size(pca_struct.u,2),pca_ntostat_max);
            pca_headmap=min(pca_ntostat,pca_headmap_max);
            %
            disp(sprintf('doing %s for %10s %s %s',...
                plot_anal_choices{plot_anal_choice}.desc_short,r.cohgram.labels{ipair},dstring,r.cohgram.pca{1,ipca}.pca_label));
            if ismember(plot_anal_choice,[1 3]) %spectrogram/coherogram plots or coherence plots
                %
                %concatenate data from coherograms
                %
                S1concat=[];
                S2concat=[];
                S12concat=[];
                cohgram_eachseg=[];% length of each coherogram segment
                datapts_eachseg=[];
                for iseg=r.segs_analyzed
                    S1concat=[S1concat;cohgram_plotstruct.S1{iseg,ipair}];
                    S2concat=[S2concat;cohgram_plotstruct.S2{iseg,ipair}];
                    S12concat=[S12concat;cohgram_plotstruct.S12{iseg,ipair}];
                    cohgram_eachseg=[cohgram_eachseg, size(cohgram_plotstruct.S1{iseg,ipair},1)];
                    datapts_eachseg=[datapts_eachseg, size(r.data_analyzed{iseg},1)];
                end
                Cconcat=abs(S12concat)./sqrt(S1concat.*S2concat);
                phiconcat=atan2(imag(S12concat),real(S12concat));
                S1S2=[cat(3,S1concat,S2concat)];
                S1S2range=10*[floor(min(log10(max(S1S2(:),min_pwr)))) ceil(max(log10(S1S2(:))))];
                S1S2S12=cat(3,S1concat,S2concat,S12concat);
                Slabels={'S1','S2','S12'};
                ntimes=size(S1S2,1);
            end
            %
            %
            switch plot_anal_choice
                case 1 %simple plots of spectrograms, coherograms, pc weights
                    %
                    tstring=sprintf('%s: %s %s %s',r.cohgram.labels{ipair},r.desc,r.cohgram.pca{1,ipca}.pca_label,dstring);
                    font_size=6;
                    nchans=2; %but won't work for any other value
                    nrows=6; %other values mess up plotting format
                    ncols=2;  %other values mess up plotting format; columns sometimes divided in thirds
                    color_list=['r','g','b','m']; %for traces and histos
                    ip2dlist={' ',[1 2],[1 2;1 3;2 3],[1 2;1 3;2 3;1 4]}; %list of pairs to plot for 2-d plot
                    %
                    %calculate statistics from PC's skewness, kurtosis, hartigan
                    %
                    [stats,stats_used]=cofl_anal_stats(pca_struct.u(:,1:pca_ntostat),stat_opts);
                    for istat=1:length(stats_used.names)
                        disp(sprintf(cat(2,'%10s: ',repmat('%7.4f ',1,pca_ntostat)),...
                            stats_used.names{istat},stats(istat,:)));
                    end
                    %
                    figure;
                    set(gcf,'Position',[50 50 1400 900]);
                    set(gcf,'Name',tstring);
                    set(gcf,'NumberTitle','off');
                    %
                    if (global_range)
                        S1S2range=global_minmax;
                    end
                    %
                    for ic=1:nchans*(nchans+1)/2;
                        subplot(nrows,ncols*3,ic);
                        vplot=abs(mean(S1S2S12(:,:,ic)));
                        plot(cohgram_freqs,10*log10(vplot),'k-');
                        hold on;
                        set(gca,'XLim',[0 max(cohgram_freqs)]);
                        xlabel('f (Hz)','FontSize',font_size);
                        set(gca,'YLim',S1S2range);
                        if (ic==1) ylabel('dB','FontSize',font_size);end
                        if (if_sppoints==1)
                            vplot_pts=abs(getfield(r.surrogate_info{ipair},Slabels{ic}));
                            plot(r.surrogate_info{1}.freqs,10*log10(vplot_pts),'k.');
                            legend(Slabels{ic},'data');
                        else
                            legend(Slabels{ic});
                        end
                        set(gca,'FontSize',font_size);
                        title(r.desc);
                    end
                    %
                    for ic=1:nchans
                        subplot(nrows,ncols,1+ncols*ic);
                        imagesc(1:ntimes,cohgram_freqs,(10*log10(S1S2(:,:,ic)))',S1S2range);set(gca,'YDir','normal');
                        hspect=gca;
                        hold on;
                        if (if_segbars)
                            for iseg=1:(length(cohgram_eachseg)-1)
                                plot(sum(cohgram_eachseg(1:iseg))*[1 1],cohgram_freqs([1 end]),'k-');
                            end
                        end
                        title(sprintf('%s %s log spectrogram, ch %1.0f (%s)',r.desc,dstring,ic,...
                            r.montage_analyzed{cohgram_plotstruct.pairs(ipair,ic)}),'FontSize',font_size);
                        set(gca,'XTick',[1 ntimes]);
                        set(gca,'XTickLabel',dt*[0 sum(datapts_eachseg)-1])
                        xlabel('t (sec)','FontSize',font_size);
                        ylabel('f (Hz)','FontSize',font_size);
                        set(gca,'YLim',[0 max(cohgram_freqs)]);
                        set(gca,'CLim',get(gca,'CLim')*[1 -0.1;0 1.1]); %make sure that last 10% of color range is not used so phacol can be used
                        hc=colorbar;set(hc,'YLim',get(hc,'YLim')*[1 0.1;0 0.9]);
                        set(gca,'FontSize',font_size);
                    end;
                    %
                    %plot cross-spectrogram
                    %
                    subplot(nrows,ncols,1+ncols*(nchans+1));
                    imagesc(1:ntimes,cohgram_freqs,10*log10(max(abs(S12concat'),min_pwr)),S1S2range);set(gca,'YDir','normal');
                    hold on;
                    if (if_segbars)
                        for iseg=1:(length(cohgram_eachseg)-1)
                            plot(sum(cohgram_eachseg(1:iseg))*[1 1],cohgram_freqs([1 end]),'k-');
                        end
                    end
                    title(sprintf('%s %s log cross-spectrogram amplitude (%s)',...
                        r.desc,dstring,cohgram_plotstruct.labels{ipair}),'FontSize',font_size);
                    set(gca,'XTick',[1 ntimes]);
                    set(gca,'XTickLabel',dt*[0 sum(datapts_eachseg)-1])
                    xlabel('t (sec)','FontSize',font_size);
                    ylabel('f (Hz)','FontSize',font_size);
                    set(gca,'YLim',[0 max(cohgram_freqs)]);
                    set(gca,'CLim',get(gca,'CLim')*[1 -0.1;0 1.1]); %make sure that last 10% of color range is not used so phacol can be used
                    hc=colorbar;set(hc,'YLim',get(hc,'YLim')*[1 0.1;0 0.9]);
                    set(gca,'FontSize',font_size);
                    %
                    %plot coherence amplitude
                    %
                    subplot(nrows,ncols,1+ncols*(nchans+2));
                    imagesc(1:ntimes,cohgram_freqs,Cconcat',[0 max(Cconcat(:))]);set(gca,'YDir','normal');
                    hold on;
                    if (if_segbars)
                        for iseg=1:(length(cohgram_eachseg)-1)
                            plot(sum(cohgram_eachseg(1:iseg))*[1 1],cohgram_freqs([1 end]),'k-');
                        end
                    end
                    title(sprintf('%s %s coherence amplitude (%s)',...
                        r.desc,dstring,cohgram_plotstruct.labels{ipair}),'FontSize',font_size);
                    set(gca,'XTick',[1 ntimes]);
                    set(gca,'XTickLabel',dt*[0 sum(datapts_eachseg)-1])
                    xlabel('t (sec)','FontSize',font_size);
                    ylabel('f (Hz)','FontSize',font_size);
                    set(gca,'YLim',[0 max(cohgram_freqs)]);
                    set(gca,'CLim',get(gca,'CLim')*[1 -0.1;0 1.1]); %make sure that last 10% of color range is not used so phacol can be used
                    hc=colorbar;set(hc,'YLim',get(hc,'YLim')*[1 0.1;0 0.9]);
                    set(gca,'FontSize',font_size);
                    %
                    %plot coherence phase
                    %
                    subplot(nrows,ncols,1+ncols*(nchans+3));
                    imagesc(1:ntimes,cohgram_freqs,phiconcat'/(2*pi),[-0.5 0.5]);set(gca,'YDir','normal');
                    %the color map messes up the others unless the ranges are compressed (see phacolor.m)
                    hold on;
                    colormap(phacolor(size(colormap,1))); %set up color map for phase
                    if (if_segbars)
                        for iseg=1:(length(cohgram_eachseg)-1)
                            plot(sum(cohgram_eachseg(1:iseg))*[1 1],cohgram_freqs([1 end]),'k-');
                        end
                    end
                    title(sprintf('%s %s coherence phase/(2*pi) (%s)',...
                        r.desc,dstring,cohgram_plotstruct.labels{ipair}),'FontSize',font_size);
                    set(gca,'XTick',[1 ntimes]);
                    set(gca,'XTickLabel',dt*[0 sum(datapts_eachseg)-1])
                    xlabel('t (sec)','FontSize',font_size);
                    ylabel('f (Hz)','FontSize',font_size);
                    set(gca,'YLim',[0 max(cohgram_freqs)]);
                    colorbar;
                    set(gca,'FontSize',font_size);
                    %
                    % PCA plots
                    %
                    %in some versions of cofl_xtp_demo, only tghe diagonal of s is saved.
                    %inflate it to full if necessary
                    %
                    s_diag=pca_struct.s;
                    if size(s_diag,2)>1
                        s_diag=diag(s_diag);
                    end
                    %
                    ds=s_diag;
                    ds=ds(1:length(pca_struct.fvals));
                    pca_ntoplot=min(length(ds),pca_ntoplot_max);
                    pca_ntoplot=min(pca_ntoplot,size(pca_struct.u,2));
                    pca_ntoplot=min(pca_ntoplot,size(pca_struct.v,2));
                    pca_nsubsets=length(pca_struct.pca_subsets); %1 for S1 or S2, 2 for S1S2, 3 for S1 S2 S12, etc.
                    %
                    %scree plot (plot all eigenvalues regardless of pca_ntoplot)
                    %
                    subplot(nrows,3*ncols,4);
                    semilogy([1:length(pca_struct.fvals)],max(ds,min_pwr)/sum(s_diag),'k.-');hold on;
                    title(sprintf('pca on %s',pca_struct.pca_label),'FontSize',font_size);
                    set(gca,'XLim',[1 length(pca_struct.fvals)]);
                    set(gca,'XTick',[1:ceil(length(pca_struct.fvals)/10):length(pca_struct.fvals)]);
                    xlabel('pc','FontSize',font_size);
                    set(gca,'YLim',[10^-4,1]);
                    set(gca,'FontSize',font_size);
                    %
                    %plot first pca_ntoplot PC's as lines and colormap
                    %
                    subplot(nrows,3*ncols,5);
                    for ip=1:pca_ntoplot
                        plot(-0.5+[1:size(pca_struct.v,1)],pca_struct.v(:,ip),cat(2,color_list(ip),'.-'));hold on;
                    end
                    set(gca,'YLim',[-1 1]*max(abs(get(gca,'YLim'))));
                    set(gca,'XLim',[0 size(pca_struct.v,1)]);
                    for ip=2:pca_nsubsets
                        plot((ip-1)*length(pca_struct.fvals)*[1 1],get(gca,'YLim'),'k-');
                    end
                    set(gca,'XTick',length(pca_struct.fvals)/pca_nsubsets*[1:pca_nsubsets]);
                    set(gca,'XTickLabel',pca_struct.fvals(end)); %matlab will repeat the label as needed
                    xlabel('f (Hz)','FontSize',font_size);
                    set(gca,'FontSize',font_size);
                    %
                    subplot(nrows,3*ncols,6);
                    vconsol=pca_struct.v(:,[1:pca_ntoplot]); %rearrange v so that strips show each pc, then each subset
                    vconsol=reshape(vconsol,[length(pca_struct.fvals)/pca_nsubsets pca_nsubsets pca_ntoplot]);
                    vconsol=permute(vconsol,[1 3 2]);
                    vconsol=reshape(vconsol,[length(pca_struct.fvals)/pca_nsubsets pca_ntoplot*pca_nsubsets]);
                    imagesc(vconsol);set(gca,'YDir','normal');hold on;
                    set(gca,'CLim',get(gca,'CLim')*[1 -0.1;0 1.1]); %make sure that last 10% of color range is not used so phacol can be used
                    %
                    for ip=2:pca_nsubsets
                        plot([1 1]*(0.5+(ip-1)*pca_ntoplot),get(gca,'YLim'),'k-');
                    end
                    set(gca,'XTick',0.5+pca_ntoplot*([1:pca_nsubsets]-0.5));
                    set(gca,'XTickLabel',pca_struct.pca_subsets);
                    colorbar off;
                    set(gca,'FontSize',font_size);
                    ylabel('f ptr'); %a pointer to the frequency, not the freq itself
                    %
                    %plot first pca_ntoplot PC's as function of time
                    %
                    pcm=max(max(abs(pca_struct.u(:,1:min(3,pca_ntoplot)))));
                    subplot(nrows,ncols,ncols+2);
                    for ip=1:pca_ntoplot
                        plot(1:ntimes,pcm*(ip-(pca_ntoplot+1)/2)+pca_struct.u(:,ip),cat(2,color_list(ip),'-'));hold on;
                        plot([1 ntimes],pcm*(ip-(pca_ntoplot+1)/2)*[1 1],'k-');hold on;
                    end
                    if (if_segbars)
                        for iseg=1:(length(cohgram_eachseg)-1)
                            plot(sum(cohgram_eachseg(1:iseg))*[1 1],get(gca,'YLim'),'k-');
                        end
                    end
                    xlabel('t (sec)','FontSize',font_size);
                    set(gca,'XLim',[1 ntimes]);
                    set(gca,'XTick',[1 ntimes]);
                    set(gca,'XTickLabel',dt*[0 sum(datapts_eachseg)-1])
                    set(gca,'Position',get(gca,'Position').*[1 1 0 1]+get(hspect,'Position').*[0 0 1 0]); %adjust x-axis of raw traces
                    set(gca,'FontSize',font_size);
                    %
                    % plot histograms of time series of PC's
                    %
                    subcol=max(pca_ntoplot,3);
                    for ip=1:pca_ntoplot
                        stat_title=[];
                        for istat=1:length(stats_used.names)
                            stat_title=cat(2,stat_title,sprintf('%s=%6.4f ',stats_used.names{istat}(1:2),stats(istat,ip)));
                        end
                        stat_title=deblank(stat_title);
                        subcol=max(pca_ntoplot,3);
                        subplot(nrows,subcol*ncols,subcol*2*ncols+subcol+ip);
                        hcounts=hist(pca_struct.u(:,ip),pcm*[-0.95:.1:0.95]);
                        hb=bar(pcm*[-0.95:.1:0.95],hcounts,1);
                        set(hb,'FaceColor',color_list(ip));
                        hold on;
                        xlabel(sprintf('pc%1.0f',ip),'FontSize',font_size);
                        set(gca,'XLim',[-pcm pcm]);
                        title(stat_title,'FontSize',font_size);
                        set(gca,'FontSize',font_size);
                    end
                    %
                    % 2d projections of time series of PC's into coordinate planes
                    %
                    selpos=find(pca_struct.u(:,1)>=0);
                    selneg=find(pca_struct.u(:,1)<0);
                    if pca_ntoplot>=2
                        for ip=1:size(ip2dlist{pca_ntoplot},1);
                            ip1=ip2dlist{pca_ntoplot}(ip,1);
                            ip2=ip2dlist{pca_ntoplot}(ip,2);
                            subplot(nrows,subcol*ncols,subcol*3*ncols+subcol+ip);
                            plot(pca_struct.u(selpos,ip1),pca_struct.u(selpos,ip2),'r.'); hold on;
                            plot(pca_struct.u(selneg,ip1),pca_struct.u(selneg,ip2),'k.'); hold on;
                            xlabel(sprintf('pc%1.0f',ip1),'FontSize',font_size);
                            ylabel(sprintf('pc%1.0f',ip2),'FontSize',font_size);
                            set(gca,'XLim',[-pcm pcm]);
                            set(gca,'YLim',[-pcm pcm]);
                            axis equal;
                            axis square;
                            set(gca,'FontSize',font_size);
                        end
                    end %pca_ntoplot
                    %
                    % 3d projections of time series of PC's into coordinate planes
                    %
                    if (pca_ntoplot>=3)
                    	ip1=1;
                        ip2=2;
                        ip3=3;
                        subplot(nrows/2,ncols,(nrows/2-1)*ncols+2);
                        plot3(pca_struct.u(selpos,ip1),pca_struct.u(selpos,ip2),pca_struct.u(selpos,ip3),'r.'); hold on;
                        plot3(pca_struct.u(selneg,ip1),pca_struct.u(selneg,ip2),pca_struct.u(selneg,ip3),'k.'); hold on;
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
                    if (cohplots_iffig)
                        pairstr=strrep(r.cohgram.labels{ipair},':','');
                        filename_fig=sprintf('%s_%s_ipca%1.0f_%s',filebase,cohplots_infix,ipca,pairstr);
                        saveas(gcf,filename_fig,'fig');
                        disp(sprintf('figure saved as %s.fig',filename_fig));
                    end
                    if (cohplots_ifps)
                        filename_ps=sprintf('%s_%s',filebase,cohplots_infix);
                        orient(gcf,'landscape');
                        print('-dpsc','-append','-r300',filename_ps);
                        disp(sprintf('figure appended to %s.ps',filename_ps));
                    end
                    %
                    %end of single-channel-pair plots
                    %
                case 2 % plots of fluctuation statistics across the head
                    %
                    % CAUTION
                    % ipca indicates which kind of pc-analysis
                    % kpc_dim indicates which dimension (i.e., which principal component)
                    %
                    [stats,stats_used]=cofl_anal_stats(pca_struct.u(:,1:pca_ntostat),stat_opts);
                    stats_head(:,:,ipair_ptr)=stats(:,1:pca_headmap); %(stat, pc-dim, pair)
                    %
                    if (nsurrs>0)
                        for isurr=1:nsurrs
                            pca_struct_surr=r.cohgram_surrogates{isurr}.pca{ipair,ipca};
                            stats_surr(:,:,isurr)=cofl_anal_stats(pca_struct_surr.u(:,1:pca_ntostat),stat_opts);
                        end
                        disp(sprintf(' calculated stats for %4.0f surrogates',nsurrs));
                        stats_surr_q=quantile(stats_surr,quantiles,3);
                        for istat=1:length(stats_used.names)
                            disp(sprintf(cat(2,'%10s: ',repmat('%7.4f ',1,pca_ntostat)),...
                                stats_used.names{istat},stats(istat,:)));
                            nlower=zeros(1,pca_ntostat);
                            for kpc_dim=1:pca_ntostat
                                nlower(kpc_dim)=sum(double(stats_surr(istat,kpc_dim,:)<stats(istat,kpc_dim)));
                            end
                            disp(sprintf(cat(2,'  quantile: ',repmat('%7.4f ',1,pca_ntostat)),nlower/nsurrs));
                            quantiles_head(istat,:,ipair_ptr)=nlower(1:pca_headmap)/nsurrs; %(stat, pc-dim, pair)
                            for iquant=1:length(quantiles)
                                disp(sprintf(cat(2,'%10.4f: ',repmat('%7.4f ',1,pca_ntostat)),...
                                    quantiles(iquant),stats_surr_q(istat,:,iquant)));
                            end
                            disp(' ');
                        end
                    else
                        for istat=1:length(stats_used.names)
                            disp(sprintf(cat(2,'%10s: ',repmat('%7.4f ',1,pca_ntostat)),...
                                stats_used.names{istat},stats(istat,:)));
                        end
                    end
                    %
                    % plot headmaps after all pairs have been accumulated
                    %
                    if (ipair_ptr==length(pair_list) & pca_headmap>0)
                        for istat=1:length(stats_used.names)
                            switch stats_used.names{istat}
                                case 'skew'
                                    lims_abs=[-1 1];
                                    lims_data=[-1 1]*max(max(abs(stats_head(istat,:,:))));
                                    tails=2;
                                case 'kurt'
                                    lims_abs=[0 1];
                                    lims_data=[-1 1]*max(max(abs(stats_head(istat,:,:)))); %colormap limits based on data
                                    tails=1;
                                case 'dip'
                                    lims_abs=[0 0.03];
                                    lims_data=[0 max(max(stats_head(istat,:,:)))];
                                    tails=1;
                                otherwise
                                    lims_abs=[-1 1];
                                    lims_data=[-1 1]*max(max(abs(stats_head(istat,:,:)))); %colormap limits based on data
                                    tails=2;
                            end
                            if (tails==1) lims_quantile=[0 1]; end
                            if (tails==2) lims_quantile=[0.5 1]; end
                            tstring=sprintf('%s: %s %s: %s',r.desc,r.cohgram.pca{1,ipca}.pca_label,dstring,stats_used.names{istat});
                            figure;
                            set(gcf,'Position',[50 50 1400 900]);
                            set(gcf,'Name',tstring);
                            set(gcf,'NumberTitle','off');
                            cscale=colormap(headmap_colormap);
                            %
                            for irow=1:2+double(nsurrs>0)
                                %use the last column for a colorbar
                                subplot(2+double(nsurrs>0),pca_headmap+1,irow*(pca_headmap+1));
                                %draw a wireframe, for each nearest neighbor (use Laplacian nonzero elements to determine neighbors)
                                if (headmap_wires_onkey) %draw headmap wireframe on key
                                    eegp_wireframe(lap_coefs,r.montage_recorded,wireframe_opts);
                                    axis off;
                                    ht=title(sprintf('%s: %s',r.desc,r.cohgram.pca{1,ipca}.pca_label));
                                    set(ht,'FontSize',font_size);
                                end %headmap_wires_onkey
                                switch irow
                                    case 1
                                        lims=lims_abs;
                                    case 2
                                        lims=lims_data;
                                    case 3
                                        lims=lims_quantile;
                                end
                                hcb=colorbar;
                                set(hcb,'YTick',[1,size(cscale,1)]);
                                set(hcb,'YTickLabel',strvcat(sprintf('%6.4f',lims(1)),sprintf('%6.4f',lims(2))),'FontSize',font_size);
                                axis off;
                                % now show each pc coordinate
                                for kpc_dim=1:pca_headmap
                                    switch irow
                                        case 1
                                            lims=lims_abs;
                                            dplot=squeeze(stats_head(istat,kpc_dim,:));
                                        case 2
                                            lims=lims_data;
                                            dplot=squeeze(stats_head(istat,kpc_dim,:));
                                        case 3
                                            lims=lims_quantile;
                                            dplot=squeeze(quantiles_head(istat,kpc_dim,:));
                                            if (tails==2)
                                                dplot=max(dplot,1-dplot);
                                            end
                                    end
                                    subplot(2+double(nsurrs>0),pca_headmap+1,kpc_dim+(irow-1)*(pca_headmap+1));
                                    if (headmap_wires_ondata) & ((irow<3) | (headmap_sigstyle<3)) %draw headmap wireframe on data unless sigstyle=3
                                        eegp_wireframe(lap_coefs,r.montage_recorded,...
                                            setfield(wireframe_opts,'headmap_labels',headmap_labels_use));
                                    end %headmap_wires_ondata
                                    %assume data will be plotted as an arc whose color indicates the value
                                    for kpair_ptr=1:length(pair_list)
                                        kpair=pair_list(kpair_ptr);
                                        %find color value corresponding to dplot(kpair_ptr)
                                        cvalue=round(size(cscale,1)*(dplot(kpair_ptr)-lims(1))/(lims(2)-lims(1)));
                                        cvalue=min(max(1,cvalue),size(cscale,1));
                                        %
                                        nsig=1;
                                        headmap_linewidth=headmap_linewidths(1);
                                        if (nsurrs>0)
                                            pval=quantiles_head(istat,kpc_dim,kpair_ptr);
                                            if (tails==2)
                                                pval=max(pval,1-pval);
                                            end
                                            nsig=[1,(find(pval>(1-(headmap_siglevels/tails))))];
                                            nsig=max(nsig);
                                        end
                                        headmap_linewidth=headmap_linewidths(nsig);
                                        lead1=r.montage_analyzed{r.cohgram.pairs(kpair,1)};
                                        lead2=r.montage_analyzed{r.cohgram.pairs(kpair,2)};
                                        narc=headmap_narc;
                                        if (headmap_style==2) & (eegp_side(lead1,eegp_opts)+eegp_side(lead2,eegp_opts))==0
                                            narc=0; %chord
                                        end
                                        coords=eegp_arcpts(lead1,lead2,narc,eegp_opts);
                                        if (headmap_style==0)
                                            hp=plot(coords(:,1),coords(:,2),'k'); hold on;
                                        else
                                            hp=plot3(coords(:,1),coords(:,2),coords(:,3),'k'); hold on;
                                        end
                                        %use color for value and line width for signficance
                                        set(hp,'Color',cscale(cvalue,:),'LineWidth',headmap_linewidth);
                                        %row 3: significance row:  optionally use discrete color scale for significance
                                        if (irow==3 & headmap_sigstyle>0)
                                            set(hp,'Color',headmap_sigcolors(nsig,:));
                                        end
                                        if (irow==3 & headmap_sigstyle>1)
                                            set(hp,'LineWidth',headmap_linewidths_sig(nsig)); %use standard line indep of signficance
                                        end
                                    end
                                    title(sprintf('%s %s pc%1.0f [%6.4f %6.4f]',...
                                        r.cohgram.pca{1,ipca}.pca_label,stats_used.names{istat},kpc_dim,lims),'FontSize',font_size);
                                    if (headmap_style==0)
                                        axis equal;view(2);
                                    else
                                        axis vis3d;view(3);
                                        if length(headmap_view)>1
                                            view(headmap_view);
                                        end
                                    end
                                    axis off;
                                end %kpc_dim which pc to plot
                            end %irow %abs lims, data lims, and quantiles
                            if (headmap_iffig)
                                filename_fig=sprintf('%s_%s_ipca%1.0f_%s',filebase,headmap_infix,ipca,stats_used.names{istat});
                                saveas(gcf,filename_fig,'fig');
                                disp(sprintf('figure saved as %s.fig',filename_fig));
                            end
                            if (headmap_ifps)
                                filename_ps=sprintf('%s_%s',filebase,headmap_infix);
                                orient(gcf,'landscape');
                                print('-dpsc','-append','-r300',filename_ps);
                                disp(sprintf('figure appended to %s.ps',filename_ps));
                            end
                        end %istat
                    end
                    %
                    %end of stats
                    %
                case 3 % plots of coherence, etc in specific bands
                    nbands=size(bandplots_bands,1); %number of frequency bands
                    nbandtypes=length(band_stat); %number of kinds of variables to analyze
                    %
                    % accumulate spectral quantities according to original pairwise analysis: dims are (time, freq, ipair_ptr)
                    %
                    Sallpair{1}(:,:,ipair_ptr)=S1concat;
                    Sallpair{2}(:,:,ipair_ptr)=S2concat;
                    S12allpair(:,:,ipair_ptr)=S12concat;
                    %
                    %collect spectra, independent of whether the channel was the first or the second in the pair
                    %
                    for kchan=1:2
                        headmap_labels_ptr=strmatch(deblank(r.montage_analyzed{r.cohgram.pairs(ipair_ptr,kchan)}),headmap_labels,'exact');
                        if Sall_count(headmap_labels_ptr)==0 %first one
                            Sall(:,:,headmap_labels_ptr)=Sallpair{kchan}(:,:,ipair_ptr);
                            disp(sprintf('  spectrum collected for %4s from chan %1.0f of %8s',headmap_labels(headmap_labels_ptr,:),kchan,r.cohgram.labels{ipair_ptr}));
                        else
                            disp(sprintf('  spectrum  verified for %4s from chan %1.0f of %8s',headmap_labels(headmap_labels_ptr,:),kchan,r.cohgram.labels{ipair_ptr}));
                            inconsist=max(max(abs(Sall(:,:,headmap_labels_ptr)-Sallpair{kchan}(:,:,ipair_ptr))));
                            if (inconsist>1e-10)
                                disp(' inconsistent spectrum calculation detected');
                                disp(sprintf(' ipair_ptr=%2.0f, kchan=%2.0f',ipair_ptr,kchan));
                            end
                        end
                        Sall_count(headmap_labels_ptr)=Sall_count(headmap_labels_ptr)+1;
                    end
                    %
                    % if last pair in list, then plot
                    %
                    if ipair_ptr==length(pair_list)
                        S1av=squeeze(mean(Sallpair{1},1));
                        S2av=squeeze(mean(Sallpair{2},1));
                        S12av=squeeze(mean(S12allpair,1));
                        Sav=squeeze(mean(Sall,1));
                        %
                        for band_type=1:nbandtypes
                            tstring=sprintf('%s: %s',r.desc,band_stat{band_type}.desc);
                            %set up limits for plotting
                            if (band_type==1)
                                specdata=abs(S12av)./sqrt(S1av.*S2av); %coherence
                                fstring='% 8.3f';
                            end
                            if (band_type==2)
                                specdata=10*log10(max(abs(S12av),min_pwr));
                                lims_spec=10*[floor(0.1*min(specdata(:))),ceil(0.1*max(specdata(:)))];
                                fstring='% 8.3f';
                            end
                            if (band_type==3)
                                specdata=10*log10(max(abs(Sav),min_pwr));
                                lims_spec=10*[floor(0.1*min(specdata(:))),ceil(0.1*max(specdata(:)))];
                                fstring='% 8.3f';
                            end
                            lims=band_stat{band_type}.lims;
                            if isempty(lims)
                                if global_range
                                    lims=global_minmax;
                                else
                                    lims=lims_spec;
                                end
                            end
                            if (band_stat{band_type}.mergetype==1)
                                nspecs=length(pair_list); %cross-channel quantity
                            end
                            if (band_stat{band_type}.mergetype==2)
                                nspecs=size(headmap_labels,1);
                            end
                            specdata_byband=zeros(nbands,nspecs);
                            fptrs=cell(0);
                            nfptrs=zeros(1,nbands);
                            for iband=1:nbands
                                freqrange=bandplots_bands(iband,:);
                                %which frequencies
                                fptrs{iband}=intersect(find(cohgram_freqs>=freqrange(1)),find(cohgram_freqs<freqrange(2))); %half-open interval
                                nfptrs(iband)=length(fptrs{iband});
                                if nfptrs(iband)>0
                                    specdata_byband(iband,:)=mean(specdata(fptrs{iband},:),1);
                                end
                            end
                            %
                            % summarize
                            %
                            disp(sprintf('%s summary',band_stat{band_type}.desc));
                            ilhlab={'   >=   ','   <    '};
                            for ilh=1:2
                                disp(sprintf(cat(2,'%s',repmat(' %7.2f',1,nbands)),ilhlab{ilh},bandplots_bands(:,ilh)));
                            end
                            disp(sprintf(cat(2,'chs/nfreqs',repmat(' %5.0f  ',1,nbands)),nfptrs));
                            if (band_stat{band_type}.mergetype==1)
                                for kpair_ptr=1:length(pair_list)
                                    kpair=pair_list(kpair_ptr);
                                    lead1=r.montage_analyzed{r.cohgram.pairs(kpair,1)};
                                    lead2=r.montage_analyzed{r.cohgram.pairs(kpair,2)};
                                    disp(sprintf(cat(2,'%4s:%4s',repmat(fstring,1,nbands)),lead1,lead2,specdata_byband(:,kpair_ptr)));
                                end
                            end
                            if (band_stat{band_type}.mergetype==2)
                                for ispec=1:nspecs
                                    disp(sprintf(cat(2,'  %4s   ',repmat(fstring,1,nbands)),headmap_labels(ispec,:),specdata_byband(:,ispec)));
                                end
                            end
                            %
                            % plots
                            %
                            % line graphs of specdata, (mergetype=1 or 2)
                            % if single-channel (mergetype==2) also bandplots using eeglab's topomap
                            % if single-channel (mergetype==2) also
                            % linegraphs positioned on the head **to be prettified
                            % colormap headplots of specdata_byband (mergetype=1 or 2) ***to be done*** 
                            %
                            %line graphs
                            figure;
                            %need to take into account headmap style, including view
                            %need to add a scale
                            set(gcf,'Position',[50 50 1400 900]);
                            set(gcf,'Name',tstring);
                            set(gcf,'NumberTitle','off');
                            [nr,nc]=nicesubp(nspecs,0.7);
                            for ispec=1:nspecs
                                if (band_stat{band_type}.mergetype==1)
                                    labtxt=r.cohgram.labels{ispec};
                                end
                                if (band_stat{band_type}.mergetype==2)
                                    labtxt=deblank(headmap_labels(ispec,:));
                                end
                                subplot(nr,nc,ispec);
                                plot(cohgram_freqs,specdata(:,ispec),'k'); hold on;
                                set(gca,'XLim',[0 max(cohgram_freqs)]);
                                xlabel('f','FontSize',font_size);
                                set(gca,'YLim',lims);
                                ylabel(band_stat{band_type}.ylabel,'FontSize',font_size);
                                set(gca,'FontSize',font_size);
                                title(labtxt,'FontSize',font_size);
                            end
                            %save the fig?
                            if (bandplots_iffig)
                                filename_fig=sprintf('%s_%sg_%s',filebase,bandplots_infix,band_stat{band_type}.suff);
                                saveas(gcf,filename_fig,'fig');
                                disp(sprintf('figure saved as %s.fig',filename_fig));
                            end
                            % save the ps?
                            if (bandplots_ifps)
                                filename_ps=sprintf('%s_%s',filebase,bandplots_infix);
                                orient(gcf,'landscape');
                                print('-dpsc','-append','-r300',filename_ps);
                                disp(sprintf('figure appended to %s.ps',filename_ps));
                            end
                            %
                            %if non pair-oriented data (mergetype==2) show bands using eeglab routines
                            % and also make line graphs positioned on head
                            if (band_stat{band_type}.mergetype==2)
                                % eeglab bandplots
                                figure;
                                set(gcf,'Position',[50 50 1400 900]);
                                set(gcf,'Name',tstring);
                                set(gcf,'NumberTitle','off');
                                title(tstring,'FontSize',font_size);
                                chanlocs=eegp_makechanlocs(headmap_labels_use); %for eeglab
                                [nr,nc]=nicesubp(nbands+1,0.7);
                                for iband=1:nbands;
                                    freqrange=bandplots_bands(iband,:);
                                    subplot(nr,nc,iband);
                                    topoplot(specdata_byband(iband,:),chanlocs,'maplimits',lims);
                                    ht=title(sprintf(' >=%5.2fHz, <%5.2fHz',freqrange));
                                    set(ht,'FontSize',font_size);
                                    axis off;
                                end
                                subplot(nr,nc,iband+1);
                                topoplot([],chanlocs,'electrodes','labels','style','blank');
                                title(tstring,'FontSize',font_size);
                                axis off;
                                hcb=colorbar;
                                set(hcb,'YTick',[1,size(cscale,1)]);
                                set(hcb,'YTickLabel',strvcat(sprintf('%6.2f',lims(1)),sprintf('%6.2f',lims(2))),'FontSize',font_size);
                                axis off;
                                %save the fig?
                                if (bandplots_iffig)
                                    filename_fig=sprintf('%s_%se_%s',filebase,bandplots_infix,band_stat{band_type}.suff);
                                    saveas(gcf,filename_fig,'fig');
                                    disp(sprintf('figure saved as %s.fig',filename_fig));
                                end
                                % line graphs positioned on the head
                                figure;
                                set(gcf,'Position',[50 50 1400 900]);
                                set(gcf,'Name',tstring);
                                set(gcf,'NumberTitle','off');
                                head_diam=2*max(eegp_cart('CZ')); %head radius
                                hscale_abs=headmap_abscissa_frac*head_diam/max(cohgram_freqs); %scale abscissa to head radius
                                hscale_ord=headmap_ordinate_frac*head_diam/(lims(2)-lims(1)); %scale ordinate to head radius
                                %data will rows (x,y), to be pre-multiplied by hxform to plot in 3d
                                hoff=[0.5*max(cohgram_freqs);mean(lims)];
                                if (headmap_yz)==1
                                    hxform=[hscale_abs 0;0 hscale_ord;0 0]; %plot ordinate along y-axis
                                end
                                if (headmap_yz)==2
                                    hxform=[hscale_abs 0;0 0;0 hscale_ord]; %plots ordinate along z-axis
                                end
                                for ispec=1:nspecs
                                     headloc=eegp_cart(deblank(headmap_labels(ispec,:)),eegp_opts);
                                     %data values
                                     vals_data=[cohgram_freqs;specdata(:,ispec)']-repmat(hoff,1,length(cohgram_freqs));
                                     xyzvals_data=hxform*vals_data+repmat(headloc',1,length(cohgram_freqs));
                                     plot3(xyzvals_data(1,:),xyzvals_data(2,:),xyzvals_data(3,:),'k');
                                     hold on;
                                     vals_axes=[0 0 max(cohgram_freqs);lims(2) lims(1) lims(1)]-repmat(hoff,1,3);
                                     xyzvals_axes=hxform*vals_axes+repmat(headloc',1,3);
                                     plot3(xyzvals_axes(1,:),xyzvals_axes(2,:),xyzvals_axes(3,:),'k');
                                     tposit=xyzvals_axes*[1 -0.2 +0.2]';
                                     text(tposit(1),tposit(2),tposit(3),deblank(headmap_labels(ispec,:)));
                                end
                                title(tstring,'FontSize',font_size);
                                axis vis3d;view(3);
                                if length(headmap_view)>1
                                    view(headmap_view);
                                end
                                axis off;
                                %save the fig?
                                if (bandplots_iffig)
                                    filename_fig=sprintf('%s_%sh_%s',filebase,bandplots_infix,band_stat{band_type}.suff);
                                    saveas(gcf,filename_fig,'fig');
                                    disp(sprintf('figure saved as %s.fig',filename_fig));
                                end
                                % save the ps?
                                if (bandplots_ifps)
                                    filename_ps=sprintf('%s_%s',filebase,bandplots_infix);
                                    orient(gcf,'landscape');
                                    print('-dpsc','-append','-r300',filename_ps);
                                    disp(sprintf('figure appended to %s.ps',filename_ps));
                                end
                            end
                            %
                            %headplots
                            figure;
                            set(gcf,'Position',[50 50 1400 900]);
                            set(gcf,'Name',tstring);
                            set(gcf,'NumberTitle','off');
                            cscale=colormap(headmap_colormap);
                            [nr,nc]=nicesubp(nbands+1,0.7);
                            %
                            %make a key
                            %
                            subplot(nr,nc,nbands+1);
                            eegp_wireframe(lap_coefs,r.montage_recorded,wireframe_opts);
                            axis off;
                            title(tstring,'FontSize',font_size);
                            hcb=colorbar;
                            set(hcb,'YTick',[1,size(cscale,1)]);
                            set(hcb,'YTickLabel',strvcat(sprintf('%6.2f',lims(1)),sprintf('%6.2f',lims(2))),'FontSize',font_size);
                            axis off;
                            %
                            %plot specdata_byband
                            %
                            for iband=1:nbands;
                                freqrange=bandplots_bands(iband,:);
                                subplot(nr,nc,iband);
                                if (headmap_wires_ondata) %draw headmap wireframe on data
                                    eegp_wireframe(lap_coefs,r.montage_recorded,...
                                        setfield(wireframe_opts,'headmap_labels',headmap_labels_use));
                                end %headmap_wires_ondata
                                ht=title(sprintf(' >=%5.2fHz, <%5.2fHz',freqrange));
                                set(ht,'FontSize',font_size);
                                if (headmap_style==0)
                                    axis equal;view(2);
                                else
                                    axis vis3d;view(3);
                                    if length(headmap_view)>1
                                        view(headmap_view);
                                    end
                                end
                                axis off;
                            end
                            %save the fig?
                            if (bandplots_iffig)
                                filename_fig=sprintf('%s_%s_%s',filebase,bandplots_infix,band_stat{band_type}.suff);
                                saveas(gcf,filename_fig,'fig');
                                disp(sprintf('figure saved as %s.fig',filename_fig));
                            end
                            %
                            %save the ps?
                            if (bandplots_ifps)
                                filename_ps=sprintf('%s_%s',filebase,bandplots_infix);
                                orient(gcf,'landscape');
                                print('-dpsc','-append','-r300',filename_ps);
                                disp(sprintf('figure appended to %s.ps',filename_ps));
                            end
                        end %band_type
                    end % the last pair
                    %
                    %end of bandplots
                    %
            end %switch plot_anal_choice
        end %isurr_ptr
    end %ipair_ptr
end %ipca_ptr
