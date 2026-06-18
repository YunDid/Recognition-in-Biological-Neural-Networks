function [Pow, f, t] = spectral_density(data, swin, nfft, dt)
% 功能：使用 Welch 方法，计算时间序列 data 的频谱图（spectrogram）
% 参数：
%   data   - 一维时间序列（如 EEG）
%   swin - 每个滑动窗口的采样点数（如 5s * Fs）
%   nfft   - 每个窗口的 FFT 长度（推荐 = length）
%   dt     - 每个采样点的时间间隔（秒）
%
% 返回：
%   Pow    - [频率 × 时间] 的功率谱图（单位：V^2/Hz）
%   f      - 频率轴（Hz）
%   t      - 时间轴（每个窗口的中心时间）

    n = length(data);                      % 原始数据长度
    k = ceil(n / swin);                 % 所需窗口数（向上取整）
    padded = [data, zeros(1, swin*k - n)];  % 零填充，保证长度对齐
    
    fdt = swin * dt / 2;                % 两窗口中心的间隔（半窗）
    t = 0:fdt:(fdt*(2*k - 2));            % 时间轴，共 2k-1 个窗口
    
    fs = 1 / dt;                          % 采样率
    f = linspace(0, fs/2, floor(nfft/2)+1);  % 频率轴 (仅正频率部分)
    Pow = zeros(length(f), 2*k - 1);      % 初始化功率谱矩阵
    
    j = 1;
    for i = 0:(k-2)
        % 非重叠窗
        idx1 = i * swin + 1;
        idx2 = idx1 + swin - 1;
        w1 = padded(idx1:idx2);
        
        % 半重叠窗（偏移 half-length）
        idx1_shift = idx1 + floor(swin/2);
        idx2_shift = idx2 + floor(swin/2);
        w2 = padded(idx1_shift:idx2_shift);
        
        Pow(:, j)   = power_spectrum(w1, nfft, dt);
        Pow(:, j+1) = power_spectrum(w2, nfft, dt);
        
        j = j + 2;
    end

    % 最后一窗单独处理
    idx_last = (k-1)*swin + 1;
    w_last = padded(idx_last : idx_last + swin - 1);
    Pow(:, j) = power_spectrum(w_last, nfft, dt);
end
