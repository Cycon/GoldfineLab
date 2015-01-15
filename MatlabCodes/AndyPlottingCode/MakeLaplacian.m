function data=MakeLaplacian(dataOriginal,channels)
%
%Code that calls Jon Victor's cofl_xtp_makemont to make a laplacian montage
%from EEGLAB data. dataOriginal is the eeg.data variable which is channels
%by time by epoch. Channels can be a cell array of channels or an EEGLAB
%chanlocs variable. Works with 10-20 locations and with EGI33 and EGI129
%but not yet programmed for other EGI systems (simply needs center
%determined for them).
%
%
%HISTORY
%New version 5/17/11 that uses cofl_xtp_makemont to make laplacian montage
%dynamically. Give data organized as channels x data x trials.
%Then channels is either cell array list of channels or an EEGLAB chanlocs structure.
%Important that all channels are represented in eegp_defopts which is where
%their locations are specified.
%version 2 has new lead locations
%version 3 allows for normalization by total power, requires params.Fs at
%minimum
%version 4 11/15/11 option to run on the EGI array (initially used with
%Srvivas's data but meant for our 129 headcap too)
%version 5 12/13/11 will ignore channels not located on head (like acc).
%Determined by EEG.chanlocs.X=NaN (done in importAccEeglab and JV's
%chanlocs code). Requires chanlocs as the second input obviously.
%version 6 7/6/12 discovered that the eeglab channel location file
%(standard 2005.mat) is not symmetrical so leads to laplacians that
%are more on one side of the head or another. Will remove call to eegp_defopts_eeglablocsAndy
%([] though still used to get the EGI128 in correctly). [] Also may
%want to incorporate JV's code that reduces the EGI128 to a
%standard 10-20 set.
%version 7 11/27/12 for bringing in patient EEG from Burke from a .edf file
%where channel labels exist but no information about channel location.
%version 8 8/6/13 allow 32 channel EGI system
%version 9 12/15/13 more flexible in case remove channels from the EGI, but
%in this case will require a chanlocs structure with the locations rather than just the
%channel names. Also fixed so it should work if not a chanlocs structure
%(didn't seem to have a way to deal with the variable if not a structure!).

%note if you use a(:,:,:) for a 2 D array it works fine.

if ndims(dataOriginal)>3 || size(dataOriginal,1)~=length(channels)
    disp('Data for MakeLaplacian needs to be channelsxdata points (x epochs)');
end

%% set defaults
%make HjorthAbsRescaled Matrix
opts.mont_mode='Laplacian';%there's a bipolar version but don't know how to get it to work

opts.Laplacian_type='HjorthAbsRescaled'; %also could do Hjorth, HjorthAbs and two others wth Qua

%  opts.Laplacian_type='ParabAbsRescaled';
%    opts.Laplacian_type='GenqAbsRescaled'; %gives weird results 5/26/11 so don't use
%  if strcmpi(opts.Laplacian_type,'GenqAbsRescaled') %required to fit the model
%      opts.Laplacian_nbrs_interior=6;
%      opts.Laplacian_nbrs_edge=5;
%  end
fprintf('Using %s montage\n',opts.Laplacian_type);


opts.Laplacian_nbrs_interior=4;%11/30/11 tried to improve consistency of shape if channel locations change,default is 4. Doesn't help

%%

%initialize data so can put in the non-EEG channels immediately
data=zeros(size(dataOriginal));
EEG_ch= true(1,size(dataOriginal,1));%make a logical vector of 1s for EEG channels

%if comes in as a chanlocs structure, if has locations then just use them
%though need to first make sure and remove channels that don't have
%locations (e.g., accelerometer channels)

if isstruct(channels)% if it's a chanlocs structure, convert to just a channel list
    if isempty(channels(1).X) %if no location information like an .edf file from xltek at BUrke 11/27/12
        chan={channels.labels};%names of channels in a cell array, assume all are EEG since EEG_ch all 1s
        disp('Assuming that all channels are EEG (no accelerometer channels');
        HjorthMatrix=cofl_xtp_makemont(chan(EEG_ch)',[],opts);%run it where it looks up the channel locations
    else %if is standard chanlocs import and want to use the channel locations
        
        %determine which channels aren't EEG
        EEG_ch(isnan([channels.X]))=false;%logical index of non-EEG channels        
        data(~EEG_ch,:,:)=dataOriginal(~EEG_ch,:,:);%fill in those rows
        
        %then put the location information in the form wanted by
        %cofl_xtp_makemont. This code is copied from
        %eegp_defopts_eeglablocsAndy and moved here so don't need that code
        for ii=1:length(channels)
            defopts.EEGP_LEADS.(upper(channels(ii).labels))=[channels(ii).X channels(ii).Y channels(ii).Z];
        end
        
        %determine the center for EGI channels based on
        %eegp_findcenter_demo which just figures it out
        if strcmpi('E1',channels(1).labels)%if EGI
            if length(channels)<34 %EGI32
                defopts.EEGP_CENTER=[ 0.000000000  0.000000000 -0.157183000];%from running eegp_findcenter_demo 
            elseif length(channels)<130 %EGI129
                defopts.EEGP_CENTER=[0 0.0437 -0.0421];%4/20/12 this came from code defopts=egi_eegp_defopts([],'net128');
            end
        %if biosemi system used in Moss Rehab with extra channels removed
        %by bdfToEeglab so only 128 channels
        elseif strcmpi('A1',channels(1).labels) && length(channels)==128 
            defopts.EEGP_CENTER=[0    0.0652   -0.1808];%1/6/13 from eegp_findcenter_demo 
        end
        
        
        HjorthMatrix=cofl_xtp_makemont({channels(EEG_ch).labels}',[],opts,defopts);%run with channel locations defined
    end
else %if just a list of channels coming in
    HjorthMatrix=cofl_xtp_makemont(channels(EEG_ch)',[],opts);%run it where it looks up the channel locations
end

%% remove extra rows
dataOriginal(~EEG_ch,:,:)=[];

%%
%here multiply my 3d matrix (each 3rd Dimension) by JV's Hjorth multiplier
%ensuring only channels present are ones I'm interested in.


%Hjorth matrices have the output in rows and input in columns (confirmed 5/17/11
%by having fewer outputs than inputs). You are reordering the columns of the data so it goes on the right.  So I put Hjorth
%matrix on the left and my data on the right as it is channels x data. Can't multiply by whole 3D
%matrix so need to multiply one snippet at a time.


% dataHjorthOrder=zeros(size(eegDataReordered));
% for i=1:size(eegDataReordered,3) %for each snippet
%     dataHjorthOrder(:,:,i)=Hjorth*eegDataReordered(:,:,i);
% end


% %modified 11/15/11 to detect EGI array since I think electrode names begin
% %with E
% if strcmpi('E1',chan(1)) %assuming first channel is E1 
%     disp('assuming EGI system');
%     if length(chan)==129
%         eegp_opts=eegp_defopts_eeglablocsAndy('EGI129');
%     elseif length(chan)==33 %33 channels but called a 32 channel system
%         eegp_opts=eegp_defopts_eeglablocsAndy('EGI32');
%     end    
%     HjorthMatrix=cofl_xtp_makemont(chan(EEG_ch)',[],opts,eegp_opts);%[] means same channels out as goes in. Could change if want to display EMG but not use for laplacian
% else %just use the default channel locations by not defining eegp_opts
% %     HjorthMatrix=cofl_xtp_makemont(chan(EEG_ch)',[],opts);
% end

%% run the conversion
[a b c]=size(dataOriginal);
data(EEG_ch,:,:)=reshape(HjorthMatrix*reshape(dataOriginal,a,[]),a,b,c); %note convert to 2D matrix for multiplication then convert back.
