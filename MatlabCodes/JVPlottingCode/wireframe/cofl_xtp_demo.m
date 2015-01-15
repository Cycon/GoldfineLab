% cofl_xtp_demo
%
% note:  the surrogate data is normalized to match the variance of the original data
%   * It is not clear why this is necessary, since surr_corrgau and
%   surr_corrgau2 should take care of this.
%
%   * Since the overall variance is matched, but the surrogates are created
%   based on spectra only up to [0 fpass], their spectra may be slightly
%   larger at the low frequencies(since, by construction, the surrogates
%   have no power above fpass)
%
%   * IMPORTANT: prior to 6-24-10, tapers were not properly normalized by sqrt(Fs)
%   This is fixed, and now "results.cohgram" has a flag, tapers_fixed=1,
%   that it is fixed.
%
% to do:
%   * Have an option to make the surrogates segment by segment, both to
%   save memory space and ensure complete statistical dependence
%   * Have an option to make the surrogates use the power in each segment
%   rather than a global power
%
% 11-7-10:  revised to use the same defaults as MC's version for the
% longitudinal data sets, and slight changes in the documentation
%
% analyzes patient EEG that has already been preprocessed (segmented, selected) --
% filtering and montaging via Shawniqua's XTP toolkit
% calculates coherence and related quantities, using Chronux
% makes surrogate data sets
%
% results{} contains the results and the parameters used,
%   and fields of results{} named *recorded are copied from the preprocessed datasets
%
% dataset file names are made by cofl_xtp_setup_[devel|clnd]
%
%   See also:  COFL_XTP_LOADCHECK, COFL_XTP_SETDEF, COFL_XTP_MAKEMONT,
%   COFL_ANAL_DEMO, PARSE_SPECGRAM_DEMO,EEGP_DEFOPTS, COFL_XTP_SETUP_DEVEL, COFL_SETUP_CLND.
%
if ~exist('ifscratch') ifscratch=1; end
ifscratch=getinp('1 to start from scratch','d',[0 1],ifscratch);
if (ifscratch==1)
    clear all;
    if ~exist('datapath') datapath='XTPAnalysis'; end
    datapath=getinp('data path','s',[],datapath);
    cofl_build_environment(cat(2,datapath,'/XTP_aug'));
    %xtp_build_environment;
    whos
    ifscratch=0;
    xtp_opts=cofl_xtp_setdef; %options to control montaging, spectral analysis, and PCA
    eegp_opts=eegp_defopts; %options for lead position package
else
    if ~exist('datapath') datapath='XTPAnalysis'; end
    datapath=getinp('data path','s',[],datapath);
end
if ~exist('isetup') isetup=1; end
isetup=getinp('1->devel setup, 2->clnd dataset setup, 3->longitudinal spectra setup','d',[1 3],isetup);
%
switch isetup
    case 1
        xtp_opts.chronux_pad=getinp('Chronux pad','d',[-1 2],xtp_opts.chronux_pad);
        xtp_opts.nsurr=5;
        xtp_opts.nsurr=getinp('standard number of surrogates to calculate','d',[0 Inf],xtp_opts.nsurr);
        xtp_opts.keep_surr_details=[1:xtp_opts.nsurr]; %default is to keep all surrogates
        xtp_opts.keep_surr_details=getinp('surrogate details to keep','d',[0 Inf],xtp_opts.keep_surr_details);
        filename_setup_def='cofl_xtp_setup_devel';
        pairlist_deftype=0; %all pairs
    case 2
        xtp_opts.nsurr=200;
        xtp_opts.nsurr=getinp('standard number of surrogates to calculate','d',[0 Inf],xtp_opts.nsurr);
        xtp_opts.keep_surr_details=unique([1 xtp_opts.nsurr]); %default is to keep only first and last surrogate
        xtp_opts.keep_surr_details=getinp('surrogate details to keep','d',[0 Inf],xtp_opts.keep_surr_details);
        filename_setup_def='cofl_xtp_setup_clnd';
        pairlist_deftype=0; %all pairs
    case 3
        xtp_opts.nsurr=0;
        xtp_opts.nsurr=getinp('standard number of surrogates to calculate','d',[0 Inf],xtp_opts.nsurr);
        xtp_opts.keep_surr_details=unique([1 xtp_opts.nsurr]); %default is to keep only first and last surrogate
        xtp_opts.keep_surr_details=getinp('surrogate details to keep','d',[0 Inf],xtp_opts.keep_surr_details);
        filename_setup_def='cofl_xtp_setup_long';
        pairlist_deftype=1; %pair with channel 1 only
        xtp_opts.remove_redund_cohdata=1;
        xtp_opts.remove_surr_timeseries=1;
end
if ismember(isetup,[1 2])
    disp('enter 0 for default calculation of coherences between all pairs, n>0 for calculation of coherences w.r.t. channel n');
    disp('  note 0 is slow but gives all coherences, n>0 suffices for all spectra but only a subset of coherences');
    pairlist_deftype=getinp('0->default pair list contains all pairs, n->default pair list is all channels paired with channel n','d',[0 Inf],pairlist_deftype);
    xtp_opts.remove_redund_cohdata=getinp('1 to remove redundant coherence data (C and phi) from results structure','d',[0 1],xtp_opts.remove_redund_cohdata);
    xtp_opts.remove_surr_timeseries=getinp('1 to remove surrogate timeseries from results structure','d',[0 1],xtp_opts.remove_surr_timeseries);
    xtp_opts.pca_max_uv_keep=getinp('maximum number of pc''s to keep (all eigs always kept)','d',[2 Inf],xtp_opts.pca_max_uv_keep);
end
xtp_opts.chronux_NW=getinp('chronux NW','d',[1 101],xtp_opts.chronux_NW);
xtp_opts.chronux_k=getinp('chronux k','d',[1 101],2*xtp_opts.chronux_NW-1);
xtp_opts.chronux_winsize=getinp('chronux window size in sec','f',[0 10],xtp_opts.chronux_winsize);
xtp_opts.chronux_winstep=getinp('chronux window step in sec','f',[0 10],xtp_opts.chronux_winsize);
%
xtp_opts.pca_minfreq=getinp('min freq for PCA','d',[0 xtp_opts.chronux_fmax],0);
xtp_opts.pca_maxfreq=getinp('max freq for PCA','d',[xtp_opts.pca_minfreq xtp_opts.chronux_fmax],xtp_opts.chronux_fmax);
%
if ~exist('laplacian')
    laplacian.on=1;
end
if ~exist('chansets')
    filename_setup=getinp('file name for chansets setup','s',[0 1],filename_setup_def);
    chansets=getfield(load(filename_setup),'chansets');
end
if ~exist('ds')
    filename_setup=getinp('file name for datasets setup','s',[0 1],filename_setup_def);
    ds=getfield(load(filename_setup),'ds');
    ndatasets=length(ds);
    ds_loaded=zeros(1,ndatasets);
else
    ndatasets=length(ds);
end
for ids=1:length(ds)
    ds{ids}.datapath=datapath;
    disp(sprintf('%2.0f -> %30s %s',ids,ds{ids}.filename,ds{ids}.desc));
    ds_loaded(ids)=isfield(ds{ids},'data');
end
if (any(ds_loaded==0))
    disp('some datasets are currently unloaded')
else
    disp('all datasets currently loaded');
end
ds_toload=find(ds_loaded==0);
if isempty(ds_toload)
    ds_toload=0;
end
ds_toload=getinp('list of datasets to (re)load and check consistency','d',[0 ndatasets],ds_toload);
if (ds_toload>0)
    for ids=ds_toload
        ds{ids}=cofl_xtp_loadcheck(ds{ids});
    end
end
ds_loaded=max(ds_loaded,ismember([1:ndatasets],ds_toload));
%
if (isetup==1) % do consistency checks in devel mode only
    if (ds_loaded(1)>0 & ds_loaded(3)>0)
        disp('checking consistency of F3-C3 bipolar montage and montage 0 for baseline (zolpidem-OFF) data');
        nOFF=ds{1}.nsegs;
        for k=1:nOFF;zoff(:,k)=ds{1}.data.data{k}(:,2);end
        for k=1:nOFF;zoff0(:,k)=ds{3}.data.data{k}(:,8)-ds{3}.data.data{k}(:,9);end
        disp(sprintf(' max dev is: %15.7g', max(max(abs(zoff-zoff0)))));
        clear nOFF zoff zoff0
    end
    if (ds_loaded(2)>0 & ds_loaded(5)>0)
        disp('checking consistency of F3-C3 bipolar montage and montage 0 for zolpidem-ON data');
        nON=ds{2}.nsegs;
        for k=1:nON;zon(:,k)=ds{2}.data.data{k}(:,2);end
        for k=1:nON;zon0(:,k)=ds{5}.data.data{k}(:,8)-ds{5}.data.data{k}(:,9);end
        disp(sprintf(' max dev is: %15.7g', max(max(abs(zon-zon0)))));
        clear nON zon zon0
    end
end

for ids=find(ds_loaded>0)
    disp(sprintf('%2.0f -> %45s %3.0f chs (%3.0f leads), %3.0f segs, montage %s',...
        ids,ds{ids}.desc,...
        ds{ids}.nchans_avail,ds{ids}.meta.numleads,ds{ids}.nsegs,ds{ids}.meta.HBmontageName));
end
ds_toproc=getinp('list of datasets to process (can repeat)','d',[0 ndatasets],find(ds_loaded>0));
%
% set up a results structure
%
results=cell(length(ds_toproc),1);
%
%specify what to do
%
data_edits=[];
pass_list=[];
for idsptr=1:length(ds_toproc)
    ids=ds_toproc(idsptr);
    disp(' ');
    disp('=================================================================');
    disp(' setup for analysis of')
    disp(sprintf('dataset %2.0f is %2.0f -> %45s %3.0f chs (%3.0f leads), %3.0f segs, montage %s',...
        idsptr,ids,ds{ids}.desc,...
        ds{ids}.nchans_avail,ds{ids}.meta.numleads,ds{ids}.nsegs,ds{ids}.meta.HBmontageName));
    results{idsptr}=[];
    results{idsptr}.xtp_opts=xtp_opts;
    results{idsptr}.dataset_number=ids;
    results{idsptr}.xtp_opts.detrend=getinp('1 to detrend (and remove the mean)','d',[0 1],xtp_opts.detrend);
    if results{idsptr}.xtp_opts.detrend==1
        results{idsptr}.xtp_opts.demean=1;
    else
        results{idsptr}.xtp_opts.demean=getinp('1 to remove the mean','d',[0 1],xtp_opts.demean);
    end
    results{idsptr}.nsurr=getinp('number of surrogates','d',[0 10000],xtp_opts.nsurr);
    xtp_opts.nsurr=results{idsptr}.nsurr;
    keep_surr_details=[1:results{idsptr}.nsurr];
    if ~isempty(xtp_opts.keep_surr_details)
        keep_surr_details=intersect(xtp_opts.keep_surr_details,[1:results{idsptr}.nsurr]);
    end
    %
    %choose a montage, first show which ones are available and what the current montage is
    %
    %headbox=ds{ids}.data.metadata(1).headbox;
    HBmontageID=ds{ids}.data.metadata(1).HBmontageID;
    HBmontageName=ds{ids}.data.metadata(1).HBmontageName;
    if HBmontageID==0
        headboxID=ds{ids}.data.metadata(1).headbox.headboxID;
    else
        headboxID=XTP_HB_MONTAGES(HBmontageID).headbox_id;
    end
    headboxName=XTP_HEADBOXES(headboxID).name;
    disp(sprintf(' collected with headboxID (%2.0f): %s',headboxID,headboxName));
    disp(sprintf(' input data has montageID (%2.0f): %s',HBmontageID,HBmontageName));
    monts_compat=0;
    disp(sprintf('montage %2.0f (passthru for headbox %2.0f): %s',0,headboxID,'passthru'));
    for imont=1:length(XTP_HB_MONTAGES)
        if (headboxID==XTP_HB_MONTAGES(imont).headbox_id)
            monts_compat=[monts_compat,imont];
        end
        disp(sprintf('montage %2.0f (intended for headbox %2.0f): %s',imont,XTP_HB_MONTAGES(imont).headbox_id,XTP_HB_MONTAGES(imont).name));
    end
    disp(' the following montages should be compatible:');
    disp(monts_compat)
    montage_number_requested=getinp('montage selection for analysis','d',[0 length(XTP_HB_MONTAGES)],HBmontageID);
    results{idsptr}.montage_number_requested=montage_number_requested;
    %necessary because number of channels available may be less than the total in the headbox
    %and because headbox list of channel names may not be uppercase
    lead_list=[];
    for ilead=1:ds{ids}.nchans_avail
        lead_list{ilead}=upper(ds{ids}.data.info.channelNames{ilead});
    end
    results{idsptr}.laplacian=[];
    results{idsptr}.laplacian.on=0; %no laplacian allowed unless montage 0
    results{idsptr}.chansets_builtin=0;
    makemont_opts=[];
    laplacian_opts=[];
    if (results{idsptr}.montage_number_requested==0)
        %
        %pass-through, or Laplacian
        %
        laplacian.on=getinp('1->apply a Laplacian prior to channel selection','d',[0 1],laplacian.on);
        if (laplacian.on)
            laplacian_opts=xtp_opts;
            laplacian_opts.mont_mode='Laplacian'; 
            switch getinp('1->simple, 2->Hjorth','d',[1 2],2);
                case 1
                    laplacian_opts.Laplacian_type='simple';
                case 2
                    laplacian_opts.Laplacian_type='Hjorth';
            end
            [coefs,names_made,laplacian_opts]=cofl_xtp_makemont(lead_list,lead_list,laplacian_opts);
            laplacian.coefs=coefs;
            laplacian.names_made=names_made;
            results{idsptr}.laplacian=laplacian;
            results{idsptr}.laplacian_opts=laplacian_opts;
        end
        %
        channel_names=cell(0);
        nleads=length(lead_list);
        if ~isempty(pass_list)
            if_pass_list=getinp('1 to select specific channels, 2 for built-in sets,-1 to use previous selection','d',[-1 2],0);
        else
            results{idsptr}.chansets_builtin=0;
            if_pass_list=getinp('1 to select specific channels, 2 for built-in sets','d',[0 2],0);
        end
        switch if_pass_list
            case 2
                for k=1:length(chansets)
                    disp(sprintf('set %1.0f ->%s',k,chansets{k}.name));
                end
                results{idsptr}.chansets_builtin=getinp('selection','d',[1 length(chansets)],1);
                pass_list=[];
                for ipass=1:size(chansets{results{idsptr}.chansets_builtin}.leadlist,1)
                    posit=strmatch(deblank(chansets{results{idsptr}.chansets_builtin}.leadlist(ipass,:)),lead_list,'exact');
                    if ~isempty(posit)
                        pass_list=[pass_list, min(posit)];
                    else
                        disp(sprintf(' requested channel %s not found',chansets{results{idsptr}.chansets_builtin}.leadlist(ipass,:)))
                    end
                end
                disp(sprintf('%2.0f channels requested, %2.0f channels found',...
                    size(chansets{results{idsptr}.chansets_builtin}.leadlist,1),length(pass_list)));
                disp('at montage positions')
                disp(pass_list);
                for ipass=1:length(pass_list)
                    channel_names{ipass,1}=lead_list{pass_list(ipass)};
                end
            case 1
                for ilead=1:nleads
                    disp(sprintf('lead %2.0f->%s',ilead,lead_list{ilead}));
                end
                pass_list=getinp('selection','d',[1 nleads],[1:nleads]);
                for ipass=1:length(pass_list)
                    channel_names{ipass,1}=lead_list{pass_list(ipass)};
                end
            case -1
                if isempty(pass_list)
                    pass_list=[1:nleads];
                else
                    pass_list=intersect(pass_list,[1:nleads]);
                end
                for ipass=1:length(pass_list)
                    channel_names{ipass,1}=lead_list{pass_list(ipass)};
                end
                disp(' previous channel list (by number) used')
            case 0
                channel_names=lead_list;
        end
        makemont_opts.mont_mode='passthru';
    else
        %necessary because number of channels available may be less than the total in the headbox
        %and because headbox list of channel names may not be uppercase
        channel_names=[];
        %for ilead=1:ds{idsptr}.nchans_avail;
        for ilead=1:length(XTP_HB_MONTAGES(montage_number_requested).channelNames)
            channel_names{ilead}=upper(XTP_HB_MONTAGES(montage_number_requested).channelNames{ilead});
        end
        makemont_opts.mont_mode='bipolar';
    end
    %
    %find the coefficient matrix that transforms the recorded montage into the one requested for analysis
    %
    % passthrough or Laplacian mode: Laplacian is applied first, then lead selection
    %
    % bipolar mode:  Laplacian is NEVER applied
    %
    [coefs,names_made,results{idsptr}.makemont_opts]=cofl_xtp_makemont(lead_list,channel_names,makemont_opts);
    %
    results{idsptr}.montage_recorded=lead_list;
    results{idsptr}.montage_requested=channel_names;
    results{idsptr}.montage_analyzed_withNA=names_made;
    results{idsptr}.coefs_withNA=coefs;
    %remove the channels that cannot be analyzed because the leads were not present or the linear combination could not be made
    chans_avail=setdiff([1:size(coefs,1)],results{idsptr}.makemont_opts.chans_nalist);
    %
    %save some results
    %
    results{idsptr}.coefs=coefs(chans_avail,:);
    results{idsptr}.montage_analyzed=names_made(chans_avail);
    results{idsptr}.nsegs=ds{ids}.nsegs;
    results{idsptr}.nchans_recorded=ds{ids}.nchans_avail;
    results{idsptr}.nchans_analyzed=size(results{idsptr}.coefs,1);
    results{idsptr}.filename=ds{ids}.filename;
    results{idsptr}.fieldname=ds{ids}.fieldname;
    results{idsptr}.desc=ds{ids}.desc;
    results{idsptr}.datapath=ds{ids}.datapath;
    results{idsptr}.info_recorded=ds{ids}.data.info;
    results{idsptr}.metadata_recorded=ds{ids}.data.metadata;
    results{idsptr}.data_recorded=ds{ids}.data.data;
    %
    %ask for data edits, and record the edits as a field of results{idsptr}
    %
    results{idsptr}.data_edits=[];
    if (size(data_edits,1)==results{idsptr}.nsegs)
        if_data_edits=getinp('1 for any data edits, -1 to use previous','d',[-1 1],0);
    else
        if_data_edits=getinp('1 for any data edits','d',[0 1],0);
    end
    switch if_data_edits
        case 1
            for iseg=1:results{idsptr}.nsegs
                data_orig(iseg,:)=[1 size(results{idsptr}.data_recorded{iseg},1)];
            end
            data_edits=data_orig;
            remove=getinp('segments to remove from analysis (0 for none)','d',[0 results{idsptr}.nsegs],0);
            remove=intersect(remove,[1:results{idsptr}.nsegs]);
            if ~isempty(remove)
                data_edits(remove,:)=0;
            end
            shorten=Inf;
            while any(shorten>0)
                shorten=getinp('segments to shorten (0 for none)','d',[0 results{idsptr}.nsegs],0);
                remove=find(max(data_edits,[],2)==0);
                shorten=setdiff(intersect(shorten,[1:results{idsptr}.nsegs]),remove); %cannot edit a seg that's been removed
                srate=results{idsptr}.metadata_recorded(1).srate;
                if any(shorten>0)
                    %give start and stop time in bins and in actual time
                    data_edits_chosen=data_edits(shorten,:);
                    disp(' as currently edited:')
                    disp(sprintf(' indicated segments start at (in samples): %5.0f to %5.0f  (in sec) %8.3f to %8.3f',...
                        min(data_edits_chosen(:,1)),max(data_edits_chosen(:,1)),(min(data_edits_chosen(:,1))-1)/srate,(max(data_edits_chosen(:,1))-1)/srate));
                    disp(sprintf(' indicated segments  end  at (in samples): %5.0f to %5.0f  (in sec) %8.3f to %8.3f',...
                        min(data_edits_chosen(:,2)),max(data_edits_chosen(:,2)),(min(data_edits_chosen(:,2))-1)/srate,(max(data_edits_chosen(:,2))-1)/srate));
                    %gete new times
                    new_start=getinp('start time (in samples)','d',[1 max(data_orig(:,2))]);
                    new_end=getinp(' end  time (in samples)','d',[new_start max(data_orig(:,2))]);
                    data_edits(shorten,:)=repmat([new_start new_end],length(shorten),1);
                    %if new_end is beyond end of data, reduce it
                    data_edits(:,2)=min(data_edits(:,2),data_orig(:,2));
                    %if new_start is beyond end of data, count it as a removal
                    beyond=find(data_edits(:,1)>data_orig(:,2));
                    data_edits(beyond,:)=0;
                end
            end
        case 0
            data_edits=[];
        case -1
            disp('previous data edits used.');
    end
    remove=find(max(data_edits,[],2)==0);
    results{idsptr}.segs_analyzed=setdiff([1:results{idsptr}.nsegs],remove');
    results{idsptr}.data_edits=data_edits;
    clear iseg remove shorten srate data_edits_chosen new_start new_end beyond
    clear imont names_made coefs chans_avail montage_number_requested
    clear monts_compat headboxName headboxID HBmontageID HBmontageName
end
%
% condition (montage, demean,  detrend) the data
%
for idsptr=1:length(ds_toproc)
    ids=ds_toproc(idsptr);
    disp(sprintf('analysis %3.0f (from dataset %2.0f): conditioning the data',idsptr,ids));
    %
    %apply the Laplacian and then the selection montage
    %
    d=cell(1,results{idsptr}.nsegs);
    for iseg=1:results{idsptr}.nsegs
        if (results{idsptr}.laplacian.on==1)
            results{idsptr}.data_laplacianed{iseg}=results{idsptr}.data_recorded{iseg}*results{idsptr}.laplacian.coefs';
            d{iseg}=results{idsptr}.data_laplacianed{iseg}*results{idsptr}.coefs';
        else
            results{idsptr}.data_laplacianed=[];
            d{iseg}=results{idsptr}.data_recorded{iseg}*results{idsptr}.coefs';
        end
    end
    if (results{idsptr}.laplacian.on)
        disp(sprintf(' laplacian applied to %4.0f segments (%s, %3.0f int_nbrs %3.0f edge_nbrs)',...
            results{idsptr}.nsegs,results{idsptr}.laplacian_opts.Laplacian_type,...
            results{idsptr}.laplacian_opts.Laplacian_nbrs_interior,...
            results{idsptr}.laplacian_opts.Laplacian_nbrs_edge));
    end
    disp(sprintf(' montage applied to %4.0f segments',results{idsptr}.nsegs));
    %
    %apply data edits: start time, stop time and exclusions for each segment
    %
    if ~isempty(results{idsptr}.data_edits)
        for iseg=1:results{idsptr}.nsegs
            if all(results{idsptr}.data_edits(iseg,:)==0)
                d{iseg}=[];
            else
                d{iseg}=d{iseg}(results{idsptr}.data_edits(iseg,1):results{idsptr}.data_edits(iseg,2),:);
            end
        end
        disp(sprintf(' data editing applied to %4.0f segments',results{idsptr}.nsegs));
    end
    %
    %subtract trend and/or mean if requested
    %
    if results{idsptr}.xtp_opts.detrend==1
        for iseg=results{idsptr}.segs_analyzed
            d{iseg}=detrend(d{iseg});
        end
        disp(sprintf(' trend and mean subtracted from %4.0f segments',results{idsptr}.nsegs));
    elseif results{idsptr}.xtp_opts.demean==1
        for iseg=results{idsptr}.segs_analyzed
            d{iseg}=detrend(d{iseg},'constant');
        end
        disp(sprintf(' mean  subtracted from %4.0f segments',results{idsptr}.nsegs));
    else
        disp(' trend and mean NOT subtracted.');
    end
    %save for analysis
    results{idsptr}.data_analyzed=d;
    clear d
end
%
% calculate coherogram-- some logic from Shawniqua's xtp_spectramc and xtp_coherencyc
%
for idsptr=1:length(ds_toproc)
    ids=ds_toproc(idsptr);
    disp(sprintf('analysis %3.0f (from dataset %2.0f): doing the coherograms',idsptr,ids));
    %
    cohgram=[];
    cparams=[];
    %
    cparams.pad=results{idsptr}.xtp_opts.chronux_pad;
    cparams.Fs=results{idsptr}.metadata_recorded(1).srate;
    ftbins_unpadded=results{idsptr}.xtp_opts.chronux_winsize*cparams.Fs;
    if (cparams.pad>=0)
        ftbins_padded=2^(cparams.pad+ceil(log(ftbins_unpadded)/log(2)));
    else
        ftbins_padded=ftbins_unpadded;
    end
    cohgram.ftbins_unpadded=ftbins_unpadded;
    cohgram.ftbins_padded=ftbins_padded;
    %
    fmin=cparams.Fs/ftbins_padded;
    fmax=results{idsptr}.xtp_opts.chronux_fmax;
    cohgram.fmin=fmin;
    cohgram.fmax=fmax;
    cohgram.freqs=[0:fmin:fmax];
    %
    cparams.fpass=[0 fmax];
    cparams.err=[results{idsptr}.xtp_opts.chronux_errtype results{idsptr}.xtp_opts.chronux_pval];
    cparams.trialave=0;
    cparams.tapers=[results{idsptr}.xtp_opts.chronux_NW results{idsptr}.xtp_opts.chronux_k];
    cohgram.cparams=cparams;
%
    movingwin=[results{idsptr}.xtp_opts.chronux_winsize results{idsptr}.xtp_opts.chronux_winstep];
    cohgram.movingwin=movingwin;
    %
    ipair=0;
    %generate the pairs; if the builtin list has a list of pairs, use it
    if (results{idsptr}.chansets_builtin==0)
        pairlist=[];
        results{idsptr}.chansets=[];
    elseif ~isfield(chansets{results{idsptr}.chansets_builtin},'pairlist')
        results{idsptr}.chansets=chansets{results{idsptr}.chansets_builtin};
        pairlist=[];
    else
        results{idsptr}.chansets=chansets{results{idsptr}.chansets_builtin};
        pairlist=chansets{results{idsptr}.chansets_builtin}.pairlist;
    end
    %set up list of pairs
    if isempty(pairlist)
        nchans_analyzed=results{idsptr}.nchans_analyzed;
        if (pairlist_deftype==0) %set up a pair list of all pairs
            for ichan=1:nchans_analyzed-1
                for jchan=ichan+1:nchans_analyzed
                    ipair=ipair+1;
                    label_candidate=cat(2,deblank(results{idsptr}.montage_analyzed{ichan}),':',deblank(results{idsptr}.montage_analyzed{jchan}));
                    cohgram.pairs(ipair,:)=[ichan,jchan];
                    cohgram.labels{ipair}=label_candidate;
                end %jchan
            end %ichan
            disp(sprintf(' all %3.0f pairs of channels to be used for coherence',size(cohgram.pairs,1)));
        else %set up a pair list of all chans paired with one selected channel (pairlist_deftype)
            pairwith=pairlist_deftype;
            if (pairwith>nchans_analyzed)
                pairwith=1;
                disp(sprintf(' channels will be paired with channel %3.0f but %3.0f was requested (more than max number of channels).',...
                    pairwith,pairlist_deftype));
            else
                disp(sprintf(' channels will be paired with channel %3.0f as requested.',pairwith));
            end
            ichan=pairwith;
            for jchan=1:nchans_analyzed
                if ~(jchan==pairwith)
                    ipair=ipair+1;
                    label_candidate=cat(2,deblank(results{idsptr}.montage_analyzed{ichan}),':',deblank(results{idsptr}.montage_analyzed{jchan}));
                    cohgram.pairs(ipair,:)=[ichan,jchan];
                    cohgram.labels{ipair}=label_candidate;
                end
            end
        end
    else
        for kpair=1:length(pairlist)
            label_candidate=deblank(pairlist(kpair,:));
            ch1label=[];
            ch2label=[];
            colonpos=findstr(label_candidate,':');
            if (colonpos>0)
                ch1label=label_candidate(1:colonpos-1);
                ch2label=label_candidate(colonpos+1:end);
                ichan=strmatch(upper(ch1label),upper(results{idsptr}.montage_analyzed),'exact');
                jchan=strmatch(upper(ch2label),upper(results{idsptr}.montage_analyzed),'exact');
                if ~isempty(ichan) & ~isempty(jchan)
                    ipair=ipair+1;
                    cohgram.pairs(ipair,:)=[ichan,jchan];
                    cohgram.labels{ipair}=label_candidate;
                end
            end
        end
        disp(sprintf(' %3.0f pairs specified for coherence, %3.0f pairs found',size(pairlist,1),size(cohgram.pairs,1)));      
    end %pairlist empty or not
    clear kpair colonpos ch1label ch2label label_candidate
    %
    cohgram.min_seg_length=movingwin(1)*cparams.Fs;
    results{idsptr}.cohgram=[];
    results{idsptr}.cohgram_surrogates=[];
    %
    %note that surrogates are made in pairs, so first we need to create surrogates for each pair
    %but it is most efficient to do it for all segments at the same time
    %
    for isurr=0:results{idsptr}.nsurr %isurr=0 for real data, isurr>0 for surrogates
        if (isurr>0)
            disp(sprintf('making surrogate %2.0f for %2.0f pairs',isurr,size(cohgram.pairs,1)));
            data_surr=[];
            for ipair=1:size(cohgram.pairs,1)
                surrogate_info=results{idsptr}.surrogate_info{ipair};
                %make twice as many points as needed, so one can take from the middle
                data_surr(:,:,ipair)=surr_corrgau2(surrogate_info.S1,surrogate_info.S2,surrogate_info.S12,surrogate_info.freqs,surrogate_info.dt,...
                    surrogate_info.npts_surr*2);
                %fix the variance
                if (var(data_surr(:,1,ipair)>0))
                    vmult=surrogate_info.ch1var/var(data_surr(:,1,ipair));
                    data_surr(:,1,ipair)=data_surr(:,1,ipair)*sqrt(vmult);
                    cohgram.vmult(1,ipair)=vmult;
                end
                if (var(data_surr(:,2,ipair)>0))
                    vmult=surrogate_info.ch2var/var(data_surr(:,2,ipair));
                    data_surr(:,2,ipair)=data_surr(:,2,ipair)*sqrt(vmult);
                    cohgram.vmult(2,ipair)=vmult;
                end
            end
            cohgram.data_surr=data_surr;
        end
        for iseg=results{idsptr}.segs_analyzed %loop over all segments
            %data range for surrogates
            if (isurr==0)
                data=results{idsptr}.data_analyzed{iseg};
                dsize=size(data,1);
            else
                drange=round(surrogate_info.npts_surr/2)+sum(surrogate_info.npts(1:iseg-1))+[1 surrogate_info.npts(iseg)];
                dsize=drange(2)-drange(1)+1;
            end
            %check that the segment has a minimum length
            if (dsize>=cohgram.min_seg_length)
                if (isurr==0)
                    disp(sprintf(' analysis %2.0f: seg %3.0f, %4.0f pairs of chans, length is %5.0f samples',...
                        idsptr,iseg,size(cohgram.pairs,1),size(data,1)));
                else
                    disp(sprintf(' analysis %2.0f: seg %3.0f, %4.0f pairs of chans, length is %5.0f samples, surr %4.0f, range %5.0f %5.0f',...
                        idsptr,iseg,size(cohgram.pairs,1),size(data,1),isurr,drange));
                end
                tapers=dpss(movingwin(1)*cparams.Fs,cparams.tapers(1),cparams.tapers(2));
                tapers=tapers*sqrt(cparams.Fs); %added 6-24-10
                for ipair=1:size(cohgram.pairs,1); % loop over all pairs
                    if (isurr==0)
                        [C,phi,S12,S1,S2,tcalc,fcalc,confC,phistd,Cerr]=cohgramc(data(:,cohgram.pairs(ipair,1)),data(:,cohgram.pairs(ipair,2)),...
                            movingwin,setfield(cparams,'tapers',tapers));
                    else
                        %data range to be taken from surrogates
                        data_surr_seg=data_surr(drange(1):drange(2),:,ipair);
                        [C,phi,S12,S1,S2,tcalc,fcalc,confC,phistd,Cerr]=cohgramc(data_surr_seg(:,1),data_surr_seg(:,2),...
                            movingwin,setfield(cparams,'tapers',tapers));
                    end
                    cohgram.tapers_fixed=1; %flag added 6-24-10
                    cohgram.C{iseg,ipair}=C;
                    cohgram.phi{iseg,ipair}=phi;
                    cohgram.S12{iseg,ipair}=S12;
                    cohgram.S1{iseg,ipair}=S1;
                    cohgram.S2{iseg,ipair}=S2;
                    cohgram.tcalc{iseg,ipair}=tcalc;
                    cohgram.fcalc{iseg,ipair}=fcalc; %this should match cohgram.freqs
                    cohgram.confC{iseg,ipair}=confC;
                    cohgram.phistd{iseg,ipair}=phistd;
                    cohgram.Cerr{iseg,ipair}=Cerr;
                end %ipair
            else
                disp(sprintf(' skipping segment %3.0f, %4.0f pairs of channels, length is %5.0f samples, min is %5.0f',...
                    iseg,size(cohgram.pairs,1),dsize,cohgram.min_seg_length));
            end
        end %loop over all segments, making pairwise surrogates
        %accumulate spectral data for surrogates
        if (isurr==0) & (results{idsptr}.nsurr>0)
            disp(sprintf('accumulating spectral data to make %2.0f surrogates for each pair',results{idsptr}.nsurr))
            for ipair=1:size(cohgram.pairs,1); % loop over all pairs
                S1concat=[];
                S2concat=[];
                S12concat=[];
                ch1var=[];
                ch2var=[];
                npts=[];
                for iseg=results{idsptr}.segs_analyzed
                    data=results{idsptr}.data_analyzed{iseg};
                    npts(iseg)=size(data,1);
                    %check that the segment has a minimum length
                    if (size(data,1)>=cohgram.min_seg_length)
                        npts(iseg)=size(data,1);
                        S1concat=[S1concat;cohgram.S1{iseg,ipair}];
                        S2concat=[S2concat;cohgram.S2{iseg,ipair}];
                        S12concat=[S12concat;cohgram.S12{iseg,ipair}];
                        ch1var=[ch1var;var(data(:,cohgram.pairs(ipair,1)))];
                        ch2var=[ch2var;var(data(:,cohgram.pairs(ipair,2)))];
                    end
                end
                surrogate_info.S12=mean(S12concat);
                surrogate_info.S1=mean(S1concat);
                surrogate_info.S2=mean(S2concat);
                surrogate_info.ch1var=mean(ch1var);
                surrogate_info.ch2var=mean(ch2var);
                surrogate_info.npts_surr=sum(npts);
                surrogate_info.dt=1./results{idsptr}.metadata_recorded(1).srate;
                surrogate_info.freqs=cohgram.freqs;
                surrogate_info.npts=npts;
                results{idsptr}.surrogate_info{ipair}=surrogate_info;
            end
        end
        %calculate PCA and other statistics, and keep this in cohgram
        %note this is done before some fields are stripped from cohgram
        %
        %========
        %PCA here, some borrowed from parse_specgram_demo
        %========
        %
        NW=cparams.tapers(1);
        %find the indices of the frequencies to sample, spaced by kmax=2*NW-1 so that each is an independent estimate
        fsample_ptrs=[NW:(2*NW-1):length(cohgram.freqs)];
        fsample_ptrs=intersect(intersect(fsample_ptrs,find(cohgram.freqs<=xtp_opts.pca_maxfreq)),find(cohgram.freqs>=xtp_opts.pca_minfreq)); %restrict frequencies if requested
        cohgram.fsample_ptrs=fsample_ptrs;
        pca=[];
        %
        for ipair=1:size(cohgram.pairs,1); % loop over all pairs
            S1concat=[];
            S2concat=[];
            S12concat=[];
            Cconcat=[]; %not yet removed
            for iseg=results{idsptr}.segs_analyzed
                %check that the segment has a minimum length
                data=results{idsptr}.data_analyzed{iseg};
                if (size(data,1)>=cohgram.min_seg_length)
                    S1concat=[S1concat;cohgram.S1{iseg,ipair}];
                    S2concat=[S2concat;cohgram.S2{iseg,ipair}];
                    S12concat=[S12concat;cohgram.S12{iseg,ipair}];
                    Cconcat=[Cconcat;cohgram.C{iseg,ipair}];
                end
            end
            S1concat=S1concat(:,fsample_ptrs);
            S2concat=S2concat(:,fsample_ptrs);
            S12concat=S12concat(:,fsample_ptrs);
            Cconcat=Cconcat(:,fsample_ptrs);
            %adapted from parse_spec_demo
            for ipca=1:12
                pca_subsets=cell(0);
                ntimes=size(S1concat,1);
                switch ipca
                    case {1} %S1
                        x=log10(max(S1concat,xtp_opts.min_pwr));
                        pca_subsets{1}='S1';
                    case {2} %S1 or S2
                        x=log10(max(S2concat,xtp_opts.min_pwr));
                        pca_subsets{1}='S2';
                    case 3 %S1 and S2 together
                        x=log10(max([S1concat,S2concat],xtp_opts.min_pwr));
                        pca_subsets{1}='S1';
                        pca_subsets{2}='S2';
                    case 11
                        x=Cconcat;
                        pca_subsets{1}='Coh';
                    case 12
                        x=atanh(Cconcat);
                        pca_subsets{1}='ZCoh';
                    case 4
                        x=log10(max(abs(S12concat),xtp_opts.min_pwr));
                        pca_subsets{1}='abs(S12)';
                    case 5
                        x=log10(max([S1concat,S2concat,abs(S12concat)],xtp_opts.min_pwr));
                        pca_subsets{1}='S1';
                        pca_subsets{2}='S2';
                        pca_subsets{3}='abs(S12)';
                    case 6 %normalized S1
                        x=S1concat./repmat(mean(S1concat,1),[ntimes 1]);
                        pca_subsets{1}='NS1';
                    case 7 %normalized S2
                        x=S2concat./repmat(mean(S2concat,1),[ntimes 1]);
                        pca_subsets{1}='NS2';
                    case {8,9,10} %normalized, both channels, possibly with cross-spectra
                        xn1=mean(S1concat,1);
                        xn2=mean(S2concat,1);
                        xnx=sqrt(xn1.*xn2);
                        if (ipca==8) | (ipca==10)
                            x1=[S1concat./repmat(xn1,[ntimes 1])];
                            x2=[S2concat./repmat(xn2,[ntimes 1])];
                            pca_subsets{1}='NS1';
                            pca_subsets{2}='NS2';
                            x=[x1,x2];
                        end
                        if (ipca==9) | (ipca==10)
                            xr=real(S12concat)./repmat(xnx,[ntimes 1]);
                            xi=imag(S12concat)./repmat(xnx,[ntimes 1]);
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
                end %switch ipca
                %set up labeling for each range of data used for pca
                pca_label=pca_subsets{1};
                for ip=2:length(pca_subsets)
                    pca_label=cat(2,pca_label,' ',pca_subsets{ip});
                end
                %subtract mean if requested
                if (xtp_opts.pca_submean==1)
                    x=x-repmat(mean(x,1),size(x,1),1);
                    pca_label=cat(2,pca_label,' msub');
                end
                fvals=repmat(cohgram.freqs(fsample_ptrs),1,length(pca_subsets)); %frequency values 
                pca{ipair,ipca}=[];
                if (size(x,1)<=size(x,2))
                    disp(sprintf(' pca on %2.0f for pair %2.0f (%30s) not done because dim(x)= %4.0f %4.0f',ipca,ipair,pca_label,size(x)));
                else
                    pca{ipair,ipca}.pca_subsets=pca_subsets;
                    pca{ipair,ipca}.pca_label=pca_label;
                    pca{ipair,ipca}.fvals=fvals;
                    %
                    %do PCA
                    %
                    [u,s,v]=svd(x,0);
                    %u(:,k) contains timecourse of kth principal component
                    %v(:,k) contains frequency-dependence of kth principal component
                    ds=diag(s);
                    ds=ds(1:length(fsample_ptrs));
                    disp(sprintf(' pca type %2.0f for pair %2.0f (%30s) done. dim(x)= %4.0f %4.0f',ipca,ipair,pca_label,size(x)));
                    %
                    %align PC's so that the frequency-dependence is declining
                    %
                    ifinvert=-sign(fvals*v);
                    v=v.*repmat(ifinvert,size(v,1),1);
                    u=u.*repmat(ifinvert,size(u,1),1);
                    uvkeep=min(size(u,2),xtp_opts.pca_max_uv_keep);
                    pca{ipair,ipca}.u=u(:,[1:uvkeep]);
                    pca{ipair,ipca}.s=diag(s);
                    pca{ipair,ipca}.v=v(:,[1:uvkeep]);
                end %size check
            end %ipca
        end %ipair
        cohgram.pca=pca;
        clear s u v x x1 x2 xr xi xn1 xn2 xnx
        %
        clear NW
        %
        %strip redundant information from cohgram, which can be recovered:
        %  phi=atan2(imag(S12),real(S12));
        %  C=abs(S12)./sqrt(S1.*S2);
        if (xtp_opts.remove_redund_cohdata==1)
            cohgram=rmfield(cohgram,'C');
            cohgram=rmfield(cohgram,'phi');
            if (isurr>0) %time and freq values can be recalculated from non-surrogates
                cohgram=rmfield(cohgram,'tcalc');
                cohgram=rmfield(cohgram,'fcalc');
                if xtp_opts.remove_surr_timeseries
                    cohgram=rmfield(cohgram,'data_surr');
                end
                if ~isempty(xtp_opts.keep_surr_details) & ~ismember(isurr,xtp_opts.keep_surr_details)
                    cohgram=rmfield(cohgram,'S1');
                    cohgram=rmfield(cohgram,'S2');
                    cohgram=rmfield(cohgram,'S12');
                    cohgram=rmfield(cohgram,'phistd');
                    cohgram=rmfield(cohgram,'confC');
                    cohgram=rmfield(cohgram,'Cerr');
                    if isfield(cohgram,'data_surr')
                        cohgram=rmfield(cohgram,'data_surr');
                    end
                end
            end
        end
        %
        if (isurr==0) %save coherogram for real data or surrogates
            results{idsptr}.cohgram=cohgram;
        else
            results{idsptr}.cohgram_surrogates{isurr}=cohgram;
        end
    end %isurr
    clear C phi S12 S1 S2 tcalc fcalc confC phistd Cerr
    clear fmin fmax movingwin ipair data tapers ichan jchan
    %plotting, pca in cofl_anal_demo
end %idsptr
clear ch1var ch2var vmult
clear iseg k
clear isurr keep_surr_details
clear pairlist pass_list surrogate_info data_surr data_surr_seg dsize
disp('suggest saving results in a mat file for later analysis by cofl_anal_demo');

