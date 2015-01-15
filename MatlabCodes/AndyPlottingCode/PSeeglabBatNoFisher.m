%this is a script so can pull ALLEEG from the system
%designed to run multiple PSeeglabs at once via runEeglabSpectra.
%uses automatic naming
%don't want all to be same length
%11/29/11 - removed call to Fisher 
%11/29/11 version 2 also modified call to runEeglabSpectra to have opts
%structure. [] need to update to have bipolar option and option for
%averaging of channels like PSeeglab will

function PSeeglabBatNoFisher
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
        [setfilename{PSeeg}, pathname{PSeeg}] = uigetfile('*.set', 'Select EEG to compare in plot(Cancel to not use this or previous selection)',pathname{PSeeg-1});    
        if setfilename{PSeeg}==0 %if press cancel
            PSeeg=PSeeg-2; %if don't have comparison, don't run previous either
            break;
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
  
    

for j=1:PSeeg %to run multiple in a row
    resopts.eegorica='e';
    [S,f,PSresult{j}]=runEeglabSpectra(alleeg{j},resopts); %output on left is to get filename (PSresult) to pass on to Fisher code below.
    %data get reordered as laplacian in runEeglabSpectra subcode
    %     runEeglabSpectra(alleeg{j},'e');
    if ~mod(j,2) %if an even number
      subplotEeglabSpectra([PSresult{j-1}(1:end-3) 'vs' PSresult{j}(1:end-3)],spectra1label,spectra2label,[PSresult{j-1} '.mat'],pwd,[PSresult{j} '.mat'],pwd,0);
      %0 at end is to suppress legend in sig freq plots
      clf;
      close(gcf);
      clf;
      close(gcf);
    end
end