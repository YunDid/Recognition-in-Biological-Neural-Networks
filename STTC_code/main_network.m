%% Date:2024/03/24 计算网络指标
clc;
clear;
close all
addpath('H:\Experienment\Voice_code\STTC_code\BCT')
parentFolder = 'E:\MetaData\AI\20250501';
contents = dir(parentFolder);
n=0;
for i = 1:length(contents)
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        n=n+1;
        
        subFolder = fullfile(parentFolder, contents(i).name);
        disp(['子文件夹：' contents(i).name]);
        % 获取子文件夹内的文件列表
        subContents=dir(fullfile(subFolder,'sttc\','*.mat'));
        fileNamess={subContents.name};
        % 构建保存文件夹的完整路径
        savedir1=strcat(subFolder,'\sttc\network\');
        mkdir(savedir1);
        % 遍历子文件夹内的每个文件
        for j = 1:length(fileNamess)
            path=fullfile(subFolder,'sttc',fileNamess(j));
            d=load(path{1,1});
            W0=d.adjM;
            W0(isnan(W0)) = 0;
            W0(W0<0)=0;
            % 找出全零行和全零列的索引
            zero_rows = all(W0 == 0, 2); % 找出全零行的索引
            zero_cols = all(W0 == 0, 1); % 找出全零列的索引
            W = W0(~zero_rows, ~zero_cols); % 剔除
            W1=W;
            W1(W1 < 0.35)=0;
            zero_rows = all(W1 == 0, 2); % 找出全零行的索引
            zero_cols = all(W1 == 0, 1); % 找出全零列的索引
            W1 = W1(~zero_rows, ~zero_cols); % 剔除
            %% Clustering coefficient
            C=clustering_coef_wu(W);
            C1=clustering_coef_wu(W1);
            CC(n,j)=sum(C)/length(find(C>0));
            CC(n,j+9)=sum(C1)/length(find(C1>0));
            %% Transitivity
            T(n,j)=transitivity_wu(W);
            T(n,j+9)=transitivity_wu(W1);
            %% Modularity
            [Ci,Q]=modularity_und(W);
            [Ci1,Q1]=modularity_und(W1);
            
            M(n,j)=Q;
            M(n,j+9)=Q1;
            %% Global efficiency
            Eglob(n,j) = efficiency_wei(W); 
            Eglob(n,j+9) = efficiency_wei(W1); 
            %% Characteristic path length
            L = weight_conversion(W, 'lengths');
            L1 = weight_conversion(W1, 'lengths');
            D = distance_wei(L);
            D1= distance_wei(L1);
            CPL(n,j) = sum(sum(D))/(length(C)*(length(C)-1));
            CPL( n,j+9) = sum(sum(D1))/(length(C)*(length(C)-1));
            %% Small word
            NEglob=zeros(100,1);NEglob1=zeros(100,1);
            NCC=zeros(100,1);NCC1=zeros(100,1);
            NCPL=zeros(100,1);NCPL1=zeros(100,1);
            NW=cell(100,1);NW1=cell(100,1);
%             for g=1:100
%                 W00 = null_model_und_sign(W,20,0.1);
%                 NW{g,1}=W00;
%                 NEglob(g,1)=efficiency_wei(W00);
%                 NC=clustering_coef_wd(W00);
%                 NCC(g,1)=mean(NC);
%                 NL=weight_conversion(W00, 'lengths');
%                 ND = distance_wei(NL);
%                 NCPL(g,1)=sum(sum(ND))/(length(NC)*(length(NC)-1));
% 
%                 W01 = null_model_und_sign(W1,20,0.1);
%                 NW1{g,1}=W01;
%                 NEglob1(g,1)=efficiency_wei(W01);
%                 NC1=clustering_coef_wd(W01);
%                 NCC1(g,1)=mean(NC1);
%                 NL1=weight_conversion(W01, 'lengths');
%                 ND1 = distance_wei(NL1);
%                 NCPL1(g,1)=sum(sum(ND1))/(length(NC1)*(length(NC1)-1));
%                 disp(g)
%             end
            savepath= strcat(savedir1,'rand-network-',fileNamess(j));
            save(savepath{1,1},'NW','NW1')
            
            nor_Eglob(n,j)=Eglob(n,j)/mean(NEglob);
            nor_Eglob(n,j+9)=Eglob(n,j+9)/mean(NEglob1);
            sw(n,j)=(CC(n,j)/CPL(n,j))/(mean(NCC)/mean(NCPL));
            sw(n,j+9)=(CC(n,j+9)/CPL(n,j+9))/(mean(NCC1)/mean(NCPL1));
            %% Strength
            [str] = strengths_und(W);
            [str1] = strengths_und(W1);
            %% Degree
            [deg] = degrees_und(W);
            [deg1] = degrees_und(W1);
            %% betweenness centrality
            bc = betweenness_wei(L);
            bc1 = betweenness_wei(L1);
            %% closeness centrality
            cloc = 1 ./ sum(D);
            cloc1 = 1 ./ sum(D1);   
            savepath= strcat(savedir1,'hubness-',fileNamess(j));
            save(savepath{1,1},'str','deg','bc','cloc','str1','deg1','bc1','cloc1')
        end
    end
end

%% Coefficient index
Coefficient_loc = fullfile(subFolder,'sttc\','Coefficient_index\');
mkdir(Coefficient_loc);

savepath2=strcat(Coefficient_loc,'clustering-coefficient.xlsx');
writematrix(CC, savepath2);
savepath2=strcat(Coefficient_loc,'transitivity.xlsx');
writematrix(T, savepath2);
savepath2=strcat(Coefficient_loc,'modularity.xlsx');
writematrix(M, savepath2);
savepath2=strcat(Coefficient_loc,'characteristic-path-length.xlsx');
writematrix(CPL, savepath2);
savepath2=strcat(Coefficient_loc,'small-word.xlsx');
writematrix(sw, savepath2);
savepath2=strcat(Coefficient_loc,'global-efficiency.xlsx');
writematrix(nor_Eglob, savepath2);