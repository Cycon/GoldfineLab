function batCrxULT_UI(varargin)

%this code is to allow for importing multiple .crx files and running them
%with mtspectrumc_unequal_length_trials
%with various montages. Has GUI to pull up list of .crx and list of montages to choose (montage folder needs to be set in program).
%Files are saved in current folder as name of crx_name of montage.

%Option in future may be to have GUI to
%say where to save them (may need change batCrxULT for this)
%
%version 1.0 11/6 created 
%version 1.1 11/9 changed crx uiget for proper naming; added uiget for
             %montage list.
%version 1.2 12/12 changes in text displayed to put warning at beginning in
             %first line
 
% fprintf('Don''t forget to modify the params in ndb to be consistent with the freq recorded\n');

[crxfiles, pathname1, filterindex1] = uigetfile('*.crx', 'Select crx files to analyze','MultiSelect','on'); %this will load the crx's to a cell array
%though they all need to be in the same path since it only produces one
%path name.

%To choose montages can type in or choose from list.
%montages={'EKDB12' 'LaplacianEKDB12'}; %this list can be manually typed in
%here can change program to allow command line or input
% persistent montageDir %define montage directory as permanent so easier to redefine on computer when moved to new computer
% if isempty(montageDir)
%     montageDir=uigetdir('','Select folder containing Montages');
% end
% [montagelist, pathname2, filterindex2] = uigetfile('*.xml', 'Select montage names from folder','MultiSelect','on',montageDir);
 [montagelist, pathname2, filterindex2] = uigetfile('*.xml', 'Select montage names from folder','MultiSelect','on','C:\Documents and Settings\Andrew Goldfine\My Documents\EEGResearch\Build112_19Oct2009\ndb\XML\Config XML\Montage\EEG\');

%if load none, it appears as a 0 so this tells the program to end
if ~iscell(crxfiles)&&~ischar(crxfiles)
    return; 
end;

%if only 1 crx or montagelist, it gets loaded as a string and need to convert to a cell for
%later
if ~iscell(crxfiles);
    crxfiles=cellstr(crxfiles);
end;

if ~iscell(montagelist);
    montagelist=cellstr(montagelist);
end;

%this removes the .xml. Has to be done as a loop since cell
for i=1:length(montagelist)
    montages{i}=montagelist{i}(1:end-4);
end;

%montages=montages{1:end}(1:end-4);


%%
% Set params for batCrxULT to use with mtspectrumc_unequal_length_trials. 
 params.tapers=[3 5];
 params.fpass=[0 0.5];
 params.pad=-1;
 params.Fs=1;
 params.err=[2 0.05];
 movingwinInSec=3;

 disp('Would you like to use default parameters for mtspectrumc_unequal_length_trials?');
 disp(params);
 fprintf('movingwin (in sec): %.0f\n',movingwinInSec);
 default = input('Return for yes (or n for no): ','s');
 if strcmp(default,'y') || isempty(default)
 else
     disp('define params (Return leaves as default)');
     p.tapers1=input('NW:');
     if ~isempty(p.tapers1)
         params.tapers(1)=p.tapers1;
     end
     p.tapers2=input('K:');
     if ~isempty(p.tapers2)
        params.tapers(2)=p.tapers2;
     end
     p.pad=input('pad (mtspecULT ignores if -1 or 0 though mtspectrumc for batFisher uses it):');
     if ~isempty(p.pad)
         params.pad=p.pad;
     end
     p.err1=input('error type (1 theoretical, 2 jacknife):');
     if ~isempty(p.err1)
         params.err(1)=p.err1;
     end
     p.err2=input('p-value:');
     if ~isempty(p.err2)
         params.err(2)=p.err2;
     end
     p.mwinsec=input('moving win (in seconds):');
     if ~isempty(p.mwinsec)
         movingwinInSec=p.mwinsec;
     end
     fprintf('\nparams are now:\n');
     disp(params);
     fprintf('movingwin (in sec): %.0f\n',movingwinInSec);
 end
 
%%

for i=1:length(crxfiles)
    for j=1:length(montages)
        
        savefilename=sprintf('%s_%s_PS',crxfiles{i}(1:end-4),montages{j});
  
batCrxULT([pathname1 crxfiles{i}],montages{j}, savefilename, params, movingwinInSec);
fprintf('%s created\n',savefilename);

    end
end;
