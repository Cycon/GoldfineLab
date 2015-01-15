function [stats,ou]=cofl_anal_stats(u,stat_opts)
% [stats,statnames]=cofl_anal_stats(u,stat_opts) calculates several
% statistics for principal components derived from cofl_xtp_demo, etc.
%
% u:  an array of principal components, each column is a PC
% stat_opts:
%   statopts.names:  a list of which statistics to calculate
%   statopts.Hartigan_boot:  number of bootstraps for Hartigan statistic
%
% stats: (whichstat,whichpc): values of the statistics
% ou: options used (ou.names=the statistics actually calculated)
%
%   See also:  COFL_XTP_DEMO, COFL_ANAL_DEMO, HARTIGANU.
if (nargin<=1)
    stat_opts=[];
end
stat_opts=filldefault(stat_opts,'names',{'std','skew','kurt','dip'});
stat_opts=filldefault(stat_opts,'Hartigan_boot',500);
ou=rmfield(stat_opts,'names');
ou.names=cell(0);
%
stats=zeros(0,size(u,2));
sofar=0;
%
for k=1:length(stat_opts.names)
    ifdone=0;
    switch stat_opts.names{k}
        case 'std'
            svals=std(u,0);
            ifdone=1;
        case 'skew'
            svals=skewness(u,0);
            ifdone=1;
        case 'kurt' %excess kurtosis
            svals=kurtosis(u,0)-3;
            ifdone=1;
        case 'dip'
            svals=zeros(1,size(u,2));
            for col=1:size(u,2)
                svals(col)=hartiganu(u(:,col));
            end
            ifdone=1;
        case 'dip_pval'
            svals=zeros(1,size(u,2));
            for col=1:size(u,2)
                [dip,svals(col)]=hartiganu(u(:,col),stat_opts.Hartigan_boot);
            end
            ifdone=1;
    end
    if (ifdone)
        sofar=sofar+1;
        stats(sofar,:)=svals;
        ou.names{sofar}=stat_opts.names{k};
    end
end
return

