%10/23/14
%
%A function to calculate confidence limits based only on order statistics
%and the binomial distribution

function [lowIndex, highIndex] = orderStatCL(n, quantile, confLim)

intProbs = zeros(n-1,1);
for k = 1:(n-1);
    intProbs(k) = binopdf(k,n,quantile);
end
sumProbs = intProbs;
totalProb = 0;
includedInds = [];
while sum(intProbs(includedInds)) < (1-confLim)
    maxInds = find(sumProbs == max(sumProbs));
    sumProbs(maxInds) = 0; %the minimum probability, so it's not counted again
    includedInds = [includedInds; maxInds];
end
lowIndex = min(includedInds);
highIndex = max(includedInds);




