function [t_surr,SX_surr,f_surr,z_surr,optsused]=surr_corrgau(SX,f,dt,npts,nexamps,opts)
% [t_surr,SX_surr,f_surr,z_surr,optsused]=_surr_corrgau(SX,f,dt,npts,nexamps,opts) creates
% surrogate multichannel correlated Gaussian time series with a specified spectrum
%   since ifft isused, this is fastest if npts is a power of 2
%
%   NOTE (May 5, 2010):  there may be a normalization problem.  In surr_test, the normalization is accurate.
%    However, in cofl_xtp_demo, the overall variance of the surrogate signals is wrong,
%    even thought the spectral shape is correct.  So there, variance is adjusted by hand.
%    It is unclear where the normalization problem arises, since in cofl_xtp_demo,
%    the spectra are calculated by coherencyc, averaged across segments, etc
%
% SX(length(f),nchans,nchans): spectra and cross-spectra on each channel
%   SX(:,k,k) is real; SX(:,m,n)=conj(SX(:,n,m));
% f: list of frequencies where SX is sampled: S(1,m,n) is cross-spectrum on channels m and n at f(1), etc.
% dt:  time resolution of series to be created
% npts:  number of points in time series; must be even
% nexamps:  number of examples, defaults to 1
% opts: options
%
% t_surr(npts,nexamps): surrogate time series
% SX_surr: spectrum used (size(SX_surr,1)=f_surr)
% f_surr: frequencies used (f_surr(1)=0)
% z_surr(:,nchans,nexamps): Fourier transform, first dim has length npts/2+1; complex-valued;
%    values at 1 and npts/2+1 must be real
%
% extrapolation and smoothing (might be controlled by opts in future)
%   for spectra:
%     below f(2), power is constant (but 0 at 0 Hz)
%     above f(end), power is 0
%     in between, spline on log scale (but have to make sure that covariances are consistent)
%   for cross-spectra:  amplitude converted to coherence, transformed by
%   atanh, and splined.  phase -- taken from nearest neighbor.
%   if cross-spectra are given at all frequencies sampled (i.e., if f is a subset of f_surr), then
%   the extrapolation and smooghing has no effect. 
%
%  The resulting covariance matrices could be singular or even not
%  positive-definite.  These are listed in optsused.failures, and at those
%  frequencies, the Gaussians are chosen to be independent. This is only
%  likely to happen when signals are very strongly correlated, and have sharp
%  spectra not well-sampled by SX.
%
%   See also:  SURR_GAU, SURR_CORRGAU2, GNORMCOR.
%
if (nargin<=4) nexamps=1; end
if (nargin<=5) opts=[]; end
opts=filldefault(opts,'coheps',10^-10); % how close a coherence can get to 1
optsused=opts;
%
npts=2*round(npts/2);
nh=npts/2+1;
nchans=size(SX,2);
%
t_surr=zeros(npts,nexamps);
% determine the frequencies we need to sample the power spectrum
flo=1./(npts*dt);
fhi=1/(2*dt);
f_surr=[0:npts/2]*flo;
%
ind.z=find(f_surr==0);
ind.lo=find((f_surr<f(2)) & (f_surr>0));
ind.hi=find(f_surr>f(end));
ind.mid=find((f_surr>=f(2)) & (f_surr<=f(end)));
SX_surr=zeros(nh,nchans,nchans);
SX_surr(ind.z,:,:)=0;
SX_surr(ind.lo,:,:)=repmat(SX(2,:,:),[length(ind.lo),1,1]);
SX_surr(ind.hi,:,:)=0;
for ich=1:nchans
    SX_surr(ind.mid,ich,ich)=exp(spline(f,log(SX(:,ich,ich)),f_surr(ind.mid)));
end
fnearptr=zeros(nh,1);
for ifreq=1:nh
    fmiss=abs(f_surr(ifreq)-f);
    fnearptr(ifreq)=min(find(fmiss==min(fmiss)));
end
for ich=1:nchans-1
    for jch=ich+1:nchans
        coh_given=zeros(length(f),1);
        inz=find(SX(:,ich,ich)>0);
        jnz=find(SX(:,jch,jch)>0);
        ijnz=intersect(inz,jnz);
        coh_given(ijnz)=min(abs(SX(ijnz,ich,jch))./sqrt(SX(ijnz,ich,ich).*SX(ijnz,jch,jch)),1-opts.coheps);
        coh_target(ind.z)=0;
        coh_target(ind.lo)=coh_given(2);
        coh_target(ind.hi)=0;
        coh_target(ind.mid)=tanh(spline(f,atanh(coh_given),f_surr(ind.mid)));
        coh_target=coh_target(:); %force a column
        phase_target=phase(SX(fnearptr,ich,jch));
        SX_surr(:,ich,jch)=exp(i*phase_target).*coh_target.*sqrt(SX_surr(:,ich,ich).*SX_surr(:,jch,jch));
        SX_surr(:,jch,ich)=conj(SX_surr(:,ich,jch));
    end
end
optsused.ind=ind;
% now work frequency by frequency to create a covariance matrix for the
% real and imaginary parts of each channel
vnorm=npts/(2*dt); % variance normalization 
covmtx=zeros(2*nchans,2*nchans,nh);
optsused.exception_freqs=[];
optsused.exception_mineiv=[];
realptr=[1:2:2*nchans-1];
imagptr=[2:2:2*nchans];
zs=zeros(nchans,nexamps,nh);
for ifreq=1:nh
    for ich=1:nchans
        ix=realptr(ich);
        iy=imagptr(ich);
        %diagonal terms
        covmtx(ix,ix,ifreq)=SX_surr(ifreq,ich,ich);
        covmtx(iy,iy,ifreq)=SX_surr(ifreq,ich,ich);
        for jch=ich+1:nchans
            jx=realptr(jch);
            jy=imagptr(jch);
            covmtx(ix,jx,ifreq)= real(SX_surr(ifreq,ich,jch));
            covmtx(ix,jy,ifreq)= imag(SX_surr(ifreq,ich,jch));
            covmtx(iy,jx,ifreq)=-imag(SX_surr(ifreq,ich,jch));
            covmtx(iy,jy,ifreq)= real(SX_surr(ifreq,ich,jch));
            covmtx([jx jy],[ix iy],ifreq)=covmtx([ix iy],[jx jy],ifreq)';
        end
    end
end
%
covmtx(:,:,1)=covmtx(:,:,1)*2;
covmtx(:,:,nh)=covmtx(:,:,nh)*2;
covmtx=covmtx*vnorm;
optsused.covmtx=covmtx;
for ifreq=1:nh
    % excerpt from gnormcor
    %[v,d]=eig(cov);
    %if (min(min(d)) < 0)
    %error('covariance matrix has negative eigenvalues.')'
    %end
    %crt=v*sqrt(d)*v';
    %x=crt*normrnd(0,1,n,npts);
    %
    %disp(sprintf(' at %4.0f %8.4f',ifreq,f_surr(ifreq)));
    %disp(covmtx(:,:,ifreq));
    [v,d]=eig(covmtx(:,:,ifreq));
    if (min(min(d)) < 0)
        optsused.exception_freqs=[optsused.exception_freqs,f_surr(ifreq)];
        warning(sprintf('covariance matrix has negative eigenvalues at f=%8.4f; independent values used at this frequency.',...
            f_surr(ifreq)))
        optsused.exception_mineiv=[optsused.exception_mineiv,min(min(d))];
        [v,d]=eig(diag(diag(covmtx(:,:,ifreq))));
    end
    crt=v*sqrt(d)*v';
    xy=crt*randn(2*nchans,nexamps); %real and imaginary pairs
    zs(:,:,ifreq)=xy(realptr,:)+i*xy(imagptr,:);
end
z_surr=permute(zs,[3 1 2]); %z now has dims of freq, channel, iexamp
z_surr(1,:,:)=real(z_surr(1,:,:)); %make sure it is real on the folds
z_surr(nh,:,:)=real(z_surr(nh,:,:));
z_surr=cat(1,z_surr,conj(z_surr(flipud(2:nh-1),:,:))); %add a complex conj half
t_surr=ifft(z_surr,'symmetric');
return
