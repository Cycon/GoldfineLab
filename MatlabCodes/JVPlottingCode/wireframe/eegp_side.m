function [side,optsused]=eegp_side(leads,opts)
% usage: [side,optsused]=eegp_side(leads,opts)
%
% leads: a string or an array of strings, specifying one or more leads
% opts: eegp options
%
% side: a column of -1 if left, 0 if midline, +1 if right, NaN if not known
% optsused: optoins used (from defopts)
%
%   See also:  EEGP_DEFOPTS, EEGP_CART.
%
if (nargin<=1), opts=[]; end

opts=eegp_defopts(opts);
[cartcoords,optsused]=eegp_cart(leads,opts);
side=sign(cartcoords(:,1));
return
