%mcsds_demo
%demo of dynamical systems for MCS talks
%
% define scenarios
if ~exist('sc')
    sc=cell(0);
end
k=1;
sc{k}.label='respiratory control';
sc{k}.uid='rc_simple';
sc{k}.xlabel='pCO_2';
sc{k}.ylabel='respiratory rate';
% p'=-kp*(r-r0) %variable 1
% r'=kr*(p-p0) %variable 2
sc{k}.params.fp=[.5 .55];
sc{k}.params.kr=1;
sc{k}.params.kp=1;
sc{k}.startpts=repmat(sc{k}.params.fp,4,1)+[.2 0;-.2 0;0 .25;0 -.35];
sc{k}.startpts=repmat(sc{k}.params.fp,6,1)+[.05 0;.15 0;.25 0;-.1 0;-.2 0; -.3 0];
sc{k}.time=6; % total amount of time to run (just less than one cycle, 2pi)
%
k=2;
sc{k}=sc{1};
sc{k}.label=cat(2,sc{1}.label,', with delay');
sc{k}.uid='rc_delay';
% p'=-kp*(r-r0) %variable 1
% r'=kr*(p[delayed by a fraction of a cycle]-p0) %variable 2
sc{k}.params.cycdel=0.05;
sc{k}.time=20; % total amount of time to run
%
k=3;
sc{k}=sc{1};
sc{k}.label=cat(2,sc{1}.label,', with resp rate setpoint');
sc{k}.uid='rc_setpoint';
% p'=-kp*(r-r0) %variable 1
% r'=kr*(p-p0)-ks*(r-r0) %variable 2
sc{k}.params.ks=0.3;
sc{k}.time=20; % total amount of time to run
%
k=4;
sc{k}=sc{1};
sc{k}.label=cat(2,sc{1}.label,', with delay and resp rate setpoint, delay dominates');
sc{k}.uid='rc_delay_setpoint';
% p'=-kp*(r-r0) %variable 1
% r'=kr*(p[delayed by a fraction of a cycle]-p0) -ks*(r-r0) %variable 2
%
sc{k}.params.cycdel=0.05;
sc{k}.params.ks=0.2;
sc{k}.time=20; % total amount of time to run
%
k=5;
sc{k}=sc{1};
sc{k}.label=cat(2,sc{1}.label,', with delay and resp rate setpoint, setpoint dominates');
sc{k}.uid='rc_delay_setpoint';
% p'=-kp*(r-r0) %variable 1
% r'=kr*(p[delayed by a fraction of a cycle]-p0) -ks*(r-r0) %variable 2
%
sc{k}.params.cycdel=0.05;
sc{k}.params.ks=0.7;
sc{k}.time=20; % total amount of time to run
%
k=6;
sc{k}=sc{1};
sc{k}.label=cat(2,sc{1}.label,', with stronger resp rate setpoint');
sc{k}.uid='rc_setpoint';
% p'=-kp*(r-r0) %variable 1
% r'=kr*(p-p0)-ks*(r-r0) %variable 2
sc{k}.params.ks=1.0;
sc{k}.time=20; % total amount of time to run
%
for k=1:length(sc)
    disp(sprintf('%2.0f->%s',k,sc{k}.label));
end %k
sclist=getinp('choice','d',[1 length(sc)],[1:length(sc)]);
for k=sclist
    s=sc{k};
    mcsds_run(s);
end
