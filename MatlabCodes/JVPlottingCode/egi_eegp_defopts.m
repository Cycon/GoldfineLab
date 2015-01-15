function [defopts]=egi_eegp_defopts(opts,netlabel)
% [defopts]=egi_eegp_defopts(opts,netlabel) 
%
% sets electrode cap geometry and options for calculating montages, neighbors, etc.
%   for egi electrode sets
%
% if opts.EEGP_LEADS exists and netid=eegp, then opts.EEGP_LEADS is used to look up coordinates
%   otherwise a builtin table is used
% netlabel: sensor net id, defaults to 'net128'
%   if empty and opts.netlabel is present, netlabel=opts.netlabel.
%     'net64': egi 64-electrode cap, 10-10 equivalents determined by my tables
%     'net128': egi 128-electrode cap, 10-10 equivalents determined by my tables 
%     'net64t': egi 64-electrode cap, 10-10 equivalents determined by Theresa Teslovich's tables
%     'net128t': egi 128-electrode cap, 10-10 equivalents determined by Theresa Teslovich's tables
%     'eegp': locations listed in eegp_defopts (Easycap locations)
%
%  Vanessa Vogel's table of 10-10 equivalents is more extensive.  The
%  choice of 10-10 equivalents *does not* change the electrode locations.
%
% modified from EEGP_DEFOPTS, using EGI location tables organized by Theresa Teslovich.
%
% EEGP_CENTER is the empiric
%     center of the best-fitting sphere, determined by eegp_findcenter_demo.
% ***this value must be changed if the coordinates are changed.
%
%   See also:  EEGP_DEFOPTS, EEGP_DEFOPTS_EEGLABLOCS, EEGP_FINDCENTER,
%   EGI_NET_GEOM, EGI_ESUBSET.

if nargin<1 opts=[]; end
if nargin<2 netlabel=[]; end
if isempty(netlabel) 
    if isfield(opts,'netlabel')
        netlabel=opts.netlabel;
    else
        netlabel='net128';
    end
end
opts.netlabel=netlabel;
opts=eegp_defopts(opts);
if ~(strcmp(opts.netlabel,'eegp'))
    opts=rmfield(opts,'EEGP_CENTER');
    opts=rmfield(opts,'EEGP_LEADS');
    if strcmp(netlabel,'net64') | strcmp(netlabel,'net128') | strcmp(netlabel,'net64t') | strcmp(netlabel,'net128t')
        [netcoords,netequivs]=egi_net_geom(netlabel);
        ncap=length(fieldnames(netcoords))-1;
        opts.netcoords=netcoords;
        opts.netequivs=netequivs;
        EEGP_LEADS=[];
        EEGP_EQUIV_CHANNO=[];
        for k=1:length(opts.netequivs)
            fieldname=cat(2,'EGI',zpad(k,3));
            if (length(deblank(opts.netequivs{k}))>0)
                EEGP_LEADS.(opts.netequivs{k})=netcoords.(fieldname); %the leads with a 10-10 equivalent
                EEGP_EQUIV_CHANNO.(opts.netequivs{k})=k;
            else
                fn_out=cat(2,'N',zpad(ncap,3),'_',zpad(k,3));
                EEGP_LEADS.(fn_out)=netcoords.(fieldname); %the leads without a 10-10 equivalent
            end
        end
        opts.EEGP_CENTER=[0 0 0];
        opts.EEGP_LEADS=EEGP_LEADS;
        opts.EEGP_EQUIV_CHANNO=EEGP_EQUIV_CHANNO;
    end
    %see egi_findcenter_demo.txt for how to obtain the center values
    switch netlabel
        case {'net64','net64t'}
            opts.EEGP_CENTER=[ 0.000000000  0.398807210 -0.382037930];
        case {'net128','net128t'}
            opts.EEGP_CENTER=[ 0.000000000  0.043692850 -0.042052260];
    end
end
defopts=opts;
return
