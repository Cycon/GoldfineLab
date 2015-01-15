%eegp_isinterior_demo
% makes a 3-d and 2-d map of leads, showing the interior ones in red
opts=eegp_defopts;
%
ihb=getinp('1 to use a built-in headbox, 2 to augment database from XTPAnalysis/XTPaug','d',[0 2],0);
if (ihb>0)
    if ihb==1
        xtp_build_environment;
    end
    if (ihb==2)
        cofl_build_environment('XTPAnalysis/XTP_aug');
    end
    nhbs=length(XTP_HEADBOXES);
    for ihb=1:nhbs
        disp(sprintf(' %2.0f -> %30s',ihb,XTP_HEADBOXES(ihb).name));
    end
    ihb=getinp('choice','d',[1 nhbs]);
    opts=eegp_selectleads(XTP_HEADBOXES(ihb).lead_list,opts);
    tstring=sprintf('headbox %2.0f: %s',ihb,XTP_HEADBOXES(ihb).name);
else
    tstring='default leads';
end
%
el=opts.EEGP_LEADS;
iftext=getinp('1 to add text labels','d',[0 1],1);
fn=fieldnames(el);
figure;
set(gcf,'Position',[100 100 1300 700]);
set(gcf,'NumberTitle','off');
set(gcf,'Name',tstring);
%
subplot(1,2,1);
for k=1:length(fn);lead=fn{k};xyz=getfield(el,lead);
   if eegp_isinterior(lead,opts)
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
axis vis3d;
view([-18, 22]);
xlabel('x');
ylabel('y');
zlabel('z');
title(tstring);
%
subplot(1,2,2);
for k=1:length(fn);lead=fn{k};xyz=getfield(el,lead);
   if eegp_isinterior(lead,opts)
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
set(gca,'XLim',[-10 10]);
set(gca,'YLim',[-10 10]);
axis equal;
view (2);
xlabel('x');
ylabel('y');
title(tstring);