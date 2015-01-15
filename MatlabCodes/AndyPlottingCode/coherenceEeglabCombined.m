function savenameCoh=coherenceEeglabCombined

%to load in previously run coherences and access the original data within
%and then run coherence. Consider auto calling subplot with comparison
%note that dataAsChannelPairs from Coheeglab is already converted to
%laplacian. This code uses same params as the 1st Coh file called in

%%
 redefineparams=0; %to use params from last file
if strcmpi(input('Use params from chosen coherence file (n / Return)?','s'),'n')
    redefineparams=1;
    disp('define params (Return uses defaults if displayed)');
     newparams.tapers(1)=input('NW:');

     newparams.tapers(2)=input('K:');

     pad=input('pad (default -1):');
     if isempty(pad)
         newparams.pad=-1;
     else
         newparams.pad=pad;
     end

     err1=input('error type (1 theoretical, 2 jacknife, default 2):'); %called err1 since can't assign [] to err(1)
     if isempty(err1)
         newparams.err(1)=2;
     else
         newparams.err(1)=err1;
     end
     err2=input('p-value (default 0.05):');
     if isempty(err2)
         newparams.err(2)=0.05;
     else
         newparams.err(2)=err2;
     end
     fpass1=input('starting frequency of fpass (default 0):');
     if isempty(fpass1)
         newparams.fpass(1)=0;
     else
         newparams.fpass(1)=fpass1;
     end
     fpass2=input('ending frequency of fpass (default 100):');
     if isempty(fpass2)
         newparams.fpass(2)=100;
     else
          newparams.fpass(2)=fpass2;
     end

     fprintf('\nparams are now:\n');
     disp(newparams);
end
 
%%
%allow for running on multiple sets and then TGT on every other
comb=1;
while comb %number of combinations
    %first if not first, ensure user wants to do more
    if comb~=1 
        if ~(strcmpi(input('Run on additional combination? (y/n)[n]','s'),'y'))
            comb=comb-1;
            break
        end
    end
    
    %then allow choice of preexisting or make new.
    clear pathname cohFilename dataAsChannelPairs
    if (strcmpi(input('Use existing combined dataset (made with this code) (y/Return)?','s'),'y'))
        [combinedFilename, pathname] = uigetfile('*_DataCombined.mat', 'Select combined file');
%         load(fullfile(pathname,combinedFilename));%to just bring into the workspace
        combFileName{comb}=fullfile(pathname,combinedFilename);
        savename{comb}=combinedFilename(1:end-17);
%         Fs=params.Fs;
%         if redefineparams
%             params=newparams; %otherwise just defined based on importdata, though need params.Fs from data!
%             params.Fs=Fs;
%         end
        comb=comb+1;
    else


        savename{comb}=input('Savename: ','s');

        %%
        %load in file, allow to choose from multiple folders
        more=1;
        while more %number of files in each combination
            selectText=sprintf('Select Coh file %.0f for combining or Cancel',more);
            [cohFilename{more}, pathname{more}] = uigetfile('*Coh.mat', selectText,pwd);
            if cohFilename{1}==0
                return;
            end
            if cohFilename{more}==0
                cohFilename=cohFilename(1:more-1);
                more=0;
            else
                more=more+1;
            end
        end


        for i=1:length(cohFilename)
            %first combine them into a new file and save it. make sure it's runable
            %by subplot meaning the same as the originals just added on more. Also
            %need to choose to use same params or send down from above
            cohFile{i}=load(fullfile(pathname{i},cohFilename{i}),'dataAsChannelPairs','pairs','params','ChannelList'); 
            dataLength(i)=size(cohFile{i}.dataAsChannelPairs{1}{1},1);%assuming all the same length
            numTrials(i)=size(cohFile{i}.dataAsChannelPairs{1}{1},2);
        end
        %can put a test in to ensure same number of channel pairs at least

        %next need to measure the shortest one then can combine them.
        minLength=min(dataLength);

        %data organized as data x trials so add on new trials to the right
        %first initialize dataAsChannelPairs
        dataAsChannelPairs={zeros(minLength,sum(numTrials))};
        dataAsChannelPairs={repmat(dataAsChannelPairs,1,2)};
        dataAsChannelPairs=repmat(dataAsChannelPairs,1,length(cohFile{1}.dataAsChannelPairs));
        for m=1:length(cohFile) %for each file
            if m==1
                start=1;
            else
                start=sum(numTrials(1:m-1))+1;
            end
         for j=1:length(cohFile{1}.dataAsChannelPairs)%for each channel pair
                dataAsChannelPairs{j}{1}(1:minLength,start:sum(numTrials(1:m)))=cohFile{m}.dataAsChannelPairs{j}{1}(1:minLength,:);
                dataAsChannelPairs{j}{2}(1:minLength,start:sum(numTrials(1:m)))=cohFile{m}.dataAsChannelPairs{j}{2}(1:minLength,:);
         end
        end

        ChannelList=cohFile{1}.ChannelList;
        pairs=cohFile{1}.pairs;
        if redefineparams
        %then just use params defined above
            params=newparams;
            params.Fs=cohFile{1}.params.Fs;
        else
            params=cohFile{1}.params; %use the one from the last one read in
        end
        combFileName{comb}=fullfile(pwd,[savename{comb} '_DataCombined']);
        save([savename{comb} '_DataCombined'],'dataAsChannelPairs','ChannelList','pairs','params');
        comb=comb+1;
    end
end    
    
%%
for cc=1:length(combFileName) %for each combined File
    %run coherence next
    % disp('running coherence on:');
    % disp(pairs);

    %data is coming in as pairs of cells organized as dataxsnippet. Need to
    %make sure all the same length!
%     combFile=load([savename{cc} '_DataCombined.mat']);
    combFile=load(combFileName{cc});
    if redefineparams
        params=newparams; %otherwise just defined based on importdata, though need params.Fs from data!
    else
        params=combFile.params;
    end
    params.trialave=1;%just to make sure
    params.Fs=combFile.params.Fs;%to ensure comes from imported data
    
    for q=1:size(combFile.pairs,1) %for each coherence pair
        [C{q},phi,S12,S1,S2,f,confC,phistd,Cerr{q}]=coherencyc(combFile.dataAsChannelPairs{q}{1},combFile.dataAsChannelPairs{q}{2},params);
    end

    %%
    % save results
    if exist([savename{cc} '_Coh.mat'],'file')==2
        savenameCoh{cc}=[savename{cc} datestr(clock)];
    end
    ChannelList=combFile.ChannelList;
    pairs=combFile.pairs;
    dataAsChannelPairs=combFile.dataAsChannelPairs;
    savenameCoh{cc}=[savename{cc} '_Coh.mat'];
    save(savenameCoh{cc},'C','f','Cerr','params','ChannelList','pairs','dataAsChannelPairs');
    
    if ~mod(cc,2) %every other
        subplotEeglabCoh([savename{cc-1} 'vs' savename{cc}],savenameCoh{cc-1},pwd,savenameCoh{cc},pwd,'1','2',0,[0 100],0)
    end
end
end


