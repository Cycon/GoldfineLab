function plotSVMFeat

%to plot the features of the SVMcode output

%%
%load dataset(s)
pathname=uipickfiles('type',{'*SVM.mat','SVM output'});
%for testing
% pathname{1}='/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/LancetPaper/FinalPatientDatasetDec13/SVMAnalysis/imjl_lancet_150_300_SVM.mat';

for p=1:length(pathname)
    [path{p} filename{p}]=fileparts(pathname{p});
end

%%

for p2=1:length(pathname)%for each file
    %convert the feature vectors into matrices of frequencyrange x channels x
    %time points.
    s=load(pathname{p2},'AllCoeffs','opts','block','type','cloc');
    
    %calculate the coefficients (a.k.a. feature weights)
    for jj=1:length(s.AllCoeffs) %for each dropped block
        %fw is frequency range x channel x time point
        fw{jj}=reshape((s.AllCoeffs{jj}.SupportVectors'*s.AllCoeffs{jj}.Alpha),4,25,[]);
    end
    
    if isfield(s.opts,'specWin') && s.opts.specWin %2/6/12
        space=s.opts.specWin;
        correction=0;
    else
        space=0.01;%default
        correction=0.01;
    end
    
    %plot with all channels averaged together
%     figure;
%     set(gcf,'name',[filename{p2} ' feature weights avg across trials']);
    
    colors={'r','b','g','m'};
%     for p3=1:length(fw)
%         subplot(length(fw),1,p3)
%         title(['Block ' num2str(p3)]);
%         hold on;
%         %plot each frequency range in a different color
%         for p4=1:4
%             plot(s.opts.startTime:.01:s.opts.startTime+s.opts.winLength-.01,squeeze(mean(fw{p3}(p4,:,:),2)),[colors{p4} '*']);         
%         end
%     end
%     allowaxestogrow;
    
    %plot with channels plotted separately
    figure;
    set(gcf,'name',[filename{p2} ' feature weights by channel across trials']);
    
%     colors={'r','b','g','k'};
    for p3=1:length(fw)
        subplot(length(fw),1,p3)
        title(['Block ' num2str(p3)]);
        hold on;
        %plot each frequency range in a different color
        for p4=1:4
            plot(s.opts.startTime:space:s.opts.startTime+s.opts.winLength-correction,abs(squeeze(fw{p3}(p4,:,:))),[colors{p4} '*']);%add '.' at end in ] if using all time points      
        end
    end
    allowaxestogrow;
    
     %plot with only channels containing top % of feature weights for each block 
    figure;
    set(gcf,'name',[filename{p2} ' feature weights by top channels across trials']);
    
    
%     colors={'r','b','g','k'};
    for p3=1:length(fw)
        
        percentile=0.005;
        ranked=abs(sort(fw{p3}(:)));
        cutoff=ranked(round(percentile*length(ranked))); 
        
        subplot(length(fw),1,p3)
        title(['Block ' num2str(p3) ' percentile ' num2str(percentile) ' cutoff ' num2str(cutoff) ]);
        hold on;
        %plot each frequency range in a different color only if that
        %channel has a value above cutoff
        for p4=1:4
            fwp=squeeze(fw{p3}(p4,:,:));%select one frequency range so is channel by time point
            cut=any(abs(fwp)>=cutoff,2);%make a column vector to determine which channels to plot
            fwp(~cut,:)=[];%remove columns not to plot
            if sum(fwp)%if any left to plot
                plot(s.opts.startTime:space:s.opts.startTime+s.opts.winLength-correction,fwp,[colors{p4} '*']);                
            end
        end
    end
    allowaxestogrow;
    
    %plot with best overall channel or best channel at each time point
end
    
