function histSVMAllPoints

%make a histogram of the fraction two sided p-values but convert accuracies below
%50% to the left side. [] ask JV if this is how I should do the other
%histogram as well. Make the histogram of fraction of causal, acausal and
%straddle. These depend on the spectrogram window! Make separate plots for
%patients, normals and both.
%
%will do with one-sided p-value since confusing with two sided because
%values far from midline get near zero probability either way and flipping
%sign does nothing. 

paths=uipickfiles('type',{'*.mat','mat'});

for p=1:length(paths)
    s(p)=load(paths{p},'T','allaccs','phat');
    [~,filename{p}]=fileparts(paths{p});
    if sum(strfind(filename{p},'_AllPoints_SVM'));
        filename{p}=filename{p}(1:strfind(filename{p},'_AllPoints_SVM')-1);
    else
        filename{p}=filename{p}(1:strfind(filename{p},'_AllPoints_HalfSecW_SVM')-1);
    end
end

%calculate one-sided p-values
for j=1:length(paths) %for each file
    %first need sum for each time point but allaccs is a cell
    %some of allaccs are nan's but myBinomTest produces a 1 so need to
    %remove these below using phat
    s(j).pvalues=myBinomTest(sum(cell2mat(s(j).allaccs'),2),length(s(j).allaccs{1}),.5,'greater')';%transpose to make a row vector to combine below
end

allPs=[s.pvalues];
allTs=[s.T];
allPhat=[s.phat];
allTs(isnan(allPhat))=[];
allPs(isnan(allPhat))=[];
spacing=20;%spacing is actually 1/spacing but this tells how many bins to make
if allTs(1)==.25 %if half sec moving window
    [a.Ps,X]=hist(allPs(allTs>=.25 & allTs<1.25),spacing);
    st.Ps=hist(allPs(allTs>=1.25 & allTs<1.75),spacing);
    c.Ps=hist(allPs(allTs>=1.75 & allTs<=max(allTs)),spacing);
elseif allTs(1)==.5 %if standard full second moving window
    [a.Ps,X]=hist(allPs(allTs>=.5 & allTs<1),spacing);
    st.Ps=hist(allPs(allTs>=1 & allTs<2),spacing);
    c.Ps=hist(allPs(allTs>=2 & allTs<=max(allTs)),spacing);
end

figure;
set(gcf,'Name','Fraction at each one-sided greater p-value');
bar(X,[(a.Ps/sum(a.Ps))' (st.Ps/sum(st.Ps))' (c.Ps/sum(c.Ps))']);
legend('pre-tone','including tone','post-tone');
xlabel('p-value','FontSize',14);
ylabel('Frequency','FontSize',14);%note not count since we divide by total number in each type
ylim([0 0.5]);
set(gca,'xtick',0:0.1:1,'ytick',0:0.1:0.5,'XMinorTick','on','YMinorTick','on','FontSize',14);