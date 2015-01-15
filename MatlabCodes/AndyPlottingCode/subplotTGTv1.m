function TGToutput=subplotTGT(varargin)
% function [dz,vdz,Adz]=subplotTGT(figuretitle,data1label,data2label,p)
% Test the null hypothesis (H0) that data sets data1 and data2 in 
% two conditions c1,c2 have equal population spectrum
%
% Usage:
% [dz,vdz,Adz]=two_sample_test_spectrum(J1,J2,p)
%
% Inputs:
% J1   tapered fourier transform in condition 1
% J2   tapered fourier transform in condition 2
% p      p value for test (default: 0.05)
% plt    'y' for plot and 'n' for no plot
% f      frequencies (useful for plotting)
%
%
% Dimensions: J1: frequencies x number of samples in condition 1
%             J2: frequencies x number of samples in condition 2
%              number of samples = number of trials x number of tapers
% Outputs:
% dz    test statistic (will be distributed as N(0,1) under H0
% vdz   Arvesen estimate of the variance of dz
% Adz   1/0 for accept/reject null hypothesis of equal population
%       coherences based dz ~ N(0,1)
% 
% 
% Note: all outputs are functions of frequency
% Note: Hemant made some updates for this 12/09 vs the one in Chronux.
% 1/12/10 Andy and Hemant made more changes to errors. See notes below.
%1/12/10 version 1 (starting with two_group_test_spectrum from Hemant /
%Chronux
%
% References: Arvesen, Jackkknifing U-statistics, Annals of Mathematical
% Statisitics, vol 40, no. 6, pg 2076-2100 (1969)
%
%note this version of the code uses no padding
%
%To do:
%[] move UI to another program pick the outputs from batCrxULT (not spectra anymore) (do as a loop)
%[] move plotting to other program flag or different version toturn off plotting so can call from subplot or
%batcrxULT to plot AdzJK on regular graph
%[]give this output variables that get read in by subplotSpectra
%[]allow to take in variable names from the command line rather than from
%UI (or make the UI and plotting a different program and make this a bat
%program and the UI a plotting program)

%%%%%%%%%%%%%%defaults%%%%%%%%%%%%%
NW = 2;
K=3;
if nargin>3
    p=varargin{4};
else
    p=0.05;
end;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% %%
% %Open datafiles only if calling from command line
% 
 figuretitle=varargin{1,1};
% 
 spectra1label=varargin{1,2};%why is this 1,2?
 [filename1, pathname1, filterindex1] = uigetfile('*.mat', 'Select first dataset');
 data1=load(fullfile(pathname1,filename1));
% 
 spectra2label=varargin{1,3};%why is this 1,3?
 [filename2, pathname2, filterindex2] = uigetfile('*.mat', 'Select second dataset');
 data2=load(fullfile(pathname2,filename2));


%need code here to accept the data as exported from subplotSpectra, so
%inputs are the two dataCutByChannel. ensure it matches with below (is a
%cell?)

%data1=varargin{1};
%data2=varargin{2};


%%
%ensure the data are each the same number of data points
if size(data1.dataCutByChannel{1},1)~=size(data2.dataCutByChannel{1},1)
    fprintf('datasets have different segment lengths\n')
    return
end;
%%
%Variables
numSnippets=size(data1.dataCutByChannel{1},2);
numSamplesPerSnippet=size(data1.dataCutByChannel{1},1);
numChannels=size(data1.dataCutByChannel,2);
frequencyRecorded=data1.frequencyRecorded;
f=linspace(0,frequencyRecorded,numSamplesPerSnippet); %the x-axis of the plot is the
%frequencies. Frequencies are 0 to frequencyRecorded/2 in divisions of
%numSamplesPerSnippet. It's actually -frequencyRecorded/2 to
%+frequencyRecorded/2 and then you plot half of the values.
%%
%compute the tapers and make work for cellfun
tapers=dpss(numSamplesPerSnippet,NW,K);
fprintf('dpss tapers calculated with NW=%g and K=%g\n',NW,K);


%Here's the for loop to calculate two sample test on each cell (channel)
%from each of the 2 input data. Will need to save the output to a cell
%array to use for the plotting part next.
for k=1:numChannels
%%
%calculate the spectra. Call J1 and J2 so use Hemant's code
J1=mtfftc(data1.dataCutByChannel{k},tapers,numSamplesPerSnippet,data1.frequencyRecorded);
J2=mtfftc(data2.dataCutByChannel{k},tapers,numSamplesPerSnippet,data2.frequencyRecorded);

%%
%reshape J1 and J2 since trials and tapers are equivalent
J1=reshape(J1,[size(J1,1) size(J1,2)*size(J1,3)]);
J2=reshape(J2,[size(J2,1) size(J2,2)*size(J2,3)]);
%%
%calculate the two sample test.
% if nargin < 2; error('Need four sets of Fourier transforms'); end;
% if nargin < 4 || isempty(plt); plt='n'; end;
% 
% Test for matching dimensionalities
%
m1=size(J1,2); % number of samples, condition 1
m2=size(J2,2); % number of samples, condition 2
dof1=m1; % degrees of freedom, condition 1
dof2=m2; % degrees of freedom, condition 2
% if nargin < 5 || isempty(f); f=size(J1,1); end; %will need to change this and below []
% if nargin < 3 || isempty(p); p=0.05; end; % set the default p value

%
% Compute the individual condition spectra, coherences
%
S1=conj(J1).*J1; % spectrum, condition 1
S2=conj(J2).*J2; % spectrum, condition 2

Sm1=squeeze(mean(S1,2)); % mean spectrum, condition 1
Sm2=squeeze(mean(S2,2)); % mean spectrum, condition 2
%
% Compute the statistic dz, and the probability of observing the value dz
% given an N(0,1) distribution i.e. under the null hypothesis
%
bias1=psi(dof1)-log(dof1); bias2=psi(dof2)-log(dof2); % bias from Thomson & Chave
var1=psi(1,dof1); var2=psi(1,dof2); % variance from Thomson & Chave
z1=log(Sm1)-bias1; % Bias-corrected Fisher z, condition 1
z2=log(Sm2)-bias2; % Bias-corrected Fisher z, condition 2
dz=(z1-z2)/sqrt(var1+var2); % z statistic
%
%%
% The remaining portion of the program computes Jackknife estimates of the mean (mdz) and variance (vdz) of dz
% 
samples1=[1:m1];
samples2=[1:m2];
%
% Leave one out of one sample
%
bias11=psi(dof1-1)-log(dof1-1); var11=psi(1,dof1-1);
for i=1:m1;
    ikeep=setdiff(samples1,i); % all samples except i
    Sm1=squeeze(mean(S1(:,ikeep),2)); % 1 drop mean spectrum, data 1, condition 1
    z1i(:,i)=log(Sm1)-bias11; % 1 drop, bias-corrected Fisher z, condition 1
    dz1i(:,i)=(z1i(:,i)-z2)/sqrt(var11+var2); % 1 drop, z statistic, condition 1
    ps1(:,i)=m1*dz-(m1-1)*dz1i(:,i);
end; 
ps1m=mean(ps1,2);
bias21=psi(dof2-1)-log(dof2-1); var21=psi(1,dof2-1);
for j=1:m2;
    jkeep=setdiff(samples2,j); % all samples except j
    Sm2=squeeze(mean(S2(:,jkeep),2)); % 1 drop mean spectrum, data 2, condition 2
    z2j(:,j)=log(Sm2)-bias21; % 1 drop, bias-corrected Fisher z, condition 2
    dz2j(:,j)=(z1-z2j(:,j))/sqrt(var1+var21); % 1 drop, z statistic, condition 2
    ps2(:,j)=m2*dz-(m2-1)*dz2j(:,j);
end;
%
% Leave one out, both samples
% and pseudo values
% for i=1:m1;
%     for j=1:m2;
%         dzij(:,i,j)=(z1i(:,i)-z2j(:,j))/sqrt(var11+var21);
%         dzpseudoval(:,i,j)=m1*m2*dz-(m1-1)*m2*dz1i(:,i)-m1*(m2-1)*dz2j(:,j)+(m1-1)*(m2-1)*dzij(:,i,j);
%     end;
% end;
%
% Jackknife mean and variance
%
% dzah=sum(sum(dzpseudoval,3),2)/(m1*m2);
ps2m=mean(ps2,2);
% dzar=(sum(ps1,2)+sum(ps2,2))/(m1+m2);
vdz=sum((ps1-ps1m(:,ones(1,m1))).*(ps1-ps1m(:,ones(1,m1))),2)/(m1*(m1-1))+sum((ps2-ps2m(:,ones(1,m2))).*(ps2-ps2m(:,ones(1,m2))),2)/(m2*(m2-1));
% vdzah=sum(sum((dzpseudoval-dzah(:,ones(1,m1),ones(1,m2))).*(dzpseudoval-dzah(:,ones(1,m1),ones(1,m2))),3),2)/(m1*m2);
%
% Test whether H0 is accepted at the specified p value
%
Adz=zeros(size(dz));
x=norminv([p/2 1-p/2],0,1);
indx=find(dz>=x(1) & dz<=x(2)); 
Adz(indx)=1;

% Adzar=zeros(size(dzar));
% indx=find(dzar>=x(1) & dzar<=x(2)); 
% Adzar(indx)=1;
% 
% Adzah=zeros(size(dzah));
% indx=find(dzah>=x(1) & dzah<=x(2)); 
% Adzah(indx)=1;

%%
%plot the spectra
% if strcmp(plt,'y');
%     if isempty(f) || nargin < 5; %AG changed from 6 which is a bug from the coherence code 1/12/10, should be 7 in coh code
%         f=linspace(0,1,length(dz)); %should be changed to 0,0.5
%     end;
    %
    % Compute the spectra
    %
    S1=squeeze(mean(conj(J1).*J1,2));
    S2=squeeze(mean(conj(J2).*J2,2));
    %
    
    TGToutput.dz{k}=dz;
    TGToutput.vdz{k}=vdz;
    TGToutput.Adz{k}=Adz;
end;
%%
    % Plot the spectra
    %
    numrows=ceil(sqrt(numChannels));
    numcols=floor(sqrt(numChannels));
    
    scrsz = get(0,'ScreenSize'); %for defining the figure siz
    figure; %added by AG on 1/12/10
    set(gcf,'Name',[varargin{1}], 'Position',[1 1 scrsz(3)*0.8 scrsz(4)*0.9]);
    
    annotation(figure(gcf),'textbox','String',{'params used:' 'tapers=' num2str(NW) num2str(K)},...
        'FitBoxToText','off',...
    'Position',[0.01635 0.5581 0.07671 0.3851],'FontUnits','normalized'); %this uses normalized units.

    for j=(1:numChannels);
        subplot(numrows,numcols,j);
        set(gca,'xtick',[0:5:frequencyRecorded/2+5]); %this sets the xticks every 5
        axis([0 frequencyRecorded/2+5 floor(min(TGToutput.dz{j}))-1 ceil(max(TGToutput.dz{j}))+1]);
        grid on; %this turns grid on
        hold('all'); %this is for the xticks and grid to stay on
%     subplot(311); 
%     plot(f(1:end/2),S1(1:end/2),f(1:end/2),S2(1:end/2)); legend('Data 1','Data 2'); %AG 1/12/10 added 1:end/2
%     set(gca,'FontName','Times New Roman','Fontsize', 16);
%     ylabel('Spectra');
%     title('Two group test for spectra'); %changed from coherence to spectra by AG 
%     subplot(312);
     plot(f(1:end/2),TGToutput.dz{j}(1:end/2));% AG 1/12/10 added 1:end/2
    set(gca,'FontName','Times New Roman','Fontsize', 16);
    ylabel('Test statistic');
    conf=norminv(1-p/2,0,1);
    line(get(gca,'xlim'),[conf conf]);
    line(get(gca,'xlim'),[-conf -conf]);
    
    %plot the jacknife errors as well
    P=repmat([p/2 1-p/2],[length(f) 1]);%this replicates the row [p/2 1-p/2] the length(f) number of times along the columns
    M=zeros(size(P)); %matrix of means equal to 0 with same dimensions as P
    V=[TGToutput.vdz{j} TGToutput.vdz{j}];
    cdz=norminv(P,M,V); %cdz is the confidence bands. Can then redefine adz to be 0 when dz is outside the band
    plot(f(1:end/2),cdz(1:end/2,1:2));
    TGToutput.AdzJK{j} = zeros(size(TGToutput.dz{j})); %AdzJK is 0 where dz is outside of JacknifeCI
    indxJK=find(TGToutput.dz{j}>=cdz(1) & TGToutput.dz{j}<=cdz(2)); 
    TGToutput.AdzJK{j}(indxJK)=1; %use this TGToutput to plot onto subplotSpectra to show significance
    TGToutput.f=f;

    
    title(data1.channelLabels{j},'FontSize',14);
       % legend(varargin{1},varargin{2}); need to modify
    %need to add in here calculation and plotting of jacknife
%     subplot(313);
%     plot(f(1:end/2),vdz(1:end/2)); %AG 1/12/10 added 1:end/2
%     set(gca,'FontName','Times New Roman','Fontsize', 16);
%     xlabel('frequency'); ylabel('Jackknifed variance');

    end

    
%%
%save results    
    %save varargin{1} f TGToutput
    allowaxestogrow;
    
    fprintf('two sample test calculated with p =%g\n',p);
end