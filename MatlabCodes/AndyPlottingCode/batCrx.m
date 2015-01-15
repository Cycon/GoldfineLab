function [oRoutineDetails oRetVal]= batcrx(varargin)
try
         if (nargin < 1)
             sPath              = 'C:\Ravi\Chronux\ChronuxPackage\Andy\Test.crx';
         else 
             sPath              = varargin{1};
         end     
         [hdr oRetVal]          = ReadChronuxFormatCrxData('Read_header',sPath, 0); % the 0 indicates that the UI shdn't be shown.
         if ~oRetVal 
            s = sprintf('Error in getting crx header for %s.', sPath);             
            display (s);
         end
         snipCount              = 1;
         for snipCount = 1:hdr.Specific.Info.Count %AG - this is a loop so reads all snippets
             [data oRetVal]     = ReadChronuxFormatCrxData('Read_Data', hdr, snipCount);
             hdr                = data.aux;   
             %ncon('get','mont','GETGROUPDETAILSFORSELECTEDMONTAGESCHEMA',selMontageType, selMontageSchema, Hdr);
             montage.Type       = 'Longitudinal Bipolar'; %AG - should replace this with varagin{2}
             montage.Schema     = 'Longitudinal Bipolar 16'; %AG - if no schema then montage.Schema=montage.Type (??)
             [oMontageGroupData oRetVal] = ncon('get','mont','GETGROUPDETAILSFORSELECTEDMONTAGESCHEMA',montage.Type, montage.Schema, hdr);
             % Get the channel combos   
             [oData oRetVal] = ncon('get','mont','GETCHNLCOMBOFROMGROUPDETAILS',oMontageGroupData.MontageGroupDetails, hdr);
             tm              = []; %AG - time samples, [] means take all samples like in browser
             tr              = 1; %AG - number of trials, always 1 for xltek like in browser
            
             %AG - here you choose the channels from the montage you want to run on. If you
             %want all ch{1:numChannels} or i=1:length(x) ch{i) = 'your
             %montage list' from oData.ChnlComboList.Label
            
             ch = oData.ChnlComboList.Label; %AG added this line
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
             
             % This indicates the routine name. AG - defaults come from the
             % browser
             rName                  = 'mtspecgramc'; %AG - this routine runs a spectrogram for each channel for each snippet
             %rName                  = 'mtspectrumc_unequal_length_trials'; %AG added this to choose this routine
             % To do pre processing call the Preprocess routine and extract the
             % preprocessed data as follows.
             data                   = dat.modData;
            % sMarkers (snipCount,1}              = dat.
             %[oRoutineDetails oRetVal] = ncon('xfrm', 'INVOKEROUTINE', 'tsPreProcess', data, hdr.Common.Fs);
            % Extract the data to send to the routine from the preprocessed
            % output.
            %data = oRoutineDetails.Output.Params(1,1).DataValue;
            
            %AG - this below actually runs the routine on the .crx, montage
            %and data chosen above
             %[oRoutineDetails oRetVal]...
             %                       = ncon('xfrm', 'INVOKEROUTINE', rName, data);    %xfrm means transform
                                
             [oRoutineDetails oRetVal]...
                                    = ncon('xfrm', 'INVOKEROUTINE', rName, data);    %AG - xfrm means transform and I added this line with sMarkers for ULT
                                % but not sure where sMarkers comes from
                                
             if ~oRetVal 
                s = sprintf('Error in performing routine%s.', rName);
                display (s);
             end
             [oStatus oRetVal]      = ncon('VIS', 'TIMESERIES','ProcData', rName, oRoutineDetails.Output, oData.ChnlComboList.Label,...
                                                             hdr.Common.Fs);         
             
         end 
         
catch
    err     = lasterror;
    oRetVal = 0;
end