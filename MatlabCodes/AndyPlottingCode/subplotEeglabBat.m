
function subplotEeglabBat
%12/5/11 AMG - based on version 2 of PSeeglabBatNoFisher but just to run subplot on a
%bunch of plots in a row with TGT calculation. Meant to compare 2 spectra
%only.
%12/15/11 AMG now select all at once in alternating order


%%
disp('SigFreqPlot will have no legend (change code if want legend placed)');
spectra1label='1';
spectra2label='2';
% disp('Do only one task at a time as a batch');
% spectra1label=input('Label for Spectra 1:','s');
% spectra2label=input('Label for Spectra 2:','s');

PSfile=uipickfiles('type',{'*PS.mat','spectra from PSeeglab'},'prompt','Pick PS.mat files alternating which ones to compare');
% startfolder='pwd';
% PSeeg=1;
% while 1; %to run multiple in a row
%     if ~mod(PSeeg,2) %if even one result will run this part
%         prompttext='Select EEG to compare to or cancel to not use prior selection';
%     else
%         prompttext='Select 1st EEG or press cancel to stop';
%     end
%     PSfile{PSeeg}=uipickfiles('output','char','type',{'*PS.mat','spectra from PSeeglab'},'num',1,'prompt',prompttext,'FilterSpec',startfolder);
%       
%     if isempty(PSfile{PSeeg}) || isnumeric(PSfile{PSeeg})
%         if mod(PSeeg,2) % if is odd meaning multiplier of 2 already selected
%             PSfile=PSfile(1:end-1);
%             PSeeg=PSeeg-1;
%             break
%         else %if 1st one of a pair
%             if PSeeg==1 %if just started
%                 return %end the program
%             else
%                 break
%             end
%         end
%     end
%     [PSpath{PSeeg} PSfilename{PSeeg}]=fileparts(PSfile{PSeeg}); 
%     startfolder=PSpath{PSeeg};
%     PSeeg=PSeeg+1;
%   
% end
  
for ff=1:length(PSfile)
    [PSpath{ff} PSfilename{ff}]=fileparts(PSfile{ff});
end
    

for j=1:2:length(PSfile) %for every other
      subplotEeglabSpectra([PSfilename{j} '_vs_' PSfilename{j+1}],spectra1label,spectra2label,[PSfilename{j} '.mat'],PSpath{j},[PSfilename{j+1} '.mat'],PSpath{j},0);
      %0 at end is to suppress legend in sig freq plots
      clf;
      close(gcf);
      clf;
      close(gcf);
end