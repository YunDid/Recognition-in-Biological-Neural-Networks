function cfg = config_japanese_vowels(date_tag)
%CONFIG_JAPANESE_VOWELS Japanese Vowels MCS 实验全局配置。
%
% 用途：
%   返回所有脚本共用的 cfg 结构体（路径、cell 标识、数据规模、编码路线、
%   时序参数、电极/按钮坐标）。所有脚本入口（run_preprocess / validate /
%   build_expected_stim_count / mcs_run）都先调本函数拿 cfg。
%
% 使用方法：
%   cfg = config_japanese_vowels         % 用今天日期
%   cfg = config_japanese_vowels('20260502')   % 显式指定日期
%
% 输入：
%   date_tag - 'YYYYMMDD' 字符串，可省略（默认取系统当天）。
%              date_tag 同时作为随机种子（cfg.random_seed = str2double(date_tag)），
%              保证同一天 baseline / training / drug 多次预处理得到完全相同的
%              trial 顺序，跨天独立。
%
% 输出：cfg struct，关键字段：
%   cfg.date_tag             - 日期标签
%   cfg.random_seed          - 随机种子
%   cfg.cell_id              - 细胞标识（每盘细胞改本文件下方 cfg.cell_id 这一行）
%   cfg.data_dir             - 数据集目录（含 ae.train、size_ae.train）
%   cfg.experiments_root     - 实验产物根目录
%   cfg.day_dir              - 当日产物目录 = experiments_root / date_tag
%   cfg.cell_dir             - 当盘细胞产物目录 = day_dir / cell_id
%   cfg.input_file           - 'ae.train'
%   cfg.size_file            - 'size_ae.train'
%   cfg.selected_speakers    - 1:8
%   cfg.samples_per_speaker  - 30
%   cfg.n_feature / n_time_slot / n_site - 12 / 12 / 6
%   cfg.feature_route        - 'first6' 或 'adjacent_mean'
%   cfg.encoding_k           - 1=top-1，2=top-2（一个时间槽同时刺激得分最高的 k 个位点）
%   cfg.score_mode           - 'abs_z'
%   cfg.long_sample_mode     - 'linear_resample' 或 'uniform_pick'
%   cfg.protocol_tag         - 协议标识，构成输出文件名后缀
%   cfg.step_interval_s / inter_trial_interval_s - 时序参数
%   cfg.trials_per_batch / rounds_per_batch / n_batch - test 阶段批次结构
%   cfg.stim_site_indices    - 6 个物理电极索引
%   cfg.elec_locx / elec_locy - 60 通道 GUI 坐标
%   cfg.record_btn / stim_test_btn / stim_train_btn / start_stim_btn - 4 个按钮坐标
%
% 落盘约定（由调用方负责 mkdir 后写入）：
%   cfg.day_dir   ← run_preprocess、build_expected_stim_count（同日共享）
%   cfg.cell_dir  ← mcs_run_japanese_vowels（每盘细胞独立）
%
% 迁机器修改清单：
%   1. cfg.cell_id        - 每盘细胞改一次
%   2. cfg.data_dir       - 数据集目录绝对路径
%   3. cfg.experiments_root - 实验产物根目录绝对路径
%   4. cfg.stim_site_indices - 诱发响应筛选后选定的 6 个物理电极索引
%   5. cfg.elec_locx / elec_locy - 60 通道 GUI 坐标
%   6. cfg.record_btn / stim_test_btn / stim_train_btn / start_stim_btn - 4 个按钮坐标

if nargin < 1 || isempty(date_tag)
    date_tag = datestr(now, 'yyyymmdd');
end
cfg.date_tag = date_tag;
cfg.random_seed = str2double(date_tag);

% ===== Cell 标识（每盘细胞改这一行）=====
cfg.cell_id = 'Cell_1';

% ===== 逻辑位点 -> MCS 物理电极索引（诱发响应筛选后填）=====
cfg.stim_site_indices = [3 7 11 17 20 21];

% ===== 路径（迁机器改这里）=====
cfg.data_dir         = 'E:\Recognition-in-Biological-Neural-Networks\Data\japanese+vowels';
cfg.experiments_root = 'E:\Exp_Data_MZY\Voice data\Stand_EXP\Data';
cfg.day_dir  = fullfile(cfg.experiments_root, cfg.date_tag);
cfg.cell_dir = fullfile(cfg.day_dir, cfg.cell_id);

cfg.input_file = 'ae.train';
cfg.size_file = 'size_ae.train';

% ===== 数据规模 =====
cfg.selected_speakers = 1:8;
cfg.samples_per_speaker = 30;
cfg.n_feature = 12;
cfg.n_time_slot = 12;
cfg.n_site = 6;

% ===== 编码路线 =====
% feature_route: 'first6'（LPC 前 6 系数）或 'adjacent_mean'（相邻均值压缩）
% encoding_k:    每个有效时间槽刺激得分最高的 k 个位点。1=top-1（每槽一个位点），
%                2=top-2（每槽同时激活两个位点，见 mcs_run 的 ClickStimSites）。
%                想试 top-2 把下面这行改成 2 即可：文件名后缀会自动变成 _top2，
%                与 top-1 产物不冲突；下游 run_preprocess / validate /
%                build_expected_stim_count / mcs_run 全部按 encoding_k 自适应。
% score_mode:    'abs_z'（z-score 后取绝对值）
% long_sample_mode: 'linear_resample' 或 'uniform_pick'
cfg.feature_route = 'first6';
cfg.encoding_k = 1;
cfg.score_mode = 'abs_z';
cfg.long_sample_mode = 'linear_resample';
cfg.protocol_tag = sprintf('%s_top%d', cfg.feature_route, cfg.encoding_k);

% ===== 时序参数 =====
cfg.step_interval_s = 0.250;
cfg.inter_trial_interval_s = 10.0;
cfg.trials_per_batch = 40;
cfg.rounds_per_batch = 5;
cfg.n_batch = 6;

% ===== MCS GUI 电极坐标（迁机器需核对）=====
cfg.elec_locx = [888 918 945 973 1002 1029 ...
    862 888 918 945 973 1002 1029 1055 ...
    862 888 918 945 973 1002 1029 1055 ...
    862 888 918 945 973 1002 1029 1055 ...
    862 888 918 945 973 1002 1029 1055 ...
    862 888 918 945 973 1002 1029 1055 ...
    862 888 918 945 973 1002 1029 1055 ...
    888 918 945 973 1002 1029] - 146;
cfg.elec_locy = [418 418 418 418 418 418 ...
    455 455 455 455 455 455 455 455 ...
    474 474 474 474 474 474 474 474 ...
    501 501 501 501 501 501 501 501 ...
    531 531 531 531 531 531 531 531 ...
    558 558 558 558 558 558 558 558 ...
    585 585 585 585 585 585 585 585 ...
    615 615 615 615 615 615] - 102;

% ===== MCS GUI 按钮坐标（迁机器需核对）=====
% stim_train_btn 当前与 stim_test_btn 同坐标；未来若 MCS 上 train/test 刺激器
% 拆为不同按钮（脉冲参数差异），改这一行即可。
cfg.record_btn = [213, 44];
cfg.stim_test_btn = [726, 171];
cfg.stim_train_btn = [726, 171];
cfg.start_stim_btn = [350, 40];
end
