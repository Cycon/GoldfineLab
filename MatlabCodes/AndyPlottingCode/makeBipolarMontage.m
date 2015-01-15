% function makeBipolarMontage
% 
%based on Shawniquas code xtp_createMontage
%now only for 29 channels. Can make one for different headboxes. Channel
%starting order is how it is in my eeglab datasets for EKDB12 montage /
%headbox. The output matrix is next stored in MakeBipolar.m.
%Updated 11/6/11 to add another channel list for analyzing IN376Q. Also to
%type in the name of the channel rather than reading the number off the
%list.
%[] would be much better if type up the list initially and then run the
%code since there would be less room for error


%EKDB12
ChanList={'Fp1','Fp2','AF7','AF8','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CP2','CP6','T5','P3','Pz','P4','T6','O1','O2'};

%EMU40+18 DB (assuming all channels present)
ChanList={'FPz','Fp1','Fp2','AF7','AF8','F7','F3','F1','Fz','F2','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CPz','CP2','CP6','T5','P3','Pz','P4','T6','PO7','O1','POz','Oz','O2','PO8'};


numleads = size(ChanList,2);
lead1 = [];
lead2 = [];
coeffMatrix = [];
channelNames = [];
addAnother = 1;
channel = 0;
 disp(ChanList);
while addAnother
    channel = channel+1;
    fprintf(1,'Lead 1 of channel %d',channel);
    lead1 = input(': ','s');
    fprintf(1,'Lead 2 of channel %d',channel);
    lead2 = input(': ','s');
    coeffMatrix = [coeffMatrix;+strcmpi(lead1,ChanList)-strcmpi(lead2,ChanList)];
    channelNames{channel} = [ChanList{strcmpi(lead1,ChanList)} '-' ChanList{strcmpi(lead2,ChanList)}];
    fprintf('Added channel %d: %s\n',channel, channelNames{channel});
    addAnother = input('Add another channel? [0 = No, 1 = Yes, default 1]: ');
    if isempty(addAnother)
        addAnother = 1;
    end
end
channelNames = channelNames';

savename=input('Savename: ','s');
save(savename,'coeffMatrix','channelNames');
