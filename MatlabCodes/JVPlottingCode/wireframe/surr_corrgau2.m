function [t_surr,SX_surr,f_surr,z_surr,optsused]=surr_corrgau2(S1,S2,S12,f,dt,npts,nexamps,opts)
% [t_surr,SX_surr,f_surr,z_surr,optsused]=_surr_corrgau2(S1,S2,S12,f,dt,npts,nexamps,opts) creates
% surrogate twochannel correlated Gaussian time series with a specified spectrum
%   since ifft isused, this is fastest if npts is a power of 2
%
%   NOTE (May 5, 2010):  there may be a normalization problem.  In surr_test, the normalization is accurate.
%    However, in cofl_xtp_demo, the overall variance of the surrogate signals is wrong,
%    even thought the spectral shape is correct.  So there, variance is adjusted by hand.
%    It is unclear where the normalization problem arises, since in cofl_xtp_demo,
%    the spectra are calculated by coherencyc, averaged across segments, etc
%
% S1(length(f)): spectrum on ch 1
% S2(length(f)): spectrum on ch 2
% S12(length(f)): cross-spectrum
%
% for other details see surr_corrgau.
%
if (nargin<=6) nexamps=1; end
if (nargin<=7) opts=[]; end
%
SX=zeros(length(S1),2,2);
SX(:,1,1)=S1(:);
SX(:,2,2)=S2(:);
SX(:,1,2)=S12(:);
SX(:,2,1)=conj(S12(:));
%
[t_surr,SX_surr,f_surr,z_surr,optsused]=surr_corrgau(SX,f,dt,npts,nexamps,opts);
%
return

