function cofl_build_environment(augfile)
% cofl_build_environment(augfile) builds an XTP environment, augmented
% by a file augfile containing variables such as XTP_HEADBOXES,
% XTP_HB_MONTAGES, XTP_GLOBAL_PARAMS
%
% augfile can be created by running xtp_build_environment in a "clear all"-ed workspace, and
% saving the resulting variables into a mat-file
%
% This is an easy way of augmenting the headbox and montage database
%
xtp_build_environment;
filedotmat=cat(2,augfile,'.mat');
if exist(augfile,'file')
    load(augfile);
elseif exist(filedotmat,'file')
    load(filedotmat);
else
    disp(sprintf('Auxiliary setup file %s or %s not found.  Proceeding with basic xtp setup.',augfile,filedotmat));
end
return
