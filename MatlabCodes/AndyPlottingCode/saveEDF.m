function saveEDF

%10/28/13 AMG to save a figure as an edf file that is known to work with
%illustrator (since the default save as doesn't work). Can theoretically be
%placed as a button in the figure or use as a favorites button


savename=input('Name of figure: ','s');
disp('Choose figure you want to save then hit return');
pause;
print('-depsc','-painters','-loose',savename);