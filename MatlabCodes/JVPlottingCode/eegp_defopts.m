function [defopts]=eegp_defopts(opts)
% usage: [defopts]=eegp_defopts(opts) 
%
% + sets default options: low radius tolerance, undefined values, and 
%   default electrode coordinates
%
% + opts:  if opts.EEGP_LEADS exists, then it is used to look up coordinates
%   otherwise a builtin table is used, derived from the EASYCAP website:
%   http://www.easycap.de/easycap/e/downloads/M1_XYZ.htm
%   EASTCAP is a Munich-based manufacturer of EEG recording caps.
%
% created on 3/29/10, JV
% modified on 5/18/10, JV, to set interior_nbrs to 8, as this is necessary
% modified on 5/18/10, JV, to add a EEGP_CENTER, this is the empiric
%     center of the best-fitting sphere, determined by eegp_findcenter_demo.
% ***this value must be changed if the coordinates are changed.
%   for   EMU40 +18 headbox to consider FC5, FC6, FZ as interior.
%
%   See also:  EEGP_DEFOPTS_EEGLABLOCS, EEGP_FINDCENTER.

if nargin<1 opts=[]; end

%set tolerance for low radii to zero] 
if ~isfield(opts,'lowradius_tol') opts.lowradius_tol=10^-10; end
%set tolerance for distance ties
if ~isfield(opts,'distmatch_tol') opts.distmatch_tol=10^-3; end
%set tolerance for zero distance
if ~isfield(opts,'zerodist_tol') opts.zerodist_tol=10^-5; end
%set an empiric coordinate center

%set criteria for interior point:  the total angle supported by a criterion
%number of neighbors must exceed circfrac (as a part of a circle)
if ~isfield(opts,'interior_nbrs') opts.interior_nbrs=8; end %5/18/11, had been 6
if ~isfield(opts,'interior_circfrac') opts.interior_circfrac=0.6; end

%set theta and phi to zero where undefined
if ~isfield(opts,'undefined_theta') opts.undefined_theta=0; end
if ~isfield(opts,'undefined_phi') opts.undefined_phi=0; end

%if specified, standard radius gives the radius of each coordinate
if ~isfield(opts,'standard_radius') opts.standard_radius=[]; end       
if ~isfield(opts,'dist_method') opts.dist_method='sphere'; end
%can also be lsphere (local spherical) or tplane (tangent plane) or chord (chord)

%set the opening-up angle that maps to "plotrad=0.5" (edge of default head) in eeglab topoplot
if ~isfield(opts,'eeglab_edgeang') opts.eeglab_edgeang=3*pi/8; end %used by eegp_makechanlocs

%set up how bipolar labels are localized
if ~isfield(opts,'bipolar_loc') opts.bipolar_loc=0; end %0->midpoint, 1->first channel, 2->second channel, -1->NaN
%
if ~isfield(opts,'EEGP_CENTER')
    opts.EEGP_CENTER=[ 0.000000000 -0.175280000  3.577810000];
end
%
%set default electrode coordinates, unless otherwise specified
if ~isfield(opts,'EEGP_LEADS') 
    EEGP_LEADS.FP1 = [-2.7,8.6,3.6];
    EEGP_LEADS.FP2 = [2.7,8.6,3.6];
    EEGP_LEADS.F3 = [-4.7,6.2,8];
    EEGP_LEADS.F4 = [4.7,6.2,8];
    EEGP_LEADS.C3 = [-6.1,0,9.7];
    EEGP_LEADS.C4 = [6.1,0,9.7];
    EEGP_LEADS.P3 = [-4.7,-6.2,8];
    EEGP_LEADS.P4 = [4.7,-6.2,8];
    EEGP_LEADS.O1 = [-2.7,-8.6,3.6];
    EEGP_LEADS.O2 = [2.7,-8.6,3.6];
    EEGP_LEADS.F7 = [-6.7,5.2,3.6];
    EEGP_LEADS.F8 = [6.7,5.2,3.6];
    EEGP_LEADS.T3 = [-7.8,0,3.6];
    EEGP_LEADS.T4 = [7.8,0,3.6];
    EEGP_LEADS.T5 = [-6.7,-5.2,3.6];
    EEGP_LEADS.T6 = [6.7,-5.2,3.6];
    EEGP_LEADS.FZ = [0,6.7,9.5];
    EEGP_LEADS.CZ = [0,0,12];
    EEGP_LEADS.PZ = [0,-6.7,9.5];
    EEGP_LEADS.F1 = [-2.4,6.5,9];
    EEGP_LEADS.F2 = [2.4,6.5,9];
    EEGP_LEADS.FC1 = [-3,3.3,11];
    EEGP_LEADS.FC2 = [3,3.3,11];
    EEGP_LEADS.C1 = [-3.4,0,11.6];
    EEGP_LEADS.C2 = [3.4,0,11.6];
    EEGP_LEADS.CP1 = [-3,-3.2,11];
    EEGP_LEADS.CP2 = [3,-3.2,11];
    EEGP_LEADS.P1 = [-2.4,-6.5,9];
    EEGP_LEADS.P2 = [2.4,-6.5,9];
    EEGP_LEADS.AF3 = [-3.4,7,6.4];
    EEGP_LEADS.AF4 = [3.4,7,6.4];
    EEGP_LEADS.FC3 = [-5.5,3.2,9.4];
    EEGP_LEADS.FC4 = [5.5,3.2,9.4];
    EEGP_LEADS.CP3 = [-5.3,-3.2,9.4];
    EEGP_LEADS.CP4 = [5.3,-3.2,9.4];
    EEGP_LEADS.PO3 = [-3.4,-7.9,6.4];
    EEGP_LEADS.PO4 = [3.4,-7.9,6.4];
    EEGP_LEADS.F5 = [-5.8,5.9,5.8];
    EEGP_LEADS.F6 = [5.8,5.9,5.8];
    EEGP_LEADS.FC5 = [-5.5,3.2,6.6];
    EEGP_LEADS.FC6 = [5.5,3.2,6.6];
    EEGP_LEADS.C5 = [-7.4,0,6.7];
    EEGP_LEADS.C6 = [7.4,0,6.7];
    EEGP_LEADS.CP5 = [-7.2,-2.7,6.6];
    EEGP_LEADS.CP6 = [7.2,-2.7,6.6];
    EEGP_LEADS.P5 = [-5.8,-5.9,5.8];
    EEGP_LEADS.P6 = [5.8,-5.9,5.8];
    EEGP_LEADS.AF7 = [-5,7.2,3.6];
    EEGP_LEADS.AF8 = [5,7.2,3.6];
    EEGP_LEADS.FT7 = [-7.6,2.8,3.6];
    EEGP_LEADS.FT8 = [7.6,2.8,3.6];
    EEGP_LEADS.TP7 = [-7.6,-2.8,3.6];
    EEGP_LEADS.TP8 = [7.6,-2.8,3.6];
    EEGP_LEADS.PO7 = [-5,-7.2,3.6];
    EEGP_LEADS.PO8 = [5,-7.2,3.6];
    EEGP_LEADS.F9 = [-6,4.8,0];
    EEGP_LEADS.F10 = [6,4.8,0];
    EEGP_LEADS.FT9 = [-6.9,2.5,0];
    EEGP_LEADS.FT10 = [6.9,2.5,0];
    EEGP_LEADS.TP9 = [-7.3,-2.5,0];
    EEGP_LEADS.TP10 = [7.3,-2.5,0];
    EEGP_LEADS.P9 = [-6.3,-4.8,0];
    EEGP_LEADS.P10 = [6.3,-4.8,0];
    EEGP_LEADS.PO9 = [-4.7,-6.7,0];
    EEGP_LEADS.PO10 = [4.7,-6.7,0];
    EEGP_LEADS.O9 = [-2.5,-8,0];
    EEGP_LEADS.O10 = [2.5,-8,0];
    EEGP_LEADS.FPZ = [0,9,3.6];
    EEGP_LEADS.AFZ = [0,8.3,6.9];
    EEGP_LEADS.FCZ = [0,3.4,11.3];
    EEGP_LEADS.CPZ = [0,-3.4,11.3];
    EEGP_LEADS.POZ = [0,-8.3,6.9]; %fixed (Z added) Sept 1 2010 JV
    EEGP_LEADS.OZ = [0,-9,3.6];
    EEGP_LEADS.IZ = [0,-8.6,0];
    EEGP_LEADS.REF = [NaN,NaN,NaN];       %noncephalic lead
    EEGP_LEADS.A1 = [NaN,NaN,NaN];        %noncephalic lead
    EEGP_LEADS.A2 = [NaN,NaN,NaN];        %noncephalic lead
    EEGP_LEADS.EKG = [NaN,NaN,NaN];       %noncephalic lead
    EEGP_LEADS.EMG = [NaN,NaN,NaN];       %noncephalic lead
    
    opts.EEGP_LEADS=EEGP_LEADS;
end

%classify noncephalic eeg leads
if ~isfield(opts,'EEGP_NC_LEADS')
    EEGP_NC_LEADS.REF = [NaN,NaN,NaN];
    EEGP_NC_LEADS.A1 = [NaN,NaN,NaN];
    EEGP_NC_LEADS.A2 = [NaN,NaN,NaN];
    EEGP_NC_LEADS.EKG = [NaN,NaN,NaN];
    EEGP_NC_LEADS.EMG = [NaN,NaN,NaN];
    
    opts.EEGP_NC_LEADS=EEGP_NC_LEADS;
end

defopts=opts;
return
