function Serr=specerr_Robust(S,J,err,trialave,method)%numsp, method)
% Function to compute lower and upper confidence intervals on the spectrum
% Usage: Serr=specerr(S,J,err,trialave,numsp)
% Outputs: Serr (Serr(1,...) - lower confidence level, Serr(2,...) upper confidence level)
%
% Inputs:
% S - spectrum
% J - tapered fourier transforms
% err - [errtype p] (errtype=1 - asymptotic estimate; 
%                   errtype=2 - Jackknife estimate; 
%                   errtype=3 - Order-statistic-based/binomial-based estimate; 
%                   errtype=4 - bootstrap estimate;
%                   p - p value for error estimates)
% trialave - 0: no averaging over trials/channels
%            1 : perform trial averaging
% numsp    - number of spikes in each channel. specify only when finite
%            size correction required (and of course, only for point
%            process data)
% method: Struct with data on how to calculate midpoint
% Outputs:
% Serr - error estimates. Only for err(1)>=1. If err=[1 p] or [2 p] Serr(...,1) and Serr(...,2)
% contain the lower and upper error bars with the specified method.
if nargin < 4; error('Need at least 4 input arguments'); end;
if err(1)==0; error('Need err=[1 p] or [2 p] for error bar calculation. Make sure you are not asking for the output of Serr'); end;

if length(method)>1; method = max(method); end;

[nf,nTapers,nTrials]=size(J);
errchk=err(1);
p=err(2);
pp=1-p/2;
qq=1-pp;

if trialave
    nSamples=nTapers*nTrials;
    nTrials=1;
    dof=2*nSamples;
    %if nargin==5; dof = fix(1/(1/dof + 1/(2*sum(numsp)))); end
    J2 = J;
    J=reshape(J,nf,nSamples);
else
    nSamples=nTapers;
    dof=2*nSamples*ones(1,nTrials);
    for ch=1:nTrials;
        %  if nargin==5; dof(ch) = fix(1/(1/dof + 1/(2*numsp(ch)))); end
    end;
end;
Serr=zeros(2,nf,nTrials);
if errchk==1;
    Qp=chi2inv(pp,dof);
    Qq=chi2inv(qq,dof);
    Serr(1,:,:)=dof(ones(nf,1),:).*S./Qp(ones(nf,1),:);
    Serr(2,:,:)=dof(ones(nf,1),:).*S./Qq(ones(nf,1),:);
elseif errchk==2; %Jackknife
    tcrit=tinv(pp,nSamples-1);
    %dims = [size(J,1), size(J,2)-1, size(J,3)];
    for k=1:nSamples;
        indices=setdiff(1:nSamples,k);
        Jjk=J(:,indices,:); % 1-drop projection
        eJjk = calc_dist_midpoint(Jjk, method, 'error');
        Sjk(k,:,:)=eJjk;%/(dim-1); % 1-drop spectrum
    end;
    sigma=sqrt(nSamples-1)*squeeze(std(log(Sjk),1,1)); if nTrials==1; sigma=sigma'; end;
    conf=repmat(tcrit,nf,nTrials).*sigma;
    conf=squeeze(conf);
    Serr(1,:,:)=S.*exp(-conf); Serr(2,:,:)=S.*exp(conf);
elseif errchk==3;   %Order-statistic-based CLs, for use with median
    nSamples=nSamples/nTapers;
    J2 = squeeze(mean(conj(J2).*J2,2));
    sortedData = sort(J2, 2);
    [lowIndex, highIndex] = orderStatCL(nSamples, .5, p);
    %sortedData = sort(conj(J).*J, 2);
    Serr(1,:,:) = sortedData(:, lowIndex).*method.scalefactor.spectrum;
    Serr(2,:,:) = sortedData(:, highIndex).*method.scalefactor.spectrum;
elseif errchk==4; %Bootstrap
    nboot = 1000;
    Jboot = zeros(nf,nboot);
    for b = 1:nboot;
        indices = repmat(ceil(unifrnd(0,nSamples,[nf,1,nTrials])), [1,nTapers,1]);
        Jboot(:,b) = calc_dist_midpoint(J(:,indices), method, 'error');
    end
    Jboot = sort(Jboot,2,'ascend');
    lowerLimIndex = floor(nboot*qq);
    upperLimIndex = ceil(nboot*pp);
    lowerlimVals = Jboot(:,lowerLimIndex);
    upperlimVals = Jboot(:,upperLimIndex);
    Serr(1,:,:)=lowerlimVals; Serr(2,:,:)=upperlimVals;
end;
Serr=squeeze(Serr);
