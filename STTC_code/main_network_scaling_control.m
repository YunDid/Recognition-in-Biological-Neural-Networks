%% main_network_scaling_control.m  ——  R1[2] STTC 全局权重缩放对照（W1 口径）
%
% 【用途与使用方法】
%   回应审稿人 R1 第 2 条：训练后 CC↑/CPL↓/Eglob↑ 是否只是连接权重整体
%   变大的算术后果，而非真实拓扑重组。做法：把训练前矩阵整体乘标量 k1
%   （使全局平均权重涨到训练后水平、连接格局不变），得到"纯缩放对照模型"
%   scaled_pre，与实测训练后指标对照。设好 CONFIG 区 merged_root 后直接运行。
%
% 【与旧版的口径变更（重要）】
%   v1 沿用 main_network_new.m 的「全 60×60 + W<0.35=0」口径，导致未激活
%   电极成孤立点、distance_wei 出 Inf、CPL 全失效。本版改用旧 main_network.m
%   的 W1 口径（论文 CPL 实际来源）：
%     adjM → NaN→0 → W<0→0 → 剔全零行列(子图1)
%          → W<0.35→0 → 再剔全零行列(子图2) → 所有拓扑指标在子图2 上算
%   子图连通 → CPL 有限可判。CC/Eglob/Q/T/Hub 节点指标同步在 W1 子图上重算。
%
% 【缩放因子口径（用户 2026-06-02 确认：非零边均值 mean_nz）】
%   只有 scaled_pre = W1_pre × kS 一个缩放网络。kS 用 mean_nz 口径（论文 mean STTC = 非零边均值）：
%   kS = mean_nz(post)/mean_nz(pre)，mean_nz = 全阵 NaN→0、W<0.35→0 后【非零】非对角边均值。
%        这是论文报告的连接强度口径，缩放对照模型 = R1[2]「把已有连接整体按比例放大」。代码里 kS 即 k2。
%   k1 = mean_all(post)/mean_all(pre)（含被清零边，仅附报）：反映"边数/密度变化"灵敏度，
%        k1 与 k2 差异大 = densification 主导而非边强度放大。
%   kS(=k2) 在全阵非零均值上算，拓扑指标在 W1 子图上算 —— 两块各自忠实匹配其原始定义。
%   （口径变更影响：原 mean_all 口径下 0117-1 因 pre 稀疏致 k≈2.8、scaled 越界失真；
%     mean_nz 口径下 k≈1.0 物理正常，0117-1 不再需特殊剔除。）
%
% 【scaled_pre 构造】
%   scaled_pre = W1_pre × kS(=k2, mean_nz)（在剔零后的 W1 子图上缩放，"阈值后缩放"）。
%   kS>0 不产生新零行 → scaled_pre 与 W1_pre 节点相同、哪些电极相连及其
%   相对强弱也相同、维度一致，即"同结构纯放大"。直接在其上算指标，不重阈值、不重剔零。逐训练后阶段
%   各算各的 kS（pre 固定）。越界（scaled>1）不截断，仅记 overflow 占比（mean_nz 下一般无越界）。
%
% 【阶段选取规则（与原对齐，选项 a，未变）】
%   计算阶段集 = 该盘 sttc/hubness/ 现存 spon 子集（扫目录得，不写死）。
%   升序＝时间序：最小号 = 训练前基准（缩放源），其余 = 训练后各时间点。
%   子集 <3 阶段或有效训练后对照 <2 的盘整盘跳过（拒绝退化两点对比）。
%
% 【输出与字段说明】
%   (1) 逐盘： <cell>/sttc/scaling_control/scaling_control_<cell>.mat，struct R：
%       R.readme        —— cellstr，本结构每个字段的中文说明（mat 自带文档）
%       R.cell          —— 盘名
%       R.kpi_unit      —— 口径标记字符串 'W1-subgraph; k on full-60 thr-mean'
%       R.stages        —— 该盘升序 spon 子集，如 [2 3 5]
%       R.pre_stage     —— 训练前基准 spon 号（子集最小号）
%       R.base(s)       —— 每阶段【实测】W1 子图指标，字段：
%            .spon          该阶段 spon 号
%            .N             W1 子图节点数（保留电极数，逐阶段不同）
%            .keep_idx      W1 子图保留的原始电极下标（1..60 中的子集）
%            .mean_all      全 60×60 阈值阵非对角均值（算 k1 用，非子图量）
%            .mean_nz       全 60×60 非零边均值（算 k2 用）
%            .CC            聚类系数 sum(C)/nnz(C>0)，C=clustering_coef_wu(W1)
%            .T             传递性 transitivity_wu(W1)
%            .Q             模块度 modularity_und(W1) 的 Q
%            .Eglob         全局效率 efficiency_wei(W1)
%            .CPL           特征路径长度 sum(sum(D))/(N*(N-1))，
%                           D=distance_wei(1/W1)；子图不连通时为 NaN
%            .cpl_disc      逻辑：该阶段 W1 子图是否仍不连通（CPL 不可用）
%            .corr_hi/med/lo  高(≥0.8)/中(0.5-0.8)/低(0-0.5)相关边占比
%            .str/.deg/.bc/.cloc/.eloc   节点级强度/度/介数/接近/局部效率(N×1)
%       R.ctrl(t)       —— 每【训练后阶段】的缩放对照，字段：
%            .post_spon     对照的训练后 spon 号
%            .k1            主缩放因子 mean_all(post)/mean_all(pre)
%            .k2            稳健性附报 mean_nz(post)/mean_nz(pre)
%            .overflow_frac scaled_pre 中权重>1 的边占非零边比例（越界探针）
%            .scaled        scaled_pre=W1_pre×k1 上的同套指标（结构同 base(s)）
%            .hub_actual_post  实测 post 的 Hub 评分（B 口径，阈值池=该盘子集）
%            .hub_scaled       scaled_pre 的 Hub 评分（同阈值池）
%       R.traj          —— 三阶段轨迹（基准+各训练后点联合，非两两配对）：
%            .spon          [pre, post1, post2, ...]
%            .CC_actual     实测轨迹：[CC(pre), CC(post1), ...]
%            .CC_scaled     缩放轨迹：[CC(pre), CC(scaled@post1), ...]（首点=pre 自身）
%            .CPL_actual/.CPL_scaled/.Eglob_actual/.Eglob_scaled  同构
%   (2) 全局： merged_root/scaling_control_summary.xlsx 与 .mat（变量 S）
%       【每盘一行】宽表，列：
%         cell, pre_spon, n_post, post_list（如 "3|5"）,
%         CC_pre,  CC_act_p1..p5,  CC_scl_p1..p5,
%         CPL_pre, CPL_act_p1..p5, CPL_scl_p1..p5,
%         Eglob_pre, Eglob_act_p1..p5, Eglob_scl_p1..p5,
%         Hub_pre, Hub_act_p1..p5, Hub_scl_p1..p5,   （节点平均得分=Fig2E-F指标，实测/缩放对照；口径见 node_3rd）
%         k1_p1..p5, k2_p1..p5, ovf_p1..p5, cpl_disc_any
%       *_pre 为基准点（实测=缩放同值）；_act_p# 实测训练后第#点；
%       _scl_p# scaled_pre 在该点的预测；post 不足 5 个的列留 NaN。
%       cpl_disc_any=1 表示该盘存在 W1 子图仍不连通的阶段，其 CPL 列为 NaN。
%       scaled_valid=0 表示该盘 scaled_pre 越界失效(k1 过大→权重大面积>1→CC_scl/Eglob_scl 非物理)，
%                     离线跨盘统计须剔除(如 0117-1)；=1 为可用。
%
% 【数据流】
%   sttc-spikes_sponX.mat(adjM) → W1 子图(拓扑) + 全阵阈值(算 k) →
%   实测指标 + scaled_pre 指标 → scaling_control_<cell>.mat + summary.xlsx
% 【操作流】
%   设 merged_root（only_cell 可先单盘验证）→ 运行本脚本 →
%   离线读 summary 做【每盘残差聚合 → 跨盘配对 Wilcoxon】判据（D，不在本脚本）
%
% 关联：PKM 卡片「BRC修订 - STTC 数据资产与分析代码清单」§5（口径已随本版更新）
% Date: 2026-05-19  W1 口径改版；main_network_new.m / main_hubness_meanS.m 原脚本不动
clc; clear; close all

%% ===== CONFIG（按机器修改）=====
merged_root = 'E:\Recognition-in-Biological-Neural-Networks\Data\merged';
only_cell   = '';     % 留空＝跑全部盘；填盘名（如 '0206-3'）＝只跑该盘验证
thr         = 0.35;   % STTC 阈值，同 main_network.m W1 段
hub_top     = 0.40;   % 节点得分全局阈值取前 40%，同 main_hubness_meanS.m
node_3rd    = 'cloc'; % 节点得分第三指标：'cloc'=接近中心性(发表 Fig2E-F 实际所用) | 'bc'=介数中心性(论文正文/审稿人所述)
MAXP        = 5;      % 宽表训练后点上限（实测各盘 post 数 ≤5）

this_dir = fileparts(mfilename('fullpath'));
if exist(fullfile(this_dir,'BCT'),'dir'); addpath(genpath(fullfile(this_dir,'BCT'))); end

%% ===== 遍历各盘 =====
cells = dir(merged_root);
cells = cells([cells.isdir] & ~ismember({cells.name},{'.','..'}));

S = {};   % 每盘一行宽表
hdr = [{'cell','pre_spon','n_post','post_list'}, ...
       blk('CC',MAXP), blk('CPL',MAXP), blk('Eglob',MAXP), blk('Hub',MAXP), ...
       pcols('k1',MAXP), pcols('k2',MAXP), pcols('ovf',MAXP), {'cpl_disc_any','scaled_valid'}];

for ci = 1:numel(cells)
    cname = cells(ci).name;
    if ~isempty(only_cell) && ~strcmp(cname, only_cell); continue; end
    cdir    = fullfile(merged_root, cname);
    sttcdir = fullfile(cdir,'sttc');
    hubdir  = fullfile(sttcdir,'hubness');

    if ~exist(hubdir,'dir'); fprintf('[跳过] %s 无 hubness 目录\n', cname); continue; end
    hf = dir(fullfile(hubdir,'hubness-*spon*.mat'));
    stages = [];
    for k = 1:numel(hf)
        tk = regexp(hf(k).name,'spon(\d+)','tokens','once');
        if ~isempty(tk); stages(end+1) = str2double(tk{1}); end %#ok<AGROW>
    end
    stages = sort(unique(stages),'ascend');
    if numel(stages) < 3
        fprintf('[跳过] %s 子集仅 %d 个阶段(<3)，三阶段轨迹不成立\n', cname, numel(stages));
        continue;
    end
    pre_stage   = stages(1);
    post_stages = stages(2:end);
    fprintf('[处理] %s  子集 spon=%s  基准=spon%d  训练后=%s\n', ...
            cname, mat2str(stages), pre_stage, mat2str(post_stages));

    % --- 逐阶段：W1 子图实测指标 + 全阵均值（算 k 用）---
    base = struct([]);
    W1map = containers.Map('KeyType','double','ValueType','any');
    okStages = [];
    for s = stages
        f = fullfile(sttcdir, sprintf('sttc-spikes_spon%d.mat', s));
        if ~exist(f,'file'); fprintf('   ! 缺 %s，跳过该阶段\n', f); continue; end
        d = load(f);
        [W1, keep] = w1_subgraph(d.adjM, thr);
        if isempty(W1) || size(W1,1) < 3
            fprintf('   ! spon%d W1 子图过小(<3)，跳过该阶段\n', s); continue;
        end
        W1map(s) = W1;
        m = net_metrics(W1);
        [m.mean_all, m.mean_nz] = mean_full(d.adjM, thr);   % 全阵口径，算 k 用
        m.spon = s; m.keep_idx = keep; m.N = size(W1,1);
        if m.cpl_disc
            fprintf('   ! spon%d W1 子图仍不连通，CPL 记 NaN\n', s);
        end
        base = [base, m]; %#ok<AGROW>
        okStages(end+1) = s; %#ok<AGROW>
    end
    if ~ismember(pre_stage, okStages)
        fprintf('   ! 基准 spon%d 缺/无效，整盘跳过\n', pre_stage); continue;
    end
    W1pre = W1map(pre_stage);
    mPre  = base([base.spon]==pre_stage);

    % --- 逐训练后阶段缩放对照 ---
    ctrl = struct([]);
    for t = post_stages
        if ~ismember(t, okStages); continue; end
        mPost = base([base.spon]==t);
        k1 = mPost.mean_all / mPre.mean_all;       % 全阵均值比(含零)，仅附报
        k2 = mPost.mean_nz  / mPre.mean_nz;        % 非零边均值比 = kS = 论文 mean STTC 口径(造网络用)
        scaled = W1pre * k2;                        % 缩放对照模型用 mean_nz 口径 kS(=k2)，在剔零后 W1 子图上缩放
        N = size(scaled,1); off = ~eye(N);
        nz  = scaled>0 & off;
        ofr = nnz(scaled>1 & nz) / max(nnz(nz),1);
        mScl = net_metrics(scaled);

        c.post_spon       = t;
        c.k1              = k1;
        c.k2              = k2;
        c.overflow_frac   = ofr;
        c.scaled          = mScl;
        c.hub_actual_post = hub_score(mPost, base, hub_top, node_3rd);
        c.hub_scaled      = hub_score(mScl,  base, hub_top, node_3rd);
        ctrl = [ctrl, c]; %#ok<AGROW>

        fprintf(['   spon%d->spon%d  k1=%.3f k2=%.3f 越界=%.1f%%  ' ...
                 'CC %.3f/%.3f/%.3f  CPL %s/%s/%s  Eglob %.3f/%.3f/%.3f\n'], ...
            pre_stage, t, k1, k2, 100*ofr, ...
            mPre.CC, mPost.CC, mScl.CC, ...
            f3(mPre.CPL), f3(mPost.CPL), f3(mScl.CPL), ...
            mPre.Eglob, mPost.Eglob, mScl.Eglob);
    end
    if numel(ctrl) < 2
        fprintf('   ! %s 有效训练后对照仅 %d 个(<2)，整盘跳过\n', cname, numel(ctrl));
        continue;
    end

    % --- 三阶段轨迹聚合 ---
    posts = [ctrl.post_spon];
    traj.spon         = [pre_stage, posts];
    traj.CC_actual    = [mPre.CC,    arrayfun(@(c) base([base.spon]==c.post_spon).CC,    ctrl)];
    traj.CPL_actual   = [mPre.CPL,   arrayfun(@(c) base([base.spon]==c.post_spon).CPL,   ctrl)];
    traj.Eglob_actual = [mPre.Eglob, arrayfun(@(c) base([base.spon]==c.post_spon).Eglob, ctrl)];
    traj.CC_scaled    = [mPre.CC,    arrayfun(@(c) c.scaled.CC,    ctrl)];
    traj.CPL_scaled   = [mPre.CPL,   arrayfun(@(c) c.scaled.CPL,   ctrl)];
    traj.Eglob_scaled = [mPre.Eglob, arrayfun(@(c) c.scaled.Eglob, ctrl)];

    % --- 保存逐盘 ---
    R = struct();
    R.readme = readme_lines();
    R.cell = cname;
    R.kpi_unit = 'W1-subgraph topology; k1/k2 on full-60 thr-mean';
    R.stages = stages; R.pre_stage = pre_stage;
    R.base = base; R.ctrl = ctrl; R.traj = traj;
    outdir = fullfile(sttcdir,'scaling_control');
    if ~exist(outdir,'dir'); mkdir(outdir); end
    save(fullfile(outdir, sprintf('scaling_control_%s.mat', cname)), 'R');
    clear R traj

    % --- 写入每盘一行宽表 ---
    np = numel(ctrl);
    actCC=nan(1,MAXP); sclCC=nan(1,MAXP); actCP=nan(1,MAXP); sclCP=nan(1,MAXP);
    actEg=nan(1,MAXP); sclEg=nan(1,MAXP); K1=nan(1,MAXP); K2=nan(1,MAXP); OF=nan(1,MAXP);
    actHub=nan(1,MAXP); sclHub=nan(1,MAXP);
    for q = 1:np
        bp = base([base.spon]==ctrl(q).post_spon);
        actCC(q)=bp.CC;  sclCC(q)=ctrl(q).scaled.CC;
        actCP(q)=bp.CPL; sclCP(q)=ctrl(q).scaled.CPL;
        actEg(q)=bp.Eglob; sclEg(q)=ctrl(q).scaled.Eglob;
        actHub(q)=ctrl(q).hub_actual_post; sclHub(q)=ctrl(q).hub_scaled;   % 节点平均得分 实测/缩放
        K1(q)=ctrl(q).k1; K2(q)=ctrl(q).k2; OF(q)=ctrl(q).overflow_frac;
    end
    hub_pre = hub_score(mPre, base, hub_top, node_3rd);                     % pre 节点得分(与 act/scl 同口径)
    cpl_any = any([base.cpl_disc]);
    % scaled_valid=0 表示该盘缩放对照模型越界失效：k1 过大使 scaled_pre 权重大面积>1，
    % 加权 CC/Eglob 公式(要求权重∈[0,1])算出非物理值(如 CC_scl>1)。离线统计须剔除 scaled_valid=0 的盘。
    scaled_valid = double( ~( any(sclCC>1) || any(sclEg>1) ) );
    S(end+1,:) = [{cname, pre_stage, np, strjoin(string(posts),'|')}, ...
        {mPre.CC},  num2cell(actCC), num2cell(sclCC), ...
        {mPre.CPL}, num2cell(actCP), num2cell(sclCP), ...
        {mPre.Eglob}, num2cell(actEg), num2cell(sclEg), ...
        {hub_pre}, num2cell(actHub), num2cell(sclHub), ...
        num2cell(K1), num2cell(K2), num2cell(OF), {double(cpl_any), scaled_valid}]; %#ok<AGROW>
end

%% ===== 全局汇总 =====
if ~isempty(S)
    T = cell2table(S, 'VariableNames', hdr);
    xlsx_out = fullfile(merged_root,'scaling_control_summary.xlsx');
    if exist(xlsx_out,'file'); delete(xlsx_out); end   % 先删旧表：writetable 只覆盖自身行范围，旧版残留长表行(含 65535 占位)不会被清除
    writetable(T, xlsx_out);
    save(fullfile(merged_root,'scaling_control_summary.mat'),'T','hdr');
    fprintf('\n每盘一行宽表已写出：%s\n', xlsx_out);
else
    fprintf('\n[警告] 无任何盘产出对照行\n');
end
disp('done');

%% ================= 局部函数 =================
function [W1, keep] = w1_subgraph(adjM, thr)
% W1 口径（旧 main_network.m:25-36）：清负→剔零行列→0.35阈值→再剔零行列
    W0 = adjM;
    W0(isnan(W0)) = 0;
    W0(W0 < 0)    = 0;                 % 仅清负值（对齐 main_network.m:26-27）
    zr = all(W0==0,2); zc = all(W0==0,1);
    idx1 = find(~zr(:)');              % 第一次保留的原始电极下标
    Wa = W0(~zr,~zc);                  % 子图1
    Wt = Wa; Wt(Wt < thr) = 0;         % 0.35 阈值
    zr2 = all(Wt==0,2); zc2 = all(Wt==0,1);
    W1  = Wt(~zr2,~zc2);               % 子图2 —— 指标在此算
    keep = idx1(~zr2(:)');             % 映射回原始 1..60 电极下标
end

function [mu_all, mu_nz] = mean_full(adjM, thr)
% 全 60×60 阈值阵均值（算 k1/k2 用），口径 = main_network_new.m:27-28,38
    W = adjM; W(isnan(W)) = 0; W(W < thr) = 0;
    N = size(W,1); off = ~eye(N);
    mu_all = mean(W(off));                       % 含被清零边，= 论文全局平均权重口径
    nzv    = W(off & W>0);
    mu_nz  = mean(nzv(:));                        % 仅非零边
end

function m = net_metrics(W)
% 拓扑指标，算法对齐 main_network.m（CPL 分母用子图 N）
    N       = size(W,1);
    offmask = ~eye(N);
    HighCorr = W(W >= 0.8);
    MedCorr  = W(W >= 0.5 & W < 0.8);
    LowCorr  = W(W <  0.5 & W > 0);
    npos     = max(numel(find(W>0)),1);
    m.corr_hi  = numel(HighCorr)/npos;
    m.corr_med = numel(MedCorr)/npos;
    m.corr_lo  = numel(LowCorr)/npos;
    C       = clustering_coef_wu(W);
    m.CC    = sum(C)/max(numel(find(C>0)),1);
    m.T     = transitivity_wu(W);
    [~,Q]   = modularity_und(W);
    m.Q     = Q;
    m.Eglob = efficiency_wei(W);
    L       = weight_conversion(W, 'lengths');
    [D,~]   = distance_wei(L);
    Doff    = D(offmask);
    if any(isinf(Doff(:)))                        % 子图仍不连通 → CPL 不可用
        m.cpl_disc = true;  m.CPL = NaN;
    else
        % 分母用子图2 节点数 N（教科书 CPL 定义、实测与缩放两侧一致，残差判据不受影响）。
        % 注意：旧 main_network.m:60 的分母用的是子图1(0.35阈值前)节点数 length(C)，
        % 在 0.35 阈值多剔 1 个节点的盘(0117-1/0822-1/1108-2/1213-5/1227-1)上二者绝对 CPL 差≤8.3%。
        % 若要把本脚本 CPL 当"论文那个 CPL"直接报，须与 main_network.m 对齐分母口径；仅做缩放残差判据则无需改。
        m.cpl_disc = false; m.CPL = sum(sum(D))/(N*(N-1));
    end
    m.str  = strengths_und(W)';
    m.deg  = degrees_und(W)';
    m.bc   = betweenness_wei(L);
    cl     = (1 ./ sum(D))';
    cl(~isfinite(cl)) = 0;
    m.cloc = cl;
    eloc   = efficiency_wei(W,2);
    if size(eloc,1) < size(eloc,2); eloc = eloc'; end
    m.eloc = eloc;
    m.zero_rows = false(N,1);                     % W1 子图已无全零行
    m.n_active  = N;
end

function avg = hub_score(mTarget, basePool, top, idx3)
% 节点平均得分（对应论文 Fig 2E-F）。阈值池 = 该盘各阶段节点指标拼接，三指标各取前 top 比例
% 为阈值，对 mTarget 节点逐个算 0-3 分后取均值。三指标 = mean_str(=str/deg 平均连接强度)
% + eloc(局部效率 efficiency_wei(W,2)) + 第三指标 idx3。
% idx3：'cloc'=接近中心性(1/∑距离)，沿用原 main_hubness_meanS.m 的实际计算（该脚本变量名
%        cloc/eloc 与惯例相反：cloc 实为接近、eloc 实为局部效率）| 'bc'=介数中心性(可选)。
% 默认 'cloc'，对齐已发表 Fig 2E-F 的实际口径；两者对幅值缩放均敏感。改 node_3rd='bc' 可切换。
    if nargin<4; idx3='cloc'; end
    aS=[]; aE=[]; a3=[];
    for j=1:numel(basePool)
        b=basePool(j);
        aS=[aS; b.str(:)./max(b.deg(:),eps)]; %#ok<AGROW>
        aE=[aE; b.eloc(:)];                    %#ok<AGROW>
        a3=[a3; b.(idx3)(:)];                  %#ok<AGROW>
    end
    g  = min(max(round(top*numel(aS)),1),numel(aS));
    sS=sort(aS,'descend'); sE=sort(aE,'descend'); s3=sort(a3,'descend');
    thS=sS(g); thE=sE(g); th3=s3(g);
    ms = mTarget.str(:)./max(mTarget.deg(:),eps);
    h  = (ms>=thS) + (mTarget.eloc(:)>=thE) + (mTarget.(idx3)(:)>=th3);
    avg = sum(h)/max(numel(ms),1);
end

function s = f3(x)
% 把可能为 NaN 的标量格式化为 3 位小数字符串（NaN→'NaN'）
    if isnan(x); s='NaN'; else; s=sprintf('%.3f',x); end
end

function c = blk(name, P)
% 宽表一个指标块的列名：<name>_pre, <name>_act_p1..pP, <name>_scl_p1..pP
    c = [{[name '_pre']}, ...
         arrayfun(@(i) sprintf('%s_act_p%d',name,i),1:P,'uni',0), ...
         arrayfun(@(i) sprintf('%s_scl_p%d',name,i),1:P,'uni',0)];
end

function c = pcols(name, P)
    c = arrayfun(@(i) sprintf('%s_p%d',name,i),1:P,'uni',0);
end

function L = readme_lines()
% 写进每盘 mat 的 R.readme，使 mat 自带字段文档
    L = {
     'kpi_unit: 拓扑指标=W1子图口径; k1/k2=全60阈值阵均值之比'
     'stages: 该盘升序spon子集; pre_stage=最小号=训练前基准'
     'base(s): 各阶段实测W1子图指标; N=子图节点数; keep_idx=原电极下标'
     'base.mean_all/mean_nz: 全60阵均值(算k用,非子图量)'
     'base.CC/T/Q/Eglob/CPL: 子图拓扑; CPL在cpl_disc=true时为NaN'
     'base.str/deg/bc/cloc/eloc: 节点级指标(N×1)'
     'ctrl(t): 各训练后阶段; k2(mean_nz)=造scaled用主因子kS; k1(mean_all)=附报'
     'ctrl.overflow_frac: scaled_pre中权重>1边占非零边比(越界探针,不截断;mean_nz下一般为0)'
     'ctrl.scaled: scaled_pre=W1_pre×kS(=k2) 上同套指标'
     'ctrl.hub_actual_post/hub_scaled: 节点平均得分(Fig2E-F指标)实测/缩放; 三指标=str/deg+eloc(局部效率)+node_3rd; 阈值池=该盘子集'
     'traj: 轨迹[pre,post1,...]; *_actual实测 *_scaled缩放对照模型(首点=pre)'
     '判据(离线): 每盘残差(actual-scaled)聚合 → 跨盘配对Wilcoxon'
    };
end
