
function		[dip,p_value, xlow,xup]=hartiganu(xsamps,nboot,ifplot)

%  function		[dip,p_value,xlow,xup]=hartiganu(xsamps,nboot,ifplot)
%
% adapted from frozen from FM's HartigansDipSignifTest
% JV 20 May 2010 --
% plotting only if ifplot>0 and nboot>0
% if nboot=0, p_value returned as NaN, no error
%
% calculates Hartigan's DIP statistic and its significance for the empirical p.d.f  xsamps (vector of sample values)
% This routine calls the matlab routine hartigan that actually calculates the DIP
% NBOOT is the user-supplied sample size of boot-strap
% Code by F. Mechler (27 August 2002)

% calculate the DIP statistic from the empirical pdf
if (nargin<=1) nboot=0; end
if (nargin<=2) ifplot=0; end
[dip,xlow,xup, ifault, gcm, lcm, mn, mj]=hartigan(xsamps);
N=length(xsamps);

p_value=NaN;
if (nboot>0)
    % calculate a bootstrap sample of size NBOOT of the dip statistic for a uniform pdf of sample size N (the same as empirical pdf)
    boot_dip=[];
    for i=1:nboot
        unifpdfboot=sort(unifrnd(0,1,1,N));
        [unif_dip]=hartigan(unifpdfboot);
    boot_dip=[boot_dip; unif_dip];
    end;
    boot_dip=sort(boot_dip);
    p_value=sum(dip<boot_dip)/nboot;
    %
    % Plot Boot-strap sample and the DIP statistic of the empirical pdf
    if (ifplot>0)
        figure(1); clf;
        [hy,hx]=hist(boot_dip); 
        bar(hx,hy,'k'); hold on;
        plot([dip dip],[0 max(hy)*1.1],'r:');
    end

end
%
%
return

