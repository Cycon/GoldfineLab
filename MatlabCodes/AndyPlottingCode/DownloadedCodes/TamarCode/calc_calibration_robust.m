%%Function to caculate scale factor for robust estimators
%Method - a struct specifying method to use
%Dims = [nfreqs, ntapers, ntrials]
%
%Calculates both spectral and error scale factors

function method_out = calc_calibration_robust(method, dims, nruns)%, calc_type)

nfreqs = dims(1);
ntapers = dims(2);
ntrials = dims(3);
dims_real = dims; dims_real(1) = 2;
dims_imag = dims; dims_imag(1) = 1;
if nargin < 4
    nruns = 1000;
end
method_nrobust = struct('class', 'standard');
method_robust = method;
%method_robust.scalefactor.(calc_type) = ones(2,1);
method_robust.scalefactor.spectrum = ones(2,1);
method_robust.scalefactor.error = ones(2,1);

simruns_nrobust_s = zeros(2,nruns);
simruns_robust_s = zeros(2,nruns);
simruns_nrobust_e = zeros(2,nruns);
simruns_robust_e = zeros(2,nruns);

simJ = normrnd(0,1,[dims_real, nruns]) + 1i*cat(1, zeros([dims_imag, nruns]), normrnd(0,1,[dims_imag, nruns]));
for i = 1:nruns
    %       simJ = normrnd(0,1,dims_real) + 1i*cat(1, zeros(dims_imag), normrnd(0,1,dims_imag));
    %       nrobust_est = calc_dist_midpoint(simJ, method_nrobust, calc_type);
    %       robust_est = calc_dist_midpoint(simJ, method_robust, calc_type);
    nrobust_est_s = calc_dist_midpoint(squeeze(simJ(:,:,:,i)), method_nrobust, 'spectrum');
    nrobust_est_e = calc_dist_midpoint(reshape(squeeze(simJ(:,:,:,i)),[2,ntapers*ntrials]), method_nrobust, 'error');
    robust_est_s = calc_dist_midpoint(squeeze(simJ(:,:,:,i)), method_robust, 'spectrum');
    robust_est_e = calc_dist_midpoint(reshape(squeeze(simJ(:,:,:,i)),[2,ntapers*ntrials]), method_robust, 'error');
    simruns_nrobust_s(:,i) = nrobust_est_s;
    simruns_robust_s(:,i) = robust_est_s;
    simruns_nrobust_e(:,i) = nrobust_est_e;
    simruns_robust_e(:,i) = robust_est_e;
end

calib_ratio_s = mean(simruns_nrobust_s,2)./mean(simruns_robust_s,2);
calib_ratio_e = mean(simruns_nrobust_e,2)./mean(simruns_robust_e,2);

indices = ones(nfreqs,1)*2; indices(1)=1; indices(end)=1;

calib_ratio_s = calib_ratio_s(indices);
calib_ratio_e = calib_ratio_e(indices);

method_out = method;
method_out.scalefactor.spectrum = calib_ratio_s;
method_out.scalefactor.error = calib_ratio_e;

%method_out.scalefactor.(calc_type) = calib_ratio;
end