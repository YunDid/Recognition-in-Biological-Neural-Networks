clc;
clear;
close all
% addpath('/Users/mengweiwei/Desktop/CODEs/burst/')
% 指定要遍历的文件夹路径
parentFolder = 'E:\Voice_Data_Eight\Exported_process_data_CCH\20250419';
% 获取文件夹内的文件和子文件夹列表
contents = dir(parentFolder);

% 遍历每个文件或文件夹
for i = 1:length(contents)
    % 忽略当前目录（.）和上一级目录（..）
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        % 获取子文件夹的路径
        folderName = contents(i).name;
        subFolder = fullfile(parentFolder, folderName);
        % 显示子文件夹的名称
        disp(['处理实验组：' folderName]);
        
        % 获取子文件夹内的文件列表
        subContents = dir(fullfile(subFolder, 'spike_cch', '*.mat'));
        fileNames = {subContents.name}';
        fileCount = length(fileNames);
        
        % 初始化结果数组
        percentageValues = zeros(fileCount, 1);
        
        % 处理该实验组中的每个文件
        for j = 1:fileCount
            path = fullfile(subFolder, 'spike_cch', fileNames{j});
            data = load(path);
            spikes = data.electrodeSpikes;
            
            spike = [];
            for k = 1:64
                spike = [spike spikes{k,1}];
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
            percentageValues(j) = (top15PercentCount / sum(counts)) * 100;
        end
        
        % 为该实验组创建结果表格
        resultsTable = table(fileNames, percentageValues, ...
                        'VariableNames', {'FileName', 'Percentage'});
        
        % 确保cch_statistical_indicators文件夹存在
        saveFolder = fullfile(subFolder, 'cch_statistical_indicators');
        if ~exist(saveFolder, 'dir')
            mkdir(saveFolder);
        end
        
        % 保存该实验组的结果
        exp = 'cch';
%         exp = 'cch';
        save_filename = strcat(exp, '-percentage_results.mat');
        full_save_path = fullfile(saveFolder, save_filename);
        save(full_save_path, 'resultsTable');
        
        % 保存为CSV文件
        csv_filename = strcat(exp, '-percentage_results.csv');
        full_csv_path = fullfile(saveFolder, csv_filename);
        writetable(resultsTable, full_csv_path);
        
        disp(['实验组 ' folderName ' 的结果已保存到: ' saveFolder]);
    end
end

disp('所有实验组处理完成。');