function ICA_Adjust
%to run ICA and then Adjust on an epoched EEGLAB dataset typically exported
%from EeglplotEpochChoose often with electrodes selected to be removed
%(especially with the EGI headset). Created starting 12/10/14 AMG.

%%Bring in the dataset
pathname=uipickfiles('type',{'*.set','.set file'},'prompt','Pick EEGLAB .set file');%allow multiple files


if isnumeric(pathname{1}) || isempty(pathname{1}) %if user presses cancel output is 0, done with no selection is {}
    return %exit the code
else
    for ii=1:length(pathname)
        
    EEG = pop_loadset(pathname{ii});
    [setfilepath,setfilename]=fileparts(pathname{ii});

    %% try filtering the data to see if it helps
    EEG = pop_eegfiltnew(EEG, [], 1, 1650, true);
    
    %% remove the bad channels though save their chanlocs for later interpolation
    badChanlocs=EEG.chanlocs(EEG.badElectrodeIndices);
%     EEG=pop_chanedit( EEG,'delete',EEG.badElectrodeIndices);%this doesn't work, not sure why!
    EEG.data(EEG.badElectrodeIndices,:,:)=[];
    EEG.nbchan=EEG.nbchan-length(EEG.badElectrodeIndices);
     EEG.chanlocs(EEG.badElectrodeIndices)=[];
    
    if sum(sum(EEG.data(end,:,:)))==0 %if Cz is the reference, then also remove it
        badChanlocs=[badChanlocs EEG.chanlocs(end)];
        EEG.data(end,:,:)=[];
        EEG.nbchan=EEG.nbchan-1;
        EEG.chanlocs(end)=[];
    end
            
    
    %% Run ICA on the good channels (not EEG.badElectrodeIndices) and not on Cz since is all 0s
    OUTEEG=pop_runica(EEG,'icatype','binica');%if use binica, may not work on a windows machine since the current code in path is set to macintosh!
%     
%() Might want to save the ICA components! Current version above may not do
%that unless recreate the data with the bad channels or interpolated
%versions and then save the ICA components in the original file

%     if size(EEG.data,2)==129 %then also don't use Cz since is reference
%         OUTEEG=pop_runica(EEG,'chanind',setdiff(1:size(EEG.data,1),[EEG.badElectrodeIndices 129]));
%     else
%         OUTEEG=pop_runica(EEG,'chanind',setdiff(1:size(EEG.data,1),EEG.badElectrodeIndices));
%     end

    %% Run Adjust and then remove the components it recommends on the good
    %channels

    %first need an output filename for the report, give the same name as the original file
    [~,filename]=fileparts(pathname{ii}); %can use filename below to name things

    artIC=ADJUST(OUTEEG,setfilename);
    OUTEEG=pop_subcomp(OUTEEG,artIC,1);%0 is no plot or 1 plots so you can confirm if you like it

    %% Interpolate in the missing channels and the reference channel (usually Cz)
    EEG=pop_interp(OUTEEG,badChanlocs,'spherical');

    %% Save the results
    EEG=pop_saveset(EEG,'filename',[setfilename '_ICA'],'filepath',setfilepath);
    
    end
end



