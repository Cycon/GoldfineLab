function [cartcoords,optsused]=eegp_ptoc(polarcoords,opts)
% usage: [cartcoords,optsused]=eegp_ptoc(polarcoords,opts)
%
% + 'leads' is either a string or an array of strings, specifying a lead
% 
% + converts poplar coords to cartesian coords 
%
% created on 3/29/10, JV
%

if (nargin<=1), opts=[]; end

opts=eegp_defopts(opts);
optsused=opts;      

for k=1:size(polarcoords,1)
    r = polarcoords(k,1);
    theta = polarcoords(k,2);
    phi = polarcoords(k,3); 
    x = r*sin(theta)*cos(phi);
    y = r*sin(theta)*sin(phi);
    z = r*cos(theta);
    cartcoords(k,:)= [x,y,z];
end

return

    

