function eegplotAcc(EEG)

%takes an EEG dataset with accelerometers as the last three columns and
%plots as two eegplots to have differential scaling. Also calculates diff
%of the accelerometer time series so it appears on the page (other option
%is low pass filter but this is faster).
%12/20/11 AMG

if isfield(EEG,'event')
    ev=EEG.event;
else
    ev=[];
end
%below use diff as a quick HPF so all appear on the page
%use permute for 3D arrays since transpose operator doesn't apply
eegplot(permute(diff(permute(EEG.data(end-2:end,:,:),[2 1 3])),[2 1 3]),'srate',EEG.srate,'eloc_file',EEG.chanlocs(end-2:end),'events',ev);
accHandle=gcf;
eegplot(EEG.data(1:end-3,:,:),'srate',EEG.srate,'eloc_file',EEG.chanlocs(1:end-3),'children',accHandle,'events',ev);
