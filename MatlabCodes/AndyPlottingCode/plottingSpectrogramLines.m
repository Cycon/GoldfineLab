% load('IMJL_RhandAll_100Hz_SG.mat')
path=uipickfiles('type',{'*SG.mat','SG'},'out','char');
load(path);
%%
spec=S{7};
% spece1=squeeze(Serr{7}(1,:,:));
% spece2=squeeze(Serr{7}(2,:,:));
time=t{7};
fr=f{7};
bsspec=spec./repmat(mean(spec(time>=1 & time<=1.5,:)),46,1);
% figure;
% imagesc(time,fr(fr>=7 & fr<=30),10*log10(bsspec(:,fr>=7 & fr<=30)'),[-2 2])
% bsspecerr1=spece1./repmat(mean(spece1(time>=1 & time<=1.5,:)),46,1);
% bsspecerr2=spece2./repmat(mean(spece2(time>=1 & time<=1.5,:)),46,1);
% figure;
% subplot(3,1,1);imagesc(time,fr(fr>=7 & fr<=30),10*log10(bsspecerr1(:,fr>=7 & fr<=30)'),[-2 2])
% subplot(3,1,2);imagesc(time,fr(fr>=7 & fr<=30),10*log10(bsspec(:,fr>=7 & fr<=30)'),[-2 2])
% subplot(3,1,3);imagesc(time,fr(fr>=7 & fr<=30),10*log10(bsspecerr2(:,fr>=7 & fr<=30)'),[-2 2])

%the above won't be that helpful since the mean subtracted of the upper and
%lower error bounds look similar to the baseline subtracted of the reular,
%becaue the baselines move up / down accordingly. Really want to see with
%baseline as the same in all three, but not sure that makes sense.

%instead try simply plotting the time course of the mean power in each
%range in the study.
%%
franges=[7 13;13 19;19 25;25 30];
colors={'b','r','g','k'};
figure;
for a=1:4%for each frequency range
    plot(time,mean(10*log10(bsspec(:,fr>=franges(a,1) & fr<=franges(a,2))),2),colors{a});
    hold on;
end
xlim([0.5 5]);
ylim([-2 2]);
% legend('7-13','13-19','19-25','25-30');