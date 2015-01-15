function [neighbors,optsused]=eegp_neighbors(lead,n,opts)
% usage: [neighbors,optsused]=eegp_neighbors(lead,n,opts)
% 
% + 'lead' is a string specifying a lead
% + 'n' is the number of nearest neighbors you'd like to return, n>0
%  
% + returns the lead name, coordinates and distance between 'lead' and each 
%   of the 'n' nearest neighbors
% + opts.dist_method determines how to calculate the distance:
%       sphere:  spherical approximation, using radius at 'alead' (default)
%       lsphere: local spherical approximation, using geometric mean of 
%                radius at 'alead' and 'bleads'
%       tplane:  tangent plane
%
% created on 4/9/10, JV
%

if (nargin<=2), opts=[]; end

%set default opts
opts=eegp_defopts(opts);
optsused=opts;

%generate list of ALL neighbors and calculate distances for each
leads=fieldnames(opts.EEGP_LEADS);
dists=eegp_dists(lead,char(leads),opts);

%replace self and NaN dists by Inf so that they are never the minimum
for k=1:size(dists,1)
    if abs(dists(k,1))<opts.zerodist_tol dists(k,1)=Inf; end
    if isnan(dists(k,1)) dists(k,1)=Inf; end
end

%sorts distances (ascending), assigns index and removes 'Inf's
[sdists,IX]=sort(dists);
finite=find(sdists<Inf);
sdists=sdists(finite);
IX=IX(finite);

%  Find 'n' nearest neighbors
%
%  NOTE: it is assumed that the list ends at the end of the near ties.
%  near_ties can be smaller than the number of requested distances
%  if shorter distances are within distmatch_tol of the next-longer
%  distance
%
%  the list of distances can be longer than n, if longer distances are
%  near ties
%

%define neighbors struct
neighbors=[];
neighbors.labels=[];

%special case: no finite distances
if isempty(finite)
    neighbors.coords=[];
    neighbors.dists=[];
    neighbors.start_ties=0;
    return
end

%if 'n' exceeds lead list, set 'n' to size of sorted list of all dists
if n>size(sdists,1) n=size(sdists,1); end   

%n is tentative number of leads to return
beyond=sdists(n:end);
if (length(beyond)>1) %check for larger near-ties
    beyond_diffs=diff(beyond);
    nadd=min(find(beyond_diffs>opts.distmatch_tol)); %position of first step that is big enough
    if isempty(nadd) %all are ties
        n=size(sdists,1);
    else
        n=n+nadd-1; %add up to but not including the first step that is big enough
    end
end

neighbors.dists=sdists(1:n);     %generate list of 'n' neighbors

%find lead name and coords for each neighbor
for k=1:n
    neighbors.labels{k,1}=deblank(char(leads(IX(k,:),:)));
    neighbors.coords(k,:)=getfield(opts.EEGP_LEADS,neighbors.labels{k,1});
end

%Starting at the end of the list, look backwards for near-ties
sdiffs=diff(neighbors.dists); %list of successive differences

%Find start of ties
lastbig=max(find(sdiffs>opts.distmatch_tol));
if (isempty(lastbig))
    neighbors.start_ties=min(1,n); %they are all nearly tied
else
    neighbors.start_ties=lastbig+1;
end


return
