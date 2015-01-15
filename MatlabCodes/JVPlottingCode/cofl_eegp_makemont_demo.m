% cofl_eegp_makemont_demo
% demonstrates creation of a Laplacian montage, without xtp_build_environment
% and also shows a headmap with the selected leads, interior leads in red
%
%   See also:  COFL_XTP_DEMO, COFL_XTP_MAKEMONT, EEGP_DEFOPTS,
%   EEGP_ISINTERIOR_DEMO
%
if ~exist('opts') opts=[];end
opts=cofl_xtp_setdef(opts);
disp(sprintf('options array after call to cofl_xtp_setdef'))
disp(opts);
opts.mont_mode='Laplacian';
disp('available Laplacian types:');
Laplacian_type_list=cofl_xtp_makemont;
for ilap=1:length(Laplacian_type_list)
    disp(sprintf('%1.0f->%s',ilap,Laplacian_type_list{ilap}));
end
laptype=getinp('choice','d',[1 length(Laplacian_type_list)]);
opts.Laplacian_type=Laplacian_type_list{laptype};
%
if ~exist('eegp_opts') eegp_opts=[]; end
eegp_opts=eegp_defopts(eegp_opts);
disp(sprintf('options array after call to eegp_opts'))
disp(eegp_opts);
%
all_leads=fieldnames(eegp_opts.EEGP_LEADS);
%
%get a subset of leads
%
if getinp('0->built-in electrode subset, 1->electrode subsets from xtp','d',[0 1])
    xtp_build_environment;
    if getinp('0 to start from scratch, 1 to include database from XTPAnalysis/XTP_aug','d',[0 1]);
        cofl_build_environment('XTPAnalysis/XTP_aug');
    end
    for ibox=1:length(XTP_HEADBOXES)
        disp(sprintf('%1.0f->%3.0f chans, %s',ibox,XTP_HEADBOXES(ibox).num_leads,XTP_HEADBOXES(ibox).name));
    end
    ibox=getinp('choice','d',[1 length(XTP_HEADBOXES)]);
    leads_present_def=[];
    for ilead=1:length(XTP_HEADBOXES(ibox).lead_list)
        leadno=min(strmatch(upper(XTP_HEADBOXES(ibox).lead_list{ilead}),upper(fieldnames(eegp_opts.EEGP_LEADS)),'exact'));
        if min(strmatch(upper(XTP_HEADBOXES(ibox).lead_list{ilead}),upper(fieldnames(eegp_opts.EEGP_NC_LEADS)),'exact'))>0
            leadno=0;
        end
        if (leadno>0)
            leads_present_def=[leads_present_def,leadno];
        end
    end
    leadset_def=XTP_HEADBOXES(ibox).name;
else
    leads_present_def=[1:19];
    leadset_def='builtin';
end
for ilead=1:length(all_leads)
    disp(sprintf(' lead number %3.0f is %10s, at (x,y,z)=(%7.3f %7.3f %7.3f)',...
        ilead,all_leads{ilead},getfield(eegp_opts.EEGP_LEADS,all_leads{ilead})));
end
iftext=getinp('1 to add text labels to plot','d',[0 1],1);
%
leadset='custom';
leads_present=getinp('list of which leads are present (on input side)','d',[1 length(all_leads)],leads_present_def);
if (length(leads_present_def)==length(leads_present))
    if (all(leads_present_def==leads_present))
        leadset=leadset_def;
    end
end
lead_list=cell(0);
for ilead=1:length(leads_present)
    lead_list{ilead}=all_leads{leads_present(ilead)};
end
%
nleads=length(lead_list);
for ilead=1:nleads
    disp(sprintf('input lead %2.0f->%s',ilead,lead_list{ilead}));
end
passlist=getinp('list of output Laplacian leads','d',[1 nleads],[1:nleads]);
for ipass=1:length(passlist)
    channel_names{ipass,1}=lead_list{passlist(ipass)};
    disp(sprintf('output channel %2.0f->%s',ipass,channel_names{ipass}));
end
showchans=getinp('output channels to show on headmap (0 for none)','d',[0 length(channel_names)],0);
xtext='input montage';
ytext='output montage';
ttext=sprintf('%s Laplacian nbrs interior %2.0f edge %2.0f',...
    opts.Laplacian_type,opts.Laplacian_nbrs_interior,opts.Laplacian_nbrs_edge);
%
%make the laplacian montage
%
[coefs,names_made,ou,ou_eegp]=cofl_xtp_makemont(lead_list,channel_names,opts,eegp_opts);
%
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
title(cat(2,'leadset: ',leadset,'; ',ttext));
xlabel(xtext);
ylabel(ytext);
for iy=1:size(coefs,1)-1;
    plot([0 size(coefs,2)]+0.5,[iy iy]+0.5,'k-');
end
for ix=1:size(coefs,2)-1;
    plot([ix ix]+0.5,[0 size(coefs,1)]+0.5,'k-');
end
clear ix iy k ilead ipass ttext xtext ytext
%
%show which are interior leads, using plotting routine from eegp_isinterior_demo
%
% first set up an options structure with only the selected leads
% so that interior is determined with respect to the selected leads
eegp_opts_selected=eegp_selectleads(lead_list,eegp_opts);
%
el=eegp_opts_selected.EEGP_LEADS;
fn=fieldnames(el);
figure;
set(gcf,'Position',[100 100 1300 700]);
set(gcf,'NumberTitle','off');
set(gcf,'Name','headmap');
%
subplot(1,2,1);
for k=1:length(fn);lead=fn{k};xyz=getfield(el,lead);
   if eegp_isinterior(lead,eegp_opts_selected)
       plot3(xyz(1),xyz(2),xyz(3),'r.');
   else
        plot3(xyz(1),xyz(2),xyz(3),'k.');
   end
   hold on;
   if (iftext)
       ht=text(xyz(1),xyz(2),xyz(3),lead);
       set(ht,'FontSize',7);
   end  
end
showcolors='gcbm';
if length(showchans) & (max(showchans)>0) >=1
    for k=1:length(showchans)
        outlead=channel_names{showchans(k)};
        zin=find(~(coefs(showchans(k),:)==0));
        cout=getfield(el,outlead);
        for kz=1:length(zin)
            inlead=lead_list{zin(kz)};
            cin=getfield(el,inlead);
            plot3([cout(1) cin(1)],[cout(2) cin(2)],[cout(3) cin(3)],showcolors(mod(k-1,length(showcolors))+1));
        end
    end
end
plot3(eegp_opts_selected.EEGP_CENTER(1),eegp_opts_selected.EEGP_CENTER(2),eegp_opts_selected.EEGP_CENTER(3),'k*');
title(leadset,'FontSize',7);
axis vis3d;
axis equal;
view([-18, 22]);
xlabel('x');
ylabel('y');
zlabel('z');
%
subplot(1,2,2);
for k=1:length(fn);lead=fn{k};xyz=getfield(el,lead);
   if eegp_isinterior(lead,eegp_opts_selected)
       plot(xyz(1),xyz(2),'r.');
   else
        plot(xyz(1),xyz(2),'k.');
   end
   hold on;
   if (iftext)
       ht=text(xyz(1),xyz(2),lead);
       set(ht,'FontSize',7);
   end
end
if length(showchans) & (max(showchans)>0) >=1
    for k=1:length(showchans)
        outlead=channel_names{showchans(k)};
        zin=find(~(coefs(showchans(k),:)==0));
        cout=getfield(el,outlead);
        for kz=1:length(zin)
            inlead=lead_list{zin(kz)};
            cin=getfield(el,inlead);
            plot([cout(1) cin(1)],[cout(2) cin(2)],showcolors(mod(k-1,length(showcolors))+1));
        end
    end
end
plot(eegp_opts_selected.EEGP_CENTER(1),eegp_opts_selected.EEGP_CENTER(2),'k*');
title(leadset,'FontSize',7);
set(gca,'XLim',[-1 1]*max([abs(get(gca,'XLim')),abs(get(gca,'YLim'))]));
set(gca,'YLim',[-1 1]*max([abs(get(gca,'XLim')),abs(get(gca,'YLim'))]));
axis equal;
view (2);
xlabel('x');
ylabel('y');
