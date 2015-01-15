function [polarcoords,optsused]=eegp_polar(leads,opts)
% usage: [polarcoords,optsused]=eegp_polar(leads,opts)
% 
% + 'leads' is either a string or an array of strings, specifying a lead
%
% + holds cartesian coordinates of select EEG leads
% + converts cartesian coords to polar coords for output
%
% opts:  if opts.EEGP_LEADS exists, then it is used to look up coordinates
%   otherwise a builtin table is used, derived from the EASYCAP website:
%   http://www.easycap.de/easycap/e/downloads/M1_XYZ.htm
%   EASTCAP is a Munich-based manufacturer of EEG recording caps.
%
% created on 3/29/10, JV
%

if (nargin<=1), opts=[]; end

opts=eegp_defopts(opts);                                    
optsused=opts;                                 

for k=1:size(leads,1)                              
    lname=deblank(upper(leads(k,:)));
    if isfield(opts.EEGP_LEADS,lname)
        cartcoords(k,:)=getfield(opts.EEGP_LEADS,lname);
        %call eegp_ctop to convert to polar coords
        polarcoords(k,:)=eegp_ctop(cartcoords(k,:),opts);
    else
        polarcoords(k,:)=[NaN NaN NaN];
    end
end

return
