%function tgt_spectrogram

%7/26/13 to pull in one dataset and calculate a spectrogram, choose a
%baseline, then determine p-value of two group test of each spectrum after
%the baseline versus the baseline. Uses tgt_spectrum_input.
%
%plan:%This needs to be brought into subplotSpectrogram as a
%check button that runs it and a plotting option to highlight
%(or not suppress) insignificant freq by 0.05 or FDR; as
%well as a button to plot p-value spectrograms

%on testing data in the workspace
load('IN316W_HandRun3_start-2to13_Lap_NoAvg_SG.mat')

%for testing make the baseline just the first one.
%[] Code to determine non overlapping segments within the
%chosen baseline
figure
scrollsubplotAndy(3,2,1);
imagesc([3;-3],[-3 3]);
colorbar
for si=1:length(S)
    s=S{si};
    scrollsubplotAndy(3,2,si+1);
    
    base=squeeze(s(1,:,:));%just the first one though needs to be modified.
    %initialize outputs of below. s is time x freq x samples
    dz=zeros(size(s,2),size(s,1));
    vdz=dz; Adz=dz;TGTp=dz;
    
    %then calculate all the TGT outputs for everything after baseline
    %[] make sure to add in code to start after the baseline
    for tt=1:size(s,1)%tt is time point
        %dz, vdz and adz are all #of freq x 1
        [dz(:,tt),vdz,Adz]=tgt_spectrum_input(squeeze(s(tt,:,:)),base,0.05);%save
        %dz for plotting its sign later. Note that base is second so that
        %get same sign of dz as doing a baseline subtraction.
        TGTp(:,tt)=2*(1-normcdf(abs(dz(:,tt)),0,sqrt(vdz)));%calculate the p-value
        
    end
    
    imagesc(t{1},f{1}(f{1}>0 & f{1}<40),-log10(TGTp(f{1}>0 & f{1}<40,:)).*sign(dz(f{1}>0 & f{1}<40,:)),[-3 3]);
    title(ChannelList{si});
    axis('xy');
%     colorbar
end