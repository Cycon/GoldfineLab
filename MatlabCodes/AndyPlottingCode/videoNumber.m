function videoNumber

%simple code to find the video number associated with a
%specific time in xltek. Assumes that the video clips
%are 2 minutes long. Need to give the start time of the 
%XLTEK file and the time of interest. 
%Hasn't been tested in cases where video is missing.

disp('Times can be inputted as [Y M D H M S] or [H M S]');
time(1,:)=input('Start time: ');
time(2,:)=input('Target time: ');

if size(time,2)==3 %if only input H M S
    time=[zeros(2,3) time];
end

durationInMin=datenum(time(2,:)-time(1,:))*24*60;
fprintf('Target at minute %.2f -> video number %.2f\n',durationInMin,durationInMin/2);
end