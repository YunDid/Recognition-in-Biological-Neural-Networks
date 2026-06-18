% plot_burst_metrics_5.m
% -------------------------------------------------------------------------
% 用途：把「组间汇总_3单vs3多」表里 5 个爆发指标各画一张折线图，对比单脑区与
%       多脑区随培养天数(5/10/15/20)的变化。每个指标一张图，两条折线（单脑区/
%       多脑区），4 个天数点连线；缺数据的点（如 NBD 第 5 天 n=0）自动留空。
%       直接在 MATLAB 里点 Run 即可，所有路径在下方 CONFIG 区改。
%
% 输入：cfg.xlsx 指向的 Excel；只读其中 cfg.sheet 这张汇总表的左半块：
%         A 列=指标名  B 列=DIV(天)  C 列=单脑区 n  D 列=单脑区 均值
%         E 列=多脑区 n  F 列=多脑区 均值
%       （右半块的逐盘明细表本脚本不使用）
%
% 输出：cfg.outdir 下每个指标一张 PNG（burst_MFR.png / burst_MBR.png ...），
%       300 dpi；同时在 MATLAB 里弹出 5 个 figure 窗口供现场查看/微调。
%
% 数据流：burst_metrics_*.xlsx（组间汇总_3单vs3多 表）→ 本脚本 → burst_<指标>.png
% 操作流：① 改 cfg.xlsx 指到当前 Excel；② 必要时改 cfg.sheet / cfg.outdir；③ Run
% -------------------------------------------------------------------------
clc; clear; close all;

%% ===== CONFIG（按需修改）=====
cfg.xlsx   = 'E:\Recognition-in-Biological-Neural-Networks\Data\Spon\副本burst_metrics_3pairs_end - 副本.xlsx';
cfg.sheet  = '组间汇总_3单vs3多';   % 若按名读不到，可改成数字 3（第 3 张表）
cfg.outdir = 'E:\Recognition-in-Biological-Neural-Networks\Data\Spon\burst_figs';

cfg.name_range = 'A2:A200';   % 指标名列（A），从第 2 行起（跳表头），多读些空行无妨
cfg.num_range  = 'B2:F200';   % 数值区（B:F）：DIV / 单n / 单均值 / 多n / 多均值

cfg.div_ticks = [5 10 15 20]; % 横轴天数刻度
cfg.color_single = [0.00 0.45 0.74];  % 单脑区 蓝
cfg.color_multi  = [0.85 0.16 0.16];  % 多脑区 红
cfg.save_png = true;
%% ============================

if ~exist(cfg.outdir, 'dir'); mkdir(cfg.outdir); end

% ---- 读 Excel ----
namesRaw = readcell(cfg.xlsx, 'Sheet', cfg.sheet, 'Range', cfg.name_range);
M        = readmatrix(cfg.xlsx, 'Sheet', cfg.sheet, 'Range', cfg.num_range);

names = string(namesRaw(:));
nrow  = min(numel(names), size(M,1));
names = names(1:nrow);
M     = M(1:nrow, :);

% 丢掉空行（指标名缺失/空白）
valid = ~ismissing(names) & strlength(strtrim(names)) > 0;
names = strtrim(names(valid));
M     = M(valid, :);

DIV   = M(:,1);   % B 列：天数
meanS = M(:,3);   % D 列：单脑区 均值
meanM = M(:,5);   % F 列：多脑区 均值

% ---- 按指标分组（保持表内出现顺序）----
[uMetrics, ~, g] = unique(names, 'stable');
fprintf('共 %d 个指标：\n', numel(uMetrics));
disp(uMetrics);

% ---- 逐指标画图 ----
for k = 1:numel(uMetrics)
    idx = (g == k);
    d  = DIV(idx);
    ys = meanS(idx);
    ym = meanM(idx);
    [d, o] = sort(d);  ys = ys(o);  ym = ym(o);   % 按天数升序

    figure('Color', 'w', 'Name', char(uMetrics(k)));
    plot(d, ys, '-o', 'Color', cfg.color_single, 'LineWidth', 2, ...
         'MarkerSize', 8, 'MarkerFaceColor', cfg.color_single); hold on;
    plot(d, ym, '-s', 'Color', cfg.color_multi,  'LineWidth', 2, ...
         'MarkerSize', 8, 'MarkerFaceColor', cfg.color_multi);
    grid on;
    xticks(cfg.div_ticks);
    xlim([min(cfg.div_ticks)-2, max(cfg.div_ticks)+2]);
    xlabel('培养天数 DIV (天)');
    ylabel(uMetrics(k));
    title(uMetrics(k));
    legend({'单脑区', '多脑区'}, 'Location', 'best');
    set(gca, 'FontSize', 11);
    box on;

    if cfg.save_png
        tok = extractBefore(uMetrics(k) + " ", " ");   % 取首词 MFR/MBR/...
        if strlength(tok) == 0; tok = "metric" + k; end
        outpng = fullfile(cfg.outdir, "burst_" + tok + ".png");
        exportgraphics(gcf, outpng, 'Resolution', 300);
        fprintf('写出: %s\n', outpng);
    end
end
disp('done');
