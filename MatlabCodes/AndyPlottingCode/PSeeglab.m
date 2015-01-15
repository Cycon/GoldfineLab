function PSeeglab

%to run one or multiple power spectra on eeglab .set data. Does not call
%Fisher. Can run on multiple at once. Calls runEeglab
%11/27/11 changed to uipickfiles so can choose from different folders
%11/29/11 version 2 changed call to runEeglabSpectra to reflect new opts structure
%12/20/11 version 3 calculate minimum frequency differece as minFR=2/length
%of each trial in seconds. Only disadvantage is requires opening files at
%beginning of code.
%3/6/12 version 4 modify to allow to run on subset of channels only for
%EGI 129 only
%3/24/12 version 5 modify so load one at a time so if some have different
%fields (like rejchan) it doesn't crash the code

%load data
% [setfilename, pathname] = uigetfile('*.set', 'Select EEG file(s) for spectra','MultiSelect','on');
setfilename=uipickfiles('type',{'*.set','EEGLAB .set file(s)'},'prompt','Pick .set file(s)');
alleegtest=pop_loadset('filename',setfilename{1});%load others later
numChan=size(alleegtest.data,1);
% for a=1:length(setfilename)
%     alleeg(a) = pop_loadset('filename',setfilename{a});
%     numChan(a)=size(alleeg(a).data,1);%for picking channels later
% end
%%
%pick montage type (laplacian, bipolar, or default
resopts.lap=0;
resopts.bip=0;
m=input('Montage as laplacian (l), bipolar (b - for EKDB12 and EMU40+18), [none])','s');

if isequal(m,'l')
    resopts.lap=1;
elseif isequal(m,'b')
    resopts.bip=1;
end

%choose channels to run on, now only for Cruse data for EGI 129 datasets,
%eventually set so user can have a list to pick from or enter them
%manually. Want to allow for different for each dataset in case EGI129 and
%EGI257 both in place like Cruse dataset.
resopts.subset=0;
if size(alleegtest.data,1)==129 ||  size(alleegtest.data,1)==257
        if strcmpi(input('Use Cruse et al. channels only? (y/n) [n]: ','s'),'y')
            resopts.subset=1;
        end
end



%theoretically you can get 1/data length frequency resolution but per Mitra
%and Pesaran, you use 1 fewer taper because the lowest value taper is
%poorly behaved.
minFR=2/(size(alleegtest.data,2)/alleegtest.srate);%minimum FR based on length of data to get 1 taper
resopts.FR=input(sprintf('Freq resolution (minimum is %.2f Hz): ',minFR));
if isempty(resopts.FR)
    resopts.FR=minFR;
end

if ~resopts.subset %can't use it together with averaging
    resopts.Avg=input('Average together groups of channels? (1/0) [0]: ','s');
    if isempty(resopts.Avg)
        resopts.Avg=0;
    else
        resopts.AvgNumregions=input('How many regions? (2,4,6) [4]');
        if isempty(resopts.AvgNumregions)
            resopts.AvgNumregions=4;
        end
    end
end

for numToRun=1:length(setfilename)
    alleeg = pop_loadset('filename',setfilename{numToRun});
    resopts.eegorica='e';
    if size(alleeg.data,1)==129 && sum(resopts.subset) %sum to convert to 1 number in case is the vector from before so if statement works.
        resopts.subset=[6    7   13   29   30   31   35   36   37   41   42   54   55   79 80   87   93  103  104  105  106  110  111  112  129];
    elseif size(alleeg.data,1)==257 && sum(resopts.subset)
        resopts.subset=[8    9   17   43   44   45   52   53   58   65   66   80   81  131  132  144  164  182  184  185  186  195  197  198  257];
    end
    runEeglabSpectra(alleeg,resopts);
    clear alleeg
end