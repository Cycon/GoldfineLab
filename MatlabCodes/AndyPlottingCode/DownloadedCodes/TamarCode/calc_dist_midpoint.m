%%Function to calculate mean or median of 3-D array
%%Used for mtspectrumctm() and specerrtm()
%%10/30/13
% J - array of freqs x tapers x trials
% trialave - whether or not to average trials
% method - A struct defining the method to be used
%       method.class = ['standard', 'one-tier', 'two-tier']
%       method.scalefactor = struct('spectrum', ... (array of numbers to scale)
%                                   'error', ... (array to scale for err
%                                   calc)
%       method.tier = struct()
%       method.tier(1) = struct()
%                       .estimator = ['mean', 'median', 'trimmedmean']...
%                       .params = (params needed for estimator)
%       method.tier(2) = struct()
%                       .estimator = ['mean', 'median', 'trimmedmean']...
%                       .params = (params needed fcror estimator)
% calc_type: 'spectrum' or 'error'

function S=calc_dist_midpoint(J, method, calc_type)%, trialave)
nfreqs = size(J,1);
ntapers = size(J,2);
ntrials = size(J,3);

% if nargin == 2; trialave = 1; end;

% Standard method:
if strcmpi(method.class, 'standard')
    S = squeeze(mean(conj(J).*J,2));
    if strcmpi(calc_type, 'spectrum')
        S = squeeze(mean(S,2));
        %     if trialave; S=squeeze(mean(S,2)); end;
    end
else
    % One-tier method:combining tapers/trials into one dimension
    if strcmpi(method.class, 'one-tier')
        J = reshape(J, [nfreqs ntapers*ntrials]);
    end
    % First tier operator (applies to both non-standard methods)
    S = conj(J).*J;
    
    if strcmpi(calc_type, 'spectrum')
        tier1method = method.tier(1);
        if strcmpi(tier1method.estimator,'mean')
            S = squeeze(mean(S,2));
        elseif strcmpi(tier1method, 'median')
            S = squeeze(median(S,2));
        elseif strcmpi(tier1method, 'trimmean')
            S = squeeze(trimmean(S, tier1method.params.percent, 'round', 2));
        end
    end
    % Two tier method: apply tier 1 method to tapers and 2nd method to trials
    if strcmpi(method.class, 'two-tier') || strcmpi(calc_type, 'error')
        tier2method = method.tier(2);
        if strcmpi(tier2method.estimator,'mean')
            S = squeeze(mean(S,2));
        elseif strcmpi(tier2method.estimator, 'median')
            S = squeeze(median(S,2));
        elseif strcmpi(tier2method.estimator, 'trimmean')
            S = squeeze(trimmean(S, tier2method.params.percent, 'round', 2));
        end
    end
%      if ~isfield(method, 'scalefactor')
%          method.scalefactor = struct('spectrum', [], 'error', []);
%          disp(strcat('Introduced scalefactor struct'))
%      end
%      if isempty(method.scalefactor.(calc_type))
%          method.scalefactor.(calc_type) = calc_calibration_robust(method, size(J), calc_type);
%          disp(strcat('Introduced ', calc_type, ' into scalefactor struct'))
%      end
    scalefact = method.scalefactor.(calc_type);
    S = S.*scalefact;
end
end

