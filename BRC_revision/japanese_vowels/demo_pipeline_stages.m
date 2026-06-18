function demo_pipeline_stages(date_tag)
%DEMO_PIPELINE_STAGES Japanese Vowels 单样本预处理分步演示导出（汇报用）。
%
% 用途：
%   面向给老师汇报 / 做 PPT，针对单条声音样本，按「展示顺序」逐步导出
%   预处理流水线的 5 个阶段中间数据，保存为一个 mat，并在命令窗口打印
%   每个阶段矩阵的尺寸与数值，便于直接截图。
%
%   ⚠ 重要说明（汇报时必须知情）：
%   本脚本的阶段顺序按汇报展示顺序排列：
%       raw 12xT → ①降采样12x12 → ②标准化 → ③abs → ④6位点压缩 → ⑤top1
%   这与生产代码 encode_sample 的真实执行顺序不同。生产代码先在变长 T 上
%   做 z-score 与 abs，再降采样到 12 槽。因 abs 与插值不可交换、短样本
%   padding 时点不同，本演示数据与实际事件表数值会有差异，仅作流程示意，
%   不能反推事件表数值。z-score 用的 mu/sigma 仍取生产口径（全体 speaker
%   1-8 原始帧的全局均值/标准差），保持标准化基准与实验一致。
%
% 使用方法：
%   demo_pipeline_stages                  % 用今天日期，自动选样本
%   demo_pipeline_stages('20260502')      % 显式指定日期（影响 mu/sigma 否？否，
%                                           mu/sigma 只依赖数据集本身；date_tag
%                                           仅决定输出目录）
%   选哪条样本：改本文件下方 DEMO_SPEAKER / DEMO_WITHIN_ID 两行。
%   DEMO_WITHIN_ID 留空 [] 时自动选该 speaker 第一条 original_T>12 的样本
%   （这样降采样可见，PPT 效果最好）。
%
% 输入：
%   date_tag - 'YYYYMMDD' 字符串，可省略
%   依赖：config_japanese_vowels.m；cfg.data_dir 下 ae.train、size_ae.train
%
% 输出：
%   <cfg.day_dir>/demo_pipeline_sp<spk>_id<wid>.mat，含变量：
%     meta              - struct：sample_id/speaker/within_id/original_T/feature_route 等
%     mu, sigma         - 1x12，生产口径全局标准化统计量
%     stage1_raw_12xT   - 12 x T，原始数据转置（T 变长）
%     stage2_ds_12x12   - 12 x 12，降采样/补槽后（标准化前）
%     stage3_z_12x12    - 12 x 12，z-score 标准化后
%     stage4_abs_12x12  - 12 x 12，取绝对值后
%     stage4b_site_6x12 - 6 x 12，12 特征压缩到 6 位点后（first6 或 adjacent_mean）
%     stage5_active     - 12 x 1，每个时间槽 top-1 命中的位点编号（padding 槽=0）
%     stage5_onehot_6x12- 6 x 12，top-1 的 one-hot 矩阵（便于截图展示刺激模式）
%     stage5b_active2   - 12 x 2，每槽 top-2 位点编号（第1列=最高,第2列=次高;padding=0）
%     stage5b_onehot_6x12-6 x 12，top-2 的 one-hot 矩阵（每非补槽列两个 1）
%     is_padding_step   - 12 x 1，逻辑向量，true=补槽（空刺激）步
%
% 数据流：
%   <data_dir>/ae.train,size_ae.train → 读全体 → 滤 speaker1-8 → 全局 mu/sigma
%       └→ 取 demo 单样本 raw(T x12) → 转置(12xT)=stage1
%       └→ 降采样到12槽=stage2 → z-score=stage3 → abs=stage4
%       └→ 6位点压缩=stage4b → 逐槽 top-1 =stage5
%   <day_dir>/demo_pipeline_sp<spk>_id<wid>.mat ← 输出
%
% 操作流：直接运行本脚本一条命令即可，无需先跑 run_preprocess。

if nargin < 1
    date_tag = '';
end
clc;

% ===== 选哪条样本演示（改这两行）=====
DEMO_SPEAKER   = 3;     % 1-8
DEMO_WITHIN_ID = [];    % 该 speaker 内第几条；[] = 自动选第一条 original_T>12

cfg = config_japanese_vowels(date_tag);
if ~exist(cfg.day_dir, 'dir')
    mkdir(cfg.day_dir);
end
fprintf('date_tag=%s, feature_route=%s, long_sample_mode=%s\n', ...
    cfg.date_tag, cfg.feature_route, cfg.long_sample_mode);

% ---- 读全体样本并滤 speaker 1-8 ----
samples = read_samples(fullfile(cfg.data_dir, cfg.input_file), ...
    fullfile(cfg.data_dir, cfg.size_file));
samples = samples(ismember([samples.speaker_label], cfg.selected_speakers));

% ---- 生产口径全局标准化统计量（全体原始帧）----
all_frames = vertcat(samples.raw_Tx12);
mu = mean(all_frames, 1);
sigma = std(all_frames, 0, 1);
sigma(sigma == 0) = 1;

% ---- 选定 demo 样本 ----
spk_mask = [samples.speaker_label] == DEMO_SPEAKER;
spk_idx = find(spk_mask);
if isempty(spk_idx)
    error('speaker %d 无样本', DEMO_SPEAKER);
end
if isempty(DEMO_WITHIN_ID)
    Ts = [samples(spk_idx).original_T];
    pick_local = find(Ts > cfg.n_time_slot, 1);
    if isempty(pick_local)
        pick_local = 1;   % 没有长样本则退回第一条
        fprintf('[提示] speaker %d 无 T>12 样本，退回第一条（将演示补槽 padding）\n', DEMO_SPEAKER);
    end
else
    pick_local = find([samples(spk_idx).within_speaker_id] == DEMO_WITHIN_ID, 1);
    if isempty(pick_local)
        error('speaker %d 内不存在 within_id=%d', DEMO_SPEAKER, DEMO_WITHIN_ID);
    end
end
s = samples(spk_idx(pick_local));

% ===== Stage 1：原始数据转置 12 x T =====
stage1_raw_12xT = s.raw_Tx12';          % 12 x T，T 变长

% ===== Stage 2：降采样 / 补槽到 12 x 12（标准化前，对 raw 操作）=====
[stage2_ds_12x12, is_padding_step] = resample_to_slots(stage1_raw_12xT, cfg);

% ===== Stage 3：z-score 标准化（生产口径 mu/sigma，逐特征行）=====
stage3_z_12x12 = (stage2_ds_12x12 - mu') ./ sigma';

% ===== Stage 4：取绝对值 =====
stage4_abs_12x12 = abs(stage3_z_12x12);

% ===== Stage 4b：12 特征压缩到 6 位点 =====
if strcmp(cfg.feature_route, 'first6')
    stage4b_site_6x12 = stage4_abs_12x12(1:cfg.n_site, :);
else  % 'adjacent_mean'
    stage4b_site_6x12 = zeros(cfg.n_site, cfg.n_time_slot);
    for site = 1:cfg.n_site
        stage4b_site_6x12(site, :) = mean(stage4_abs_12x12([2*site-1, 2*site], :), 1);
    end
end

% ===== Stage 5：逐时间槽 top-1 位点（padding 槽=0）=====
stage5_active = zeros(cfg.n_time_slot, 1);
stage5_onehot_6x12 = zeros(cfg.n_site, cfg.n_time_slot);
for t = 1:cfg.n_time_slot
    if ~is_padding_step(t)
        [~, a] = max(stage4b_site_6x12(:, t));
        stage5_active(t) = a;
        stage5_onehot_6x12(a, t) = 1;
    end
end

% ===== Stage 5b：逐时间槽 top-2 位点（padding 槽=0）=====
% 每个非补槽时间步取 6 位点得分最高的 2 个；stage5b_active2 第1列=最高位点
% （与 top-1 一致），第2列=次高位点。one-hot 中该槽两个位点均置 1。
stage5b_active2 = zeros(cfg.n_time_slot, 2);
stage5b_onehot_6x12 = zeros(cfg.n_site, cfg.n_time_slot);
for t = 1:cfg.n_time_slot
    if ~is_padding_step(t)
        [~, order] = sort(stage4b_site_6x12(:, t), 'descend');
        top2 = order(1:2);
        stage5b_active2(t, :) = top2';
        stage5b_onehot_6x12(top2, t) = 1;
    end
end

% ---- 元信息 ----
meta = struct();
meta.sample_id = s.sample_id;
meta.speaker_label = s.speaker_label;
meta.within_speaker_id = s.within_speaker_id;
meta.original_T = s.original_T;
meta.n_feature = cfg.n_feature;
meta.n_time_slot = cfg.n_time_slot;
meta.n_site = cfg.n_site;
meta.feature_route = cfg.feature_route;
meta.long_sample_mode = cfg.long_sample_mode;
meta.score_mode = cfg.score_mode;
meta.stage_order_note = 'presentation order: raw -> downsample -> zscore -> abs -> 6site -> top1 (differs from production encode_sample)';

% ---- 命令窗口打印（便于截图）----
print_stage('Stage1 原始转置 12xT', stage1_raw_12xT);
fprintf('  original_T = %d, speaker = %d, within_id = %d, sample_id = %d\n', ...
    s.original_T, s.speaker_label, s.within_speaker_id, s.sample_id);
print_stage('Stage2 降采样/补槽 12x12', stage2_ds_12x12);
fprintf('  padding steps: %s\n', mat2str(find(is_padding_step)'));
print_stage('Stage3 标准化 12x12', stage3_z_12x12);
print_stage('Stage4 绝对值 12x12', stage4_abs_12x12);
print_stage('Stage4b 6位点压缩 6x12', stage4b_site_6x12);
print_stage('Stage5 top-1 one-hot 6x12', stage5_onehot_6x12);
fprintf('Stage5 每槽命中位点 (1x12): %s\n', mat2str(stage5_active'));
print_stage('Stage5b top-2 one-hot 6x12', stage5b_onehot_6x12);
fprintf('Stage5b 每槽命中位点 top1/top2 (12x2):\n');
disp(stage5b_active2);

% ---- 保存 ----
out_file = fullfile(cfg.day_dir, ...
    sprintf('demo_pipeline_sp%d_id%d.mat', s.speaker_label, s.within_speaker_id));
save(out_file, 'meta', 'mu', 'sigma', ...
    'stage1_raw_12xT', 'stage2_ds_12x12', 'stage3_z_12x12', 'stage4_abs_12x12', ...
    'stage4b_site_6x12', 'stage5_active', 'stage5_onehot_6x12', ...
    'stage5b_active2', 'stage5b_onehot_6x12', 'is_padding_step');
fprintf('\nSaved -> %s\n', out_file);
end


function print_stage(title_str, M)
fprintf('\n===== %s  [%d x %d] =====\n', title_str, size(M, 1), size(M, 2));
disp(M);
end


function [feat_fixed, is_padding_step] = resample_to_slots(raw_12xT, cfg)
% 对 12 x T 原始矩阵降采样/补槽到 12 x n_time_slot。逻辑对齐生产代码
% encode_sample 的时间槽处理，区别仅在于此处作用于 raw（未标准化）。
T = size(raw_12xT, 2);
feat_fixed = zeros(cfg.n_feature, cfg.n_time_slot);
is_padding_step = false(cfg.n_time_slot, 1);

if T > cfg.n_time_slot
    if strcmp(cfg.long_sample_mode, 'linear_resample')
        original_axis = 1:T;
        target_axis = linspace(1, T, cfg.n_time_slot);
        for f = 1:cfg.n_feature
            feat_fixed(f, :) = interp1(original_axis, raw_12xT(f, :), target_axis, 'linear');
        end
    else  % 'uniform_pick'
        picked_idx = round(linspace(1, T, cfg.n_time_slot));
        feat_fixed = raw_12xT(:, picked_idx);
    end
elseif T == cfg.n_time_slot
    feat_fixed = raw_12xT;
else
    feat_fixed(:, 1:T) = raw_12xT;
    is_padding_step((T + 1):cfg.n_time_slot) = true;
end
end


function samples = read_samples(data_path, size_path)
% 与 run_preprocess_japanese_vowels.m 内同名局部函数逻辑一致，独立复制
% 以便本演示脚本单独运行（不依赖先跑 run_preprocess）。
size_vec = str2num(fileread(size_path)); %#ok<ST2NM>

fid = fopen(data_path, 'r');
blocks = {};
current = [];
while true
    line = fgetl(fid);
    if ~ischar(line)
        break;
    end
    line = strtrim(line);
    if isempty(line)
        if ~isempty(current)
            blocks{end+1} = current; %#ok<AGROW>
            current = [];
        end
    else
        current = [current; sscanf(line, '%f')']; %#ok<AGROW>
    end
end
if ~isempty(current)
    blocks{end+1} = current;
end
fclose(fid);

samples = struct('sample_id', {}, 'speaker_label', {}, 'within_speaker_id', {}, ...
    'original_T', {}, 'raw_Tx12', {});
idx = 0;
for speaker = 1:numel(size_vec)
    for k = 1:size_vec(speaker)
        idx = idx + 1;
        samples(idx).sample_id = idx;
        samples(idx).speaker_label = speaker;
        samples(idx).within_speaker_id = k;
        samples(idx).original_T = size(blocks{idx}, 1);
        samples(idx).raw_Tx12 = blocks{idx};
    end
end
end
