function [polarcoords,optsused]=eegp_ctop(cartcoords,opts)
% usage: [polarcoords,optsused]=eegp_ctop(cartcoords,opts)
%
% + 'leads' is either a string or an array of strings, specifying a lead
% 
% + converts cartesian coords to polar coords
%
% created on 3/29/10, JV
%

if (nargin<=1), opts=[]; end

opts=eegp_defopts(opts);
optsused=opts;

for k=1:size(cartcoords,1)
    x = cartcoords(k,1);
    y = cartcoords(k,2);
    z = cartcoords(k,3);
    %find r
    r = sqrt(x^2 + y^2 + z^2);
    if (r<=opts.lowradius_tol)
        polarcoords(k,:)=[r,opts.undefined_theta,opts.undefined_phi];
    else
        %find theta
        theta = acos(z/r);
        if (sqrt(x^2+y^2)<opts.lowradius_tol)
            polarcoords(k,:)=[r,theta,opts.undefined_phi];
        else
            polarcoords(k,:)= [r,theta,atan2(y,x)];     %phi = atan2(y,x)
        end
    end
end

return

    

