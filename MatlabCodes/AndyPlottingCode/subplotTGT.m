function subplotTGT_UI(varargin)

%this code calls batTGT and plots it on one figure like subplotSpectra
%does.
%runs on output of batCrxULT_UI (via batCrxULT)
%user inputs:
%subplotSpectraUI('title') (though will create title if not given)
%
%version 1 1/19/10 created though not yet tested
%version 1.1 1/26/10 ran it and fixed a bunch of bugs (mainly needed to
%give it more variables from the output of subplotTGT

%%

% spectra1label=varargin{1,2};%why is this 1,2? can use this if decide to
% plot spectra as well
[filename1, pathname1, filterindex1] = uigetfile('*.mat', 'Select first dataset');
data1=load(fullfile(pathname1,filename1));

% spectra2label=varargin{1,3};%why is this 1,3?
[filename2, pathname2, filterindex2] = uigetfile('*.mat', 'Select second dataset');
data2=load(fullfile(pathname2,filename2));


%[] put here command to run the TGT so can plot it below.
TGToutput=batTGT(data1,data2);
%%
%Variables
numSnippets=size(data1.dataCutByChannel{1},2);
numSamplesPerSnippet=size(data1.dataCutByChannel{1},1);
numChannels=size(data1.dataCutByChannel,2);
frequencyRecorded=data1.frequencyRecorded;
p=TGToutput{1}.p;

%%
    % Plot the spectra
    %

    numrows=ceil(sqrt(numChannels));
    numcols=floor(sqrt(numChannels));
    
    scrsz = get(0,'ScreenSize'); %for defining the figure siz
    figure; %added by AG on 1/12/10
    
    if isempty(varargin) %if no title used then create one
        varargin{1}=[filename1(1:end-4) ' vs ' filename2(1:end-4) ' TGT']
    end
    set(gcf,'Name',[varargin{1}], 'Position',[1 1 scrsz(3)*0.8 scrsz(4)*0.9]);
    
    annotation(figure(gcf),'textbox','String',{'params used:' 'p=' num2str(TGToutput{1}.p) 'tapers=' num2str(TGToutput{1}.NW) num2str(TGToutput{1}.K)},...
        'FitBoxToText','off',...
    'Position',[0.01635 0.5581 0.07671 0.3851],'FontUnits','normalized'); %this uses normalized units.

plottingRange=[5 25];
plotFreq=[plottingRange(1)<TGToutput{1}.f & TGToutput{1}.f<plottingRange(2)];
    for j=(1:numChannels);
        subplot(numrows,numcols,j);
        set(gca,'xtick',[0:5:plottingRange(2)]); %this sets the xticks every 5
%         axis([0 frequencyRecorded/2+5 floor(min(TGToutput{j}.dz))-1
%         ceil(max(TGToutput{j}.dz))+1]); %removed 6/8/10
        grid on; %this turns grid on
        hold('all'); %this is for the xticks and grid to stay on
%     subplot(311); 
%     plot(f(1:end/2),S1(1:end/2),f(1:end/2),S2(1:end/2)); legend('Data 1','Data 2'); %AG 1/12/10 added 1:end/2
%     set(gca,'FontName','Times New Roman','Fontsize', 16);
%     ylabel('Spectra');
%     title('Two group test for spectra'); %changed from coherence to spectra by AG 
%     subplot(312)
    plot(TGToutput{1}.f(plotFreq),TGToutput{j}.dz(plotFreq),'b','LineWidth',3);%changed 6/8/10
%      plot(TGToutput{1}.f(1:end/2),TGToutput{j}.dz(1:end/2));% AG 1/12/10 added 1:end/2
    set(gca,'FontName','Times New Roman','Fontsize', 16);
    ylabel('Test statistic');
    conf=norminv(1-p/2,0,1);
    %two lines below plot the normal distribution 95% error bars but I
    %don't use them so will suppress (6/8/10)
%     line(get(gca,'xlim'),[conf conf]); %removed 6/8/10
%     line(get(gca,'xlim'),[-conf -conf]);
    
    %plot the jacknife errors as well
     P=repmat([p/2 1-p/2],[length(TGToutput{1}.f) 1]);%this replicates the row [p/2 1-p/2] the length(f) number of times along the columns
     M=zeros(size(P)); %matrix of means equal to 0 with same dimensions as P
     V=[TGToutput{j}.vdz TGToutput{j}.vdz];
     cdz=norminv(P,M,V); %cdz is the confidence bands. Can then redefine adz to be 0 when dz is outside the band
    plot(TGToutput{1}.f(plotFreq),cdz(plotFreq,1:2),'g--','LineWidth',2); %changed 6/8/10
    legend('z-statistic','95% JK error');
%     plot(TGToutput{1}.f(1:end/2),cdz(1:end/2,1:2));
%     TGToutput{j}.AdzJK = zeros(size(TGToutput{j}.dz)); %AdzJK is 0 where dz is outside of JacknifeCI
%     indxJK=find(TGToutput{j}.dz>=cdz(1) & TGToutput{j}.dz<=cdz(2)); 
%     TGToutput{j}.AdzJK(indxJK)=1; %use this TGToutput to plot onto subplotSpectra to show significance
%     TGToutput.f=f;

%%
%create titles but for some montages need to shorten title from full
%formula

figuretitles=data1.ChannelList; %6/8/10 - so can use from PSeeglab method
    if isfield(data1,'channellist') % 6/8 10 - if from ndb analysis method

        if strcmp(data1.channellist,'LaplacianEKDB12') %to create a list of names for plotting
                  figuretitles={'Fp1','Fp2','AF7','AF8','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CP2','CP6','T5','P3','Pz','P4','T6','O1','O2'};
        elseif strcmp(data1.channellist,'LaplacianEMU40')
                  figuretitles={'FPz','Fp1','Fp2','AF7','AF8','F7','F3','F1','Fz','F2','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CPz','CP2','CP6','T5','P3','Pz','P4','T6','PO7','O1','POz','Oz','O2','PO8'};
        end;
    end
              
    title(figuretitles{j},'FontSize',14);
       % legend(varargin{1},varargin{2}); need to modify
    %need to add in here calculation and plotting of jacknife
%     subplot(313);
%     plot(f(1:end/2),vdz(1:end/2)); %AG 1/12/10 added 1:end/2
%     set(gca,'FontName','Times New Roman','Fontsize', 16);
%     xlabel('frequency'); ylabel('Jackknifed variance');

    end

    allowaxestogrow;
