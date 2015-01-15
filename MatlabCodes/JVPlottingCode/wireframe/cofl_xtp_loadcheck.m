function ds_out=cofl_xtp_loadcheck(ds)
% ds_out=cofl_xtp_loadcheck(ds)
%  loads one or more datasets, amalgamates metadata, and checks for consistency
%  ds:  a single dataset structure, defined in cofl_xtp_demo or similar
%
%  ds_out: ds, with data loaded and metadata merged
%  ds_loaded: a list of which data sets have been successfully loaded
s=load(cat(2,ds.datapath,filesep,ds.filename));
disp(sprintf(' loaded dataset %30s (%s)',ds.filename,ds.desc));
ds_in=ds;
ds.data=getfield(s,ds.fieldname);
ds.nsegs=length(ds.data.metadata);
ds.meta=[];
ds.nchans_avail_from_info_channeNames=length(ds.data.info.channelNames);
ds.nchans_avail=size(ds.data.data{1},2);
%
%merge and do a consistency check on metadata
%
ifok_global=1;
md=ds.data.metadata;
%
%retrieve headbox ID from subfield if presaent
%
if isfield(md(1),'headbox')
    for iseg=1:ds.nsegs
        md(iseg).headboxID_extracted=md(iseg).headbox.headboxID;
    end
end
%
fns=fieldnames(md);
for ifn=1:length(fns)
    fn=fns{ifn};
    ifok=[];
    for iseg=1:ds.nsegs
        switch fn
            %string parameters that should match exactly
            case {'units','HBmontageName','prefiltering'}
                if iseg==1
                    ds.meta.(fn)=md(1).(fn);
                    ifok=1;
                else
                    if ~strcmp(ds.meta.(fn),md(iseg).(fn))
                        disp(sprintf('%s does not match for segment %2.0f',fn,iseg));
                        ifok=0;
                    end
                end
            %string parameters that need not match
            case {'sourceFile'}
                if iseg==1
                    ds.meta.(fn)=md(1).(fn);
                    ifok=2;
                else
                    ds.meta.(fn)=strvcat(ds.meta.(fn),md(iseg).(fn));
                end
            %string parameters that SHOULD not match
            case {'start','end'}
                if iseg==1
                    ds.meta.(fn)=md(1).(fn);
                    ifok=3;
                else
                    ds.meta.(fn)=strvcat(ds.meta.(fn),md(iseg).(fn));
                end
            %numeric parameters that should match exactly
            case {'srate','numleads','HBmontageID','headboxID_extracted'}
                if iseg==1
                    ds.meta.(fn)=md(1).(fn);
                    ifok=1;
                else
                    if ~(ds.meta.(fn)==md(iseg).(fn))
                        disp(sprintf('%s does not match for segment %2.0f',fn,iseg));
                        ifok=0;
                    end
                end
            %scalar numeric parameters that need not match
            case {'hbnum','numsamples'}
                ds.meta.(fn)(iseg)=md(iseg).(fn);
                if iseg==1
                    ifok=2;
                else
                    if ~(ds.meta.(fn)(1)==md(iseg).(fn))
                        ifok=-1;
                    end
                end
            %vector numeric parameters that need not match
            case {'EMGratings'}
                ifok=2;
                ds.meta.(fn)(iseg,:)=md(iseg).(fn);
         end %switch fn
     end %iseg
     if (ifok==3) %requires all values different
         ndiff=size(unique(ds.meta.(fn),'rows'),1);
         if (ndiff<ds.nsegs)
             disp(sprintf('   common values (ERROR) for %s.',fn));
             ifok_global=0;
         else
            disp(sprintf('   all values different (required) for %s.',fn));
         end
     end
     if (ifok==2)
         ndiff=size(unique(ds.meta.(fn),'rows'),1);
         if (ndiff==1)
             disp(sprintf('   consistency (not required) for %s.',fn));
         else
            disp(sprintf('   inconsistency (allowable) for %s.',fn));
         end
     end
     if (ifok==1) disp(sprintf('   consistency (required) for %s.',fn)); end
     if (ifok==-1) disp(sprintf('   inconsistency (allowable) for %s.',fn)); end
     if (ifok==0)
         disp(sprintf('   inconsistency (ERROR) for %s.',fn));
         ifok_global=0;
     end
end %ifn
if ~isfield(ds.meta,'EMGratings')
    ds.meta.EMGratings=repmat(NaN,ds.nsegs,ds.nchans_avail);
end
if (ifok_global)
    disp('overall consistency check passes.')
    ds_out=ds;
else
    disp('overall consistency check FAILS, data not loaded.')
    ds_out=ds_in;
end
return
