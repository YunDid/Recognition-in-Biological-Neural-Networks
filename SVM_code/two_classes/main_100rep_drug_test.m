%% Date:2026/05/01 2分类 100 repeats drug test-only
% 输入数据为二次 NEX 导出的 4 个 test mat 文件。
% 分析逻辑参照八分类：4 个记录文件分别提取响应，再合并为全局 ins。
% 标签使用 MCS 实验脚本保存的 stim_labels_test，按标签划分 1/2 类。
%
% 数据文件结构：
%   parentFolder
%   └─ 某个实验样本文件夹
%      ├─ stim_labels_two_class_100rep_drug_test.mat
%      └─ drug_test_mat
%         ├─ batch1.mat
%         ├─ batch2.mat
%         ├─ batch3.mat
%         └─ batch4.mat
%
% 示例：
%   E:\Voice_Data_TwoClass_100rep\Exported_process_data
%   └─ Cell_001
%      ├─ stim_labels_two_class_100rep_drug_test.mat
%      └─ test_mat
%         ├─ test_1.mat
%         ├─ test_2.mat
%         ├─ test_3.mat
%         └─ test_4.mat
% 
% 如果实际子文件夹叫 test_mat，只需要改：
%   parentFolder = 'E:\Voice_Data_TwoClass_100rep\Exported_process_data';
%   subTestname = 'test_mat';


clc;
clear;
close all

%% 路径参数：实机数据导出后主要改这里
parentFolder = 'E:\Voice_Data_TwoClass_100rep\Exported_process_data';
subTestname = 'drug_test_mat';
labelFileName = 'stim_labels_two_class_100rep_drug_test.mat';

% 八分类目录里有 new_active_channel/new_stimulus_data/new_instance。
addpath('E:\Recognition-in-Biological-Neural-Networks\Code\SVM_code\eight_classes');
addpath('E:\Recognition-in-Biological-Neural-Networks\Code\SVM_code\two_classes');

%% 分析参数
up = repmat([1,1,1,1,0,0,0,0], 1, 8);
down = repmat([0,0,0,0,1,1,1,1], 1, 8);
time_offset_ms = 10;
bin_ms = 10;
train_per_class = 80;
test_per_class = 20;

contents = dir(parentFolder);
accuracy_matrix = [];

for i = 1:length(contents)
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        subFolder = fullfile(parentFolder, contents(i).name);
        disp(['子文件夹：' contents(i).name]);

        %% 读取刺激标签
        order = load(fullfile(subFolder, labelFileName));
        label = order.stim_labels_test';

        if length(label) ~= 200
            error('stim_labels_test 数量不是 200，请检查标签文件或实验批次数。');
        end
        if sum(label == 1) ~= 100 || sum(label == 2) ~= 100
            error('1/2 类标签数量不是各 100，请检查刺激标签。');
        end

        %% 读取 4 个二次 NEX 导出的 mat 文件
        matFolder = fullfile(subFolder, subTestname);
        subContents = dir(fullfile(matFolder, '*.mat'));
        fileNamess = {subContents.name};

        if length(fileNamess) ~= 4
            error('drug test mat 文件数量不是 4，请检查导出文件夹。');
        end

        d = load(fullfile(matFolder, fileNamess{1}));
        d2 = load(fullfile(matFolder, fileNamess{2}));
        d3 = load(fullfile(matFolder, fileNamess{3}));
        d4 = load(fullfile(matFolder, fileNamess{4}));

        %% 提取诱发响应并合并为全局样本矩阵
        k = time_offset_ms;
        p = bin_ms;

        active_ch = new_active_channel(d, d2, d3, d4, k * 0.001, up, down);

        [sti_data, interval] = new_stimulus_data(d, active_ch, k * 0.001);
        [sti_data2, interval2] = new_stimulus_data(d2, active_ch, k * 0.001);
        [sti_data3, interval3] = new_stimulus_data(d3, active_ch, k * 0.001);
        [sti_data4, interval4] = new_stimulus_data(d4, active_ch, k * 0.001);

        ins1 = new_instance(sti_data, interval, p * 0.001);
        ins2 = new_instance(sti_data2, interval2, p * 0.001);
        ins3 = new_instance(sti_data3, interval3, p * 0.001);
        ins4 = new_instance(sti_data4, interval4, p * 0.001);

        ins = [ins1; ins2; ins3; ins4];

        if size(ins, 1) ~= length(label)
            error('响应样本数量和 stim_labels_test 数量不一致，请检查 NEX 导出顺序和刺激标签。');
        end

        %% 按标签划分训练集和测试集
        class1 = find(label == 1);
        class2 = find(label == 2);

        train = [ins(class1(1:train_per_class), :); ins(class2(1:train_per_class), :)];
        test = [ins(class1(train_per_class+1:train_per_class+test_per_class), :); ...
                ins(class2(train_per_class+1:train_per_class+test_per_class), :)];

        trainLabel = [zeros(train_per_class, 1); ones(train_per_class, 1)];
        testLabel = [zeros(test_per_class, 1); ones(test_per_class, 1)];

        %% SVM 分类
        [model_linear, bestcv, bestg, bestc, train_ins] = svm_sequence_linear_train(train, trainLabel);
        [predict_label, accu, test_ins] = svm_sequence_linear_test(test, train, testLabel, model_linear);

        class1_acc = sum(predict_label(1:test_per_class) == 0) / test_per_class * 100;
        class2_acc = sum(predict_label(test_per_class+1:end) == 1) / test_per_class * 100;

        fprintf('总体准确率: %.2f%% (%d/%d)\n', accu(1), sum(predict_label == testLabel), length(testLabel));
        fprintf('类别 1 准确率: %.2f%%\n', class1_acc);
        fprintf('类别 2 准确率: %.2f%%\n', class2_acc);

        %% 保存结果
        resultFolder = fullfile(subFolder, 'svm_result_100rep_drug_test');
        if ~exist(resultFolder, 'dir')
            mkdir(resultFolder);
        end

        save(fullfile(resultFolder, [contents(i).name, '_100rep_drug_test_svm.mat']), ...
            'label', 'active_ch', 'ins', 'train', 'test', 'trainLabel', 'testLabel', ...
            'model_linear', 'predict_label', 'accu', 'class1_acc', 'class2_acc', ...
            'train_ins', 'test_ins', 'time_offset_ms', 'bin_ms', ...
            'train_per_class', 'test_per_class');

        accuracy_matrix = [accuracy_matrix; accu(1), class1_acc, class2_acc]; %#ok<AGROW>
        savepath2 = fullfile(resultFolder, [contents(i).name, '_100rep_drug_test_accuracy.xlsx']);
        header = {'Overall Accuracy', 'Class 1 Accuracy', 'Class 2 Accuracy'};
        writecell(header, savepath2, 'Sheet', 1);
        writematrix(accuracy_matrix, savepath2, 'Sheet', 1, 'Range', 'A2');
    end
end
