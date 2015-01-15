function [data,ChannelList]=CombineChannels(dataOriginal,leads,opts)

%Stacks channels together to create new combo channels to create average
%spectra across them in runEeglabSpectra. 
%
%Created 11/29/11 AMG

if nargin<3 || ~isfield(opts,'AvgNumregions')
    opts.AvgNumregions=4;
end

if isstruct(leads) %if comes in as a chanlocs file
    LeadList=struct2cell(leads);
    LeadList=squeeze(LeadList(1,1,:));%names of channels in a cell array
else
    LeadList=leads;
end

%EMU40+18 with all or 35 leads (missing AF7 and AF8 okay but not F1 and
%F2 though that only happens with one dataset so okay).
if length(LeadList)==35 || length(LeadList)==37
    if ~sum(+strcmpi('F1',LeadList)) %if F1 not present
        disp('CombineChannels assumes F1 is present if 35 channels');
        return
    end
    fprintf('Combining Channels - %.0f channels found, assuming EMU40+18 montage\n',length(LeadList));
    if opts.AvgNumregions==4
        combinedList={'F3','F1','FC1','FC5';'C3','CP5','CP1','P3';'F4','F2','FC2','FC6';'C4','CP6','CP2','P4'};
    elseif opts.AvgNumregions==2
        combinedList={'Fz','FC1','FC2','Cz';'CP1','P3','CP2','P4'};
    else %assume 6 regions, add central head regions, need all to have same number
        disp('6 regions not made yet');
        return
%         combinedList={'F3','FC1','FC5''C3';'CP5','CP1','P3';'F4','F2','FC2','FC6';'C4','CP6','CP2','P4';'Fz','Cz','F1,'F2';'CPz','Pz','POz'};
    end
end

if length(LeadList)==29
    if opts.AvgNumregions==2
        combinedList={'Fz','FC1','FC2','Cz';'CP1','P3','CP2','P4'};
    end
end

data=zeros(size(combinedList,1),size(dataOriginal,2)*size(combinedList,2),size(dataOriginal,3));
for jj=1:size(combinedList,1)
    for kk=1:size(combinedList,2)
        data(jj,(kk-1)*size(dataOriginal,2)+1:(kk)*size(dataOriginal,2),:)=dataOriginal(strcmpi(LeadList,combinedList{jj,kk}),:,:);
    end
    ChannelList{jj}=[combinedList{jj,:}];
    %do chanlocs elsewhere since typically created on the fly
end

