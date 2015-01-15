function fractionFreqBands

%3/7/12 to calculate power (not log power) within specific frequency bands of each
%channel from a PS.mat file and do so for multiple subjects. Needs to save
%the output as well for redisplay. Display will show fraction power in each
%band.


%%
%allow to reload previously saved file
if ~strcmpi(input('Load previously saved file? (y/n) [n]: ','s'),'y')

%%
%load files
disp('If choose multiple subjects, need same channels');
savename=input('Savename: ','s');

PSfile=uipickfiles('type',{'*PS.mat','spectra from PSeeglab'});
if isempty(PSfile) || isnumeric(PSfile) %two options in case press cancel or done with no selection
    return; 
end
for nss=1:length(PSfile)
    spectra(nss)=load(PSfile{nss});
    [~,filenames{nss}]=fileparts(PSfile{nss});
    filenames{nss}=filenames{nss}(1:end-3);%so matches with SVMsubjectLookup
end;

numSpec=length(PSfile);

%%
%define frequency bands
freqBands=[1 4;4 8;8 13;13 30];
disp(freqBands);
disp('If want to change them do in the code.');

%%
%run for loop for each spectra and each channel to calculate the bands.
%later on will display them on the screen.

%fbPower is file x channel x frequency band
fbPower=zeros(length(PSfile),spectra(1).numChannels,size(freqBands,1));
for si=1:length(spectra)
    %need to convert all powers to positive numbers since otherwise some
    %can be positive and some can be negative and can average out to zero!
    
    f=spectra(si).f;%is 1 x num frequencies
    for ci=1:spectra(si).numChannels
        for fi=1:size(freqBands,1)
            %note, can't do of log because log power can be positive or
            %negative. Need to log the output though
            fbPower(si,ci,fi)=mean(spectra(si).S(f>=freqBands(fi,1) & f<freqBands(fi,2),ci));
        end
    end
end
        

%%
%save output 
ChannelList=spectra(1).ChannelList;
save([savename '_FBPower'],'fbPower','filenames','freqBands','ChannelList');

else
%%
%reload previously saved file
prevDonePath=uipickfiles('type',{'*FBPower.mat','Freq Band File'},'num',1,'output','char');
load(prevDonePath);%just load it so will get the same variables

end

%%
%display them on the screen though might want to do only 1 channel.

%choose channel(s)
for cc=1:length(ChannelList)
    fprintf('%.0f. %s\n',cc,ChannelList{cc});
end
chan=input('Which channel(s) to display? [all]: \n');
if isempty(chan)
    chan=1:length(ChannelList);
end

%%
%rename Cruse et al. files
[subjectNumberName,~,orderi,~]=SVMsubjectLookUp(filenames);
fbPower=fbPower(orderi,:,:);
subjectNumberName=subjectNumberName(orderi);

%%
disp('Frequency bands: ');
disp(freqBands);
for s2=1:size(fbPower,1) %for each subject
    fprintf('\nFor subject %s: \n',subjectNumberName{s2})
    for c2=chan
        fprintf('Channel %s fraction power\n',ChannelList{c2});
        fprintf('%.2f %.2f %.2f %.2f\n',fbPower(s2,c2,:)./sum(fbPower(s2,c2,:)));
    end
    fprintf('Average across all channels is:\n');
    fprintf('%.2f %.2f %.2f %.2f\n',sum(fbPower(s2,:,:),2)./sum(sum(fbPower(s2,:,:))));%sum by frequency for all channels divided by sum across frequencies
end
    