clc;
clear;
close all
maindir='/Users/mengweiwei/Desktop/spike/12-23-1-before-10minspon(1).mat';%stimulus marker & data
a=load(maindir);
Namess=fieldnames(a);
for k=1:length(Namess)
    %     k=1;
    rowNames=Namess{k,1};
    row = str2double( rowNames(21));
    row=num2str(row);
    column = str2double( rowNames(20));
    column=num2str(column);
    spike=extractfield(a,rowNames);
    %     N = (3:4);
    %     Steps = 10.^(-5:.05:1.5);
    %     HistogramISIn(spike,N,Steps)
    NN=3;
    isi_nn=0.1;
    [Burst, SpikeBurstNumber] = BurstDetectISIn( spike, NN, isi_nn);
    savepath=strcat(column,row,'.mat');
    save (savepath,'Burst')
end