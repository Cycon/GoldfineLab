% cofl_xtp_setup_devel: set up a mat file that defines channel sets and datasets
% this corresponds to isetup=1 (devel) of cofl_xtp_demo
%
%   See also:  COFL_XTP_DEMO.
%
clear;
setupname='devel';
chansets=cell(0);
ds=cell(0);
%
chansets{1}.name='basic 2 leads: C3 C4';
chansets{1}.leadlist=strvcat('C3','C4');
chansets{2}.name='basic 8 leads: F3 C3 P3 O1 F4 C4 P4 O2';
chansets{2}.leadlist=strvcat('F3','C3','P3','O1','F4','C4','P4','O2');
chansets{3}.name='bipolar channels for SfN pt 2: FP1-F7, T3-T5 , FP2-F8, T4-T6';
chansets{3}.leadlist=strvcat('FP1-F7','T3-T5','FP2-F8','T4-T6');
chansets{3}.pairlist=strvcat('FP1-F7:T3-T5','FP1-F7:FP2-F8','FP2-F8:T4-T6','FP1-F7:FP2-F8');
chansets{4}.name='for debugging: bipolar channels for SfN pt 2 with reverse coherence and mismatches';
chansets{4}.leadlist=strvcat('FP1-F7','T3-T5','FP2-F8','T4-T6','T3-T4');
chansets{4}.pairlist=strvcat('FP1-F7:T3-T5','FP2-CZ:T4-T6','FP2-F8:FP1-F7'); %second pair is a mismatch, third pair is reversed
chansets{5}.name='19 chans common to all datasets, with 8 inter-hemispheric and 7 longitudinal pairings';
chansets{5}.leadlist=strvcat('FP1','F3','C3','P3','O1','F7','T3','T5','FP2','F4','C4','P4','O2','F8','T4','T6','FZ','CZ','PZ');
chansets{5}.pairlist=strvcat('FP1:FP2','F3:F4','F7:F8','C3:C4','P3:P4','T3:T4','T5:T6','O1:O2',...
    'F7:T5','F3:P3','FP1:O1','FZ:PZ','FP2:O2','F4:P4','F8:T6');
chansets{6}.name='9 interior chans common to all datasets, with 3 inter-hemispheric and 3 longitudinal pairings';
chansets{6}.leadlist=strvcat('F3','C3','P3','F4','C4','P4','FZ','CZ','PZ');
chansets{6}.pairlist=strvcat('F3:F4','C3:C4','P3:P4','F3:P3','FZ:PZ','F4:P4');
%
ds{1}.filename='IN301M2007offonPP.mat';          ds{1}.fieldname='IN301M2007offPP';           ds{1}.desc='IN301 baseline 1 (pt 2 for SFN)';
ds{2}.filename='IN301M2007offonPP.mat';          ds{2}.fieldname='IN301M2007onPP';            ds{2}.desc='IN301 zolpidem 1';
ds{3}.filename='IN301M2007offonMontage0PP.mat';  ds{3}.fieldname='IN301M2007t1offMontage0PP'; ds{3}.desc='IN301 baseline 1 montage0';
ds{4}.filename='IN301M2007offonMontage0PP.mat';  ds{4}.fieldname='IN301M2007t1onMontage0PP';  ds{4}.desc='IN301 zolpidem 1 montage0, w. first 20 min';
ds{5}.filename='IN301M2007offonMontage0PP2.mat'; ds{5}.fieldname='IN301M2007t1onMontage0PP2'; ds{5}.desc='IN301 zolpidem 1 montage0';
ds{6}.filename='IN356Wawake04PPmay4.mat';        ds{6}.fieldname='IN356Wawake04PP';           ds{6}.desc='IN356 test';
ds{7}.filename='IN356Wawake04PPmay4.mat';        ds{7}.fieldname='IN356Wawake04PP';           ds{7}.desc='IN356 visit 1 awake OFF';
ds{8}.filename='IN356Wawake05PPmay8.mat';        ds{8}.fieldname='IN356Wawake05PP';           ds{8}.desc='IN356 visit 2 awake OFF';
ds{9}.filename='IN300Eawake07PPmay9.mat';        ds{9}.fieldname='IN300Eawake07PP';           ds{9}.desc='IN300 visit 1 awake OFF';
%
filename_def=cat(2,'cofl_xtp_setup_',setupname,'.mat');
filename=getinp('file name to save chansets and ds','s',[0 1],filename_def);
if length(strrep(filename,'.mat',''))>2
    save(filename,'chansets','ds');
    disp(sprintf('chansets and ds saved into %s',filename));
else
    disp('file *NOT* saved.');
end
