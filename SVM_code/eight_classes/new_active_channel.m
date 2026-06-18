function [active_channels] = new_active_channel(spike_data, spike_data2, spike_data3, spike_data4, t, up_weights, down_weights)
% ACTIVE_CHANNEL 识别多组尖峰数据中最活跃的通道
%
% 输入参数:
%   spike_data_sets - 包含多个spike数据结构的cell数组
%   t - 时间偏移量，用于计算分析间隔
%   up_weights - 向上权重矢量(64个元素)
%   down_weights - 向下权重矢量(64个元素)
%
% 输出参数:
%   active_channels - 排序后的活跃通道列表
%
% 示例:
%   active_ch = active_channel({spike_data1, spike_data2, spike_data3, spike_data4}, 0.1, up, down);

    spike_data_sets = {spike_data, spike_data2, spike_data3, spike_data4};
    
    % 初始化总活动计数
    total_activity = zeros(1, 64);
    
    % 处理每个spike数据结构
    for data_idx = 1:length(spike_data_sets)
        spike_data = spike_data_sets{data_idx};
        
        % 提取field名称
        field_names = fieldnames(spike_data);
        
        % 提取刺激开始和结束时间
        stim_start = extractfield(spike_data, field_names{end, 1});
        stim_end = extractfield(spike_data, field_names{end - 1, 1});
        
        % 计算分析间隔
        intervals = calculate_intervals(stim_start, stim_end, t);
        
        % 计算每个通道在每个间隔内的尖峰次数
        evoked_data = calculate_spike_counts(spike_data, field_names, intervals);
        
        % 累加到总活动
        total_activity = total_activity + sum(evoked_data);
    end
    
    % 应用权重并选择活跃通道
    activity_up = total_activity .* up_weights;
    activity_down = total_activity .* down_weights;
    
    % 选择最活跃的向上和向下通道
    [~, sorted_up_indices] = sort(activity_up, 'descend');
    up_channels = sorted_up_indices(1:16);
    
    [~, sorted_down_indices] = sort(activity_down, 'descend');
    down_channels = sorted_down_indices(1:16);
    
    % 合并并排序活跃通道
    channels = [up_channels, down_channels];
    active_channels = sort(channels);
end

function intervals = calculate_intervals(stim_start, stim_end, t)

    disp(size(stim_end))
    disp(size(stim_start))
    % 计算分析间隔
    intervals = [stim_end + t; 
                 [stim_start(2:end), stim_end(end) + 0.25]];
    
    % 调整特定间隔
    for m = 6:6:length(intervals)
        intervals(2, m) = intervals(1, m) + 0.24;
    end
end

function spike_counts = calculate_spike_counts(spike_data, field_names, intervals)
    % 初始化spike计数矩阵
    num_intervals = size(intervals, 2);
    spike_counts = zeros(num_intervals, 64);
    
    % 计算每个通道的spike计数
    for k = 1:length(field_names)
        % 获取通道名称和数据
        channel_name = field_names{k, 1};
        
        if startsWith(channel_name, 'AnSt_Label_E_00159') && ... % 使用前缀筛选
           ~contains(channel_name, 'cluster') && ... % 不包含cluster
           ~contains(channel_name, 'unsorted') && ... % 不包含unsorted
           ~contains(channel_name, 'Ref') && ... % 不包含Ref
           ~contains(channel_name, 'EvSt') % 不包含EvSt
        
            % 从channel名称中提取行和列（假设格式一致）
            row = str2double(channel_name(21));
            column = str2double(channel_name(20));

            % 计算通道索引
            channel_idx = (column - 1) * 8 + row;

            % 提取该通道的spike时间
            spike_times = extractfield(spike_data, channel_name);

            % 计算每个间隔内的spike数量
            for n = 1:num_intervals
                time_start = intervals(1, n);
                time_end = intervals(2, n);
                spike_count = sum(spike_times > time_start & spike_times <= time_end);
                spike_counts(n, channel_idx) = spike_count;
            end
        end
    end
end