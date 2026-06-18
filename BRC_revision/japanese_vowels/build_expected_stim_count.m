%% build_expected_stim_count.m
%
% 用途：
%   基于事件表 mat 计算每个 batch 的理论刺激数（test 与 train 阶段），
%   导出为独立 mat 文件，用于后续与 NEX 实测刺激事件数对照核验。
%
% 使用方法：
%   1. 先确保 run_preprocess_japanese_vowels(date_tag) 已生成事件表
%   2. 在 MATLAB 里把 japanese_vowels/ 加入 Path
%   3. 修改下方 date_tag（留空 = 当天）后 F5 直接跑
%
% 数据流：
%   <cfg.day_dir>/japanese_vowels_mcs_<protocol_tag>_events.mat   ← 输入
%       └── 提取 sample_features 中各 trial 的 is_padding_step
%       └── 按 trial 顺序与 speaker_label 切分 test / train batches
%       └── 触发次数 = 12 - padding；期望刺激脉冲数 = encoding_k × (12 - padding)
%   <cfg.day_dir>/expected_stim_count_<protocol_tag>.mat          ← 输出（同日所有细胞共享）
%   <cfg.cell_dir>/expected_stim_count_<protocol_tag>.mat         ← 输出（当盘细胞目录副本）
%
% 操作流：
%   run_preprocess_japanese_vowels   ← 生成事件表
%       ↓
%   build_expected_stim_count        ← 本脚本（生成期望表）
%       ↓
%   实验完成后导出 NEX → 二次导出 mat
%       ↓
%   人工或脚本读 expected_stim_count_*.mat 与 NEX 计数对照
%
% 输出 mat 中 expected struct 字段含义：
%   expected.protocol_tag            ← 协议标识，如 'first6_top1'
%   expected.date_tag                ← 实验日期 'YYYYMMDD'
%   expected.encoding_k              ← 每有效槽刺激的位点数（1 或 2）
%   expected.total_triggers          ← 全局总触发次数（每有效槽一次“开始刺激”）
%   expected.total_stim              ← 全局总刺激脉冲数（= encoding_k × 触发次数）
%   expected.total_padding           ← 全局 padding 槽数
%   expected.test_batches(6).batch_id, .n_trial, .n_active_slots, .expected_stim, .padding
%                                    ← test 阶段每 batch 触发次数/期望刺激脉冲数/padding
%   expected.train_batches(8).speaker_label, .n_trial, .n_active_slots, .expected_stim, .padding
%                                    ← train 阶段每 batch（每 speaker）触发/刺激脉冲/padding
%   expected.trial_summary           ← 240 行 table，每 trial 一行：
%       global_trial_id, sample_id, speaker_label, within_speaker_id,
%       test_batch_id, train_batch_id, n_active_slots, expected_stim, padding
%   expected.cfg_snapshot            ← 当前 cfg 副本（追溯实验配置）
%
% 核对方法（外部）：
%   把每个 NEX 文件中 STG 1 Single Pulse Start 的事件计数与
%   expected.test_batches(b).expected_stim / expected.train_batches(b).expected_stim
%   逐一比对。容差见 Atlas 卡片
%   [[BRC修订 - MCS GUI 点击式协议的固有漏点容差]]。

%% ↓↓↓↓↓↓ 顶部参数 ↓↓↓↓↓↓
date_tag = '';   % 想跑指定日期：改成 'YYYYMMDD'；留空 = 当天

clc;
cfg = config_japanese_vowels(date_tag);
if ~exist(cfg.day_dir, 'dir')
    mkdir(cfg.day_dir);
end
fprintf('date_tag=%s, cell_id=%s\nday_dir=%s\n', cfg.date_tag, cfg.cell_id, cfg.day_dir);

%% 加载事件表
events_path = fullfile(cfg.day_dir, sprintf('japanese_vowels_mcs_%s_events.mat', cfg.protocol_tag));
S = load(events_path, 'cfg', 'sample_features', 'trial_table');
sample_features = S.sample_features;
trial_table = S.trial_table;

n_trial = numel(sample_features);
n_slot_per_trial = cfg.n_time_slot;

% 每 trial 的 padding 数、有效槽数（触发次数）与期望刺激脉冲数。
% 有效槽数 = 12 - padding（每个有效槽按一次“开始刺激”触发）。
% 期望刺激脉冲数 = encoding_k × 有效槽数（每个有效槽同时刺激 k 个电极，每电极各
% 产生一个刺激脉冲）。encoding_k=1 时两者相等（与旧版完全一致）。
k_per_slot = cfg.encoding_k;
padding_per_trial = zeros(n_trial, 1);
for tr = 1:n_trial
    padding_per_trial(tr) = sum(sample_features(tr).is_padding_step);
end
active_slots_per_trial = n_slot_per_trial - padding_per_trial;   % 触发次数
expected_per_trial = k_per_slot * active_slots_per_trial;        % 刺激脉冲数（=k×触发）

%% 全局
total_stim = sum(expected_per_trial);              % 总刺激脉冲数（×k）
total_triggers = sum(active_slots_per_trial);      % 总触发次数（每有效槽一次）
total_padding = sum(padding_per_trial);

%% Test 阶段：6 batches × 40 trials/batch（按 trial_table 中 batch_id）
test_batch_id_col = trial_table.batch_id;
test_batches = struct('batch_id', {}, 'n_trial', {}, 'n_active_slots', {}, 'expected_stim', {}, 'padding', {});
for b = 1:cfg.n_batch
    mask = test_batch_id_col == b;
    test_batches(b).batch_id = b;
    test_batches(b).n_trial = sum(mask);
    test_batches(b).n_active_slots = sum(active_slots_per_trial(mask));   % 触发次数
    test_batches(b).expected_stim = sum(expected_per_trial(mask));        % 刺激脉冲数（×k）
    test_batches(b).padding = sum(padding_per_trial(mask));
end

%% Train 阶段：8 batches，每 batch = 一个 speaker
speaker_col = trial_table.speaker_label;
train_batches = struct('speaker_label', {}, 'n_trial', {}, 'n_active_slots', {}, 'expected_stim', {}, 'padding', {});
for sp = 1:numel(cfg.selected_speakers)
    speaker = cfg.selected_speakers(sp);
    mask = speaker_col == speaker;
    train_batches(sp).speaker_label = speaker;
    train_batches(sp).n_trial = sum(mask);
    train_batches(sp).n_active_slots = sum(active_slots_per_trial(mask));   % 触发次数
    train_batches(sp).expected_stim = sum(expected_per_trial(mask));        % 刺激脉冲数（×k）
    train_batches(sp).padding = sum(padding_per_trial(mask));
end

%% trial_summary：240 行 table
test_batch_id_per_trial = test_batch_id_col;
train_batch_id_per_trial = speaker_col;   % train 阶段 batch_id 即 speaker_label

trial_summary = table( ...
    trial_table.global_trial_id, ...
    trial_table.sample_id, ...
    trial_table.speaker_label, ...
    trial_table.within_speaker_id, ...
    test_batch_id_per_trial, ...
    train_batch_id_per_trial, ...
    active_slots_per_trial, ...
    expected_per_trial, ...
    padding_per_trial, ...
    'VariableNames', {'global_trial_id', 'sample_id', 'speaker_label', ...
        'within_speaker_id', 'test_batch_id', 'train_batch_id', ...
        'n_active_slots', 'expected_stim', 'padding'});

%% 打包并保存
expected = struct();
expected.protocol_tag = cfg.protocol_tag;
expected.date_tag = cfg.date_tag;
expected.encoding_k = cfg.encoding_k;
expected.total_triggers = total_triggers;   % 总触发次数（每有效槽一次“开始刺激”）
expected.total_stim = total_stim;            % 总刺激脉冲数（= encoding_k × 触发次数）
expected.total_padding = total_padding;
expected.test_batches = test_batches;
expected.train_batches = train_batches;
expected.trial_summary = trial_summary;
expected.cfg_snapshot = cfg;

out_name = sprintf('expected_stim_count_%s.mat', cfg.protocol_tag);
out_path = fullfile(cfg.day_dir, out_name);          % 同日共享副本
save(out_path, 'expected');
% 再存一份到当盘细胞目录（与该盘 stim_labels 同目录），后期直接复现/对照不必重跑。
% 注意：只写当前 cfg.cell_id 对应的目录；换盘重设 cell_id 后重跑本脚本即可在该盘
% 目录下再落一份（脚本只读共享事件表，重跑代价很小）。
if ~exist(cfg.cell_dir, 'dir')
    mkdir(cfg.cell_dir);
end
cell_out_path = fullfile(cfg.cell_dir, out_name);    % 当盘细胞目录副本
save(cell_out_path, 'expected');
fprintf('Saved expected stim count to:\n  (同日共享) %s\n  (当盘细胞) %s\n', out_path, cell_out_path);

%% 控制台速览（便于直接抄到 NEX 比对）
fprintf('\n=== 全局 (encoding_k=%d) ===\n', cfg.encoding_k);
fprintf('总触发次数(每有效槽一次): %d\n', total_triggers);
fprintf('总刺激脉冲数(=k×触发, NEX 若按电极计数对这个): %d\n', total_stim);
fprintf('总 padding: %d\n', total_padding);

fprintf('\n=== Test (6 batches × 40 trials) ===\n');
for b = 1:cfg.n_batch
    fprintf('  batch %d: 触发=%d, 期望刺激脉冲=%d, padding=%d\n', ...
        test_batches(b).batch_id, test_batches(b).n_active_slots, ...
        test_batches(b).expected_stim, test_batches(b).padding);
end

fprintf('\n=== Train (8 batches × 30 trials, 每 batch = 一个 speaker) ===\n');
for sp = 1:numel(cfg.selected_speakers)
    fprintf('  speaker %d: 触发=%d, 期望刺激脉冲=%d, padding=%d\n', ...
        train_batches(sp).speaker_label, train_batches(sp).n_active_slots, ...
        train_batches(sp).expected_stim, train_batches(sp).padding);
end
