function SVMcodeAllBlocksResults
%To display output of SVMcodeAllBlocks
%3/6/12 modified so that it loads them in order and then reorders them later
%3/8/12 tried to modify the figure creation so put all on one figure but
%didn't work.
%3/13/12 again modify the figure ot put all on one but group by subject.

%%
paths=uipickfiles('type',{'*.mat','SVM file'});
for pp=1:length(paths)
    [~,filenames{pp}]=fileparts(paths{pp});
    filenames{pp}=filenames{pp}(1:strfind(filenames{pp},'_AllBlockPairs_SVM')-1);%remove the ending
end
[subjectNumberName,~,orderi,~]=SVMsubjectLookUp(filenames);
subjectName=char(subjectNumberName);%make same length for printing to screen
%%
%this part spits out the accuracies and then full result from myfisher
fprintf('%s\n','Fisher exact by myfisher.m:');
for p=1:length(paths) %changed 3/6 so not for p=order
    %line below changed 3/6 so it's order(n) rather than p
    s(p)=load(paths{p},'numaccu','numwrong','pfisher','pvalue','phat','filename','blockpairs','allaccs');
    disp(subjectNumberName{p});
    %3/14/12 - this is not an accurate p-value since the tests are
    %certainly not independent! So don't show it.
%     fprintf('%.0f blocks. Total p-value is %.6g\n',max(s(p).blockpairs(:)),s(p).pvalue);

    fprintf('%.0f blocks.\n',max(s(p).blockpairs(:)));
    disp([s(p).numaccu;s(p).numwrong]);%correct over incorrect in a table
    fprintf('percent accurate = %.2f, Fisher Exact p = %.4f\n',100*s(p).phat,s(p).pfisher);
    fprintf('\n');
    clear c;%added 2/22/12
end

%%
%this just spits out the Fisher Exact p-values. Note that s is not in the new
%order from above
disp('Fisher Exact Results:');
for j=orderi %to put them in order
    fprintf('%s: %.6g\n',subjectName(j,:),s(j).pfisher);
    fprintf('fraction accurate = %.4f\n',s(j).phat);
end

%%
%make figures showing number correct as a function of distance between the
%blocks. Need the x-axes to all be the maximum distance and ys to be 0 to 1
%with dotted line at 0.5. Also need open rectangle plotted on top
%representing the mean for each distance - don't need range since see all
%the data.

s=s(orderi); %put in correct order
subjectNumberName=subjectNumberName(orderi);

%determine x-axis limits
xmax=max(max(cell2mat({s.blockpairs}')))-1;%need to convert to cell to transpose so can combine
%two max to get rid of second dimension

figure;
[nr,nc]=subplotNumCalc(length(s));
for k=1:length(s)
    subplot(nr,nc,k);
    spacing=abs(diff(s(k).blockpairs,1,2));
    plot(abs(spacing),s(k).numaccu./(s(k).numaccu+s(k).numwrong),'marker','o','markerfacecolor','b','linestyle','none','markersize',4);
    hold on;
    for ss=1:max(spacing)+1%for each spacing range but need to convert to 0 start by subtracting 1 below
        meanvalues(ss)=mean(s(k).numaccu(spacing==ss-1)./(s(k).numaccu(spacing==ss-1)+s(k).numwrong(spacing==ss-1)));
    end
    %     plot(abs(diff(s(k).blockpairs,1,2)),mean(s(k).numaccu./(s(k).numaccu+s(k).numwrong)),'square');%plot the mean as a square
    %plot separate small lines representing means
    plot([(0:max(spacing))-.25;(0:max(spacing))+.25],[meanvalues;meanvalues],'color','r','linewidth',2);
    
    %plot line connecting the means
%     plot(spacing(1:length(meanvalues)),meanvalues,'color','r','linestyle',':','linewidth',2);
    
    %plot 50% line
    plot([-.5 xmax+.5],[50 50],'k:');%50% line
    ylim([0 1]);
    xlim([-.5 xmax+.5]);
%     [cr,cc]=ind2sub([nr,nc],k);
%     if cr==nr
        set(gca,'xtick',0:xmax);
%     else
%         set(gca,'xtick',[]);
%     end
%     if cc==1
        set(gca,'ytick',0:.5:1);
%     else
%         set(gca,'ytick',[]);
%     end
    title(subjectNumberName{k});
    clear meanvalues spacing
end

%%
%this figure has all on one.
% colorlist={'k' 'b' 'c' 'm' 'r' 'y'};
colorlist=varycolor(xmax+1);%to ensure have enough add 1 since spacing starts with 0
colorlist=colorlist(end:-1:1,:);%flip so starts with black
figure;
xlabels={};
xtickLoc=[];
interSubSpace=5;
%  xtickind=1;
for m=1:length(s) %for each subject now ordered as patients and then normals
    spacing=abs(diff(s(m).blockpairs,1,2));
    
    hold on
    for ss=1:length(spacing) %make for loop so can vary the marker face color
        %note xmax is total spacing, can increase it's value to have more
        %between subjects.
        %note spacing starts at 0 so indexing into color list needs to add
        %1 to it.
        plot(spacing(ss)+(xmax+interSubSpace)*(m-1),s(m).numaccu(ss)./(s(m).numaccu(ss)+s(m).numwrong(ss)),'markerfacecolor',colorlist(spacing(ss)+1,:),'marker','o','linestyle','none');
        hold on;
    end
    clear meanvalues %important because created below by adding so shorter ones will have left over from before!
    for s2=1:max(spacing)+1%for each spacing range but need to convert to 0 start by subtracting 1 below
        meanvalues(s2)=mean(s(m).numaccu(spacing==s2-1)./(s(m).numaccu(spacing==s2-1)+s(m).numwrong(spacing==s2-1)));
        %         xlabels{s2+(xmax+interSubSpace)*(m-1)}=num2str(s2-1);
        %          xtickLoc(xtickind)=(s2-1)+(xmax+interSubSpace)*(m-1);
        %          xtickind=xtickind+1;
    end
    xtickLoc=[xtickLoc (0:max(spacing))+(xmax+interSubSpace)*(m-1)];
    xlabels=[xlabels num2cell(0:max(spacing))];
    %      xtickind=xtickind+interSubSpace;
    plot((0:max(spacing))+(xmax+interSubSpace)*(m-1),meanvalues,'color','k','linewidth',2);%plot the mean
    %     for s3
    %      plot((1:max(spacing))+(xmax+interSubSpace)*(m-1),mean(s(m).numaccu(spacing./(s(m).numaccu+s(m).numwrong)),'square');%plot the mean as a square
    %     plot([(0:max(spacing))-.1;(0:max(spacing))+.1],[meanvalues;meanvalues],'g--');
    
    %     ylim([0 100]);
    %     xlim([-.5 xmax+.5]);
    %     set(gca,'xtick',0:xmax);
end
graphXlim=get(gca,'xlim');

% xtickLoc=0:length(xlabels)-1;%but don't want all of them
% xtickLoc=0:graphXlim(2);
% xtickLoc(xtickLoc==0)=[];%since filled in with lots of extra zeros but don't want ticks everywhere
% xtickLoc=[0 xtickLoc];%since want that first 0 in there
set(gca,'xlim',[-.5 graphXlim(2)+.5],'xtick',xtickLoc,'xticklabel',xlabels,'ylim',[0 1]);
plot([-.5 graphXlim(2)+.5],[.5 .5],'k:','linewidth',1);%50% line


