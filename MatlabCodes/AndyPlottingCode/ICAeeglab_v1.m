%runs ICA on two datasets after combining them, saves the datasets, opens
%the scroll of the components as well as the components and starts program
%to run powerspectra on them.

%June 25 removed fpart creation, not sure why it's there since PSeeglab
%does it too.
% %prepare for batFisher
% %set fpart and save in the workspace to use by the code
% fStart=6;
% fEnd=24;
% fSpacing=1;
% disp('Prepare fpart for Fisher Discriminant');
% defaultfpart=sprintf('Start at %g, End at %g, Space by %g',fStart,fEnd,fSpacing);
% 
% %choose which fpart to use (from workspace, default, or make new)
% if exist('fpart.mat','file')==2 %if fpart.mat is in the folder
%     disp('Using frequency bins (fpart) from saved fpart.mat');
% %     load('fpart.mat');
% %     disp(fpart);   
% else
%     useDefault=input(['Use default frequency bins? (' defaultfpart ') - (Return for Yes or n): '], 's');
%     if isempty(useDefault) || strcmpi(useDefault,'y');
%         fpart(:,1)=(fStart:fSpacing:fEnd-fSpacing)';
%         fpart(:,2)=fpart(:,1)+fSpacing;
%     else 
%         fStart=input('Starting frequency:');
%         fEnd=input('Ending frequency:');
%         fSpacing=input('Spacing:');
%         fpart(:,1)=(fStart:fSpacing:fEnd-fSpacing)';
%         fpart(:,2)=fpart(:,1)+fSpacing;
%         
%     end
%     save fpart fpart
% end


% figuretitle=input('Figure Title: ','s'); This is supposed to work for
% running the Fisher test below but doesn't work
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'retrieve',[1 2] ,'study',0); 
EEG = eeg_checkset( EEG );
EEG = pop_runica(EEG, 'icatype','runica','concatcond','on','options',{'extended' 1});
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, [1 2] ,'retrieve',1,'study',0); 
EEG = pop_saveset( EEG, 'savemode','resave');
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'retrieve',2,'study',0); 
EEG = pop_saveset( EEG, 'savemode','resave');
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, [1 2] ,'retrieve',1,'study',0);
pop_eegplot( EEG, 0, 1, 1);
pop_selectcomps(EEG, [1:length(EEG.icachansind)] );
eeglab redraw
% alleeg{1}=ALLEEG(1);
% eegorica{1}='i';
PSeeglabWorkspace; %runs automatically from above two lines, savename name comes from alleeg.setname
% subplotEeglabSpectra(figuretitle,'ica'); % doesn't work
clear alleeg eegorica figuretitle