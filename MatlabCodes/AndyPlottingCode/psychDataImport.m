function psychDataImport

%8/26/14 to import EGI data exported as .mat from the Cornell Psych
clear

%Set defaults
samplingRate=500;%accurate for Dora's EGI data as of 5/29/14

%% choose file
egiAllfiles=uipickfiles('type',{'*.mat' '.mat'},'prompt','Select EGI file as .mat');
if isnumeric(egiAllfiles) || isempty(egiAllfiles) %if user presses cancel and it is set to 0
    return
end



for e=1:length(egiAllfiles)
    egiFile=egiAllfiles{e};
    
    [~,filename,~]=fileparts(egiFile);
%replace spaces with underscores since then matches with the underlying
%variable
filename=strrep(filename,' ','_');
filename=strrep(filename,'#','num');

    matdata=load(egiFile);%creates a structure containing everything from the egi output
    %and fixes the bad variable names by replacing for example # with an _
    
    %this contains the data which is the same name as the file though with spaces replaced by _ and is
    %channel x time and then a variable called Impedances_0 (a
    %cell); 
    
    %the load process replaces spaces in the fieldname with underscore
    matfields=fieldnames(matdata);
    
    eegData=matdata.(matfields{~strcmp(matfields,'Impedances_0')});%pick the non-impedance one
    
    
    
    %need to create all the eeglab structure information manually next:
    
        chanlocs=readlocs('GSN-HydroCel-129.sfp');
        chanlocs=chanlocs(4:end);%first three aren't real

    
    % create the EEG file with no events
    eeg = pop_importdata('dataformat','array','data',eegData,...
        'setname',matfields{~strcmp(matfields,'Impedances_0')},'srate',samplingRate,...
        'subject','1','nbchan',size(eegData,1),'chanlocs',chanlocs);
    
   



%% run 60 Hz line noise removal copied from xltekToEeglab
% if strcmpi(input('Remove 60Hz noise? (y/n) [n]','s'),'y')
%     if ndims(eeg.data)==3 %if exported from EGI as epochs
%         disp('This is only for continuous data, could be changed');
%         return
%     end
%     filename=[filename '_60'];%to show that it was performed
%     params.fpass=[55 65];
%     params.pad=4;
%     params.tapers=[1 10 1];%since will go in 10 sec chunks
%     cL=params.tapers(2)*eeg.srate;%cut length for noise removal
%     params.Fs=eeg.srate;
%     
%     fprintf('%.2f seconds of data cut off of end.\n',...
%         mod(size(eeg.data,2),cL)/eeg.srate);
%     %then cut off the end of the data
%     eeg.data=eeg.data(:,1:end-mod(size(eeg.data,2),cL));
%     
%     
%     denoised=zeros(size(eeg.data));%initialize
%     %denoised is now data x channel (transposed from EEG)
%     for jk=1:size(eeg.data,2)/cL %number of epochs length of tapers(2)
%         denoised(:,(jk-1)*cL+1:jk*cL)=rmlinesc(eeg.data...
%             (:,(jk-1)*cL+1:jk*cL)',params,0.2,'n')';%transpose for rmlinesc
%         
%     end
%     eeg.data=denoised;
%     %clean up the data structure since cut off end
%     eeg.pnts=size(eeg.data,2);
%     eeg.times=eeg.times(1:size(eeg.data,2));%times is in ms
%     
%     %remove events that were in the part cutoff. Latency is in samples
%     eeg.event=eeg.event([eeg.event.latency]<=size(eeg.data,2));
% end

%%
%save the data
eeg=pop_saveset(eeg,'filename',filename,'filepath',pwd);

% %% nested code to get events out of xml file
%     function desc=eventsFromxml
%         xmlFile=uipickfiles('type',{'*.xml','EGI Event Marks xml file'},'prompt','Select EGI event Marks xml file','output','char','num',1);
%         if isnumeric(xmlFile) || isempty(xmlFile) %if user presses cancel and it is set to 0
%             %if cancel then don't do this code
%         else
%             eventStruct=parseXML(xmlFile);%bring in the xml file as a structure
%             event=eventStruct.Children;
%             a=1;
%             for i=1:length(event) %some contain nothing and starting at 6 they contain the events
%                 if ~isempty(event(i).Children) %if some info in it
%                     if isfield(event(i),'Children') && length(event(i).Children)>1
%                         if ~isempty(event(i).Children(10)) &&...
%                                 ~isempty(event(i).Children(10).Children)
%                             %this is for when the event description is typed in
%                             desc{a}=event(i).Children(10).Children.Data;
%                         else
%                             %this is the label from clicking an option
%                             desc{a}=event(i).Children(6).Children.Data;
%                         end
%                         a=a+1;
%                     end
%                 end
%             end
%         end
%     end
% 
% %at one point this used to run on .raw and if want to do again note
% %below:
% %         if strcmp(ext,'.raw') %if .raw data then events already in EGI dataset
% %             if length(desc)~=length(eeg.event)
% %                 disp('Different number of events in xml than eeg, please fix code');
% %             return
% %             end
% %
% %             for e=1:length(eeg.event)
% %                 eeg.event(e).type=desc{e};
% %             end
% %         else %if .mat data

end%end code

