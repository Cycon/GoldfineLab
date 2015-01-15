function opts_used=eegp_wireframe(wire_table,lead_names,opts)
% opts_used=cofl_wireframe(opts) draws a wireframe, optionally labeled
%
%  wire_table: symmetric matrix in which a nonzero element indicates a
%     connection between nodes
%     best if the wires connect nearest neighbors.  One way to do this is
%       wire_table=cofl_xtp_makemont(montage_recorded,montage_recorded,setfield([],'mont_mode','Laplacian'));
%  lead_names: a list of labels for the nodes
%  opts: various options
%    opts.eegp_opts:  eegp_opts used in EEGP routines
%    opts.headmap_*: styles, etc
%
%  See also:  EEGP_ARCPTS
%
if (nargin<=2) opts=[]; end
opts=filldefault(opts,'eegp_opts',[]);
opts=filldefault(opts,'font_size',8);
opts=filldefault(opts,'headmap_narc',10);
opts=filldefault(opts,'headmap_style',0); %headmap style
% 0->2d, 1->3d, 2->3d with chords for interhemispheric
opts=filldefault(opts,'headmap_view',0); %view parameters (if nonzero)
opts=filldefault(opts,'headmap_iflabel',1); %default is to put labels on
opts=filldefault(opts,'headmap_labels',[]); %if non-empty, a list of which leads to label
%      if empty, all or none are labeled, as controlled by headmap_iflabel
opts_used=opts;
%
for k1=1:size(wire_table,1)
    for k2=1:k1
        if ~(wire_table(k1,k2)==0) | ~(wire_table(k2,k1)==0)
            coords_cart=eegp_arcpts(lead_names{k1},lead_names{k2},opts.headmap_narc,opts.eegp_opts);
            if (k1==k2) % if self, then just label
                if (opts.headmap_iflabel)
                    islisted=strmatch(upper(lead_names{k1}),upper(opts.headmap_labels),'exact');
                    if ~isempty(islisted) | isempty(opts.headmap_labels)
                        ht=text(coords_cart(1,1),coords_cart(1,2),coords_cart(1,3),lead_names{k1});
                        set(ht,'FontSize',opts.font_size);
                    end
                end
            else %if not self, then draw an arc
                if (opts.headmap_style==0)
                    hp=plot(coords_cart(:,1),coords_cart(:,2),'k'); hold on;
                else
                    hp=plot3(coords_cart(:,1),coords_cart(:,2),coords_cart(:,3),'k'); hold on;
                end
            end
        end
    end
end
% set up the view
if (opts.headmap_style==0)
    axis equal;view(2);
else
    axis vis3d;view(3);
    if length(opts.headmap_view)>1
        view(opts.headmap_view);
    end
end
return
