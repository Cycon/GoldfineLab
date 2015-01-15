function openAndSaveAsPNG(varargin)

[figName, pathname] = uigetfile('*.fig', 'Select Figures','MultiSelect','on');

directory = uigetdir;

for i=1:length(figName);
    open(fullfile(pathname,figName{i}));
    savename=sprintf('%s/%s',directory,figName{i}(1:end-4));
    saveas(gcf,savename,'png');
    clf;
end