function data=normByPower(data,params)

%give data organized as channels x datapoints x trials (eeglab type) and
%params.Fs and it will calculate power spectra and divide all channels by
%average power. 
%
%Meant to be run on Laplacian Montaged data though could use for bipolar as
%well. Shouldn't be necessary for common average reference.
%
%Need to test and decide if to use full range of power or just a subset
%(powerRange). Also need to test to ensure generally equal power everywhere
%after this.
%
%need to decide if to divide by total power calculated here or multiply by
%a ratio of the lowest one (all divided by min so lowest one stays at
%itself).

powerRange=[4 20]; %range in which to look at power for normalization of all power. 
%don't want to include power of artifact especially if using data without
%ICA correction where might differ between channels.

freqRes=2;
params.tapers=[2 size(data,2)/params.Fs 1];
params.trialave=1;
params.pad=-1; %could change if it speeds it up
params.fpass=powerRange;

for jj=1:size(data,1)
    [s]=mtspectrumc(squeeze(data(jj,:,:)),params);
    sum_sqrt_s(jj)=sqrt(sum(s));
    data(jj,:,:)=data(jj,:,:)./sqrt(sum(s));
end

data=data.*min(sum_sqrt_s); %so multiply all by the smallest so return smallest to it's original
%value and all others to some smaller value this way no big change compared
%to previous version in overall power

% meanPower=mean(s,2);%gives mean for each frequency. Note it's not mean of log10power.