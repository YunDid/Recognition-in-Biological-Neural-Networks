function validate_preprocess_japanese_vowels(date_tag)
%VALIDATE_PREPROCESS_JAPANESE_VOWELS 抽查事件表统计。
%
% 用途：
%   加载 run_preprocess 生成的事件表 mat，打印 speaker / batch / padding /
%   active_site 分布与首个 trial 的中间结果，供肉眼核对。仅打印，不写文件。
%
% 使用方法：
%   validate_preprocess_japanese_vowels                 % 用今天日期
%   validate_preprocess_japanese_vowels('20260502')     % 显式指定日期
%
% 输入：
%   date_tag - 'YYYYMMDD' 字符串，可省略
%   依赖文件：<cfg.day_dir>/japanese_vowels_mcs_<protocol_tag>_events.mat
%
% 输出：仅控制台打印
%   - 配置回显（feature_route / encoding_k / score_mode / long_sample_mode）
%   - speaker / batch / batch×speaker 样本数分布
%   - active_site / padding 分布
%   - 首个 trial 的 meta、6 位点得分矩阵、每步选位

if nargin < 1
    date_tag = '';
end
clc;
cfg = config_japanese_vowels(date_tag);
fprintf('date_tag=%s, seed=%d, cell_id=%s\nday_dir=%s\n', ...
    cfg.date_tag, cfg.random_seed, cfg.cell_id, cfg.day_dir);

protocol_path = fullfile(cfg.day_dir, sprintf('japanese_vowels_mcs_%s_events.mat', cfg.protocol_tag));
S = load(protocol_path, 'cfg', 'samples', 'mu', 'sigma', 'trial_table', 'event_table', 'sample_features');

fprintf('Protocol: %s\n', protocol_path);
fprintf('feature_route=%s, encoding_k=%d, score_mode=%s, long_sample_mode=%s\n', ...
    S.cfg.feature_route, S.cfg.encoding_k, S.cfg.score_mode, S.cfg.long_sample_mode);
fprintf('Trials=%d, Events=%d\n', height(S.trial_table), height(S.event_table));

speaker_summary = groupsummary(S.trial_table, 'speaker_label');
batch_summary = groupsummary(S.trial_table, 'batch_id');
batch_speaker_summary = groupsummary(S.trial_table, {'batch_id', 'speaker_label'});
site_summary = groupsummary(S.event_table, 'active_site');
padding_summary = groupsummary(S.event_table, 'is_padding');

fprintf('\n[每个 speaker 样本数]\n');
disp(speaker_summary);
fprintf('[每个 batch 样本数]\n');
disp(batch_summary);
fprintf('[每个 batch×speaker 样本数（应全为 %d）]\n', cfg.rounds_per_batch);
disp(batch_speaker_summary);
fprintf('[active_site 分布（top-1 主位点；0=空槽不刺激）]\n');
disp(site_summary);
if ismember('active_site_2', S.event_table.Properties.VariableNames) && S.cfg.encoding_k >= 2
    fprintf('[active_site_2 分布（top-2 次位点；0=空槽）]\n');
    disp(groupsummary(S.event_table, 'active_site_2'));
end
fprintf('[padding 分布]\n');
disp(padding_summary);

fprintf('\n[首个 trial meta]\n');
disp(S.trial_table(1, :));
fprintf('[首个 trial 的 6 位点得分矩阵 (6 x 12)]\n');
disp(S.sample_features(1).site_score);
fprintf('[首个 trial 每步选位 (top-%d；列1=time_step, 中间=选中位点(0=空), 末列=is_padding)]\n', S.cfg.encoding_k);
disp([(1:S.cfg.n_time_slot)', ...
    S.sample_features(1).active_site_per_step, ...
    double(S.sample_features(1).is_padding_step(:))]);
end
