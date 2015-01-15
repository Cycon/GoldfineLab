function [t_surr,S_surr,f_surr,z_surr,optsused]=surr_gau(S,f,dt,npts,nexamps,opts)
% [t_surr,S_surr,f_surr,z_surr,optsused]=surr_gau(S,f,dt,npts,nexamps,opts) creates surrogate Gaussian
% time series with a specified spectrum
%
%   since ifft isused, this is fastest if npts is a power of 2
%
% S: power spectrum
% f: list of frequencies wher S is sampled: S(1) is power at f(1), etc.
% dt:  time resolution of series to be created
% npts:  number of points in time series; must be even
% nexamps:  number of examples, defaults to 1
% opts: options
%
% t_surr(npts,nexamps): surrogate time series
% S_surr: spectrum used (length =f_surr)
% f_surr: frequencies used (f_surr(1)=0)
% z_surr(:,nexamps): Fourier transform, first dim has length npts/2+1; complex-valued;
%    values at 1 and npts/2+1 must be real
%
% extrapolation and smoothing (might be controlled by opts in future)
%   below f(2), power is constant (but 0 at 0 Hz)
%   above f(end), power is 0
%   in between, spline on log scale
%
%   See also:  SURR_CORRGAU.
%
if (nargin<=4) nexamps=1; end
if (nargin<=5) opts=[]; end
%
optsused=opts;
%
npts=2*round(npts/2);
nh=npts/2+1;
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
S_surr(ind.z)=0;
S_surr(ind.lo)=S(2);
S_surr(ind.hi)=0;
S_surr(ind.mid)=exp(spline(f,log(S),f_surr(ind.mid)));
S_surr=S_surr(:); %make sure it is a column
optsused.ind=ind;
%
z_surr=randn(nh,nexamps)+i*randn(nh,nexamps);
normfac=sqrt(npts*S_surr/(2*dt));
normfac(1)=normfac(1)*sqrt(2); % since this FC must be real
normfac(end)=normfac(end)*sqrt(2); %since this FC must be real
z_surr=z_surr.*repmat(normfac,1,nexamps);
z_surr(1,:)=real(z_surr(1,:));
z_surr(end,:)=real(z_surr(end,:));
z_surr=[z_surr;flipud(conj(z_surr(2:end-1,:)))];
%
t_surr=ifft(z_surr,'symmetric');
%
return
