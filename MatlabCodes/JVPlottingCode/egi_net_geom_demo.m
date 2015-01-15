% egi_net_geom_demo
%
% demonstrate egi nets
%
plot_opts=[];
plot_opts.iftext=1;
netlists={'eegp','net64','net128','net64t','net128t'};
for inet=1:length(netlists)
    disp(sprintf('%1.0f->%s',inet,netlists{inet}));
end
inets=getinp('choice(s)','d',[1 length(netlists)],[1:length(netlists)]);
eegp_opts=cell(0);
hf=cell(0);
for inetptr=1:length(inets)
    inet=inets(inetptr);
    disp(sprintf('plotting lead placement for %s',netlists{inet}));
    eegp_opts{inet}=egi_eegp_defopts([],netlists{inet});
    [hf{inet},plot_opts_used{inet}]=eegp_plotleads(eegp_opts{inet},setfield(plot_opts,'tstring',netlists{inet}));
end

