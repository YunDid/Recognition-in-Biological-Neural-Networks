%% Date:2024/03/19 八分类 3轮测试
clc;
clear;
close all

% order=load('E:\Voice_Data_Eight\20250311\C1_20250311_MCon_Cell0218\stim_labels.mat');
% label = order.stim_labels_test2';
parentFolder = 'E:\Voice_Data_Eight\Exported_process_data_CCH\20250323\1';
contents = dir(parentFolder);
up = repmat([1,1,1,1,0,0,0,0], 1, 8);
down = repmat([0,0,0,0,1,1,1,1], 1, 8);

% 初始化保存准确率的矩阵
accuracy_matrix = zeros(21, 9);

for i = 1:length(contents)
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        subFolder = fullfile(parentFolder, contents(i).name);
        disp(['子文件夹：' contents(i).name]);
  
        order=load(fullfile(subFolder,'stim_labels.mat'));
        label = order.stim_labels_test3';
        
        subTestname = 'test3_3_mat';
        matFolder = strcat(subFolder,'/' ,subTestname,'/');
        subContents = dir(fullfile(matFolder, '*.mat'));
        fileNamess = {subContents.name};
%         for k = 0:1:20
        for k = 10
            savedir1 = strcat(matFolder,'/stimulation/' , num2str(k), 'ms/');
            mkdir(savedir1);

            % 加载数据文件
            d = load(fullfile(matFolder, fileNamess{1}));
            d2 = load(fullfile(matFolder, fileNamess{2}));
            d3 = load(fullfile(matFolder, fileNamess{3}));
            d4 = load(fullfile(matFolder, fileNamess{4}));

            [active_ch] = new_active_channel(d, d2, d3, d4, k * 0.001, up, down);

            [sti_data, interval] = new_stimulus_data(d, active_ch, k * 0.001);
            [sti_data2, interval2] = new_stimulus_data(d2, active_ch, k * 0.001);
            [sti_data3, interval3] = new_stimulus_data(d3, active_ch, k * 0.001);
            [sti_data4, interval4] = new_stimulus_data(d4, active_ch, k * 0.001);

            bin = 10;
            p = bin;

            [ins1] = new_instance(sti_data, interval, p * 0.001);
            [ins2] = new_instance(sti_data2, interval2, p * 0.001);
            [ins3] = new_instance(sti_data3, interval3, p * 0.001);
            [ins4] = new_instance(sti_data4, interval4, p * 0.001);
            ins = [ins1; ins2; ins3; ins4];

            % 获取各类样本索引
            class_indices = arrayfun(@(x) find(label == x), 1:8, 'UniformOutput', false);

            % 划分训练集和测试集
            train = [];
            test = [];
            for class_idx = 1:8
                train = [train; ins(class_indices{class_idx}(1:21), :)];
                test = [test; ins(class_indices{class_idx}(22:28), :)];
            end

            % 类标签
            repeat1 = 21;
            repeat2 = 7;
            trainLabel = repelem(1:8, repeat1)';
            testLabel = repelem(1:8, repeat2)';

            % 训练和测试 SVM 模型
            [model_linear, bestcv2, bestg2, bestc2, train_ins2] = svm_sequence_linear_train(train, trainLabel);
            [predict_label2, accu2, test_ins2] = svm_sequence_linear_test(test, train, testLabel, model_linear);

            % 总体准确率
            accuracy_linear(k + 1) = accu2(1);

            % 逐类计算准确率
            class_accuracy = zeros(1, 8);
            class_correct = zeros(1, 8);
            class_total = zeros(1, 8);

            for class_idx = 1:8
                indices = find(testLabel == class_idx);
                class_total(class_idx) = length(indices);
                class_correct(class_idx) = sum(predict_label2(indices) == testLabel(indices));
                class_accuracy(class_idx) = class_correct(class_idx) / class_total(class_idx) * 100;
                fprintf('类别 %d 的准确率: %.2f%% (%d/%d)\n', class_idx, class_accuracy(class_idx), class_correct(class_idx), class_total(class_idx));
            end

            % 显示总体准确率
            fprintf('总体准确率: %.2f%% (%d/%d)\n', accu2(1), sum(class_correct), length(testLabel));

            % 保存到矩阵中
            accuracy_matrix(k + 1, 1) = accu2(1);
            accuracy_matrix(k + 1, 2:9) = class_accuracy;
        end
        
        % 在父文件夹下创建result文件夹
        resultFolder = fullfile(subFolder, 'svm_result');
        if ~exist(resultFolder, 'dir')
            mkdir(resultFolder);
        end

        % 保存准确率矩阵到Excel文件
        savepath2 = fullfile(resultFolder, [contents(i).name,'_',subTestname, '-accuracy.xlsx']);
        header = {'Overall Accuracy', 'Class 1 Accuracy', 'Class 2 Accuracy', 'Class 3 Accuracy', ...
                  'Class 4 Accuracy', 'Class 5 Accuracy', 'Class 6 Accuracy', 'Class 7 Accuracy', 'Class 8 Accuracy'};

        % 使用 writecell 写入标题行
        writecell(header, savepath2, 'Sheet', 1);

        % 使用 writematrix 写入准确率数据
        writematrix(accuracy_matrix, savepath2, 'Sheet', 1, 'Range', 'A2');
    end
end
