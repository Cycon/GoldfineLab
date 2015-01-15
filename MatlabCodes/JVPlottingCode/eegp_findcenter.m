function [ctr,rad,dists,names]=eegp_findcenter(ys,zs,opts)
% [ctr,rad,dists,names]=eegp_findcenter(ys,zs,opts) finds the coordinates of the
% center of the best-fitting sphere for a set of channels in EEGP_CHANS, via brute-force
%
% sphere is determined by minimizing the variance of the distances
%
% ctr: coordinates (x,y,z) of the center -- NB: x forced to 0
% rad: the radius of the best sphere
% dists: the distances from the empiric center to the cephalic leads of opts
% names: the names corresonding to dists
%
% ys: search (low, step, hi) for y; [] chooses defaults=[-2 0.01 2]; singleton forces value
% zs: search (low, step, hi) for z; [] chooses defaults=[-4 0.01 4]; singleton forces value
% opts: an options structure set up by eegp_defopts
%
% search is restricted to the limits of the coordinates of the channels
%
% coordinates are read directly from eegp_defopts.EEGP_LEADS, rather than via eegp_cart
% this is so that eegp_cart can be modified to subtract off this empiric center
%
% See also:  EEGP_DEFOPTS, EEGP_CART.
%
if (nargin<=2) opts=[]; end
opts=eegp_defopts(opts);
if isempty(ys) ys=[-2 0.01 2]; end
if isempty(zs) zs=[-4 0.01 4]; end
scat=Inf;
ctr=[0 ys(1) zs(1)];
names=fieldnames(opts.EEGP_LEADS);
c=[];
for iname=1:length(names)
    if ~any(isnan(opts.EEGP_LEADS.(names{iname})))
        c=[c;opts.EEGP_LEADS.(names{iname})];
    end       
end
if (length(ys)<3)
    yvals=ys(1);
else
    yvals=[ys(1):ys(2):ys(3)];
end
if (length(zs)<3)
    zvals=zs(1);
else
    zvals=[zs(1):zs(2):zs(3)];
end
for iy=1:length(yvals)
    for iz=1:length(zvals)
         cadj=c-repmat([0 yvals(iy) zvals(iz)],size(c,1),1);
         d=sqrt(sum(cadj.^2,2));
         rad_new=mean(d);
         scat_new=sum((d-rad_new).^2);
         if (scat_new<scat)
             scat=scat_new;
             rad=rad_new;
             dists=d;
             ctr=[0 yvals(iy) zvals(iz)];
         end
    end
end
return
