function GCplot(showtext,Ctot,Cvec,f,filename,CS)

%plots results of GCEeglab
%originally designed to run from GCEeglab but turned to independent program


if nargin<1
    if strcmpi(input('Channel and value labels (y/n)[y]?','s'),'n')
        showtext=0;
    else
        showtext=1;
    end
end

pfrDefault=[2 40];
fprintf('Plotting range for matrix is %.0f to %.0f Hz.\n',pfrDefault(1),pfrDefault(2));


if nargin<2
    pfrValues=input('Change? (two numbers like [4 40] or return)');
    if isempty(pfrValues)
        pfrValues=pfrDefault;
    end
    GCfile=uipickfiles('Type',{'*GC.mat','*GC file'},'Prompt','Select GC file(s)');
    for ff=1:length(GCfile)
        [path filename]=fileparts(GCfile{ff});
        load(GCfile{ff},'Ctot','Cvec','f','CS');
        GCplotDo(pfrValues)
    end
else
    GCplotDo(pfrDefault)
end

%%
    function GCplotDo(pfrValues)
        pfr=f>pfrValues(1) & f<pfrValues(2);
        figure;set(gcf,'name',[filename '- GC']);
        subplot(6,4,[1 2 5 6]);
        plot(f(pfr),Ctot(pfr));axis([0 40 0 1]);
        % subplot(2,1,2);
        % set(gcf,'name',[filename '- Cvec']);
        subplot(6,4,[3 4 7 8]);
        imagesc(1:length(CS.channels),f(pfr),abs(Cvec(pfr,:)));
        set(gca,'XTick',1:length(CS.channels));
        set(gca,'XTickLabel',CS.channels);
        for jj=2:17
            subplot(6,4,jj+7);rectPlot(abs(Cvec(f==2*jj,:)),CS.channels,showtext);title(num2str(2*jj));
        %      subplot(6,4,jj+7);topoplot(abs(Cvec(f==2*jj,:)),eegp_makechanlocs(char(CS')),'electrodes','labels');title(num2str(2*jj));
        %     subplot(6,4,jj+11);topoplot(abs(Cvec(f==2*jj,:)),eegp_makechanlocs(char(CS')),'conv','off');colorbar;title(num2str(2*jj));
        end
        allowaxestogrow
    end
end