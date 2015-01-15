function h = CIplot(x1,y1,y1ci,varargin)
%function h = CIplot(x1,y1,y1ci,varargin)
%
% CIplot plots a filled area for a confidence interval around a heavy
% weight estimate.  CIplot can take multiple sets of arguments in a single
% call to plot multiple confidence intervals on the same axes.
%
% INPUTS:
%       x1, a vector of >2 x values
%       y1, a vector of >2 y values
%       y1ci, a [2 nValues] matrix of confidence interval, with one row
%           containing the upper confidence limit and the other row
%           containing the lower confidence limit
%       Additional sets of confidence limits can be plotted by passing in
%       additional doubles of y values and their confidence intervals (e.g.
%       CIplot(x1,y1,y1ci,y2,y2ci,y3,y3ci...), or by specifying additional
%       triples of x, y, and confidence intervals (e.g.
%       CIplot(x1,y1,y1ci,x2,y2,y2ci,...).
%
% OUTPUTS:
%       h, a vector of handles for the confidence limits and lines in the
%       new axis.
%
% Written by Andrew Hudson, 1/14/2005.
%
[tmp,idx] = min(size(x1));
if idx == 2, x1 = x1'; end
[tmp,idx] = min(size(y1));
if idx == 2, y1 = y1'; end
[tmp,idx] = min(size(y1ci));
if idx == 2, y1ci = y1ci'; end

args{1} = [x1(1:end) x1(end:-1:1)];
args{2} = [y1(1:end) y1(end:-1:1)];
args{3} = [y1ci(1,1:end) y1ci(2,end:-1:1)];
isaci(3) = 1;
if isempty(varargin) 
    nfills = 1; 
else
    for i = 1:length(varargin)
        [tmp,midx(i+3)] = min(size(varargin{i}));
        isaci(i+3) = (tmp==2);
    end
    
    nfills = length(find(isaci));
        
    count = 4;
    for i = 1:length(varargin)
        if (midx(i+3) == 2) varargin{i} = varargin{i}'; end;
        if ~isaci(i+3)
            if isaci(i+2) & isaci(i+4)
                args{count} = args{1};
                args{count+1} = [varargin{i}(1:end) varargin{i}(end:-1:1)];
                count = count+2;
            else
                args{count} = [varargin{i}(1:end) varargin{i}(end:-1:1)];
                count = count+1;
            end
        else
            args{count} = [varargin{i}(1,1:end) varargin{i}(2,end:-1:1)];
            count = count+1;
        end
    end
end;



% as a general way to make a pleasant set of transparent colors, I'd
% recommend the following:
co = get(gca,'colororder');
c = co*.8;
ci = co*.4+.4*ones(size(co));
nColors = size(co,1);
temp = co(3,:);
co(3,:) = co(1,:);
co(1,:) = temp;
clear temp;
temp = ci(3,:);ci(3,:) = ci(1,:);ci(1,:) = temp;clear temp;
temp = c(3,:);c(3,:) = c(1,:);c(1,:) = temp;clear temp;

commandstring = 'h = fill(';
ciplotidx = sort([1:3:length(args) 3:3:length(args)]);
for i=1:length(ciplotidx)
    if mod(i,2)==0
        if i<length(ciplotidx)
            commandstring = [commandstring ' args{' num2str(ciplotidx(i)) '}, ci(' num2str(mod(i/2,7)+1) ',:),'];
        else
            commandstring = [commandstring ' args{' num2str(ciplotidx(i)) '}, ci(' num2str(mod(i/2,7)+1) ',:));'];
        end
    else
        commandstring = [commandstring ' args{' num2str(ciplotidx(i)) '},'];
    end
end

eval(commandstring);
set(h,'linestyle','none','facealpha',0.5);
hold on;
for i = 1:length(args)/3
    h = [h; plot(args{(i*3)-2},args{(i*3)},'Color',ci(mod(i,7)+1,:),'LineWidth',0.5,'LineStyle','-')];
end;


%legend([repmat('y',[nfills 1]) num2str((1:nfills)')]);
% legend([num2str((1:nfills)')]);%turned off by AG, green is 1 and blue is
% 2

for i = 1:length(args)/3
    h = [h; plot(args{(i*3)-2},args{(i*3)-1},'Color',c(mod(i,7)+1,:),'LineWidth',2)];
end;

set(gca,'box','on','xgrid','on','ygrid','on');