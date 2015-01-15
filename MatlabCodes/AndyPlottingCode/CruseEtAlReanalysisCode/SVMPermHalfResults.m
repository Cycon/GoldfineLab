function SVMPermHalfResults

%to display results from SVMcode with permutationHalf chosen
%column of classification, number accurate for each block, total trials.
%Top is original list

pathname=uipickfiles('type',{'*f_SVM.mat','halfperm file'});

if isnumeric(pathname)
    return
end

filename=pathname;
for p=1:length(pathname)
    [~, filename{p}]=fileparts(pathname{p});
end

for p2=1:length(pathname)
    s=load(pathname{p2},'finalaccu','finalaccuPM','numaccu','numaccuPM','block','blockdrop','allaccs');
    if ~isfield(s,'blockdrop')
        s.blockdrop=0;
    end
    pvalues=myBinomTest([sum(s.numaccu) sum(s.numaccuPM,2)'],[length(s.allaccs) repmat(length(s.block),1,size(s.numaccuPM,1))],0.5,'Two');%list of p-values with two-sided binocdf.
    overall{p2}=sprintf('\n%s in %.0f trials. %.0f of %.0f permutations are <=0.05\n',filename{p2},length(s.block),sum(pvalues(2:end)<=0.05),size(s.numaccuPM,1));
    fprintf('%s',overall{p2});
    if s.blockdrop>0
        fprintf('**block %.0f dropped for perm. since odd number of blocks.**\n',s.blockdrop);
    end
    fprintf('Perc correct   p-value      \t \tNum accurate per block\n');
    if s.blockdrop %if any blocks dropped
        s.numaccuPM=[s.numaccuPM nan(size(s.numaccuPM,1),1)];
    end
    %     matrix=([s.finalaccu round(s.numaccu);round(s.finalaccuPM) round(s.numaccuPM)]);
    
    %first line is the original
    fprintf('%.2f\t\t',s.finalaccu);
    fprintf('%.2g\t \t \t',pvalues(1));
    fprintf('%.0f\t',s.numaccu);
    if pvalues(1)<=0.05
        fprintf(' *');
    end
    if pvalues(1)<=0.01
        fprintf('*');
    end
    if pvalues(1)<=0.001
        fprintf('*');
    end
    fprintf('\n');
    
    %remainder of lines are the permuted versions. Each on different line
    %of code otherwise will run through all the blocks using the 0.2f of
    %the percent accuracy.
    for jk=1:size(s.numaccuPM,1)
        fprintf('%.2f\t \t',s.finalaccuPM(jk));%percent accuracy
        fprintf('%.2g\t \t \t',pvalues(jk+1));%start at second one. Want g since can be very small number
        fprintf('%.0f\t',s.numaccuPM(jk,:));
        if pvalues(jk+1)<=0.05
            fprintf(' *');
        end
        if pvalues(jk+1)<=0.01
            fprintf('*');
        end
        if pvalues(jk+1)<=0.001
            fprintf('*');
        end
        fprintf('\n');
    end
    
    %
    %     fprintf('%.1f \t\t %.0f \t %.0f ',s.finalaccu,length(s.block),[s.numaccu]);
    %     fprintf('\n \n');%so return is after all the numaccu spit out
    %     for p3=1:size(s.numaccuPM,1)
    %         fprintf('%.1f \t\t %.0f \t %.0f ',s.finalaccuPM(p3),length(s.block),s.numaccuPM(p3,:));
    %         fprintf('\n');
    %     end
end

for p4=1:length(overall)
    fprintf('%s',overall{p4});
end
