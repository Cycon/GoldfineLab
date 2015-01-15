function SVMcode(pathname,opts)

%1/23/12 based on SVMscript which is a script based on Damian's code from
%Cruse et al paper. As much as possible used their code but had to change
%because we don't have access to g.tec's BSAnalyze. opts.startTime in
%seconds, opts.winLength in seconds. Both used for selecting data.
%[] need to add in way of calculating the p-value by going through a
%variety of binofit significances
%1/25/12 version 2 add option for permutation test instead of binomial test of
%significance to get the p-value. Bsed on JV's email need to: [] randomize
%the permutation order when more than 70. [] save the number correct and
%not just percentage correct in each block (will need to save number of
%trials as well). [] make another version that runs on all possible cases
%where 1/2 of the blocks are relabeled "to see if the number correct is
%distributed randomly, not just whether it is less than in the real
%dataset.
%1/26/12 remove blocks with less than 5 trials since done by original code.
%Only releevant for sk_s1 but changes code since cant use max(block) for
%number of blocks anymore!
%2/1/12 version 3 change permutation test to use combnk so is symmetric and
%can cut out half and get all the information
%2/6/12 add option to make spectrogram have bigger moving window to get fewer features.
%3/14/12 make permutation cut off (and randomize) at 5000 so can run the
%rest of the patients. Doesn't work with combnk when over 7 blocks since
%end up with weird order of combinations (too many starting with 1) so
%chose uperms instead.

%%
%set defaults
if nargin<2
    opts.winLength=3;%this is for the SVM, the spectra are always using 1 second windows so
    %even if the winLength here is 0.5 the features used include data from
    %half second before to half second afterwards.
    opts.specWin=0;%an option added 2/6/12 so that can modify the moving window of the spectrogram
    %to get fewer features. If 0 then use default of moving by one point.
    %Otherwise this value should be in seconds.
    opts.startTime=1.5;
    opts.stat='binofit';%binofit, permutation, permutationHalf
    disp('Setting default start time of 1.5 and win length of 3');
end

if ~isfield(opts,'winLength')
    opts.winLength=3;
end

if ~isfield(opts,'startTime')
    opts.startTime=1.5;
end

if ~isfield(opts,'stat')
    opts.stat='binofit';
end

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
if opts.specWin %added 2/6/12
    if opts.specWin==winlen/srate %not allowed by the code so change to 1% overlap
        overlap=winlen*.01;
    else
        overlap=winlen*opts.specWin;
    end
else%default (if is 0)
    overlap=winlen-1;%default overlap so that moves by only one datapoint
end
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
        [~,F,T,P] = spectrogram(squeeze(double(data(c,:,t))),winlen,overlap,winlen,srate);
        %P is frequency x timepoint for each channel and trial
        
        for fr = 1:length(freqranges)-1
            %             freqidx = find(F >= freqranges(fr) & F <= freqranges(fr+1));
            %             bpdata((length(freqranges)-1)*(c-1) + fr,:,t) = mean(P(freqidx,:),1);
            bpdata((length(freqranges)-1)*(c-1) + fr,:,t) = mean(P(F >= freqranges(fr) & F <= freqranges(fr+1),:),1);%AMG
        end
    end
end

disp(num2str(T)); %T ranges from 0.5 to 5.
%0.5 is actually -1 (represents data from -1.5 to -0.5 relative to beep)
%5 is actually 3.5 post beep (represents data from 3 to 4 post beep).
%So primary analysis should be .5 to 3.5 post beep which is 2 to 5 in T
%and actually represents data from 0 to 4 post beep.
bpdata = permute(bpdata,[3 2 1]);%so that it's trials x time points x (freqRange x channel=100)
%the last dimension goes each frequency range of a channel before going on
%to the next channel.

%future codes call this P_C_S.Data

%%
%next cut out the 0.5 to 3.5 and put all features from each trial in a vector. Follow concatdata.m
%which is also an EEGLAB code so careful to use theirs! Goal is to make a
%vector of trials,1,numfeats*win (after permute at the end). win is 3 seconds
%
%to use pre-tone data like in paper would need to modify win and t
%carefully

datac=permute(bpdata,[3 2 1]);%so is (freqRange x channel) x time pts x trial
numfeats=size(datac,1);
win=opts.winLength;
if opts.specWin %can't use default code if not one window of spectrogram per data point
    swrange=T>=opts.startTime & T<=opts.startTime+opts.winLength;
    outdata = zeros(numfeats*sum(swrange),1,size(datac,3));
else %default method
    win=round(win * srate);%so 300 windows for 4 seconds of data as spectra
    swstart=opts.startTime*srate;%convert to data points for below
    if swstart==0
        swstart =1;%in case put in 0, start at first available time point
        win=win+1; %so same number of time points
    end
    outdata = zeros(numfeats*win,1,size(datac,3));
end
fprintf('Collapsing features..\n');
for chan = 1:size(datac,1) %for each feature and channel, total of 100
    %     fprintf('Collapsing feature %s of %s...\n',num2str(chan),num2str(size(data,3)));
    for trial = 1:size(datac,3) %for each trial
        
        %below used in Damian's code. Weird that for loop since always the
        %same. May have originally tried a variety of times and picked best
        %one
        %         for t = srate + round(srate/2); %always start at 150 which is 2 seconds in which is 0.5 post beep
        
        %             swstart = t;
        if opts.specWin %can't use default code if not one window of spectrogram per data point
            d = squeeze(datac(:,swrange,trial));%added 2/6/12
        else %default method
            swstop = swstart+win-1;%stop at 150+300-1 which is 4.98 seconds which is 3.5 seconds post beep
            
            d = squeeze(datac(:,swstart:swstop,trial));%picks all features from a specific time range and trial
            %is organized as (freqRange x channel) x time points so is 100 x 300
        end
        d = reshape(d,1,size(d,1)*size(d,2));%row vector of freqRange then channel then time points
        %so would be freq range for each channel through all channels
        %for one time point then next time point.
        
        %             outdata(trial,t,:) = d;
        outdata(:,1,trial) = d;%same as d but now third dimension is trial
        
        %         end
        
    end
end

features = permute(outdata,[3 2 1]); %trials x 1 x num features (30,000 - freqrange then channel then time)
%interesting now to plot(squeeze(features(1,1,:)) or log10 of it. See go up
%and down since different power at different frequency ranges and slight
%change over time.

%%

%this is based on svmlda.m. Can't use actual code since uses BS code to do
%log 10 and separate out trials by block and task.

%Notes:
%-smoothwin not used in their code
%-targetwin not used in their code
%-targetwinidx not used in their code
%- out_x not used in their code
%bestwvidx not used
%WM not used


%not clear how to use the Attribute field of P_C_S.Attribute but likely

%They first run gBSarithmetic to do log 10 and then later
%features=P_C_S.Data. It then gets converted to mat if a cell.
%take log10 of the features and then have them organized where
%as trials by samples (baseline and task) by features. Will not include
%'samples' since not planning to do baseline and task at once though see end
%of their code for how to compare them

%do log10 and permute so is log of trials x features
lfeatures=log10(squeeze(features));%remove the singleton in the middle


%set training features to be all but the ith block of hand and foot using a
%for loop that moves from first to last block.
AllCoeffs = {};
allaccs=[];
for run=unique(block);%assuming same number of blocks each trial type
    
    %set testfeatures to be the ith block
    testfeatures=lfeatures(block==run,:);
    trainfeatures=lfeatures(block~=run,:);
    
    %check for < 5trials which Damian's code does line 87
    if size(testfeatures,1)<5
        fprintf('Block %.0f has < 5 trials, shouldn''t use',run);
    end
    
    %calculate mean, std and normalize training features.
    %done in code by vector of mean for each feature across all trials
    %So not a grand mean but different for each frequency range channel
    %timepoint
    
    %below from Damian's code but I rewrote it without for loops
    %     for feat=1:size(trainfeatures,2) %for each of the 30000 features
    %         meanfeats(feat)= mean(trainfeatures(:,feat));
    %         stdfeats(feat) = std(trainfeatures(:,feat));
    %         normtrainfeats(:,feat) = (trainfeatures(:,feat) - meanfeats(feat)) ./ stdfeats(feat);
    %     end
    meanfeats=mean(trainfeatures,1);%same as above
    stdfeats=std(trainfeatures);%same as above
    
    normtrainfeats=(trainfeatures-repmat(meanfeats,size(trainfeatures,1),1))./repmat(stdfeats,size(trainfeatures,1),1);
    
    trainfeatures = normtrainfeats;
    
    %normalize test features with the same mean and std
    %Damian's version. Below I change to no for loops
    %     for feat = 1:size(testfeatures,2)
    %         normtestfeats(:,feat) = (testfeatures(:,feat) - meanfeats(feat)) ./ stdfeats(feat);
    %     end
    normtestfeats=(testfeatures-repmat(meanfeats,size(testfeatures,1),1))./repmat(stdfeats,size(testfeatures,1),1);
    testfeatures = normtestfeats;
    clear meanfeats stdfeats normtrainfeats normtestfeats;
    
    %make a list of labels of the groups for the training and testing set
    trainlabels=type(block~=run);
    testlabels=type(block==run);%should be a cell array of RIGHTHAND and TOES
    
    %run svmtrain. Note seems that it runs on each trial even though
    %one block of trials is taken out at a time.
    %Save output in a cell, one for each block. This code wants a
    %matrix of observations x features and a column vector of the class labels
    AllCoeffs{run}=svmtrain(trainfeatures,trainlabels,'autoscale','false');
    
    %run svmclassify on the test features and save the results in allaccs and testaccu
    testres = svmclassify(AllCoeffs{run},testfeatures);
    
    %allaccs is how many right but need to change right hand left hand to 1
    %0 to work
    
    %Damian's version but mine uses the actual event names
    %     allaccs = [allaccs; ~xor(testres > 0, testlabels > 0)];
    %     testaccu(run) = (sum(~xor(testres > 0, testlabels > 0))/length(testlabels)) * 100;
    %     %removed t from testaccu since not running against baseline at this
    %     %point
    allaccs=[allaccs strcmp(testres',testlabels)];
    numaccu(run)=sum(strcmp(testres',testlabels));
    testaccu(run)=sum(strcmp(testres',testlabels))/length(testlabels)*100;
    
end
% clear normtestfeats;

%calculate mean accuracy assuming used 'CV' method
finalaccu=mean(testaccu);%initially ,1 but that's because in their version of the
%code test accu has another dimension to allow comparison to baseline
%AG - [] above is wrong since should have been a weighted average by block
%size. Not a huge deal but worth testing

if strcmpi(opts.stat,'binofit')
    
    [phat, pci05] = binofit(sum(allaccs),length(allaccs),0.05);
    [~, pci01] = binofit(sum(allaccs),length(allaccs),0.01);
    [~, pci001] = binofit(sum(allaccs),length(allaccs),0.001);
    bestaccu = phat*100;
    %     bestaccu = finalaccu;
    
    sig = 'x';
    
    if pci05(1) > 0.5
        sig = '*';
    end
    if pci01(1) > 0.5
        sig = '**';
    end
    if pci001(1) > 0.5
        sig = '***';
    end
    fprintf('Mean classification accuracy for %s: %.1f %s across %s trials\n',filename,bestaccu,char(sig),num2str(length(allaccs)));
    
    save([filename '_' num2str(opts.startTime*100) '_' num2str(opts.winLength*100) '_SVM'],'finalaccu','allaccs','testaccu','AllCoeffs','testres','opts','block','type','phat','pci05','pci01','pci001','cloc','filename');
    
elseif strcmpi(opts.stat,'permutation') %if use permutation test and recalculate it with up to 200 permutations
    
    %come up with a list of permutations radomly selected.
    
    %     origList=[zeros(1,numblocks) ones(1,numblocks)];%represents the block order where they alternate based on the loop that creates newtype
    %
    %         [~, ~, permlist]=uperms(origList); %code I downloaded that gives all unique permutations but combnk is symmetric so can use first half 2/1/12
    %         permlist=permlist(2:end);%so doesn't include the original one
    
    %added 3/14/12 to all to run for large number of blocks. Imaggennetto
    %has 24309 permutations which is why it takes forever to run!
    if numblocks>6 %if use 7 blocks then 3432/2=1716 combinations
        disp('combnk not recommended, will use uperms');
        [~,~,permlist]=uperms(1:numblocks*2,1001);%pick 1000 randomly selected, initially did 5000 but took over 2 hours
        permlist=permlist(2:end,:);%since first is original
        permlist=permlist(:,1:numblocks);%since code is designed for combnk which gives it like this
    else %prefer to use combnk since is symmetric so can remove 2nd half to save time
        permlist=combnk(1:numblocks*2,numblocks); %gives a list of numperms x numblocks where each row represents the blocks (of total numblocks*2)
        %to reassign. Code below goes through and reassigns the blocks and type where the first half are hand and second half are toe)
        permlist=permlist(2:end/2,:); %since first and last are equivalent to original version but actually 2nd half = 1st half
        %           permlist=permlist(randperm(size(permlist,1)),:); %randomly reorder it so not always the same though doesn't matter if do all perms
    end
    
    %
    %     if size(permlist,1)>5000
    %         permlist2=permlist(randperm(size(permlist,1)),:);%randomly reorder
    %         permlist3=permlist2(1:5000,:);
    %     end
    
    for pm=1:size(permlist,1)
        
        %set training features to be all but the ith block of hand and foot using a
        %for loop that moves from first to last block.
        AllCoeffs = {};
        allaccs=[];
        for run=unique(block);%block numbers may not be contiguous
            
            %set testfeatures to be the ith block
            testfeatures=lfeatures(block==run,:);
            trainfeatures=lfeatures(block~=run,:);
            
            %check for < 5trials which Damian's code does line 87
            if size(testfeatures,1)<5
                fprintf('Block %.0f has < 5 trials, shouldn''t use',run);
            end
            
            %calculate mean, std and normalize training features.
            %done in code by vector of mean for each feature across all trials
            %So not a grand mean but different for each frequency range channel
            %timepoint
            
            
            meanfeats=mean(trainfeatures,1);%same as above
            stdfeats=std(trainfeatures);%same as above
            
            normtrainfeats=(trainfeatures-repmat(meanfeats,size(trainfeatures,1),1))./repmat(stdfeats,size(trainfeatures,1),1);
            
            trainfeatures = normtrainfeats;
            
            %normalize test features with the same mean and std
            
            normtestfeats=(testfeatures-repmat(meanfeats,size(testfeatures,1),1))./repmat(stdfeats,size(testfeatures,1),1);
            testfeatures = normtestfeats;
            clear meanfeats stdfeats normtrainfeats normtestfeats;
            
            %reassign the labels based on the permuted order
            reassign=zeros(1,numblocks*2);
            reassign(permlist(pm,:))=1;%to use to decide which blocks get what type
            newtype=zeros(1,length(type));%just to initialize it
            ntb=unique(block);%for use below since one subject has block removed
            for nt=1:numblocks%need to use indexing for the reassign below
                newtype(block==ntb(nt) & strcmpi(type,'RIGHTHAND'))=reassign(nt);%first half for hand
                newtype(block==ntb(nt) & strcmpi(type,'TOES'))=reassign(nt+numblocks);%second half for toes
            end
            
            
            %make a list of labels of the groups for the training and testing set
            trainlabels=newtype(block~=run);
            testlabels=newtype(block==run);%should be a cell array of RIGHTHAND and TOES
            
            %run svmtrain. Note seems that it runs on each trial even though
            %one block of trials is taken out at a time.
            %Save output in a cell, one for each block. This code wants a
            %matrix of observations x features and a column vector of the class labels
            
            %added 3/14/12 for P15 who has no right hand in block 3!
            if sum(trainlabels)/length(trainlabels)==1 || sum(trainlabels)==0 %if all the same number doesn't work
                fprintf('On block %.0f and perm %.0f all trainlabels are the same so skipping\n',run,pm);
                AllCoeffs{run}=nan;
                numaccu(pm,run)=nan;
                testaccu(run)=nan;
            else
                AllCoeffs{run}=svmtrain(trainfeatures,trainlabels','autoscale','false');
                
                %run svmclassify on the test features and save the results in allaccs and testaccu
                testres = svmclassify(AllCoeffs{run},testfeatures);
                
    
                %             allaccs=[allaccs testres==testlabels];
                numaccu(pm,run)=sum(testres==testlabels');%number accurate per permutation and run (JV thinks helpful)
                testaccu(run)=sum(testres==testlabels')/length(testlabels)*100; %calculate each permutation for each block to average below
            end
            
        end %blocks
        
        finalaccuPM(pm)=mean(testaccu);%determine the final accuracy for each permutation
        
    end %permutations
    
    p_perm=1-((sum(finalaccu>finalaccuPM))/length(finalaccuPM));%1 - the fraction of times it's better than the shuffled versions
    disp('note p_perm isn''t right. Better to run DisplayCorrectedPvals.m');
    
    
    
    save([filename '_' num2str(opts.startTime*100) '_' num2str(opts.winLength*100) '_Perm_SVM'],'finalaccu','finalaccuPM','p_perm','opts','block','type','cloc','numaccu','permlist','filename');
    
elseif  strcmpi(opts.stat,'permutationHalf')
    
    %1/26 realized there's an issue where can't follow these methods in
    %subjects with 5 blocks. JV recommends cutting out a block (1st or
    %last block) and doing the analysis.
    blockdrop=0;
    if mod(numblocks,2)%if odd number of blocks
        blockdrop=max(block);%can also do with 1st block
        lfeatures(block==blockdrop,:)=[];
        type(block==blockdrop)=[];
        block(block==blockdrop)=[];
        numblocks=numblocks-1;
    end
    
    %here strategy is swich labels of half of the block pairs at a time
    %so make a moderate impact and avoid potential of beginning / end
    %time effect. Not used to calculate p-value though
    blockwisePerm=nchoosek(1:numblocks,0.5*numblocks);%list of all ways to chose half of the blocks
    
    
    
    for pm=1:size(blockwisePerm,1)/2 %do for all though 1st and latter half the same
        
        %set training features to be all but the ith block of hand and foot using a
        %for loop that moves from first to last block.
        AllCoeffs = {};
        for run=unique(block);%assuming same number of blocks each trial type
            
            %set testfeatures to be the ith block
            testfeatures=lfeatures(block==run,:);
            trainfeatures=lfeatures(block~=run,:);
            
            %check for < 5trials which Damian's code does line 87
            if size(testfeatures,1)<5
                fprintf('Block %.0f has < 5 trials, shouldn''t use',run);
            end
            
            meanfeats=mean(trainfeatures,1);%same as above
            stdfeats=std(trainfeatures);%same as above
            
            normtrainfeats=(trainfeatures-repmat(meanfeats,size(trainfeatures,1),1))./repmat(stdfeats,size(trainfeatures,1),1);
            
            trainfeatures = normtrainfeats;
            
            %normalize test features with the same mean and std
            
            normtestfeats=(testfeatures-repmat(meanfeats,size(testfeatures,1),1))./repmat(stdfeats,size(testfeatures,1),1);
            testfeatures = normtestfeats;
            clear meanfeats stdfeats normtrainfeats normtestfeats;
            
            %reassign the labels based on the permuted order
            newtype(pm,:)=zeros(1,length(type));%just to initialize it
            for nt=unique(block)%in case a block is dropped because <5
                if sum(nt==blockwisePerm(pm,:)) %if that block is in the list to change
                    newtype(pm,block==nt & strcmpi(type,'RIGHTHAND'))=1;
                    newtype(pm,block==nt & strcmpi(type,'TOES'))=0;
                else
                    newtype(pm,block==nt & strcmpi(type,'RIGHTHAND'))=0;
                    newtype(pm,block==nt & strcmpi(type,'TOES'))=1;
                end
            end
            
            
            %make a list of labels of the groups for the training and testing set
            trainlabels=newtype(pm,block~=run);
            testlabels=newtype(pm,block==run);%should be a cell array of RIGHTHAND and TOES
            
            %run svmtrain. Note seems that it runs on each trial even though
            %one block of trials is taken out at a time.
            %Save output in a cell, one for each block. This code wants a
            %matrix of observations x features and a column vector of the class labels
            AllCoeffs{run}=svmtrain(trainfeatures,trainlabels','autoscale','false');
            
            %run svmclassify on the test features and save the results in allaccs and testaccu
            testres = svmclassify(AllCoeffs{run},testfeatures);
            
            %allaccs is how many right but need to change right hand left hand to 1
            %0 to work
          
            numaccuPM(pm,run)=sum(testres==testlabels');%number accurate per run (JV thinks helpful)
            testaccuPM(pm,run)=sum(testres==testlabels')/length(testlabels)*100; %calculate each permutation for each block to average below
            
            
        end %blocks
        
        
    end %permutations
    
    finalaccuPM=mean(testaccuPM,2);%determine the final accuracy for each permutation
    fprintf('%s permhalf accuracies are:\n',filename);
    disp(finalaccuPM);
    
    
    save([filename '_' num2str(opts.startTime*100) '_' num2str(opts.winLength*100) '_PermHalf_SVM'],'finalaccu','finalaccuPM','opts','block','type','cloc','numaccuPM','testaccu','testaccuPM','blockwisePerm','newtype','numaccu','blockdrop','allaccs','filename');
    
    
end
