function [spec]=calculatesurrogatepvalues(spec,SgBaseCorr,btr)


specrand=spec;

for c=1:size(spec(1).Sg,4)
    Alltrials=cat(3,spec(1).Sg(:,:,:,c),spec(2).Sg(:,:,:,c));
    firstcondsize=size(spec(1).Sg(:,:,:,c),3);
    for i=1:1000
        randindex=randperm(size(Alltrials,3));
        specrand(1).Sg(:,:,:,c) = Alltrials(:,:,randindex(1:firstcondsize));
        specrand(2).Sg(:,:,:,c) = Alltrials(:,:,randindex(firstcondsize+1:end));
        
        %calculate for first and second specrandtra
        meanBaseline=mean(specrand(1).Sg(btr,:,:,c),1);%mean of all times
        meanBaseline=mean(meanBaseline,3);% mean across trials
        meanBaseline=repmat(meanBaseline,size(specrand(1).Sg,1),1);%make a 2D matrix same size as rest of data
        meanBaseline2=mean(specrand(2).Sg(btr,:,:,c),1);%[]check this!
        meanBaseline2=mean(meanBaseline2,3);%next mean across trials
        meanBaseline2=repmat(meanBaseline2,size(specrand(2).Sg,1),1);%make a 2D matrix
        
        %Next take mean first to conver to 2D then divide by
        %baseline (same as subtracting the logs)
        SgBaseCorrR(:,:,c)=squeeze(mean(specrand(1).Sg(:,:,:,c),3))./meanBaseline;
        SgBaseCorr2R(:,:,c)=squeeze(mean(specrand(2).Sg(:,:,:,c),3))./meanBaseline2;%dividing by power is same as subtracting log
        
        %calculate for second specrandtra if comparing baseline
        %subtracted specrandtra
        SgBaseCorrrand(:,:,c,i)=SgBaseCorrR(:,:,c)./SgBaseCorr2R(:,:,c);
    end
end

spec(1).dz=SgBaseCorr;


for c=1:size(spec(1).Sg,4)
    for tp=1:size(spec(1).Sg,1) %for each time point including those in baseline
        %dz, vdz and adz are all #of freq x 1
        for fr=1:size(spec(1).Sg,2)
            spec(1).tgtp_value(fr,tp,c)=sum(abs(squeeze(SgBaseCorrrand(tp,fr,c,:)))>abs(squeeze(SgBaseCorr(tp,fr,c))))/1000;
            %[h,spec(1).tgtp_value(fr,tp,c)]=ttest2(squeeze(SgBaseCorr(tp,fr,c)),squeeze(SgBaseCorrrand(tp,fr,c,:)));
        end
    end
end

%p=sum(abs(permDiff)>abs(actDiff))/numPerms;%how many times the absolute value of the permutations are further apart than the actual datasets.