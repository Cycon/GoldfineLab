function [Sigscrol]=EMGscrol(sig,sources,w_x)
%
%[Sigscrol]=EMGscrol(sig,sources,w_x)
%
%  input  : [sig], EEG matrix dimension(channels x time samples);
%         : [sources], time course of the sources obtained by EMGsorsep.m;
%         : [w_x], demixing matrix obtained by EMGsorsep.m;
%  output : [Sigscrol], cell containing reconstructed EEGs based on
%                       removing one source at the time from below (ordering based
%                       on autocorrelation of the sources)
%
%© 2005 Wim De Clercq 
%Notice that the BSS-CCA software (containing EMGscrol.m and EMGsorsep.m) can be freely used for non-commercial use only. For commercial licenses, see Commercial Use. 
%The BSS-CCA software is accompanied by an Academic Public License. 
%These licenses can be found at:
%[Engels] http://www.neurology-kuleuven.be/?id=210
%[Nedederlands] http://www.neurology-kuleuven.be/?id=209
%If utilization of the BSS-CCA software results in outcomes which will be published,  
%Academic User shall acknowledge K.U.LEUVEN as the provider of the BSS-CCA software and shall 
%include a reference to [Vergult A., De Clercq W., Palmini A., Vanrumste B., Dupont P., Van Huffel S., Van Paesschen W., ``Improving the Interpretation of Ictal Scalp EEG: BSS-CCA algorithm for muscle artifact removal'', Internal Report 06-148, ESAT-SISTA, K.U.Leuven (Leuven, Belgium), 2006.] 
%and [De Clercq W., Vergult A., Vanrumste B., Van Paesschen W., Van Huffel S., ``Canonical Correlation analysis applied to remove muscle artifacts from the electroencephalogram'', Internal Report 05-116, ESAT-SISTA, K.U.Leuven (Leuven, Belgium), 2005. Accepted for publication in Transactions on Biomedical Engineering. ] in the manuscript. 

D=pinv(w_x)';
N=size(sig);
Sigscrol{1}=sig;
for i=1:N(1)
    D(:,end-i+1:end)=0;
    Sigscrol{i+1}=D*sources+(ones(N(2)-1,1)*mean(sig'))';
end