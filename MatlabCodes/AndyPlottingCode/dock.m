if strcmpi(input('Dock figures? (y = yes, Return = no): ','s'),'y')
    set(0,'DefaultFigureWindowStyle','docked');
else
    set(0,'DefaultFigureWindowStyle','normal');
end