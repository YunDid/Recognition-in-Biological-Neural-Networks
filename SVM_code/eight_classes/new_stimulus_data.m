function [stimulus_spike_data, stimulus_intervals] = new_stimulus_data(spike_data, active_channels, time_offset)
% STIMULUS_DATA 从神经元尖峰数据中提取特定活跃通道的刺激相关数据
%
% 输入参数:
%   spike_data - 包含神经元尖峰时间的数据结构
%   active_channels - 需要分析的活跃通道索引数组
%   time_offset - 刺激后的时间偏移量（用于定义排除区间）
%
% 输出参数:
%   stimulus_spike_data - 包含每个活跃通道刺激相关尖峰数据的cell数组
%   stimulus_intervals - 用于提取刺激区间的时间范围矩阵 [开始时间, 结束时间]
%
% 示例:
%   [stim_data, intervals] = stimulus_data(spike_data, active_ch, 0.1);

    % 提取字段名称
    field_names = fieldnames(spike_data);
    
    % 提取刺激开始和结束时间
    stim_start_times = extractfield(spike_data, field_names{end, 1});
    stim_end_times = extractfield(spike_data, field_names{end - 1, 1});
    
    % 计算排除区间 - 刺激结束后的短暂时间段
    % 格式: [刺激结束时间, 刺激结束时间+时间偏移]
    exclusion_intervals = [stim_end_times; stim_end_times + time_offset]';
    
    % 计算刺激区间 - 每6个刺激选一个，持续1.5秒
    % 格式: [选定的刺激开始时间, 开始时间+1.5秒]
    stimulus_intervals = [stim_start_times(1:6:end); stim_start_times(1:6:end) + 1.5]';
    
    % 初始化输出 - 存储每个活跃通道的尖峰数据
    stimulus_spike_data = cell(length(active_channels), 1);
    
    % 初始化计数器
    channel_counter = 0;
    
    % 处理每个通道的数据
    for channel_idx = 1:length(field_names)
       channel_name = field_names{channel_idx, 1};
       
       if startsWith(channel_name, 'AnSt_Label_E_00159') && ... % 使用前缀筛选
           ~contains(channel_name, 'cluster') && ... % 不包含cluster
           ~contains(channel_name, 'unsorted') && ... % 不包含unsorted
           ~contains(channel_name, 'Ref') && ... % 不包含Ref
           ~contains(channel_name, 'EvSt') % 不包含EvSt

            % 从通道名称中提取行和列信息
            row = str2double(channel_name(21));
            column = str2double(channel_name(20));

            % 计算通道编号
            channel_number = (column - 1) * 8 + row;

            % 检查是否为活跃通道
            if ismember(channel_number, active_channels)
                % 提取该通道的所有尖峰时间
                all_spike_times = extractfield(spike_data, channel_name);

                % 初始化逻辑索引数组 - 用于标记落在刺激区间内的尖峰
                in_stimulus_interval = false(size(all_spike_times));

                % 对每个刺激区间进行迭代，标记落在区间内的尖峰
                for interval_idx = 1:size(stimulus_intervals, 1)
                    interval_start = stimulus_intervals(interval_idx, 1);
                    interval_end = stimulus_intervals(interval_idx, 2);

                    % 找到落在当前区间内的尖峰索引
                    spikes_in_interval = (all_spike_times >= interval_start) & (all_spike_times <= interval_end);

                    % 将这些索引标记为true
                    in_stimulus_interval = in_stimulus_interval | spikes_in_interval;
                end

                % 提取落在刺激区间内的尖峰数据
                stimulus_spikes = all_spike_times(in_stimulus_interval);

                % 如果时间偏移不为0，进一步排除落在排除区间内的尖峰
                if time_offset ~= 0
                    % 初始化逻辑索引 - 用于标记落在排除区间内的尖峰
                    in_exclusion_interval = false(size(stimulus_spikes));

                    % 对每个排除区间进行迭代
                    for interval_idx = 1:size(exclusion_intervals, 1)
                        exclusion_start = exclusion_intervals(interval_idx, 1);
                        exclusion_end = exclusion_intervals(interval_idx, 2);

                        % 找到落在当前排除区间内的尖峰
                        spikes_to_exclude = (stimulus_spikes >= exclusion_start) & (stimulus_spikes <= exclusion_end);

                        % 标记这些尖峰
                        in_exclusion_interval = in_exclusion_interval | spikes_to_exclude;
                    end

                    % 保留不在排除区间内的尖峰
                    final_spikes = stimulus_spikes(~in_exclusion_interval);
                else
                    % 如果时间偏移为0，不需要进一步排除
                    final_spikes = stimulus_spikes;
                end

                % 更新计数器并存储结果
                channel_counter = channel_counter + 1;
                stimulus_spike_data{channel_counter, 1} = final_spikes;

                % 可选：显示进度
                % fprintf('处理进度: %d/%d\n', channel_counter, length(active_channels));
            end
       end
    end
end