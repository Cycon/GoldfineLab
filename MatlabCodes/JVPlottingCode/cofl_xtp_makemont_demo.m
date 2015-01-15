% cofl_xtp_makemont_demo
% demonstrates creation of an array (for montaging)
%
%   See also:  COFL_XTP_DEMO, COFL_XTP_MAKEMONT, EEGP_DEFOPTS
%
if ~exist('ifscratch') ifscratch=1; end
ifscratch=getinp('1 to start from scratch, 2 to include database from XTPAnalysis/XTP_aug','d',[0 2],ifscratch);
if (ifscratch>0)
    if (ifscratch==1) 
        clear all;
        xtp_build_environment;
    elseif (ifscratch==2)
        clear all;
        cofl_build_environment('XTPAnalysis/XTP_aug');
    end
    whos
    ifscratch=0;   
end
%
if ~exist('opts') opts=[];end
opts=cofl_xtp_setdef(opts);
%
if ~exist('eegp_opts') eegp_opts=[]; end
eegp_opts=eegp_defopts(eegp_opts);
%
disp('modes:');
disp('1->select channels from a passthrough montage');
disp('2->create a bipolar montage from a passthrough montage');
disp('3->select channels from a bipolar montage');
disp('4->create one bipolar montage from another bipolar montage');
disp('5->create a Laplacian montage from a passthrough montage');
imode=getinp('choice','d',[1 5]);
nhbs=length(XTP_HEADBOXES);
for ihb=1:nhbs
    disp(sprintf(' %2.0f -> %30s',ihb,XTP_HEADBOXES(ihb).name));
end
ihb=getinp('choice','d',[1 nhbs]);
%
if (ismember(imode,[2 3 4]))
    nmonts=length(XTP_HB_MONTAGES);
    disp('available bipolar montages')
    conform=[];
    for imont=1:nmonts
        if (XTP_HB_MONTAGES(imont).headbox_id==ihb)
            conform=[conform imont];
            cstring='match';
        else
            cstring='mismatch';
        end
        disp(sprintf(' %2.0f (%3.0f chans from headbox %3.0f, %8s) -> %30s',imont,...
            length(XTP_HB_MONTAGES(imont).channelNames),...
            XTP_HB_MONTAGES(imont).headbox_id,cstring,XTP_HB_MONTAGES(imont).name));
    end
    if (ismember(imode,[2 3]))
        imont=getinp('choice','d',[1 nmonts],min(conform));
    end
    if (ismember(imode,[4]))
        imont=getinp('choice for starting montage','d',[1 nmonts],min(conform));
        imont_out=getinp('choice for output montage','d',[1 nmonts],min(setdiff(conform,imont)));
    end
        
end
%
channel_names=[];
if (imode==1)
    opts.mont_mode='passthru';
    lead_list=XTP_HEADBOXES(ihb).lead_list;
    nleads=length(lead_list);
    for ilead=1:nleads
        disp(sprintf('lead %2.0f->%s',ilead,lead_list{ilead}));
    end
    passlist=getinp('selection','d',[1 nleads],[1:nleads]);
    for ipass=1:length(passlist)
        channel_names{ipass,1}=lead_list{passlist(ipass)};
    end
    xtext=cat(2,'headbox: ',XTP_HEADBOXES(ihb).name);
    ytext='output montage';
    ttext='selected passthrough';
end
if (imode==2)
    opts.mont_mode='bipolar';
    lead_list=XTP_HEADBOXES(ihb).lead_list;
    channel_names=XTP_HB_MONTAGES(imont).channelNames;
    xtext=cat(2,'headbox: ',XTP_HEADBOXES(ihb).name);
    ytext='output montage';
    ttext='bipolar montage from passthrough';
end
if (imode==3)
    opts.mont_mode='bipolar';
    lead_list=XTP_HB_MONTAGES(imont).channelNames;
    nleads=length(lead_list);
    for ilead=1:nleads
        disp(sprintf('lead %2.0f->%s',ilead,lead_list{ilead}));
    end
    passlist=getinp('selection','d',[1 nleads],[1:nleads]);
    for ipass=1:length(passlist)
        channel_names{ipass,1}=lead_list{passlist(ipass)};
    end
    xtext=cat(2,'headbox: ',XTP_HEADBOXES(ihb).name);
    ytext='output montage';
    ttext='selected passthrough of bipolar montage';
end
if (imode==4)
    opts.mont_mode='bipolar';
    lead_list=XTP_HB_MONTAGES(imont).channelNames;
    channel_names=XTP_HB_MONTAGES(imont_out).channelNames;
    xtext='input montage';
    ytext='output montage';
    ttext=cat(2,'remontaging based on headbox: ',XTP_HEADBOXES(ihb).name);
end
if (imode==5)
    opts.mont_mode='Laplacian';
    eegp_opts=eegp_defopts(eegp_opts);
    disp('eegp_opts (exit and edit if desired):')
    disp(eegp_opts);
    lead_list=XTP_HEADBOXES(ihb).lead_list;
    nleads=length(lead_list);
    for ilead=1:nleads
        disp(sprintf('lead %2.0f->%s',ilead,lead_list{ilead}));
    end
    passlist=getinp('selection','d',[1 nleads],[1:nleads]);
    for ipass=1:length(passlist)
        channel_names{ipass,1}=lead_list{passlist(ipass)};
    end
    xtext=cat(2,'headbox: ',XTP_HEADBOXES(ihb).name);
    ytext='output montage';
    ttext=sprintf('selected %s Laplacian nbrs interior %2.0f edge %2.0f',...
        opts.Laplacian_type,opts.Laplacian_nbrs_interior,opts.Laplacian_nbrs_edge);
end
[coefs,names_made,ou,ou_eegp]=cofl_xtp_makemont(lead_list,channel_names,opts,eegp_opts);
for k=1:length(names_made)
    if strmatch(names_made{k},opts.nalabel);
        outnames{k}=cat(2,names_made{k},' (req: ',channel_names{k},')');
    else
        outnames{k}=names_made{k};
    end
end
%plot the montage matrix as a colormap
figure;
set(gcf,'Position',[100 100 1050 800]);
imagesc(coefs,[-1 1]*max(abs(coefs(:))));
axis equal;
axis tight;
hold on;
set(gca,'YTick',[1:size(coefs,1)]);
set(gca,'YTickLabel',outnames);
set(gca,'XTick',[1:size(coefs,2)]);
set(gca,'XTickLabel',lead_list);
set(gca,'FontSize',7)
colorbar;
title(ttext);
xlabel(xtext);
ylabel(ytext);
for iy=1:size(coefs,1)-1;
    plot([0 size(coefs,2)]+0.5,[iy iy]+0.5,'k-');
end
for ix=1:size(coefs,2)-1;
    plot([ix ix]+0.5,[0 size(coefs,1)]+0.5,'k-');
end
