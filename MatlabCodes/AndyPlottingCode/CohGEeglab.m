function CohGEeglab

%this does coherograms (cohgramc) on eeglab format data
%Open .set file, run coherogram without error bars on all or preselected
%channel pairs. Then need a viewer program like subplotCoh
%to select which channel pairs and frequency ranges to look at.
%Might be good to write as a parrallel for loop across all 
%channel pairs so can run on CAC!
%
%Based on SGeeglab
%
%[] consider a plotting version that compares to coherograms or does
%baseline subtraction on the fly. Also make sure plotting program 
%has 0 to 1 color bar.
%NOT COMPLETE LEFT OFF ON LINE 131. Also think about parallel versino

[setfilename, pathname] = uigetfile('*.set', 'Select EEG file');
        
if setfilename==0; %if press cancel for being done
    return
end
alleeg = pop_loadset('filename',setfilename,'filepath',pathname);
%         

savename=setfilename(1:end-4);
if strcmpi(input('Use laplacian? (y-yes or Return): ','s'),'y')
    alleeg.data=MakeLaplacian(alleeg.data,alleeg.chanlocs);
    savename=[savename '_Lap'];
end

%%
%defaults
frequencyResolution=2;
%  fpassInHz=[0 100];
 params.pad=-1;
 params.Fs=alleeg.srate; %need to define this from data later in code
%  params.err=[1 0.05];
 params.trialave=0; %can change to 0 to look at one snippet at a time.
 %if 0, then output S is time points x frequencies x trials.
 %if 1, then output S is time points x spectrograms. Important to know for plotting
 %if movingwin is the length of each snippet then time points =1!
 movingwinInSec=[10 1];

 disp('Would you like to use default parameters for cohgramc?');
 fprintf('Frequency Resolution %.0f Hz\n',frequencyResolution);
 disp(params);
%  fprintf('    fpass (in Hz): [%.0f %.0f]\n',fpassInHz(1), fpassInHz(2));
 fprintf('    movingwin (in sec): [%.2f %.2f]\n',movingwinInSec(1), movingwinInSec(2));
 default = input('Return for yes (or n for no): ','s');
 if strcmp(default,'y') || isempty(default)
 else
     disp('define params (Return leaves as default)');
     FR=input('Frequency Resolution: ');
     if ~isempty(FR)
         frequencyResolution=FR;
     end
     p.pad=input('pad:');
     if ~isempty(p.pad)
         params.pad=p.pad;
     end
%      fpass1=input('starting frequency of fpass:');
%      if ~isempty(fpass1)
%          fpassInHz(1)=fpass1;
%      end
%      fpass2=input('ending frequency of fpass:');
%      if ~isempty(fpass2)
%          fpassInHz(2)=fpass2;
%      end
     p.mwinsec=input('moving win (in seconds in brackets like [1 0.1]):');
     if ~isempty(p.mwinsec)
         movingwinInSec=p.mwinsec;
     end
     if strcmpi(input('Average trials? (y-yes or Return for no)','s'),'y');
         params.trialave=1;
     end
     fprintf('\nparams are now:\n');
     disp(params);
     fprintf('movingwin (in sec): [%.2f %.2f]\n',movingwinInSec(1), movingwinInSec(2));
     fprintf('Frequency Resolution %.0f Hz\n',frequencyResolution);
 end
 
 params.tapers(1)=frequencyResolution/2*movingwinInSec(1);
 params.tapers(2)=params.tapers(1)*2-1;
 if params.tapers(2)<1
     disp('<1 taper, won''t work.');
     return
 end


%
%[] need to take data organized as dataxchannelxsnippet and reorganize to
%be dataxsnippet so can average across them and then do one channel at a
%time

params.fpass=fpassInHz;

%%
%chronux code wants data x trial which is just row and 3rd dimension of
%alleeg.data (will need to squeeze).

% %change to be data x snippet with each channel in a cell
% numChan=size(alleeg.data,1);
% numSnip=size(alleeg.data,3);
% for i=1:numChan
%     for j=1:numSnip
%         dataByChannel{i}(:,j)=alleeg.data(i,:,j); %organized as dataxsnippet (dataxtrial in chronux terms)
%     end
ChannelList={alleeg.chanlocs.labels};
% end

% alleeg.data=reshape(alleeg.data,size(alleeg.data,1),[]);%convert to channels x data
    
combinations=nchoosek(1:numChan,2); %all possible combinations of 2 channels, nx2 matrix
% combinations=[1 2]; %for testing to speed up
pairs=ChannelList(combinations);
for q=1:size(pairs,1)%for each coherence pair
    [C{q},phi,S12,S1,S2,t,f,confC,phistd,Cerr{q}]=cohgramc(squeeze(alleeg.data(combinations(q,1),:,:),squeeze(alleeg.data(combinations(q,2),:,:),movingwinInSec,params);
    [S{ij},t{ij},f{ij}]=mtspecgramc(dataByChannel{ij},movingwinInSec,params);
%     [S{ij},t{ij},f{ij},Serr{ij}]=mtspecgramc(dataByChannel{ij},movingwinInSec,params);
end
    
% end
if exist([savename '_SG.mat'])==2
    savename=input('Savename already exists, new name: ','s');
end
event=alleeg.event;%want to save event information for displaying in spectrograms
if isfield(alleeg,'startTime')
    startTime=alleeg.startTime;
else
    startTime='';
end
save([savename '_SG.mat'],'S','t','f','params','movingwinInSec','ChannelList','event','startTime')
% save([savename
% '_SG.mat'],'S','t','f','Serr','params','movingwinInSec','ChannelList')
end

