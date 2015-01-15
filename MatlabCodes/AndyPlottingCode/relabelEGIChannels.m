function relabelEGIChannels

%just a look up table to relabel EGI channels with the 10/10 system.
%Based on HydroCelGSN_10-20. Problem is that it doesn't cover all
%electrodes and there are duplications.


Labels={'C3';'C4';'Cz';'F3';'F4';'F7';'F8';'FP1';'FP2';'FPZ';'FPZ';'FPZ';'FZ';'O1';'O2';'P3';'P4';'T5-P7';'T6-P8';'T3-T7';'T4-T8';'AF3';'AF4';'AF7';'AF8';'AFZ';'C1';'C2';'C5';'C6';'CP1';'CP2';'CP3';'CP4';'CP5';'CP6';'CPZ';'F1';'F10';'F2';'F5';'F6';'F9';'FC1';'FC2';'FC3';'FC4';'FC5';'FC6';'FCZ';'FT10';'FT7';'FT8';'FT9';'OZ';'P1';'P9';'P10';'P2';'P5';'P6';'P9';'PO3';'PO4';'PO7';'PO8';'POZ';'PZ';'T10';'T11';'T12';'T9';'TP10';'TP7';'TP8';'TP9'};
Numbers={36;104;129;24;124;33;122;22;9;14;21;15;11;70;83;52;92;58;96;45;108;23;3;26;2;16;30;105;41;103;37;87;42;93;47;98;55;19;1;4;27;123;32;13;112;29;111;28;117;6;121;34;116;38;75;60;64;95;85;51;97;64;67;77;65;90;72;62;114;45;108;44;100;46;102;57;}