% function SVMFisherExact
%To determine the p-value of the chi-squared but using Fisher exact of
%independence of the blocks for a subject.

%2/22/12 added clear c at end of each part of the code because if subject
%had fewer blocks than previous, it was leaving in the end block(s) of the
%previous subject leading to more blocks than there actually were and false
%results.

%%
clear
paths=uipickfiles('type',{'*SVM.mat','SVM file'});

%%
%this part calculates and then spits out the full result from myfisher
fprintf('%s\n','Fisher exact by myfisher.m:');
for p=1:length(paths)
    s=load(paths{p});
    ub=unique(s.block);
    nb=length(ub);
    for b=1:nb
        c(1,b)=sum(s.allaccs(s.block==ub(b)));%sum of the 1s
        c(2,b)=sum(~s.allaccs(s.block==ub(b)));%sum of the 0s
    end
    [~,filename{p}]=fileparts(paths{p});
    disp(filename{p});
    disp(c);
    P(p)=myfisher(c);
    fprintf('\n');
    clear c;%added 2/22/12
end

%%
%this just spits out the p-values
for j=1:length(filename)
    fprintf('%s - %.4g\n',filename{j},P(j));
end

%%
%here want to display and calculate fisher on whether the previous value
%was the same (correct or incorrect). Need a table using only 2nd through
%end trials correct / incorrect and whether previous was correct or
%incorrect
for p=1:length(paths)
    s=load(paths{p});
    ub=unique(s.block);
    nb=length(ub);
    c=zeros(2,2);%initialize it
    for b=1:nb
        baccs=s.allaccs(s.block==ub(b));% the ones for this block starting with 2nd
        accsdiff=diff(baccs);%2nd minus the first so 1 is 1-0, -1 is 0-1 and 0 is either 1-1 or 0-0       
        c(1,1)=c(1,1)+sum(accsdiff==0 & baccs(2:end)==1);%correct where previous was correct
        c(1,2)=c(1,2)+sum(accsdiff==1);%correct where previous was incorrect
        c(2,1)=c(2,1)+sum(accsdiff==-1); %incorrect but previous correct so -1
        c(2,2)=c(2,2)+sum(accsdiff==0 & baccs(2:end)==0);%incorrect where previous incorrect
    end
    [~,filename{p}]=fileparts(paths{p});
    disp(filename{p});
    disp(c);
    P(p,:)=myfisher22(c);%p is left then right then 2-sided
    fprintf('\n');
    clear c;%added 2/22/12
end

%%
for f=1:length(filename)
    filename{f}=filename{f}(1:end-12);
end

%%
for i=1:size(P,1)
    fnameprint=char(filename);%to make the filenames all the same length!
    fprintf('%s\t %.4g \t%.4g \t%.4g\n',fnameprint(i,:),P(i,1),P(i,2),P(i,3));
end
