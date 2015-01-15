function avgdiff5to100=Sderivative(varargin)

for i=1:length(varargin)
    f{i}=varargin{i}.f{1}*varargin{i}.frequencyRecorded;
    y=diff(varargin{i}.S{1});
    y5to100=y(5<=f{i} & f{i}<100,:); %just values between 5 and 100 Hz since lower values don't trust
    avgdiff5to100byCondition{i}=mean(y5to100,1);
end

%convert results above to a cell matrix listing avg derivative of both
%conditions
for i=1:length(avgdiff5to100byCondition{1})
    avgdiff5to100{i}=(avgdiff5to100byCondition{1}(i)+avgdiff5to100byCondition{2}(i))/2;
end