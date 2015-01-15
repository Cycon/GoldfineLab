function SVMoutput

%just to display number outputs from SVMcode

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
    clear s;
    s=load(pathname{p2},'phat','finalaccu','allaccs','testaccu','pci05','pci01','pci001');
    clear sig;
    sig=' ';
    if s.pci05(1) > 0.5
        sig = '*';
    end
    if s.pci01(1) > 0.5
        sig = '**';
    end
    if s.pci001(1) > 0.5
        sig = '***';
    end
    
    
    fprintf('For %s\n',filename{p2});
    fprintf('mean(testaccu) is %.2f. ',mean(s.testaccu));
    fprintf('phat is %.2f %s \n',100*s.phat,sig);
    fprintf('Accuracy for each run is: ');
    disp(s.testaccu);
    fprintf('\n');
end