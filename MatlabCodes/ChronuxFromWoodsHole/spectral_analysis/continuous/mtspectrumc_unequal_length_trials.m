function [ S, f, Serr ]= mtspectrumc_unequal_length_trials( data, movingwin, params, sMarkers )

% This routine computes the multi-taper spectrum for a given set of unequal length segments. It is
% based on modifications to the Chronux routines. The segments are continuously structured in the 
% data matrix, with the segment boundaries given by markers. Below,
% movingwin is used in a non-overlaping way to partition each segment into
% various windows. Th spectrum is evaluated for each window, and then the
% spectrum estimated by averaging over all windows for all segments. 
%
% Inputs: 
%
%   data = data( samples, channels )- here segments must be stacked along 
%   the samples dimension, as explained in the email 
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
%
%       S       frequency x channels
%       f       frequencies x 1
%       Serr    (error bars) only for err(1)>=1
%
%
% Change log: 
% 10 June 09: Changes made whereby error bar computation inputs include
% all the averaging windows in a single call to specerr (ie all avg windows
% across all segments input as opposed to only those windows over
% individual segments). This will only affect the error bars, not the 
% spectra or coherence.
%
%11/29/11 version 3 - removed line 45 since all data are always same length so no
%reason to pad

debug = 0; % will display intermediate calcs. 

if nargin < 2; error('avgSpectrum:: Need data and window parameters'); end;
if nargin < 3; params=[]; end;
if isempty( sMarkers ), error( 'avgSpectrum:: Need Markers...' ); end
[ tapers, pad, Fs, fpass, err, trialave, params ] = getparams( params );
% if pad==-1; pad=0; disp('avgSpectrum:: Zero pad factor not an option. Auto computed.'); end;


if nargout > 2 && err(1)==0; 
%   Cannot compute error bars with err(1)=0. change params and run again.
    error('avgSpectrum:: When Serr is desired, err(1) has to be non-zero.');
end;

% Set moving window parameters to no-overlapping
if abs(movingwin(2) - movingwin(1)) >= 1e-6, disp( 'avgSpectrum:: Warming: Window parameters for averaging should be non-overlapping. Set movingwin(2) = movingwin(1).' ); end

wLength = round( Fs * movingwin(1) ); % number of samples in window
wStep = round( movingwin(2) * Fs ); % number of samples to step through

% Check whether window lengths satify segment length > NW/2
if ( wLength < 2*tapers(1) ), error( 'avgSpectrum:: movingwin(1) > 2*tapers(1)' ); end

% Left align segment markers for easier coding
sM = ones( size( sMarkers, 1 ), 2 ); 
sM( :, 2 ) = sMarkers( :, 2 ) - sMarkers( :, 1 ) + 1;

% min-max segments 
Nmax = max( sM(:,2) ); Nmin = min( sM(:,2) );
if ( Nmin < 2*tapers(1) ), error( 'avgSpectrum:: Smallest segment length > 2*tapers(1). Change taper settings' ); end

% max time-sample length will be the window length. 
nfft = 2^( nextpow2( wLength ) + pad );
[ f, findx ] = getfgrid( Fs, nfft, fpass); 

% Precompute all the tapers
sTapers = tapers;
sTapers = dpsschk( sTapers, wLength, Fs ); % compute tapers for window length

nChannels = size( data, 2 ); 
nSegments = size( sMarkers, 1 );

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

        % Compute & store the tapered ffts... used later for spectra & err
        % bars
        % J1 = frequency x taper x nWindows
        % J2 = frequency x taper x nWindowTotal x nChannels
        for c = 1 : nChannels
            J1 = mtfftc( squeeze(wData( :, c, : )), sTapers, nfft, Fs ); % FFT for the tapered data
            J2( :, :, nWins+1:nWins+nWindows, c ) = J1(findx,:,:);
        end
        
        nWins = nWins + nWindows; % keep track of window index globally

    else
        if debug, disp(['avgSpectrum:: Zero windows for segment: ' num2str(sg) ]); end
    end
end % end of segment loop 

% Preallocate
S = zeros( length(f), nChannels );
Serr = zeros( 2, length(f), nChannels );

% computing the avg over all windows - spectra & error bars
% this sturcture is needed to ensure that the DOF in chi-square error bar
% calculations are proper. 

% J2 = frequency x taper x nWindowTotal x nChannels
% Inner mean = Average over tapers => frequency x nWindowTotal x nChannels
% Outer mean = Average over windows => frequency x nChannels
dim1 = [length(f), nWindowTotal, nChannels];
dim2 = [length(f), nChannels];
% S = frequency x nChannels
S = reshape( squeeze( mean( reshape( squeeze( mean( conj(J2).*J2, 2 ) ), dim1), 2 ) ), dim2 );

% Now treat the various "windowed data" as "trials"
% Serr = 2 x frequency x channels. Output from specerr = 2 x frequency x 1
for c = 1 : nChannels
    Serr( :, :, c ) = specerr( squeeze( S(:, c ) ), squeeze( J2(:,:,:, c ) ), err, 1 );
end

if ~nWins
    if debug, disp(['avgSpectrum:: No segment long enough with movingwin parameters found. Reduce movingwin.' ]); end
end




