function plotSVMAllPoints

%3/27 added option for MCS subjects so can plot original accuracy line
%%
paths=uipickfiles('type',{'*.mat','mat'});
numplots=length(paths);
[nr,nc]=subplotNumCalc(numplots);

for p=1:length(paths)
    s(p)=load(paths{p},'T','pvalue','phat','allaccs');
    [~,filename{p}]=fileparts(paths{p});
    if sum(strfind(filename{p},'_AllPoints_SVM'));
        filename{p}=filename{p}(1:strfind(filename{p},'_AllPoints_SVM')-1);
    else
        filename{p}=filename{p}(1:strfind(filename{p},'_AllPoints_HalfSecW_SVM')-1);
    end
    s(p).pvalue(isnan(s(p).phat))=NaN;%since it gives a false p-value
end

%%
%rename the plots and reorder the figures to be patients then controls

[plotName,~,sortOrder,PaperAccuracy]=SVMsubjectLookUp(filename(1:end));%not actually used here but don't feel like mucking with it
if sum(strfind(filename{1},'01MCS')) %if an MCS subject, use list pasted below
    PaperAccuracy=[0.601694915254237,0.556650246305419,0.450000000000000,0.535433070866142,0.549618320610687,0.398305084745763,0.589595375722543,0.550561797752809,0.735632183908046,0.623595505617978,0.705882352941177,0.536000000000000,0.400000000000000,0.612676056338028,0.398009950248756,0.511278195488722,0.761363636363636,0.503030303030303,0.685185185185185,0.583815028901734,0.502994011976048,0.641025641025641,0.473214285714286];
end
% [plotName,plotOrder,sortOrder,PaperAccuracy]=SVMsubjectLookUp(filename(1:end/2));%version for when plotted two versions on one plot
s(1:end)=s(sortOrder);
plotName=plotName(sortOrder);
PaperAccuracy=PaperAccuracy(sortOrder);


% figure
% set(gcf,'Name','-log P-values');
% for p2=1:numplots
%     subplot(nr,nc,p2);
%     plot(s(p2).T,-log10(s(p2).pvalue));
%     set(gca,'ylim',[0 6]);
%     title(filename{p2});
% end
%%
yrange=[30 100];
fh=figure;
set(gcf,'Name','Accuracies');
 for p3=1:numplots
%     p3=1;%for debugging
    sh(p3)=subplot(nr,nc,p3,'parent',fh);
    %figure out current row and column index to decide on labeling later
    [cc,cr]=ind2sub([nr nc],p3);
    
    plot(-1.5+s(p3).T,100*s(p3).phat);%plot the accuracies
    hold on;
    plot([.5 3.5],[PaperAccuracy(p3)*100;PaperAccuracy(p3)*100],'k','linewidth',2);%original accuracy
   
%     text('parent',fh,'units','normalized','position',[.05 .45],'string','Accuracies','fontsize',12,'rotation',90);
    %put lines on the graph representing different p-values
    numtrials=length(s(p3).allaccs{1});
    %note that binoinv does a 1-sided p-value (see email from JV 2/16/12)
    %so need to divide the p-value input by 2 to get a 2-sided output. Do
    %1- before hand to get the values greater than .5*numtrials and put the
    %10^-1.3 at the beginning to get an additional 0.05 on the other side.
    plines=binoinv([[10^-3 10^-2 10^-1.3]/2 1-[10^-1.3 10^-2 10^-3 10^-6 10^-9]/2],numtrials,.5);
    acclines=100*plines/numtrials; %convert to accuracy 
    
    cmap=colormap('spring');%gives 64 colors, red to yellow
    colororderr=[cmap(64/2,:);cmap(64/4,:);cmap(1,:);cmap(1,:);cmap(64/4,:);cmap(64/2,:);cmap(64*.75,:);cmap(end,:)];
    set(gca,'colororder',colororderr);
%     ph=plot([-1.5+min(s(p3).T); -1.5+max(s(p3).T)],[acclines;acclines]); %line for p-values using colororder set above
    ph=plot([-1.5 4],[acclines;acclines]); 
    
    %legend
    lh=legend(ph,'0.001','0.01','0.05','0.05','0.01','0.001','10^-6','10^-9');
    if cc==nc && cr==1
%         set(lh,'location','NorthEastOutside');
        set(lh,'position',[0.95 0.8 0.03 0.18]);
    else
        set(lh,'Visible','Off');
    end
    plot([0 0],yrange,'r--');%a line where the beep occurs
%     plot([min(s(p3).T-1.5) max(s(p3).T-1.5)],[50 50],'k--');
    plot([-1.5 4],[50 50],'k--');
%     if cc==1 %if first column
%         ylabel('% Accurate','fontsize',12);
%     end
%     if cr==nr %if final row
%         xlabel('Time','fontsize',12);
%     end
%     set(gca,'xticklabel',(min(s(p3).T)-1.5:.5:max(s(p3).T)-1.5));

     ylim(yrange);
%      xlim([-1.5+min(s(p3).T); -1.5+max(s(p3).T)]);
    xlim([-1.5 4]);
%     title(filename{p3},'fontsize',12);
    title(plotName{p3},'fontsize',12,'interpreter','none');
    
    %instead of hold on, use a different set of axes so can have labels as
    %p-values
   
%      drawnow;
%      ax2 = axes('Position',get(sh(p3),'Position'));
%         %note plot below is a matrix in y so does a different line for each
%         %column (since rows corresponds to the length of x)
%          
%          set(ax2,'Color','none','XTick',[],'YAxisLocation','right','YColor','k','YTick',acclines,'YTicklabel',{'0.05','0.05','0.01','0.001','10^-6','10^-9'});
%           ylim([40 100]);
%          xlim([-1.5+min(s(p3).T); -1.5+max(s(p3).T)]);
%          if cc==nc %if in the final column 
%             ylabel('p-value','fontsize',12);
%          end
%           xlim([0 max(s(p3).T)+.5]);doesn't work well because only
%           changes the second axis.
   %can't use line next because it's a patch object and hides everything
   %else
%     line(repmat([min(s(p3).T); max(s(p3).T)],1,length(plines)),[acclines;acclines],'color','b','parent',ax2);

end
 %consider changing below to use annotation arrow since can rotate it but
 %then hide the arrow itself
 
 yh=annotation('textarrow',[.05 .05],[.5 .5],'string','% Accurate Trials','HeadStyle','none','LineStyle', 'none', 'TextRotation',90,'FontSize',14);
 xh=annotation('textarrow',[.5 .5],[.05 .05],'string','Time (sec)','HeadStyle','none','LineStyle', 'none','FontSize',14);
% [~,yh]=suplabel('Accuracies','y');
% [~,xh]=suplabel('Time','x');
set([xh yh],'fontsize',14);