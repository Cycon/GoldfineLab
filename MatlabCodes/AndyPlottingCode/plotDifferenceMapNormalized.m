function plotDifferenceMapNormalized

%2/24/12 AMG
%take one or two spectra files, then normalize the power at one frequency
%by another by subtracting the logs. Then either topoplot it or if two
%selected will subtract them and topoplot them.
%6/7/12 change frequency resolution to be +/- FR of the data. Also
%converted s to a structure instead of a cell.
%7/6/12 removed call to eegp_defopts_eeglablocsAndy since asymmetric,
%though not for EGI system
%8/29/13 added ability to use EGI 33 channel system

disp('Note this displays in units of log, need to *10 to convert to dB'); %added 6/8/13, need to fix eventually
paths=uipickfiles('type',{'*PS.mat','mat'},'prompt','Pick one or two files, two will do subtraction.');


fi=input('Frequency of interest: ');
fn=input('Frequency to subtract off: ');

for p=1:length(paths)
    s(p)=load(paths{p});
    %conver to log and subtract the baseline then do mean to get one per
    %channel
    %%
    %Calculate frequency resolution for first one so consistent
    FR=s(1).params.tapers(1)/(0.5*(size(s(1).dataCutByChannel{1},1)/s(1).params.Fs));

    s(p).snorm=mean(log10(s(p).S(s(p).f>=(fi-FR) & s(p).f<=(fi+FR),:)),1)-mean(log10(s(p).S(s(p).f>=(fn-FR) & s(p).f<=(fn+FR),:)),1);
end

if strcmpi(s(1).ChannelList(1),'E1') 
    if length(s(1).ChannelList)==129 %if EGI system and none removed (because Kat removed some 4/25/12 and to get to work
    %would need to add a for loop to look for which channel is removed and then pull it out of the chanlocs, should be easy. Tried using JVs new egi version but 
    %didn't work on first pass)
        chanlocs=readlocs('GSN-HydroCel-129.sfp');
    elseif length(s(1).ChannelList)==33 %added 8/29/13
        chanlocs=pop_readlocs('GSN-HydroCel-32.sfp');
        %found on 8/13/13 that for some reason the horizontal axis (Y) is
        %opposite sign to the EGI129 and JV's code so need to flip them all
        for d3=1:length(chanlocs)
            chanlocs(d3).Y=-chanlocs(d3).Y;
        end
    end
    chanlocs(1:3)=[];%required for all EGI systems
elseif    length(s(1).ChannelList)==129 %if 129 named channels which is rarely used
    opts=eegp_defopts_eeglablocs('129');
    chanlocs=eegp_makechanlocs(char(s(1).ChannelList),opts);
else
%     opts=eegp_defopts_eeglablocs;%
    chanlocs=eegp_makechanlocs(char(s(1).ChannelList));
end


%%

tf=figure;
if length(paths)==1
    figuretitle=sprintf('Power at %.0f +/-%.2gHz, normalized by %.0f +/-%.2gHz',fi,FR,fn,FR);
else
    figuretitle=sprintf('Power difference at %.0f +/-%.2gHz, normalized by %.0f +/-%.2gHz',fi,FR,fn,FR);
end
set(tf,'Name',figuretitle);
uicontrol('parent',tf,'style','text','string','Color limits','units','normalized','position',[.05 .95 .1 .05]);
lower=uicontrol('parent',tf,'style','edit','string',' ','units','normalized','position',[.05 .9 .05 .05]);
upper=uicontrol('parent',tf,'style','edit','string',' ','units','normalized','position',[.1 .9 .05 .05]);
uicontrol('parent',tf,'style','pushbutton','callback',{@plotTopo,lower,upper,s,chanlocs},'units','normalized','position',[.05 .05 .1 .05],'string','plot');

function plotTopo(~,~,lower,upper,s,chanlocs)
    lb=str2double(get(lower,'string'));
    ub=str2double(get(upper,'string'));
if isnan(lb) || isempty(lb)%if space will be NaN
    if length(paths)==1
        limits='minmax';
    else
        limits='absmax';
    end
else
    limits=[lb ub];
end

if length(paths)==1
    topoplot(s(1).snorm,chanlocs,'maplimits',limits);
    colorbar;
else %if 2
    topoplot(s(1).snorm-s(2).snorm,chanlocs,'maplimits',limits);
    colorbar;
end
    
end
end
