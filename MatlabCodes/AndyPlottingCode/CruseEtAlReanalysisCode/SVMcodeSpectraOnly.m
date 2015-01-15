function SVMcodeSpectraOnly(pathname)

%modification of SVM code version 2/6/12 to run the SVM on all time points
%of the spectrogram result one at a time. Want to prove that there's no
%advantage in using a moving window to get the results and may help to show
%the acausal results wth positive before the beep. Also will give a feature
%vector for a single time point so might be easier to see what lead to the
%positive classification. 
 
%%
%2/15/12 add option here to increase the number of iterations
svmoptions=statset('MaxIter',30000);

%%
%load the file
if nargin<1
    pathname=uipickfiles('type',{'*.set','set file'},'output','char');
end
% pathname='/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/Srivas/LancetPaper/FinalPatientDatasetDec13/SVMAnalysis/imjl_lancet.set';
EEG=pop_loadset(pathname);%load in original data. Cut time later. EEG.data is channel x timepoint x trial
[path,filename]=fileparts(pathname);
%each dataset is 5.5 seconds (1.5 before and 4 after the beep)
block=[EEG.event.bnum]; %vector of what block each trial is in
type={EEG.event.type};%cell vector of RIGHTHAND and TOES for each trial

%select only channels they used, code from lvm
%Cut out all channels except the ones required
if EEG.nbchan == 129
    origchan = [6    7   13   29   30   31   35   36   37   41   42   54   55   79   80   87   93  103  104  105  106  110  111  112  129];
    cloc = pop_readlocs('GSN-HydroCel-129.sfp');%12/19/11
elseif EEG.nbchan == 257
    origchan = [8    9   17   43   44   45   52   53   58   65   66   80   81  131  132  144  164  182  184  185  186  195  197  198  257];
    cloc=pop_readlocs('GSN-HydroCel-257.sfp');
    
elseif EEG.nbchan == 64
    origchan = [20 19 15 16 21 23 24 4 55 30 53 54 59 58 52 48 45 3 29 41 26 50 22 57];
    cloc = pop_readlocs('/Users/andrewgoldfine/Documents/CornellResearch/EEGResearchJune8NoNmlOrigs/EGIInformation/support/3rdPartySoftwareSupport/BESA/HCGSNSensorPostionFiles/GSN-HydroCel-64 1.0.sfp');
end

cloc=cloc(origchan);%to have to save for later plotting or labeling

dataOrig=EEG.data(origchan,:,:);
srate=100;

%remove blocks with <5 trials total, not just in one type, as per paper results 69 in subj4 (added 1/26/12)
rb5=[];
for bb=1:max(block)%determine which blocks (type and block number) have fewer than 5
    if sum(block==bb)<5 %need sum to count number of 1s
        rb5=[rb5 bb];            
    end
end

rb5=unique(rb5);%make a simple vector of blocks to remove
    for bb2=1:length(rb5)
            dataOrig=dataOrig(:,:,block~=rb5(bb2));
            type=type(block~=rb5(bb2));
            block=block(block~=rb5(bb2));
            fprintf('Block %.0f removed since <5 trials.\n',rb5(bb2));
    end
    
    numblocks=length(unique(block));%now that have removed blocks, need this later rather than max block

%next downsample to 100Hz with resample since that's what EEGLAB uses
for run=1:size(dataOrig,3)%for each trial which is now fewer than original
    data(:,:,run)=resample(double(squeeze(dataOrig(:,:,run)))',srate,EEG.srate)';
end

%[] need to figure out how their downsampling worked!

%%
%below from lda.m and bandpower.m
%calculate spectrogram using spectrogram.
%Do separately for each channel and trial. Want to get 301 time points
%between .5 and 3.5 and 451 time points all together. 
f_low = 7;
f_step = 6;
f_high = 30;
winlen=srate;
overlap=winlen-1;%default overlap so that moves by only one datapoint
freqranges = f_low:f_step:f_high;
if freqranges(end) < f_high
    freqranges = [freqranges f_high];
end
fprintf('Calculating bandpower in frequency bands between %d:%d:%dHz\n',f_low,f_step,f_high);

%initialize matrices
[~,F,T,P] = spectrogram(squeeze(double(data(1,:,1))),winlen,overlap,winlen,srate);
%[] to verify this, replace the second 100 points by zeros then expect that
%estimate to be zero
bpdata = zeros((length(freqranges)-1)*size(data,1),length(T),size(data,3));

for t = 1:size(data,3) %for each trial
    for c = 1:size(data,1) %for each channel
        %P is PSD. ~ is for the spectrogram which we don't need.
        [~,F,T,P(:,:,t,c)] = spectrogram(squeeze(double(data(c,:,t))),winlen,overlap,winlen,srate);
        %P is frequency x timepoint for each channel and trial
        
        for fr = 1:length(freqranges)-1
%             freqidx = find(F >= freqranges(fr) & F <= freqranges(fr+1));
%             bpdata((length(freqranges)-1)*(c-1) + fr,:,t) = mean(P(freqidx,:),1);
            bpdata((length(freqranges)-1)*(c-1) + fr,:,t) = mean(P(F >= freqranges(fr) & F <= freqranges(fr+1),:,t,c),1);%AMG
        end
    end
end

disp(num2str(T)); %T ranges from 0.5 to 5.
%0.5 is actually -1 (represents data from -1.5 to -0.5 relative to beep)
%5 is actually 3.5 post beep (represents data from 3 to 4 post beep).
%So primary analysis should be .5 to 3.5 post beep which is 2 to 5 in T
%and actually represents data from 0 to 4 post beep.
bpdata = permute(bpdata,[3 2 1]);%so that it's trials x time points=451 x (freqRange x channel = 100)

save([filename '_SpectraOnlySVM'],'T','F','P','filename','bpdata','block','type');
    
