function opts_used=eegp_wireframe_data(wireframe_data,opts)
% opts_used=eegp_wireframe_data(opts) plots lead-based or pair-based data on an EEG wireframe
%
%  wireframe_data: data structure 
%       these fields are for pair-based data (e.g., coherence); omit if no pair data
%     wireframe_data.pairlabel{k,m}: (m=1,2) the strings for the kth eeg lead pair
%     wireframe_data.paircolor(k,:):  the rgb triplet for the kth eeg lead pair
%     wireframe_data.pairwidth(k):   line width for the kth pair
%       these fields are for lead-based data (e.g., power), omit if no lead-oriented data
%     wireframe_data.leadlabel{r}:  rth lead label
%     wireframe_data.leadcolor(r,:):  rgb triplet for the rth lead
%     wireframe_data.leadsize(r):   marker size for the rth lead
%
%  opts: various options
%    opts.eegp_opts:  eegp_opts used in EEGP routines
%    opts.headmap_*: styles, etc
%
% for lead-oriented data, can also use eeglab's topoplot, along with EEGP_MAKECHANLOCS to define
%   lead locations
%
%  See also:  EEGP_ARCPTS, EEGP_WIREFRAME, TOPOPLOT, EEGP_MAKECHANLOCS.
%
if (nargin<=1) opts=[]; end
opts=filldefault(opts,'eegp_opts',[]);
opts=filldefault(opts,'headmap_narc',10);
opts=filldefault(opts,'headmap_style',0); %headmap style, 0->2d, 1->3d, 2->3d with chords for interhemispheric
opts=filldefault(opts,'headmap_view',0); %view parameters (if nonzero)
opts_used=opts;
%
if isfield(wireframe_data,'pairlabel')
    npairs=size(wireframe_data.pairlabel,1);
    for ipair=1:npairs
        narc=opts.headmap_narc;
        for m=1:2
            lead{m}=wireframe_data.pairlabel{ipair,m};
        end
        if (opts.headmap_style==2) & (eegp_side(lead{1},opts.eegp_opts)+eegp_side(lead{2},opts.eegp_opts)) ==0
            narc=0; %chord
        end
        coords_cart=eegp_arcpts(lead{1},lead{2},narc,opts.eegp_opts);
        if (opts.headmap_style==0)
            hp=plot(coords_cart(:,1),coords_cart(:,2),'k'); hold on;
        else
            hp=plot3(coords_cart(:,1),coords_cart(:,2),coords_cart(:,3),'k'); hold on;
        end
        set(hp,'Color',wireframe_data.paircolor(ipair,:),'LineWidth',wireframe_data.pairwidth(ipair));
    end
end
%
if isfield(wireframe_data,'leadlabel')
    nleads=length(wireframe_data.leadlabel);
    for ilead=1:nleads
        coords_cart=eegp_cart(wireframe_data.leadlabel{ilead},opts.eegp_opts);
        if (opts.headmap_style==0)
            hp=plot(coords_cart(:,1),coords_cart(:,2),'.'); hold on;
        else
            hp=plot3(coords_cart(:,1),coords_cart(:,2),coords_cart(:,3),'.'); hold on;
        end
        set(hp,'Color',wireframe_data.leadcolor(ilead,:),'MarkerSize',wireframe_data.leadsize(ilead));
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
