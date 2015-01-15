%this is a script so can pull ALLEEG from the system when Eeglab is open

%[]consider option to pick components to plot against each other
% version Aug31: added laplacian option (need to get it to work)
%12/16/11 added opts field for runEeglabSpectra
%12/20/11 modified opts structure to take lap (and can add bip later)
%%
%clear first in case it was aborted before
% clear S f more dataset numToRun PSeeg alleeg eegorica fStart fEnd fSpacing defaultfpart useDefault fisherFiguretitle PSresult
%%


%%


more = 1;
PSeeg=1;


%give option to run laplacian without adding another variable
if isequal(input('Run laplacian (y-yes, otherwise no): ','s'),'y')
    opts.lap=1;
else 
    opts.lap=0;
end


if ~exist('alleeg','var') %so can create during ICAeeglab in workspace (doesn't run below if alleeg exists)
    while more
        for a=1:length(ALLEEG)
            fprintf('%.0f. %s\n',a,ALLEEG(a).setname);
        end
        if ~mod(PSeeg,2) %if is an even one, result will be 0, otherwise skips
            dataset=input('Which eeglab dataset to compare to with Fisher? (Return to skip)'); %compare to previouse
            if ~isempty(dataset)
                fisherFiguretitle{PSeeg}=input('Name of Fisher figure: ','s');
            end
        else
            dataset=input('Which eeglab dataset (Return to End)?'); %choose number
        end
        if isempty(dataset)
            PSeeg=PSeeg-1;
            break
        end
        alleeg(PSeeg)=ALLEEG(dataset);
        if PSeeg <2; %since never run more than one ICA at a time
            opts.eegorica=input('Run on ICA components or EEG (i - ica, e - eeg)?','s');
        end
       
         PSeeg=PSeeg+1;
    %     savename=input('Savename: ','s');
    %     savename=[savename '_PS'];
    end
end

    
for numToRun=1:PSeeg
    %S and f used in runCCA but not used here
    [S,f,PSresult{numToRun}]=runEeglabSpectra(alleeg(numToRun),opts);
    if ~mod(numToRun,2) %results in 0 if even
        subplotFisher(fisherFiguretitle{numToRun},[PSresult{numToRun-1} '.mat'],pwd,[PSresult{numToRun} '.mat'],pwd); %pwd added so knows where to save file
        %could put line here to run subplotSpectra
    end
end

clear S f more dataset numToRun PSeeg alleeg eegorica fStart fEnd fSpacing defaultfpart useDefault fisherFiguretitle PSresult


