function defopts=eegp_defopts_eeglablocsAndy(opts)
%
% set up a default options structure using EEGLAB channel locations
%
%version 2 modified 11/15/11 AMG to use the EGI 129 array. Likely the
%center info is wrong though not sure it matters.
%version 2.1 4/19/12 AMG fixed an error for the EGI129 channel since need
%to remove the first three channels. Also, the code was written to replace
%the default labels that JV used but since EGI is different labels, it
%actually was adding to them! So needed to remove them first.
%Renamed it with Andy at the end so can keep JVs original version. Note
%that for EGI JV uses a different code called egi_eegp_defopts([],'net64')
%or egi_eegp_defopts([],'net128') but gives the output slightly differently
%(actually relabels the EGI channels with 10-10 electrode names).
%version 3 8/6/13 to allow for EGI 32 channel as well as 129. Also removes
%call to the EEGLAB standard locations since found out last year that
%they're not symmetric on some parts of the head.
%
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
if strcmpi(opts,'EGI129') %if telling it it's the EGI129 array from MakeLaplacian
    defopts=rmfield(defopts,'EEGP_LEADS');%added 4/19 since otherwise just added on to the ones already created
    chanlocs = pop_readlocs('GSN-HydroCel-129.sfp');%this file comes with EEGLAB and also is in EGI
    defopts.EEGP_CENTER=[0 0.0437 -0.0421];%4/20/12 this came from code defopts=egi_eegp_defopts([],'net128');
elseif strcmpi(opts,'EGI32')
    defopts=rmfield(defopts,'EEGP_LEADS');%added 4/19 since otherwise just added on to the ones already created
    chanlocs = pop_readlocs('GSN-HydroCel-32.sfp');%this file comes with EEGLAB and also is in EGI
    defopts.EEGP_CENTER=[ 0.000000000  0.000000000 -0.157183000];%from running eegp_findcenter_demo 
end

    chanlocs=chanlocs(4:end);%because the first three are non-data channels. Also assumes that Cz is in the data
    labels={chanlocs.labels}';
     %loc=[chanlocs.X;chanlocs.Y;chanlocs.Z]';%so looks like the loc variable of standard1005.mat
     %can double check channel locations in put back in above line and
     %type:
     %figure;plot3(loc(:,1),loc(:,2),loc(:,3),'*')
    %text(loc(:,1),loc(:,2),loc(:,3),labels)
    
    
    for ii=1:length(labels)
        defopts.EEGP_LEADS.(upper(labels{ii}))=[chanlocs(ii).X chanlocs(ii).Y chanlocs(ii).Z];
    end
    

return
