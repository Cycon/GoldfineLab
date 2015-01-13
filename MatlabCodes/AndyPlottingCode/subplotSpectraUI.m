function subplotSpectraUI(varargin)

%this code calls subplotSpectra but allows the user to choose the inputs from a menu box and plots all graphs
%on one figure. 
%user inputs:
%subplotSpectraUI('title','spectra1label','spectra2label','spectra3label')
%
%version 1.0 11/4/09 created
%version 1.1 11/5/09 added fullfile so can choose items to plot from
             %different folders
%version 1.2 12/15 added xstart and end options at bottom to plot only to
             %50 - later removed, but if want back just type ,0, 50 at end
             %on command on bottom.
%version 1.3 2/26 xstart and end options are gone from subplotSpectra (not
    %sure where). New option for user to pick previous output of batTGT to save
    %time in replotting in case want to plot but hide bad channels

graphcomments = input('Paste any notes for graph [Return leaves blank]: ', 's');
if isempty(graphcomments)
    graphcomments = 0;
end

%ask the user if they'd like to use previous output of batTGT (from
%previous run of subplotSpectra)

useTGT=input('Use file with previous TGToutput (y - yes or Return)?','s');
if strcmpi(useTGT,'y')
    [filename4, pathname4, filterindex4] = uigetfile('*List.mat', 'Select file with TGToutput:');
    previousResult=load(fullfile(pathname4,filename4));
    TGToutput=previousResult.TGToutput;
else
    TGToutput=[];
end

figuretitle=varargin{1,1};
spectra1label=varargin{1,2};

[filename1, pathname1, filterindex1] = uigetfile('*PS.mat', 'Select first spectra');
spectra1=load(fullfile(pathname1,filename1));

if nargin>2
    spectra2label=varargin{1,3};
    [filename2, pathname2, filterindex2] = uigetfile('*PS.mat', 'Select second spectra');
    spectra2=load(fullfile(pathname2,filename2));
else
    spectra2=0;
    spectra2label='1';
end;


if nargin>3
    spectra3label=varargin{1,4};
    [filename3, pathname3, filterindex3] = uigetfile('*PS.mat', 'Select third spectra');
    spectra3=load(fullfile(pathname3,filename3));
else
    spectra3=0;
    spectra3label='1';
end;

subset=[1:size(spectra1.S{1,1},2)];
    
numrows=ceil(sqrt(max(subset)));
numcols=floor(sqrt(max(subset)));

if numrows*numcols<max(subset)
    numcols=numcols+1;
end;
%this is to ensure that there is only 1 figure.



subplotSpectra(spectra1,spectra2,spectra3,subset,figuretitle,spectra1label, spectra2label, spectra3label, numrows, numcols, graphcomments, TGToutput);

end
