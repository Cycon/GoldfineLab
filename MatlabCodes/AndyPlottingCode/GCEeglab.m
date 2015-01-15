function GCEeglab

%%
%set defaults (params defaults below)
%%
%choose channels (sets designed from EKDB12 so work in more datasets)

CSet(1).channels=[];
CSet(1).name='All';
CSet(2).channels={'F3' 'Fz' 'F4' 'FC5' 'FC1' 'FC2' 'FC6' 'C3' 'Cz' 'C4' 'CP5' 'CP1' 'CP2' 'CP6'};
CSet(2).name='centralChannels';
CSet(3).channels={'F3' 'Fz' 'F4' 'FC5' 'FC1' 'FC2' 'FC6' 'C3' 'Cz' 'C4' 'CP5' 'CP1' 'CP2' 'CP6' 'P3' 'Pz' 'P4'};
CSet(3).name='centralAndParietal';
CSet(4).channels={'P3' 'Pz' 'P4' 'O1' 'O2'};
CSet(4).name='POChannels';


%add in code to turn on or off
for dd=1:length(CSet)
    fprintf('%.0f - %s\n',dd,CSet(dd).name);
end
setUse=input('Which channel set to use? [1]');
if isempty(setUse)%default
    setUse=1;
end
CS=CSet(setUse);%this is the chosen set or turn useCI=0;

%%
setfiles=uipickfiles('Type',{'*.set','.set'},'Prompt', 'Select .set file(s)');
    
for kk=1:length(setfiles)
    EEG = pop_loadset('filename',setfiles{kk});
    GCEeglabDo;
end

%%
function GCEeglabDo

channelsCell=struct2cell(EEG.chanlocs);
channels=channelsCell(1,1,:);%names of channels in a cell array


%%
dl=size(EEG.data,2)/EEG.srate; %datalength in seconds
%want to catch situations where not even number since messes up plotting
%code
if mod(dl,1)>0 %if not an even number
    fprintf('Data not integer length, shortening trials to %.0f sec\n',floor(dl));
    dl=floor(dl);
    EEG.data=EEG.data(:,1:dl*EEG.srate,:);
end
params.tapers=[1 dl 1];
% params.fpass=[2 40];%fpass doesn't matter much. GC is calculated relative
% to other evalues at that frequency.
params.pad=-1;
params.Fs=EEG.srate;
data=MakeLaplacian(EEG.data,EEG.chanlocs);

data=normByPower(data,params);%added May 26 since want data to be normalized by power so all similar amplitude
%this corrects for different distances between electrodes on different
%parts of the head and if the spacing is different from the model

%%
%select only certain channels
if setUse==1 %if chose All channels
    CS.channels=squeeze(channels);%for labeling
else 
     for j=1:length(CS.channels)
        CI(j)=find(strcmpi(CS.channels{j},channels));%CI is channel indices
     end
    data=data(CI,:,:);
end

data=permute(data,[2 1 3]);

[Sc,Cmat,Ctot,Cvec,Cent,f]=CrossSpecMatc(data,dl,params);

%%
savename=sprintf('%s-%.0f-GC',EEG.setname,setUse);%put in setName in case have multiple versions
save(savename,'Sc','Cmat','Ctot','Cvec','Cent','f','CS');

% GCplot(1,Ctot,Cvec,f,EEG.setname,CS)
end
end