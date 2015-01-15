% function [S,f,savename]=runEeglabSpectra(alleeg,eegorica,combineddata,name)
function [S,f,savename]=runEeglabSpectra_Robust(alleeg,opts,mtmethod,combineddata)

%called by PSeeglab
%
%opts.eegorica 'e' or 'i'
%opts.FR value for frequency resolution
%opts.lap for laplacian
%opts.bip for bipolar
%
%runs eeglabSpectra on data sent from eeglabSpectra. Kept separate since
%eeglabSpectra pulls from active workspace
%version 2 - 8/31/10 adds option for laplacian
%verion 3 - 3/18/11 added option to run on first 30 seconds if too long
%version 3.1 - 11/7/11 modified call to MakeBipolar.
%11/28/11 removed "EEG" from end of savename since obvious
%version 4 - 11/29/11 [x] give option to average together multiple channels
%instead of running on all of them. 
%[x]remove calculation of spectra for individual trials which FLD used
%(done in batCrxSpectra I think). [x] Set frequency resolution in call to
%this code so don't need to change in the code (or make it in the opts
%structure). [x] Give an opts input so can add more options easily (like
%combining channels and frequency resolution). [x] Change frequency
%resolution to be a default if the opts.FR field doesn't exist
%version 4.1 12/5/11 changed to mtspectrumc from ULT because the TGT doesn't have
%ULT version and with EEGLAB force everything to be equal so error bars
%probably aren't accurate this way (though ULT would be better since contiguous
%often but not an option with TGT). Make output look the same 
%as ULT so don't need to change subplotEeglabSpectra. 
%12/13/11 fixed bug that if no ICA present it crashed.
%12/20/11 version 5 have montage come in as an option rather than within the alleeg
%structure
%1/18/12 fixed error where was putting Lap at end even if wasn't running
%laplacian

%%
%set defaults and choose datatype
%If Fs is specified in Hz, windows have to specified in seconds. fpass
%should also be specified in Hz. so, Fs=256, movingwin=[1 0.2] and fpass=[0
%50]. 
if ~isfield(opts,'lap')
    opts.lap=0;
end
if ~isfield(opts,'bip')
    opts.bip=0;
end

snippetLengthInSec=alleeg.pnts/alleeg.srate;
if snippetLengthInSec>30
    if strcmpi(input('Data > 30 seconds, want to run on first 30 sec only? (y/n)[n]','s'),'y')
        alleeg.data=alleeg.data(:,1:alleeg.srate*30);
        if strcmpi(opts.eegorica,'i')
            alleeg.icaact=alleeg.icaact(:,1:alleeg.srate*30);
        end
        snippetLengthInSec=30;
    end
end
frequencyRecorded=alleeg.srate;
% if ~isfield(opts,'FR')
%     frequencyResolution=2; %in Hz
% else
%     frequencyResolution=opts.FR;
% end
% if ~isfield(opts,'Avg')
%     opts.Avg=0; %default is to not average channels
% end
% params.tapers(1) = snippetLengthInSec*frequencyResolution/2;
% params.tapers(2) = floor(params.tapers(1)*2-1); %set from data and frequency Resolution above, 3/2/11 added floor
% if params.tapers(2)<1
%     disp('Frequency Resolution too low for segment length in runEeglabSpectra');
%     return
% end
%params.tapers(1)=getinp('chronux NW','d',[1 101],3);
%params.tapers(2)=getinp('chronux k','d',[1 101],2*params.tapers(1)-1);

%%%% Changed default NW = 3 K = 5; uncomment to manually prompt!
params.tapers(1)=3;
params.tapers(2)=5;

params.pad=-1;
params.Fs=frequencyRecorded;
% params.fpass=[0 100];
params.trialave=1; %was not on for ULT but turn on for regular 12/5/11
params.err=[2 0.05];
chanlocs=alleeg.chanlocs;
% movingwinInSec=[snippetLengthInSec snippetLengthInSec]; %number of seconds per snippet, in seconds since fpass in Hz, determined by data
 

%%
%naming of output
icadata=0; %use to determine if running on components or eeg in subplot program
if nargin>3 %if running on one combined dataset
    data=combineddata;
    
    if opts.lap
        savename=[opts.name '_Lap_PS'];
    else
        savename=[opts.name '_PS'];
    end
else
    combineddata=0;
    opts.name=0;
    % eegorica=input('Run on ICA components or EEG (i - ica, e - eeg)?','s');
    if strcmp(opts.eegorica,'i')
        data=alleeg.icaact;
        icadata=1;
        savename=sprintf('%s_ICA_PS',alleeg.setname);
    elseif strcmp(opts.eegorica,'e')
        data=alleeg.data;
        if opts.lap %if laplacian chosen
                if isfield(alleeg,'filename')
                    savename=sprintf('%s_Lap_PS',alleeg.filename(1:end-4));%changed to filename on 9/1/10
                else
                    savename=sprintf('%s_Lap_PS',alleeg.setname);
                end
            else %if laplacian not selected
                if isfield(alleeg,'filename')
                    savename=sprintf('%s_PS',alleeg.filename(1:end-4));%changed to filename on 9/1/10
                else
                    savename=sprintf('%s_PS',alleeg.setname);
                end
        end
    else
        return
    end
end

numSnippets=size(data,3);
%%
numChannels = size(data,1); %or components
%data is ch x data x epochs. look at 1 channel at a time. With squeeze
%command it becomes data x epochs which mtspectrumc takes and averages
%across.


%% Run laplacian
%first check if a field (since not an option in PSeeglab combined yet []
%needs to work for dataBySnippet and dataReshaped. Can it work on data?
if opts.lap %if it equals 1 meaning user wants laplacian
        %next need to assign all rows of dataReshaped to new names and then
        %paste in formulas or have if for number of channels and send to
        %new code to rename, one for ekdb 12 and oneemu40
    data=MakeLaplacian(data,chanlocs);
end
 
%%
%put option here to convert to Shawniqua bipolar montage 3. Need to change
%the data as well as create a ChannelList and then skip below. Also need
%to modify code that calls this to allow for bipolar montaging. Will modify
%PSeeglab only. Also need to modify CohEeglab.
if opts.bip
    [data,ChannelList]=MakeBipolar_Robust(data,chanlocs);
    savename=[savename(1:end-7) '_Bip_PS'];
    numChannels=size(data,1);
end


%%
%combine together multiple channels
%[] make a new datset where they're one after the other
%[] create a .mat file or .m that lists the average channels depending on
%the number of channels or just the leads present or come up with a
%standard list that works on all datasets?
%[] rename the channel with all the prior names in a row. Create a variable
%called ChannelList so don't need to create below from the chanlocs
%[] consider for plotDifferenceMap a modification of the chanlocs file that
%catches that its multiple channels (by spaces present) and creates an
%average lead location for each one. Not necessary here!
if opts.Avg %if set to 1 by PSeeglab (need to modify other codes that call this)
    if opts.bip %give error message and don't run this
        disp('Channel Averaging not setup yet for bipolar montage'); 
    else
        if ~isfield(opts,'AvgNumregions')
            opts.AvgNumregions=4;
        end
        [data,ChannelList]=CombineChannels(data,chanlocs,opts);
        savename=[savename(1:end-2) 'Avg_PS'];
        numChannels=size(data,1);
    end
end
    

%use mtspectrumc_ULT so use more of the data and more similar to current
%results. Use reshape and don't forget it detrends in it. Need to
%transpose. Need to make sMarkers
% sMarkers = zeros(size(data,3),2);
% for s=1:size(sMarkers,1)
%     sMarkers(s,:)=[(s-1)*size(data,2)+1 s*size(data,2)];
% end


%%
%Run Power spectra
% dataReshaped=reshape(data,size(data,1),size(data,2)*size(data,3)); %channels by datapoints (snippets stacked)
% [S,f,Serr]=mtspectrumc_unequal_length_trials(dataReshaped',movingwinInSec,params,sMarkers);

%
if isfield(params,'fpass')
    numFreq=floor(params.fpass(2)/2)+1;%depends on range of frequencies calculated
else
    numFreq=floor(size(data,2)/2)+1;
end
S=zeros(numFreq,size(data,1));
Serr=zeros(2,size(S,1),size(S,2));
dc={zeros(size(data,2),size(data,3))};
dataCutByChannel=repmat(dc,1,size(data,1));
%
for ps=1:size(data,1) %for each channel
    [S(:,ps) f Serr(:,:,ps)]=mtspectrumc_Robust(squeeze(data(ps,:,:)),params, mtmethod); %stack each spectra in a column which is way that ULT gives the output
    dataCutByChannel{ps}=squeeze(data(ps,:,:));%11/29/11 this is used only for batTGT in subplotEeglabSpectra
end
%%
% if ~icadata && ~ccadata %removed June 6 to allow ICA comparisons
    %need to send to batCrxSpectra to get cut and prepared for TGT and Fisher
    %It wants data with each snippet per cell and organized as (data x channels)
    %probably don't want to do this for ICA data since won't be comparing
    %components yet. Don't need to detrend here 

%     dataBySnippet{1}=zeros(size(data,1),size(data,2));
%     dataBySnippet=repmat(dataBySnippet,1,size(data,3));
%      for is = 1:numSnippets
%           dataBySnippet{is}=(data(:,:,is))'; %transposed and put in cell form for batCrxSpectra
%      end
% 
%     [spectraByChannel,fMtSpectrumc,dataCutByChannel,neighborTag]=batCrxSpectra('input1','input2',0,params,movingwinInSec(1),dataBySnippet,params.Fs); 
    %inputs 1 and 2 are just placeholders. 0 is to tell batCrxSpectra to not
    %save results
    %[] need code to Change ordering of channels

%     %11/29/11 - not using unequal length trials anymore since not allowed
%     %by EEGLAB and not using Fisher so don't need batCrxSpectra. Just need
%     %dataCutByChannel (cells with time point x trials) for batTGT and fMtSpectrumc for the TGT plotting
%     for icc=1:size(data,1) %for each channel
%             dataCutByChannel{icc}=squeeze(data(icc,:,:));
%     end
    
    
%     if isfield(alleeg,'bipolar') && alleeg.bipolar %since ChannelList comes from makeBipolar
    if exist('ChannelList','var'); %comes from bipolar or from the combining of multiple channels
    else %if the field doesn't exist or the field does exist and bipolar not chosen
        if ~isempty(alleeg.chanlocs)
            for cl=1:length(chanlocs)
                if ~icadata
                    ChannelList{cl}=chanlocs(cl).labels;
                else
                    ChannelList{cl}=num2str(cl);
                end
            end
        else
            for cl=1:numChannels
                ChannelList{cl}=num2str(cl);
            end
        end
    end
    savename = [savename '_' mtmethod.class];
    savename(savename==' ')=[];% to remove spaces in the name of the file
    
   
    
    save (savename,'S','f','Serr','frequencyRecorded','numChannels','icadata','ChannelList','dataCutByChannel','params');
    fprintf('%s created\n',savename);

end

