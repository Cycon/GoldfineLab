function [sigma,f] = nonst_stat(data,A,sumV,params)

% Nonstationarity test - continuous process
%
% Usage:
%
% sigma=nonst_test(data,A,sumV,params)
% Input: 
% Note units have to be consistent. See chronux.m for more information.
%       data (1d array in samples) -- required
%       A   quadratic coefficient matrix - (Compute this separately since
%       the computation is time consuming - [A,sumV]=quadcof(N,NW,order). order
%       has to < 4NW.)
%       sumV   sum of the quadratic inverse basis vectors 
%       params  structure with fields tapers, Fs and fpass
%          tapers precomputed tapers or in the form [NW 2NW] where NW is the
%             time-bandwidth product used to compute A
%          Fs   (sampling frequency) - optional. Default 1.
%          fpass        band of frequencies at which the statistic is to
%                        be computed. Default [0 Fs/2]
% Output:
%       sigma   (nonstationarity index Thomson, 2000) 
%       f        frequencies
% To use the test, compute the percentile value of the chi square
% distribution with degrees of freedom = order = size(A,3). Then compare the statistic
% sigma with that percentile value.
% e.g. for 95%, 
%  >> x=chi2inv(0.95,order);
%  >> idx=find(sigma>=x);
%  Then, f(idx) are the frequencies where the observed statistic is higher
%  than the 95th percentile of the chi-square distribution. Note however
%  that since there are multiple frequencies, this is a multiple comparison
%  problem and we would expect 5% of the frequenies to show sigma > x. If
%  the number of frequencies showing this are much higher than 5%, then
%  something interesting is going on.


if nargin < 3; error('Need data, quadratic coefficient matrix and sum of basis vectors'); end;
order = size(A,3);
maxtapers=size(A,1);
NW=maxtapers/2;
if nargin < 4; 
    params.tapers=[NW maxtapers];
    params.Fs=1;
    params.fpass=[0 params.Fs/2];
end;
[tapers,pad,Fs,fpass]=getparams(params);
sz=size(tapers);
if sz(1)==1; % tapers in the form [NW 2NW]
   if tapers(1)~=NW || tapers(2)~=maxtapers; 
      error('specified tapers do not agree with those used for computing A'); 
   end;
else % precomputed tapers
   if sz(2)~=maxtapers;
      error('specified tapers do not agree with those used for computing A');
   end;
end;
N = length(data);
tapers=dpsschk(tapers,N,Fs); % check tapers
alpha=zeros(1,order);
for j=1:order
  alpha(j) = trace(squeeze(A(:,:,j))*squeeze(A(:,:,j)));
end;

tmp=mtfftc(data,tapers,N,Fs);
f=getfgrid(Fs,N,[0,Fs/2]);
%tmp=mtfftc(data,tapers,nfft,Fs);
sigma = zeros(length(data),1);
% Pbar = sum(abs(tmp).^2,2)./sum(weights.^2,2);
Pbar=mean(abs(tmp).^2,2);
whos tmp A
for ii=1:order
  a0=real(sum(tmp'.*(squeeze(A(:,:,ii))*tmp.')))'/alpha(ii);
  sigma=sigma+alpha(ii)*(a0./Pbar-sumV(ii)).^2;
end;
% Restrict to frequencies of interest
idx=find(f>=fpass(1)& f<=fpass(2));
sigma=sigma(idx);
f=f(idx);

