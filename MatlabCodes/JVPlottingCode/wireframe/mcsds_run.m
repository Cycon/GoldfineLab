function mcsds_run(s)
%demo of dynamical systems for MCS talks
%s: structure defined in mcsds_demo
%sclist: list of scenarios to use
%
%  See also:  MCSDS_DEMO, QUIVER.
%
% need to reorganize calculation of vector field into a subroutine
%
s=filldefault(s,'nsamp_vf',16);
s=filldefault(s,'time',2.*pi*1.01); %total time
s=filldefault(s,'dt',0.002); %time step
s=filldefault(s,'nsamp_traj',round(s.time/s.dt)); % number of time steps in a trajectory
s=filldefault(s,'ndt_vf',0); %number of dts for each vf along a trajectory
s=filldefault(s,'title',s.label);
s=filldefault(s,'xlim',[0 1]);
s=filldefault(s,'ylim',[0 1]);
s=filldefault(s,'xtick',[]);
s=filldefault(s,'ytick',[]);
s=filldefault(s,'startpts',[]);
s=filldefault(s,'xvals',s.xlim(1)+(s.xlim(2)-s.xlim(1))*([1:s.nsamp_vf]-0.5)/s.nsamp_vf);
s=filldefault(s,'yvals',s.ylim(1)+(s.ylim(2)-s.ylim(1))*([1:s.nsamp_vf]-0.5)/s.nsamp_vf);
s=filldefault(s,'arrowpower',0.5);     %power law to uniformize arrow lengths (1=no uniformization)
s=filldefault(s,'arrowscale',0.7);
s=filldefault(s,'dotsize',12);
s=filldefault(s,'nullcline_thick',1);
s=filldefault(s,'nullcline_type',':');
s=filldefault(s,'ywall',20); %a steep wall to prevent runaway pCO2; 5 is reasonable
s=filldefault(s,'ywall_pwr',3); %a steep wall to prevent runaway pCO2
s=filldefault(s,'ywall_thr',0.25); %threshold for wall
s=filldefault(s,'traj_colors','rgbmcy');
for istage=0:3
    figure;
    p=s.params;
    set(gcf,'NumberTitle','off');
    set(gcf,'Name',sprintf('stage %1.0f %s',istage,s.label));
    plot(p.fp(1),p.fp(2),'k.','MarkerSize',s.dotsize);
    hold on;
    if (istage>0)
        set(gca,'XTick',s.xtick);
        set(gca,'YTick',s.ytick);
    end
    [x,y]=meshgrid(s.xvals,s.yvals);
    %
    %draw vector field
    [x_vf,y_vf]=mcsds_run_vf(s,x,y);
    vn=(x_vf.*x_vf+y_vf.*y_vf).^(s.arrowpower/2);
    vn(find(vn==0))=1;
    hquiver=quiver(x,y,x_vf./vn,y_vf./vn,s.arrowscale,'k');
    %draw trajectories
    if istage>=2
        vtraj=cell(size(s.startpts,1),1); %for trajectories
        hvtraj=cell(length(vtraj),1); %for trajectories
        for it=1:size(s.startpts,1);
            vtraj{it}=s.startpts(it,:);
            [x_df,y_df]=mcsds_run_vf(s,vtraj{it}(1,1),vtraj{it}(1,2));
            for idt=1:s.nsamp_traj
                [x_df(idt+1),y_df(idt+1)]=mcsds_run_vf(s,vtraj{it}(end,1),vtraj{it}(end,2));
                vtraj{it}=[vtraj{it};vtraj{it}(end,:)+s.dt*[x_df(idt),y_df(idt)]];
            end %idt
            tcolor=s.traj_colors(1+mod(it-1,length(s.traj_colors)));
            hvtraj{it}=plot(vtraj{it}(:,1),vtraj{it}(:,2),cat(2,tcolor,'-'));
            plot(vtraj{it}(1,1),vtraj{it}(1,2),cat(2,tcolor,'.'),'MarkerSize',s.dotsize);
            plot(vtraj{it}(end,1),vtraj{it}(end,2),cat(2,tcolor,'*'));
            if (s.ndt_vf>0)
                vflist=[1:s.ndt_vf:s.nsamp_traj];
                hvq=quiver(vtraj{it}(vflist,1),vtraj{it}(vflist,2),x_df(vflist),y_df(vflist),'r-');
            end
        end
     end
     %draw nullclines
     if istage>=3
        vnull=mcsds_run_nullcline(s);
        hvnull=cell(length(vnull),1); %for nullclines
        for iv=1:length(vnull)
            if ~isempty(vnull{iv})
                hvnull{iv}=plot(vnull{iv}(:,1),vnull{iv}(:,2),...
                cat(2,'k',s.nullcline_type),'LineWidth',s.nullcline_thick);
            end
        end
    end
    set(gca,'XLim',s.xlim);
    set(gca,'YLim',s.ylim);
    xlabel(s.xlabel); 
    ylabel(s.ylabel);
    title(s.title); 
end %istage
%
function vnull=mcsds_run_nullcline(s)
%
%calculate nullclines; vnull{ivar}=columns of coordinates
%
vnull=cell(2,1); %for nullclines
p=s.params;
switch s.uid
    case 'rc_simple'
        vnull{1}=[s.xlim',repmat(p.fp(2),2,1)];
        vnull{2}=[repmat(p.fp(1),2,1),s.ylim'];
    case 'rc_delay'
        vnull{1}=[s.xlim',repmat(p.fp(2),2,1)];
        vnull{2}=[p.fp(1)+tan(p.cycdel*2*pi)*(s.ylim'-p.fp(2)),s.ylim'];;
    case 'rc_setpoint'
    case 'rc_delay_setpoint'
end
return
function [xv,yv]=mcsds_run_vf(s,x,y)
%
%calculate vector field
%
p=s.params;
switch s.uid
    case 'rc_simple'
        xv=-p.kp*(y-p.fp(2));
        yv=p.kr*(x-p.fp(1));
    case 'rc_delay'
        xd=p.fp(1)+cos(p.cycdel*2*pi)*(x-p.fp(1))+sin(p.cycdel*2*pi)*(y-p.fp(2));
        xv=-p.kp*(y-p.fp(2));
        yv=p.kr*(xd-p.fp(1));
    case 'rc_setpoint'
        xv=-p.kp*(y-p.fp(2));
        yv=p.kr*(x-p.fp(1))-p.ks*(y-p.fp(2));
    case 'rc_delay_setpoint'
        xd=p.fp(1)+cos(p.cycdel*2*pi)*(x-p.fp(1))+sin(p.cycdel*2*pi)*(y-p.fp(2));
        xv=-p.kp*(y-p.fp(2));
        yv=p.kr*(xd-p.fp(1))-p.ks*(y-p.fp(2));
end
ywi=max((abs(y-p.fp(2))-s.ywall_thr),0);
yv=yv-s.ywall*ywi.^s.ywall_pwr.*sign(y-p.fp(2));
return
