function [actualDiff,f,f_pvalue,p_value,params]=calcSpecDifference(spectra,TGToutput)

%based on calcDifferenceMap but meant to be called by subplotEeglabSpectra
%assumes equal number of channels and frequencies to no need to check for
%errors.
%inputs: spectra (cell array of 2 spectra)
%   TGToutput
%8/7/13 modified to correct normcdf to use sd and not variance
%8/12/13 modified so is giving difference of dB not just log (multiply by
%10) so is consistent with power spectra plots

%%

    %spectraByChannel's length is number of channels not number of snippets.
    %Tags needs to be number of snippets
    numChan=size(spectra{1}.S,2);
%     numFreq=size(PS1.S,1);

    actualDiff=cell(1,numChan); %partway initialized
    p_value=cell(1,numChan);

    for s=1:numChan %for each Channel
        actualDiff{s}=10*log10(spectra{1}.S(:,s))-10*log10(spectra{2}.S(:,s));
%         actualDiff{s}=mean(PS1.spectraByChannel{s},2)-mean(PS2.spectraByChannel{s},2);
        p_value{s}=(2*(1-normcdf(abs(TGToutput{s}.dz),0,sqrt(TGToutput{s}.vdz))))';
       
    end

    %%
    %save results, include freq, fMtSpectrumc, actual and shuffled Diff
    f=spectra{1}.f;
     f_pvalue=TGToutput{1,1}.f;
%     ChannelList=PS1.ChannelList;
    params=spectra{1}.params;


    



        