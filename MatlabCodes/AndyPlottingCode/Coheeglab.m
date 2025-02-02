function Coheeglab(setfilename,pathname,laplacian,params,freqResolution)
%Written 10/28/10 AMG. Designed to pull in data from an Eeglab setfile.
%[ ] may want gui to modify channels to run analysis on rather than having
%to modify code or can be text based

%version2 2/24/11 saves dataByChannel as pairs to use for two group test
%later. No need to save all the channels and is better to save as pairs so
%matches with the coherence comparisons
%version3 2/25/11 allows for calling by CoheeglabBat
%version 4 3/17/11 stops saving original data as pairs. Need to modify
%combined code as well as subplot TGT code to get their data from original
%source.
%
%3/20/11 no longer saves data as pairs but saves as channel. Also precalculates FFT (Js) to send to 
%new version of coherencyc coherencycJ. [] next need to find out from Hemant if same J can be used
%for TGT to save one more calculation
%4/20/12 now it saves the frequency Resolution in case want to look at it
%or display it in later code

%%
if nargin<1
    %load data
    [setfilename, pathname] = uigetfile('*.set', 'Select EEG file(s) for coherence','MultiSelect','on');

    %in case only choose one, make into a cell
    if ~iscell(setfilename)
        if setfilename==0; %if press cancel for being done
            return
        end
        setfilename=cellstr(setfilename);
    end

        %give option to run laplacian
        if isequal(input('Run laplacian (y-yes, otherwise no): ','s'),'y')
            laplacian=1;
        else
            laplacian=0;
        end
  
    %%
    %set defaults
     freqResolution=6;
%      params.tapers=[5 9]; %define below
     params.fpass=[0 100]; %in Hz so that f is in Hz at the end
     params.pad=-1;
     params.err=[2 0.05];
     params.trialave=1; %can change to 0 to look at one snippet at a time.
     %if 0, then output S is frequencies x trials.
     %if 1, then output S is dimension frequencies.
    %  movingwinInSec=[5 5]; %may want to change later to unequal length trial
    %  version

     disp('Would you like to use default parameters for coherencyc?');
     disp(params);
     fprintf('Freq Resolution is %.0f',freqResolution);
     fprintf('    fpass (in Hz): [%.0f %.0f]\n',params.fpass(1), params.fpass(2));
    %  fprintf('    movingwin (in sec): [%.2f %.2f]\n',movingwinInSec(1),
    %  movingwinInSec(2));
     default = input('Return for yes (or n for no): ','s');
     if strcmp(default,'y') || isempty(default)
     else
         disp('define params (Return leaves as default)');
         freqRes=input('FrequencyResolution: ');
         if ~isempty(freqRes)
             freqResolution=freqRes;
         end
%          p.tapers1=input('NW:');
%          if ~isempty(p.tapers1)
%              params.tapers(1)=p.tapers1;
%          end
%          p.tapers2=input('K:');
%          if ~isempty(p.tapers2)
%             params.tapers(2)=p.tapers2;
%          end
         p.pad=input('pad:');
         if ~isempty(p.pad)
             params.pad=p.pad;
         end
         p.err1=input('error type (1 theoretical, 2 jacknife):');
         if ~isempty(p.err1)
             params.err(1)=p.err1;
         end
         p.err2=input('p-value:');
         if ~isempty(p.err2)
             params.err(2)=p.err2;
         end
         fpass1=input('starting frequency of fpass:');
         if ~isempty(fpass1)
             params.fpass(1)=fpass1;
         end
         fpass2=input('ending frequency of fpass:');
         if ~isempty(fpass2)
             params.fpass(2)=fpass2;
         end
         fprintf('\nparams are now:\n');
         disp(params);
         disp(freqResolution);
     end
else
    setfilename=cellstr(setfilename); %to convert to a cell so this code can remain able to run on a bunch in one file
end


%%
%choose channels to run coherence on, give option to program in here a set
%of defaults but a second option to pop up a gui (add in later)
%independent channels might be: AF7, AF8, FC5, FC6, T5, T6; Pz, Fz
ac=0; %all combinations
% pairs={'AF7' 'AF8'; 'F3' 'F4'; 'FC5' 'FC6'; 'C3' 'C4';'T5' 'T6';'CP5' 'CP6';'Cz' 'C3';'Cz' 'C4';'Cz' 'CP5';'Cz' 'CP6';'F3' 'Pz';'F4' 'Pz'; 'F3' 'P3'; 'F4' 'P4'; 'FP1' 'Cz';'FP2' 'Cz';'Fz' 'Pz';'FP1' 'FC5';'FP2' 'FC6';'Fz' 'C3';'Fz' 'C4'; 'AF7' 'FC5'; 'AF8' 'FC6'; 'CP5' 'T5'; 'CP6' 'T6'; 'P3' 'O1'; 'P4' 'O2'};
% 
% disp('Running coherence on:');
% disp(pairs);
% if strcmpi(input('Run on all combinations instead (y/n)[y]','s'),'n')
% else
    pairs=[];
    ac=1;
% end
%%
for s=1:length(setfilename)
    runCoheeglab(setfilename{s},pathname,params,pairs,laplacian,freqResolution)
end
    
    function    runCoheeglab(setfilename,pathname,params,pairs,laplacian,freqResolution) %nested code so one doesn't influence the other and don't need to clear variables
        
        alleeg = pop_loadset('filename',setfilename,'filepath',pathname);

        params.Fs=alleeg.srate; %can't be defined earlier like rest of params
        savename=setfilename(1:end-4); %changed from alleeg.setname since this way CoheeglabBat can predict name

        if laplacian
            alleeg.data=MakeLaplacian(alleeg.data,alleeg.chanlocs); %runs on Eeglab type data in 3D
            savename=[savename '_Lap'];
        end



        %%
        %[] need to take data organized as dataxchannelxsnippet and reorganize to
        %be dataxsnippet so can average across them and then do one channel at a
        %time

        %change to be data x snippet with each channel in a cell
        numChan=size(alleeg.data,1);
        numPoints=size(alleeg.data,2);
        numSnip=size(alleeg.data,3);
        params.tapers(1)=numPoints/params.Fs*freqResolution/2; %note coherenceDiffMap assuming a 2 value tapers to calculate Freq Res 12/22/11
        params.tapers(2)=ceil(params.tapers(1)*2-1);
        
        %added 3/20/11 to save time below, requires modifying coherencyc
        tapers=dpsschk(params.tapers,numPoints,params.Fs); % calculates tapers and multiplies by sqrt(Fs)

        fprintf('Running coherence with %.0f tapers\n',params.tapers(2));
        for ii=1:numChan
            for jj=1:numSnip
                dataByChannel{ii}(:,jj)=alleeg.data(ii,:,jj); %organized as dataxsnippet (data x trial in chronux terms)
                JByChannel{ii}=mtfftc(dataByChannel{ii},tapers,numPoints,params.Fs);%by using numPoints means no padding
            end
            ChannelList{ii}=alleeg.chanlocs(ii).labels;
        end

        if ac==0
            %check if any are missing from dataset
            pairslist=reshape(pairs,1,numel(pairs)); %to have an easy to index list for code below
            for p2=1:numel(pairs) %for each coherence pair
                if sum(strcmpi(pairslist{p2},ChannelList))==0
                   fprintf('%s of the pairs list not present in %s, aborting run',pairslist{p2},alleeg.setname)
                   return
                end
            end
        else
            combinations=nchoosek(1:numChan,2); %all possible combinations of 2 channels, nx2 matrix
%             combinations=[1 2]; %for testing to speed up
            pairs=ChannelList(combinations);
        end
        %%
        % run coherence on channels chosen above, don't save cross spectrum or
        % individual spectrum or phase of confC or phistd since not planning to use. f is the same for
        % all so just save one
        


        %first initialize matrices to save processing time
        if params.trialave==1 %these would all be different if averaging each snippet separately
            numCPoints=ceil(size(dataByChannel{1},1)/(params.Fs/(params.fpass(2)-params.fpass(1)))+1);
            %number of values seems to be number of datapoints/ratio of freqRec
            %over frequency range analyzed at all +1 (so 2000 datapoints at 200 Hz
            %from 0 to 100 Hz gives 1001 coherence points.
            %2/25/11 added ceil since was giving a fraction and worked for
            %1 dataset
            C{1}=zeros(numCPoints,1); 
            C=repmat(C,1,size(pairs,1)); %to make into the right number of cells for each comparison
            Cerr{1}=zeros(2,numCPoints);
            Cerr=repmat(Cerr,1,size(pairs,1));
        else
            disp('Code not setup for trialave=0, though may not be big deal to fix'); %not clear what needs to change, need to try it out
            return
        end
        %%

        for q=1:size(pairs,1) %for each coherence pair
%             ChanIndex1=strcmpi(pairs(q,1),ChannelList);
%             ChanIndex2=strcmpi(pairs(q,2),ChannelList);
%             dataAsChannelPairs{q}{1}=dataByChannel{ChanIndex1};
%             dataAsChannelPairs{q}{2}=dataByChannel{ChanIndex2};
             [C{q},phi,S12,S1,S2,f,confC,phistd,Cerr{q}]=coherencycJ(JByChannel{combinations(q,1)},JByChannel{combinations(q,2)},params,numPoints);%send FFT instead of data and send numpoints
%               [C{q},phi,S12,S1,S2,f,confC,phistd]=coherencyc(dataAsChannelPairs{q}{1},dataAsChannelPairs{q}{2},params);%3/19/11 no Cerr to save time
        end

        %%
        % save results
        if exist([savename '_Coh.mat'])==2
            savename=[savename datestr(clock)];
        end
%         save([savename '_Coh.mat'],'C','f','Cerr','params','ChannelList','pairs','dataAsChannelPairs');
           save([savename '_Coh.mat'],'C','f','Cerr','params','ChannelList','pairs','dataByChannel','combinations','freqResolution'); %saving dataAsPairs takes too much memory!
%             save([savename '_Coh.mat'],'C','f','params','ChannelList','pairs'); %3/19/11
    end
end