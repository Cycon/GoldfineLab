% cofl_pcaeivs_demo:  extract eivs of principal components from a data file written
% by cofl
%
if ~exist('fns')
    fns=cell(0);
    fns{1}.name='D:\Data\clnd\cofl_IN301_zoffx_e.mat';
    fns{1}.label='off';
    fns{2}.name='D:\Data\clnd\cofl_IN301_zon_e.mat';
    fns{2}.label='on';
end
nds=length(fns);
if getinp('1 to start from scratch','d',[0 1],double(~exist('coh')));
    coh=cell(0);
    pca_label=cell(0);
    for ids=1:length(fns)
        disp(sprintf(' condition %1.0f (label=%8s; name=%s)',...
            ids,fns{ids}.label,fns{ids}.name));
        r=getfield(load(fns{ids}.name,'results'),'results');
        coh{ids}.labels=r{1}.cohgram.labels; %electrode labels
        npairs=size(r{1}.cohgram.pca,1);
        if (ids==1) %assumes all files have the same kinds of pca analyses
            npcas=size(r{1}.cohgram.pca,2);
            for ipca=1:npcas
                pca_label{ipca}=r{1}.cohgram.pca{1,ipca}.pca_label;
            end
        end
        if (ids>1)
            if ~(size(r{1}.cohgram.pca,2)==npcas)
                disp('pca types are not compatible across datasets.');
            end
        end
        coh{ids}.freqs=r{1}.cohgram.freqs;
        for ipair=1:npairs
            for ipca=1:npcas
                coh{ids}.eivs{ipca}(:,ipair)=r{1}.cohgram.pca{ipair,ipca}.s;
            end
        end
        nsurrs=length(r{1}.cohgram_surrogates);
        for isurr=1:nsurrs
            for ipair=1:npairs
                for ipca=1:npcas
                    coh{ids}.eivs_surr{ipca}(:,ipair,isurr)=...
                        r{1}.cohgram_surrogates{isurr}.pca{ipair,ipca}.s;
                end
            end
        end
        disp('coherence pca eivs extracted.');
    end
    clear r
end
for ipca=1:npcas
    disp(sprintf('%2.0f-> pca type %s',ipca,pca_label{ipca}));
end
pca_list=getinp('pca types to run','d',[1 npcas],11);
npcs=getinp('number of pc''s to analyze','d',[1 10],10);
fstring=cat(2,' %14s ',repmat('%7.4f ',1,npcs));
for kpca=1:length(pca_list)
    ipca=pca_list(kpca);
    for ids=1:length(fns)
        disp(sprintf('pca type %s;  file desc: %s',pca_label{ipca},fns{ids}.label));
        disp(sprintf('data: top %2.0f eigenvalues for individual pairs',npcs));
        %look at fraction power explained
        eivs_data=coh{ids}.eivs{ipca};
        eivs_surr=coh{ids}.eivs_surr{ipca};
        nsurrs=size(eivs_surr,3);
        for ifsurr=0:1
            if (ifsurr==0)
                eivs=eivs_data;
                disp('data');
            end
            if (ifsurr==1)
                eivs=mean(eivs_surr,3);
                disp(sprintf('mean of %4.0f surrogates',nsurrs));
            end
            for ipair=1:npairs
                disp(sprintf(fstring,coh{ids}.labels{ipair},eivs(1:npcs,ipair)/sum(eivs(:,ipair))));
            end
            disp(sprintf(fstring,'weighted mean',mean(eivs(1:npcs,:),2)/sum(mean(eivs(:,:),2))));
        end
        % compare with surrogates, after normalizing for size
        disp(sprintf('freq that data value exceeds %4.0f surrogates',nsurrs))
        eivs=eivs_data./repmat(sum(eivs_data,1),[size(eivs_data,1) 1]);
        eivs_compare=eivs_surr./repmat(sum(eivs_surr,1),[size(eivs_surr,1) 1 1]);
        fbigger=sum(double(repmat(eivs,[1 1 nsurrs])>eivs_compare),3)/nsurrs;
        for ipair=1:npairs
            disp(sprintf(fstring,coh{ids}.labels{ipair},fbigger(1:npcs,ipair)));
        end
    end
end
