%% Date:2024/03/24 计算网络指标
clc;
clear;
close all
% addpath('/Users/mengweiwei/Desktop/code_final/STTC/BCT/2019_03_03_BCT/')
parentFolder = 'K:\Fig5_summary\TestData_0812\20250718\Cell1-2-STTC';
contents = dir(parentFolder);
n=0;
for i = 1:length(contents)
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        n=n+1;
        subFolder = fullfile(parentFolder, contents(i).name);
        disp(['子文件夹：' contents(i).name]);
        % 获取子文件夹内的文件列表
        subContents=dir(fullfile(subFolder,'/sttc/','*.mat'));
        fileNamess={subContents.name};
        % 构建保存文件夹的完整路径
        savedir1=strcat(subFolder,'/network/');
%         mkdir(savedir1);
        savedir2=strcat(subFolder,'/sttc/hubness/');
        mkdir(savedir2)
        % 遍历子文件夹内的每个文件
        for j = 1:length(fileNamess)
            path=fullfile(subFolder,'sttc',fileNamess(j));
            d=load(path{1,1});
            W0=d.adjM;
            W0(isnan(W0)) = 0;
            W0(W0<0.35)=0;
            % 找出全零行和全零列的索引
            zero_rows = all(W0 == 0, 2); % 找出全零行的索引
            zero_cols = all(W0 == 0, 1); % 找出全零列的索引
%             W = W0(~zero_rows, ~zero_cols);
            W = W0;
%             W = threshold_proportional(W, 0.8);
%             zero_rows1 = all(W == 0, 2); % 找出全零行的索引
%             zero_cols1 = all(W == 0, 1); % 找出全零列的索引
%             W = W(~zero_rows1, ~zero_cols1);
            mean_STTC(n,j) = mean(W(~eye(size(W))));
            % find high correlation: > 0.8
            HighCorr = W(W >= 0.8);
            % find medium correlation: 0.5 - 0.8
            MedCorr = W(W >= 0.5 & W < 0.8);
            % find low correlation distances: < 0.5
            LowCorr = W(W < 0.5 & W > 0);
            corr(n,3*(j-1)+1)=length(HighCorr)/length(find(W>0));
            corr(n,3*(j-1)+2)=length(MedCorr)/length(find(W>0));
            corr(n,3*(j-1)+3)=length(LowCorr)/length(find(W>0));
%             std_w = std(W(~eye(size(W))));
            %% Clustering coefficient
            C=clustering_coef_wu(W);
            
            CC(n,j)=sum(C)/length(find(C>0));
            
            %% Transitivity
            T(n,j)=transitivity_wu(W);
           
            %% Modularity
            [Ci,Q]=modularity_und(W);
            
            M(n,j)=Q;
            
            %% Global efficiency
            Eglob(n,j) = efficiency_wei(W); 
             
            %% Characteristic path length
            L = weight_conversion(W, 'lengths');
            
            [D,B] = distance_wei(L);
            
            CPL(n,j) = sum(sum(D))/(length(C)*(length(C)-1));
            
            %% Small word
%             NEglob=zeros(100,1);
%             NCC=zeros(100,1);
%             NL=zeros(100,1);
%             NW=cell(100,1);
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
%                 disp(g)
%             end
%             savepath= strcat(savedir1,'rand-network-',fileNamess(j));
%             save(savepath{1,1},'NW')
%             
%             nor_Eglob(n,j)=Eglob(n,j)/mean(NEglob);
%             
%             sw(n,j)=(CC(n,j)/CPL(n,j))/(mean(NCC)/mean(NCPL));
%             
            %% Strength
            [str] = strengths_und(W);
            
            %% Degree
            [deg] = degrees_und(W);
            
            %% betweenness centrality
            bc = betweenness_wei(L);
           
            %% closeness centrality
            cloc = 1 ./ sum(D);
            %% local efficiency
            eloc = efficiency_wei(W,2);
            
            savepath= strcat(savedir2,'hubness-',fileNamess(j));
            save(savepath{1,1},'str','deg','bc','cloc','eloc','zero_rows')
        end
%% Coefficient index        
        Coefficient_loc = fullfile(subFolder,'sttc\','sttc_Coefficient_index\');
        mkdir(Coefficient_loc);

        savepath2=strcat(Coefficient_loc,'0401-0.35-clustering-coefficient.xlsx');
        writematrix(CC, savepath2);
        savepath2=strcat(Coefficient_loc,'0401-0.35-transitivity.xlsx');
        writematrix(T, savepath2);
        savepath2=strcat(Coefficient_loc,'0401-0.35-modularity.xlsx');
        writematrix(M, savepath2);
        savepath2=strcat(Coefficient_loc,'0401-0.35-characteristic-path-length.xlsx');
        writematrix(CPL, savepath2);
        savepath2=strcat(Coefficient_loc,'0401-0.35-mean-STTC.xlsx');
        writematrix(mean_STTC, savepath2);
        savepath2=strcat(Coefficient_loc,'0401-0.35-corr.xlsx');
        writematrix(corr, savepath2);   
    end
end


% savepath2=strcat('/Users/mengweiwei/Desktop/结果/spon/network/','small-word.xlsx');
% writematrix(sw, savepath2);
% savepath2=strcat('/Users/mengweiwei/Desktop/结果/spon/network/','global-efficiency.xlsx');
% writematrix(nor_Eglob, savepath2);