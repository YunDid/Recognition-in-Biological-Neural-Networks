%% Japanese Vowels MCS 实验主脚本（参照 Cch_Exp_train_eight 的可编排形态）
%
% 用途：
%   按 cfg 中 cell_id 指定的细胞执行多阶段 MCS 实验流程（test / train / spon）。
%   阶段函数从 cfg.day_dir 读取共享事件表，向 cfg.cell_dir 写入每盘独立刺激标签。
%
% 使用方法：
%   1. 改 config_japanese_vowels.m 中的 cfg.cell_id 到当前细胞
%   2. 改本脚本顶部 date_tag（留空=当天）
%   3. F5 直接跑
%
% 编排说明：
% - 「实验流程」段是脚本中段，按需删/加/换顺序。
% - run_test_jv:  按事件表中已平衡随机化的顺序播放 240 trials，6 batches × 40
% - run_train_jv: 按 speaker 1→8、speaker 内 within_speaker_id 1→30 顺序播放
%                 240 trials，8 batches × 30；与 test 总 trial 数相同
% - Record_Spon:  自放电记录指定秒数
%
% 数据流：
%   <cfg.day_dir>/japanese_vowels_mcs_<protocol_tag>_events.mat   ← 输入（同日所有细胞共享）
%       └── run_test_jv / run_train_jv 读 trial_table + event_table
%       └── 通过 java.awt.Robot 点击 MCS GUI 触发刺激
%   <cfg.cell_dir>/stim_labels_<protocol_tag>_<stage_tag>_batch_NN.mat
%   <cfg.cell_dir>/stim_labels_<protocol_tag>_<stage_tag>_final.mat   ← 输出（每盘独立）
%
% 输出 mat 字段：
%   stim_labels             - 1×N 数组，按播放顺序的 speaker 标签
%   stim_sample_ids         - 1×N 数组，按播放顺序的 ae.train 样本编号
%   stim_global_trial_ids   - 1×N 数组，按播放顺序的全局 trial 编号
%   executed_trial_table    - N 行 table，按播放顺序的 trial meta
%                             train 阶段额外含 train_batch_id / train_trial_id
%   cfg                     - 当前配置副本
%   stage_tag               - 阶段标签字符串
%
% 实验前确保：
% 1. run_preprocess_japanese_vowels(date_tag) 已生成事件表（同 date_tag 跑过一次即可）
% 2. config_japanese_vowels.m 中以下项已对当前机器核对：
%    cell_id / stim_site_indices / elec_locx / elec_locy /
%    record_btn / stim_test_btn / stim_train_btn / start_stim_btn

%% ↓↓↓↓↓↓ 顶部参数 ↓↓↓↓↓↓
date_tag = '';   % 想跑指定日期：改成 'YYYYMMDD'；留空 = 当天

clc; close all;
cfg = config_japanese_vowels(date_tag);
if ~exist(cfg.cell_dir, 'dir')
    mkdir(cfg.cell_dir);
end
fprintf('date_tag=%s, seed=%d, cell_id=%s\nday_dir=%s\ncell_dir=%s\n', ...
    cfg.date_tag, cfg.random_seed, cfg.cell_id, cfg.day_dir, cfg.cell_dir);

%% ↓↓↓↓↓↓ 实验流程（自由编排：删/加/换顺序）↓↓↓↓↓↓
pause(10);

% 自放电记录
Record_Spon(300, cfg.record_btn);

% 第一轮 test
test1 = run_test_jv(cfg, 'test1');

% 自放电记录
Record_Spon(300, cfg.record_btn);

% 训练阶段
train = run_train_jv(cfg, 'train');

% 自放电记录
Record_Spon(300, cfg.record_btn);

% 第二轮 test
test2 = run_test_jv(cfg, 'test2');

% 自放电记录
Record_Spon(300, cfg.record_btn);

%% ↑↑↑↑↑↑ 实验流程结束 ↑↑↑↑↑↑
disp('实验完成');


%% ↓↓↓↓↓↓ 阶段函数 ↓↓↓↓↓↓

function result = run_test_jv(cfg, stage_tag)
% Test 阶段：按事件表中已平衡随机化的顺序播放 240 trials，6 batches × 40。
% 每 batch 后写出累积 mat（含 stim_labels 标签数组，可断电恢复）。
% 事件表从 cfg.day_dir 读（同日共享），输出写到 cfg.cell_dir（每盘独立）。

protocol_path = fullfile(cfg.day_dir, sprintf('japanese_vowels_mcs_%s_events.mat', cfg.protocol_tag));
P = load(protocol_path, 'trial_table', 'event_table');
trial_table = P.trial_table;
event_table = P.event_table;

stim_labels = [];
stim_sample_ids = [];
stim_global_trial_ids = [];
executed_trial_table = trial_table([], :);

for batch = 1:cfg.n_batch
    ClickOnce(cfg.record_btn(1), cfg.record_btn(2));
    pause(5);
    ClickOnce(cfg.stim_test_btn(1), cfg.stim_test_btn(2));

    batch_trials = trial_table(trial_table.batch_id == batch, :);
    for r = 1:height(batch_trials)
        current_trial = batch_trials(r, :);
        events = event_table(event_table.global_trial_id == current_trial.global_trial_id, :);
        play_trial(cfg, events);

        stim_labels(end + 1) = current_trial.speaker_label; %#ok<AGROW>
        stim_sample_ids(end + 1) = current_trial.sample_id; %#ok<AGROW>
        stim_global_trial_ids(end + 1) = current_trial.global_trial_id; %#ok<AGROW>
        executed_trial_table = [executed_trial_table; current_trial]; %#ok<AGROW>
        pause(cfg.inter_trial_interval_s);
    end

    ClickOnce(cfg.stim_test_btn(1), cfg.stim_test_btn(2));
    ClickOnce(cfg.record_btn(1), cfg.record_btn(2));
    pause(5);

    save_path = fullfile(cfg.cell_dir, sprintf('stim_labels_%s_%s_batch_%02d.mat', cfg.protocol_tag, stage_tag, batch));
    save(save_path, 'stim_labels', 'stim_sample_ids', 'stim_global_trial_ids', ...
        'executed_trial_table', 'cfg', 'stage_tag');
    fprintf('[%s] Batch %d/%d done. Saved to %s\n', stage_tag, batch, cfg.n_batch, save_path);
end

final_path = fullfile(cfg.cell_dir, sprintf('stim_labels_%s_%s_final.mat', cfg.protocol_tag, stage_tag));
save(final_path, 'stim_labels', 'stim_sample_ids', 'stim_global_trial_ids', ...
    'executed_trial_table', 'cfg', 'stage_tag');
fprintf('[%s] Final labels saved to: %s\n', stage_tag, final_path);

result = struct('stim_labels', stim_labels, 'stim_sample_ids', stim_sample_ids, ...
    'stim_global_trial_ids', stim_global_trial_ids, ...
    'executed_trial_table', executed_trial_table, 'final_path', final_path);
end


function result = run_train_jv(cfg, stage_tag)
% Train 阶段：按 speaker 1→8、speaker 内 within_speaker_id 1→30 顺序播放 240 trials。
% 8 batches × 30 trials/batch（每 speaker 一个 batch）。
% 顺序固定无需现场盯，因此不写 executed_label_sequence CSV；标签数组保留在 mat 中。
%
% 关于字段语义：原 batch_id / trial_id 字段保留 test 阶段平衡随机化时的批号
% （1..6 / 1..40），train 阶段在此基础上额外追加 train_batch_id（1..8，对应
% 当前阶段实际 NEX 文件号）与 train_trial_id（1..30，当前 NEX 文件内的播放序号）。
%
% 事件表从 cfg.day_dir 读（同日共享），输出写到 cfg.cell_dir（每盘独立）。

protocol_path = fullfile(cfg.day_dir, sprintf('japanese_vowels_mcs_%s_events.mat', cfg.protocol_tag));
P = load(protocol_path, 'trial_table', 'event_table');
trial_table = P.trial_table;
event_table = P.event_table;

% speaker_label 升序、speaker 内 within_speaker_id 升序重排
train_order = sortrows(trial_table, {'speaker_label', 'within_speaker_id'});

stim_labels = [];
stim_sample_ids = [];
stim_global_trial_ids = [];
executed_trial_table = trial_table([], :);
executed_trial_table.train_batch_id = double.empty(0, 1);
executed_trial_table.train_trial_id = double.empty(0, 1);

n_train_batch = numel(cfg.selected_speakers);

for batch = 1:n_train_batch
    speaker = cfg.selected_speakers(batch);
    ClickOnce(cfg.record_btn(1), cfg.record_btn(2));
    pause(5);
    ClickOnce(cfg.stim_train_btn(1), cfg.stim_train_btn(2));

    batch_trials = train_order(train_order.speaker_label == speaker, :);
    for r = 1:height(batch_trials)
        current_trial = batch_trials(r, :);
        current_trial.train_batch_id = batch;
        current_trial.train_trial_id = r;
        events = event_table(event_table.global_trial_id == current_trial.global_trial_id, :);
        play_trial(cfg, events);

        stim_labels(end + 1) = current_trial.speaker_label; %#ok<AGROW>
        stim_sample_ids(end + 1) = current_trial.sample_id; %#ok<AGROW>
        stim_global_trial_ids(end + 1) = current_trial.global_trial_id; %#ok<AGROW>
        executed_trial_table = [executed_trial_table; current_trial]; %#ok<AGROW>
        pause(cfg.inter_trial_interval_s);
    end

    ClickOnce(cfg.stim_train_btn(1), cfg.stim_train_btn(2));
    ClickOnce(cfg.record_btn(1), cfg.record_btn(2));
    pause(5);

    save_path = fullfile(cfg.cell_dir, sprintf('stim_labels_%s_%s_batch_%02d.mat', cfg.protocol_tag, stage_tag, batch));
    save(save_path, 'stim_labels', 'stim_sample_ids', 'stim_global_trial_ids', ...
        'executed_trial_table', 'cfg', 'stage_tag');
    fprintf('[%s] Batch %d/%d (speaker %d) done. Saved to %s\n', stage_tag, batch, n_train_batch, speaker, save_path);
end

final_path = fullfile(cfg.cell_dir, sprintf('stim_labels_%s_%s_final.mat', cfg.protocol_tag, stage_tag));
save(final_path, 'stim_labels', 'stim_sample_ids', 'stim_global_trial_ids', ...
    'executed_trial_table', 'cfg', 'stage_tag');
fprintf('[%s] Final labels saved to: %s\n', stage_tag, final_path);

result = struct('stim_labels', stim_labels, 'stim_sample_ids', stim_sample_ids, ...
    'stim_global_trial_ids', stim_global_trial_ids, ...
    'executed_trial_table', executed_trial_table, 'final_path', final_path);
end


%% ↓↓↓↓↓↓ 通用刺激接口 ↓↓↓↓↓↓

function play_trial(cfg, events)
% 单条 trial 内的 12 个时间槽：把该槽的 top-k 位点收集成一个列表，
% 列表为空（padding 或无位点）则空等一个步长，否则同一槽内同时激活这些位点
% （见 ClickStimSites）。encoding_k=1 时每槽至多一个位点，退化为原单点刺激。
has_site2 = ismember('active_site_2', events.Properties.VariableNames);
for e = 1:height(events)
    sites = events.active_site(e);
    if has_site2
        s2 = events.active_site_2(e);
        if s2 ~= 0
            sites = [sites, s2]; %#ok<AGROW>
        end
    end
    sites = sites(sites ~= 0);
    if isempty(sites)
        pause(cfg.step_interval_s);
    else
        ClickStimSites(sites, cfg);
    end
end
end


function Record_Spon(seconds, record_pos)
ClickOnce(record_pos(1), record_pos(2));
pause(seconds);
ClickOnce(record_pos(1), record_pos(2));
end


function ClickOnce(x, y)
import java.awt.Robot;
robot = java.awt.Robot;
robot.mouseMove(-1, -1);
robot.mouseMove(x, y);
robot.mousePress(java.awt.event.InputEvent.BUTTON1_MASK);
robot.mouseRelease(java.awt.event.InputEvent.BUTTON1_MASK);
end


function ClickStimSites(sites, cfg)
% 同一时间槽内同时激活 1~k 个逻辑位点：先依次点选所有目标电极，再点一次
% “开始刺激”让被选电极一起发放，等待一个步长后再依次取消选中。
% sites 为逻辑位点编号（1~6）向量，经 cfg.stim_site_indices 映射到物理电极。
% numel(sites)==1 时退化为原单点刺激（选中→触发→等待→取消）。
%
% ⚠ 前提假设：MCS GUI 中点选电极是“可叠加多选”——连续点选多个电极后它们都
%   处于选中态，一次“开始刺激”让它们同步发放。若你的 GUI 是“单选/点新的会
%   取消旧的”，top-2 在此方式下无法齐发，需改触发方式（联系我改）。
elec_position = cfg.stim_site_indices;
locx = cfg.elec_locx;
locy = cfg.elec_locy;
elec_idx = elec_position(sites);

% 选中所有目标电极
for i = 1:numel(elec_idx)
    ClickOnce(locx(elec_idx(i)), locy(elec_idx(i)));
end
% 一次触发，被选电极同步发放
ClickOnce(cfg.start_stim_btn(1), cfg.start_stim_btn(2));
pause(cfg.step_interval_s);
% 取消选中所有目标电极
for i = 1:numel(elec_idx)
    ClickOnce(locx(elec_idx(i)), locy(elec_idx(i)));
end
end
