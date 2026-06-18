%% Date:2026/05/02 Japanese Vowels 八分类 test-only SVM
%
% 用途：
%   对 Japanese Vowels MCS 任务的某次 test session 完成八分类 SVM 分析。
%   仅分析 test 阶段，不分析 train 阶段。每个 <date>/<cell>/ 子目录跑一次。
%
% 使用方法：
%   实机数据二次导出后，改顶部「路径参数」段六个变量，F5 直接跑。
%   分析端 trial 切分容错策略见 [[BRC修订 - MCS GUI 点击式协议的固有漏点容差]] §6。
%
% 数据组织：
%   <parentFolder>/
%   └─ <date_tag>/                                              ← 同日所有 cell 共享
%      ├─ japanese_vowels_mcs_<protocol_tag>_events.mat         ← 事件表（软校验用，可选）
%      └─ <cell_id>/                                            ← 当盘细胞独立
%         ├─ stim_labels_<protocol_tag>_<stage_tag>_final.mat   ← MCS 主脚本输出
%         └─ <subTestname>/                                     ← NEX 二次导出
%            ├─ batch_01.mat
%            ├─ ...
%            └─ batch_06.mat
%
% 输入：
%   - stim_labels_<protocol_tag>_<stage_tag>_final.mat：含 stim_labels (1×240)、
%     stim_global_trial_ids (1×240)；与 MCS 主脚本输出一致
%   - <subTestname>/*.mat：6 个 batch 的 NEX 二次导出 spike 数据
%   - japanese_vowels_mcs_<protocol_tag>_events.mat（可选）：含 event_table，
%     用于按 global_trial_id 反推每 trial 期望非空 step 数
%
% 输出：
%   <parentFolder>/<date_tag>/<cell_id>/svm_result_jv_<stage_tag>/
%     ├─ <cell_id>_jv_<stage_tag>_svm.mat       结构化结果（模型、预测、特征、参数）
%     └─ <cell_id>_jv_<stage_tag>_accuracy.xlsx 总体 + 8 类准确率表
%
% 数据流：
%   batch mat → jv_active_channel → jv_stimulus_data → jv_instance → ins (240×F)
%   stim_labels final mat → label (240×1)
%   ins + label → 80/20 划分 (192/48) → svm_sequence_linear_train (内部 5-fold 选 C)
%                                    → svm_sequence_linear_test → 总体 + 8 类准确率

clc; clear; close all;

%% ===== 路径参数（实机数据导出后改这里）=====
parentFolder = 'E:\Voice_Data_JV_8class\Data';
date_tag     = '20260502';
cell_id      = 'Cell_1';
protocol_tag = 'first6_top1';
stage_tag    = 'test1';
subTestname  = sprintf('%s_mat', stage_tag);   % 默认与 stage_tag 同名 + _mat

% 工具函数路径（transform / svm_sequence_linear_train / svm_sequence_linear_test）
addpath('E:\Recognition-in-Biological-Neural-Networks\Code\SVM_code\eight_classes');

%% ===== 分析参数 =====
up   = repmat([1,1,1,1,0,0,0,0], 1, 8);
down = repmat([0,0,0,0,1,1,1,1], 1, 8);
time_offset_ms    = 10;     % 伪迹排除窗
bin_ms            = 10;     % bin 宽度
trial_window_s    = 3.0;    % trial 响应窗（12 step × 250 ms）
trial_gap_s       = 5.0;    % trial 边界识别阈值（漏点容差见容差卡片 §6.1）
n_class           = 8;
samples_per_class = 30;
trials_per_batch  = 40;
train_per_class   = 24;     % 80%
test_per_class    = 6;      % 20%

%% ===== 文件命名 =====
labelFileName  = sprintf('stim_labels_%s_%s_final.mat', protocol_tag, stage_tag);
eventsFileName = sprintf('japanese_vowels_mcs_%s_events.mat', protocol_tag);

cellFolder = fullfile(parentFolder, date_tag, cell_id);
disp(['处理细胞目录：' cellFolder]);

%% ===== 加载 stim_labels final mat =====
order = load(fullfile(cellFolder, labelFileName));
label = double(order.stim_labels(:));
expected_n_trial = n_class * samples_per_class;

if length(label) ~= expected_n_trial
    error('stim_labels 长度 %d 与期望 %d 不一致', length(label), expected_n_trial);
end
for c = 1:n_class
    if sum(label == c) ~= samples_per_class
        error('类别 %d 样本数 %d 与期望 %d 不一致', ...
              c, sum(label == c), samples_per_class);
    end
end

%% ===== 加载事件表（漏点软校验用，可选）=====
events_path = fullfile(parentFolder, date_tag, eventsFileName);
expected_per_trial_full = [];
if exist(events_path, 'file')
    P = load(events_path, 'event_table');
    event_table = P.event_table;
    gids = order.stim_global_trial_ids(:);

    expected_per_trial_full = zeros(expected_n_trial, 1);
    for t = 1:expected_n_trial
        rows = event_table(event_table.global_trial_id == gids(t), :);
        expected_per_trial_full(t) = sum(rows.active_site ~= 0);
    end
    fprintf('已加载事件表，启用单 trial 漏点软校验\n');
else
    warning('未找到事件表 %s，跳过单 trial 漏点软校验', events_path);
end

%% ===== 加载 batch mat =====
matFolder = fullfile(cellFolder, subTestname);
subContents = dir(fullfile(matFolder, '*.mat'));
fileNames = sort({subContents.name});
n_batch = length(fileNames);
fprintf('共加载 %d 个 batch 文件\n', n_batch);

if n_batch * trials_per_batch ~= expected_n_trial
    error('batch 文件数 %d × %d trials/batch ≠ 期望总 trial 数 %d', ...
          n_batch, trials_per_batch, expected_n_trial);
end

spike_data_sets = cell(1, n_batch);
for b = 1:n_batch
    spike_data_sets{b} = load(fullfile(matFolder, fileNames{b}));
end

%% ===== 通道选择 =====
active_ch = jv_active_channel(spike_data_sets, time_offset_ms * 0.001, ...
                              up, down, trial_gap_s);
fprintf('选定 %d 个 active channel\n', length(active_ch));

%% ===== 提取诱发响应并合并为全局样本矩阵 =====
ins_all = cell(1, n_batch);
total_missed = 0;
total_expected = 0;

for b = 1:n_batch
    idx_start = (b - 1) * trials_per_batch + 1;
    idx_end   = b * trials_per_batch;

    if isempty(expected_per_trial_full)
        expected_b = [];
    else
        expected_b = expected_per_trial_full(idx_start:idx_end);
    end

    [sti_b, intervals_b, miss_b, exp_b] = jv_stimulus_data( ...
        spike_data_sets{b}, active_ch, time_offset_ms * 0.001, ...
        trial_window_s, trial_gap_s, ...
        trials_per_batch, expected_b);

    ins_all{b} = jv_instance(sti_b, intervals_b, bin_ms * 0.001, trial_window_s);

    total_missed   = total_missed + miss_b;
    total_expected = total_expected + exp_b;
    fprintf('batch %d/%d: trials=%d, miss=%d/%d\n', ...
            b, n_batch, size(intervals_b, 1), miss_b, exp_b);
end

ins = vertcat(ins_all{:});

if size(ins, 1) ~= length(label)
    error('合并后 trial 数 %d 与 stim_labels 长度 %d 不一致', ...
          size(ins, 1), length(label));
end

%% ===== 全实验漏点率软校验（容差卡片 §6.2）=====
if total_expected > 0
    miss_rate = total_missed / total_expected;
    fprintf('全实验累计漏点：%d / %d (%.2f%%)\n', ...
            total_missed, total_expected, miss_rate * 100);
    if miss_rate > 0.003
        warning('全实验漏点率 %.2f%% 超出 0.3%% 容差，建议复核', miss_rate * 100);
    end
end

%% ===== 80/20 划分 =====
class_indices = arrayfun(@(c) find(label == c), 1:n_class, 'UniformOutput', false);
train = [];
test  = [];
for c = 1:n_class
    idxs = class_indices{c};
    train = [train; ins(idxs(1:train_per_class), :)]; %#ok<AGROW>
    test  = [test;  ins(idxs(train_per_class + 1 : train_per_class + test_per_class), :)]; %#ok<AGROW>
end
trainLabel = repelem((1:n_class)', train_per_class);
testLabel  = repelem((1:n_class)', test_per_class);

%% ===== SVM =====
[model_linear, bestcv, bestg, bestc, train_ins] = ...
    svm_sequence_linear_train(train, trainLabel);
[predict_label, accu, test_ins] = ...
    svm_sequence_linear_test(test, train, testLabel, model_linear);

class_accuracy = zeros(1, n_class);
for c = 1:n_class
    indices = find(testLabel == c);
    n_correct = sum(predict_label(indices) == testLabel(indices));
    class_accuracy(c) = n_correct / length(indices) * 100;
    fprintf('类别 %d 准确率: %.2f%% (%d/%d)\n', ...
            c, class_accuracy(c), n_correct, length(indices));
end
fprintf('总体准确率: %.2f%% (%d/%d)\n', ...
        accu(1), sum(predict_label == testLabel), length(testLabel));

%% ===== 保存 =====
resultFolder = fullfile(cellFolder, sprintf('svm_result_jv_%s', stage_tag));
if ~exist(resultFolder, 'dir')
    mkdir(resultFolder);
end

save_basename = sprintf('%s_jv_%s', cell_id, stage_tag);

save(fullfile(resultFolder, [save_basename '_svm.mat']), ...
    'label', 'active_ch', 'ins', 'train', 'test', 'trainLabel', 'testLabel', ...
    'model_linear', 'predict_label', 'accu', 'class_accuracy', ...
    'train_ins', 'test_ins', ...
    'time_offset_ms', 'bin_ms', 'trial_window_s', 'trial_gap_s', ...
    'train_per_class', 'test_per_class', ...
    'total_missed', 'total_expected', ...
    'date_tag', 'cell_id', 'protocol_tag', 'stage_tag');

accuracy_row = [accu(1), class_accuracy];
header = {'Overall Accuracy', ...
          'Class 1 Accuracy', 'Class 2 Accuracy', 'Class 3 Accuracy', ...
          'Class 4 Accuracy', 'Class 5 Accuracy', 'Class 6 Accuracy', ...
          'Class 7 Accuracy', 'Class 8 Accuracy'};
xlsx_path = fullfile(resultFolder, [save_basename '_accuracy.xlsx']);
writecell(header, xlsx_path, 'Sheet', 1);
writematrix(accuracy_row, xlsx_path, 'Sheet', 1, 'Range', 'A2');

fprintf('结果已保存到 %s\n', resultFolder);
