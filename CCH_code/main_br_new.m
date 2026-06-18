clc;
clear;
close all
% addpath('/Users/mengweiwei/Desktop/CritAnalysisSoftwarePackage2016-04-25')
parentFolder = 'E:\Voice_Data_Eight\20250311_Eight_CCH_export_mat\20251019';
contents = dir(parentFolder);

for i = 1:length(contents)
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        % 为每个实验组准备变量
        folderName = contents(i).name;
        subFolder = fullfile(parentFolder, folderName);
        disp(['处理实验组：' folderName]);
        
        % 获取该实验组内的文件列表
        subContents = dir(fullfile(subFolder, 'spike_con/', '*.mat'));
        fileNames = {subContents.name}';
        fileCount = length(fileNames);
        
        % 初始化结果数组
        brValues = zeros(fileCount, 1);
        brsimpleValues = zeros(fileCount, 1);
        
        % 处理该实验组中的每个文件
        for j = 1:fileCount
            path = fullfile(subFolder, 'spike_con', fileNames{j});
            d = load(path);
            spikes = d.electrodeSpikes;
            
            for r = 1:length(spikes)
                spikes{r,1} = round(spikes{r,1}*1000);
                spikes{r,1}(spikes{r,1}>300000) = [];
            end
            
            asdf2.raster = spikes;
            asdf2.binsize = 1;
            asdf2.nbins = 300000;
            asdf2.nchannels = 64;
            [br, slopevals, brsimple] = brestimate(asdf2);
            
            % 存储该文件的结果
            brValues(j) = br;
            brsimpleValues(j) = brsimple;
        end
        
        % 为该实验组创建结果表格
        resultsTable = table(fileNames, brValues, brsimpleValues, ...
                        'VariableNames', {'FileName', 'BR', 'BR_Simple'});
        
        % 确保cch_statistical_indicators文件夹存在
        saveFolder = fullfile(subFolder, 'cch_statistical_indicators');
        if ~exist(saveFolder, 'dir')
            mkdir(saveFolder);
        end
        
        % 保存该实验组的结果
        exp = 'con';
        save_filename = strcat(exp, '-br_results.mat');
        full_save_path = fullfile(saveFolder, save_filename);
        save(full_save_path, 'resultsTable');
        
        % 保存为CSV文件
        csv_filename = strcat(exp, '-br_results.csv');
        full_csv_path = fullfile(saveFolder, csv_filename);
        writetable(resultsTable, full_csv_path);
        
        disp(['实验组 ' folderName ' 的结果已保存到: ' saveFolder]);
    end
end

disp('所有实验组处理完成。');