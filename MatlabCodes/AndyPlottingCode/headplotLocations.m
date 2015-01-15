function [xnew,ynew]=headplotLocations(chanlocs,EGI)

%8/16/13 AMG based on headplotEeglabSpectra but a smaller code just to
%figure out axes locations so it can be flexible and called by other codes.
%Takes in EEG chanlocs structure variables. ***Just need to
%produce the axes locations and sizes for the other code to use, locations should be NaN for non-EEG
%channels. Need another code to plot
%
%9/4/13 made it so flips left to right all EGI data either from detecting
%E1 as the first name, or a flag that comes in in case labels were changed.
%Flip left to right since EGI files have -Y but otherwise we get positive Y
%and not clear how topoplot figures out to make it work (might be the
%theta?).
%
ChannelList={chanlocs.labels};
if nargin==1
    EGI=0;
end

if strcmpi(ChannelList{1},'E1') || EGI %if an EGI file
   %on 9/6/13 trying doing this using the sign of the theta value of each chanlocs
   %but couldn't get it to work in the same way for the EGI and for the JV
   %created chanlocs folders so just using this method instead.
        for d3=1:length(chanlocs)
            chanlocs(d3).Y=-chanlocs(d3).Y;
        end
end

% 
%initialize outputs
xnew=zeros(1,length(chanlocs));
ynew=xnew;

        %calculate the angle (theta) between all points and the center (Cz)
        for jj=1:length(chanlocs)
            chanlocs(jj).th=atan2(chanlocs(jj).Y,chanlocs(jj).X);
        end
        
        %determine the central channel
        if sum(strcmpi({chanlocs.labels},'Cz'));%if there is a channel named Cz like in all laplacian spectra
            cc=chanlocs(strcmpi({chanlocs.labels},'Cz'));
        elseif sum(strcmpi({chanlocs.labels},'FZ-CZ'));%for bipolar
            cc=chanlocs(strcmpi({chanlocs.labels},'FZ-CZ'));%seems like a good choice though might be others
        elseif sum(strcmpi({chanlocs.labels},'A1')) %if biosemi system from Moss rehab
            cc=chanlocs(strcmpi({chanlocs.labels},'A1'));
        else
            disp('No clear central channel, add option to code');
            return
        end
        
        d=zeros(1,length(chanlocs));%just to initialize it
        
        %calculate the spherical arc length between all points and the center
        for j=1:length(chanlocs)
            if ~isstruct(chanlocs(j))%if not an eeg channel then I think will be nan 9/6/13
                d(j)=nan;
            end
            d(j) = atan2(norm(cross([chanlocs(j).X chanlocs(j).Y chanlocs(j).Z],[cc.X cc.Y cc.Z])),dot([chanlocs(j).X chanlocs(j).Y chanlocs(j).Z],[cc.X cc.Y cc.Z]));
        end
        
        %calculate new x and y locations using the spherical arc length as the
        %radius. These are vectors for all channels.
        xnew=d.*cos([chanlocs.th]);
        ynew=d.*sin([chanlocs.th]);