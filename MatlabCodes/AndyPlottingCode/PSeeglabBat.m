%this is a script so can pull ALLEEG from the system
%designed to run multiple PSeeglabs at once via runEeglabSpectra.
%does Fisher on every alternate dataset!
%uses automatic naming
%don't want all to be same length

function PSeeglabBat
%%
if isequal(input('Run laplacian (y-yes, otherwise no): ','s'),'y')
    laplacian=1;
else 
    laplacian=0;
end  

disp('SigFreqPlot will have no legend (change code if want legend placed)');
spectra1label='1';
spectra2label='2';
% disp('Do only one task at a time as a batch');
% spectra1label=input('Label for Spectra 1:','s');
% spectra2label=input('Label for Spectra 2:','s');

ds=1;
PSeeg=1;
while 1; %to run multiple in a row
    
    if ~mod(PSeeg,2) %if is an even one result will be 0 and will skip this part
        [setfilename{PSeeg}, pathname{PSeeg}] = uigetfile('*.set', 'Select EEG to compare via Fisher (Cancel to not use this or previous selection)',pathname{PSeeg-1});    
        if setfilename{PSeeg}==0 %if press cancel
            PSeeg=PSeeg-2; %if don't have comparison, don't run previous either
            break;
            %[] fisherFiguretitle{PSeeg}=input('Name of Fisher figure: ','s'); %[]change to automatic like batFisher if possible
        end
        EEG = pop_loadset('filename',setfilename{PSeeg},'filepath',pathname{PSeeg});
%             [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );    
        alleeg{PSeeg}=EEG;
        
        if laplacian
            alleeg{PSeeg}.laplacian=1;
        else
            alleeg{PSeeg}.laplacian=0;
        end
        PSeeg=PSeeg+1;
    
    else
        if PSeeg>2
            [setfilename{PSeeg}, pathname{PSeeg}] = uigetfile('*.set', 'Select 1st EEG file (Cancel to stop)',[pathname{PSeeg-1} '/..']);%to move up one level, doesn't work!
        else
            [setfilename{PSeeg}, pathname{PSeeg}] = uigetfile('*.set', 'Select 1st EEG file (Cancel to stop)');
        end
        if setfilename{PSeeg}==0; %if press cancel for being done
            PSeeg=PSeeg-1;
            break
        end
        EEG = pop_loadset('filename',setfilename{PSeeg},'filepath',pathname{PSeeg});
%             [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );    
        alleeg{PSeeg}=EEG;
        
        if laplacian
            alleeg{PSeeg}.laplacian=1;
        else
            alleeg{PSeeg}.laplacian=0;
        end    
        PSeeg=PSeeg+1;
    end
  
end
    
        %[] add laplacian=1 as a field
        %[] Why can't i just use alleeg?
  
    

for j=1:PSeeg %to run multiple in a row
    [S,f,PSresult{j}]=runEeglabSpectra(alleeg{j},'e'); %output on left is to get filename (PSresult) to pass on to Fisher code below.
    %data get reordered as laplacian in runEeglabSpectra subcode
    %     runEeglabSpectra(alleeg{j},'e');
    if ~mod(j,2) %if an even number
      subplotFisher(PSresult{j-1}(1:end-3),[PSresult{j-1} '.mat'],pwd,[PSresult{j} '.mat'],pwd); %pwd added so knows where to find and save file
      clf; %to help prevent running out of java memory
      close(gcf);
      disp('this code calls older version of subplotEeglabSpectra and not clear if it''s called correctly, 11/29/11');
      subplotEeglabSpectra_v5(PSresult{j-1}(1:end-3),spectra1label,spectra2label,[PSresult{j-1} '.mat'],pwd,[PSresult{j} '.mat'],pwd,pwd,[PSresult{j-1}(1:end-3) '_FisherData.mat'],0);
      %0 at end is to suppress legend in sig freq plots
      clf;
      close(gcf);
      clf;
      close(gcf);
    end
end