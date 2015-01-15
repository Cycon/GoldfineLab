function plotSigFreqSimpleBat

%runs batplotSigFreqSimple in batch mode. legendon tells plotSigFreq to not
%display a legend, annotation or titles so is designed for power point.
%created 11/28 as a modification of batplotSigFreq

TGTfilenames=uipickfiles('type',{'*List.mat','TGTOutput file(s) '},'prompt','Select TGTOutput file(s)');

if isempty(TGTfilenames) || isnumeric(TGTfilenames) %if press cancel
    return
end
               


for i=1:length(TGTfilenames) %whether entered one a time or in a group
    [TGTfilepath TGTfilename]=fileparts(TGTfilenames{i});
    TGToutputContigList=load(TGTfilenames{i});
    TGToutput=TGToutputContigList.TGToutput;
    ChannelList=TGToutputContigList.ChannelList;
    figuretitle=TGTfilename(1:end-27);
    plotSigFreqSimple(figuretitle,[], [],TGToutput, ChannelList,TGTfilepath,0);
    clf; %in hopes to prevent timeout waiting for window (one website said to use this then pause(n) seconds but trying without pause)
    close(gcf);
end
end