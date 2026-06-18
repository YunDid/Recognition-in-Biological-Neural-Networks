function [Pxx, f, t] = calculate_spectrum(data, SR, fres)
% 计算 EEG 信号的频谱图（Spectrogram）
% Inputs:
%   data - 脑电数据
%   SR  - 采样率
%   fres  - 频率分辨率（0.5 或 1.0 Hz）
% Outputs:
%   Pxx   - EEG1 功率谱图 [freq x time]
%   f     - 频率轴
%   t     - 时间轴

if nargin < 3
    fres = 0.5;  % 默认频率分辨率为 0.5 Hz
end

% 加载采样率
swin = round(SR) * 5;              % 窗口为 5 秒数据
fft_win = round(swin / 5);         % 默认 FFT 窗口为 1 秒

if fres == 1.0
    % 使用 1 秒 FFT 窗
elseif fres == 0.5
    fft_win = 2 * fft_win;         % 使用 2 秒 FFT 窗
else
    error('Unsupported resolution. Use fres = 1.0 or 0.5');
end

% 加载 EEG 数据
eeg_data = data;
EEG = double(eeg_data(:));  % 保证为列向量

% 计算 EEG 功率谱图
[Pxx, f, t] = spectral_density(EEG, swin, fft_win, 1/SR);
% 保存EEG
% spfile = fullfile(savepath, ['sp_' name '.mat']);
% SP = Pxx;
% save(spfile, 'SP', 'f', 't');
end

