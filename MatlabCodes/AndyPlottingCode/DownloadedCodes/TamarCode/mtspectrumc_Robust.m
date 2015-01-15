function [S,f,Serr,J, method]=mtspectrumc_Robust(data,params,method)
% Multi-taper spectrum - continuous process
%
% Usage:
%
% [S,f,Serr]=mtspectrumc(data,params,method)
% Input:
% Note units have to be consistent. See chronux.m for more information.
%       data (in form samples x channels/trials) -- required
%       params: structure with fields tapers, pad, Fs, fpass, err, trialave
%       -optional
%           tapers : precalculated tapers from dpss or in the one of the following
%                    forms:
%                    (1) A numeric vector [TW K] where TW is the
%                        time-bandwidth product and K is the number of
%                        tapers to be used (less than or equal to
%                        2TW-1).
%                    (2) A numeric vector [W T p] where W is the
%                        bandwidth, T is the duration of the data and p
%                        is an integer such that 2TW-p tapers are used. In
%                        this form there is no default i.e. to specify
%                        the bandwidth, you have to specify T and p as
%                        well. Note that the units of W and T have to be
%                        consistent: if W is in Hz, T must be in seconds
%                        and vice versa. Note that these units must also
%                        be consistent with the units of params.Fs: W can
%                        be in Hz if and only if params.Fs is in Hz.
%                        The default is to use form 1 with TW=3 and K=5
%
%	        pad		    (padding factor for the FFT) - optional (can take values -1,0,1,2...).
%                    -1 corresponds to no padding, 0 corresponds to padding
%                    to the next highest power of 2 etc.
%			      	 e.g. For N = 500, if PAD = -1, we do not pad; if PAD = 0, we pad the FFT
%			      	 to 512 points, if pad=1, we pad to 1024 points etc.
%			      	 Defaults to 0.
%           Fs   (sampling frequency) - optional. Default 1.
%           fpass    (frequency band to be used in the calculation in the form
%                                   [fmin fmax])- optional.
%                                   Default all frequencies between 0 and Fs/2
%           err  (error calculation [1 p] - Theoretical error bars; [2 p] - Jackknife error bars
%                                   [0 p] or 0 - no error bars) - optional. Default 0.
%           trialave (average over trials/channels when 1, don't average when 0) - optional. Default 0
%       method: struct defining method
% Output:
%       S       (spectrum in form frequency x channels/trials if trialave=0;
%               in the form frequency if trialave=1)
%       f       (frequencies)
%       Serr    (error bars) only for err(1)>=1

if nargin < 1; error('Need data'); end;
if nargin < 2; params=[]; end;
if nargin < 3;
    disp('Defaulting to robust estimation method.');
    method = struct('class', 'two-tier', 'scalefactor', struct('spectrum', [], 'error', []), 'tier', struct('estimator', {'mean', 'median'}));
end;

[tapers,pad,Fs,fpass,err,trialave,params]=getparams(params);
if nargout > 2 && err(1)==0;
    %   Cannot compute error bars with err(1)=0. Change params and run again.
    error('When Serr is desired, err(1) has to be non-zero.');
end;
if strcmpi(method.class, 'two-tier') && err(1) ~= 3;
    warning('err(1)=3 is recommended for two-tier/robust estimation method.');
end
data=change_row_to_column(data);
N=size(data,1);
nfft=max(2^(nextpow2(N)+pad),N);
[f,findx]=getfgrid(Fs,nfft,fpass);
%rcmult=repmat(2,1,length(findx)); %create an array that is 1 for obligate-real FC's and 2 for all others
%rcmult(findx==1)=1;
%rcmult(findx==nfft/2+1)=1;
tapers=dpsschk(tapers,N,Fs); % check tapers
J=mtfftc(data,tapers,nfft,Fs);
J=J(findx,:,:);
%S = calc_dist_midpoint(J, trialave, method);
if ~isfield(method, 'scalefactor') || isempty(method.scalefactor.spectrum)
    method.scalefactor = struct();
    method = calc_calibration_robust(method, size(J));    
end

% if ~isfield(method.scalefactor, 'spectrum') || isempty(method.scalefactor.spectrum)
%     method = calc_calibration_robust(method, size(J),'spectrum');
%     %method.scalefactor.spectrum = calib;
% end
% if ~isfield(method.scalefactor, 'error') || isempty(method.scalefactor.error)
%     if err(1) ~=3
%         method = calc_calibration_robust(method, [size(J,1), size(J,2)*size(J,3)] ,'error');
%     end
%     %method.scalefactor.error = calib_err;
% end
S = calc_dist_midpoint(J, method, 'spectrum');
if nargout>=3; Serr=specerr_Robust(S,J,err,trialave, method); end;
