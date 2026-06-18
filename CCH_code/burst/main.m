clc;
clear;
close all
maindir='/Users/mengweiwei/Desktop/spike/7-21-3first-learning-L1.mat';%stimulus marker & data
a=load(maindir);
Namess=fieldnames(a);
spike=[];
for k=1:length(Namess)
%     k=2;
        Names=Namess{k,1};
        data=extractfield(a,Names);
        spike=[spike data];
end
spike=sort(spike);
spike(spike==0)=[];
N = (100:150);
Steps = 10.^(-5:.05:1.5);
HistogramISIn(spike,N,Steps)
NN=120;
isi_nn=0.032;
[Burst, SpikeBurstNumber] = BurstDetectISIn( spike, NN, isi_nn);
save ('Burst-7-21-3first-learning-L1.mat','Burst')