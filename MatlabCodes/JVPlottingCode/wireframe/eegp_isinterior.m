function [isinterior,optsused,neighbors,fraccircs]=eegp_isinterior(lead,opts)
% usage: [isinterior,optsused,neighbors,fraccircs]=eegp_isinterior(lead,opts)
% 
% + 'lead' is a string specifying a lead
% + opts.interior_nbrs and opts.interior_circfrac determins
%   the criteria for being on the inside:
%   the angle subteneded by nbrs must exceeld circfrac of a circle
% neighbors are the neighbors returned by eegp_neighbors
% fraccircs are the angular positions of each neighbor, as a fraction of a circle
%   (returned only if there are 3 or more neighbors), so taht the tangent
%   plane is unambiguous
%
% created on 5/7/10, JV
%
% as a quick demo which makes a 3-d plot with the interior leads red, see EEGP_ISINTERIOR_DEMO
%

if (nargin<=1), opts=[]; end

%set default opts
opts=eegp_defopts(opts);
optsused=opts;
%assume not exterior
isinterior=0;
neighbors=eegp_neighbors(lead,opts.interior_nbrs,opts);
nn=length(neighbors.labels);
fraccircs=[];
if nn<3
    return
end
%mycoord=eegp_cart(lead,opts); %don't need this since tpcoords centers at 0
tpcoords=eegp_tpcoords(lead,char(neighbors.labels),opts);
% have to reduce this to 2-d, and then find angles in the plane
[u,s,v]=svd(tpcoords,0);
plane_coords=u(:,[1:2])*s(1:2,1:2);
fraccircs=atan2(plane_coords(:,2),plane_coords(:,1))/(2*pi); %angles around the circle
sorted=sort(fraccircs+1); %sorted in ascending order
dubs=[sorted;sorted+1];
spans=dubs(nn:(2*nn-1))-dubs(1:nn); %try spans across all possible cutpoints
if all(spans>opts.interior_circfrac)
    isinterior=1;
end
return
