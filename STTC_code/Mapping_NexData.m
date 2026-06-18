%% 此脚本将NEX文件中的神经元放电数据(spike)进行sorting并映射到对应的电极位置
% 根据变量名中的数字索引提取行号和列号，sorting后重新组织数据

%% 清空工作区和命令窗口
clc
clear 
close all

%% 设置输入和输出路径
inputDir = 'E:\MetaData\AI\test\618\';     % 原始数据路径
outputDir = 'E:\MetaData\AI\test\618\spike\';  % 保存结果路径
mkdir(outputDir);

%% 获取目录中所有mat文件
matFiles = dir(fullfile(inputDir, '*.mat'));
matFileNames = {matFiles.name};

%% 处理每个文件
for fileIdx = 1:length(matFileNames)
    % 加载当前文件数据
    currentFilePath = strcat(inputDir, matFileNames(fileIdx));
    fileData = load(currentFilePath{1,1});
    FieldNames = fieldnames(fileData);
    
    % 初始化64个电极的spike数组
    electrodeSpikes = cell(64, 1);
    
    % 处理每个变量，提取电极位置信息
    for fieldIdx = 1:length(FieldNames)
        currentField = FieldNames{fieldIdx, 1};
        
        % 跳过包含"Ref"或"StartStop"的变量
        if contains(currentField, 'Ref') || strcmp(currentField, 'StartStop')
            continue;
        end
        
        % 从变量名中提取行号和列号
        % mea60第21个字符表示行号，第20个字符表示列号
        electrodeRow = str2double(currentField(21));
        electrodeCol = str2double(currentField(20));
        
        % 提取spike数据，并做sorting
        spikeData = extractfield(fileData, currentField);
        
        % 计算电极的线性索引（64个电极的8×8网格）
        electrodeIndex = (electrodeCol - 1) * 8 + electrodeRow;
        
        % 将spike数据赋值给对应电极位置
        electrodeSpikes{electrodeIndex, 1} = spikeData;
    end
    
    % 保存处理后的结果
    outputFilePath = strcat(outputDir, 'spikes_', matFileNames(fileIdx));
    save(outputFilePath{1,1}, 'electrodeSpikes')
    
    % 显示处理进度
    fprintf('已处理文件 %d/%d: %s\n', fileIdx, length(matFileNames), matFileNames{fileIdx});
end

%% 处理完成提示
fprintf('处理完成！所有文件已保存至 %s\n', outputDir);