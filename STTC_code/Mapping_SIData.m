%% 将神经元排序结果映射到电极位置
% 该脚本将SpikeInterface排序结果映射到对应的电极通道
% 处理步骤：
% 1. 加载排序结果和单元位置数据
% 2. 将每个神经元单元的尖峰时间点提取出来
% 3. 基于位置信息将单元映射到对应电极
% 4. 合并同一电极上的所有单元尖峰
% 5. 保存处理结果

clear
close all
clc

%% 设置路径
% 定义数据和输出目录
mainDataDir = 'E:\MetaData\AI\test\20250815\raw_h5\after_raw_h5\2025-07-04T10-03-24McsRecording_E-00224\tran\npz';          % 尖峰排序数据目录
unitLocDir = 'E:\MetaData\AI\test\20250815\raw_h5\after_raw_h5\2025-07-04T10-03-24McsRecording_E-00224\tran\npy'; % 单元位置数据目录
outputDir = 'E:\MetaData\AI\test\20250815\raw_h5\after_raw_h5\2025-07-04T10-03-24McsRecording_E-00224\tran\spike\';          % 输出结果目录

% 创建输出目录(如果不存在)
mkdir('E:\Voice_Data_Eight\Voice_data_export\20250208_0117C1_Con\Con-onlyPDMS\Sti\spike\')

%% 获取文件列表
dataFiles = dir(fullfile(mainDataDir, '*.mat'));
locFiles = dir(fullfile(unitLocDir, '*.mat'));

dataFileNames = {dataFiles.name};
locFileNames = {locFiles.name};

%% 定义电极位置坐标矩阵 (8x8电极阵列，单位：微米)
% 行1：X坐标；行2：Y坐标
electrodePositions = [
    0,   0,   0,   0,   0,   0,   0,   0,...
    200, 200, 200, 200, 200, 200, 200, 200,...
    400, 400, 400, 400, 400, 400, 400, 400,...
    600, 600, 600, 600, 600, 600, 600, 600,...
    800, 800, 800, 800, 800, 800, 800, 800,...
    1000,1000,1000,1000,1000,1000,1000,1000,...
    1200,1200,1200,1200,1200,1200,1200,1200,...
    1400,1400,1400,1400,1400,1400,1400,1400;...
    1400,1200,1000,800, 600, 400, 200, 0,...
    1400,1200,1000,800, 600, 400, 200, 0,...
    1400,1200,1000,800, 600, 400, 200, 0,...
    1400,1200,1000,800, 600, 400, 200, 0,...
    1400,1200,1000,800, 600, 400, 200, 0,...
    1400,1200,1000,800, 600, 400, 200, 0,...
    1400,1200,1000,800, 600, 400, 200, 0,...
    1400,1200,1000,800, 600, 400, 200, 0
];

%% 处理每个文件
fprintf('开始处理 %d 个文件...\n', length(dataFileNames));

for fileIdx = 1:length(dataFileNames)
    %% 加载数据
    dataFilePath = fullfile(mainDataDir, dataFileNames{fileIdx});
    locFilePath = fullfile(unitLocDir, locFileNames{fileIdx});
    
    fprintf('处理文件 %d/%d: %s\n', fileIdx, length(dataFileNames), dataFileNames{fileIdx});
    
    % 加载尖峰数据和单元位置数据
    spikeData = load(dataFilePath);
    locationData = load(locFilePath);
    
    % 提取尖峰索引和标签
    spikeIndices = spikeData.spike_indexes_seg0;  % 尖峰时间索引
    spikeLabels = spikeData.spike_labels_seg0;    % 尖峰所属单元标签
    unitIds = spikeData.unit_ids;                 % 单元IDs
    unitLocations = locationData.unit_locations';  % 单元位置坐标 (转置为2xN)
    
    %% 提取每个单元的尖峰时间
    numUnits = length(unitIds);
    unitSpikes = cell(numUnits, 1);  % 存储每个单元的尖峰时间
    
    for unitIdx = 1:numUnits
        currentUnitId = unitIds(unitIdx);
        
        % 找出当前单元的所有尖峰索引
        unitSpikeIndices = spikeIndices(spikeLabels == currentUnitId);
        
        % 将尖峰时间转换为毫秒
        unitSpikes{unitIdx} = round(unitSpikeIndices / 25);
        
        % 只保留前5分钟的数据 (300000个样本)
        unitSpikes{unitIdx}(unitSpikes{unitIdx} > 300000) = [];
        
        % 转换为浮点数并转换单位为秒
        unitSpikes{unitIdx} = double(unitSpikes{unitIdx}) / 1000;
    end
    
    %% 将单元映射到电极
    numLocations = size(unitLocations, 2);
    unitElectrodes = zeros(numLocations, 1);  % 存储每个单元对应的电极索引
    
    for locIdx = 1:numLocations
        % 获取当前单元的位置坐标
        xPos = unitLocations(1, locIdx);
        yPos = unitLocations(2, locIdx);
        
        % 在电极位置矩阵中查找匹配的位置
        electrodeIdx = find(electrodePositions(1, :) == xPos & electrodePositions(2, :) == yPos);
        
        % 记录电极索引
        unitElectrodes(locIdx) = electrodeIdx;
    end
    
    %% 合并同一电极上的所有单元尖峰
    numElectrodes = 64;  % 8x8电极阵列
    electrodeSpikes = cell(numElectrodes, 1);  % 存储每个电极的尖峰时间
    
    for electrodeIdx = 1:numElectrodes
        % 找出映射到当前电极的所有单元
        unitsOnElectrode = find(unitElectrodes == electrodeIdx);
        
        if ~isempty(unitsOnElectrode)
            % 合并所有单元的尖峰时间
            allSpikes = [];
            
            for unitIdx = 1:length(unitsOnElectrode)
                currentUnitSpikes = unitSpikes{unitsOnElectrode(unitIdx)};
                allSpikes = [allSpikes, currentUnitSpikes];
            end
            
            % 排序并去重
            allSpikes = unique(allSpikes);
            allSpikes = sort(allSpikes);
            
            % 存储合并后的尖峰时间
            electrodeSpikes{electrodeIdx} = allSpikes;
        end
        % 空电极将保持为空单元格
    end
    
    %% 保存结果
    spikes = electrodeSpikes;  % 为了保持与原代码一致的变量名
    outputFileName = ['spikes_', dataFileNames{fileIdx}];
    outputFilePath = fullfile(outputDir, outputFileName);
    
    fprintf('保存结果到: %s\n', outputFilePath);
    save(outputFilePath, 'spikes');
end

fprintf('所有文件处理完成!\n');