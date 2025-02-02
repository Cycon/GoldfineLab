function PCACoherenceEeglab(varargin)

%1. pull up all ICA pruned datasets to compare (task and rest)
%2. run svd on combined data 
%3. run cross spectral matrix (and coherences for plotting?) on PCs from each dataset separately. Ensure
%to run spectra as well (cross spectra to itself). May want to choose
%number of PCs ahead of time or based on amount of variance accounted for.
%May want to plot the eigenvalues (themselves?) or plot variance accounted
%for (see varexplainedICA code for methods).
%4. plot comparisons of PC coherences to look for differences, run tgt, save outputs
%5. reconstruct cross spectra and divide by powers to get coherences for each PC comparison in
%channel space giving a different set of coherent networks for each PC
%comparison.

%%
%select and load .set files
savename=input('Savename: ','s');
more=1;
while more
    selectText=sprintf('Select Set file %.0f for combining or Cancel',more);
    [setfilename{more}, pathname{more}] = uigetfile('*.set', selectText);
    if setfilename{1}==0
        return;
    end
    if setfilename{more}==0
        setfilename=setfilename(1:more-1);
        more=0;
    else
        more=more+1;
    end
end


%load datasets
combinedData=[];
for e=1:length(setfilename)
   eeg{e}=pop_loadset('filename',setfilename{e},'filepath',pathname{e});
   numTrials(e)=size(eeg{e}.data,3);
   trialLength(e)=size(eeg{e}.data,2);
   numChannels(e)=size(eeg{e}.data,1);
   combinedData=[combinedData;reshape(eeg{e}.data,size(eeg{e}.data,1),[])']; %remove 3rd Dimension and stack
end
  
%%
   

%run pca on combined dataset
[coeff,score,latent]=princomp(combinedData); %score is the PCs, coeff is how to
% switch back
%to get original data back: dataRecon=score*coeff'; each is observations x
%components so need to transpose coeff
% can do cumsum(latent)./sum(latent)
% or 100*latent/sum(latent) %note latent is same as variances

%next reshape data to be like the originals
PCs{1}=reshape(score(1:numTrials(1)*trialLength(1),:)',size(eeg{1}.data));
PCs{2}=reshape(score(numTrials(1)*trialLength(1)+1:end,:)',size(eeg{2}.data));

%%
%probably good to do spectra now and compare the components between the 2
%tasks
params.Fs=eeg{1}.srate;
%conditions
params.Fs=256;
params.trialave=1; params.tapers=[3 5];params.fpass=[0 100]; params.err=[2 0.05];
%do first dataset and then second, in future can allow for more than two.
%%this code isn't finished!
PCSpectraFigure=figure;
for s=1:4 %for first four components. Save as PC. so can use later for PC.C for coherences
    [PC.S{1}{s},PC.Sf,PC.Serr{1}{s}]=mtspectrumc(squeeze(PCs{1}(s,:,:)),params);%looking at 1 component across all datapoints and epochs

    [PC.S{2}{s},PC.Sf,PC.Serr{2}{s}]=mtspectrumc(squeeze(PCs{2}(s,:,:)),params);
    subplot(2,2,s);
    errorBars1=fill([PC.Sf fliplr(PC.Sf)],[10*log10(PC.Serr{1}{s}(1,:)) 10*log10(fliplr(PC.Serr{1}{s}(2,:)))],'r','HandleVisibility','off');
    set(errorBars1,'linestyle','none','facealpha',0.2); %to make the fill transparent
    hold on;
    plot(PC.Sf,10*log10(PC.S{1}{s}),'r','LineWidth',2); 
    errorBars2=fill([PC.Sf fliplr(PC.Sf)],[10*log10(PC.Serr{2}{s}(1,:)) 10*log10(fliplr(PC.Serr{2}{s}(2,:)))],'b','HandleVisibility','off');
    set(errorBars2,'linestyle','none','facealpha',0.2); %to make the fill transparent
    plot(PC.Sf,10*log10(PC.S{2}{s}),'b','LineWidth',2); 
    titletext=sprintf('Component %.0f, %.0f% of Var',s,100*latent(s)/sum(latent));
    title(titletext);
end
allowaxestogrow;
PSfigurename=[savename '_PC_Spectra'];
saveas(PCSpectraFigure,PSfigurename,'fig');

%%
% next for interest make figure of coherence between all combinations of
% PCs
params.tapers=[9 17];
combinations=nchoosek(1:4,2);
CohFigure=figure;
for c=1:size(combinations,1) %for each row of combinations
    for st=1:2 %for each dataset
        [PC.C{st}{c},PC.phi{st}{c},PC.S12{st}{c},S1,S2,PC.Cf,PC.confC{st}{c},PC.phistd{st}{c},PC.Cerr{st}{c}]=coherencyc(squeeze(PCs{st}(combinations(c,1),:,:)),squeeze(PCs{st}(combinations(c,2),:,:)),params);
    end
    subplot(2,3,c);
    errorBars3=fill([PC.Cf fliplr(PC.Cf)],[PC.Cerr{1}{c}(1,:) fliplr(PC.Cerr{1}{c}(2,:))],'r','HandleVisibility','off');
    set(errorBars3,'linestyle','none','facealpha',0.2); %to make the fill transparent
    hold on;
    plot(PC.Cf,PC.C{1}{c},'r','LineWidth',2); 
    errorBars4=fill([PC.Cf fliplr(PC.Cf)],[PC.Cerr{2}{c}(1,:) fliplr(PC.Cerr{2}{c}(2,:))],'b','HandleVisibility','off');
    set(errorBars4,'linestyle','none','facealpha',0.2); %to make the fill transparent
    plot(PC.Cf,PC.C{2}{c},'b','LineWidth',2); 
    titletext=sprintf('Components %.0f and %.0f',combinations(c,1),combinations(c,2));
    title(titletext);
    axis([params.fpass(1) params.fpass(2) 0 1]);
    %need to add in TGT code here to run, plot and save. Ensure change 
    %coherence code to output J1 and J2 to save time
end
allowaxestogrow;
Cohfigurename=[savename '_Coh_Spectra'];
saveas(CohFigure,Cohfigurename,'fig');

%%
%save PCs and spectra and coherences on them and names of data 
save([savename '_PCdataAndSpectra'],'setfilename','coeff','score','latent','PC','combinations');
%%
%next step is to do what JV said with the cross spectra and convert back to
%channel space