function [active_channels] = jv_active_channel(spike_data_sets, t, up_weights, down_weights, trial_gap_s)
%JV_ACTIVE_CHANNEL Japanese Vowels 八分类任务的活跃通道选择。
%
% 用途：
%   多 batch（任意数量）下的 active channel 选择。沿用旧八分类
%   new_active_channel.m 的 up/down 平衡机制：每列前 4 行为 up、后 4 行为 down，
%   按全实验 evoked spike 总数分别选 top 16 通道，合并后 32 通道。
%
% 输入：
%   spike_data_sets - 1×N cell，每个元素为一个 batch 的 NEX 二次导出 mat 内容
%   t               - 伪迹排除窗长度（s），与下游 jv_stimulus_data 的 time_offset 一致
%   up_weights      - 1×64 二值向量（每列前 4 行 = 1，后 4 行 = 0）
%   down_weights    - 1×64 二值向量（每列前 4 行 = 0，后 4 行 = 1）
%   trial_gap_s     - trial 边界识别阈值（s），用于识别 trial 末尾 step 缩窗。
%                     与 jv_stimulus_data 一致；漏点容差见
%                     [[BRC修订 - MCS GUI 点击式协议的固有漏点容差]] §6.1。
%
% 输出：
%   active_channels - 1×32 活跃通道索引（1-64），数值升序
%
% 数据流：
%   每 batch → 提取 stim_start / stim_end → 计算每 step 的 evoked 区间
%           → 累加每通道 evoked spike 数 → up/down 加权 → top 16+16 → 合并
%
% 与旧 new_active_channel 的差异：
%   1. 接口由硬编码 4 个参数 (d, d2, d3, d4) 改为 1×N cell（支持任意 batch 数）
%   2. trial 末尾 step 的窗口缩窗判定由 m=6:6:length 改为基于 stim_start 间隔
%      （diff > trial_gap_s 视为 trial 末尾），与 JV 任务可变 step 数兼容
%   3. up/down 选择逻辑、64 通道索引体系、top 16+16 合并完全保留

n_batch = length(spike_data_sets);
total_activity = zeros(1, 64);

for b = 1:n_batch
    spike_data = spike_data_sets{b};
    field_names = fieldnames(spike_data);

    stim_start = extractfield(spike_data, field_names{end, 1});
    stim_end   = extractfield(spike_data, field_names{end - 1, 1});

    intervals = calculate_intervals(stim_start, stim_end, t, trial_gap_s);
    evoked_data = calculate_spike_counts(spike_data, field_names, intervals);
    total_activity = total_activity + sum(evoked_data);
end

activity_up   = total_activity .* up_weights;
activity_down = total_activity .* down_weights;

[~, sorted_up_indices]   = sort(activity_up,   'descend');
up_channels = sorted_up_indices(1:16);

[~, sorted_down_indices] = sort(activity_down, 'descend');
down_channels = sorted_down_indices(1:16);

active_channels = sort([up_channels, down_channels]);
end


function intervals = calculate_intervals(stim_start, stim_end, t, trial_gap_s)
% 每 step 的 evoked 区间：[stim_end + t, 下一 stim_start]。
% trial 末尾 step（包括 batch 最后一个 step）单独缩窗到 0.24 s，避免把
% trial 间 10 s 静息期纳入 evoked 窗。
intervals = [stim_end + t; ...
             [stim_start(2:end), stim_end(end) + 0.25]];

gap = [diff(stim_start), Inf];
trial_end_steps = find(gap > trial_gap_s);
for k = trial_end_steps
    intervals(2, k) = intervals(1, k) + 0.24;
end
end


function spike_counts = calculate_spike_counts(spike_data, field_names, intervals)
% 按 (column-1)*8 + row 的 64 通道索引体系累加 spike。
% 通道命名前缀 'AnSt_Label_E_00159' 与旧八分类 SVM 代码一致。
num_intervals = size(intervals, 2);
spike_counts = zeros(num_intervals, 64);

for k = 1:length(field_names)
    channel_name = field_names{k, 1};

    if startsWith(channel_name, 'AnSt_Label_E_00159') && ...
       ~contains(channel_name, 'cluster') && ...
       ~contains(channel_name, 'unsorted') && ...
       ~contains(channel_name, 'Ref') && ...
       ~contains(channel_name, 'EvSt')

        row    = str2double(channel_name(21));
        column = str2double(channel_name(20));
        channel_idx = (column - 1) * 8 + row;

        spike_times = extractfield(spike_data, channel_name);

        for n = 1:num_intervals
            spike_counts(n, channel_idx) = sum( ...
                spike_times >  intervals(1, n) & ...
                spike_times <= intervals(2, n));
        end
    end
end
end
