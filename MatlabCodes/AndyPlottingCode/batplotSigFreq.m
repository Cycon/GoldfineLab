function batplotSigFreq

%runs batplotSigFreq in batch mode. legendon tells plotSigFreq to not
%display a legend, annotation or titles so is designed for power point.
%version 2 9/3/10 allows for multiselect as long as Fisher files are same
    %name as TGT output files as created by PSeeglabSpectraBat

spectra1label='1'; %since no legend is created
spectra2label='2';

% if strcmp(input('Swim or Nav (type n for nav, default swim): ','s'),'n')  
%     spectra1label='nav';
%     spectra2label='stop';
% else
%     spectra1label='swim';
%     spectra2label='stop';
% end

m=1;
if strcmpi(input('Use Fisher? (y-yes): ','s'),'y')
    useFisher=1;
    if isequal(input('Auto associate Fisher with TGT by name (allows for multiselect) (y-yes, Return-no)?','s'),'y')
        autoFisher=1;
    else
        autoFisher=0;
    end

    while 1
        if autoFisher %use multiselect for many
            [TGTfilename,TGTpathnameM]=uigetfile('*List.mat', ['Select TGTOutput ' num2str(m) ', Cancel to stop'],'MultiSelect','on');

            if ~iscell(TGTfilename); %in case only enter one
                TGTfilename=cellstr(TGTfilename);

            end;

            break
        else
            [TGTfilename{m},TGTpathname{m}]=uigetfile('*List.mat', ['Select TGTOutput ' num2str(m) ', Cancel to stop']);
            if TGTfilename{m}==0
                TGTfilename=TGTfilename(1:end-1);
                m=m+1;
                break
            end

    %         TGToutputContigList{m}=load(fullfile(TGTpathname{m},TGTfilename{m}));
    %         TGToutput{m}=TGToutputContigList{m}.TGToutput;
    %         ChannelList{m}=TGToutputContigList{m}.ChannelList;
    %         figuretitle{m}=TGTfilename{m}(1:end-31);

            [Fisherfilename{m},Fisherpathname{m}]=uigetfile('*FisherData.mat', ['Select Fisher ' num2str(m)],TGTpathname{m});
            disp(['Figure ' num2str(m) ' is from ' TGTfilename{m}(1:end-26) ' and ' Fisherfilename{m}(1:end-4)]);
            m=m+1;

        end
    end
else
    [TGTfilename,TGTpathname]=uigetfile('*List.mat', ['Select TGTOutput(s) ' num2str(m) ', Cancel to stop'],'MultiSelect','on');
    useFisher=0;
end


if useFisher
    for i=1:length(TGTfilename) %whether entered one a time or in a group
        if autoFisher %if multiselect used
            TGTpathname{i}=TGTpathnameM;
            Fisherfilename{i}=[TGTfilename{i}(1:end-30) 'FisherData.mat'];
            Fisherpathname{i}=TGTpathnameM;
        end
        TGToutputContigList=load(fullfile(TGTpathname{i},TGTfilename{i}));
        TGToutput=TGToutputContigList.TGToutput;
        ChannelList=TGToutputContigList.ChannelList;
        figuretitle=TGTfilename{i}(1:end-31);

        plotSigFreq(figuretitle,spectra1label, spectra2label,TGToutput, ChannelList,TGTpathname{i},Fisherpathname{i},Fisherfilename{i},0);
        clf; %in hopes to prevent timeout waiting for window (one website said to use this then pause(n) seconds but trying without pause)
        close(gcf);
    end
else
    for i=1:length(TGTfilename) %whether entered one a time or in a group
        TGToutputContigList=load(fullfile(TGTpathname,TGTfilename{i}));
        TGToutput=TGToutputContigList.TGToutput;
        ChannelList=TGToutputContigList.ChannelList;
        figuretitle=TGTfilename{i}(1:end-31);
        plotSigFreqSimple(figuretitle,[], [],TGToutput, ChannelList,TGTpathname,0);
        clf; %in hopes to prevent timeout waiting for window (one website said to use this then pause(n) seconds but trying without pause)
        close(gcf);
    end
end