%% plot_edge_3e.m —— STTC 边层面空间连边变化图（郭峰 Brainoware 图 3e 风格）
%
% 【用途】把训练前→训练后(post1/post2)的连边变化画成空间图：
%   发散色标按 ΔSTTC（蓝=减弱、红=增强），绿色节点按"参与改变的边数"定大小，
%   右侧色条 = Correlation(Δ)，底部 = Node edges(Δ) 节点大小图例。
%   2×2 面板：上排 Strengthened / 下排 Weakened；左列 pre→post1 / 右列 pre→post2。
%   一次运行可出多个盘（见 cfg.dishes）。设好 CONFIG 区后直接运行。
%
% 【你要改的地方都在下面 CONFIG 区，每行注释说明改什么】：
%   - 画哪些盘 / 各盘三阶段 spon ...... cfg.dishes（每行：盘名, pre, post1, post2）
%   - 阈值 ............................ cfg.tau(边存在) / cfg.delta(变化噪声)
%   - 边颜色范围（ΔSTTC 色标，≠存在阈值！） .. cfg.corr_vmin/vmax（默认 ±0.8 对齐郭峰；本数据 Δ 偏小，嫌色淡可收到 ±0.6）
%   - 色系反转/换色 .................. 见 diverging_cmap()，默认蓝低红高（类 RdYlBu_r）
%   - 节点颜色/大小/图例刻度 ......... cfg.node_color / node_edge_color / node_size_min/max / node_edges_min/max
%   - 线宽 ........................... cfg.edge_lw_min/max（按 |ΔSTTC|）
%   - 图太糊（只画最强的边） ......... cfg.max_edges_per_panel（[]=全画；填如 120）
%   - 用真实电极坐标 ................. cfg.coords_csv（64×2 的 x,y，按电极号1..64）；''=8×8 占位网格
%   - 输出目录 ....................... cfg.out_dir
%
% 【数据来源】<merged>/<cell>/sttc/sttc-spikes_sponX.mat 的 adjM + activeElectrode，现场算四类，不依赖中间文件。
% 【坐标说明】数据里没有真实 MEA 坐标，默认 8×8 占位——空间排布是示意性的，要进正文必须给 cfg.coords_csv。
% 【输出】每盘一张 edge_3e_<cell>.<out_format>（默认 tiff，600 dpi；格式与 dpi 见 CONFIG 区 cfg.out_format / cfg.out_dpi）
% Date: 2026-06-02
clc; clear; close all

%% ===== CONFIG（按机器/需求修改）=====
cfg.merged_root = 'E:\Recognition-in-Biological-Neural-Networks\Data\merged';
cfg.dishes = {            % 盘名, pre, post1, post2（一次跑多盘）
    '1227-1', 3, 4, 6;
    '1108-1', 2, 3, 6;
};
cfg.tau   = 0.65;         % 边存在阈值：STTC≥tau 才算有连接
cfg.delta = 0.10;         % 变化噪声阈值：|ΔSTTC|>delta 才算真变；新增/修剪要跨 tau+delta

cfg.corr_vmin = -0.6;     % ΔSTTC 颜色下限（对齐郭峰 ±0.8）。注意 0.35 是"边存在阈值"，色标表示的是 post−pre 的 ΔSTTC，二者不是一回事
cfg.corr_vmax =  0.6;     % ΔSTTC 颜色上限（本数据 Δ 偏小，嫌色淡可收到 ±0.6；勿用 ±0.35，那是阈值不是变化幅度）

cfg.node_color      = [0.60 0.82 0.66];  % 节点填充色（淡绿；原纯绿 [0.235 0.702 0.443] 偏艳已调淡）
cfg.node_edge_color = [0.45 0.65 0.52];  % 节点描边色（柔和绿，配淡填充；原深绿 [0.12 0.48 0.30]）
cfg.node_size_min  = 8;   % 节点最小面积（改变边数=node_edges_min 时）
cfg.node_size_max  = 120; % 节点最大面积（改变边数≥node_edges_max 时；原 320 偏大已调小）
cfg.node_edges_min = 1;   % 节点大小映射/图例下限
cfg.node_edges_max = 20;  % 节点大小映射/图例上限（郭峰图例 1~20）

cfg.edge_lw_min = 0.3;    % 线宽下限
cfg.edge_lw_max = 4.0;    % 线宽上限

cfg.max_edges_per_panel = [];   % []=全画；填数字=每面板只画 |ΔSTTC| 最大的 N 条（去糊）
cfg.coords_csv = '';            % ''=8×8 占位；填 csv 路径(64×2) =真实坐标
cfg.grid_cols  = 8;
cfg.out_dir    = cfg.merged_root;
cfg.out_format = 'tiff';        % 输出格式：仅支持 'tiff'(投稿首选) | 'png' | 'pdf'(矢量,out_dpi 无效)；勿填 svg/jpeg
cfg.out_dpi    = 600;           % 栅格分辨率 dpi：本图为线+点组合图，Elsevier 组合图最低 500，取 600 留余量（纯黑白线条图才需 1000）

cmap = diverging_cmap(256);

%% ===== 逐盘出图 =====
for di = 1:size(cfg.dishes,1)
    cell_name = cfg.dishes{di,1};
    pre = cfg.dishes{di,2}; p1 = cfg.dishes{di,3}; p2 = cfg.dishes{di,4};
    C = coords_of(cfg);

    [W0,a0] = load_stage(cfg.merged_root, cell_name, pre);
    [W1,a1] = load_stage(cfg.merged_root, cell_name, p1);
    [W2,a2] = load_stage(cfg.merged_root, cell_name, p2);
    if isempty(W0) || isempty(W1) || isempty(W2)
        fprintf('[跳过] %s 缺阶段文件\n', cell_name); continue;
    end
    E1 = classify_edges(W0, W1, intersect(a0,a1), cfg.tau, cfg.delta);
    E2 = classify_edges(W0, W2, intersect(a0,a2), cfg.tau, cfg.delta);

    fig = figure('Color','w','Position',[80 80 900 820]);
    colormap(fig, cmap);
    ax(1) = subplot(2,2,1); draw_panel(ax(1), E1, [1 3], cfg, C, cmap);
    ax(2) = subplot(2,2,2); draw_panel(ax(2), E2, [1 3], cfg, C, cmap);
    ax(3) = subplot(2,2,3); draw_panel(ax(3), E1, [2 4], cfg, C, cmap);
    ax(4) = subplot(2,2,4); draw_panel(ax(4), E2, [2 4], cfg, C, cmap);

    % 色条 Correlation(Δ)
    for k=1:4; caxis(ax(k), [cfg.corr_vmin cfg.corr_vmax]); end
    cb = colorbar(ax(2),'Position',[0.92 0.30 0.02 0.45]);
    cb.Label.String = 'Correlation (\Delta)';
    cb.Ticks = [cfg.corr_vmin 0 cfg.corr_vmax];

    % 节点大小图例 Node edges(Δ)
    lax = axes('Position',[0.30 0.02 0.42 0.07]); hold(lax,'on');
    vals = [1 5 10 20];
    for k=1:numel(vals)
        scatter(lax, k, 1, node_size(vals(k),cfg), cfg.node_color, 'filled', ...
                'MarkerEdgeColor',cfg.node_edge_color);
        text(lax, k, 0.35, num2str(vals(k)), 'HorizontalAlignment','center','FontSize',9);
    end
    xlim(lax,[0.5 numel(vals)+0.5]); ylim(lax,[0 1.6]); axis(lax,'off');
    title(lax,'Node edges (\Delta)','FontSize',9);

    note = '[grid placeholder coords]'; if ~isempty(cfg.coords_csv); note='[real coords]'; end
    sgtitle(sprintf('%s  edge changes (Strengthened / Weakened)  %s', cell_name, note));

    out = fullfile(cfg.out_dir, sprintf('edge_3e_%s.%s', cell_name, cfg.out_format));
    exportgraphics(fig, out, 'Resolution', cfg.out_dpi, 'BackgroundColor','white');
    fprintf('写出：%s  (%d dpi)\n', out, cfg.out_dpi);
end
disp('done');

%% ================= 局部函数 =================
function [W, act] = load_stage(root, cell_name, s)
    W = []; act = [];
    f = fullfile(root, cell_name, 'sttc', sprintf('sttc-spikes_spon%d.mat', s));
    if ~exist(f,'file'); return; end
    d = load(f); A = d.adjM; A(isnan(A))=0; A(A<0)=0;
    A = (A+A')/2; A(1:size(A,1)+1:end)=0; W = A;
    act = double(d.activeElectrode(:)');
end

function E = classify_edges(Wp, Wq, common, tau, delta)
% E = N×4 [i j dSTTC kind]，kind: 1=增强 2=减弱 3=新增 4=修剪（电极号 1-based）
    idx = sort(common(:))'; E = zeros(0,4);
    for a = 1:numel(idx)-1
        for b = a+1:numel(idx)
            i = idx(a); j = idx(b); av = Wp(i,j); bv = Wq(i,j);
            pp = av>=tau; pq = bv>=tau;
            if pp && pq
                if     bv-av >  delta; E(end+1,:) = [i j bv-av 1]; %#ok<AGROW>
                elseif av-bv >  delta; E(end+1,:) = [i j bv-av 2]; %#ok<AGROW>
                end
            elseif ~pp && pq && bv>=tau+delta; E(end+1,:) = [i j bv-av 3]; %#ok<AGROW>
            elseif pp && ~pq && av>=tau+delta; E(end+1,:) = [i j bv-av 4]; %#ok<AGROW>
            end
        end
    end
end

function C = coords_of(cfg)
    if ~isempty(cfg.coords_csv) && exist(cfg.coords_csv,'file')
        C = readmatrix(cfg.coords_csv);            % 64×2，按电极号
    else
        nc = cfg.grid_cols; C = zeros(64,2);
        for e = 1:64; C(e,:) = [mod(e-1,nc), -floor((e-1)/nc)]; end
    end
end

function sz = node_size(nch, cfg)
    t = min(max((nch - cfg.node_edges_min)./max(cfg.node_edges_max-cfg.node_edges_min,1),0),1);
    sz = cfg.node_size_min + t.*(cfg.node_size_max - cfg.node_size_min);
end

function draw_panel(ax, E, kinds, cfg, C, cmap)
    hold(ax,'on');
    if ~isempty(E)
        sub = E(ismember(E(:,4), kinds), :);
    else
        sub = zeros(0,4);
    end
    if ~isempty(cfg.max_edges_per_panel) && size(sub,1) > cfg.max_edges_per_panel
        [~,ord] = sort(abs(sub(:,3)),'descend'); sub = sub(ord(1:cfg.max_edges_per_panel),:);
    end
    scatter(ax, C(:,1), C(:,2), 5, [0.9 0.9 0.9], 'filled');   % 底层全电极淡点
    n = size(cmap,1); nch = zeros(64,1);
    amax = max(abs(sub(:,3))); if isempty(amax)||amax==0; amax = 1; end
    vmin = cfg.corr_vmin; vmax = cfg.corr_vmax;
    for r = 1:size(sub,1)
        i = sub(r,1); j = sub(r,2); d = sub(r,3);
        ci = min(max(round((d-vmin)/(vmax-vmin)*(n-1))+1, 1), n);
        lw = cfg.edge_lw_min + abs(d)/amax*(cfg.edge_lw_max - cfg.edge_lw_min);
        line(ax, [C(i,1) C(j,1)], [C(i,2) C(j,2)], 'Color', cmap(ci,:), 'LineWidth', lw);
        nch(i) = nch(i)+1; nch(j) = nch(j)+1;
    end
    act = find(nch>0);
    if ~isempty(act)
        scatter(ax, C(act,1), C(act,2), node_size(nch(act),cfg), cfg.node_color, ...
                'filled', 'MarkerEdgeColor',cfg.node_edge_color);
    end
    axis(ax,'equal'); axis(ax,'off');
end

function cmap = diverging_cmap(n)
% 蓝(低/减弱)→黄(0)→红(高/增强)，类 RdYlBu_r。换色系就改 anchors。
    anchors = [ 49  54 149;  69 117 180; 116 173 209; 171 217 233; 224 243 248; ...
               255 255 191; 254 224 144; 253 174  97; 244 109  67; 215  48  39; 165  0  38]/255;
    x  = linspace(0,1,size(anchors,1));
    xi = linspace(0,1,n);
    cmap = [interp1(x,anchors(:,1),xi)', interp1(x,anchors(:,2),xi)', interp1(x,anchors(:,3),xi)'];
end
