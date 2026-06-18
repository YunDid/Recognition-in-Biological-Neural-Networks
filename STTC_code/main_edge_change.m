%% main_edge_change.m —— R1[2] / R1[主要3] STTC 边层面重连分析（学郭峰 Brainoware 图 3e/3f）
%
% 【用途与使用方法】
%   缩放对照(main_network_scaling_control.m)只能排除"纯整体放大"，不能正面证明重组。
%   本脚本做边层面分解：逐电极对统计训练前→训练后的连边变化，分四类——
%     增强(enhanced) / 减弱(weakened) / 新增(new) / 修剪(pruned)——
%   计数(对应郭峰图3f) + 导出空间变化图数据(对应郭峰图3e)。
%   设好 CONFIG 区 merged_root 后直接运行。
%   逻辑要害：整体均匀缩放只让所有边同向变化，造不出"增强边与减弱边同时大量并存"，
%   更造不出真正的新增/修剪边。展示四类并存且【超过缩放对照模型】，就直接否定"只是整体放大"。
%
% 【缩放对照模型对照（本版核心，回应 R1[2] 的决定性一步）】
%   只数实测四类不够：均匀缩放会把临界附近的边推过/推下阈值(伪"新增"/"修剪")、把已有边推大/推小(伪"增强"/"减弱")。
%   故对每个 post 阶段同时算"缩放对照模型臂"：scaled_pre = Wpre×kS（kS 与缩放对照同口径
%   = mean_nz(post)/mean_nz(pre)，全阵阈值后【非零】边均值之比，用户 2026-06-02 确认=论文 mean STTC 口径），把 (Wpre→scaled_pre) 走同一套
%   四类判定。多数盘 kS≈1(已有边强度几乎没变)→缩放对照模型四类≈0。
%   实测的 减弱/修剪/bidir_min 显著高于缩放对照模型 = 双向结构重连，不是整体缩放。
%   汇总同时给 obs、null 与 obs−null 差，逐盘可判(避免跨盘异质相消，见卡片 §6)。
%
% 【与缩放对照的口径差异】
%   缩放对照在每阶段各自 W1 子图上算(剔零节点逐阶段不同)。边层面必须在【固定全电极阵】上做：
%   NaN→0、清负、不剔零，使 pre 与 post 天然同电极索引对齐。再用 activeElectrode 限制到
%   【pre 与 post 都活跃】的电极对，防止"电极由静默变活跃"被误判成"新增边"(卡片 §6 的 0117-1 募集假象)。
%   公共活跃集为主统计；电极增减(turnover)单独报，不混入边判定。
%
% 【四类判定】(电极对 i<j，i,j∈pre∩post 公共活跃电极；a=STTC_pre, b=STTC_post，均 NaN→0、清负)
%   present_pre = a>=τ ; present_post = b>=τ
%   两端都在: (b-a)> δ→增强; (a-b)> δ→减弱; 否则→稳定
%   仅 post 在且 b>=τ+δ: →新增 ; 仅 pre 在且 a>=τ+δ: →修剪 ; 其余近阈值抖动→稳定(不计入"变了的边")
%   τ(cfg.tau，默认0.35)=边存在阈值；δ=变化噪声阈值。新增/修剪也要跨过 τ+δ，与增强/减弱同等抗噪。
%
% 【δ 噪声阈值三种模式(cfg.delta_mode)】
%   'fixed' : δ=cfg.delta_fixed(默认0.10)。最简，做探针看四类是否并存。
%   'drift' : δ=同盘≥2个训练前记录之间 |ΔSTTC| 分布的 cfg.delta_pct(默认95)分位数(郭峰图3f漂移臂)。
%             需 cfg.drift_pre 给出每盘训练前 spon 列表(≥2)；缺则告警并回退 fixed。该 δ 同时用于主臂与漂移臂。
%   'perm'  : δ=置换零模型(随机打乱 post 电极标签 cfg.perm_n 次)的 |ΔSTTC| 分布 cfg.delta_pct 分位数。
%             无需元数据，但只校准"是否大于随机"，【不替代缩放对照模型】回应 R1[2]——缩放对照模型臂始终算。
%
% 【输出】
%   (1) 逐盘 <cell>/sttc/edge_change/edge_change_<cell>.mat，struct E：
%        E.cell, E.tau, E.delta, E.delta_mode, E.pre_stage, E.post_stages, E.common_n
%        E.obs(t)/E.null(t): 各 post 阶段 实测臂/缩放对照模型臂 四类计数(.enhanced/.weakened/.new/.pruned/.stable/.total_possible/.k1/.post_spon)
%        E.primary_obs / E.primary_null: 主对比(pre→末次post)
%        E.edges(t): per-edge 表(i,j,a,b,delta,category)，i/j 为原始电极号
%        E.node_changed(t): 公共电极×1，每电极参与"变了的边"条数(图3e节点大小)；E.node_ids(t)=对应原始电极号
%        E.turnover(t): .gain(仅post活跃电极数) .lost(仅pre活跃) .common
%        E.drift(可选): 训练前漂移臂同结构 counts
%   (2) 全局 merged_root/edge_change_summary.xlsx：每盘一行(主对比)——
%        cell, pre, post_primary, common_n, k1,
%        n_enh,n_wkn,n_new,n_prn,n_stab, bidir_min,                （实测臂）
%        null_enh,null_wkn,null_new,null_prn, null_bidir_min,       （缩放对照模型臂）
%        d_enh,d_wkn,d_new,d_prn,d_bidir,                          （obs−null，正且大=真重连）
%        turn_gain,turn_lost,                                       （电极增减）
%        (drift 启用时追加 dr_enh,dr_wkn,dr_new,dr_prn)
%   (2b) 全局 merged_root/edge_change_3stage.xlsx（郭峰f图/统计图用）：每盘一行——pre/post1/post2 spon +
%        pre→post1 四类实测 p1_enh/wkn/new/prn + 缩放对照模型 p1null_* ，pre→post2 同结构 p2_*/p2null_*。
%        仅 cfg.designation 指定的盘（默认上面 9 盘）。这是做四类计数柱状图(实测 vs 缩放对照模型, n=9)的数据源。
%   (3) 代表盘(cfg.plot_cell)的 3e 空间图 png：增强红/减弱蓝/新增绿/修剪灰，节点大小按 node_changed。
%        坐标用 cfg.coords(必须按【原始电极号】索引，第 k 行=电极 k)；留空＝按列网格占位(须换真实 MEA 布局)。
%
% 【数据流】 sttc-spikes_sponX.mat(adjM,activeElectrode) → 全阵清理+公共活跃掩码 →
%   实测臂 + 缩放对照模型臂 四类判定 → edge_change_<cell>.mat + summary.xlsx + 代表盘 3e png
% 【操作流】 设 merged_root、delta_mode(先 'fixed' 探针)→ 运行 →
%   离线读 summary：逐盘 d_bidir/d_wkn/d_prn>0 计数(X/12 盘超过缩放对照模型) = R1[2] 主证据(判据 D，不在本脚本)
%
% 关联：PKM 卡片「BRC修订 - STTC 数据资产与分析代码清单」§6/§7；缩放对照见 main_network_scaling_control.m
% Date: 2026-06-02  v2（加缩放对照模型臂 P0 + 新增/修剪 τ+δ 抗抖动 P1 + drift δ 实装 P2 + 电极号 double 化）
%       待用户校验 + 待实验元数据确认 drift 臂训练前 spon 列表
clc; clear; close all

%% ===== CONFIG（按机器/需求修改）=====
cfg.merged_root = 'E:\Recognition-in-Biological-Neural-Networks\Data\merged';
cfg.only_cell   = '';        % 留空＝全部盘；填盘名＝只跑该盘
cfg.tau         = 0.35;      % 边存在阈值，同拓扑分析
cfg.delta_mode  = 'fixed';   % 'fixed' | 'drift' | 'perm'
cfg.delta_fixed = 0.10;      % delta_mode='fixed'(及 drift 缺元数据回退)时的 δ
cfg.delta_pct   = 95;        % 'drift'/'perm' 取 |ΔSTTC| 分布的分位数(%)
cfg.perm_n      = 200;       % 'perm' 置换次数
cfg.plot_cell   = '1108-2';  % 出 3e 空间图的代表盘(留空＝不出图)
cfg.coords      = [];        % K×2 电极坐标，按【原始电极号】索引；留空＝按网格占位
cfg.grid_cols   = 8;         % 占位网格列数

% 每盘 pre/post 指定（默认对齐缩放对照：pre=hubness 子集最小号，post=其余）。留空 map＝自动扫目录。
% 三阶段图(郭峰f)用：下面 9 盘 pre/post1/post2 与 END 表/缩放对照完全一致（已剔除 0822-3、1108-2 逆向盘）。
% post=[post1 post2]，故 E.obs(1)=pre→post1、E.obs(2)=pre→post2。改盘/改阶段只动这里。
cfg.designation = containers.Map();
cfg.designation('0117-1') = struct('pre',1,'post',[2 6]);
cfg.designation('0206-1') = struct('pre',2,'post',[4 5]);
cfg.designation('0206-2') = struct('pre',3,'post',[4 5]);
cfg.designation('0206-3') = struct('pre',2,'post',[3 5]);
cfg.designation('0206-4') = struct('pre',1,'post',[3 5]);
cfg.designation('0928-3') = struct('pre',2,'post',[3 6]);
cfg.designation('1108-1') = struct('pre',2,'post',[3 6]);
cfg.designation('1213-5') = struct('pre',3,'post',[4 5]);
cfg.designation('1227-1') = struct('pre',3,'post',[4 6]);

% drift 臂：每盘训练前 spon 列表(≥2)。【待实验元数据确认】当前留空＝不启用。
% 例：cfg.drift_pre = containers.Map({'1213-5','1227-1'}, {[1 2],[1 2]});
cfg.drift_pre   = containers.Map();

this_dir = fileparts(mfilename('fullpath'));
if exist(fullfile(this_dir,'BCT'),'dir'); addpath(genpath(fullfile(this_dir,'BCT'))); end

%% ===== 遍历各盘 =====
cells = dir(cfg.merged_root);
cells = cells([cells.isdir] & ~ismember({cells.name},{'.','..'}));

Srows = {};
hdr = {'cell','pre','post_primary','common_n','k1', ...
       'n_enh','n_wkn','n_new','n_prn','n_stab','bidir_min', ...
       'null_enh','null_wkn','null_new','null_prn','null_bidir_min', ...
       'd_enh','d_wkn','d_new','d_prn','d_bidir','turn_gain','turn_lost'};
drift_on = cfg.drift_pre.Count > 0;
if drift_on; hdr = [hdr, {'dr_enh','dr_wkn','dr_new','dr_prn'}]; end

% 三阶段表头（郭峰f图：pre→post1 / pre→post2，实测 obs 四类 + 缩放对照模型 null 四类）
hdr3 = {'cell','pre_spon','post1_spon','post2_spon', ...
        'p1_enh','p1_wkn','p1_new','p1_prn','p1null_enh','p1null_wkn','p1null_new','p1null_prn', ...
        'p2_enh','p2_wkn','p2_new','p2_prn','p2null_enh','p2null_wkn','p2null_new','p2null_prn'};
S3rows = {};

for ci = 1:numel(cells)
    cname = cells(ci).name;
    if ~isempty(cfg.only_cell) && ~strcmp(cname, cfg.only_cell); continue; end
    sttcdir = fullfile(cfg.merged_root, cname, 'sttc');
    if ~exist(sttcdir,'dir'); continue; end

    % --- pre/post 阶段 ---
    if isKey(cfg.designation, cname)
        dsg = cfg.designation(cname); pre_stage = dsg.pre; post_stages = dsg.post;
    else
        stages = scan_stages(fullfile(sttcdir,'hubness'));
        if numel(stages) < 2; fprintf('[跳过] %s 阶段<2\n', cname); continue; end
        pre_stage = stages(1); post_stages = stages(2:end);
    end

    [Wpre, actPre] = load_stage(sttcdir, pre_stage, cfg.tau);
    if isempty(Wpre); fprintf('[跳过] %s 缺训练前 spon%d\n', cname, pre_stage); continue; end

    % --- 本盘 δ（drift/fixed 给定值；perm 在每阶段单独估）---
    [delta_cell, delta_is_perm] = delta_for_cell(cfg, sttcdir, cname);

    fprintf('[处理] %s  pre=spon%d  post=%s  δ模式=%s\n', cname, pre_stage, mat2str(post_stages), cfg.delta_mode);

    E = struct(); E.cell=cname; E.tau=cfg.tau; E.delta_mode=cfg.delta_mode;
    E.pre_stage=pre_stage; E.post_stages=post_stages;
    E.obs=struct([]); E.null=struct([]); E.edges=struct([]); E.common_n=[];
    E.node_changed={}; E.node_ids={}; E.turnover=struct([]);
    okPost=[];
    for t = post_stages
        [Wpost, actPost] = load_stage(sttcdir, t, cfg.tau);
        if isempty(Wpost); fprintf('   ! 缺 post spon%d\n', t); continue; end
        common = intersect(actPre, actPost);
        common = common(common>=1 & common<=size(Wpre,1));
        if numel(common) < 3; fprintf('   ! spon%d 公共活跃<3\n', t); continue; end

        if delta_is_perm; delta = perm_delta(Wpre, Wpost, common, cfg.perm_n, cfg.delta_pct);
        else;             delta = delta_cell; end

        % 实测臂
        [obs, etab, ndchg] = classify_edges(Wpre, Wpost, common, cfg.tau, delta);
        % 缩放对照模型臂：scaled_pre = Wpre×kS（kS=mean_nz 比值，同缩放对照口径）
        kS = mean_nz_thr(Wpost, cfg.tau) / max(mean_nz_thr(Wpre, cfg.tau), eps);
        scaled = Wpre * kS;
        nullc  = classify_edges(Wpre, scaled, common, cfg.tau, delta);

        obs.k1=kS; obs.post_spon=t; obs.delta=delta; obs.common_n=numel(common);
        nullc.k1=kS; nullc.post_spon=t; nullc.delta=delta; nullc.common_n=numel(common);
        E.obs=[E.obs,obs]; E.null=[E.null,nullc]; %#ok<AGROW>
        ee.post_spon=t; ee.table=etab; E.edges=[E.edges,ee]; %#ok<AGROW>
        E.node_changed{end+1}=ndchg; E.node_ids{end+1}=common(:); %#ok<AGROW>
        E.common_n(end+1)=numel(common); %#ok<AGROW>
        tn.gain=numel(setdiff(actPost,actPre)); tn.lost=numel(setdiff(actPre,actPost)); tn.common=numel(common);
        E.turnover=[E.turnover,tn]; %#ok<AGROW>
        okPost(end+1)=t; %#ok<AGROW>

        fprintf(['   spon%d->spon%d  kS=%.3f δ=%.3f 公共=%d | 实测 增%d 减%d 新%d 剪%d | ' ...
                 '缩放对照模型 增%d 减%d 新%d 剪%d\n'], pre_stage, t, kS, delta, numel(common), ...
                 obs.enhanced,obs.weakened,obs.new,obs.pruned, ...
                 nullc.enhanced,nullc.weakened,nullc.new,nullc.pruned);
    end
    if isempty(okPost); fprintf('   ! %s 无有效 post\n', cname); continue; end
    E.delta=E.obs(end).delta; E.primary_obs=E.obs(end); E.primary_null=E.null(end);

    % --- drift 臂(可选) ---
    if drift_on && isKey(cfg.drift_pre,cname) && numel(cfg.drift_pre(cname))>=2
        dp=cfg.drift_pre(cname);
        [Wd1,a1]=load_stage(sttcdir,dp(1),cfg.tau); [Wd2,a2]=load_stage(sttcdir,dp(2),cfg.tau);
        if ~isempty(Wd1) && ~isempty(Wd2)
            cm=intersect(a1,a2); cm=cm(cm>=1 & cm<=size(Wd1,1));
            if numel(cm)>=3
                dl = delta_cell; if delta_is_perm; dl=perm_delta(Wd1,Wd2,cm,cfg.perm_n,cfg.delta_pct); end
                E.drift = classify_edges(Wd1,Wd2,cm,cfg.tau,dl);
                E.drift.pre_pair=dp(1:2); E.drift.common_n=numel(cm); E.drift.delta=dl;
                fprintf('   [漂移臂] spon%d~spon%d δ=%.3f  增%d 减%d 新%d 剪%d\n', ...
                    dp(1),dp(2),dl,E.drift.enhanced,E.drift.weakened,E.drift.new,E.drift.pruned);
            end
        end
    end

    % --- 保存逐盘 ---
    outdir = fullfile(sttcdir,'edge_change');
    if ~exist(outdir,'dir'); mkdir(outdir); end
    save(fullfile(outdir, sprintf('edge_change_%s.mat', cname)), 'E');

    % --- 汇总行(主对比) ---
    o=E.primary_obs; n=E.primary_null; tn=E.turnover(end);
    bm=min(o.enhanced,o.weakened); nbm=min(n.enhanced,n.weakened);
    row={cname, pre_stage, o.post_spon, o.common_n, o.k1, ...
         o.enhanced,o.weakened,o.new,o.pruned,o.stable, bm, ...
         n.enhanced,n.weakened,n.new,n.pruned, nbm, ...
         o.enhanced-n.enhanced, o.weakened-n.weakened, o.new-n.new, o.pruned-n.pruned, bm-nbm, ...
         tn.gain, tn.lost};
    if drift_on
        if isfield(E,'drift'); d=E.drift; row=[row,{d.enhanced,d.weakened,d.new,d.pruned}];
        else; row=[row,{NaN,NaN,NaN,NaN}]; end
    end
    Srows(end+1,:)=row; %#ok<AGROW>

    % --- 三阶段行：pre→post1 / pre→post2（仅 cfg.designation 指定盘，且 ≥2 个有效 post）---
    if isKey(cfg.designation, cname) && numel(E.obs) >= 2
        o1=E.obs(1); n1=E.null(1); o2=E.obs(2); n2=E.null(2);
        S3rows(end+1,:) = {cname, pre_stage, o1.post_spon, o2.post_spon, ...
            o1.enhanced,o1.weakened,o1.new,o1.pruned, n1.enhanced,n1.weakened,n1.new,n1.pruned, ...
            o2.enhanced,o2.weakened,o2.new,o2.pruned, n2.enhanced,n2.weakened,n2.new,n2.pruned}; %#ok<AGROW>
    end

    if ~isempty(cfg.plot_cell) && strcmp(cname,cfg.plot_cell); plot_3e(E,cfg,outdir); end
end

%% ===== 全局汇总 =====
if ~isempty(Srows)
    T = cell2table(Srows,'VariableNames',hdr);
    xo = fullfile(cfg.merged_root,'edge_change_summary.xlsx');
    if exist(xo,'file'); delete(xo); end
    writetable(T, xo);
    save(fullfile(cfg.merged_root,'edge_change_summary.mat'),'T','hdr');
    fprintf('\n边层面每盘一行汇总已写出：%s\n', xo);
else
    fprintf('\n[警告] 无任何盘产出边层面行\n');
end

%% ===== 三阶段汇总（郭峰f图用）：pre→post1 / pre→post2，实测 + 缩放对照模型 =====
if ~isempty(S3rows)
    T3 = cell2table(S3rows,'VariableNames',hdr3);
    xo3 = fullfile(cfg.merged_root,'edge_change_3stage.xlsx');
    if exist(xo3,'file'); delete(xo3); end
    writetable(T3, xo3);
    save(fullfile(cfg.merged_root,'edge_change_3stage.mat'),'T3','hdr3');
    fprintf('三阶段边层面汇总（post1/post2 实测+缩放对照模型）已写出：%s\n', xo3);
else
    fprintf('[提示] 无三阶段行（检查 cfg.designation 是否设置）\n');
end
disp('done');

%% ================= 局部函数 =================
function stages = scan_stages(hubdir)
    stages = [];
    if ~exist(hubdir,'dir'); return; end
    hf = dir(fullfile(hubdir,'hubness-*spon*.mat'));
    for k = 1:numel(hf)
        tk = regexp(hf(k).name,'spon(\d+)','tokens','once');
        if ~isempty(tk); stages(end+1) = str2double(tk{1}); end %#ok<AGROW>
    end
    stages = sort(unique(stages),'ascend');
end

function [W, active] = load_stage(sttcdir, s, tau) %#ok<INUSD>
% 全阵 STTC：NaN→0、清负、对称化、清对角，不剔零(固定电极索引)。active=活跃电极原始号(double)。
    W = []; active = [];
    f = fullfile(sttcdir, sprintf('sttc-spikes_spon%d.mat', s));
    if ~exist(f,'file'); return; end
    d = load(f);
    A = d.adjM; A(isnan(A))=0; A(A<0)=0;
    A = (A+A')/2; A(1:size(A,1)+1:end)=0;
    W = A;
    if isfield(d,'activeElectrode') && ~isempty(d.activeElectrode)
        active = double(d.activeElectrode(:)');          % uint8→double，防整数运算污染
    else
        active = find(any(W>0,2))';
    end
end

function mu = mean_nz_thr(W, thr)
% 全阵阈值后【非零】非对角边均值 = 论文 mean STTC / 缩放因子 kS 口径(用户 2026-06-02 确认)。
    Wt = W; Wt(Wt<thr)=0; N=size(Wt,1); off=~eye(N);
    v = Wt(off); v = v(v>0);
    if isempty(v); mu = 0; else; mu = mean(v); end
end

function [delta_cell, is_perm] = delta_for_cell(cfg, sttcdir, cname)
% 返回本盘 δ：fixed/drift 给定标量；perm 返回 is_perm=true(逐阶段估)。
    is_perm=false; delta_cell=cfg.delta_fixed;
    switch cfg.delta_mode
        case 'fixed'
            delta_cell=cfg.delta_fixed;
        case 'perm'
            is_perm=true; delta_cell=[];
        case 'drift'
            if isKey(cfg.drift_pre,cname) && numel(cfg.drift_pre(cname))>=2
                dp=cfg.drift_pre(cname);
                [Wa,aa]=load_stage(sttcdir,dp(1),cfg.tau); [Wb,bb]=load_stage(sttcdir,dp(2),cfg.tau);
                if ~isempty(Wa) && ~isempty(Wb)
                    cm=intersect(aa,bb); cm=cm(cm>=1 & cm<=size(Wa,1));
                    delta_cell=pair_delta(Wa,Wb,cm,cfg.delta_pct);
                else
                    fprintf('   [drift] %s 训练前对缺失，δ 回退 fixed=%.3f\n',cname,cfg.delta_fixed);
                end
            else
                fprintf('   [drift] %s 无≥2训练前 spon(cfg.drift_pre)，δ 回退 fixed=%.3f\n',cname,cfg.delta_fixed);
            end
    end
end

function delta = pair_delta(Wa, Wb, common, pct)
% 两记录在公共电极上 |ΔSTTC| 上三角分布的 pct 分位数(漂移噪声地板)。
    idx=common(:); m=numel(idx); ut=triu(true(m),1);
    a=Wa(idx,idx); b=Wb(idx,idx);
    delta = prctile(abs(b(ut)-a(ut)), pct);
end

function delta = perm_delta(Wpre, Wpost, common, nperm, pct)
% 置换零模型：随机打乱 post 公共电极标签 nperm 次，取 |ΔSTTC| 分布 pct 分位数为 δ。
    idx=common(:); m=numel(idx); ut=triu(true(m),1);
    a=Wpre(idx,idx); b=Wpost(idx,idx);
    pooled=zeros(nnz(ut)*nperm,1); off=0;
    for p=1:nperm
        pr=randperm(m); bp=b(pr,pr); dd=abs(bp(ut)-a(ut));
        pooled(off+(1:numel(dd)))=dd; off=off+numel(dd);
    end
    delta = prctile(pooled, pct);
end

function [cnt, etab, node_changed] = classify_edges(Wpre, Wpost, common, tau, delta)
% pre∩post 公共活跃电极对(i<j)逐边四类判定。新增/修剪要跨 τ+δ(抗近阈抖动)。
    idx=common(:); m=numel(idx); a=Wpre(idx,idx); b=Wpost(idx,idx);
    cnt=struct('enhanced',0,'weakened',0,'new',0,'pruned',0,'stable',0,'total_possible',0);
    rows={}; node_changed=zeros(m,1);
    for ii=1:m-1
        for jj=ii+1:m
            av=a(ii,jj); bv=b(ii,jj);
            ppre=av>=tau; ppost=bv>=tau;
            if ~ppre && ~ppost; continue; end
            cnt.total_possible=cnt.total_possible+1;
            if ppre && ppost
                if     (bv-av)>delta; cat='enhanced'; cnt.enhanced=cnt.enhanced+1;
                elseif (av-bv)>delta; cat='weakened'; cnt.weakened=cnt.weakened+1;
                else;                 cat='stable';   cnt.stable=cnt.stable+1;
                end
            elseif ~ppre && ppost && bv>=tau+delta
                cat='new';    cnt.new=cnt.new+1;
            elseif ppre && ~ppost && av>=tau+delta
                cat='pruned'; cnt.pruned=cnt.pruned+1;
            else
                cat='stable'; cnt.stable=cnt.stable+1;   % 近阈抖动，不算"变了的边"
            end
            if ~strcmp(cat,'stable')
                node_changed(ii)=node_changed(ii)+1; node_changed(jj)=node_changed(jj)+1;
            end
            rows(end+1,:)={idx(ii),idx(jj),av,bv,bv-av,cat}; %#ok<AGROW>
        end
    end
    if isempty(rows); rows=cell(0,6); end
    etab=cell2table(rows,'VariableNames',{'i','j','a_pre','b_post','delta','category'});
end

function plot_3e(E, cfg, outdir)
% 郭峰图3e 风格空间图(主对比/末次post)。坐标按原始电极号索引。
    ee=E.edges(end); etab=ee.table; common=E.node_ids{end}; nd=E.node_changed{end};
    coords=cfg.coords;
    if isempty(coords); coords=grid_coords(max(common),cfg.grid_cols); end
    figure('Color','w','Position',[100 100 560 520]); hold on
    cm=containers.Map({'enhanced','weakened','new','pruned'}, ...
                      {[0.85 0.1 0.1],[0.1 0.3 0.85],[0.1 0.7 0.2],[0.6 0.6 0.6]});
    for r=1:height(etab)
        c=etab.category{r};
        if strcmp(c,'stable'); continue; end
        p1=coords(etab.i(r),:); p2=coords(etab.j(r),:);
        lw=0.5+3*min(abs(etab.delta(r)),0.5);
        plot([p1(1) p2(1)],[p1(2) p2(2)],'-','Color',cm(c),'LineWidth',lw);
    end
    scatter(coords(common,1),coords(common,2),20+12*nd,[0.15 0.15 0.15],'filled');
    axis equal off
    title(sprintf('%s  spon%d→spon%d (δ=%.2f) 红增/蓝减/绿新/灰剪', ...
        E.cell,E.pre_stage,E.primary_obs.post_spon,E.primary_obs.delta),'FontSize',9);
    saveas(gcf, fullfile(outdir, sprintf('edge_3e_%s.png',E.cell)));
    fprintf('   3e 空间图已存：%s\n', fullfile(outdir, sprintf('edge_3e_%s.png',E.cell)));
end

function coords = grid_coords(K, ncol)
% 占位坐标：1..K 按行优先铺到 ncol 列网格。【非真实 MEA 几何，仅探针出图，须换 cfg.coords】
    K=double(K); coords=zeros(K,2);
    for e=1:K
        r=ceil(e/ncol); c=mod(e-1,ncol)+1; coords(e,:)=[c,-r];
    end
end
