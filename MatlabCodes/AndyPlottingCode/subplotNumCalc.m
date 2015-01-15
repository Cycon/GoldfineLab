function [nr,nc]=subplotNumCalc(numplots)

%2/14/12 simple code to calculate how many rows and columns are optimal for
%the number of plots desired

nr=ceil(sqrt(numplots));
nc=floor(sqrt(numplots));
if nr*nc<numplots
    nc=nc+1;
end;