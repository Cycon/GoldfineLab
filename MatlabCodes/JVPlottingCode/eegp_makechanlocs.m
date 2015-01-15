function [chanlocs,optsused]=eegp_makechanlocs(leads,opts)
% [chanlocs,optsused]=eegp_makechanlocs(leads,opts,cang) creates a 'chanlocs'
% structure used by EEGLAB for topoplot
%
% leads: a string or an array of strings, specifying a lead
% opts: an array of options, see eegp_defopts
%
% chanlocs:  a structure array, as used by topoplot.
%    determined by reverse-engineering, only some fields are used, but
%    these seem to be sufficient to use topoplot.
%    Order of entries in chanlocs matches those in leads.
%
%
% example: 
% topoplot([],eegp_makechanlocs(leads),'electrodes','labels','style','blank')
% will make a blank headmap showing the positions of the leads in the character array 'leads'
%
% See also:  EEGP_CART, EEGP_POLAR.
%

if (nargin<=1) opts=[]; end
opts=eegp_defopts(opts);
optsused=opts;                                 

c=eegp_cart(leads,opts); % x,y,z
p=eegp_polar(leads,opts); %r, theta, phi
rmax=max(eegp_polar('Cz',opts));
chanlocs=struct([]);
for k=1:size(leads,1)                              
    chanlocs(k).labels=deblank(leads(k,:));
    chanlocs(k).type=k;
    chanlocs(k).X=c(k,2);
    chanlocs(k).Y=c(k,1);
    chanlocs(k).Z=c(k,3);
    phi=p(k,3);
    theta=p(k,2);
    %eegp_polar(C3) has phi=pi, chanlocs needs theta=-90
    %eegp_polar(C4) has phi=0, chanlocs needs theta=90
    %eegp_polar(Fz) has phi=pi/2, chanlocs needs theta=0
    chanlocs(k).theta=180.*(pi/2-phi)/pi;
    %convert polar opening-up angle to a value in opts.eeglab_edgeang maps to 0.5
    chanlocs(k).radius=0.5*theta/opts.eeglab_edgeang;
end
return
