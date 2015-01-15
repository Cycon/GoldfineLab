%this is a script so can pull ALLEEG from the system
%designed to concatenate multiple eeg runs and send to runEeglabSpectra
%Also determines min length to ensure all the same.
%%
%need to change to add to previous and only send one to runEeglabSpectra
%need to load them all in and then determine the minimum length and then
%combine them and send them.
%version 2 9/2/10 for running Fisher and subplot immediately after
    %calculating and getting Hjorth Laplacian to run in runEeglabSpectra
%11/29/11 calls v5 of 

function PSeeglabCombined
%%

disp('This code doesn''t work with new version of runEeglabSpectra, need to update with opts structure and remove name variable.');
disp('Need to check still works with subplotEeglabSpectra');

ds=1; %ds is for the number of combined datasets to run on
if isequal(input('Run laplacian (y-yes, otherwise no): ','s'),'y')
    laplacian=1;
else 
    laplacian=0;
end  

if isequal(input('Run Fisher on every other (y-yes, otherwise no): ','s'),'y')
    Fisher=1;
else
    Fisher=0;
end

disp('Code set to have no legend, change code if want legend'); %put 1 at end of subplotEeglabSpectra and allow lines below this one
spectra1label=1; spectra2label=2;
% disp('Do only one task at a time as a batch since enter only one type of label');
% spectra1label=input('Label for Spectra 1:','s');
% spectra2label=input('Label for Spectra 2:','s');

pathname=pwd; %starts in current directory but then moves to new one in case running 
%from higher level folder to save clicks

while 1; %to run multiple in a row
    PSeeg=1; %for individual datasets
    if ~strcmpi(input('Use previous concantenated set (Return - no, y- yes)','s'),'y')
        while 1
            [setfilename, pathname] = uigetfile('*.set', 'Select PS file to concatenate, (Cancel to stop)',pathname);
            if setfilename==0; %if press cancel for being done
                PSeeg=PSeeg-1;
                break
            end
            EEG = pop_loadset('filename',setfilename,'filepath',pathname);
%             [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );    
            data{PSeeg}=EEG.data;
            datapoints(PSeeg)=size(data{PSeeg},2);
            PSeeg=PSeeg+1;
        end

        minlength=(min(datapoints)); %pick shortest length snippets so all are the same, % could change to set all to a predefined length[]

        %problem with below if assume that all runs were same length
        %better to use cat command
        combineddata{ds}=[];
        for cd=1:PSeeg
%             combineddata{ds}(:,:,((cd-1)*size(data{cd},3)+1):cd*size(data{cd},3))=data{cd}(:,1:minlength,:); %send all same length and add to previous
            combineddata{ds}=cat(3,combineddata{ds},data{cd}(:,1:minlength,:)); %send all same length and add to previous
        end
        
        alleeg{ds}=EEG;
        if laplacian
            alleeg{ds}.laplacian=1;
        else
            alleeg{ds}.laplacian=0;
        end    
        
        savenameCombined{ds} = input('Name to save combined data as: ','s');
        combinedDataSaved=combineddata{ds};
        save([savenameCombined{ds} '_CombinedData'],'alleeg','combinedDataSaved');
        
        if ~strcmp(input('Run another dataset (y-yes, otherwise Return to stop):','s'),'y')
%             eeglab redraw;
            break
        else
            pathname=pwd; %to restart where to look since previous cancel made it 0
            ds=ds+1;
        end
    else
        [previousCombinedDataset, pathname] = uigetfile('*CombinedData.mat', 'Select previous combined dataset');
        previous=load(fullfile(pathname,previousCombinedDataset));
        alleeg{ds}=previous.alleeg{1};
        if laplacian
            alleeg{ds}.laplacian=1;
        else
            alleeg{ds}.laplacian=0;
        end  
       
        savenameCombined{ds}=previousCombinedDataset(1:end-17);
        combineddata{ds}=previous.combinedDataSaved; %originally combineddata but had to change save command above
        if ~strcmp(input('Run another dataset (y-yes, otherwise Return to stop): ','s'),'y')
            break
        else
            pathname=pwd; %to restart where to look since previous cancel made it 0
            ds=ds+1;
        end
    end
end    


for j=1:ds %to run multiple in a row and do Fisher if requested.
    [S,f,PSresult{j}]=runEeglabSpectra_v3pt1(alleeg{j},'e',combineddata{j},savenameCombined{j});
    if Fisher && ~mod(j,2) %if an even number
      subplotFisher(PSresult{j-1}(1:end-3),[PSresult{j-1} '.mat'],pwd,[PSresult{j} '.mat'],pwd); %pwd added so knows where to find and save file
      close(gcf);
      subplotEeglabSpectra(PSresult{j-1}(1:end-3),spectra1label,spectra2label,[PSresult{j-1} '.mat'],pwd,[PSresult{j} '.mat'],pwd,pwd,[PSresult{j-1}(1:end-3) '_FisherData.mat'],0);
      close(gcf);
      close(gcf);
    end
end