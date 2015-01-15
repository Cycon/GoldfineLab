function [coefs,names_made,optsused,eegpused]=cofl_xtp_makemont(lead_list,channel_names,opts,eegp_opts)
% [coefs,names_made,optsused,eegpused]=cofl_xtp_makemont(lead_list,channel_names,opts,eegp_opts)
%  creates a montage from a set of leads
%
% lead_list:  a vertical cell array of text labels of the headbox leads
% channel_names: a vertical cell array of text labels for the montage to be made
%    if it is empty, then it is set equal to lead_list
% opts: options for xtp routines
%    opts.mont_mode='passthrough','bipolar', or 'Laplacian'
%       in Laplacian mode, opts.Laplacian_type='simple' or 'Hjorth' 
%       or 'HjorthAbs' or 'HjorthAbsRescaled' (last two added 16 May 11)
%          HjorthAbs is like Hjorth, but divided by mean of squared dists to neighbors
%          HjorthAbsRescaled is like HjorthAbs, but entire matrix rescaled to max of 1
%         (cf. discussions with Andy Goldfine)
%
%       distances are calculated according to options set in eegp_opts,
%       including distances on sphere (default), local sphere, or tangent plane
%    see cofl_xtp_setdef for details on other params
% eegp_opts: options for eegp routines (EEG lead positions and distances)
%    used only for opts.mont_mode='Laplacian'
%    see eegp_defopts for details
%
% if called with no input arguments, returns a list of available Laplacian types
%
%  coefs:  an array, size=[length(channel_names),length(lead_list)], indicating
%    how to create each channel from a linear combination of the leads
%    If a channel cannot be made, coefs(ichan,:)=0
%  names_made: vertical cell array of names of channels made
%    opts.nalabel if channel cannot be calculated from lead list
%    but otherwise should match channel_names
%  optsused:  options used, error messages, list of channels made
%  eegpused:  eegp options used, only returned if mont_mode='Laplacian' or if eegp_opts is explicitly passed
%
%   See also:  COFL_XTP_DEMO, COFL_XTP_FITMONT, COFL_XTP_SETDEF, COFL_XTP_MAKEMONT_DEMO, EEGP_DEFOPTS.
%
%   AG: this is the updated version 5/16/11 with Hjorth Abs and
%   HjorthAbsRescaled. These new versions take into account the distance
%   between the lead and the ones being subtracted out so that some don't
%   end up with higher amplitudes than others if all leads are far away
%   (like FC5). HjorthAbsRescaled brings all the values to a normal range.
%
if (nargin==0) %special case to return available Laplacian types
    coefs={'simple','Hjorth','HjorthAbs','HjorthAbsRescaled'};
    return
end
if (nargin<=2) opts=[]; end
opts=cofl_xtp_setdef(opts);
%
if (nargin<=3) eegp_opts=[]; end
if strcmp(opts.mont_mode,'Laplacian') | ~isempty(eegp_opts)
    eegp_opts=eegp_defopts(eegp_opts);
end
%
if isempty(channel_names)
    channel_names=lead_list;
end
coefs=zeros(length(channel_names),length(lead_list));
names_made=cell(length(channel_names),1);
opts.errmsg=[];
opts.chans_nalist=[]; %list of channels not available
opts.nlabels_duplicates=0;
opts.nlabels_missing=0;
%
% if bipolar mont_mode, then form a matrix that expresses the 'leads'
% in terms of a virtual montage.  this will enable conversion of one
% bipolar montage to another, etc.
if strcmp(opts.mont_mode,'bipolar');
    vnames=cell(0);
    for ilead=1:length(lead_list)
        r=lead_list{ilead};
        while length(r)>0
            [t,r]=strtok(r,opts.minuschar);
            r=r(2:end);  %strip the token
            if (opts.casesens==0)
                t=upper(t);
            end
            vnames{end+1}=t;
        end
        vnames=unique(vnames);
    end
    opts.vnames=vnames;
    %now determine how the leads are built from the virtual names
    vcoefs=zeros(length(lead_list),length(vnames));
    for ilead=1:length(lead_list)
        wheredash=find(lead_list{ilead}==opts.minuschar);
        vn=cell(0);
        if isempty(wheredash)
            vn{1}=lead_list{ilead};
        else
            vn{1}=lead_list{ilead}(1:wheredash(1)-1);
            vn{2}=lead_list{ilead}(wheredash(1)+1:end);
        end
        for ivn=1:length(vn)
            if (opts.casesens==0)
                vn{ivn}=upper(vn{ivn});
            end
            matches=strmatch(vn{ivn},vnames,'exact');
            if length(matches)==1
                if (ivn==1) vcoefs(ilead,matches)= 1; end
                if (ivn==2) vcoefs(ilead,matches)=-1; end
            else
                warning('cannot parse the input montage');
            end
        end
    end
    opts.vcoefs=vcoefs;
    opts.vcoefs_rank=rank(vcoefs);
    if (opts.vcoefs_rank<length(lead_list))
        warning('lead list appears to have duplicates or linear dependencies.');
    end
end
switch opts.mont_mode
    case 'Laplacian'
        %for finding interior leads and nearest neighbors, adjust eegp_opts so that it only includes the leads we have
        eegp_opts_restr=eegp_selectleads(channel_names,eegp_opts);
        %
        for ichan=1:length(channel_names)
            if (opts.casesens==0)
                matches=strmatch(upper(channel_names{ichan}),upper(lead_list),'exact');
            else
                matches=strmatch(channel_names{ichan},lead_list,'exact');
            end
            if (isempty(matches)) %missing
                names_made{ichan,1}=opts.nalabel;
                opts.chans_nalist=[opts.chans_nalist,ichan];
                opts.nlabels_missing=opts.nlabels_missing+1;
            elseif length(matches)>1 %duplicates
                names_made{ichan,1}=opts.nalabel;
                opts.chans_nalist=[opts.chans_nalist,ichan]; 
                opts.nlabels_duplicates=opts.nlabels_duplicates+1;
            else %just one match -- so find nearest neighbors
                names_made{ichan,1}=channel_names{ichan};
                match_central=matches;
                %find other coefficients
                ifinterior=eegp_isinterior(channel_names{ichan},eegp_opts_restr); %will later have to calculate whether interior or not
                if (ifinterior)
                    neighbors=eegp_neighbors(channel_names{ichan},opts.Laplacian_nbrs_interior,eegp_opts_restr);
                else
                    neighbors=eegp_neighbors(channel_names{ichan},opts.Laplacian_nbrs_edge,eegp_opts_restr);
                end
                %disp(channel_names{ichan});
                %disp(neighbors);
                %disp(neighbors.labels)
                matchno=[];
                for inbr=1:size(neighbors.labels)
                    if (opts.casesens==0)
                        matches=strmatch(upper(neighbors.labels{inbr}),upper(lead_list),'exact');
                    else
                        matches=strmatch(neighbors.labels{inbr},lead_list,'exact');
                    end
                    if (isempty(matches))
                        matchno(inbr)=0;
                    else
                        matchno(inbr)=min(matches);
                    end
                end
                %
                cvec=zeros(1,size(coefs,2)); %initialize coefficient vector
                if all(matchno==0) %are there any matching neighbors?
                    names_made{ichan,1}=opts.nalabel;
                    opts.chans_nalist=[opts.chans_nalist,ichan];
                    opts.nlabels_missing=opts.nlabels_missing+1;
                else
                    cvec(match_central)=1; %if there are matching neighbors, start with the central channel
                end
                %now add coefs for the matching neighbors
                switch opts.Laplacian_type
                    case 'simple'
                        if (any(matchno>0))
                            for inbr=1:size(neighbors.labels)
                                if matchno(inbr)>0
                                    cvec(matchno(inbr))=-1./sum(double(matchno>0));
                                end
                            end
                        end
                    case 'Hjorth'
                        if (any(matchno>0))
                            neighdists=neighbors.dists(find(matchno>0));
                            for inbr=1:size(neighbors.labels)
                                if matchno(inbr)>0
                                    cvec(matchno(inbr))=-1./neighbors.dists(inbr)/sum(1./neighdists);
                                end
                            end
                        end
                    case {'HjorthAbs','HjorthAbsRescaled'}
                        if (any(matchno>0))
                            neighdists=neighbors.dists(find(matchno>0));
                            neigh_msq=mean(neighdists.^2);
                            cvec(match_central)=1/neigh_msq;
                            for inbr=1:size(neighbors.labels)
                                if matchno(inbr)>0
                                    cvec(matchno(inbr))=-1./neighbors.dists(inbr)/sum(1./neighdists)/neigh_msq;
                                end
                            end
                        end
                end
                %matchno
                %cvec
                coefs(ichan,:)=cvec; %the match
            end 
        end
        if strcmp(opts.Laplacian_type,'HjorthAbsRescaled')
            coefs=coefs/max(abs(coefs(:)));
        end
    case 'passthru'
        for ichan=1:length(channel_names)
            if (opts.casesens==0)
                matches=strmatch(upper(channel_names{ichan}),upper(lead_list),'exact');
            else
                matches=strmatch(channel_names{ichan},lead_list,'exact');
            end
            if (isempty(matches)) %missing
                names_made{ichan,1}=opts.nalabel;
                opts.chans_nalist=[opts.chans_nalist,ichan];
                opts.nlabels_missing=opts.nlabels_missing+1;
            elseif length(matches)>1 %duplicates
                names_made{ichan,1}=opts.nalabel;
                opts.chans_nalist=[opts.chans_nalist,ichan]; 
                opts.nlabels_duplicates=opts.nlabels_duplicates+1;
            else %just one match
                names_made{ichan,1}=channel_names{ichan};
                coefs(ichan,matches)=1; %the match
            end 
        end
    case 'bipolar'
        %find the matrix needed to transform the virtual channels into the needed montage
        tneeded=zeros(length(channel_names),length(opts.vnames));
        for ichan=1:length(channel_names)
            wheredash=findstr(channel_names{ichan},opts.minuschar);
            vn=cell(0);
            if ~length(wheredash)==1
                warning(sprintf('makemont %s mode: cannot parse requested channel name %s',...
                    opts.mont_mode,channel_names{ichan}));...
            else
                vn{1}=channel_names{ichan}(1:wheredash-1);
                vn{2}=channel_names{ichan}(wheredash+1:end);
            end
            %look vn{1} and vn{2} up in vnames and create target vector
            tvec=zeros(1,length(opts.vnames));
            ifok=1;
            if ~isempty(vn)
                for im=1:2
                    if (opts.casesens==0)
                        vn{im}=upper(vn{im});
                    end
                    matches=strmatch(vn{im},opts.vnames,'exact');
                    if (length(matches)==1)
                        tvec(matches)=3-2*im;
                    else
                        warning(sprintf('makemont %s mode: cannot find a lead (%s) required for %s',...
                            opts.mont_mode,vn{im},channel_names{ichan}));
                        ifok=0;
                    end
                end
                if (ifok==1)
                    tneeded(ichan,:)=tvec;
                end
            end
        end
        %find how closely one can achieve this via regression
        [names_made,coefs,opts]=cofl_xtp_fitmont(tneeded,channel_names,opts);
    otherwise
        opts.errmsg=sprintf('makemont %s mode: unknown mode.',opts.mont_mode);
        for ichan=1:length(channel_names)
            names_made{ichan,1}=opts.nalabel;
            opts.chans_nalist=[opts.chans_nalist,ichan]; 
        end
end %switch
if (length(opts.chans_nalist)>0)
    opts.errmsg=sprintf('makemont %s mode: %3.0f channels not found, %3.0f channels duplicated.',opts.mont_mode,...
        opts.nlabels_missing,opts.nlabels_duplicates);
end
%
optsused=opts;
eegpused=eegp_opts;
return
