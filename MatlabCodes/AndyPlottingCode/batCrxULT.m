function  batCrxULT(varargin)

%type batCrxULT('file.crx','montagename','SaveNameForTheOutput',params,movingWinInSec)
%will run mtspectrumc_unequal_length_trials on the file with the chosen montagename and save the
%output as a .mat file in the current folder.
%
%[]Add in code to call another code to load the data
%
%This program is called from batCrxULT_UI giving it GUIs to pick the crx
%and montage(s).
%
%This program originally created by Ravi so much of his code that isn't
%relevant still there. 
%
%version 1 11/6 created
%version 1.1 11/9 added frequencyRecorded and channellist to output
%version 1.2 11/16 added output to say the params used in the analysis on
            %the screen
%version 1.3 1/22 adding call to batCrxSpectra to cut the data and run
            %spectra on each cut for use by two group test and fisher
            %discriminant
%version 1.4 2/8/10 adds neighborTags output from batCrxSpectra
%version 1.5 2/8/10 change datapoints to new variable name after extracting
            %it and sends it to batCrxSpectra so batCrxSpectra doesn't need
            %to pull in Crx file
%version 1.6 2/9/10 adds look in current directory to see if save name
             %exists, if it does, then adds current date and time to end of filename.
%version 1.7 2/18/10 now runs mtspectrumc_ULT on data directly
             %(not via browser) and defines params at beginning
            
             
             
%%
%set default params (if not sent over from batCrxULT_UI)
if nargin>3
    params=varargin{4};
    movingwinInSec=varargin{5};
else
    params.tapers=[3 5];
    params.fpass=[0 0.5];
     params.pad=-1;
     params.Fs=1;
     params.err=[2 0.05];
     movingwinInSec=3;
end
     
%%
%Read in chronux data (AG 2/18/10 - determines how many snippets)
         if (nargin < 1)
             fprintf('please supply a .crx file/n');
             return
         else 
             sPath              = varargin{1};
         end     
         [hdr oRetVal]          = ReadChronuxFormatCrxData('Read_header',sPath, 1); % in v 112, the 0 indicates that the UI shdn't be shown (?)
         %AG - the 0 makes it fail in browser 115 and is used to tell which
         %snippet to load. Does the job of determining how many snippets
         %when set o 1.
         if ~oRetVal 
            s = sprintf('Error in getting crx header for %s.', sPath);             
            display (s);
         end
         
%%
%Read in snippets and apply montage
         snipCount              = 1;
         
         for snipCount = 1:hdr.Specific.Info.Count %AG - this is a loop so reads all snippets
             [data oRetVal]     = ReadChronuxFormatCrxData('Read_Data', hdr, snipCount);
             hdr                = data.aux;   
             %ncon('get','mont','GETGROUPDETAILSFORSELECTEDMONTAGESCHEMA',selMontageType, selMontageSchema, Hdr);
            
             if nargin>1
                 montage.Type=varargin{2};
             else
             montage.Type = 'EMU40Transverse'; %AG - here can define montage type if not sent in by batCrxULT_UI or in command
             end;
             
             montage.Schema = montage.Type; %some of the default montages have schema. Not any that we created
             
             [oMontageGroupData oRetVal] = ncon('get','mont','GETGROUPDETAILSFORSELECTEDMONTAGESCHEMA',montage.Type, montage.Schema, hdr);
             % Get the channel combos   
             [oData oRetVal] = ncon('get','mont','GETCHNLCOMBOFROMGROUPDETAILS',oMontageGroupData.MontageGroupDetails, hdr);
             tm              = []; %AG - time samples, [] means take all samples like in browser
             tr              = 1; %AG - number of trials, always 1 for xltek like in browser
            
             %AG - here you choose the channels from the montage you want
             %to run on. 
             ch = oData.ChnlComboList.Label; %AG added this line to run on all channels, though could choose subset for coherence
             if length(ch)<3
                 if ~strcmp(input('Crx file has <3 channels, would you like to continue? (y-yes)','s'),'y')
                     return
                 end
             end
             
             %ch{1}           = 'Fp1-F3';
             %ch{2}           = 'F3-C3';
             [dat retval] = ncon('load', 'dat', hdr, tm, tr, ch, montage);   %AG - this reads the data from the crx based on the montage           
                %[dat oRetVal]          = ReadChronuxFormatCrxData('Read_Data', hdr, tm, tr, ch, montage); % the 1 indicates the snippet number. 
             if ~oRetVal 
                s = sprintf('Error in loading crx snippet(%d)data.', snipCount);             
                display (s);
             end
             % Select a particular montage.
             %[oMontageGroupData oRetVal] =
             
          
%%
%Create sMarkers
             %AG - here I create the sMarkers list from the data. Created
             %as a cell and then transposed and converted later
             if snipCount==1
             sMarkers {snipCount} = [1 size(dat.modData{1,1},1)]; %AG - this creates the first row
             else
                 sMarkers{snipCount} = [sMarkers{snipCount-1}(2)+1 sMarkers{snipCount-1}(2)+size(dat.modData{1,1},1)]; %AG - this creates the rest
             end
             
             datapoints{snipCount}=[dat.modData{1,1}]; %AG - datapoints are the data used for the analysis.     
            
         end 
         
         
%%
         %AG - now run the analysis out of the loop on all the data. Make
         %sure it's all in a series of rows and not columns.
         
            % This indicates the routine name. AG - defaults come from the
             % browser
             %rName                  = 'mtspecgramc'; %AG - this routine runs a spectrogram for each channel for each snippet
             %rName                  = 'mtspectrumc_unequal_length_trials'; %AG added this to choose this routine
             % To do pre processing call the Preprocess routine and extract the
             % preprocessed data as follows. 
             
           %[oRoutineDetails oRetVal] = ncon('xfrm', 'INVOKEROUTINE', 'tsPreProcess', data, hdr.Common.Fs);
            % Extract the data to send to the routine from the preprocessed
            % output.
            %data = oRoutineDetails.Output.Params(1,1).DataValue;
            
            %AG - this below actually runs the routine on the .crx, montage
            %and data chosen above
             %[oRoutineDetails oRetVal]...
             %                       = ncon('xfrm', 'INVOKEROUTINE', rName, data);    %xfrm means transform
                          
 sMarkers=sMarkers';
 sMarkers=cell2mat(sMarkers);

 datapointsMatrix=cell2mat(datapoints'); %this converts data to one big matrix, stacked with channels in columns
             
 sMarkers={sMarkers}; %AG - these two lines are because ncon expects cell (based on original code and testing)
 datapointsMatrix={datapointsMatrix};
             
             
%%
% %Run the routine via browser with browser params
%           [oRoutineDetails oRetVal]...
%                                     = ncon('xfrm', 'INVOKEROUTINE', 'mtspectrumc_unequal_length_trials', datapointsMatrix, sMarkers);    %AG - xfrm means transform and I added this line with sMarkers for ULT
%          
                                
%%
 %Run the routine manually with params set above
frequencyRecorded=dat.aux.Common.Fs; %define frequency recorded from data
mw=[frequencyRecorded*movingwinInSec frequencyRecorded*movingwinInSec]; 
disp('Running mtspectrumc_unequal_length_trials (averageSpectra)');                                
[ Sm, fm, Serrm ]= mtspectrumc_unequal_length_trials( datapointsMatrix{1}, mw, params, sMarkers{1} )  ;                              

                       
              
%%
%Run batCrxSpectra to create cut data (cutLength defined as 3 seconds in
%batCrxSpectra) and spectra for each cut.

[spectraByChannel,fMtSpectrumc,dataCutByChannel,neighborTag]=batCrxSpectra(varargin{1},varargin{2},0,params,movingwinInSec); %older version little slower, requires
%batCrxSpectra to open the file on it's own

%    [spectraByChannel,dataCutByChannel,neighborTag]=batCrxSpectra(varargin{1},varargin{2},0,datapoints,dat.aux.Common.Fs); %last var is frequencyRecorded
%%
%Save Results
              %these are all defined to be the same as the browser exports
              %so subplotSpectra can read them in directly
             
%  params=oRoutineDetails.Input.Params(1,3).DataValue; %AG - this is a structure
movingwin=mw; %AG - this is a 2 element vector
data=[]; %AG - this is because data is defined above and needs to be reset 
data{1,1}=datapointsMatrix;
sMarkers=sMarkers{1}; %AG this is a number matrix
channellabels=ch; %AG - this is direcly used in subplotSpectra
channellist=varargin{2}; %AG - in subplotSpectra this can be used
S{1,1}=10*log10(Sm);%this and below defined as cell and converted to dB since that's what subplotSpectra expects.
f{1,1}=fm;
Serr{1,1}=10*log10(Serrm);
% S{1,1}=oRoutineDetails.Output.Params(1,1).DataValue{1,1};
% f{1,1}=oRoutineDetails.Output.Params(1,2).DataValue{1,1};
% Serr{1,1}=oRoutineDetails.Output.Params(1,3).DataValue{1,1};  
             
 fprintf('spectra created with %d tapers and %d sec movingwin from %g to %g Hz\n',params.tapers(2),movingwin(1)/frequencyRecorded,frequencyRecorded*params.fpass(1),frequencyRecorded*params.fpass(2));
 savename=varargin{3};
 if exist([savename '.mat'],'file') ==2; %check to see if file exists of that savename
     savename=sprintf('%s_%s',savename, datestr(now, 'dd_mm_yyyy_HH_MM'));
 end
 save(savename,'params','movingwin','data','sMarkers','channellabels','S','f','fMtSpectrumc','Serr','channellist','frequencyRecorded','spectraByChannel','dataCutByChannel','neighborTag')
