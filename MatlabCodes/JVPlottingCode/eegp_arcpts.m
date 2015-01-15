function [coords,optsused]=eegp_arcpts(lead1,lead2,npts,opts)
% [coords,optsused]=eegp_arcpts(lead1,lead2,npts,opts) gives the
% coordinates of a circular arc between two leads
% 
% lead1: text string for lead 1
% lead2: text string for lead 2
% npts: number of points in between leads (0 just returns endpoints)
%    if npts<0, a chord is returned; defaults to 4
% opts: eegp options
%
% coords: size=[npts+2 3]: the coordinates of an arc between the specified leads
% optsused: optoins used (from defopts)
%
%  See also:  EEGP_CART, EEGP_DEFOPTS.
%
if (nargin<=2) npts=4; end
if (nargin<=3), opts=[]; end
opts=eegp_defopts(opts);
optsused=opts;
%
endpts=[eegp_cart(strvcat(lead1,lead2),opts)];
if (npts==0)
    coords=endpts;
    return
end
spacing=[0:abs(npts)+1]/(abs(npts)+1);
wts=[spacing(:) 1-spacing(:)];
chord=wts*endpts;
if (npts<0)
    coords=chord;
    return
end
% to make a simple arc, we use the directions of the chord points, and a linear change of radii
if (npts>0)
    polarcoords=eegp_ctop(chord,opts);
    polarcoords(:,1)=wts*sqrt(sum(endpts.^2,2));
    coords=eegp_ptoc(polarcoords);
end
return
