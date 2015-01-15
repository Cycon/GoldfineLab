function defopts=cofl_xtp_setdef(opts)
%defopts=cofl_xtp_setdef(opts) sets the default options for cofl routines
%   opts: can be missing or blank
%   opts.mont_mode: type of montage to create
%    'bipolar': default, channel_names are assumed to be something like
%       'T3-PZ','T5-PZ', etc., and the two leads are used to define the
%       channel
%    'passthru': channel names are passed through
%       if channel_names are specified, they should be of form 'T3',
%       and not all channels need be selected
%    'laplacian', etc:  for the future
%       if channel_names are specified, they should be of form 'T3'
%    opts.nalabel: label to use for channels that are not available, defaults to 'N/A'
%    opts.minuschar: character used to indicate a "minus" in bipolar leads, defaults to '-'
%    opts.tol:  tolerance for creating a linear combination via
%       remontaging, defaults to 10^-5
%    opts.casesens: 0 for case-insensitivity (default)
% defopts: default options
%
%   See also:  COFL_XTP_MAKEMONT, COFL_XTP_DEMO.
%
if nargin<1 opts=[]; end
opts=filldefault(opts,'mont_mode','bipolar');
opts=filldefault(opts,'nalabel','N/A');
opts=filldefault(opts,'minuschar','-');
opts=filldefault(opts,'tol',1e-5);
opts=filldefault(opts,'casesens',0);
opts=filldefault(opts,'detrend',1);
opts=filldefault(opts,'demean',1);
opts=filldefault(opts,'remove_redund_cohdata',1); %set to remove redundant coherence data, i.e., C and phi
opts=filldefault(opts,'remove_surr_timeseries',1); %set to remove surrogate time series
%    phi=atan2(imag(S12),real(S12));
%    C=abs(S12)./sqrt(S1.*S2);
opts=filldefault(opts,'nsurr',200);
opts=filldefault(opts,'keep_surr_details',[]); %list of which surrogates to keep details
opts=filldefault(opts,'Laplacian_type','simple'); %alternatives: simple, Hjorth
opts=filldefault(opts,'Laplacian_nbrs_interior',4); %number of neighbors for Laplacian for an interior lead
opts=filldefault(opts,'Laplacian_nbrs_edge',3); %number of neighbors for Laplacian for an edge lead
%
opts=filldefault(opts,'chronux_pad',-1);
opts=filldefault(opts,'chronux_NW',3);
opts=filldefault(opts,'chronux_k',5);
opts=filldefault(opts,'chronux_errtype',2); %0->no EB, 1->theoretical, 2->jackknife
opts=filldefault(opts,'chronux_pval',0.05); 
opts=filldefault(opts,'chronux_fmax',50.);
opts=filldefault(opts,'chronux_winsize',1); %window size in sec
opts=filldefault(opts,'chronux_winstep',1); %window step in sec
%
opts=filldefault(opts,'pca_minfreq',1);
opts=filldefault(opts,'pca_maxfreq',opts.chronux_fmax);
opts=filldefault(opts,'pca_submean',1); %subtract the mean for PCA
opts=filldefault(opts,'min_pwr',10^-10); %minimum nonzero power for plotting or PCA
opts=filldefault(opts,'pca_max_uv_keep',6); %maximum number of PC's to keep (all eigs always kept) 
%
opts=filldefault(opts,'EMGcutoff',Inf); %set lower to exclude trials with EMG above a criterion
%
% Note that EMG cutoff criteria is not yet implemented into processing, since
% (a) processing multiple channels together (for surrogates) would require EMG criteria
% to be met on ALL channels
% (b) EMG criteria would need to be propagated through the montaging
%
defopts=opts;
return

