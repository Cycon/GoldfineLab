function [polarcoords,optsused]=eegp_polar(leads,opts)
% usage: [polarcoords,optsused]=eegp_polar(leads,opts)
% 
%   leads can be 'Fz', etc, or 'C3-P3', etc. 
%   behavior for bipolar leads is determined by opts.bipolar_loc, default
%     is to return midpoint
%
% input:
%   leads:  a string or an array of strings, specifying a lead
%   opts: options, see eegp_defopts
%
% polarcoords is (r, theta, phi)
%
% See also:  EEGP_CART, EEGP_CTOP.
%

if (nargin<=1), opts=[]; end

opts=eegp_defopts(opts);                                    
optsused=opts;                                 

cartcoords=eegp_cart(leads,opts);
for k=1:size(leads,1)                              
    polarcoords(k,:)=eegp_ctop(cartcoords(k,:),opts);
end
return
