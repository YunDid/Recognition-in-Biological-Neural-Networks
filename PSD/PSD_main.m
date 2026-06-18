clc
clear
close all
path="/Users/mengweiwei/Desktop/zaiti012.abf";
[dataa, si]=abfload(path);
eeg_data=dataa(:,1);
fres=0.5;
%%
[Pxx, f, t] = calculate_spectrum(eeg_data, si, fres);
%%
% 转换单位：V²/Hz → µV²/Hz
psd_curve = mean(Pxx, 2);  % [freq × 1]
psd_curve_uv=psd_curve* 1e12;
figure
plot(f, psd_curve_uv);
ylabel('Power (µV^2/Hz)');
% xlim([1 50]);
xlabel('Frequency (Hz)');
title('Averaged Power Spectral Density (from Spectrogram)');
%%
% 绘图（可选转为 dB）
figure;
plot(f, 10*log10(psd_curve));  % 转 dB 单位
% xlim([1 50]);
xlabel('Frequency (Hz)');
ylabel('Power (dB/Hz)');
title('Averaged Power Spectral Density (from Spectrogram)');
grid on;

