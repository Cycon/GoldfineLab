%avg_cofl_spec.m:  routine to calculate average spectra,
%from a results structure produced by cofl_xtp_demo.m
% assumes "results" exists
% creates "avspec" structure
%
nsegs=results{1}.nsegs;
disp(sprintf('nsegs: %1.0f',nsegs));
nchans_analyzed=results{1}.nchans_analyzed;
disp(sprintf('nchans analyzed: %1.0f',nchans_analyzed));
c=results{1}.cohgram;
nfreqs=length(c.freqs);
disp(sprintf('nfreqs: %1.0f',nfreqs));
%
%define some frequency bands
if ~exist('bands')
    bands=[1 4;1 12.5;12.5 25;20 40;25 40];
end
nbands=size(bands,1);
disp('bands to be used:');
disp(bands);
%
avspec=[];
avspec.nsegs=nsegs;
avspec.segs_analyzed=results{1}.segs_analyzed;
avspec.nsegs_analyzed=length(results{1}.segs_analyzed);
avspec.nchans_analyzed=nchans_analyzed;
avspec.freqs=c.freqs;
avspec.montage_analyzed=results{1}.montage_analyzed;
avspec.filename=results{1}.filename;
avspec.laplacian=results{1}.laplacian;
avspec.desc=results{1}.desc;
avspec.spectra=zeros(nchans_analyzed,nfreqs);
avspec.inbands=zeros(nchans_analyzed,nbands);
whichfreqs=cell(0);
for iband=1:nbands
    whichfreqs{iband}=intersect(find(c.freqs>=bands(iband,1)),find(c.freqs<bands(iband,2)));
end
avspec.bands=bands;
avspec.whichfreqs=whichfreqs;
for ichan=1:nchans_analyzed
    %find this channel in the list of channel pairs
    iposit=0;
    pos1=find(ichan==c.pairs(:,1));
    pos2=find(ichan==c.pairs(:,2));
    if ~isempty(pos1)
        iposit=min(pos1);
        specs=c.S1;
        sno=1;
    elseif ~isempty(pos2)
        iposit=min(pos2);
        specs=c.S2;
        sno=2;
    end
    if (iposit>0)
        disp(sprintf('averaging channel %2.0f (%10s), spectrum taken from position %4.0f in S%1.0f',...
        ichan,avspec.montage_analyzed{ichan},iposit,sno));
        %do the averaging (average the log of the spectra, i.e., average as dB)
        avs=zeros(1,nfreqs);
        for isegptr=1:avspec.nsegs_analyzed
            iseg=results{1}.segs_analyzed(isegptr);
            avs=avs+mean(log(specs{iseg,iposit}),1); %add the mean spectrum from within each segment
        end
        avs=avs/nsegs; %average as logs
        avspec.spectra(ichan,:)=exp(avs);
        for iband=1:nbands
            avspec.inbands(ichan,iband)=exp(mean(avs(whichfreqs{iband})));
        end
    else
        disp(sprintf('averaging channel %2.0f: spectrum cannot be found.',ichan));
    end
end
avspec.spectra_dB=10*log10(avspec.spectra);
avspec.inbands_dB=10*log10(avspec.inbands);
%plot all the spectra (at high resolution)
figure;
plot(avspec.freqs,avspec.spectra_dB);
legend(avspec.montage_analyzed);
xlabel('freq');
ylabel('dB');
title(avspec.desc);
%plot the average power in each band
figure;
plot([1:nbands],avspec.inbands_dB);
legend(avspec.montage_analyzed);
xlabel('band');
set(gca,'XTick',[1:nbands]);
ylabel('dB');
title(avspec.desc);
%display the power in bands
disp('bands');
disp(bands)
disp('dB average in each band')
disp(avspec.inbands_dB);
%
disp('suggest saving the calculation by ''save [filename] avspec''');




