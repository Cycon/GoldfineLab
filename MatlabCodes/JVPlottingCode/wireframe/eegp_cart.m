function [cartcoords,optsused]=eegp_cart(leads,opts)
% usage: [cartcoords,optsused]=eegp_cart(leads,opts)
%
%   leads can be 'Fz', etc, or 'C3-P3', etc. 
%   behavior for bipolar leads is determined by opts.bipolar_loc, default
%     is to return midpoint
%
% input:
%   leads:  a string or an array of strings, specifying a lead
%   opts: options, see eegp_defopts
% 
% cartcoords: cartesian coordinates of lead specified
%    x: neg on left, pos on right
%    y: towards nose
%    z: towards top of head
%
%  See also:  EEGP_DEFOPTS, EEGP_POLAR.
%

if (nargin<=1), opts=[]; end

opts=eegp_defopts(opts);
optsused=opts;                                 

for k=1:size(leads,1)
    lname=deblank(upper(leads(k,:)));
    c=eegp_cart_sub(lname,opts);
    if isempty(c) %lookup for a single lead failed
        hy=strfind(lname,'-'); %is it a bipolar label?
        if (length(hy)==1)
            ld{1}=lname(1:hy-1);
            ld{2}=lname(hy+1:end);
            switch opts.bipolar_loc
                case -1
                    c=[NaN NaN NaN];
                case {1,2}
                    c=eegp_cart_sub(ld{opts.bipolar_loc},opts);
                case 0
                    c1=eegp_cart_sub(ld{1},opts);
                    c2=eegp_cart_sub(ld{2},opts);
                    if ~isempty(c1) & ~isempty(c2)
                        cm=(c1+c2)/2;
                        if ~isempty(opts.standard_radius)
                            if (sum(cm.^2)>0)
                                cm=opts.standard_radius*cm/sqrt(sum(cm.^2));
                            end
                        end
                        c=cm;
                    end
            end
        end
    end
    if isempty(c) %lookup failed and not bipolar
        c=[NaN NaN NaN];
    end
    cartcoords(k,:)=c;
end

return

function c=eegp_cart_sub(lname,opts)
c=[];
if isfield(opts.EEGP_LEADS,lname)
    c=getfield(opts.EEGP_LEADS,lname);
    if ~isempty(opts.standard_radius)
        if (sum(c.^2)>0)
            c=opts.standard_radius*c/sqrt(sum(c.^2));
        end
    end
end
return
