function [results,ou]=subplotFisher(figureTitle,condition1matfile,condition2matfile)

%Calls fisherdisc to run on invidual spectra as created by batCrxSpectra 
%which is called by batCrxULT / batCrxULT_UI).
%type batFisher('figureTitle','condition1.mat','condition2.mat')
%or just batFisher('figureTitle') then pull conditions from GUI
%Each condition file must contain variable of spectraByChannel
%
%requires fisherdisc, fisherdisc_def, filldefault, findsegflips,
%fisherdisc_do, getinp, gnormcor, jacksa, nicesubp, setfields (all JVs codes)


%   1. New code to run the comparison modeled after fisherdisc_demo. Start with loading the data (give two options either type at command line which helps so can run again and again with different options (fpath, use of segs or not) or if nothing typed than UI pops up. 
%  2. Consider one code for running the disc and a second to plot it. That way can at least have values for how good the disc is from the first code and later can figure out how to plot it.
%     1. Put the data from each file together
%     2. create features (binning) - and options to change it
%     3. data needs to be ordered as number of samples per column and features per row (not individual frequencies!)
%     4. create tags with 1s and 2s for each set
%     5. set defaults 
%       1. sends only segs and delrad
%       2. other options just defined in the code or from user interface (such as using segs or not with nshuffle)
%       3. (look at fisher_disc demo and option file
%   3. Output coding / plotting
%     1. Want list of channel names with how good the baysian classifier is (with and without opts.segs) as well as the p-value for the variance
%     2. Plot of the classifier and consider plotting subtraction (or spectra?)

%version 1 2/9/10 Created
% 3/19 name changed to subplotFisher

%%
%set defaults for fisherdisc to use
%these are the defaults set by fisherdisc_demo
tic
if nargin == 0
    fprintf('(next time type batFisher(''FigureTitle''))\n');
    figureTitle=input('Figure title:','s');
end
    
if ~exist('opts') %not sure that I should have this as an if or just reset each time ?
    opts=[];
    opts.nshuffle=-1; %could try Inf, 100, -1 appropriate # of shuffles for unrestricted shuffle only while nflips
    %determines number of restricted shuffles
    opts.xvalid=1; %could try 0
    opts.nshuffle_max=200; %could try 10000;
    opts.sub1=1;
    opts.classifiers={'halfway','mapequal','mapbayes'}; %will only use mapbayes since does the best job
    opts=filldefault(opts,'nflips',200); %should increase to 1000 but takes to long since with 200 get cases of p-value = 0 (though get with 10000 too!)
end

%these are the defaults set by fisherdisc_def, change them above if want
%different values (need to determine if changing these works by looking at output)
% opts=filldefault(opts,'nshuffle',0);
% opts=filldefault(opts,'nshuffle_max',200);
% opts=filldefault(opts,'xvalid',0);
% opts=filldefault(opts,'sub1',0);
% opts=filldefault(opts,'classifiers',[]);
% opts=filldefault(opts,'condmax',Inf);
% opts=filldefault(opts,'segs',[]); %This is the list of neighboring cuts
% opts=filldefault(opts,'delrad',Inf); %tells it how many neighbors to flip
% together, Inf uses all which is the case unless long list of neighbors
% opts=filldefault(opts,'nflips',200); %how many flips to do
% opts=filldefault(opts,'nflips_maxtries',10000);
% opts=filldefault(opts,'nflips_tol',1); %tolerate # of asymmetric flips (if more in one group than the other)

%%
% Allow user to pass in 2 mat files from command line, if not then pull up UI 
% Load in the mat files
if nargin < 2
    [filename1, pathname1, filterindex1] = uigetfile('*PS.mat', 'Select first condition');
    condition{1}=load(fullfile(pathname1,filename1));
    [filename2, pathname2, filterindex2] = uigetfile('*PS.mat', 'Select second condition');
    condition{2}=load(fullfile(pathname2,filename2));
    scenario_name=[filename1(1:end-4) ' vs ' filename2(1:end-4)];
else 
    condition{1}=load(condition1matfile);
    condition{2}=load(condition2matfile);
    scenario_name=[condition1matfile(1:end-4) '_vs_' condition2matfile(1:end-4)];
end

%%
%ensure both conditions use the same montage, otherwise exit program
if ~(strcmp(condition{1}.channellist,condition{2}.channellist));
        fprintf('Montages are not the same in the conditions, they are %s and %s\n',condition{1}.channellist,condition{2}.channellist);
        return
end

numChannels = size(condition{1}.spectraByChannel,2);
if strcmp(condition{1}.channellist,'LaplacianEKDB12') %to create a list of names for easier plotting later
                  channellabels={'Fp1','Fp2','AF7','AF8','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CP2','CP6','T5','P3','Pz','P4','T6','O1','O2'};
elseif strcmp(condition{1}.channellist,'LaplacianEMU40')
                  channellabels={'FPz','Fp1','Fp2','AF7','AF8','F7','F3','F1','Fz','F2','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CPz','CP2','CP6','T5','P3','Pz','P4','T6','PO7','O1','POz','Oz','O2','PO8'};
else
    channellabels=condition{1}.channellabels;
end;


%%
%default freq ranges for features
fStart=4;
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
    savefpartInWorkspace=input('Save partitions as ''fpart'' for next time? (y - yes or n)','s');
        if savefpartInWorkspace=='y'
            save fpart fpart %want it saved to folder for use next time
        end
    end
end


%%
%define some defaults (modified from fisherdisc_demo)
freq_datasampling=condition{1}.frequencyRecorded;
if isfield(condition{1},'fMtSpectrumc')
    freqs=condition{1}.fMtSpectrumc*freq_datasampling; %since f from mtspectrumc is different than from ULT (has padding)
else
     freqs=linspace(0,0.5,size(condition{1}.spectraByChannel{1},1))*freq_datasampling; %for data withoutfMtSpectrumc
end
freq_spectralsampling=freqs(2)-freqs(1); %This is a way to determine the spacing btween the frequency values on the abscissa.
mt_params=condition{1}.params;

%%
%assign the spectraByChannel to the variable spectra which is a cell array
%of channels by condition
for is=1:numChannels %for each channel
    for ig=1:2 %conditions
%         file_name=cat(2,datapath,subj_name,class_name{ig},'Spectrum',scenario_name{is},'.mat');
%         field_name=cat(2,'spectra',scenario_name{is},lower(class_name{ig}));
%         disp(sprintf('attempting to load %s from %s',field_name,file_name));
%         d{is,ig}=load(file_name);
        spectra{is,ig}=condition{ig}.spectraByChannel{is};
    end
end

%%
% Asssign the field corresponding to spectra by Channel to variables. 
%I have condition{1}.spectraByChannel - 37 channels (each is a cell) each containing a matrix of 
%data x cuts. For this code want to run fisherdisc on each channel
%separately but need to convert the matrix to be features x cuts. So flow
%should be 1. for each channel (loop) 2. convert condition 1 and condition
%2 to features 3. Run fisherdisc 4. Save output to a cell array (or
%structure) and associate it with the names of the channels from
%channellabels

for is=1:numChannels %for each channel
    scenarios{is}.name=cat(2,channellabels{is},': ',scenario_name);
    scenarios{is}.sigsize=1; %just for compatibility with fisherdisc_test
    ifeat=0; %each feature is mean power in a non-empty partition of frequencies
    scenarios{is}.data=[];
    for ipart=1:size(fpart,1) %ipart is an index for number of features
        fbins=intersect(find(freqs>=fpart(ipart,1)),find(freqs<fpart(ipart,2)));
        %fbins serves as an index to say where in spectra to take data from
        if length(fbins)>0
            ifeat=ifeat+1;
            for ig=1:2 %for each condtion
                scenarios{is}.data{ig}(ifeat,:)=mean(spectra{is,ig}(fbins,:),1);
                %for each scenario create a row in "data" at a time
                %representing the mean of the rows (across all columns) of "spectra" within each
                %frequency range
            end
        end %length(fbins)
    end %ipart
    for ig=1:2 %for each condition write how many samples
        scenarios{is}.nsamps(1,ig)=size(scenarios{is}.data{ig},2);
    end
    scenarios{is}.nfeat=ipart; %how many features
    %difference of means, not necessariliy the discriminant
    dmean=mean(scenarios{is}.data{1},2)-mean(scenarios{is}.data{2},2); %mean by columns, changed to 1-2
    dmean=dmean./sqrt(sum(dmean.^2)); %why?
    scenarios{is}.signal=dmean; %to save the mean difference within the sceanrio (channel)
    nsamps=sum(scenarios{is}.nsamps); %total number of samples
    %set up the segments for each channel (but problem is its not designed
    %for by condition in fisherdisc. Segs are defined by neighborTags
    %field. Below 4 lines won't use
%     scenarios{is}.segs=cell(0);
%     for iseg=1:ceil(nsamps/segsize);
%         scenarios{is}.segs{iseg}=[1+segsize*(iseg-1):min(segsize*iseg,nsamps)];
%     end
end

% %next 5 lines allow you to choose which channel to run
% for is=1:length(scenarios) %for each channel
%     disp(sprintf('%3.0f->%32s, nfeatures=%2.0f nsamps=[%4.0f %4.0f]',...
%         is,scenarios{is}.name,scenarios{is}.nfeat,scenarios{is}.nsamps));
% end
% islist=getinp('choice','d',[1 length(scenarios)],[1:length(scenarios)]);
results=cell(0);
ou=cell(0);
%
% run each requested scenario (plot all of them at the end later)
% %
% for isp=1:length(islist)
%     is=islist(isp);
%     
%create opts.segs which is a concatenated list from each condition
for i=1:length(condition{1,2}.neighborTag)
    condition2NeighborTagsAdjusted{i}=condition{1,2}.neighborTag{i}+max(condition{1,1}.neighborTag{end});
end
segs=[condition{1,1}.neighborTag condition2NeighborTagsAdjusted];

for is=1:numChannels
    sc=scenarios{is};
    tags=[repmat(2,[1 sc.nsamps(1)]),repmat(1,[1 sc.nsamps(2)])]; %create list of 1s and 2s for each sample
    %the 1 and 2 are switched from original version since I want condition
    %1 minus condition 2 (rather than having condition 1 as the "baseline"
    %and seeing how 2 is more than it like in fisherdisc_demo).
    %
    % do the Fisher analysis
    %
    [results{is},ou{is}]=fisherdisc([sc.data{1},sc.data{2}],tags,setfields(opts,{'segs'},{segs})); %set no segs or delrad since delrad use default
    %and can't yet do separate segs for each condition
    
    %     [results{isp},ou{isp}]=fisherdisc([sc.data{1},sc.data{2}],tags,...
%         setfields(opts,{'segs','delrad'},{sc.segs,delrad}));
end

%%
%next plot the results
%in Jon's version it plots as part of loop above but might be better to run
%Fisher Disc on all the channels in the loop and below plot everything.
%
%Framework of loop from SubplotTGT or SubplotSpectra
%Plotting of discriminant and dmean
%Annotation box with feature description, number of features and number of
%samples used for each group.
%Calculation of xvalid and segflip prediction
%Calculation of p-value vs segflipped data variance explained
%place both those in the titles
%%
    % Plot the spectra (below based on subplotTGT_UI)
    %
%%
%define figure and annotation box
numrows=ceil(sqrt(numChannels));
numcols=floor(sqrt(numChannels));

scrsz = get(0,'ScreenSize'); %for defining the figure size
figure; 

%     if isempty(varargin) %if no title used then create one
%         varargin{1}=[filename1(1:end-4) ' vs ' filename2(1:end-4) ' TGT']
%     end
set(gcf,'Name',figureTitle, 'Position',[1 1 scrsz(3)*0.8 scrsz(4)*0.9]);

%annotation of feature definition, # of features, # of samples in each
%group, params used
titletext=sprintf('Channel Label \n Xvalid by Seg, XV UR, p-value');
annotation(figure(gcf),'textbox','String',titletext,'Position',[0.00725 0.931 0.1948 0.05459],'FontSize',10,...
    'HorizontalAlignment','center','LineStyle','none');
annotationtext=sprintf('mtspec params:\ntapers: %.0f %.0f\npad: %.0f\n\nFrequency bins:\nStart at:%.0f\nEnd at:%.0f\nUnits of:%.0f\n Number of Bins:%.0f\n\nNumber of Samples:\nCondition 1: %.0f\nCondition 2: %.0f',...
    mt_params.tapers,mt_params.pad,fStart,fEnd,fSpacing, size(fpart,1),size(condition{1}.spectraByChannel{1},2),size(condition{2}.spectraByChannel{1},2));

annotation(figure(gcf),'textbox','String',annotationtext,'FitBoxToText','on','Position',[0.00725 0.5 0.07671 0.35],'FontSize',9);

% annotation(figure(gcf),'textbox','String',{['Title:' ' ' 'Channel,' '  ' 'XV by Seg,' ' XV UR, p-value' '  ' '   ' 'mtspec params:' '  ' 'tapers=' num2str(mt_params.tapers)] ['pad='...
% num2str(mt_params.pad)] ' ' 'Frequency bins:' ['Start at:' num2str(fStart)] ['End at:' num2str(fEnd)]...
% ['Units of:' num2str(fSpacing)] ['Number of Bins:' num2str(size(fpart,1))] ' ' 'Number of samples' 'condition 1:'...
% num2str(size(condition{1}.spectraByChannel{1},2)) 'condition 2:' num2str(size(condition{2}.spectraByChannel{1},2))}...
% ,'FitBoxToText','off','Position',[0.00725 0.327 0.07671 0.65],'FontUnits','normalized'); %this uses normalized units.
%x,y,width,height
%     'Position',[0.00725 0.327 0.08025 0.649])
%%
%Calculate significance values to use in titles
%Cross validation - takes the confusion matrix, adds true pos + true neg (1,1 and 2,2) and
%divides by the total number of samples. sg uses version with segments
%(doesn't use itself or its neighbor(s) to calcualate FisherDisc). xv is
%unrestricted x-validation. Using baysian classifier which knows how many
%are in each class (unlike halfway and mapequal which are also run).

%p_segflip p-value calculation: sees how many segflips have (class 
%variance / total variance) < (class variance / total variance of fisher). 
%Then total number divided by # of shuffles to get a p-value.
for ipc=1:length(results)
    percentCorrectMapbayesSegs{ipc}=sum(diag(results{ipc}.sg_mapbayes_cmatrix))/sum(sc.nsamps)*100;
    percentCorrectMapbayesUnrestricted{ipc}=sum(diag(results{ipc}.xv_mapbayes_cmatrix))/sum(sc.nsamps)*100;
    p_segflip{ipc}=sum(results{ipc}.segflip.ss_class./results{ipc}.segflip.ss_total<results{ipc}.ss_class/...
    results{ipc}.ss_total)/length(results{ipc}.segflip.ss_class);
end;


%%
%plot
    for j=(1:numChannels);
        subplot(numrows,numcols,j);
%         set(gca,'xtick',[0:5:frequencyRecorded/2+5]); %this sets the
%         xticks every 5
%         axis([0 frequencyRecorded/2+5 floor(min(TGToutput.dz{j}))-1 ceil(max(TGToutput.dz{j}))+1]);
%         grid on; %this turns grid on
%         hold('all'); %this is for the xticks and grid to stay on
%      plot(TGToutput.f(1:end/2),TGToutput.dz{j}(1:end/2));% AG 1/12/10 added 1:end/2
    hp(1)=plot([1:scenarios{j}.nfeat],scenarios{j}.signal,'k-','LineWidth',1);hold on;%already normalized above
    hp(2)=plot([1:scenarios{j}.nfeat],results{j}.discriminant,'b-','LineWidth',2);hold on; 
    labels={'signal','classifier'};
    set(gca,'FontName','Times New Roman','Fontsize', 20);
    plot([0.5 sc.nfeat+0.5],[0 0],'k-');hold on;
%         xlabel('feature','FontSize',12);
        set(gca,'XTick',[1:sc.nfeat]);
        %fancy argument to use bracketed ranges for tick labels
        set(gca,'XTickLabel',cellstr(reshape(sprintf('[%4.1f %4.1f]',fpart'),[11 scenarios{j}.nfeat])'));
        set(gca,'XLim',[0.5 scenarios{j}.nfeat+0.5]);
        set(gca,'FontSize',10); %changed
        ylabel('weight','FontSize',12);
        set(gca,'YTick',[-1:0.5:1],'FontSize',12); %changed
        set(gca,'YLim',[-1 1]);
        legend(hp,labels,'FontSize',10);
        graphTitle=sprintf('%s -\n %.0f%%, %.0f%%, %.5g',channellabels{j},percentCorrectMapbayesSegs{j},percentCorrectMapbayesUnrestricted{j},p_segflip{j}); 
%         graphTitle(1)={'\bfOr' [channellabels{j}]};
%         graphTitle(2)={num2str(percentCorrectMapbayesSegs{j})
        title(graphTitle,'FontSize',12); 
%         title(cat(2,sc.name,sprintf(': segsize=%3.0f delrad=%3.0f',segsize,delrad)),'FontSize',10);
    end
    allowaxestogrow;

    summarytable=[cell2mat(percentCorrectMapbayesSegs)' cell2mat(p_segflip)']; %list for pasting into excel
    
    savename=[figureTitle '_FisherData'];
%     savename=['Fisherdisc_' scenario_name]; 
     if exist([savename '.mat'],'file') ==2; %check to see if file exists of that savename
        savename=sprintf('%s_%s',savename, datestr(now, 'dd_mm_yyyy_HH_MM'));
     end
    save (savename,'results','ou','p_segflip','percentCorrectMapbayesSegs','percentCorrectMapbayesUnrestricted','channellabels','summarytable','fpart');
toc
end