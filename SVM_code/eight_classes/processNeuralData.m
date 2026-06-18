% 剔除unsorted放电数据并处理所有通道
% 此代码从原始数据中删除unsorted放电数据，并为所有通道生成处理后的数据

function processNeuralData(inputFile, outputFile)
% processNeuralData - 处理神经放电数据，剔除unsorted放电
%
% 输入:
%   inputFile - 输入MAT文件路径
%   outputFile - 输出MAT文件路径
%
% 示例:
%   processNeuralData('your_data_file.mat', 'processed_data.mat')

% 检查输入参数
if nargin < 2
    outputFile = 'processed_data.mat';
end
if nargin < 1
    error('请提供输入文件路径');
end

% 1. 加载MAT文件
try
    fprintf('加载文件: %s\n', inputFile);
    data = load(inputFile);
    fprintf('加载成功\n');
catch
    error('无法加载文件: %s\n', inputFile);
end

% 2. 创建结构体来存储处理后的数据
processedData = struct();

% 3. 获取所有字段名称
fieldNames = fieldnames(data);
fprintf('文件中共有 %d 个字段\n', length(fieldNames));

% 4. 提取和分组相关字段
% 初始化存储结构
channelGroups = struct();
stgFields = {};
refFields = {};

% 分类和组织字段
fprintf('开始分组字段...\n');
for i = 1:length(fieldNames)
    currentField = fieldNames{i};
    
    % 存储STG相关字段
    if contains(currentField, 'STG')
        stgFields{end+1} = currentField;
        continue;
    end
    
    % 存储参考电极字段
    if contains(currentField, 'ref')
        refFields{end+1} = currentField;
        continue;
    end
    
    % 提取通道ID用于分组
    [channelID, electrode] = extractChannelInfo(currentField);
    
    % 跳过无法识别的字段
    if isempty(channelID)
        fprintf('  无法识别的字段: %s\n', currentField);
        continue;
    end
    
    % 创建分组键
    groupKey = [channelID, '_', electrode];
    
    % 将字段添加到相应的组
    if ~isfield(channelGroups, groupKey)
        channelGroups.(groupKey) = struct('original', '', 'unsorted', '', 'clusters', {});
    end
    
    % 根据字段类型分类
    if contains(currentField, '_unsorted')
        channelGroups.(groupKey).unsorted = currentField;
    elseif contains(currentField, '_cluster')
        channelGroups.(groupKey).clusters{end+1} = currentField;
    elseif contains(currentField, 'cquisition') && contains(currentField, '_nr')
        channelGroups.(groupKey).original = currentField;
    end
end

% 5. 处理每个通道组
fprintf('开始处理通道数据...\n');
groupKeys = fieldnames(channelGroups);
processedChannels = 0;

for i = 1:length(groupKeys)
    groupKey = groupKeys{i};
    group = channelGroups.(groupKey);
    
    % 检查是否有必要的字段
    if isempty(group.original) || isempty(group.unsorted)
        fprintf('  跳过通道组 %s: 缺少原始数据或unsorted数据\n', groupKey);
        continue;
    end
    
    % 处理当前通道组
    fprintf('  处理通道组: %s\n', groupKey);
    
    % 获取原始数据和unsorted数据
    originalData = data.(group.original);
    unsortedData = data.(group.unsorted);
    
    % 从原始数据中剔除unsorted数据
    cleanedData = removeUnsortedSpikes(originalData, unsortedData);
    
    % 将处理后的数据保存到结果结构中
    processedData.(group.original) = cleanedData;
    
    % 保存所有cluster数据
    for j = 1:length(group.clusters)
        clusterField = group.clusters{j};
        processedData.(clusterField) = data.(clusterField);
    end
    
    % 记录处理信息
    fprintf('    原始数据大小: %d, Unsorted数据大小: %d, 处理后数据大小: %d\n', ...
        numel(originalData), numel(unsortedData), numel(cleanedData));
    
    processedChannels = processedChannels + 1;
end

% 6. 添加STG相关数据
fprintf('添加STG相关数据...\n');
for i = 1:length(stgFields)
    processedData.(stgFields{i}) = data.(stgFields{i});
end

% 7. 保存处理后的数据
try
    fprintf('保存处理后的数据到: %s\n', outputFile);
    save(outputFile, '-struct', 'processedData');
    fprintf('保存成功\n');
catch
    error('保存文件失败: %s', outputFile);
end

% 8. 输出处理摘要
fprintf('\n处理摘要:\n');
fprintf('共处理了 %d 个通道组\n', processedChannels);
fprintf('添加了 %d 个STG相关字段\n', length(stgFields));
fprintf('跳过了 %d 个参考电极字段\n', length(refFields));
end

% ===== 辅助函数 =====

function [channelID, electrode] = extractChannelInfo(fieldName)
% 从字段名中提取通道ID和电极信息
% 例如，从 "AnSt_Label_E_00159_12_ID_20_St_sition_1_Electrode_R_cluster1" 
% 提取 "12_ID_20" 和 "Electrode_R"

% 使用正则表达式匹配模式
idPattern = '(\d+_ID_\d+)';
electrodePattern = '(Electrode_R[a-z]*)';

% 提取通道ID
idTokens = regexp(fieldName, idPattern, 'tokens');
if ~isempty(idTokens)
    channelID = idTokens{1}{1};
else
    channelID = '';
end

% 提取电极信息
electrodeTokens = regexp(fieldName, electrodePattern, 'tokens');
if ~isempty(electrodeTokens)
    electrode = electrodeTokens{1}{1};
else
    electrode = '';
end
end

function cleanedData = removeUnsortedSpikes(originalData, unsortedData)
% 从原始数据中移除unsorted放电数据
% 输入:
%   originalData - 原始数据数组
%   unsortedData - 待移除的unsorted数据数组
% 输出:
%   cleanedData - 处理后的数据数组

% 确保数据是列向量
originalData = originalData(:);
unsortedData = unsortedData(:);

% 初始化结果
cleanedData = originalData;

% 使用更高效的方法移除数据
if isempty(unsortedData)
    return;  % 如果没有unsorted数据，直接返回原始数据
end

% 创建一个逻辑索引数组来标记要保留的数据点
keepIndices = true(size(originalData));

% 设置容差（用于浮点比较）
tolerance = 1e-10;

% 使用向量化操作查找匹配
% 对于每个unsorted数据点，找到它在原始数据中的位置
for i = 1:length(unsortedData)
    unsortedValue = unsortedData(i);
    
    % 找到与当前unsorted数据点匹配的原始数据点
    matchIndices = abs(originalData - unsortedValue) < tolerance;
    
    % 更新要保留的索引
    keepIndices = keepIndices & ~matchIndices;
end

% 只保留未标记的数据点
cleanedData = originalData(keepIndices);
end