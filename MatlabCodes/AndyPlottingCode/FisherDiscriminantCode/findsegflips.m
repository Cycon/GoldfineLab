function [segflips,aux,opts_used]=findsegflips(tags,whichsegs,opts)
% [segflips,aux,opts_used]=findsegflips(tags,whichsegs,opts) determines
% a random list of label "flips" to be applied to data segments, for 
% shuffle-like significance testing of a classifier
%
%  Finds ways to reverse the group assignment of a randomly chosen
%   set of segments, so as to preserve, within a tolerance, the total
%   number of trials within each group
%
% This is effectively a knapsack problem, so a Monte Carlo method is used.
%
%  tags:  [1 ntrials]: 1's and 2's, indicating the group assignment of each trial
%  whichsegs:[1 ntrials]:  the segment containing each trial
%
%  opts.nflips: number of flips to seek
%  opts.nflips_maxtries: maximum number of tries to find flips
%  opts.nflips_tol:  tolerance on change in number of trials assigned to each group
%
%  segflips: [nflips, nsegs]:  +1 if a segment is flipped, 0 if a segment is not flipped
%  aux: auxiliary outputs
%  opts_used: options used
%
%  See also:  FISHERDISC, FISHERDISC_DEF.
%
if (nargin<=2)
    opts=[];
end
opts=fisherdisc_def(opts);
opts_used=opts;
aux=[];
segflips=[];
errormsg=[];
%
usegs=unique(whichsegs); %list of unique segments
maxsegs=max(usegs);
for iseg=1:maxsegs
    imbal(iseg)=sum(tags(find(whichsegs==iseg))==2)-sum(tags(find(whichsegs==iseg))==1);
    nocc(iseg)=sum(whichsegs==iseg);
end
unocc=find(nocc==0);
%
% Monte Carlo method
%
nfound=0;
ntries=0;
aux.flip_imbal=[];
candidate=zeros(1,maxsegs);
while (nfound<opts.nflips) & (ntries<opts.nflips_maxtries)
    ntries=ntries+1;
    candidate=round(rand(1,maxsegs));
    candidate(unocc)=0;%never flip an unoccupied segment
    flip_imbal=sum(candidate.*imbal);
    if (abs(flip_imbal)<=opts.nflips_tol)
        nfound=nfound+1;
        segflips(nfound,:)=candidate;
        aux.flip_imbal(nfound,1)=flip_imbal;
    end
end
if (nfound<opts.nflips)
    errormsg=sprintf('%5.0f flips requested, but only %5.0f found in %5.0f tries.',...
        opts.nflips,nfound,opts.nflips_maxtries);
end
aux.errormsg=errormsg;
aux.nfound=nfound;
aux.ntries=ntries;
aux.usegs=usegs;
aux.maxsegs=maxsegs;
aux.imbal=imbal;
aux.nocc=nocc;
aux.flips_unique=unique(segflips,'rows');
aux.msg=sprintf('%5.0f flips requested, %5.0f found (%5.0f unique) in %5.0f tries (%5.0f allowed).',...
        opts.nflips,nfound,size(aux.flips_unique,1),ntries,opts.nflips_maxtries);
return;
end


