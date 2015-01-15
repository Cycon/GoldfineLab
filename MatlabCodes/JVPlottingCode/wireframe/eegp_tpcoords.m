function [tpcoords,optsused]=eegp_tpcoords(alead,bleads,opts)
% usage: [tpcoords,optsused]=eegp_tpcoords(alead,bleads,opts)
%
% + 'alead' is a string specifying a lead
% + 'bleads' is either a string or an array of strings, specifying a lead
% 
% + calculates the coordinates of the vectors to 'bleads', projected onto
%   the tangent plane of 'alead'
%
% created on 4/9/10, JV
%

if (nargin<=2), opts=[]; end

opts=eegp_defopts(opts);
optsused=opts;                                 

%project coordinates onto tangent plane
acoord=eegp_cart(alead,opts);
bcoords=eegp_cart(bleads,opts);
denom=bcoords*acoord';
denom(find(denom==0))=1;
lambdas=acoord*acoord'./denom; %column vector of multipliers
tpcoords=repmat(acoord,size(bleads,1),1)-repmat(lambdas,1,3).*bcoords;
tpcoords(find(denom==0),:)=NaN; %noncephalic
return
