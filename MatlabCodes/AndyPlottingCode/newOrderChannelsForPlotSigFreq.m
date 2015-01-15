function [ChannelOrder,spaces]=newOrderChannelsForPlotSigFreq(ChannelList)

%simple script to place reorder list for plotSigFreqSimple so that if I
%update the plotting code don't need to redo this part for other users with
%different lists.

if length(ChannelList)==37
    ChannelOrder={'AF7','F7','FC5','T3','CP5','T5','PO7','Fp1', 'F3','F1','FC1','C3','CP1','P3','O1','FPz','Fz','Cz','CPz','Pz','POz','Oz','Fp2','F4','F2','FC2','C4','CP2','P4','O2','AF8','F8','FC6','T4','CP6','T6','PO8'};
    spaces=[8 16 23 31];
    %         ChannelOrder={'FPz','Fp1','Fp2','AF7','AF8','F7','F3','F1','Fz','F2','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CPz','CP2','CP6','T5','P3','Pz','P4','T6','PO7','O1','POz','Oz','O2','PO8'};
elseif length(ChannelList)==40 && strcmpi(ChannelList{40},'AccZ') %if EMU40+18 with accelerometer at the end
    ChannelOrder={'AF7','F7','FC5','T3','CP5','T5','PO7','Fp1', 'F3','F1','FC1','C3','CP1','P3','O1','FPz','Fz','Cz','CPz','Pz','POz','Oz','Fp2','F4','F2','FC2','C4','CP2','P4','O2','AF8','F8','FC6','T4','CP6','T6','PO8','AccX','AccY','AccZ'};
    spaces=[8 16 23 31 38];
elseif length(ChannelList)==29
    ChannelOrder={'AF7','F7','FC5','T3','CP5','T5','Fp1','F3','FC1','C3','CP1','P3','O1','Fz','Cz','Pz','Fp2','F4','FC2','C4','CP2','P4','O2','AF8','F8','FC6','T4','CP6','T6'};
    spaces=[7 14 24];
    %         ChannelOrder={'Fp1','Fp2','AF7','AF8','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T3','C3','Cz','C4','T4','CP5','CP1','CP2','CP6','T5','P3','Pz','P4','T6','O1','O2'};
elseif length(ChannelList)==35
    if sum(strcmpi('F1',ChannelList)==1)%if F1 is in the dataset, assume AF7 and AF8 are out
        ChannelOrder={'F7','FC5','T3','CP5','T5','PO7','Fp1', 'F3','F1','FC1','C3','CP1','P3','O1','FPz','Fz','Cz','CPz','Pz','POz','Oz','Fp2','F4','F2','FC2','C4','CP2','P4','O2','F8','FC6','T4','CP6','T6','PO8'};
        spaces=[7 15 22 30]; %locations to put an extra line above (labels start from top of screen)
    else %assume F1 and F2 are out
        ChannelOrder={'AF7','F7','FC5','T3','CP5','T5','PO7','Fp1', 'F3','FC1','C3','CP1','P3','O1','FPz','Fz','Cz','CPz','Pz','POz','Oz','Fp2','F4','FC2','C4','CP2','P4','O2','AF8','F8','FC6','T4','CP6','T6','PO8'};
        spaces=[8 15 22 29];
    end
elseif length(ChannelList)==129 
    %then automatically create the ordering
    %first column will be everything to the left of E26 which is Y= 4.0918
    %so want things with greater Y values (Y is left right and X is up
    %down!).
    %second column will be things between 0 and 4.0918
    %fourth is E2 and right which is Y=-5.2918
    cv=pop_readlocs('GSN-HydroCel-129.sfp');
    cv=cv(4:end);
    labels={cv.labels};
    X=[cv.X];
    Y=[cv.Y];
    left=labels(Y>=4.0918);Xn=X(Y>=4.0918);
    [x,i]=sort(Xn,'descend');
    left=left(i);
    leftmid=labels(Y>0.001 & Y<4.0918);Xn=X(Y>0 & Y<4.0918);
    [x,i]=sort(Xn,'descend');
    leftmid=leftmid(i);
    midline=labels(Y>-0.001 & Y<0.001);Xn=X(Y==0);%some posterior channels just off of midline
    [x,i]=sort(Xn,'descend');
    midline=midline(i);
    rightmid=labels(Y<0.001 & Y>-5.2918);Xn=X(Y<0 & Y>-5.2918);
    [x,i]=sort(Xn,'descend');
    rightmid=rightmid(i);
    right=labels(Y<=-5.2918);Xn=X(Y<=-5.2918);
    [x,i]=sort(Xn,'descend');
    right=right(i);
    ChannelOrder=[left leftmid midline rightmid right];
    spaces=cumsum([length(left)+1 length(leftmid) length(midline) length(rightmid)]);

else
    fprintf('Unable to match number of channels with channel list for reordering')
    ChannelOrder=ChannelList;
    spaces=[];
end