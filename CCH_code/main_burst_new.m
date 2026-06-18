%% 神经网络爆发活动分析
% 此脚本用于从神经元放电数据中提取和分析突触爆发活动的关键指标
% 提取的主要指标:
%   - CH_SIB (Spikes In Burst): 爆发内脉冲占总脉冲的百分比，反映神经元活动的同步性
%   - MFR (Mean Firing Rate): 平均放电率，表示神经元的活跃程度
% 使用方法：设置正确的数据路径后运行脚本
% 结果将保存在每个实验组的cch_statistical_indicators文件夹中

clc;
clear;
close all

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
        ch_sib_values = zeros(fileCount, 1);
        mfr_values = zeros(fileCount, 1);
        
        % 处理该实验组中的每个文件
        for j = 1:fileCount
            path = fullfile(subFolder, 'spike_cch', fileNames{j});
            data = load(path);
            spikes = data.electrodeSpikes;
            
            ch_burst = cell(64,1);        %每个单通道burst
            ch_spike_number = cell(64,1); %每个单通道spike
            active = zeros(64,1);         %活跃电极
            burst_start = cell(64,1);     %每个单通道burst开始时间
            burst_end = cell(64,1);       %每个单通道burst结束时间
            
            %提取单通道爆发
            ch_total_bursts = 0;
            ch_BD = [];
            ch_total_spikes = 0;
            ch_total_sib = 0;
            
            for k = 1:length(spikes)
                if ~isempty(spikes{k,1})
                    NN = 2;
                    isi_nn = 0.1;
                    %逐个提取单通道burst
                    [Burst, SpikeBurstNumber] = BurstDetectISIn(spikes{k,1}, NN, isi_nn);
                    d = find(Burst.S >= 5);
                    Burst.S = Burst.S(1,d);
                    Burst.T_end = Burst.T_end(1,d);
                    Burst.T_start = Burst.T_start(1,d);
                    
                    ch_BD = [ch_BD Burst.T_end-Burst.T_start];
                    ch_total_bursts = ch_total_bursts + length(Burst.T_start);
                    ch_total_spikes = ch_total_spikes + length(SpikeBurstNumber);
                    ch_total_sib = ch_total_sib + sum(Burst.S);
                    
                    %确定活跃电极
                    if length(Burst.T_start) >= 20
                        active(k) = 1;
                        burst_start{k,1} = Burst.T_start;
                        burst_end{k,1} = Burst.T_end;
                    end
                    
                    ch_burst{k,1} = Burst;
                    ch_spike_number{k,1} = SpikeBurstNumber;
                end
            end
            
            % 计算需要的指标
            ch_sib_values(j) = ch_total_sib / ch_total_spikes * 100;
            mfr_values(j) = ch_total_spikes / 5 / sum(active);
        end
        
        % 为该实验组创建结果表格
        resultsTable = table(fileNames, ch_sib_values, mfr_values, ...
                        'VariableNames', {'FileName', 'CH_SIB', 'MFR'});
        
        % 确保cch_statistical_indicators文件夹存在
        saveFolder = fullfile(subFolder, 'cch_statistical_indicators');
        if ~exist(saveFolder, 'dir')
            mkdir(saveFolder);
        end
        
        exp = 'cch';
        % 保存该实验组的结果
        save_filename = strcat(exp,'burst_analysis_results.mat');
        full_save_path = fullfile(saveFolder, save_filename);
        save(full_save_path, 'resultsTable');
        
        % 保存为CSV文件
        csv_filename = strcat(exp,'burst_analysis_results.csv');
        full_csv_path = fullfile(saveFolder, csv_filename);
        writetable(resultsTable, full_csv_path);
        
        disp(['实验组 ' folderName ' 的结果已保存到: ' saveFolder]);
    end
end

disp('所有实验组处理完成。');