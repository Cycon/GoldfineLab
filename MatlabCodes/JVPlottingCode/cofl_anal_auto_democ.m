%cofl_anal_auto_democ.m
% runs cofl_anal_demo, making plots of coherograms
%
anal_opts.pair_list=[1:17]; %which pairs to show
anal_opts.surr_list=[0]; %which surrogates to show
anal_opts.ipca_list=[3 11]; %which kind of pca's to show (S1S2 and coh)
anal_opts.quantiles=[0.05 0.95];
anal_opts.cohplots_infix='basic_c'; % infix for plot and stat output files
anal_opts.cell_choice=1; %first segment in each data file
anal_opts.plot_anal_choice=1; %headmap
%
if ~exist('file_list')
    s=load('cofl_anal_data.mat');
    file_list=s.file_list;
    dirstring=s.dirstring;
    clear s;
end
%
%check that all files are present
have_files=[];
for ifile=1:length(file_list)
    auto.filename=cat(2,dirstring,file_list{ifile},'.mat');
    if_found=exist(auto.filename);
    if (if_found==2)
        disp(sprintf('%3.0f->     found: %s',ifile,auto.filename));
        have_files=[have_files,ifile];
    else
        disp(sprintf('%3.0f-> not found: %s',ifile,auto.filename));
    end
end
have_files=getinp('files to process','d',[1 length(file_list)],have_files);
%
for ifile_ptr=1:length(have_files)
    ifile=have_files(ifile_ptr);
    auto=anal_opts;
    auto.filename=cat(2,dirstring,file_list{ifile},'.mat');
    diary_filename=cat(2,file_list{ifile},'_',anal_opts.cohplots_infix,'_stats.txt');
    diary(diary_filename);
    disp(sprintf('analyzing %s with diary written %s',auto.filename,diary_filename));
    disp(datestr(now));
    disp('analysis options');
    disp(anal_opts);
    %do the analysis
    %
    cofl_anal_demo;
    %
    disp('analysis complete.');
    close all;
    diary off;
end
