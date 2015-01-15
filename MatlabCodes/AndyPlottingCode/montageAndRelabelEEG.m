function EEG=montageAndRelabelEEG(EEG,opts)

%10/2/13 based on same code in eegplotEpochChoose to make it easier to
%montage and relabel (EGI) channels. EEG is an EEGLAB structure of data.
%opts
%is a structure containing EEGmontage which can be 'laplacian', 'bipolar'
%or 'commonavg' (or anything else for no montage). opts also contains a field called relabel1020 which if ==1, relables 
%the 10-20 of EGI and removes the rest. 

%% first set defaults
if ~isfield(opts,'relabel1020')
    opts.relabel1020=0;
end

if ~isfield(opts,'EEGmontage')
    opts.EEGmontage='none';%so no montaging happens in case already performed
end

%% %montage first so that can display 10-20
        if strcmpi(opts.EEGmontage,'laplacian')
                EEG.data=MakeLaplacian(EEG.data,EEG.chanlocs);
        elseif strcmpi(opts.EEGmontage,'bipolar') %if bipolar
                [EEG.data,chanlist,EEG.chanlocs]=MakeBipolar(EEG.data,EEG.chanlocs);
                EEG.nbchan=length(EEG.chanlocs);%since fewer channels now
        elseif strcmpi(opts.EEGmontage,'commonavg') %if common average ref
                EEG = pop_reref( EEG, []);
        end
        
        %determine if EGI for later headplot
        if ~strcmpi(EEG.chanlocs(1).labels,'E1') %if not EGI
                EEG.EGI=0;%for headplotLocations
            else
                EEG.EGI=1;
        end
        
        %channels to display
        if opts.EEGchannels %10-20 subset for EGI only
            %then rename the EGI channels and only show them.
            
            %rename channels if from EGI
            if ~strcmpi(EEG.chanlocs(1).labels,'E1') %if not EGI
                errordlg('10-20 just for EGI');
            else
                etable=egi_equivtable_Andy;%columns of E65, output, E129, E33
                output=etable(:,2);
                for ee=1:length(EEG.chanlocs)
                    switch length(EEG.chanlocs)
                        case 33 %if EGI33
                            EEG.chanlocs(ee).labels=output...
                                {strcmpi(EEG.chanlocs(ee).labels,etable(:,4))};
                        case 129
                            EEG.chanlocs(ee).labels=output...
                                {strcmpi(EEG.chanlocs(ee).labels,etable(:,3))};
                        case 65
                            EEG.chanlocs(ee).labels=output...
                                {strcmpi(EEG.chanlocs(ee).labels,etable(:,1))};
                        otherwise
                            errordlg('Wrong number of EGI channels for list');
                            return
                    end
                end
                %remove non 10-20
                non1020=cellfun('isempty',{EEG.chanlocs.labels});
                EEG.chanlocs=EEG.chanlocs(~non1020);
                EEG.data=EEG.data(~non1020,:,:);
                EEG.nbchan=size(EEG.data,1);
            end
        end
    end