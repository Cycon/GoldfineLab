% jacksa_demo
% demonstrates jacksa:  mean, variance, covariance, 3rd and 4th moments
%
if ~exist('nsamps') nsamps=100; end
if ~exist('r') r=0.5; end %for making a nonzero correlation
if ~exist('b') b=5; end %for making a nonzero mean for y
x=randn(nsamps,1);
y=sqrt(1-r^2).*randn(nsamps,1)+r*x+b;
%
naive=[];dropped=[]; %make sure it is empty to start with
%
naive.means=[mean(x) mean(y)];
c=cov(x,y);
naive.rho=c(1,2)/sqrt(c(1,1)*c(2,2));
naive.variances=diag(c)';
naive.mom3=[sum((x-mean(x)).^3) sum((y-mean(y)).^3)]/nsamps;
naive.mom4=[sum((x-mean(x)).^4) sum((y-mean(y)).^4)]/nsamps;
%
expected.means=[0 b];
expected.rho=r;
expected.variances=[1 1];
expected.mom3=[0 0];
expected.mom4=[3 3];
%
for idrop=1:nsamps
    dropindex=setdiff([1:nsamps],idrop);
    dropped(idrop).means=[mean(x(dropindex)) mean(y(dropindex))];
    c=cov(x(dropindex),y(dropindex));
    dropped(idrop).rho=c(1,2)/sqrt(c(1,1)*c(2,2));
    dropped(idrop).variances=diag(c)';
    dropped(idrop).mom3=[sum((x(dropindex)-mean(x(dropindex))).^3) sum((y(dropindex)-mean(y(dropindex))).^3)]/(nsamps-1); 
    dropped(idrop).mom4=[sum((x(dropindex)-mean(x(dropindex))).^4) sum((y(dropindex)-mean(y(dropindex))).^4)]/(nsamps-1); 
end
[jbias,jdebiased,jvar,jsem]=jacksa(naive,dropped);
disp('expected stats');
disp(expected);
disp('naive stats')
disp(naive);
disp('debiased stats (mean and variances should not change)')
disp(jdebiased);
disp('jackknife estimates of sem')
disp(jsem);
disp('jackknife estimates of bias')
disp(jbias);
