function [pxx, f] = power_spectrum(data, length, dt)
    % 计算功率谱密度（PSD）单位为 V^2/Hz
    % 输入：
    %   data  - 一维信号向量
    %   length - 每个 Welch 窗口的点数（必须为偶数）
    %   dt    - 采样时间间隔（单位：秒）
    %
    % 输出：
    %   pxx   - 功率谱密度 [V^2/Hz]
    %   f     - 频率轴 [Hz]

    Fs = 1 / dt;  % 采样率
    nfft = length;  % FFT 长度
    window = hann(length);  % Hann 窗口
    noverlap = length / 2;  % 50% 重叠

    [pxx, f] = pwelch(data, window, noverlap, nfft, Fs);
end
