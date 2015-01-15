function defopts=eegp_defopts_eeglablocs(opts)
%
% set up a default options structure using EEGLAB channel locations
%
% EEGP_CENTER determined as follows (this runs once, and initially
% EEGP_CENTER has value assigned by eegp_defopts, but this is ignored)
%
% eegp_opts=eegp_defopts_eeglablocs;
% eegp_opts
% eegp_opts = 
%        lowradius_tol: 1.0000e-010
%        distmatch_tol: 1.0000e-003
%         zerodist_tol: 1.0000e-005
%        interior_nbrs: 8
%    interior_circfrac: 0.6000
%      undefined_theta: 0
%        undefined_phi: 0
%      standard_radius: []
%          dist_method: 'sphere'
%       eeglab_edgeang: 1.1781
%          bipolar_loc: 0
%          EEGP_CENTER: [0 -0.1753 3.5778]
%           EEGP_LEADS: [1x1 struct]
%        EEGP_NC_LEADS: [1x1 struct]
%>> eegp_findcenter_demo
%Enter iters (range: 1 to 10, default= 8):
%iter  1 step 10.0000000000:  ctr [ 0.000000000 -20.000000000  0.000000000] rad 97.7570203 scat 8.9199932
%iter  2 step 1.0000000000:  ctr [ 0.000000000 -17.000000000 -1.000000000] rad 97.9250430 scat 8.7506150
%iter  3 step 0.1000000000:  ctr [ 0.000000000 -17.400000000 -1.000000000] rad 97.9283341 scat 8.7471318
%iter  4 step 0.0100000000:  ctr [ 0.000000000 -17.380000000 -1.040000000] rad 97.9369506 scat 8.7471130
%iter  5 step 0.0010000000:  ctr [ 0.000000000 -17.384000000 -1.043000000] rad 97.9376487 scat 8.7471126
%iter  6 step 0.0001000000:  ctr [ 0.000000000 -17.383500000 -1.042500000] rad 97.9375339 scat 8.7471126
%iter  7 step 0.0000100000:  ctr [ 0.000000000 -17.383530000 -1.042470000] rad 97.9375276 scat 8.7471126
%iter  8 step 0.0000010000:  ctr [ 0.000000000 -17.383525000 -1.042473000] rad 97.9375282 scat 8.7471126
%
%   See also:  EEGP_DEFOPTS, EEGP_FINDCENTER.
%
if nargin<1 opts=[]; end
defopts=eegp_defopts;
load standard1005.mat;
for ii=1:length(labels)
    defopts.EEGP_LEADS.(upper(labels{ii}))=loc(ii,:);
end
defopts.EEGP_CENTER=[ 0.000000000 -17.383525000 -1.042473000];
return
