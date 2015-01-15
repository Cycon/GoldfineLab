%cofl_anal_data_make: a script to make cofl_anal_data.mat
% containing file lists used by cofl_anal_demo and cofl_anal_democ
%
% these are names of output files created by cofl_xtp_demo
%
clear;
%
%directory on laptop: ..\..\Data\clnd\*_e.mat /b')
%
%normals
%
%cofl_nml01_e.mat 
%cofl_nml02_e.mat 
%cofl_nml03_e.mat 
%cofl_nml04_e.mat (missing)
%cofl_nml05_e.mat 
%
%patient longitudinals
%
%cofl_IN300_v1_e.mat 
%cofl_IN300_v2_e.mat 
%cofl_IN316_v1_e.mat 
%cofl_IN316_v2_e.mat 
%cofl_IN316_v3_e.mat 
%cofl_IN354_v1_e.mat 
%cofl_IN354_v2_e.mat 
%cofl_IN354_v3_e.mat 
%cofl_IN356_v1_e.mat 
%cofl_IN356_v2_e.mat 
%
%patient Zolpidem off and on
%
%cofl_IN301_zoff_e.mat 
%cofl_IN301_zonw_e.mat 
%cofl_IN301_zon_e.mat 
%cofl_IN301_zoffx_e.mat %zoff with outlier removed 
%
%
file_list=cell(0);
file_list={...
    'cofl_nml01_e','cofl_nml02_e','cofl_nml03_e','cofl_nml04_e','cofl_nml05_e',...
    'cofl_IN300_v1_e','cofl_IN300_v2_e',...
    'cofl_IN316_v1_e','cofl_IN316_v2_e','cofl_IN316_v3_e',...
    'cofl_IN354_v1_e','cofl_IN354_v2_e',...
    'cofl_IN356_v1_e','cofl_IN356_v2_e',...
    'cofl_IN365_v1_e','cofl_IN365_v2_e',...
    'cofl_IN301_zoff_e','cofl_IN301_zonw_e','cofl_IN301_zon_e','cofl_IN301_zoffx_e',...
    'cofl_IN354_v3_e'};
%
dirstring='..\..\Data\clnd\';
if (getinp('1 to save file as cofl_anal_data','d',[0 1]))
    save cofl_anal_data
end