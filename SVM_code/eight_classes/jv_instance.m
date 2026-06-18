function [transformed_data, spike_counts] = jv_instance(stimulus_spike_data, ...
                                                          trial_intervals, ...
                                                          bin_width, ...
                                                          trial_window_s)
%JV_INSTANCE Japanese Vowels 单 batch 的诱发响应分箱与展平。
%
% 用途：
%   把 jv_stimulus_data 输出的 trial 内 spike 时间按固定 bin 切分成尖峰计数矩阵，
%   再用旧八分类 transform.m 展平为 SVM 可用的特征矩阵。
%
% 输入：
%   stimulus_spike_data - N×1 cell，每元素为该 active channel 的 trial 内 spike 时间
%   trial_intervals     - n_trial×2 矩阵，[trial 起点, trial 起点 + trial_window_s]
%   bin_width           - bin 宽度（s），固定 0.01
%   trial_window_s      - trial 窗口长度（s），固定 3.0
%
% 输出：
%   transformed_data - n_trial × (bins_per_trial × n_active_ch) 特征矩阵
%   spike_counts     - (n_trial × bins_per_trial) × n_active_ch 分箱原始计数
%
% 数据流：
%   trial_intervals → 每 trial 切 bins_per_trial 个等宽 bin
%                  → 每 bin × 每 channel 的 spike 计数
%                  → transform.m 展平为单行特征
%
% 与旧 new_instance 的差异：
%   1. trial 窗口长度由硬编码 1.5 s 改为参数 trial_window_s（JV 用 3.0 s）
%   2. 其余逻辑（bin 边界、计数、展平）保持一致

bins_per_trial = trial_window_s / bin_width;
trial_starts = trial_intervals(:, 1)';

bin_start_times = [];
for t = 1:length(trial_starts)
    for b = 0:(bins_per_trial - 1)
        bin_start_times = [bin_start_times, trial_starts(t) + b * bin_width]; %#ok<AGROW>
    end
end
bin_start_times = sort(bin_start_times);
bin_end_times = bin_start_times + bin_width;

n_bin = length(bin_start_times);
n_ch  = length(stimulus_spike_data);
spike_counts = zeros(n_bin, n_ch);

for ch = 1:n_ch
    channel_spikes = stimulus_spike_data{ch, 1};
    for k = 1:n_bin
        spike_counts(k, ch) = sum( ...
            channel_spikes >  bin_start_times(k) & ...
            channel_spikes <= bin_end_times(k));
    end
end

transformed_data = transform(spike_counts, bins_per_trial, n_ch);
end
