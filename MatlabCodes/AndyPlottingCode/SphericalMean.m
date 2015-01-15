function [X,Y,Z]=SphericalMean(x1,y1,z1,x2,y2,z2)
% Given 2 points (x1,y1,z1) and (x2,y2,z2)
% calculates midpoint/average of the 2 points on sphere
%
%Dthengone - 1/12/12
[theta(1,1),phi(1,1),radius(1,1)]=cart2sph(x1,y1,z1);
[theta(2,1),phi(2,1),radius(2,1)]=cart2sph(x2,y2,z2);
[X,Y,Z]=sph2cart(mean(theta),mean(phi),mean(radius));
end
