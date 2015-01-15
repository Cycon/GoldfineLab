function batFisher(varargin)

%this code will need:
%type code
%title of first figure
%mat files for first analysis
%keep going till press done
%then run all in a loop.
%need to use default params only in subplotFisher so need to change
%subplotFisher to take in a code to run default params. 
%
%may want to change subplotFisher to automatically save the figures later
%%
%set fpart and save in the workspace to use by the code
fStart=6;
fEnd=24;
fSpacing=2;
defaultfpart=sprintf('Start at %g, End at %g, Space by %g',fStart,fEnd,fSpacing);

%choose which fpart to use (from workspace, default, or make new)
if exist('fpart.mat','file')==2 %if fpart.mat is in the folder
    disp('Using frequency bins (fpart) from saved fpart.mat');
    load('fpart.mat');
    disp(fpart);   
else
    useDefault=input(['Use default frequency bins? (' defaultfpart ') - (Return for Yes or n): '], 's');
    if isempty(useDefault) || strcmpi(useDefault,'y');
        fpart(:,1)=(fStart:fSpacing:fEnd-fSpacing)';
        fpart(:,2)=fpart(:,1)+fSpacing;
    else 
        fStart=input('Starting frequency:');
        fEnd=input('Ending frequency:');
        fSpacing=input('Spacing:');
        fpart(:,1)=(fStart:fSpacing:fEnd-fSpacing)';
        fpart(:,2)=fpart(:,1)+fSpacing;
        
    end
    save fpart fpart
end

%%
%here user inputs the title of each figure and chooses the mat files to use
%in the analysis. need to figure out how to do it a variable number of
%times (while loop?). Need to make sure to send full pathname to
%subplotFisher since doesn't look for it otherwise outsiede the folder.

if isempty(input('Use default naming (from 1st file)? (Return - yes, or n): ','s'))
    defaultname=1;
else
    defaultname=0;
end

i=1;
% more=1;
while more
    if ~defaultname
        inputScript=sprintf('Enter Figuretitle %.0f (Return to stop): ',i);
        figuretitle{i}=input(inputScript,'s');
        if isempty(figuretitle{i})
         i=i-1;
         break;
        end
    end
%     if isempty(figuretitle{i})
%         i=i-1;
%         break;
%     else
    [filename1{i}, pathname1{i}] = uigetfile('*PS.mat', 'Select first condition or cancel to stop');
    
    if filename1{i}==0 %to end
        i=i-1;
        break %out of the while loop to finish it
    else
%         if ~exist([pathname1{i} '/FisherBy1AndOriginal'],'dir') %if I forgot to move the old Fisher files over
%             disp('need to move Fisher results first, FisherBy1AndOriginal doesn''t exist (remember to remove this line)') %remove this line once done 7/2/10! 
%             i=i-1;
%         else
            [filename2{i}, pathname2{i}] = uigetfile('*PS.mat', 'Select second condition',pathname1{i});
            if defaultname
                figuretitle{i}=filename1{i}(1:end-7); %automatically set figure title from 1st input (assumes second input is control condition)
            end
            disp(['Fisher ' num2str(i) ' is ' filename1{i} ' vs ' filename2{i} '.']);
            i=i+1;
%         end
    end
%     condition{2}=load(fullfile(pathname2,filename2));
%     scenario_name=[filename1(1:end-4) ' vs ' filename2(1:end-4)];
%     moreComparisons=input('Would you like to add another comparision? (y
%     or Return = yes):','s');
end

%%
%here call subplotFisher for each one above
for j=1:i
    subplotFisher(figuretitle{j},filename1{j},pathname1{j},filename2{j},pathname2{j})
    close(gcf); %since I never look at these figures anyhow 6/8/10
end

