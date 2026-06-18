%% 神经网络连接枢纽(Hub)节点分析脚本
% 此脚本用于计算神经网络中的Hub节点，基于多种中心性指标的全局评分
% 计算方法：
%   1. 合并所有文件的数据进行全局排序，确定全局阈值
%   2. 对每个文件分别计算节点的Hub得分
%   3. 计算每个文件中所有节点的平均Hub得分
%   4. 将结果保存为Excel表格，便于后续分析
% 
% 日期：2024/03/24
% 作者：Original code modified
clc;
clear;
close all
% addpath('/Users/mengweiwei/Desktop/code_final/STTC/BCT/2019_03_03_BCT/')
parentFolder = 'K:\ZY\Voice_Data_Eight\20250316\';
contents = dir(parentFolder);
for i = 1:length(contents)
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        subFolder = fullfile(parentFolder, contents(i).name);
        disp(['处理实验组：' contents(i).name]);
        
        % 获取子文件夹内的文件列表
        subContents = dir(fullfile(subFolder, 'sttc/hubness', '*.mat'));
        fileNames = {subContents.name}';
        fileCount = length(fileNames);
        
        % 创建保存结果的文件夹
        saveDir = fullfile(subFolder, 'sttc/hubness/result/');
        if ~exist(saveDir, 'dir')
            mkdir(saveDir);
        end
        
        % 初始化数据合并变量
        allStr = [];
        allDeg = [];
        allCloc = [];
        allEloc = [];
        allData = cell(fileCount, 1);
        
        % 第一轮循环：收集所有数据
        for j = 1:fileCount
            path = fullfile(subFolder, 'sttc/hubness', fileNames{j});
            data = load(path);
            allData{j} = data;
            
            % 合并数据
            allStr = [allStr, data.str];
            allDeg = [allDeg, data.deg];
            allCloc = [allCloc, data.cloc];
            
            % 确保eloc维度一致
            if size(data.eloc, 1) > size(data.eloc, 2)
                allEloc = [allEloc, data.eloc'];
            else
                allEloc = [allEloc, data.eloc];
            end
        end
        
        % 计算平均连接强度
        allMeanStr = allStr ./ allDeg;
        
        % 全局排序确定阈值
        sortedStr = sort(allMeanStr, 'descend');
        sortedCloc = sort(allCloc, 'descend');
        sortedEloc = sort(allEloc, 'descend');
        
        % 计算全局阈值
        globalThreshold = round(0.4 * length(allMeanStr));
        strThreshold = sortedStr(globalThreshold);
        clocThreshold = sortedCloc(globalThreshold);
        elocThreshold = sortedEloc(globalThreshold);
        
        % 初始化结果数组
        avgScores = zeros(fileCount, 1);
        
        % 第二轮循环：使用全局阈值对每个文件计算得分
        for j = 1:fileCount
            data = allData{j};
            
            % 计算各个中心性指标
            mean_str = data.str ./ data.deg;  % 平均连接强度
            cloc = data.cloc;                % 局部效率
            eloc = data.eloc;                % 临近中心性
            
            % 确保eloc维度一致
            if size(eloc, 1) > size(eloc, 2)
                eloc = eloc';
            end
            
            % 使用全局阈值计算每个节点是否为高值节点
            a1 = (mean_str >= strThreshold) * 1;
            b1 = (cloc >= clocThreshold) * 1;
            c1 = (eloc >= elocThreshold) * 1;
            
            % 计算每个节点的总得分(0-3分)
            hubScores = a1 + b1 + c1;
            
            % 计算平均得分
            numNodes = length(mean_str);
            activeNodes = numNodes - sum(data.zero_rows);
            avgScore = sum(hubScores) / activeNodes;
            avgScores(j) = avgScore;
            
            % 保存单个文件的结果
            singleFileResult = struct('ele', data.zero_rows, 'hub', hubScores);
            singleSavePath = fullfile(saveDir, ['hub_result_', fileNames{j}]);
            save(singleSavePath, '-struct', 'singleFileResult');
        end
        
        % 创建结果表格
        resultsTable = table(fileNames, avgScores, 'VariableNames', {'FileName', 'AverageHubScore'});
        
        % 保存为Excel文件
        excelPath = fullfile(saveDir, 'hub_analysis_results.xlsx');
        writetable(resultsTable, excelPath, 'Sheet', 'HubScores');
        
        disp(['实验组 ' contents(i).name ' 的结果已保存到: ' saveDir]);
    end
end
disp('所有实验组处理完成。');