function [Cmn,Phimn,Smn,Smm,f,ConfC,PhiStd,Cerr] = coherencyc_unequal_length_trials( data, movingwin, params, sMarkers )

% This routine computes the average multi-taper coherence for a given set of unequal length segments. It is
% based on modifications to the Chronux routines. The segments are continuously structured in the 
% data matrix, with the segment boundaries given by markers. Below,
% movingwin is used in a non-overlaping way to partition each segment into
% various windows. Th coherence is evaluated for each window, and then the
% window coherence estimates averaged. Further averaging is conducted by
% repeating the process for each segment. 
%
% Inputs: 
%
%   data = data( samples, channels )- here segments must be stacked
%   as explained in the email 
%   movingwin = [window winstep] i.e length of moving
%              window and step size. Note that units here have
%              to be consistent with units of Fs. If Fs=1 (ie normalized)
%              then [window winstep]should be in samples, or else if Fs is
%              unnormalized then they should be in time (secs). 
%   sMarkers = N x 2 array of segment start & stop marks. sMarkers(n, 1) = start
%           sample index; sMarkers(n,2) = stop sample index for the nth segment
%   params = see Chronux help on mtspecgramc
%
% Output:
%       For more details on each quantity below, see coherencyc.m 
%
%       Cmn     magnitude of coherency - frequencies x iChPairs
%       Phimn   phase of coherency - frequencies x iChPairs
%       Smn     cross spectrum -  frequencies x iChPairs
%       Smm     spectrum m - frequencies x channels
%       f       frequencies x 1
%       ConfC   1 x iChPairs; confidence level for Cmn at 1-p % - only for err(1)>=1
%       PhiStd  frequency x iChPairs; error bars for phimn - only for err(1)>=1
%       Cerr    2 x frequency x iChPairs; Jackknife error bars for Cmn - use only for Jackknife - err(1)=2
%
%       Here iChPairs = indices corresponding to the off-diagonal terms of the
%       lower half matrix. iChPairs = 1 : nChannels*(nChannels-1)/2. So,
%       iChPairs=1,2,3,4,...correspond to C(2,1), C(3,1), C(3,2), C(4,1), etc. 
%       The mapping can be obtained as follows: 
%
%       C(i,j) = Cmn(:,k) where k = j + (1/2)*(i-1)*(i-2)
%
%       The above also applies to Phimn, Smn
%
% Note: 
%   segment length >= NW/2 where NW = half bandwidth parameter (see dpss). So the power spectrum will 
%   be computed only for those segments whose length > NW/2. For that reason, the routine returns the 
%   indices for segments for which the spectra is computed. This check is
%   done here since pSpecgramAvg calls it. 
%
% Change log: 
% 10 June 09: Changes made whereby error bar computation inputs include
% all the averaging windows in a single call to specerr (ie all avg windows
% across all segments input as opposed to only those windows over
% individual segments). This will only affect the error bars, not the 
% spectra or coherence.  

debug = 0; % will display intermediate calcs. 

if nargin < 2; error('avgCoherence:: Need data and window parameters'); end;
if nargin < 3; params=[]; end;
[ tapers, pad, Fs, fpass, err, trialave, params ] = getparams( params );
if isempty( sMarkers ), error( 'avgCoherence:: Need Markers...' ); end
% Not designed for "trialave" so set to 0
params.trialave = 0;
[ tapers, pad, Fs, fpass, err, trialave, params ] = getparams( params );
if nargout > 7 && err(1)~=2; 
    error('avgCoherence:: Cerr computed only for Jackknife. Correct inputs and run again');
end;
if nargout > 5 && err(1)==0;
%   Errors computed only if err(1) is nonzero. Need to change params and run again.
    error('avgCoherence:: When errors are desired, err(1) has to be non-zero.');
end;
if size(data,2)==1, error('avgCoherence:: Need more than 1 channel to compute coherence'); end

% Set moving window parameters to no-overlapping
if abs(movingwin(2) - movingwin(1)) >= 1e-6, disp( 'avgCoherence:: Warming: Window parameters for averaging should be non-overlapping. Set movingwin(2) = movingwin(1).' ); end

wLength = round( Fs * movingwin(1) ); % number of samples in window
wStep = round( movingwin(2) * Fs ); % number of samples to step through

% Check whether window lengths satify segment length > NW/2
if ( wLength < 2*tapers(1) ), error( 'avgCoherence:: movingwin(1) > 2*tapers(1)' ); end

% Left align segment markers for easier coding
sM = ones( size( sMarkers, 1 ), 2 ); 
sM( :, 2 ) = sMarkers( :, 2 ) - sMarkers( :, 1 ) + 1;

% min-max segments 
Nmax = max( sM(:,2) ); Nmin = min( sM(:,2) );
if ( Nmin < 2*tapers(1) ), error( 'avgCoherence:: Smallest segment length > 2*tapers(1). Change taper settings' ); end

% max time-sample length will be the window length. 
nfft = 2^( nextpow2( wLength ) + pad );
[ f, findx ] = getfgrid( Fs, nfft, fpass); 

% Precompute all the tapers
sTapers = tapers;
sTapers = dpsschk( sTapers, wLength, Fs ); % compute tapers for window length

nChannels = size( data, 2 );
nSegments = size( sMarkers, 1 );
iChPairs = ceil( nChannels*(nChannels-1)/2 );

if debug
    disp( ['Window Length = ' num2str(wLength)] );
    disp( ['Window Step = ' num2str(wStep)] );
    disp( ' ' );
end

% Precompute the total number of averaging windows that are used for all
% the segments. This is used only for array memory preallocation
%
nWindowTotal = 0; 
for sg = 1 : nSegments
    N = sM(sg,2); 
    wStartPos = 1 : wStep : ( N - wLength + 1 );
    nWindowTotal = nWindowTotal + length( wStartPos );
end

% J2 = frequency x taper x nWindowTotal x nChannels
J2 = zeros( length(f), tapers(2), nWindowTotal, nChannels ); J2 = complex( J2, J2 );

nWins = 0;
for sg = 1 : nSegments
    % Window lengths & steps fixed above
    % For the given segment, compute the positions & number of windows
    N = sM(sg,2); 
    wStartPos = 1 : wStep : ( N - wLength + 1 );
    nWindows = length( wStartPos );
    if nWindows

        w=zeros(nWindows,2);
        for n = 1 : nWindows
            w(n,:) = [ wStartPos(n), (wStartPos(n) + wLength - 1) ]; % nWindows x 2. just like segment end points
        end

        % Shift window limits back to original sample-stamps
        w(:, 1) = w(:,1) + (sMarkers( sg, 1 ) - 1);
        w(:, 2) = w(:,2) + (sMarkers( sg, 1 ) - 1);

        if debug
            disp( ['Segment Start/Stop = ' num2str( w(1,1) ) ' ' num2str( w(end,2) ) ] );
            disp( ['Min / Max Window Positions = ' num2str( min(w(:,1)) ) ' ' num2str( max(w(:,1)) ) ] );
            disp( ['Total Number of Windows = ' num2str(nWindows) ]);
            disp( ' ' );
        end

        % Pile up window segments similar to segment pileup
        wData = zeros( wLength, nChannels, nWindows ); %initialize to avoid fragmentation
        for n = 1:nWindows
            %wData( :, :, n ) = detrend( data( w(n,1):w(n,2), : ), 'constant' );
            wData( :, :, n ) = detrend( data( w(n,1):w(n,2), : ) );
        end

        % Compute & store the tapered ffts... used later for coherence & err
        % bars
        % J1 = frequency x taper x nWindows
        % J2 = frequency x taper x nWindowTotal x nChannels
        %J2 = zeros( length(f), tapers(2), nWindows, nChannels ); J2 = complex( J2, J2 );
        for c = 1 : nChannels
            J1 = mtfftc( squeeze(wData( :, c, : )), sTapers, nfft, Fs ); % FFT for the tapered data
            J2( :, :, nWins+1:nWins+nWindows, c ) = J1(findx,:,:);
        end
        
        nWins = nWins + nWindows; % keep track of window index globally

    else
        if debug, disp(['avgCoherence:: Zero windows for segment: ' num2str(sg) ]); end
    end
end


% J2 = frequency x taper x nWindowTotal x nChannels
% Inner mean = Average over tapers => frequency x nWindowTotal x nChannels
% Outer mean = Average over windows => frequency x nChannels
% smm = diagonal terms, ie power spectrum
%
dim1 = [length(f), nWindowTotal, nChannels];
dim2 = [length(f), nChannels];
% diagonal terms, smm = frequency x nChannels
Smm = reshape( squeeze( mean( reshape( squeeze( mean( conj(J2).*J2, 2 ) ), dim1), 2 ) ), dim2 );

%
% Compute only the lower off-diagonal terms
% smn = Cross Spectrum terms = complex
% cmn = abs( coherence ); phimn = phase( coherence )
%

%
% ConfC is has dimensions [1 size(cmn,2)]  => confc = 1 x iChPairs
% PhiStd has dimensions [f size(cmn,2)]  => phistd = frequencies x iChPairs = size( cmn )
% Cerr has dimensions [2 size(cmn)]   => cerr = 2 x frequencies x iChPairs
%
Cerr = zeros( 2, length(f), iChPairs ); ConfC = zeros(1,iChPairs); PhiStd=zeros( length(f), iChPairs );

Cmn = zeros( length(f), iChPairs ); Phimn=Cmn; Smn = complex( Cmn, Cmn );

dim = [length(f), tapers(2), nWindowTotal];
id = 1;
for m=2:nChannels
    Jm = reshape( squeeze( J2(:,:,:,m) ), dim ); % frequency x taper x nWindowTotal
    for n=1:m-1 % since we want off-diagonal terms only
        Jn = reshape( squeeze( J2(:,:,:,n) ), dim ); % frequency x taper x nWindowTotal

        % Average the Cross-Spectrum, Smn, over the windows
        % Smn = complex
        % First average over tapers, then over windows
        %
        Smn(:,id) = squeeze( mean( squeeze( mean( conj(Jm).*Jn, 2 ) ), 2 ) ); % frequency x iChPairs

        % Coh = Coherence = complex = size( smn ) = frequency x iChPairs
        %
        Coh = Smn(:,id) ./ ( sqrt( Smm(:,m) .* Smm(:,n) ) );
        
        Cmn(:,id) = abs(Coh); % frequencies x iChPairs
        Phimn(:,id) = angle(Coh); % frequencies x iChPairs

        % Since we've averaged over segments, set trialave = 1
        %
        % coherr outputs:
        % confc is has dimensions [1 size(Cmn(:,1),2)]  => confC = 1 x iChPairs
        % phierr has dimensions [f size(Cmn(:,1),2)]  => phistd = frequencies x iChPairs = size( Cmn )
        % cerr has dimensions [2 size(Cmn(:,1))]   => Cerr = 2 x frequencies x iChPairs
        %
        % Now treat the various "windowed data" as "trials"
        %
        if nargout == 8; % Jacknife
            [ cconfc, cphistd, ccerr ] = coherr( Cmn(:,id), Jm, Jn, err, 1 );
            Cerr(:,:,id ) = ccerr;
        elseif nargout==7;
            [ cconfc, cphistd ] = coherr( Cmn(:,id), Jm, Jn, err, 1 );
        end
        
        ConfC(id) = cconfc;
        PhiStd(:,id) = cphistd; % frequencies x iChPairs

        id = id + 1;
    end
end

if ~nWins
    if debug, disp(['avgCoherence:: No segment long enough with movingwin parameters found. Reduce movingwin.' ]); end
end





