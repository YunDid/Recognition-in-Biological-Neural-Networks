function run_preprocess_japanese_vowels(date_tag)
%RUN_PREPROCESS_JAPANESE_VOWELS 生成 Japanese Vowels 六位点 MCS 事件表。
%
% 用途：
%   读取 Japanese Vowels 数据集，筛选 speaker 1-8、z-score 标准化、取绝对值、
%   固定 12 时间槽、压缩到 6 位点、每个有效时间槽按得分选 top-k 位点
%   （k = cfg.encoding_k，1 或 2），按 6 batches × 5 rounds × 8 speakers
%   = 240 trials 平衡随机化，输出事件表 mat。
%   同日所有细胞共用同一份事件表（trial 顺序由 date_tag 作种子）。
%
% 使用方法：
%   run_preprocess_japanese_vowels                 % 用今天日期
%   run_preprocess_japanese_vowels('20260502')     % 显式指定日期
%
% 输入：
%   date_tag - 'YYYYMMDD' 字符串，可省略（默认取系统当天）
%   依赖文件：cfg.data_dir 下的 ae.train、size_ae.train（由 config 指定）
%
% 输出：
%   <cfg.day_dir>/japanese_vowels_mcs_<protocol_tag>_events.mat
%   含变量：cfg、samples、mu、sigma、trial_table、event_table、sample_features
%
% 字段含义见 [[BRC修订 - Japanese Vowels LPC 特征到六位点刺激范式]] 卡片。
%
% 数据流：
%   <data_dir>/ae.train, size_ae.train         ← 输入
%       └── 解析 → 筛选 speaker 1-8 → z-score → 取绝对值
%       └── 固定 12 时间槽 → 压缩 6 位点 → top-k 选位（k=encoding_k）
%       └── 按 batch×round×speaker 平衡随机化
%   <day_dir>/japanese_vowels_mcs_<tag>_events.mat   ← 输出（同日所有细胞共享）

if nargin < 1
    date_tag = '';
end
clc;
cfg = config_japanese_vowels(date_tag);
if ~exist(cfg.day_dir, 'dir')
    mkdir(cfg.day_dir);
end
fprintf('date_tag=%s, seed=%d, cell_id=%s\nday_dir=%s\n', ...
    cfg.date_tag, cfg.random_seed, cfg.cell_id, cfg.day_dir);

samples = read_samples(fullfile(cfg.data_dir, cfg.input_file), ...
    fullfile(cfg.data_dir, cfg.size_file));
samples = samples(ismember([samples.speaker_label], cfg.selected_speakers));

[mu, sigma] = compute_feature_stats(samples);
[trial_table, event_table, sample_features] = build_event_table(samples, mu, sigma, cfg);

protocol_file = sprintf('japanese_vowels_mcs_%s_events.mat', cfg.protocol_tag);
save(fullfile(cfg.day_dir, protocol_file), ...
    'cfg', 'samples', 'mu', 'sigma', 'trial_table', 'event_table', 'sample_features');

fprintf('Saved %d trials, %d events to %s\n', height(trial_table), height(event_table), protocol_file);
end


function samples = read_samples(data_path, size_path)
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


function [mu, sigma] = compute_feature_stats(samples)
all_frames = vertcat(samples.raw_Tx12);
mu = mean(all_frames, 1);
sigma = std(all_frames, 0, 1);
sigma(sigma == 0) = 1;
end


function [trial_table, event_table, sample_features] = build_event_table(samples, mu, sigma, cfg)
rng(cfg.random_seed);

n_speaker = numel(cfg.selected_speakers);
n_trial = n_speaker * cfg.samples_per_speaker;

% 每个 speaker 内部样本顺序打乱
samples_by_speaker = cell(n_speaker, 1);
for i = 1:n_speaker
    speaker = cfg.selected_speakers(i);
    idx = find([samples.speaker_label] == speaker);
    samples_by_speaker{i} = idx(randperm(numel(idx)));
end

% 按 batch × round × speaker 平衡铺排
ordered_idx = zeros(n_trial, 1);
batch_id = zeros(n_trial, 1);
round_id = zeros(n_trial, 1);
trial_in_batch = zeros(n_trial, 1);
global_trial_id = zeros(n_trial, 1);
row = 0;
for batch = 1:cfg.n_batch
    for round_i = 1:cfg.rounds_per_batch
        class_order = randperm(n_speaker);
        for c = 1:n_speaker
            speaker_idx = class_order(c);
            pick_id = (batch - 1) * cfg.rounds_per_batch + round_i;
            row = row + 1;
            ordered_idx(row) = samples_by_speaker{speaker_idx}(pick_id);
            batch_id(row) = batch;
            round_id(row) = round_i;
            trial_in_batch(row) = (round_i - 1) * n_speaker + c;
            global_trial_id(row) = row;
        end
    end
end

trial_sample_id = [samples(ordered_idx).sample_id]';
speaker_label = [samples(ordered_idx).speaker_label]';
within_speaker_id = [samples(ordered_idx).within_speaker_id]';
original_T = [samples(ordered_idx).original_T]';

trial_table = table(global_trial_id, batch_id, round_id, trial_in_batch, ...
    trial_sample_id, speaker_label, within_speaker_id, original_T, ...
    'VariableNames', {'global_trial_id', 'batch_id', 'round_id', 'trial_id', ...
    'sample_id', 'speaker_label', 'within_speaker_id', 'original_T'});

% 逐 trial 编码并展开为事件长表
n_event = n_trial * cfg.n_time_slot;
ev_global = zeros(n_event, 1);
ev_batch = zeros(n_event, 1);
ev_round = zeros(n_event, 1);
ev_trial = zeros(n_event, 1);
ev_sample = zeros(n_event, 1);
ev_speaker = zeros(n_event, 1);
ev_step = zeros(n_event, 1);
ev_padding = false(n_event, 1);
ev_active = zeros(n_event, 1);     % top-1 主位点（0=空槽）
ev_active2 = zeros(n_event, 1);    % top-2 次位点（encoding_k>=2 时填，否则恒为 0）
ev_score = zeros(n_event, cfg.n_site);

sample_features = struct('sample_id', {}, 'speaker_label', {}, 'raw_Tx12', {}, ...
    'feat_zabs', {}, 'feat_fixed', {}, 'site_score', {}, 'active_site_per_step', {}, ...
    'is_padding_step', {}, 'feature_route', {});

for tr = 1:n_trial
    sample = samples(ordered_idx(tr));
    [feat_zabs, feat_fixed, site_score, active_site_per_step, is_padding_step] = ...
        encode_sample(sample.raw_Tx12, mu, sigma, cfg);

    sample_features(tr).sample_id = sample.sample_id;
    sample_features(tr).speaker_label = sample.speaker_label;
    sample_features(tr).raw_Tx12 = sample.raw_Tx12;
    sample_features(tr).feat_zabs = feat_zabs;
    sample_features(tr).feat_fixed = feat_fixed;
    sample_features(tr).site_score = site_score;
    sample_features(tr).active_site_per_step = active_site_per_step;
    sample_features(tr).is_padding_step = is_padding_step;
    sample_features(tr).feature_route = cfg.feature_route;

    for t = 1:cfg.n_time_slot
        e = (tr - 1) * cfg.n_time_slot + t;
        ev_global(e) = global_trial_id(tr);
        ev_batch(e) = batch_id(tr);
        ev_round(e) = round_id(tr);
        ev_trial(e) = trial_in_batch(tr);
        ev_sample(e) = sample.sample_id;
        ev_speaker(e) = sample.speaker_label;
        ev_step(e) = t;
        ev_padding(e) = is_padding_step(t);
        ev_active(e) = active_site_per_step(t, 1);
        if cfg.encoding_k >= 2
            ev_active2(e) = active_site_per_step(t, 2);
        end
        ev_score(e, :) = site_score(:, t)';
    end
end

event_table = table(ev_global, ev_batch, ev_round, ev_trial, ev_sample, ev_speaker, ...
    ev_step, ev_padding, ev_active, ev_active2, ...
    ev_score(:,1), ev_score(:,2), ev_score(:,3), ev_score(:,4), ev_score(:,5), ev_score(:,6), ...
    'VariableNames', {'global_trial_id', 'batch_id', 'round_id', 'trial_id', ...
    'sample_id', 'speaker_label', 'time_step', 'is_padding', 'active_site', 'active_site_2', ...
    'score_site1', 'score_site2', 'score_site3', 'score_site4', 'score_site5', 'score_site6'});
end


function [feat_zabs, feat_fixed, site_score, active_site_per_step, is_padding_step] = ...
    encode_sample(raw_Tx12, mu, sigma, cfg)
% 单条样本编码：z-score abs -> 固定 12 时间槽 -> 6 位点得分 -> 每槽 top-k 位点
% （k=cfg.encoding_k）。active_site_per_step 为 n_time_slot × k 矩阵，按得分降序排，
% padding 槽整行为 0。
z_Tx12 = (raw_Tx12 - mu) ./ sigma;
feat_zabs = abs(z_Tx12)';   % 12 x T，对应 cfg.score_mode = 'abs_z'

T = size(feat_zabs, 2);
feat_fixed = zeros(cfg.n_feature, cfg.n_time_slot);
is_padding_step = false(cfg.n_time_slot, 1);

if T > cfg.n_time_slot
    if strcmp(cfg.long_sample_mode, 'linear_resample')
        original_axis = 1:T;
        target_axis = linspace(1, T, cfg.n_time_slot);
        for f = 1:cfg.n_feature
            feat_fixed(f, :) = interp1(original_axis, feat_zabs(f, :), target_axis, 'linear');
        end
    else  % 'uniform_pick'
        picked_idx = round(linspace(1, T, cfg.n_time_slot));
        feat_fixed = feat_zabs(:, picked_idx);
    end
elseif T == cfg.n_time_slot
    feat_fixed = feat_zabs;
else
    feat_fixed(:, 1:T) = feat_zabs;
    is_padding_step((T + 1):cfg.n_time_slot) = true;
end

if strcmp(cfg.feature_route, 'first6')
    site_score = feat_fixed(1:cfg.n_site, :);
else  % 'adjacent_mean'
    site_score = zeros(cfg.n_site, cfg.n_time_slot);
    for site = 1:cfg.n_site
        site_score(site, :) = mean(feat_fixed([2*site-1, 2*site], :), 1);
    end
end

active_site_per_step = zeros(cfg.n_time_slot, cfg.encoding_k);
for t = 1:cfg.n_time_slot
    if ~is_padding_step(t)
        [~, order] = sort(site_score(:, t), 'descend');
        kk = min(cfg.encoding_k, numel(order));
        active_site_per_step(t, 1:kk) = order(1:kk)';
    end
end
end
