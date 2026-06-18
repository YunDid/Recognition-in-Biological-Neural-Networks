function [stimulus_spike_data, trial_intervals, total_missed, total_expected] = ...
    jv_stimulus_data(spike_data, active_channels, time_offset, ...
                     trial_window_s, trial_gap_s, ...
                     expected_n_trial, expected_per_trial)
%JV_STIMULUS_DATA Japanese Vowels 单 batch 的 trial 切分与诱发响应提取。
%
% 用途：
%   按 stim_start 间隔识别 trial 边界（容忍漏点），从 NEX spike 数据中提取每 trial
%   窗口内、剔除伪迹后的 active channel spike 时间，并执行三层校验。
%
% 输入：
%   spike_data         - 单 batch NEX 二次导出 mat 内容
%   active_channels    - 1×N 活跃通道索引（1-64）
%   time_offset        - 伪迹排除窗长度（s）
%   trial_window_s     - 每 trial 响应窗长度（s），固定 3.0
%   trial_gap_s        - trial 边界识别阈值（s），固定 5.0
%                        漏点容差见 [[BRC修订 - MCS GUI 点击式协议的固有漏点容差]]
%   expected_n_trial   - 该 batch 期望 trial 数（用于硬校验）
%   expected_per_trial - 该 batch 期望每 trial 非空 step 数（软校验，可空）
%
% 输出：
%   stimulus_spike_data - N×1 cell，每元素为该 active channel 在所有 trial 内的
%                         spike 时间（已剔除伪迹），顺序按字段名遍历
%   trial_intervals     - n_trial×2 矩阵，[trial 起点, trial 起点 + trial_window_s]
%   total_missed        - 该 batch 累计漏点数
%   total_expected      - 该 batch 累计期望非空 step 数
%
% 数据流：
%   stim_start → diff → 间隔 > trial_gap_s 的位置切 trial → 硬校验 trial 数
%             → 期望 vs 实际 step 数（软校验）
%             → 按 trial_intervals 提取 spike → 排除窗剔除伪迹
%
% 校验层级（与容差卡片 §6.2 对齐）：
%   1. 硬校验：实际 trial 数必须等于 expected_n_trial，否则 error
%   2. 单 trial 漏点软校验：missed > 3 时 warning
%   3. 全实验丢失率软校验：由主脚本汇总 total_missed / total_expected 做

field_names = fieldnames(spike_data);
stim_start_times = extractfield(spike_data, field_names{end, 1});
stim_end_times   = extractfield(spike_data, field_names{end - 1, 1});

%% 1. 切 trial（间隔阈值）
gaps = diff(stim_start_times);
trial_break_idx = find(gaps > trial_gap_s);
trial_starts = stim_start_times([1, trial_break_idx + 1]);
n_trial = length(trial_starts);

if n_trial ~= expected_n_trial
    error(['trial 数 %d 与期望 %d 不一致。漏 ≤ 3 不会让 trial 间 10 s 间隔消失，' ...
           '请检查 GUI 坐标 / batch 启动 / NEX 字段名。'], n_trial, expected_n_trial);
end

trial_intervals = [trial_starts; trial_starts + trial_window_s]';

%% 2. 单 trial 漏点软校验
total_missed = 0;
total_expected = 0;

if ~isempty(expected_per_trial)
    if length(expected_per_trial) ~= n_trial
        error('expected_per_trial 长度 %d 与 trial 数 %d 不一致', ...
              length(expected_per_trial), n_trial);
    end

    actual_per_trial = zeros(n_trial, 1);
    for t = 1:n_trial - 1
        actual_per_trial(t) = sum(stim_start_times >= trial_starts(t) & ...
                                   stim_start_times <  trial_starts(t + 1));
    end
    actual_per_trial(n_trial) = sum(stim_start_times >= trial_starts(n_trial));

    for t = 1:n_trial
        missed = expected_per_trial(t) - actual_per_trial(t);
        if missed > 3
            warning('trial %d 漏 %d 个 step，超出容差 (≤ 3)', t, missed);
        end
        if missed > 0
            total_missed = total_missed + missed;
        end
    end
    total_expected = sum(expected_per_trial);
end

%% 3. 伪迹排除窗
exclusion_intervals = [stim_end_times; stim_end_times + time_offset]';

%% 4. 提取每通道 trial 窗内 spike
stimulus_spike_data = cell(length(active_channels), 1);
channel_counter = 0;

for channel_idx = 1:length(field_names)
    channel_name = field_names{channel_idx, 1};

    if startsWith(channel_name, 'AnSt_Label_E_00159') && ...
       ~contains(channel_name, 'cluster') && ...
       ~contains(channel_name, 'unsorted') && ...
       ~contains(channel_name, 'Ref') && ...
       ~contains(channel_name, 'EvSt')

        row    = str2double(channel_name(21));
        column = str2double(channel_name(20));
        channel_number = (column - 1) * 8 + row;

        if ismember(channel_number, active_channels)
            all_spike_times = extractfield(spike_data, channel_name);

            in_trial = false(size(all_spike_times));
            for t = 1:n_trial
                in_trial = in_trial | ...
                    (all_spike_times >= trial_intervals(t, 1) & ...
                     all_spike_times <= trial_intervals(t, 2));
            end
            trial_spikes = all_spike_times(in_trial);

            if time_offset ~= 0
                in_exclusion = false(size(trial_spikes));
                for e = 1:size(exclusion_intervals, 1)
                    in_exclusion = in_exclusion | ...
                        (trial_spikes >= exclusion_intervals(e, 1) & ...
                         trial_spikes <= exclusion_intervals(e, 2));
                end
                final_spikes = trial_spikes(~in_exclusion);
            else
                final_spikes = trial_spikes;
            end

            channel_counter = channel_counter + 1;
            stimulus_spike_data{channel_counter, 1} = final_spikes;
        end
    end
end
end
