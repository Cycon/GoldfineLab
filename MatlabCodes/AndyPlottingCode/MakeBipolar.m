function [dataBipolar, ChannelList,chanlocs]=MakeBipolar(dataOriginal,leads)


%Give it a matrix of channels x data (like EEG.data) and a list of the
%electrodes. Variable "leads" can either
%be a cell array list of channels or an EEGLAB chanlocs structure.
%version 1 had the multipliers in it. dataOriginal should be original
%reference (to a single electrode) or common average reference (NOT
%LAPLACIAN).
%11/6/11 added option for EMU40+18 (assuming all electrodes present)
%11/7/11 version 2 - modify code to actually create the bipolar matrix here. Advantage
%is it can take in different channel orders.
%1/6/12 version 3 - added options for 19 (2008) and 30 (unclear if exists)
%bipolar
%1/12/12 version 4 DT - actually creates a chanlocs variable based on
%average of spherical coordinates using Dan's code SphericalMean.
%[] Consider making another code that can create a chanlocs file using the
%mean of each. Would be useful for plotDifference Map. Make sure that JVs
%doesn't do this first. The chanlocs output here is just the lead names.
%Output can be plotted with eegplot(dataBipolar,'eloc_file',chanlocs);
%[] If want more than one bipolar type (like transverse in addition) would need
%to put an input statement for user to choose.
%7/6/12 removed call to eegp_defopts_eeglablocsAndy since asymmetric
%11/28/12 give ability to use edf file which doesn't have channel location
%information (X,Y,Z are blank). Though need to fix this simply using eegp_make_chanlocs.
%11/29/12 add in 8 channel version for Dylan's headbox
%4/16/13 add in another 20 lead version for Columbia (similar but some
%different channels from White Plains)

%note, if used to modify an existing EEG file, need to change EEG.nbchan
%since likely 1 or more fewer channels.

%%
%set defaults (only one option now, if user wants other bipolar types like
%transverse then add in an input question here).
bipolartype='DoubleBanana';%this isn't used but if other options then
%add if statements below

%%
%first convert chanlocs structure into a cell array. Need to make the
%output a chanlocs file too so can do nicer plotting.
if isstruct(leads)
    if isempty(leads(1).X) %if is a .edf file from xltek at Burke 11/27/12
        disp('No channel location information. Run addChanlocsLocations first on the .set file');
    else
        LeadList=struct2cell(leads);
        LeadList=squeeze(LeadList(1,1,:));%names of channels in a cell array
    end
else
    LeadList=leads;
end

%%
%Next create the bipolar multiplier matrix depending on the number of
%channels and which channels are present and preset lists. Have catches in
%case channels are not present in the data.
montage=[];
%EKDB12 with 29 leads
if length(LeadList)==29
    montage={'FP1' 'F3';'F3' 'FC1';'FC1' 'C3';'C3' 'CP1';'CP1' 'P3';'P3' 'O1';'FP2' 'F4';'F4' 'FC2';'FC2' 'C4';'C4' 'CP2';'CP2' 'P4';'P4' 'O2';'FP1' 'AF7';'AF7' 'F7';'F7' 'FC5';'FC5' 'T3';'T3' 'CP5';'CP5' 'T5';'T5' 'O1';'FP2' 'AF8';'AF8' 'F8';'F8' 'FC6';'FC6' 'T4';'T4' 'CP6';'CP6' 'T6';'T6' 'O2';'FZ' 'CZ';'CZ' 'PZ'};
    disp('Creating bipolar montage assuming EKDB12 with 29 leads (no FPz)');
end

if length(LeadList)==19 %added 1/6/12
    montage={'Fp1' 'F3';'F3' 'C3';'C3' 'P3';'P3' 'O1';'Fp2' 'F4';'F4' 'C4';'C4' 'P4';'P4' 'O2';'Fp1' 'F7';'F7' 'T3';'T3' 'T5';'T5' 'O1';'Fp2' 'F8';'F8' 'T4';'T4' 'T6';'T6' 'O2';'Fz' 'Cz';'Cz' 'Pz'};
    disp('Creating bipolar montage assuming Mobee 32 headbox with 19 leads like 2008 datasets');
end

if length(LeadList)==30
    montage={'FP1' 'F3';'F3' 'FC1';'FC1' 'C3';'C3' 'CP1';'CP1' 'P3';'P3' 'O1';'FP2' 'F4';'F4' 'FC2';'FC2' 'C4';'C4' 'CP2';'CP2' 'P4';'P4' 'O2';'FP1' 'AF7';'AF7' 'F7';'F7' 'FC5';'FC5' 'T3';'T3' 'CP5';'CP5' 'T5';'T5' 'O1';'FP2' 'AF8';'AF8' 'F8';'F8' 'FC6';'FC6' 'T4';'T4' 'CP6';'CP6' 'T6';'T6' 'O2';'FPz' 'Fz';'FZ' 'CZ';'CZ' 'PZ'};
    disp('Creating bipolar montage assuming EKDB12 with 30 leads');
end

%EMU40+18 or EMU128 with 37 leads on the head
if length(LeadList)==37
    montage={'Fp1' 'FPz';'Fp1' 'F3';'F3' 'FC1';'FC1' 'C3';'C3' 'CP1';'CP1' 'P3';'P3' 'O1';'FPz' 'Fp2';'Fp2' 'F4';'F4' 'FC2';'FC2' 'C4';'C4' 'CP2';'CP2' 'P4';'P4' 'O2';'Fp1' 'AF7';'AF7' 'F7';'F7' 'FC5';'F1' 'FC1';'FC5' 'T3';'T3' 'CP5';'CP5' 'T5';'T5' 'PO7';'PO7' 'O1';'Fp2' 'AF8';'AF8' 'F8';'F8' 'FC6';'F2' 'FC2';'FC6' 'T4';'T4' 'CP6';'CP6' 'T6';'T6' 'PO8';'PO8' 'O2';'Fz' 'Cz';'Cz' 'Pz';'CPz' 'POz';'POz' 'Oz'};
    disp('Creating bipolar montage assuming EMU40 with 37 (all) leads');
end

%EMU40+18 missing 2 electrodes (like AF7 AF8 or F1 F2)
if length(LeadList)==35
    if sum(+strcmpi('AF7',LeadList)) %if AF7 is present, assume F1 missing
        disp('Creating bipolar montage assuming EMU40 assuming F1 and F2 missing');
        %montage=[];
    else %assume AF7 and AF8 are missing
        disp('Creating bipolar montage assuming EMU40 assuming AF7 and AF8 missing');
        %montage=[];
    end
end

%10-20 clinical setup used for Burke EEG November 2012 with 20 electrodes,
%though FPz isn't used in the xltek display, wonder if it is the reference?
%Will add it in anyhow
if length(LeadList)==20
    if sum(+strcmpi('T3',LeadList)) %If T3 is present, assume from White Plains where there is also T4 and T5 and T6
        montage={'FP1' 'F3';'F3' 'C3';'C3' 'P3';'P3' 'O1';'FP2' 'F4';'F4' 'C4';'C4' 'P4';'P4' 'O2';'FP1' 'F7';'F7' 'T3';'T3' 'T5';'T5' 'O1';'FP2' 'F8';'F8' 'T4';'T4' 'T6';'T6' 'O2';'FPZ' 'FZ';'FZ' 'CZ';'CZ' 'PZ'};
        disp('Creating bipolar montage assuming clinical EEG from White Plains Hospital');
    else %assume from Columbia where there is T7 and T8 and P7 and P8
        montage={'FP1' 'F3';'F3' 'C3';'C3' 'P3';'P3' 'O1';'FP2' 'F4';'F4' 'C4';'C4' 'P4';'P4' 'O2';'FP1' 'F7';'F7' 'T7';'T7' 'P7';'P7' 'O1';'FP2' 'F8';'F8' 'T8';'T8' 'P8';'P8' 'O2';'FPZ' 'FZ';'FZ' 'CZ';'CZ' 'PZ'};
        disp('Creating bipolar montage assuming clinical EEG from NYP Columbia Hospital');
    end
end

%added 11/28/12
if length(LeadList)==8
    montage={'F3' 'C3';'C3' 'P3';'Fpz' 'Cz';'F4' 'C4';'C4' 'P4'};
    disp('Creating bipolar montage assuming Dylan''s 8 channel.');
end

if isempty(montage)
    disp('Bipolar montage not yet created for the number of channels given, modify code MakeBipolar.m');
    return
end

%%
%make conversion matrix. Works by finding where the first electrode is in the
%list, converting it to a logical 1 then the + in front makes it a regular
%1. Then convert where the second lead is to a -1. Overall makes a
%conversion matrix where its number of bipolar channels x number of leads.
conversionMatrix=zeros(length(montage),length(LeadList));
ChannelList=cell(length(montage),2);
for ii=1:size(montage,1) %for each bipolar channel
    conversionMatrix(ii,:)=+strcmpi(montage{ii,1},LeadList)-strcmpi(montage{ii,2},LeadList);
    ChannelList(ii)={[montage{ii,1} '-' montage{ii,2}]};
    chanlocs(ii).labels=ChannelList{ii};
    chanlocs(ii).type=ii;
    %create chanlocs structure from original data
%     opts=eegp_defopts_eeglablocs;
    cv=eegp_makechanlocs(char(LeadList));
    ch1=cv(strcmpi(montage{ii,1},LeadList));
    ch2=cv(strcmpi(montage{ii,2},LeadList));
    %Spherical Mean
    [chanlocs(ii).X,chanlocs(ii).Y,chanlocs(ii).Z]=SphericalMean(ch1.X,ch1.Y,ch1.Z,ch2.X,ch2.Y,ch2.Z);
    chanlocs(ii).theta=0;
    chanlocs(ii).radius=0;
    chanlocs(ii).ref='bipolar';
end


%%
%here multiply my 3d matrix (each 3rd Dimension) by bipolar matrix
%multiplier.
%Bipolar multiplier matrices have the information in the rows. I want to in the end reorder the
%rows of my matrix since it's channels x data x snippet. So I put
%matrix on the left and my data on the right as it is channels x data. Can't multiply by whole 3D
%matrix so need to multiply one snippet at a time.

dataBipolar=zeros(size(conversionMatrix,1),size(dataOriginal,2),size(dataOriginal,3));
for i=1:size(dataOriginal,3) %for each snippet
    dataBipolar(:,:,i)=conversionMatrix*dataOriginal(:,:,i);
end
