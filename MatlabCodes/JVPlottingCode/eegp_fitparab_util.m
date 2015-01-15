function [invmtx,vreg]=eegp_fitparab_util(tpcoords2,if_gen)
% [invmtx,vreg]=eegp_fitparab_util(tpcoords2) is a utility to find a regression matrix to
% determine the best-fitting parabola at chan and 
%
%   See eegp_fitparab for details
%
% tpcoords2: coords (2d) in the tangent plane
% if_gen:  0 to assume a syymmetric parabola (default), 1 for a full quadratic 
% invmtx: a matrix of size [nnear 4] for if_gen=0, [nnear 6] for if_gen=1; 
% vreg: the regressors
%
% for if_gen=0:
%  (invmtx*V)(i) =[a,b,c,d] a+b*x(i)+c*y(i)+d*(x(i)^2+y(i)^2) via least squares
% for if_gen=1:
%  (invmtx*V)(i) =[a,b,c,d,e,f] a+b*x(i)+c*y(i)+d*x(i)^2+e*x(i)y(i)+f*y(i)^2
% via least squares
%
% no protection at present if singular
%
%  See also:  EEGP_FITPARAB.
%
if (nargin<=1)
    if_gen=0;
end
if (if_gen==0)
    vreg=[ones(size(tpcoords2,1),1),tpcoords2(:,1),tpcoords2(:,2),tpcoords2(:,1).^2+tpcoords2(:,2).^2];
    invmtx=vreg*inv(vreg'*vreg); %pseudoinverse
else
    vreg=[ones(size(tpcoords2,1),1),tpcoords2(:,1),tpcoords2(:,2),...
        tpcoords2(:,1).^2,tpcoords2(:,1).*tpcoords2(:,2),tpcoords2(:,2).^2];
end
invmtx=vreg*inv(vreg'*vreg); %pseudoinverse
return

