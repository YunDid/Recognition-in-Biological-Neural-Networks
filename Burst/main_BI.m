clc;
clear;
close all
addpath('/Users/mengweiwei/Desktop/CODEs/burst/')

% 指定要遍历的文件夹路径
parentFolder = '/Users/mengweiwei/Desktop/结果/spon/cch';
% 获取文件夹内的文件和子文件夹列表
contents = dir(parentFolder);
% 遍历每个文件或文件夹
n=0;
for i = 1:length(contents)
    % 忽略当前目录（.）和上一级目录（..）
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        % 获取子文件夹的路径
        subFolder = fullfile(parentFolder, contents(i).name);
        % 显示子文件夹的名称
        disp(['子文件夹：' contents(i).name]);
        n=n+1;
        % 获取子文件夹内的文件列表
        subContents=dir(fullfile(subFolder,'spike','*.mat'));
        fileNamess={subContents.name};
        for jj=1:length(fileNamess)
            path=fullfile(subFolder,'spike',fileNamess(jj));
            data=load(path{1,1});
            spikes=data.spikes;
            spike=[];
            for k=1:64
                spike=[spike spikes{k,1}];
            end
            % 设置bin的范围和宽度
            binWidth = 1;
            binEdges = 0:binWidth:300;
            
            % 统计落入各bin内元素的个数
            [counts, ~] = histcounts(spike, binEdges);
            
            % 找出具有最大计数的前15%的bin
            sortedCounts = sort(counts, 'descend');
            top15PercentCount = sum(sortedCounts(1:ceil(0.15 * numel(sortedCounts))));
            
            % 计算具有最大计数的前15%的bin内元素占所有元素总数的百分比
            percentage(n,jj) = (top15PercentCount / sum(counts)) * 100;
        end
    end
end