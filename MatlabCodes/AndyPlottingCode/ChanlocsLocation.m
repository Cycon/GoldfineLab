function [ChanlocsFilename,ChanlocsPath]=ChanlocsLocation(numChannels,headbox)

if numChannels==37
    ChanlocsFilename='ChanlocsEMU40.ced';
elseif numChannels==29
    ChanlocsFilename='ChanlocsEKDB12.ced';
elseif numChannels==35 && headbox==0
    ChanlocsFilename='ChanlocsEMU40_Chin.ced';
elseif numChannels==35 && headbox==9
    ChanlocsFilename='ChanlocsEMU4035_NoF1F2.ced';
else
    disp('Wrong number of channels for available chanlocs files');
    return
end
    
if ~exist('/Users/andrewgoldfine/Documents/Cornell Research/EEGResearchJune8NoNmlOrigs/AndyPlottingCode','dir')
    disp('Need to modify code ''ChanlocsLocation'' to put path in for AndyPlottingCode line 12');
    ChanlocsPath=uigetdir(pwd,'Where is AndyPlottingCode?');
else
    ChanlocsPath='/Users/andrewgoldfine/Documents/Cornell Research/EEGResearchJune8NoNmlOrigs/AndyPlottingCode';
end
