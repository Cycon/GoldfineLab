function TGToutput=batTGT(data1,data2)
%
%called by subplotTGT as well as by subplotSpectra
%Takes in data from PSeeglab. Each input needs to be a structure containing
%fields: dataCutByChannel, frequencyRecorded, params. dataCutByChannel is a
%cell with one channel per cell. This code then runs the two group test on
%each channel and produces outputs including significance with jackknife
%error bar calculations.
%
%modified version of Hemant's Two Group Test to calculate spectra and run on
%multiple channels as outputted from batCrxULT (data need to be cut into
%equal segment lengths first).
%called by subplotEeglabSpectra to run the two group test
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
%
%version 1 created
%version 1.1 removed all plotting
%version 1.2 renamed to batTGT (subplotTGT actually plots though should
          %just call this one and only plot and pull up data). Also will
          %calculate AdzJK1 and AdzJK2 to signify which condition is higher
          %for those significant frequency ranges to make plotting clear. 
%version 1.3 7/26/13 cleaned up
%version 1.4 7/28/13 changed calculation of p-value to use SD (correct)
%instead of variance (incorrect and based on email from Hemant)



%%
%defaults
if isfield(data1,'params') %use same values as mtspectrumc_ULT from batCrxULT
    NW=data1.params.tapers(1);
    K=data1.params.tapers(2);
    p=data1.params.err(2);
else %in case calling this from subplotTGT
NW = 3; 
K=5;
    if nargin>2
        p=varargin{3}; %can decide on a p-value in the call I guess
    else
        p=0.05;
    end;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
%ensure the data are each the same number of data points
downsampled=0; %sets default
if size(data1.dataCutByChannel{1},1)~=size(data2.dataCutByChannel{1},1)
    fprintf('datasets have different segment lengths\n')
    %downsample if 2nd one is 4x 1st one.
    if size(data2.dataCutByChannel{1},1)/size(data1.dataCutByChannel{1},1)==4
        disp('downsampling data2 by 4 using decimate command')
        downsampled=1;
        for id=1:length(data2.dataCutByChannel)
            for ic=1:size(data2.dataCutByChannel{id},2) %for each column
             data2downsampled.dataCutByChannel{id}(:,ic)=decimate(data2.dataCutByChannel{id}(:,ic),4);
            end
        end
    else
        return
    end
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
%compute the tapers
tapers=dpss(numSamplesPerSnippet,NW,K);
fprintf('Two Group Test uses dpss tapers calculated with NW=%g and K=%g and p-value=%.3f\n',NW,K,p);


%Here's the for loop to calculate two sample test on each cell (channel)
%from each of the 2 input data. Will need to save the output to a cell
%array to use for the plotting part next.
for k=1:numChannels
    TGToutput{k}.NW=NW;
    TGToutput{k}.K=K;
    TGToutput{k}.p=p;
    %%
    %calculate the spectra. Call J1 and J2 so use Hemant's code
    J1=mtfftc(data1.dataCutByChannel{k},tapers,numSamplesPerSnippet,data1.frequencyRecorded);
    if downsampled
        data2.frequencyRecorded=data1.frequencyRecorded;
        data2.dataCutByChannel=data2downsampled.dataCutByChannel;
    end
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
    Adz=ones(size(dz)); %changed zeros to ones
    x=norminv([p/2 1-p/2],0,1);
    indx=find(dz>=x(1) & dz<=x(2)); %[] Adz is the vector of the same dimension as dz which is 0 when the null hypothesis is rejected and 1 otherwise (this is
      % based on N(0,1)).
    Adz(indx)=0;

% Adzar=zeros(size(dzar));
% indx=find(dzar>=x(1) & dzar<=x(2)); 
% Adzar(indx)=1;
% 
% Adzah=zeros(size(dzah));
% indx=find(dzah>=x(1) & dzah<=x(2)); 
% Adzah(indx)=1;

%%
    % Compute the spectra
    %
    S1=squeeze(mean(conj(J1).*J1,2));
    S2=squeeze(mean(conj(J2).*J2,2));
    %
    
    TGToutput{k}.dz=dz;
    TGToutput{k}.vdz=vdz;
    TGToutput{k}.Adz=Adz;

%     
     %calculate the jacknife errors as well
     P=repmat([p/2 1-p/2],[length(f) 1]);%this replicates the row [p/2 1-p/2] the length(f) number of times along the columns
     M=zeros(size(P)); %matrix of means equal to 0 with same dimensions as P
     V=[TGToutput{k}.vdz TGToutput{k}.vdz];
     cdz=norminv(P,M,sqrt(V)); %cdz is the confidence bands. Can then define AdzJK (Jacknife) to be 1 when dz is outside the band
%     plot(f(1:end/2),cdz(1:end/2,1:2));

     %make an index of where TGT is significant compared to JK confidence
     %intervals
     TGToutput{k}.AdzJK = ones(size(TGToutput{k}.dz)); %changed zeros to ones
     TGToutput{k}.indxJK=find(TGToutput{k}.dz>=cdz(:,1) & TGToutput{k}.dz<=cdz(:,2)); %initially made error of putting cdz(1) like
     %for gaussian but here its a vector of numbers not a single confidence
     %interval
     TGToutput{k}.AdzJK(TGToutput{k}.indxJK)=0; %set AdzJK to 1 where dz is outside of JacknifeCI, use this TGToutput to plot onto subplotSpectra to show significance

     %make an index of where TGT is significant, accounting for which
     %condition is higher
     TGToutput{k}.indxJKC{1}=find(TGToutput{k}.dz<=cdz(:,2)); %index where condition 1 is not higher
     TGToutput{k}.indxJKC{2}=find(TGToutput{k}.dz>=cdz(:,1)); %index where condition 2 is not higher
     TGToutput{k}.AdzJKC{1} = ones(size(TGToutput{k}.dz));
     TGToutput{k}.AdzJKC{2} = ones(size(TGToutput{k}.dz)); 
     TGToutput{k}.AdzJKC{1}(TGToutput{k}.indxJKC{1})=0; %list of 1s for where condition 1 is higher
     TGToutput{k}.AdzJKC{2}(TGToutput{k}.indxJKC{2})=0; %list of 1s for where condition 2 is higher 
    
     TGToutput{k}.f=f;
end;
     
% 
%     
%     title(data1.channelLabels{j},'FontSize',14);
%        % legend(varargin{1},varargin{2}); need to modify
%     %need to add in here calculation and plotting of jacknife
% %     subplot(313);
% %     plot(f(1:end/2),vdz(1:end/2)); %AG 1/12/10 added 1:end/2
% %     set(gca,'FontName','Times New Roman','Fontsize', 16);
% %     xlabel('frequency'); ylabel('Jackknifed variance');
% 
%     end

    
%%
%save results    
    %save varargin{1} f TGToutput
%     allowaxestogrow;
    
    fprintf('two sample test calculated with p =%g\n',p);
end