function runCCA(ALLEEG)

%type runCCA(ALLEEG(1))
numSnippets=size(ALLEEG(1).data,3);
numChannels=size(ALLEEG(1).data,1);
for e=1:numSnippets %for each snippet
    [sources{e},w_x{e},autocor{e}]= EMGsorsep(ALLEEG(1).data(:,:,e));
    snippet{e}=EMGscrol(ALLEEG(1).data(:,:,e),sources{e},w_x{e});
    %run power spectra, use PSsavename to find file to plot later (?) and
    %to get ratio.
    [S{e},f{e},PSsavename{e}]=runEeglabSpectra(ALLEEG,'c',sources{e},[ALLEEG.setname '_' num2str(e)]);
    
    opt.femg=15;
    opt.fs=ALLEEG.srate;
    opt.ratio=5;
    opt.range=[0 numChannels]; %allow to remove all components to see
    [index{e},I{e}]=emg_psd(sources{e},opt);

    %remove all components bigger than the minimum one from snippet
    %snippets get cleaner as they get bigger
    %[] better to just create the one I want!
    EMGrange=(f{e}>=15 & f{e}<=100);
    EEGrange=(f{e}>=5 & f{e}<=10);
    %S is a cell containing data x component
    for s=1:numChannels
        isEMG{e}(s)=mean(S{e}(EMGrange',s))>=mean(S{e}(EEGrange',s));
    end
    numlist=[1:numChannels];
    componentsToRemove{e}=numlist.*isEMG{e};
    % choose the lowest component number (not =0)
    versionToUse{e}=numChannels-min(componentsToRemove{e}(componentsToRemove{e}>0))+1; 
    automatedfinaldata{e}=snippet{e}{versionToUse{e}};
    
%     versionToUse{e}=numChannels-min(index{e});
%     automatedfinaldata{e}=snippet{e}{(numChannels-min(index{e}))+1};
end

automatedfinaleeglab=cell2mat(automatedfinaldata);
save('sourcestesting','sources','w_x','autocor','index','I','automatedfinaleeglab','versionToUse');
% command=sprintf('EEG = pop_importdata('dataformat','array','data','eeg%.0f','setname','eeg%.0f','srate',256,'pnts',2559,'xmin',0,'nbchan',0,'chanlocs','{ ALLEEG(1).chanlocs ALLEEG(1).chaninfo ALLEEG(1).urchanlocs }')',et,et);
%%
%run power spectra so can exclude ones with lots of high power like in
%paper



%%

%next want to look at one snippet and popup one version at a time and then
%choose the version (save the number of the version). Then at end pick the
%versions from all, make all the same length, and import to eeglab as a new
%eeg with cca cleaned at the end.

%open figures
%  eegfig=figure;
%  set(eegfig,'Position',[500 300 800 500]); %Left Bottom Width Height

%setup control figure
controlFigure=figure;
setappdata(controlFigure,'finalchoice',ones(1,length(snippet)));
set(controlFigure,'Name','Choose from CCA','Units','normalized','Position',[0 0.2 0.2 0.7]);
% finaldata=cell(1,length(snippet)); % can't figure out how to modify this
uicontrol('Style','text','String','Snippet #:','Units','normalized','FontSize',12,'Position',[0 0.9 0.3 0.05],'BackgroundColor',[1 1 1]);
snippetBox=uicontrol('Style','edit','String',1,'Units','normalized','FontSize',12,'Position',[0.3 0.9 0.2 0.05],'BackgroundColor',[1 1 1],'Callback',{@ShowVersion});
uicontrol('Style','text','String','Version #:','Units','normalized','FontSize',12,'Position',[0 0.6 0.3 0.05],'BackgroundColor',[1 1 1]);
versionBox=uicontrol('Style','edit','String',1,'Units','normalized','FontSize',12,'Position',[0.3 0.6 0.2 0.05],'BackgroundColor',[1 1 1]);
% uicontrol('Style','text','String','PS plotting range:','Units','normalized','FontSize',12,'Position',[0 0.3 0.3 0.2],'BackgroundColor',[1 1 1]);
% psBox=uicontrol('Style','edit','String',3,'Units','normalized','FontSize',12,'Position',[0.3 0.3 0.2 0.1],'BackgroundColor',[1 1 1]);
uicontrol('Units','normalized','Position',[0.7 0.5 0.2 0.1],'String','Plot','FontSize',12,'Callback',{@Plot_callback});
uicontrol('Units','normalized','Position',[0.7 0.3 0.2 0.1],'String','Choose','FontSize',12,'Callback',{@Choose_callback});
uicontrol('Units','normalized','Position',[0.7 0 0.2 0.1],'String','Done','FontSize',12,'Callback',{@Done_callback});

    columninfo.titles={'Snippet','Version'};
    columninfo.formats={'%.0f','%.0f'};
    columninfo.weight=[1, 1];
    columninfo.multipliers=[1, 1];
    columninfo.isEditable =  [ 0, 1];
    columninfo.isNumeric =   [ 1,  1];
    columninfo.withCheck = false; % optional to put checkboxes along left side
    rowHeight = 5;
    gFont.size=9;
    gFont.name='Helvetica';
    tbl = axes('Units','normalized','position', [.1 .1 .4 .4]);
    cell_data{1}=0;
    cell_data=repmat(cell_data,length(snippet),2);
%     mltable(controlFigure,tbl,'CreateTable',columninfo, rowHeight, cell_data, gFont);
% 
% mltable(controlFigure,tbl,'CreateTable',columninfo, rowHeight, cell_data, gFont);
% finaldata=cell(1,length(snippet));
uiwait

    function ShowVersion(varargin) %when pick snippet, change version to show automated choice
        snippetChoice=str2num(get(snippetBox,'String'));
        set(versionBox,'String',versionToUse{snippetChoice});
        uiresume
    end

function Plot_callback(varargin)
    snippetToPlot=str2double(get(snippetBox,'String'));
    versionToPlot=str2double(get(versionBox,'String'));
    
%     close(findobj('type','figure','tag','EEGPLOT')); %only closes it if it exists
    uiresume
    ploteegplot(snippetToPlot,versionToPlot);%run code below
    
end

     function ploteegplot(snippetToPlot,versionToPlot)
    %         figure(eegplotFigHandle);
            close(findobj('type','figure','tag','EEGPLOT')); %only closes it if it exists
            data=snippet{snippetToPlot}{versionToPlot};
            eegplot(data,'srate',ALLEEG.srate,'position',[500 300 800 500],...
                'winlength',size(snippet{snippetToPlot}{versionToPlot},2)/ALLEEG.srate,'spacing',1000);
     end

%need to get the info out of this and store it somewhere (in the control
%figure?)
function Choose_callback(src, eventdata)
    snippetToUse=str2double(get(snippetBox,'String'));
    versionToUse=str2double(get(versionBox,'String'));
    uiresume
%     setappdata(controlFigure,'finaldata1',versionToUse);
%     disp(finaldata);
    choice=getappdata(controlFigure,'finalchoice');
    choice(snippetToUse)=versionToUse;
    disp(choice);
    setappdata(controlFigure,'finalchoice',choice);
%     tabledata=get(tbl,'UserData');
%     tabledata.data{2,2}=2;
%     tabledata.userModified(1,2)=2;
%     set(tbl,'UserData',tabledata);
%     endfcn = sprintf('mltable(%14.13f, %14.13f, ''SetCellValue'');', hObject, handles.tblParams);
%     set(hObject,'buttondownfcn',endfcn);
%     mltable(controlFigure,tbl,'SetCellValue');
%     mltable(controlFigure,tbl,'CreateTable',columninfo, rowHeight, cell_data, gFont);
%     cell_data{snippetToUse,2}=versionToUse;
    
end

function Done_callback(varargin)
    finalchoice=getappdata(controlFigure,'finalchoice');
    disp(finalchoice);
    for fd=1:length(snippet)
        finaldata{fd}=snippet{fd}{finalchoice(fd)};
        numdata(fd)=size(finaldata{fd},2);
    end
    %make all same length
    mindata=min(numdata);
    for fd=1:length(snippet)
        finaldata{fd}=finaldata{fd}(:,1:mindata);
    end
    finaleeglab=cell2mat(finaldata);
    uiresume
    %here need to make finaldata into an eeg and import it
    EEG = pop_importdata('dataformat','array','data',finaleeglab,...
    'setname',[ALLEEG.setname '_CCA'],'srate',ALLEEG.srate,'subject','1','pnts',mindata,'xmin',0,'nbchan',0,'chanlocs',ALLEEG.chanlocs,'ref','averef');
    EEG = eeg_checkset( EEG );
    savename=[ALLEEG.setname '_CCA.set'];
    currentFolder = pwd;
    EEG = pop_saveset( EEG, 'filename',savename,'filepath',currentFolder); %not sure about filepath, could be ./ or .
    EEG = eeg_checkset( EEG );
    eeglab redraw
end

   
end