function [dists,optsused]=eegp_dists(alead,bleads,opts)
% usage: [dists,optsused]=eegp_dists(alead,bleads,opts)
% 
% + 'alead' is a string specifying a lead
% + 'bleads' is either a string or an array of strings, specifying a lead
%
% + calculates the distances of the vectors to 'bleads';
% + opts.dist_method determines how to calculate the distance:
%       sphere:  spherical approximation, using radius at 'alead' (default)
%       lsphere: local spherical approximation, using geometric mean of 
%                radius at 'alead' and 'bleads'
%       tplane:  tangent plane
%
% created on 4/9/10, JV
%

if (nargin<=2), opts=[]; end

opts=eegp_defopts(opts);
optsused=opts;

%calculation of distances between 'alead' and 'bleads' vectors in one of
%the three following ways:
switch opts.dist_method
    case {'sphere','lsphere'}
        acoord=eegp_cart(alead,opts);
        arad=sqrt(sum(acoord.^2));
        bcoords=eegp_cart(bleads,opts);
        brads=sqrt(sum(bcoords.^2,2));
        z=bcoords*acoord'./(arad*brads);
        thetas=acos(max(min(z,1),-1));
        thetas(find(isnan(z)))=NaN;
        switch opts.dist_method
            case 'sphere'
                dists=arad*thetas;
            case 'lsphere' %aspherical
                %dists=sqrt(arad*sqrt(2))*thetas;
                dists=((arad+brads)./2).*thetas;
        end
    case 'tplane'
        tpcoords=eegp_tpcoords(alead,bleads,opts);
        dists=sqrt(sum(tpcoords.^2,2));
    case 'chord'
        acoord=eegp_cart(alead,opts);
        bcoords=eegp_cart(bleads,opts);
        amb=bcoords-repmat(acoord,size(bcoords,1),1);
        dists=sqrt(sum(amb.^2,2));
    otherwise
        dists=zeros(size(bleads,1),0); %0 distance if unknown method
end

return
