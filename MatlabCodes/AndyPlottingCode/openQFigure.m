function openQFigure

%8/12/11 to open figures created by importQsensor easily
[figname figpath]=uigetfile('*.fig','Pick Q figure created by importQsensor');
open(fullfile(figpath,figname));
dynamicDateTicks(gca,'link');
axis tight;
zoom xon;
end