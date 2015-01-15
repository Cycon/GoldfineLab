% cofl_xtp_setup_long: set up a mat file that defines channel sets and datasets
% this corresponds to isetup=2 (clnd) of cofl_xtp_demo
%
%   See also:  COFL_XTP_DEMO.
%
clear;
setupname='long';
chansets=cell(0);
ds=cell(0);
%
chansets{1}.name='19 chans common to all datasets, with 8 inter-hemispheric and 9 longitudinal pairings including all chans';
chansets{1}.leadlist=strvcat('FP1','F3','C3','P3','O1','F7','T3','T5','FP2','F4','C4','P4','O2','F8','T4','T6','FZ','CZ','PZ');
chansets{1}.pairlist=strvcat('FP1:FP2','F3:F4','F7:F8','C3:C4','P3:P4','T3:T4','T5:T6','O1:O2',...
    'F7:T5','F3:P3','FP1:O1','FZ:PZ','FZ:CZ','CZ:PZ','FP2:O2','F4:P4','F8:T6');
%
ds{1}.filename='IN356Wawake04PPmay4.mat';          ds{1}.fieldname='IN356Wawake04PP';           ds{1}.desc='IN356 visit 1 awake';
ds{2}.filename='IN356Wawake05PPmay8.mat';          ds{2}.fieldname='IN356Wawake05PP';           ds{2}.desc='IN356 visit 2 awake';
ds{3}.filename='IN300Eawake07PPmay9.mat';          ds{3}.fieldname='IN300Eawake07PP';           ds{3}.desc='IN300 visit 1 awake';
ds{4}.filename='IN300Eawake08PP_May11.mat';        ds{4}.fieldname='IN300Eawake08PP';           ds{4}.desc='IN300 visit 2 awake';
ds{5}.filename='Nml01_awake01_30segsPP_May20.mat'; ds{5}.fieldname='Nml01_awake01_30segsPP';    ds{5}.desc='Nm101 awake';
ds{6}.filename='Nml02_awake01_30segsPP_May19.mat'; ds{6}.fieldname='Nml02_awake01_30segsPP';    ds{6}.desc='Nm102 awake';
ds{7}.filename='Nml03_awake01_30segsPP_May21.mat'; ds{7}.fieldname='Nml03_awake_30segsPP';      ds{7}.desc='Nm103 awake';
ds{8}.filename='Nml04_awake01_30segsPP_May21.mat'; ds{8}.fieldname='Nml04_awake_30segsPP';      ds{8}.desc='Nm104 awake';
ds{9}.filename='Nml05_awake01_30segsPP_May21.mat'; ds{9}.fieldname='Nml05_awake_30segsPP';      ds{9}.desc='Nm105 awake';
ds{10}.filename='IN301M2007offonMontage0PP.mat';   ds{10}.fieldname='IN301M2007t1offMontage0PP';ds{10}.desc='IN301 baseline 1';
ds{11}.filename='IN301M2007offonMontage0PP.mat';   ds{11}.fieldname='IN301M2007t1onMontage0PP'; ds{11}.desc='IN301 zolpidem 1 w. first 20 min';
ds{12}.filename='IN301M2007offonMontage0PP2.mat';  ds{12}.fieldname='IN301M2007t1onMontage0PP2';ds{12}.desc='IN301 zolpidem 1';
ds{13}.filename='IN316Wawake0208PP_May26.mat';     ds{13}.fieldname='IN316W_awake0208PP';       ds{13}.desc='IN316 visit 1 awake';
ds{14}.filename='IN316Wawake1108PP_May26.mat';     ds{14}.fieldname='IN316Wawake1108PP';        ds{14}.desc='IN316 visit 2 awake';
ds{15}.filename='IN316Wawake1109PP_May26.mat';     ds{15}.fieldname='IN316Wawake1109PP';        ds{15}.desc='IN316 visit 3 awake';
ds{16}.filename='IN354Hawake08PP_May31.mat';       ds{16}.fieldname='IN354Hawake08PP';          ds{16}.desc='IN354 visit 1 awake';
ds{17}.filename='IN354Hawake09PP_May31.mat';       ds{17}.fieldname='IN354Hawake09PP';          ds{17}.desc='IN354 visit 2 awake';
ds{18}.filename='IN365Lawake0209PP_May31.mat';     ds{18}.fieldname='IN365Lawake0209PP';        ds{18}.desc='IN365 visit 1 awake';
ds{19}.filename='IN365Lawake0609PP_May31.mat';     ds{19}.fieldname='IN365Lawake0609PP';        ds{19}.desc='IN365 visit 2 awake';
ds{20}.filename='IN354Hawake10PP_Jun11.mat';       ds{20}.fieldname='IN354Hawake10PP';          ds{20}.desc='IN354 visit 3 awake';
%
filename_def=cat(2,'cofl_xtp_setup_',setupname,'.mat');
filename=getinp('file name to save chansets and ds','s',[0 1],filename_def);
if length(strrep(filename,'.mat',''))>2
    save(filename,'chansets','ds');
    disp(sprintf('chansets and ds saved into %s',filename));
else
    disp('file *NOT* saved.');
end
