function numbersTable

[NumbersFiles,NumbersPathname]=uigetfile('*Numbers.mat', ['Select Numbers Files'],'MultiSelect','on');

filenames=sort(NumbersFiles);
for i=1:length(filenames)
    filenamesshort{i}=filenames{i}(1:end-26);
end
filenamestable=char(filenamesshort);
for j=1:length(filenames)
    numbersfile=load(fullfile(NumbersPathname,filenames{j}));
    fprintf('%s | total Sig TGT: %4.0f | FDR TGT: %4.0f | FDR Fisher: %2.0f\n',filenamestable(j,:),numbersfile.totalSigTGT,numbersfile.totalFDRTGT,numbersfile.totalFD_FDRSig)
end