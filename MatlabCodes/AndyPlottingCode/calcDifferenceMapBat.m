function calcDifferenceMapBat

p=1;
cont=1;
while cont==1;
    [PSfilename1{p}, pathname1{p}] = uigetfile('*PS.mat', 'Select 1st power spectra data, Cancel to stop');
    if PSfilename1{p}==0
        p=p-1;
        cont=0;
    else
        [PSfilename2{p}, pathname2{p}] = uigetfile('*PS.mat', 'Select 2nd power spectra data',pathname1{p});
        [TGTfilename{p}, TGTpathname{p}] = uigetfile('*sList.mat', 'Select TGT output',pathname1{p});
        p=p+1;
    end
end

for ii=1:p
    calcDifferenceMap([PSfilename1{ii}(1:end-7) 'vs' PSfilename2{ii}(1:end-7)],PSfilename1{ii},pathname1{ii},PSfilename2{ii},pathname2{ii},TGTfilename{ii}, TGTpathname{ii});
end