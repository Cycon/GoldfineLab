
function subplotSpectra(spectra1, spectra2, spectra3, subset, figuretitle, spectra1label, spectra2label, spectra3label, numrows, numcols, graphcomments, TGToutput)

%makes a figure containing graphs of 1,2 or 3 spectra and their error bars
%from data exported by NDB. Best is to use subplotSpectraUI to call this
%code and to use spectra created by batCrxULT (called by batCrxULT_UI).
%Also plots results from two group test as * where significant difference.
%
%Spectra need to be in structure format (meaning create by typing results=load('output.mat').
%Values are assumed to be in dB format (default output from browser (no need to multiply by 10log10).
%
%Here's what to type: subplotSpectra(spectra1,spectra2,spectra3,[subset],'figuretitle','spectra1label','s
%pectra2label','spectra3label',numrows,numcols,'graphcomments')
%graphcomments are optional.
%
%Requires title, spectralabels and graphcomments to be in 'quotes'. Subset is a vector in
%[] with channel numbers of interest (such as 1:9). If you have less than 3 spectra,
%replace remaining spectra and spectralabels with any character.
%
%If powerspectrum done in browser, need to choose the ChannelList from within the program to set the
%appropriate titles of the graphs. The order is the same as how the browser
%graphs it. Also need to ensure accurate frequency data recorded at from within
%program.

%
%This program requires allowaxestogrow.m be in the path.
%http://www.mathworks.de/matlabcentral/fileexchange/7867-allowaxestogrow
%with line 104 changed to presetaxes = [0.11 0.05 0.81 0.9];
%also linkzoom
%http://www.mathworks.com/matlabcentral/fileexchange/21414-linkzoom-m-v1-3-aug-2009
%also maximize
%http://www.mathworks.co.jp/matlabcentral/fileexchange/10274
%also contiguous
%http://www.mathworks.com/matlabcentral/fileexchange/5658-contiguous-start-and-stop-indices-for-contiguous-runs
%
%Features pending: % label y and x-axis. Also need to add Drew or Shawniqua's
% fancy error bars. If movingwin is normalized need to change code for
% secondsofdataused. If browser makes channel labels useful (instead of long formulas) then will want also to read in these labels
% to use instead of long formula fix.
%
%version 1.1 suppressed 'hold on' from output by changing to 'hold on' from
%        hold; and have it display frequency used to ensure it's correct.
%version 1.2 fixed figure choice so can run if there are figures open
%            already and pastes in some of the params from spectra 1
%            automatically to the figure in the upper left
%version 1.3 shows the amount of time for spectra 1 and 2 (though includes
%            data cutoff by moving window so is excessive)
%version 1.4 had error if no figures, figurecount gave [] so added code. 
%version 1.5 now calculates actual number of seconds used for analysis.
%           will need to change if movingwin becomes normalized. also added
%           code so can plot figures even if ones from browser are opened.
%version 1.6 fixed time calculation by adding +1. Also added display of
%           time of 3rd spectrum (though square around it too small)
%version 1.7 added allowaxestogrow and linkzoom though need to confirm that it works and
%            if there's a point if need to retype every time. Also need to figure how
%            to run it on all open figures
%version 1.8 added xticks at 5 and grid lines and code to assign
%            FreqRecorded from name of channel
%version 1.9 11/2 made title font size bigger, fixed to allow for plotting
             %only some figures. 
%version 2   11/3 adding in graphcomments as an input variable and making sure it only appears when
             %exists. Also allowed for 1 spectra (like Toshiki's version).
             %Added transverse montages.
%version 2.1 11/9 added ability to take in channelList and
             %frequencyRecorded from output of batCrxULT. If these fields
             %don't exist (i.e. uses output from browser) will use old
             %method.
%version 2.2 11/11 changed channel labels so that if using Avg or Laplacian
             %it will use the abreviated names below. Also now exits code
             %if montages are not the same in the spectra.
%version 2.3 1/17 calls subplotTGT to calcuate significance with Two Group
             %Test (corrects for different sample sizes) and other slight
             %mods. Also puts * in title if any sig differences
%version 2.4 2/12 calculates and displays  frequencies with contiguous frequencies over set
             %number of Hz.
%version 2.5 2/17 calls batTGT instead of subplotTGT (program renamed).
%version 2.6 2/18/10 Removed calculation of contiguous frequencies and move
             %to plotSigFreq. Calls plotSigFreq
%version 2.7 2/26 takes in TGToutput so dont need to rerun if just want to
             %replot. Now can put in option to not plot bad plots 
%version 2.8 3/1 sets a default plotting range which can change but mainly
             %for plotting data acquired at 1024 and analyzed up to 512Hz
%version 2.9 3/29 changed frequency recorded to actual frequency recorded
                %to allow for differences between the spectra. This
                %eliminated option of plotting browser output.
             
%%
%Defaults 
plottingRange=[0 100]; %range to plot
plottingFreqIndeces=(spectra1.f{1}*spectra1.frequencyRecorded>=plottingRange(1) & spectra1.f{1}*spectra1.frequencyRecorded<=plottingRange(2));

%%
%Run two group test to obtain Adz. Runs only if 2 spectra
%Just below this uses output to calculate and display contiguous
%significant differences > a set value
if isstruct(spectra2) && ~isstruct(spectra3) %to ensure only runs if 2 spectra
    if iscell(TGToutput)%if TGT entered as variable, don't rerun
        saveresults=0;
    else
        avgdiff5to100=Sderivative(spectra1,spectra2);
        TGToutput=batTGT(spectra1,spectra2);
        saveresults=1; %save the results of TGT and avgdiff
    end
end;

%%
%Need to ensure that all spectra have the same montage:
if isstruct(spectra3) && isfield(spectra2,'channellist'); %need both to ensure that 3 spectra used and is from batCrx and not browser
    if ~(strcmp(spectra1.channellist,spectra2.channellist) && strcmp(spectra1.channellist,spectra3.channellist));
        fprintf('Montages are not the same in all spectra, they are %s, %s and %s\n',spectra1.channellist,spectra2.channellist,spectra3.channellist);
        return
    end
end


if isstruct(spectra2) && isfield(spectra2,'channellist');
    if ~(strcmp(spectra1.channellist,spectra2.channellist));
        fprintf('Montages are not the same in all spectra, they are %s and %s\n',spectra1.channellist,spectra2.channellist);
        return
    end
end
    
%%
%if spectra1.ch exists (from batCrxULT) then set it to be the Channellist. If it is one of the 4 with the long names, titles assigned here. 
%If used browser, need to type it in below where is says Channellist=... and put in one from the list.
if isfield(spectra1,'channellabels') && (strcmp(spectra1.channellist,'AvgRefEKDB12') || strcmp(spectra1.channellist,'LaplacianEKDB12'));
    ChannelList={'Fp1','Fp2','AF7','AF8','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CP2','CP6','T5','P3','Pz','P4','T6','O1','O2'};
elseif isfield(spectra1,'channellabels') && (strcmp(spectra1.channellist,'AvgRefEMU40') || strcmp(spectra1.channellist,'LaplacianEMU40'));
    ChannelList={'FPz','Fp1','Fp2','AF7','AF8','F7','F3','F1','Fz','F2','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CPz','CP2','CP6','T5','P3','Pz','P4','T6','PO7','O1','POz','Oz','O2','PO8'};
elseif isfield(spectra1,'channellabels');
    ChannelList=spectra1.channellabels;
else
    
%OldHeadbox:
EKDBChannels={'Fp1-F3'	'F3-FC1'	'FC1-C3'	'C3-CP1'	'CP1-P3'	'P3-O1'	'Fp2-F4'	'F4-FC2'	'FC2-C4'	'C4-CP2'	'CP2-P4'	'P4-O2'	'Fp1-AF7'	'AF7-F7'	'F7-FC5'	'FC5-T3'	'T3-CP5'	'CP5-T5'	'T5-O1'	'Fp2-AF8'	'AF8-F8'	'F8-FC6'	'FC6-T4'	'T4-CP6'	'CP6-T6'	'T6-O2'	'Fz-Cz'	'Cz-Pz'};
NeonatalChannels={'Fz-Cz' 'T4-O2' 'Fp2-T4' 'C4-O2' 'Fp2-C4' 'T3-O1' 'Fp1-T3' 'C3-O1' 'Fp1-C3'};
LaplacianEKDB12={'Fp1','Fp2','AF7','AF8','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CP2','CP6','T5','P3','Pz','P4','T6','O1','O2'};
%LaplacianEKDB12 also used for AvgRefEKDB12
EKDBTransverse={'F7-AF7','AF7-Fp1','Fp1-Fp2','AF8-Fp2','F8-AF8','F7-F3','F3-Fz','F4-Fz','F8-F4','FC5-FC1','FC1-FC2','FC6-FC2','T3-C3','C3-Cz','C4-Cz','T4-C4','CP5-CP1','CP1-CP2','CP6-CP2','T5-P3','P3-Pz','P4-Pz','T6-P4','O1-O2'};

%NewHeadboxEMU40:
EMU40DBplus18={'Fp1-FPz' 'Fp1-F3' 'F3-FC1' 'FC1-C3' 'C3-CP1' 'CP1-P3' 'P3-O1' 'FPz-Fp2' 'Fp2-F4' 'F4-FC2' 'FC2-C4' 'C4-CP2' 'CP2-P4' 'P4-O2' 'Fp1-AF7' 'AF7-F7' 'F7-FC5' 'F1-FC1' 'FC5-T3' 'T3-CP5' 'CP5-T5' 'T5-PO7' 'PO7-O1' 'Fp2-AF8' 'AF8-F8' 'F8-FC6' 'F2-FC2' 'FC6-T4' 'T4-CP6' 'CP6-T6' 'T6-PO8' 'PO8-O2' 'Fz-Cz' 'Cz-Pz' 'CPz-POz' 'POz-Oz'};
Laplacian1={'Fz vs FC5+FC6+FPz' 'Cz vs P3+P4+Fz' 'P3 vs T5+POz+C3' 'P4 vs T6+POz+C4'};
Laplacian2={'Cz-(FC1+FC2+CP1+CP2' 'C3-(FC5+FC1+CP5+CP1)' 'C4-(FC2+FC6+CP2+CP6)' 'P3-(T5+POz+CP5+CPz)' 'P4-(T6+POz+CP6+CPz)'};
Laplacian3={'FPz-(Fp1+Fp2)/2' 'Fp1-(FPz-AF7)/2' 'Fp2-(FPz+AF8)/2' 'AF7-(Fp1+F7)/2' 'AF8-(F8+Fp2)/2' '(F3-(AF7+FC5+FC1+(Fp1+Fz)/2)/4)/2.25'... 
'(F4-(AF8+FC6+FC2+(Fp2+Fz)/2)/4)/2.25' 'FC5-(F7+F3+T3+C3)/4' 'FC1-(F3+Fz+C3+Cz)/4' 'FC2-(F4+Fz+C4+Cz)/4'... 
'FC6-(F8+F4+T4+C4)/4' '(T3-(F7+T5)/2)/4' 'C3-(FC5+FC1+CP5+CP1)/4' 'Cz-(FC1+FC2+CP1+CP2)/4' 'C4-(FC6+FC2+CP6+CP2)/4'...
'(T4-(F8+T6)/2)/4' 'CP5-(T3+C3+T5+P3)/4' 'CP1-(C3+Cz+P3+Pz)/4' 'CPz-(Cz+CP1+CP2+Pz)/4' 'CP2-(C4+Cz+P4+Pz)/4'...
'CP6-(T4+C4+T6+P4)/4' 'P3-(T5+POz+CP5+CPz)/4' 'P4-(T6+POz+CP6+CPz)/4' 'PO7-(T5+O1)/2' 'O1-(PO7+Oz)/2' 'Oz-(O1+O2)/2'...
'O2-(Oz+PO8)/2' 'PO8-(O2+T6)/2'};
LaplacianEMU40={'FPz','Fp1','Fp2','AF7','AF8','F7','F3','F1','Fz','F2','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CPz','CP2','CP6','T5','P3','Pz','P4','T6','PO7','O1','POz','Oz','O2','PO8'};
%LaplacianEMU40 also used for AvgRefEMU40
EMU40Transverse={'F7-AF7','AF7-Fp1','Fp1-FPz','Fp2-FPz','AF8-Fp2','F8-AF8','F7-F3','F3-F1','F1-Fz','F2-Fz',...
    'F4-F2','F8-F4','FC5-FC1','FC1-FC2','FC6-FC2','T3-C3','C3-Cz','C4-Cz','T4-C4','CP5-CP1','CP1-CPz',...
    'CP2-CPz','CP6-CP2','T5-P3','P3-Pz','P4-Pz','T6-P4','PO7-POz','PO8-POz','O1-Oz','O2-Oz'};

ChannelList=LaplacianEMU40; %here you define which channel list from above is used if need to define manually.
fprintf('data from browser used, ensure ChannelList variable set correctly in subplotSpectra (%s chosen)\n',ChannelList);
end;


%%
%run separate plot of significant frequencies, can add column vactor to end to
%change plotting range
if isstruct(spectra2) && ~isstruct(spectra3) %to ensure only runs if 2 spectra
    [contiguousMoreThanFR,contiguousSigFreq]=plotSigFreq(figuretitle,spectra1label, spectra2label,TGToutput, ChannelList);
end
%%
%here determine if all values are there, if not replace with defaults.
%Start with just graphcomments.
if nargin<11
    graphcomments=0;
end;

%here determine frequencyRecorded either from the powerspectrum (if done
%with batCrxULT) or decided manually below (if from browser export) where
%new montages will need to be added.
if ~isfield(spectra1,'frequencyRecorded')
    disp('spectra doesn''t have frequencyRecorded, need to rerun')
    return
end
%         FrequencyRecorded=spectra1.frequencyRecorded;     
% else
%     if isequal(ChannelList,EKDBChannels) || isequal(ChannelList,LaplacianEKDB12) || ...
%         isequal(ChannelList,NeonatalChannels) || isequal(ChannelList,EKDBTransverse)
%         FrequencyRecorded=200;
%     else
%         FrequencyRecorded=256;
%     end;
% end;

numchannels=size(subset,2);
%this calculates the number of channels to display

%%
%figure out what figure number to start with

numfigs=ceil(numchannels/(numrows*numcols));
%this calculates the number of figures that will be needed

openfigsnotfrombrowser=findobj('type','figure')<50;%gives a logical array for all figures <50 since browser creates figures with very large #s
openfigs=findobj('type','figure');%gives a list of all open figs as a logical array.
figurecount = max(openfigs(openfigsnotfrombrowser));%gives the maximum figure number <50 (50 since assume that will never have that many open)
%this is to count how many figures are open already so you can just add to it with the next command.

if isempty(figurecount) %this code is necessary because if no figures then figurecount=[]
    figurecount=0;
end;

%%
%figure out data for annotation

secondsofdatausedspectra1=sum((floor((spectra1.sMarkers(:,2)-spectra1.sMarkers(:,1)+1)/spectra1.movingwin(1,1))).*spectra1.movingwin(1,1)./spectra1.frequencyRecorded);

if isstruct(spectra2)
    secondsofdatausedspectra2=sum((floor((spectra2.sMarkers(:,2)-spectra2.sMarkers(:,1)+1)/spectra2.movingwin(1,1))).*spectra2.movingwin(1,1)./spectra2.frequencyRecorded);
else
    secondsofdatausedspectra2=0;
end;
%the plus 1 was added since it wasn't counting the 1st datapoint and if
%exactly the same as the moving window, you lose 1 second since rounds
%down.

if isstruct(spectra3)
    secondsofdatausedspectra3=sum((floor((spectra3.sMarkers(:,2)-spectra3.sMarkers(:,1)+1)/spectra3.movingwin(1,1))).*spectra3.movingwin(1,1)./spectra3.frequencyRecorded);
else
    secondsofdatausedspectra3=0;
end;
    %this calculates the number of seconds of data used for the analysis by
%using sMarkers to determine length of intervals (in datapoints), then
%dividing by movingwin length (in datapoints) and rounding down to
%determine how much data was actually used; then it converts back to
%datapoints by multiplying by movingwin and then dividing by
%frequencyRecorded to convert to seconds. Finally it sums.
%If movingwin is ever normalized to seconds, will need to change this code.

%%
%begin plotting
scrsz = get(0,'ScreenSize'); %for defining the figure size, need to change if want on a 2nd monitor

for i=1:numfigs;
    figure(i+figurecount);
    
%this will open up the figure and assign it a size.

    %set(gcf,'Name',[figuretitle '-Figure' num2str(i)], 'Position',[1 1 scrsz(3)*0.95 scrsz(4)*0.9]); %big size
    set(gcf,'Name',[figuretitle '-Figure' num2str(i)], 'Position',[1 1 scrsz(3)*0.8 scrsz(4)*0.9]); %smaller size
    %Name assigns a name for the figure. 
    
    %this is for the annotation of params with a version for 3 and a
    %version for 2 spectra: (may want to change to be sprintf created
    %variable)
    
    if isstruct(spectra3)
    annotation(figure(gcf),'textbox','String',{'params used:' 'tapers=' num2str(spectra1.params.tapers),...
        'pad=' num2str(spectra1.params.pad) 'fpass=' num2str(spectra1.params.fpass) 'err=' num2str(spectra1.params.err),...
        'MW=' num2str(spectra1.movingwin) 'Spectrum1 (sec used):' num2str(secondsofdatausedspectra1),...
        'Spectrum2 (sec used):' num2str(secondsofdatausedspectra2) 'Spectrum3 (sec used):' num2str(secondsofdatausedspectra3)},'FitBoxToText','on',...
    'Position',[0.01635 0.5581 0.07671 0.3851],'FontUnits','normalized'); %this uses normalized units.

    else
        annotation(figure(gcf),'textbox','String',{'params used:' 'tapers=' num2str(spectra1.params.tapers),...
        'pad=' num2str(spectra1.params.pad) 'fpass=' num2str(spectra1.params.fpass) 'err=' num2str(spectra1.params.err),...
        'MW=' num2str(spectra1.movingwin) 'Spectrum1 (sec used):' num2str(secondsofdatausedspectra1),...
        'Spectrum2 (sec used):' num2str(secondsofdatausedspectra2)},'FitBoxToText','on',...
    'Position',[0.01635 0.5581 0.07671 0.3851],'FontUnits','normalized');
%However, if you set the FontUnits property of an annotation textbox object to normalized, the text changes
%size rather than wraps if the textbox size changes. FitBoxToText needs to
%be on or gives error when runs
    end;


%this will create a box containing comments in lower left of figure, if
%graphcomments comments exist
if ischar(graphcomments)
 annotation(figure(gcf),'textbox','String',{graphcomments},'FitBoxToText','off',...
    'Position',[0.01975 0.2134 0.07886 0.2778],'FontUnits','normalized');
end;
%%
%plot data between plotting range defined at top of this code (can modify
%to come from subplotSpectraUI so user can change)

   for j=((numrows*numcols*(i-1))+1):min(length(subset),numrows*numcols*i); %designed to stop when subset reaches end but has error if don't use all graphs. so need to change not to max of subset but count of subset.
        subplot(numrows,numcols,j-numrows*numcols*(i-1));
        set(gca,'xtick',[0:5:spectra1.frequencyRecorded/2+5],'FontSize',14); %this sets the xticks every 5
        grid on; %this turns grid on
        hold('all'); %this is for the xticks and grid to stay on
        plot(spectra1.frequencyRecorded*spectra1.f{1}(plottingFreqIndeces),(spectra1.S{1}(plottingFreqIndeces,subset(j))),'b','LineWidth',2); %f is normalized by browser so need to multiply by frequency recorded
        %spectra are organized by channel with each channel in a column
        hold on; 
        plot(spectra1.frequencyRecorded*spectra1.f{1}(plottingFreqIndeces),(spectra1.Serr{1}(:,plottingFreqIndeces,subset(j))),'b','HandleVisibility','off'); 
         %by turning HandleVisibility off the legend won't label it since
         %don't want to label the error
        title(ChannelList{subset(j)},'FontSize',14);
%         legend(spectra1label); %can change to turn off legend
        if isstruct(spectra2)%this line allows it to determine if a second spectra is entered
            plot(spectra2.frequencyRecorded*spectra2.f{1}(plottingFreqIndeces),(spectra2.S{1}(plottingFreqIndeces,subset(j))),'r','LineWidth',2); %changed 2/4
             plot(spectra2.frequencyRecorded*spectra2.f{1}(plottingFreqIndeces),(spectra2.Serr{1}(:,plottingFreqIndeces,subset(j))),'r','HandleVisibility','off'); 
 %            legend(spectra1label,spectra2label); %can change to turn off legend
%             ylabel('Power in db','FontSize',16)
%             xlabel('Frequency','FontSize',16)
        %would be nice to have a default name of the variable for legend if
        %not typed in
        end;
        if isstruct(spectra3)
            plot(spectra3.frequencyRecorded*spectra3.f{1}(plottingFreqIndeces),(spectra3.S{1}(plottingFreqIndeces,subset(j))),'g','LineWidth',2);
             plot(spectra3.frequencyRecorded*spectra3.f{1}(plottingFreqIndeces),(spectra3.Serr{1}(:,plottingFreqIndeces,subset(j))),'g','HandleVisibility','off');
%             legend(spectra1label,spectra2label,spectra3label);
        end;
        
        plotTGT=1; %so can suppress TGT tresults
        if isstruct(spectra2) && ~isstruct(spectra3)
            if plotTGT
            %here plot results of JK sig test from two group test
            TGTplottingFreqIndeces=(plottingRange(1)<=TGToutput{j}.f & TGToutput{j}.f<=plottingRange(2));
            if isstruct(spectra2) && ~isstruct(spectra3) %to ensure only runs if 2 spectra
             plot(TGToutput{j}.f(TGTplottingFreqIndeces),TGToutput{j}.AdzJK(TGTplottingFreqIndeces)*20,'*'); %hidden 3/26 for presentation
             if any(contiguousMoreThanFR{j}{1}) | any(contiguousMoreThanFR{j}{2}) %if any frequencies are sig
                 %more than freqResolution then put a * next to title
                 SigResultTitle=sprintf([ChannelList{subset(j)} '*']);
                 title(SigResultTitle,'FontSize',14);
             end;
            end;
            end
        end
           
    end;
    
%%
if isstruct(spectra2) && ~isstruct(spectra3)
    if saveresults %if previous TGToutput not entered, then save its results
        savename=[figuretitle '_TGToutput & contiguousList'];
        save(savename,'contiguousMoreThanFR','contiguousSigFreq','ChannelList','TGToutput','avgdiff5to100');
    end
end

allowaxestogrow;
linkzoom;

end;
%maximize(gcf); %this command will run a code to blow up figure to fill
%entire window, but is slow
%maximize('all');