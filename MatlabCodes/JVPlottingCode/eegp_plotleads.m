function [hf,plot_opts_used]=eegp_plotleads(eegp_opts,plot_opts);
% utility routine to show the leads in the structure eegp_opts
%
% hf: handle to figure
% plot_opts_used: plot_opts with defaults filled in
%
% plot_opts.iftext: 1 to add text labels
% plot_opts.tstring: title string
% plot_opts.xlim, ylim, zlim: if present, forces plot limits
% plot_opts.marked_leads: % a structure with field names contaiing lead
% labels, and values indicating the point format; this overrides the
% standard plotting of interior leads as red points, other leads as black
%  e.g., plot_opts.marked_leads.F3='b+' causes the F3 point to be plotted as
%  a blue cross
%
%  See also EEGP_ISINTERIOR_DEMO.
%
if nargin<=1
    plot_opts=[];
end
plot_opts=filldefault(plot_opts,'iftext',1);
plot_opts=filldefault(plot_opts,'xlim',[]);
plot_opts=filldefault(plot_opts,'ylim',[]);
plot_opts=filldefault(plot_opts,'zlim',[]);
plot_opts=filldefault(plot_opts,'tstring','head map');
plot_opts=filldefault(plot_opts,'marked_leads',[]);
if (~isstruct(plot_opts.marked_leads))
    marked_leads=[];
else
    marked_leads=plot_opts.marked_leads;
end
plot_opts_used=plot_opts;
%
el=eegp_opts.EEGP_LEADS;
fn=fieldnames(el);
hf=figure;
set(gcf,'Position',[100 100 1300 700]);
set(gcf,'NumberTitle','off');
set(gcf,'Name',plot_opts.tstring);
%
subplot(1,2,1);
for k=1:length(fn);lead=fn{k};xyz=getfield(el,lead);
   if (isfield(marked_leads,lead))
       plot3(xyz(1),xyz(2),xyz(3),getfield(marked_leads,lead));
   else
       if eegp_isinterior(lead,eegp_opts)
            plot3(xyz(1),xyz(2),xyz(3),'r.');
       else
            plot3(xyz(1),xyz(2),xyz(3),'k.');
        end
   end
   hold on;
   if (plot_opts.iftext)
       ht=text(xyz(1),xyz(2),xyz(3),lead,'Interpreter','none');
       set(ht,'FontSize',7);
   end
end
plot3(eegp_opts.EEGP_CENTER(1),eegp_opts.EEGP_CENTER(2),eegp_opts.EEGP_CENTER(3),'k*');
axis vis3d;
view([-18, 22]);
if ~isempty(plot_opts.xlim) xlim(plot_opts.xlim); end
if ~isempty(plot_opts.ylim) ylim(plot_opts.ylim); end
if ~isempty(plot_opts.zlim) zlim(plot_opts.zlim); end
xlabel('x');
ylabel('y');
zlabel('z');
title(plot_opts.tstring,'Interpreter','none');
%
subplot(1,2,2);
for k=1:length(fn);lead=fn{k};xyz=getfield(el,lead);
   if (isfield(marked_leads,lead))
       plot(xyz(1),xyz(2),getfield(marked_leads,lead));
   else
        if eegp_isinterior(lead,eegp_opts)
            plot(xyz(1),xyz(2),'r.');
        else
            plot(xyz(1),xyz(2),'k.');
        end
   end
   hold on;
   if (plot_opts.iftext)
       ht=text(xyz(1),xyz(2),lead,'Interpreter','none');
       set(ht,'FontSize',7);
   end
end
plot(eegp_opts.EEGP_CENTER(1),eegp_opts.EEGP_CENTER(2),'k*');
set(gca,'XLim',[-1 1]*max([abs(get(gca,'XLim')),abs(get(gca,'YLim'))]));
set(gca,'YLim',[-1 1]*max([abs(get(gca,'XLim')),abs(get(gca,'YLim'))]));
axis equal;
view (2);
if ~isempty(plot_opts.xlim) xlim(plot_opts.xlim); end
if ~isempty(plot_opts.ylim) ylim(plot_opts.ylim); end
xlabel('x');
ylabel('y');
title(plot_opts.tstring,'Interpreter','none');
return
