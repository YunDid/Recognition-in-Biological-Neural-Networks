function [transformed_data, spike_counts] = new_instance(stimulus_spike_data, stimulus_intervals, bin_width)
% INSTANCE 分析神经元尖峰数据在时间窗口中的分布
%
% 输入参数:
%   stimulus_spike_data - 包含各通道尖峰时间的cell数组 (从stimulus_data函数获得)
%   stimulus_intervals - 刺激时间区间矩阵 [开始时间, 结束时间]
%   bin_width - 时间窗口宽度(秒)，用于将刺激区间分割成等宽的bin
%
% 输出参数:
%   transformed_data - 经transform函数处理后的数据
%   spike_counts - 每个时间窗口内各通道的尖峰计数矩阵，维度为[窗口数, 通道数]
%
% 示例:
%   [transformed_data, spike_counts] = instance(sti_data, interval2, 0.05);

    % 计算每个刺激区间需要划分的窗口数
    % 假设每个刺激区间长度为1.5秒
    bins_per_interval = 1.5 / bin_width;
    
    % 获取所有刺激区间的起始时间
    interval_start_times = stimulus_intervals(:,1)';
    
    % 初始化所有窗口的起始时间数组
    bin_start_times = [];
    
    % 为每个刺激区间创建等间隔的时间窗口起始点
    for interval_idx = 1:length(interval_start_times)
        % 获取当前刺激区间的起始时间
        current_interval_start = interval_start_times(interval_idx);
        
        % 为当前区间创建所有窗口的起始时间
        for bin_idx = 0:(bins_per_interval-1)
            bin_start_times = [bin_start_times, current_interval_start + bin_idx * bin_width];
        end
    end
    
    % 对起始时间进行排序（确保时间顺序）
    bin_start_times = sort(bin_start_times);
    
    % 计算每个窗口的结束时间
    bin_end_times = bin_start_times + bin_width;
    
    % 组合起始和结束时间
    time_bins = [bin_start_times; bin_end_times];
    
    % 初始化尖峰计数矩阵
    % 维度: [窗口数, 通道数]
    spike_counts = zeros(length(bin_start_times), length(stimulus_spike_data));
    
    % 对每个通道进行处理
    for channel_idx = 1:length(stimulus_spike_data)
        % 获取当前通道的尖峰时间
        channel_spikes = stimulus_spike_data{channel_idx, 1};
        
        % 对每个时间窗口计算尖峰数量
        for bin_idx = 1:length(bin_start_times)
            % 获取当前窗口的时间范围
            window_start = time_bins(1, bin_idx);
            window_end = time_bins(2, bin_idx);
            
            % 计算落在当前窗口内的尖峰数量
            spikes_in_window = sum(channel_spikes > window_start & channel_spikes <= window_end);
            
            % 存储计数结果
            spike_counts(bin_idx, channel_idx) = spikes_in_window;
        end
    end
    
    % 使用transform函数进一步处理数据
    % 假设transform函数需要尖峰计数矩阵、每个区间的窗口数和通道数作为参数
    [transformed_data] = transform(spike_counts, bins_per_interval, length(stimulus_spike_data));
end