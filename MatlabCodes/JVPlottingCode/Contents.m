% m-files for MCS project by J. Victor
%
% Analysis of model data.
%   parse_specgram_demo - parse time series as text (Drover output) spectrograms into state
%   surr_corrgau        - make multichannel Gaussian time series with specified power spectra and cross-spectra
%   surr_corrgau2       - make two-channel  Gaussian time series with specified power spectra and cross-spectrum
%   surr_gau            - make Gaussian time series with specified power spectrum
%   surr_test           - test surrgau, surr_corrgau2
%   text2spec_demo      - time series as text (Drover output) to spectra
%   text2specgram_demo  - time series as text (Drover output) to spectrograms
%
% Analysis of patient data.
%   avg_cofl_spec        - average the spectrograms (from cofl_xtp_demo) across time
%   cofl_anal_auto_demo  - runs cofl_anal_demo to make headmaps, saves plots as fig files and .ps, and stats as a text
%   cofl_anal_auto_demob - runs cofl_anal_demo to make band plots of spectral quantities, saves plots as fig files and .ps, and stats as a text
%   cofl_anal_auto_democ - runs cofl_anal_demo to make coherence plots, saves plots as fig files and .ps, and stats as a text
%   cofl_anal_data_make - make a file list, for cofl_anal_auto_demo and cofl_anal_auto_democ
%   cofl_anal_demo      - demonstrate further analysis of results of cofl_xtp_demo, pca, stats
%   cofl_anal_stats     - calculates the statistics for cofl_anal_demo
%   cofl_build_environment - build an xtp environment with an augmented montage database
%   cofl_eegp_makemont_demo - make Laplacian montages, without xtp_build_environment
%   cofl_pcaeiv_demo    - retrieve and analyze eigenvalues from output of cofl_xtp_demo
%   cofl_xtp_demo       - demonstrate spectral analysis of xtp-preprocessed data
%   cofl_xtp_loadcheck  - read and load preprocessed dataset
%   cofl_xtp_fitmont    - determine whether a montage can be made from the available channels
%   cofl_xtp_makemont_demo   - test cofl_xtp_makemont
%   cofl_xtp_makemont   - make a montage coefficient matrix
%   cofl_xtp_setdef     - set up the default options for cofl modules
%   cofl_xtp_setup_clnd  - make setup files (data file names and channel sets) for cofl_xtp_demo, clnd analyses
%   cofl_xtp_setup_devel - make setup files (data file names and channel sets) for cofl_xtp_demo, development mode
%   cofl_xtp_setup_long  - make setup files (data file names and channel sets) for cofl_xtp_demo, longitudinal analyses
%
%  EEG lead positions (with Theresa Teslovich)
%   eegp_arcpts          - cartesian coords of an arc of points between two leads
%   eegp_cart            - cartesian coords of a lead
%   eegp_ctop            - convert cartesian to polar lead coord
%   eegp_defopts         - set options for distances and standard lead coordinates
%   eegp_defopts_eeglablocs - variant of eegp_defopts to load eeglab electrode locations
%   eegp_dists           - distances from one lead to several
%   eegp_fitparab        - fit a parabolic voltage function to lead positions in the tangent plane
%   eegp_fitparab_util   - utility for eegp_fitparab
%   eegp_findcenter      - find the center of the best-fitting sphere; use this to set up EEGP_CENTER in eegp_defopts
%   eegp_findcenter_demo - demonstrate eegp_findcenter
%   eegp_isinterior      - determine if a lead is an interior lead
%   eegp_isinterior_demo - demonstrate eegp_isinterior
%   eegp_makechanlocs    - create a chanlocs structure for use by eeglab's topoplot
%   eegp_neighbors       - finds nearest neighbor leads, along with near-ties
%   eegp_selectleads     - select a subset of leads from an options structure defined by eegp_defopts
%   eegp_polar           - polar coords of a lead
%   eegp_ptoc            - convert polar to cartesian lead coord
%   eegp_side            - indicate which side a lead is on
%   eegp_tpcoord         - coordintes in tangent plane
%   eegp_wireframe       - draw a head with a wireframe between specified leads
%   eegp_wireframe_data  - draws pairwise data on a head wireframe
%
% Demos.
%   coh_demo            - make examples of signals with low and high coherence
%   mcsds_demo          - demonstrate mcsds_run
%   mcsds_run           - run sims of a simple dynamical system (respiratory control), show VFs
%   mtnormalize_demo    - demonstrate normalization of spectra and spectrograms
%

%   Copyright (c) 2009, 2010 by J. Victor


