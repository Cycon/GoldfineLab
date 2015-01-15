% mtnormalize_demo
%
% demonstrates proper normalization of mtspectrum and related
%
clear
figure;
g=randn(1000,1);
% s is a smoothed Gaussian noise
s=conv(g,0.1*ones(10,1));
cparams=[];
cparams.tapers=[5,9];
%
%spectrum of s
[p,f]=mtspectrumc(s,cparams);
loglog(f,p,'b');hold on; 
%
%spectrum of s, sampled at every other point
[p2,f2]=mtspectrumc(s(2:2:1000),setfield(cparams,'Fs',0.5));
loglog(f2,p2,'r');hold on;
%
%spectrogram calculated from spectrogram of S, from short segments (limited frequency resolution)
[SgramShort,t,fgramShort]=mtspecgramc(s,[100 100],cparams);
loglog(fgramShort,mean(SgramShort,1),'m.')
%
%spectrogram calculated from spectrogram of S, from longer segments (better frequency resolution)
[Sgram,t,fgram]=mtspecgramc(s,[300 300],cparams);
loglog(fgram,mean(Sgram,1),'g.')
%
%spectrogram calculated from spectrogram of S, from every other point of longer segments (better frequency resolution)
[Sgram2,t,fgram2]=mtspecgramc(s(2:2:1000),[300 300],setfield(cparams,'Fs',0.5));
loglog(fgram2,mean(Sgram2,1),'k.')
%
legend('spec','spec of every other','specgram short','specgram','specgram every other','Location','SouthWest')
xlabel('f')
ylabel('power')
%
%
figure;
[C,phi,S12,S1,S2,f]=coherencyc(s,s,cparams);
loglog(f,S1,'b');hold on;
[C,phi,S12_2,S1_2,S2_2,f_2]=coherencyc(s(2:2:1000),s(2:2:1000),setfield(cparams,'Fs',0.5));
loglog(f_2,S1_2,'r');
cparams.err=[1 0.05];
[C,phi,S12,S1gram,S2,t,fgram]=cohgramc(s,s,[300 300],cparams);
loglog(fgram,mean(S1gram,1),'g.');hold on;
[C,phi,S12_2,S1_2gram,S2_2,t_2,f_2gram]=cohgramc(s(2:2:1000),s(2:2:1000),[300 300],setfield(cparams,'Fs',0.5));
loglog(f_2gram,mean(S1_2gram,1),'k.');
legend('from coh','from coh of every other','from cohgram','from cohgram of every other','Location','SouthWest')
xlabel('f')
ylabel('power')
