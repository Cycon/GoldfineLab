function data=MakeLaplacian(dataOriginal,channels)
%
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

%note if you use a(:,:,:) for a 2 D array it works fine.

if ndims(dataOriginal)>3 || size(dataOriginal,1)~=length(channels)
    disp('Data for MakeLaplacian needs to be channelsxdata points (x epochs)');
end

%initialize data so can put in the non-EEG channels immediately
data=zeros(size(dataOriginal));
EEG_ch= true(1,size(dataOriginal,1));%make a logical vector of 1s for EEG channels

%first convert chanlocs structure into a cell array
if isstruct(channels)
    if isempty(channels(1).X) %if is a .edf file from xltek at BUrke 11/27/12
        chan={channels.labels};%names of channels in a cell array, assume all are EEG
        disp('Assuming that all channels are EEG (no accelerometer channels');
    else %if is standard import
        channelsCell=struct2cell(channels);
        chan=squeeze(channelsCell(1,1,:));%names of channels in a cell array
        
        %determine which channels aren't EEG
        EEG_ch(isnan([channels.X]))=false;%logical index of non-EEG channels
        data(~EEG_ch,:,:)=dataOriginal(~EEG_ch,:,:);%fill in those rows
    end
end

%remove extra rows
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

%%
opts.Laplacian_nbrs_interior=4;%11/30/11 tried to improve consistency of shape if channel locations change,default is 4. Doesn't help

%modified 11/15/11 to detect EGI array since I think electrode names begin
%with E
if strcmpi('E1',chan(1)) %assuming first channel is E1
    disp('assuming EGI 129 channel array');
    eegp_opts=eegp_defopts_eeglablocsAndy('EGI129');
    HjorthMatrix=cofl_xtp_makemont(chan(EEG_ch)',[],opts,eegp_opts);%[] means same channels out as goes in. Could change if want to display EMG but not use for laplacian
else %just use the default channel locations by not defining eegp_opts
    HjorthMatrix=cofl_xtp_makemont(chan(EEG_ch)',[],opts);
end

[a b c]=size(dataOriginal);
data(EEG_ch,:,:)=reshape(HjorthMatrix*reshape(dataOriginal,a,[]),a,b,c); %note convert to 2D matrix for multiplication then convert back.
