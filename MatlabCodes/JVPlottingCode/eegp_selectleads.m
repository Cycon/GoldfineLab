function optsnew=eegp_selectleads(channel_names,opts)
% optsnew=eegp_selectleads(channel_names,opts) selects only a subset of leads
%
% channel_names:  cell array of lead names
%
% See also:  EEGP_DEFOPTS.
%
if nargin<1 opts=[]; end
opts=eegp_defopts(opts);
optsnew=rmfield(opts,'EEGP_LEADS');
EEGP_LEADS=[];
for ichan=1:length(channel_names)
    uname=upper(channel_names{ichan});
    if (isfield(opts.EEGP_LEADS,uname))
        EEGP_LEADS=setfield(EEGP_LEADS,uname,getfield(opts.EEGP_LEADS,uname));
    end
end
optsnew.EEGP_LEADS=EEGP_LEADS;
return
