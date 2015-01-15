function CIplotPS(f,varargin)
%call as: CIplotPS(f,spectra1,spectraerr1,spectra2...,[low high])
%
%Like Drew's CIplot, but automatically converts spectra and serr to dB.
%Also allows for plotting frequency range as the final argument as [low
%high].
%version 1 10/24/11 AMG

if length(varargin{end})~=2 %if user does not give a plot range
    varargin{end+1}=[f(1) f(end)];
end
pfr=f>=varargin{end}(1) & f<=varargin{end}(2);
s=varargin(1:2:end-2);
serr=varargin(2:2:end-1);
% for i=1:length(varargin)-1 %convert to dB
%     varargin{i}=10*log10(varargin{i}(pfr));
% end

colorlist={'r','b','g'};
for ns=1:(length(varargin)-1)/2 %for each spectra
        errorBars(ns)=fill([f(pfr) fliplr(f(pfr))],[10*log10(serr{ns}(1,(pfr))) fliplr(10*log10(serr{ns}(2,(pfr))))],colorlist{ns},'HandleVisibility','callback');
        hold on;
        plot(f(pfr),10*log10(s{ns}(pfr)),colorlist{ns},'LineWidth',2); 
%         set(gca,'xtick',[f(1):5:plottingRange(2)],'FontSize',12); %this sets the xticks every 5
        %     set(gca,'xtick',[plottingRange(1):3:plottingRange(2)],'FontSize',32,'Ylim',[10 40],'Xlim',plottingRange); %for paper figure
%         ylimPlot=ylim; %ylim here can be reset below to ensure negative TGT results are off the screen
        axis tight;
        grid on; %this turns grid on
        %  grid off; %JUNE 30 FOR MARY
        hold('all'); %this is for the xticks and grid to stay on
end
% set(errorBars,'linestyle','none'); %to make the fill not transparent for
% adobe
disp('Shading doesn''t work in eps so for illustrator turn it off');
set(errorBars,'linestyle','none','facealpha',0.3); %to make the fill transparent
