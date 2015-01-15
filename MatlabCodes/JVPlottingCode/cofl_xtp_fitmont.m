function [names_made,coefs,optsused]=cofl_xtp_fitmont(tneeded,channel_names,opts)
% [names_made,coefs,optsused]=cofl_xtp_fitmont(tneeded,channel_names,opts)
% determines whether a montage can be made from another
% this is typically called by cfl_xtp_makemont
%
% tneeded:  an array (channel_names, lead names) of the desired montage
%  in terms of the leads in the starting montage
% channel_names:  the channel names of the montage to be made
% opts:  options (see cofl_xtp_setdef)
%   opts.vnames is a cell array of the names of the leads, typically parsed
%      by cofl_xtp_makemont
%   opts.vcoefs is a matrix of how the available channels in the
%      starting montage are made from the virtual leads
% 
%  Strategy:  seek to write each row of tneeded in terms of
%   a linear combination of the rows of vcoefs
%
%   See also:  COFL_XTP_MAKEMONT, COFL_XTP_DEMO.
%
tmade=zeros(length(channel_names),length(opts.vnames));
if (nargin<=2) opts=[]; end
opts=cofl_xtp_setdef(opts);
for ichan=1:length(channel_names)
    b=regress(tneeded(ichan,:)',opts.vcoefs');
    tmade(ichan,:)=b'*opts.vcoefs;
    coefs(ichan,:)=b';
end
dists=sqrt(sum((tneeded-tmade).^2,2));
for ichan=1:length(channel_names)
    if dists<opts.tol & any(tneeded(ichan,:)>0)
        names_made{ichan,1}=channel_names{ichan};
    else
        names_made{ichan,1}=opts.nalabel;
        coefs(ichan,:)=0;
        opts.chans_nalist=[opts.chans_nalist,ichan];
        opts.nlabels_missing=opts.nlabels_missing+1;
    end
end
optsused=opts;
return
