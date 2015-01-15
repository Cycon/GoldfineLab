function [results,opts_used]=fisherdisc(data,tags,opts)
% [results,opts_used]=fisherdisc(data,tags,opts)
% computes the Fisher discriminant and associated statistics, 2-class, with cross-validation
% (no assumption of equal within-class covariances) 
%
%   see FisherDiscrimWikipedia.pdf
%
%  data: size(data)=[nfeats,nsamps], i.e., one sample per column, one row per feature
%  tags: size(tags)=[1 nsamps], containing 1 or 2 to tag each sample
%  opts: options
%    opts.nshuffle: number of shuffles to apply.
%       Defaults to 0.  Can also be Inf -- exhaustive, or -1'
%       if -1, then uses exhausive shuffling, or random selection of opts.nshuffle_max
%       if exhaustive would exceed opts.nshuffle_max.  If number requested is greater
%       than number necessary for exhaustive, then exhaustive is used.
%    opts.nshuffle_max: maximum number of shuffles if opts.nshuffle=-1; defaults to 200
%    opts.xvalid:  1 to do drop-one cross-validation and jackknife stats, defaults to 0
%    opts.sub1:   1 to subtract 1 for empirical estimate of within-class covariances, defaults to 0
%        Note that this only matters if the number of elements in each class is unequal
%    opts.classifiers: cell array of names of classifiers to use, as cell array
%      'halfway' (halfway between the two midpoints)
%      'mapequal' (maximum a posteriori based on equal class occupancies)
%      'mapbayes' (maximum a posteriori based on empiric class occupancies)
%    opts.condmax: maximum condition number for covariance matrix, defaults to Inf
%      
%   results: results structure
%      results.discriminant [1 nfeat] a unit-vector discriminant, positive values favor class 2
%      results.projections [1 nsamps] values of the projections of each sample
%      results.ss_eachclass: [1 2] sum of squares, within each class
%      results.ss_class: sum of squares, total within each class
%      results.ss_total:  sum of squares, total
%      results.fc_*
%      results.fc_[name]_classes: [1 nsamps] 1 or 2 based on classification
%      results.fc_[name]_cmatrix: [2 2] confusion matrix, row=correct class, column=assigned class
%      results.fc_[name]_cutpoint, projections greater than cutpoint are assigned to class 2
%            (cutpoint not calculated for mapequal or mapbayes, since the discrimination may be supported by an interval)
%      ***the next fields are only calculated if opts.xvalid=1
%      results.xv_[name]_classes: [1 nsamps] 1 or 2 based on classification
%      results.xv_[name]_cmatrix: [2 2] confusion matrix, row=correct class, column=assigned class
%      results.discriminant_jdebiased: [1 nfeat] jackknife-debiased discriminant (not orthonormalized)
%      results.discriminant_jsem: [1 nfeat] std devs from jackknife
%          (_jdebiased is NOT orthonormalized, and wa not used to calculate classes; classes
%          are calculated based on discriminant, or on individual drop-one discriminants)
%      IMPORTANT
%         When the covariances are highly non-circular and signal is small, the discriminant is
%         shaped by the covariances, rather than the signal -- see scenario 2
%         of fisherdisc_test -- and in this case, the error bars may be small,
%         but the out-of-sample testing shows that the discriminator is not valid
%      results.shuffle.*: corresponding quantities for shuffle, only present if opts.nshuffle is not 0
%
%   opts_used: options used
%
% See also:
%  FISHERDISC_TEST, FISHERDISC_DEF, JACKSA.
%
if (nargin<=2)
    opts=[];
end
opts=fisherdisc_def(opts);
opts=filldefault(opts,'nshuffle',0);
opts=filldefault(opts,'nshuffle_max',200);
opts=filldefault(opts,'xvalid',0);
opts=filldefault(opts,'sub1',0);
opts=filldefault(opts,'classifiers',[]);
opts=filldefault(opts,'condmax',Inf);
results=[];
%
results_all=fisherdisc_do(data,tags,opts);
nfeat=size(data,1);
nsamps=size(data,2);
for ig=1:2
    ptrs{ig}=find(tags==ig);
    n(ig)=length(ptrs{ig});
end
fn=fieldnames(results_all);
%keep all fields that end in 'in' but strip '_'in'; drop the '_out' fields, keep all others
for ifn=1:length(fn)
    fname=fn{ifn};
    if (strcmp(fname(end-2:end),'_in'))
        results=setfield(results,fname(1:end-3),getfield(results_all,fname));
    elseif (strcmp(fname(end-3:end),'_out'))
    else
        results=setfield(results,fname,getfield(results_all,fname));
    end
end
clist=opts.classifiers;
%
% if cross-validation is requested: do the drop-one analyses
% for classification, and also for jackknifing
%
if (opts.xvalid) %cross-validation
    jnaive.discriminant=results.discriminant;
    jdrop=[];
    xv=[];
    for ic=1:length(clist)
        cname=clist{ic};
        sname=cat(2,'fc_',cname);
        name_fc{ic}=cat(2,'fc_',cname,'_classes');
        name_xv_classes{ic}=cat(2,'xv_',cname,'_classes');
        name_xv_cmatrix{ic}=cat(2,'xv_',cname,'_cmatrix');
        xv=setfield(xv,name_xv_classes{ic},zeros(1,nsamps));
   end
   %do the Fisher discriminant with each sample flagged as out-of-sample
   for idrop=1:nsamps
        outflag=zeros(1,nsamps);
        outflag(idrop)=1;
        results_drop=fisherdisc_do(data,tags,opts,outflag);
        jdrop(idrop).discriminant=results_drop.discriminant;
        for ic=1:length(clist)
            xv=setfield(xv,name_xv_classes{ic},{idrop},getfield(results_drop,name_fc{ic},{idrop}));
        end
   end %idrop
   %confusion matrices for cross-validated classifiers
   for ic=1:length(clist)
       xvc=getfield(xv,name_xv_classes{ic});
       for ig_row=1:2
           for ig_col=1:2
                cmat(ig_row,ig_col)=sum(xvc(ptrs{ig_row})==ig_col);
            end
       end
       xv=setfield(xv,name_xv_cmatrix{ic},cmat);
   end
   xvfn=fieldnames(xv);
   %install the fields
   for ifn=1:length(xvfn)
       results=setfield(results,xvfn{ifn},getfield(xv,xvfn{ifn}));
   end
   % do jackknife
    [jbias,jdebiased,jvar,jsem]=jacksa(jnaive,jdrop);
    results.discriminant_jdebiased=jdebiased.discriminant; %not orthonormal
    results.discriminant_jsem=jsem.discriminant; %not orthonormal   
end %if xvalid
%
% if shuffle is requested, determine how good the classification is
% with real data and with shuffle.  Cross-validation not done on shuffled sets.
%
if ~(opts.nshuffle==0)
%      first, determine whether to do an exhausive shuffle
%      if 'uptomax' then uses exhausive shuffling, or random selection 
%      if 'all' then do all
%
%
    nexhaust_log=gammaln(nsamps+1)-gammaln(n(1))-gammaln(n(2));
    if (exp(nexhaust_log) > 10^14)
        nexhaust=exp(nexhaust_log);
    else
        nexhaust=nchoosek(nsamps,n(1));
    end
    %
    if opts.nshuffle>0 & opts.nshuffle<Inf
        if opts.nshuffle>nexhaust
            ns=nexhaust;
            ifexhaust=1;
        else
            ns=opts.nshuffle;
            ifexhaust=0;
        end
    elseif opts.nshuffle==Inf
        ns=nexhaust;
        ifexhaust=1;
    else
        if (nexhaust<=opts.nshuffle_max)
            ns=nexhaust;
            ifexhaust=1;
        else
            ns=opts.nshuffle_max;
            ifexhaust=0;
        end
    end
    results.shuffle_details=sprintf(' nsamps=%4.0f n=[%4.0f %4.0f] opts.nshuffle=%4.0f nexhaust=%17.10g ->ns=%10.0f ifexhaust=%1.0f',...
        nsamps,n,opts.nshuffle,nexhaust,ns,ifexhaust');
    sorted=[ptrs{1} ptrs{2}];
    if (ifexhaust)
        %establish the list of tags, without assuming that tags were originally in order
        shuffs=nchoosek([1:nsamps],n(1));
    end
    a=[]; %accumulate for shuffle
    for ishuf=1:ns
        if (ifexhaust)
            tperm=[shuffs(ishuf,:) setdiff([1:nsamps],shuffs(ishuf,:))];
        else
            tperm=randperm(nsamps);
        end
        tags_shuffled=tags(tperm);
        %
        r=fisherdisc_do(data,tags_shuffled,opts);
        a.ss_total(1,ishuf)=r.ss_total_in;
        a.ss_eachclass(:,ishuf)=r.ss_eachclass_in;
        a.ss_class(:,ishuf)=r.ss_class_in;
        for ic=1:length(clist)
            shuf_cmatrix(:,:,ishuf,ic)=getfield(r,cat(2,'fc_',clist{ic},'_cmatrix_in'));
        end
    end
    for ic=1:length(clist)
        a=setfield(a,cat(2,'fc_',clist{ic},'_cmatrix'),shuf_cmatrix(:,:,:,ic));
    end
    results.shuffle=a;
end
%
opts_used=opts;
return
