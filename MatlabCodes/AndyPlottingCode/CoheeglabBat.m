function CoheeglabBat
%to call both Coheeglab and subplotEeglabCoh on pairs of .set files.
%modeled after PSEeglabBatNoFisher

if isequal(input('Run laplacian (y-yes, otherwise no): ','s'),'y')
    laplacian=1;
else 
    laplacian=0;
end  

disp('Coherence plots will have no legend (change code if want legend placed)');
spectra1label='1';
spectra2label='2';
% disp('Do only one task at a time as a batch');
% spectra1label=input('Label for Spectra 1:','s');
% spectra2label=input('Label for Spectra 2:','s');

%%
%set defaults, may want to make this a separate program to keep neater
%%
    %set defaults
     freqResolution=6;
%      params.tapers=[5 9]; %need to determine in the code 
     params.fpass=[0 100]; %in Hz so that f is in Hz at the end
     params.pad=-1;
     params.err=[2 0.05];
     params.trialave=1; %can change to 0 to look at one snippet at a time.
     %if 0, then output S is frequencies x trials.
     %if 1, then output S is dimension frequencies.
    %  movingwinInSec=[5 5]; %may want to change later to unequal length trial
    %  version

     disp('Would you like to use default parameters for coherencyc?');
     disp(params);
     fprintf('Frequency Resolution %.0f Hz\n',freqResolution);
%      fprintf('    fpass (in Hz): [%.0f %.0f]\n',params.fpass(1), params.fpass(2));
    %  fprintf('    movingwin (in sec): [%.2f %.2f]\n',movingwinInSec(1),
    %  movingwinInSec(2));
     default = input('Return for yes (or n for no): ','s');
     if strcmp(default,'y') || isempty(default)
     else
         disp('define params (Return leaves as default)');
         freqRes=input('Freq Resolution: ');
         if ~isempty(freqRes)
             freqResolution=freqRes;
         end
%          p.tapers1=input('NW:');
%          if ~isempty(p.tapers1)
%              params.tapers(1)=p.tapers1;
%          end
%          p.tapers2=input('K:');
%          if ~isempty(p.tapers2)
%             params.tapers(2)=p.tapers2;
%          end
         p.pad=input('pad:');
         if ~isempty(p.pad)
             params.pad=p.pad;
         end
         p.err1=input('error type (1 theoretical, 2 jacknife):');
         if ~isempty(p.err1)
             params.err(1)=p.err1;
         end
         p.err2=input('p-value:');
         if ~isempty(p.err2)
             params.err(2)=p.err2;
         end
         fpass1=input('starting frequency of fpass:');
         if ~isempty(fpass1)
             params.fpass(1)=fpass1;
         end
         fpass2=input('ending frequency of fpass:');
         if ~isempty(fpass2)
             params.fpass(2)=fpass2;
         end

         fprintf('\nparams are now:\n');
         disp(params);
    
     end

     %plotting range determined by gui
% plottingRange=[0 100]; %for subplotEeglabCoh
% fprintf('Plotting range set at %.0f to %.0f Hz\n',plottingRange(1), plottingRange(2));
% if strcmpi(input('Change plotting frequency range? (y or Return): ','s'),'y')
%     plottingRange(1)=input('Starting value: ');
%     plottingRange(2)=input('Ending value: ');
% end
%%
%pull in files
ds=1;
PSeeg=1;
while 1; %to run multiple in a row
  
    
    if ~mod(PSeeg,2) %if is an even one result will be 0 and will skip this part
        [setfilename{PSeeg}, pathname{PSeeg}] = uigetfile('*.set', 'Select EEG to compare in plot(Cancel to not use this or previous selection)',pathname{PSeeg-1});    
        if setfilename{PSeeg}==0 %if press cancel
            PSeeg=PSeeg-2; %if don't have comparison, don't run previous either
            break;
        end
       
        PSeeg=PSeeg+1;
    
    else
        if PSeeg>2
            [setfilename{PSeeg}, pathname{PSeeg}] = uigetfile('*.set', 'Select 1st EEG file (Cancel to stop)',[pathname{PSeeg-1}]);
        else
            [setfilename{PSeeg}, pathname{PSeeg}] = uigetfile('*.set', 'Select 1st EEG file (Cancel to stop)');
        end
        if setfilename{PSeeg}==0; %if press cancel for being done
            PSeeg=PSeeg-1;
            break
        end
       
        PSeeg=PSeeg+1;
    end
  
end
  
%%
%call Coheeglab and subplotEeglabCoh on result

for jj=1:PSeeg %to run multiple in a row
    Coheeglab(setfilename{jj},pathname{jj},1,params,freqResolution);
    if ~mod(jj,2) %if an even number
      subplotEeglabCoh([setfilename{jj-1}(1:end-4) ' vs ' setfilename{jj}(1:end-4)],[setfilename{jj-1}(1:end-4) '_Lap_Coh.mat'],pwd,[setfilename{jj}(1:end-4) '_Lap_Coh.mat'],pwd,'','',0);
      %0 at end is to suppress legend in coherence plots
      clf;
      close(gcf);
    end
end
end