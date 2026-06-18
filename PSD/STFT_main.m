%% 生成示例EEG信号
Fs = 1000;  % 采样率（Hz）
t = 0:1/Fs:60-1/Fs;  % 时间向量（10秒）
freq1 = 10;  % 第一频段频率（Hz）
freq2 = 20;  % 第二频段频率（Hz）
eeg_data = sin(2*pi*freq1*t) + 0.5*sin(2*pi*freq2*t);% 生成带有两个不同频段的模拟信号
%%
clc
clear
close all
path="/Users/mengweiwei/Desktop/zaiti012.abf";
path2="/Users/mengweiwei/Desktop";
[dataa, si]=abfload(path);
eeg_data=dataa(:,2);
Fs=si;
%% 计算短时傅里叶变换（STFT）
window = hamming(256);  % 使用汉明窗
noverlap = 128;  % 重叠样本数
nfft = 2048;  % FFT点数
%%
[S, F, T] = stft(eeg_data, Fs, 'Window', window, 'OverlapLength', noverlap, 'FFTLength', nfft);
%% 绘制时频图
figure;
imagesc(T, F, abs(S));
axis xy;  % 保持y轴从低频到高频
ylim([1 100]);  % 只显示~Hz频段
colormap jet;
% 添加 colorbar 并标注单位
colorbar_label =colorbar;
ylabel(colorbar_label , 'Amplitude (\muV)');  % 根据你的实际单位
% clim([0 0.01]);  % 可以根据需要设置色条范围
% 设置图标题和坐标轴标签
title('EEG Time-Frequency Analysis');
xlabel('Time [s]');
ylabel('Frequency [Hz]');


% 绘制时频图，使用dB转换
figure;
imagesc(T, F, 20*log10(abs(S) + eps));  % dB转换
axis xy;
ylim([1 50]);  % 显示1-50 Hz频段
% colorbar;  % 显示颜色条
% 给colorbar添加标签（单位）
% clim([-50 50]);  % 可以根据需要设置色条范围
colorbar_label = colorbar;
ylabel(colorbar_label, 'Magnitude (dB)');  % 修改colorbar的标签，显示单位
title('EEG Time-Frequency Analysis (dB, 1-50 Hz)');
xlabel('Time [s]');
ylabel('Frequency [Hz]');


% savepath=fullfile(path2, ['timefreq.png']);
% savepath=erase(savepath,'.abf');
% print(gcf,savepath,'-r600','-djpeg')%保存图片