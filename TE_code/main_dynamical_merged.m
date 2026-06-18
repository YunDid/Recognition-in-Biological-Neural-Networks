%% Date:2024/03/28 动力学丰富度-merged
clc;
clear;
close all
% addpath('/Users/mengweiwei/Desktop/CODEs/BCT/2019_03_03_BCT/')
parentFolder = 'E:\Voice_Data_Eight\Voice_data_export\20250215_0117C1_HTrain_Cell1_medium\STTC';
contents = dir(parentFolder);
n=0;
for i = 1:length(contents)
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        n=n+1;
        subFolder = fullfile(parentFolder, contents(i).name);
        disp(['子文件夹：' contents(i).name]);
        % 获取子文件夹内的文件列表
        subContents=dir(fullfile(subFolder,'/te-network/','*.mat'));
        fileNamess={subContents.name};
        subContents2=dir(fullfile(subFolder,'/spike/','*.mat'));
        fileNamess2={subContents2.name};
        % 构建保存文件夹的完整路径
        %         savedir1=strcat(subFolder,'/network/');
        %         mkdir(savedir1);
        %         savedir2=strcat(subFolder,'/sttc/hubness/');
        %         mkdir(savedir2)
        % 遍历子文件夹内的每个文件
        for j = 1:length(fileNamess)
            path=fullfile(subFolder,'te-network',fileNamess(j));
            data=load(path{1,1});
            W=data.nom_connect;
            W(logical(eye(size(W)))) = NaN;
            binEdges = 0:0.01:1;
            % 使用histcounts函数计算每个区间内的数据个数
            counts = histcounts(W, binEdges);
            %     pdfValues = ksdensity(adjM, binEdges);
            % 绘制条形图显示每个区间内的个数
            %     bar(binEdges(1:end-1) + 0.025, counts, 'BarWidth', 0.9);
            %     % 设置图标题和轴标签
            %     title('Counts of Data in Intervals of 0.05');
            %     xlabel('Value');
            %     ylabel('Count');
            p=counts/(length(W)*(length(W)-1));
            a=1-(sum(abs(p-0.01)))*100/(100-1)/2;
            Corr(n,j)=a;
            
            path2=fullfile(subFolder,'spike',fileNamess2(j));
            data2=load(path2{1,1});
            spike=data2.electrodeSpikes;
            bin=0:0.1:300;
            L=[];
            b=1;
            for k=1:length(spike)
                sp=spike{k};
                if ~isempty(sp)
                    count = histcounts(sp, bin);
                    L(b,:)=count;
                    b=b+1;
                else
                end
            end
            g=L;
            %     g(g<6)=0;
            g(g ~=  0) = 1;
            c=sum(g)/b;
            binEdges2 = 0:0.05:1;
            counts2 = histcounts(c, binEdges2);
            p2=counts2/length(c);
            a2=1-(sum(abs(p2-0.05)))*20/(20-1)/2;
            spi(n,j)=a2;
            com=a*a2;
            DR(n,j)=com;
        end
    end
end