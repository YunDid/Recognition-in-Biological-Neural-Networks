# Japanese Vowels 前 6 系数 top-1 刺激协议

本目录存放 BRC 返修中标准声音数据集补充实验的 MATLAB 流程。目标是把 Japanese Vowels 的 `ae.train` 数据转换为 MCS 可执行的六位点稀疏时空刺激事件表，并提供桌面点击式 MCS 执行模板。

## 文件说明

- `config_japanese_vowels.m`：全局配置（路径、数据规模、编码路线、时序、电极坐标、按钮坐标、物理刺激位点映射）。**迁机器只改这一个文件**。
- `run_preprocess_japanese_vowels.m`：读取 `ae.train`，筛选 speaker 1-8，生成事件表，输出 `mat`。
- `validate_preprocess_japanese_vowels.m`：从 `mat` 加载并打印关键统计；不写 CSV。
- `mcs_run_japanese_vowels.m`：实验主脚本（参照旧八分类 `Cch_Exp_train_eight.m` 的可编排形态）。脚本中段是流程编排区，可按需删/加/换 `run_test_jv` / `run_train_jv` / `Record_Spon` 的顺序；末尾以 local function 形式提供 test 阶段、train 阶段、自放电记录与基础点击接口。

## 按日期归类与随机种子

- `cfg.date_tag` 为 `'YYYYMMDD'` 字符串，默认取运行当天。
- 同一个 `date_tag` 既作为随机种子（`cfg.random_seed = str2double(date_tag)`），也作为输出子目录名。
- 同一天内多次运行（baseline / training / drug 各自上机前的预处理）得到完全一致的 trial 顺序，所有当日实验共用一份事件表。
- 不同天得到独立的 trial 顺序，输出文件落到独立子目录，互不覆盖。
- `run_preprocess` 与 `validate` 接受可选参数 `date_tag`；`mcs_run_japanese_vowels` 是脚本，跑指定日期请改脚本顶部 `date_tag = '...'`。

```matlab
run_preprocess_japanese_vowels                 % 用今天的日期
run_preprocess_japanese_vowels('20260502')     % 显式指定日期
validate_preprocess_japanese_vowels('20260502')
mcs_run_japanese_vowels                        % 主脚本，按下 F5 直接跑；改日期编辑脚本顶部
```

## 当前默认决策

- 数据来源：Japanese Vowels 的 `ae.train`。
- 标签选择：speaker 1-8，每类 30 条，共 240 trials。
- 标准化方式：按特征维度做 z-score。均值和标准差在选中的 240 条样本全部原始时间帧上逐列计算，得到 `1 x 12` 的 `mu` 和 `sigma`。
- 时间槽：每条样本固定为 12 个刺激时间槽。
- 长样本处理：`cfg.long_sample_mode` 控制；默认 `linear_resample`（线性插值到 `linspace(1,T,12)`），可改为 `uniform_pick`（等间隔抽帧）。
- 短样本处理：保留原始有效时间步，后续空槽标记为 padding，不触发刺激。
- top-1 得分：`cfg.score_mode = 'abs_z'`，使用 z-score 后的偏离强度。该步骤是 MCS 固定脉冲输入的编码选择，不是 Japanese Vowels 原始数据定义。
- 六位点路线：`cfg.feature_route = 'first6'`，直接使用前 6 个 LPC cepstrum 系数。
- 主线编码：每个有效时间槽只保留 top-1 逻辑位点。
- 协议标识：`cfg.protocol_tag = 'first6_top1'`，正式输出文件名均包含该标识。
- 批次安排：6 batches × 40 trials = 240 trials；每个 batch 包含 5 轮平衡刺激，每轮 8 个 speaker 各 1 条。

## 首次运行

在 MATLAB 中把本目录加入路径，然后运行：

```matlab
run_preprocess_japanese_vowels
validate_preprocess_japanese_vowels
```

输出目录结构（按日期 + 细胞分层，下例 2026-05-02 当天 Cell_1）：

```text
<cfg.experiments_root>/
└── 20260502/                                       ← cfg.day_dir（同日所有细胞共享）
    ├── japanese_vowels_mcs_first6_top1_events.mat
    ├── expected_stim_count_first6_top1.mat
    └── Cell_1/                                     ← cfg.cell_dir（每盘独立）
        ├── stim_labels_first6_top1_test1_*.mat
        ├── stim_labels_first6_top1_train_*.mat
        └── stim_labels_first6_top1_test2_*.mat
```

主要产物：

- `japanese_vowels_mcs_first6_top1_events.mat`：MATLAB 主协议文件；包含 `cfg`、`samples`、`mu`、`sigma`、`trial_table`、`event_table`、`sample_features`。同日所有细胞共用一份。
- `expected_stim_count_first6_top1.mat`：期望刺激计数表（由 `build_expected_stim_count` 生成），与 NEX 实测对照。同日所有细胞共用一份。
- `stim_labels_*.mat`：每盘细胞自己的实验产物，写到对应 `Cell_X/` 子目录。

## 如何检查每一步是否正确

`validate_preprocess_japanese_vowels` 会打印：

- 配置回显（feature_route / encoding_k / score_mode / long_sample_mode）。
- speaker 分布：应为 speaker 1-8 各 30 条。
- batch 分布：每个 batch 应为 40 条。
- batch×speaker 分布：每格应为 5 条（即 `rounds_per_batch`）。
- active_site 分布：检查 top-1 位点是否明显偏向单一位点（0 表示空槽不刺激）。
- padding 分布：检查短样本空刺激槽数量。
- 首个 trial 的 meta、6 位点得分矩阵 `6 x 12`、每步选位 `(time_step, active_site, is_padding)`。

如需逐条核对 trial 顺序：

```matlab
S = load('japanese_vowels_mcs_first6_top1_events.mat');
disp(S.trial_table)         % 240 行
disp(S.event_table(1:24,:)) % 头 2 个 trial 共 24 行事件
```

## 数据结构

一个 `trial` 表示一次完整输入一条 Japanese Vowels 语音样本，包含 12 个刺激时间槽。

`trial_table` 每行是一个 trial（共 240 行），字段：`global_trial_id, batch_id, round_id, trial_id, sample_id, speaker_label, within_speaker_id, original_T`。

`event_table` 每行是一个 trial 内的一个时间槽（共 `240 × 12 = 2880` 行）。同一个 `global_trial_id` 对应 12 行，每行包含 `score_site1..6`，`active_site` 是该行六个分数中最大的位点编号；padding 槽 `active_site = 0`。

输出顺序按 batch 保持类别平衡：

```text
6 batches × 5 rounds × 8 speakers = 240 trials
```

每个 batch 含 40 个 trial，每个 speaker 各 5 条。每个 speaker 内部的 30 条样本顺序随机，每个 round 内 speaker 1-8 出现顺序也随机；随机种子来自 `cfg.date_tag`，同一天内多次运行的顺序一致，不同天独立。

## 刺激位点映射

MCS GUI 点击使用两层位点编号：

```text
active_site:        事件表中的逻辑位点，取值 1-6
stim_site_indices:  逻辑位点到 MCS GUI 坐标索引的映射
elec_locx/elec_locy: MCS GUI 上每个坐标索引对应的实际点击位置
```

确定六个物理刺激位点后，只需要修改 `config_japanese_vowels.m` 中的：

```matlab
cfg.stim_site_indices = [3 7 11 17 20 21];
```

`mcs_run_sound_top1_template.m` 会先读取 `active_site`，再通过 `cfg.stim_site_indices(active_site)` 找到 GUI 坐标索引，最后执行 `ClickStim(elec_locx(elec_index), elec_locy(elec_index), ...)`。

## 长样本处理方式切换

```matlab
cfg.long_sample_mode = 'linear_resample';  % 默认，线性插值
cfg.long_sample_mode = 'uniform_pick';     % 仅抽帧，不插值
```

修改后重新运行：

```matlab
run_preprocess_japanese_vowels
validate_preprocess_japanese_vowels
```

## 实验流程编排

主脚本 `mcs_run_japanese_vowels.m` 的中段是流程编排区，参照旧 `Cch_Exp_train_eight.m`：

```matlab
pause(10);
Record_Spon(300, cfg.record_btn);
test1 = run_test_jv(cfg, 'test1');
Record_Spon(300, cfg.record_btn);
train = run_train_jv(cfg, 'train');
Record_Spon(300, cfg.record_btn);
test2 = run_test_jv(cfg, 'test2');
Record_Spon(300, cfg.record_btn);
```

按需调整：

- 只做 baseline test：保留前两行 + 一次 `run_test_jv(cfg, 'test1')`，删其余。
- 只做 test → spon → train → spon：删除最后两行 `run_test_jv(cfg, 'test2')` 及其前后 spon。
- 加药态再做一次 test：在末尾追加 `run_test_jv(cfg, 'test3')` 即可。
- `stage_tag`（'test1' / 'train' / 'test2' / 'test3' ...）会出现在所有 mat 文件名中，避免阶段间互相覆盖。

### Test 阶段（`run_test_jv`）

- 输入：`japanese_vowels_mcs_first6_top1_events.mat` 中的 `trial_table`（6 batches × 5 rounds × 8 speakers，平衡随机化）
- batch 划分：6 batches × 40 trials/batch
- 单 batch 时长：≈ 9-10 min；总时长 ≈ 54-60 min
- MCS 刺激器按钮：`cfg.stim_test_btn`
- 每 batch 后写出累积 mat（含 `stim_labels` 标签数组，可断电恢复）

### Train 阶段（`run_train_jv`）

- 顺序：speaker 1 的 30 条（`within_speaker_id` 1→30）→ speaker 2 的 30 条 → ... → speaker 8 的 30 条
- batch 划分：8 batches × 30 trials/batch（每 speaker 一个 batch）
- 单 batch 时长：≈ 6.7 min；总时长 ≈ 54 min（与 test 总时长基本相等）
- MCS 刺激器按钮：`cfg.stim_train_btn`（当前与 `stim_test_btn` 同坐标，保留为单独字段以便后续拆分）
- 复用同一份事件表，内部用 `sortrows(trial_table, {'speaker_label','within_speaker_id'})` 重排顺序——不需要为 train 单独生成事件表

#### `executed_trial_table` 字段语义（train 与 test 的差异）

train 阶段的 batch 边界与事件表预生成时的 test 平衡批号不同。为避免覆盖原始平衡结构，train 阶段保留全部原字段（`batch_id` 1..6、`trial_id` 1..40 仍指 test 平衡铺排中的位置），并**额外追加**两列：

| 字段 | test 阶段 | train 阶段 |
|----|----|----|
| `batch_id` | 1..6（当前阶段 NEX 文件号） | 1..6（**事件表预生成时的 test 批号**，非当前阶段批号） |
| `trial_id` | 1..40（当前阶段批内序号） | 1..40（**事件表预生成时的 test 批内序号**） |
| `train_batch_id` | 不存在 | 1..8（当前阶段 NEX 文件号 = speaker_label） |
| `train_trial_id` | 不存在 | 1..30（当前 NEX 文件内的播放序号） |

后续 SVM 分析读 train 阶段 NEX 文件时，按 `train_batch_id` 对应 NEX 文件号、按 `train_trial_id` 在文件内定位 trial。

### 各阶段输出

每个阶段独立保存，互不覆盖：

```text
stim_labels_first6_top1_test1_batch_01.mat ... batch_06.mat, _final.mat
stim_labels_first6_top1_train_batch_01.mat ... batch_08.mat, _final.mat
stim_labels_first6_top1_test2_batch_01.mat ... batch_06.mat, _final.mat
```

## 跨机器迁移

迁实验电脑只改 `config_japanese_vowels.m`：

1. `cfg.cell_id`：每盘细胞改一次（默认 `'Cell_1'`）。
2. `cfg.data_dir`：数据集目录绝对路径（含 `ae.train`、`size_ae.train`）。
3. `cfg.experiments_root`：实验产物根目录绝对路径。
4. `cfg.stim_site_indices`：诱发响应筛选后选定的 6 个物理电极索引。
5. `cfg.elec_locx` / `cfg.elec_locy`：60 通道 GUI 坐标（如分辨率或布局变化）。
6. `cfg.record_btn` / `cfg.stim_test_btn` / `cfg.stim_train_btn` / `cfg.start_stim_btn`：4 个 GUI 按钮坐标。

输出自动归档到 `<experiments_root>/<date_tag>/<cell_id>/`，事件表与期望表共享在 `<experiments_root>/<date_tag>/`。
