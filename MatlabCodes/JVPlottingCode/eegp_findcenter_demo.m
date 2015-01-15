% eegp_findcenter_demo
% demonstrate eegp_findcenter
niters=getinp('iters','d',[1 10],8);
step=10;
shrink=10;
ys=[-100 step 100];
zs=[-100 step 100];
if ~exist('eegp_opts')
    eegp_opts=[];
end
eegp_opts=eegp_defopts(eegp_opts);
for iter=1:niters
    [ctr,rad,dists,names]=eegp_findcenter(ys,zs,eegp_opts);
    disp(sprintf('iter %2.0f step %12.10f:  ctr [%12.9f %12.9f %12.9f] rad %9.7f scat %9.7f',iter,step,ctr,rad,sqrt(mean((dists-rad).^2))));
    ys=[ctr(2)-2*step step/shrink ctr(2)+2*step];
    zs=[ctr(3)-2*step step/shrink ctr(3)+2*step];
    step=step/shrink;
end
