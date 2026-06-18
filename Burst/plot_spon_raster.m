function plot_spon_raster(spike_path)
% plot_spon_raster.m
% -------------------------------------------------------------------------
% 用途：给一个 spon spike 文件路径，画出该文件的 spike train 光栅图。
%       纵轴=所有通道（一行一个通道），横轴=spike 时间；横纵坐标刻度不显示，
%       只显示图本身。命令行直接调用：
%           plot_spon_raster('E:\...\rec01_spikes.mat')
%
% 输入：spike_path —— 一个 .mat 文件路径，自动识别两种格式：
%       (1) 含变量 spikes（64×1 cell，每格一个通道的 spike 时间向量，空通道为空）
%           —— spike_ready\...\recNN_spikes.mat 即此格式；
%       (2) NEX_mat 原始导出：每个电极一个数值向量变量（名形如
%           AnSt_Label_..._Electrode_R_nr），外加 StartStop。此时按电极号排序，
%           排除 StartStop。
%
% 输出：一个 figure 窗口（黑色竖线 = spike）。不写文件；如需存图自行 exportgraphics。
%
% 数据流：recNN_spikes.mat / NEX_mat\...\N.mat → 本函数 → 屏幕光栅图
% 操作流：plot_spon_raster('文件路径') 一行即出图
% -------------------------------------------------------------------------

    if nargin < 1 || isempty(spike_path)
        error('请传入一个 spike .mat 文件路径，例如 plot_spon_raster(''E:\...\rec01_spikes.mat'')');
    end
    assert(exist(spike_path, 'file') == 2, '文件不存在: %s', spike_path);

    S = load(spike_path);

    % ---- 识别格式，统一成 cell 数组 ch（每格一个通道的 spike 时间行向量）----
    if isfield(S, 'spikes') && iscell(S.spikes)
        ch = S.spikes(:);                       % 格式(1)：spikes cell，保留全部通道（含空通道占行）
    else
        % 格式(2)：NEX_mat —— 收集数值向量变量，排除 StartStop，按电极号排序
        fn = fieldnames(S);
        ch = {};
        enum = [];
        for i = 1:numel(fn)
            name = fn{i};
            if strcmpi(name, 'StartStop'); continue; end
            v = S.(name);
            if isnumeric(v) && isvector(v) && ~isempty(v)
                ch{end+1, 1} = v(:)';                                  %#ok<AGROW>
                tok = regexp(name, '_(\d+)_ID_', 'tokens', 'once');    % 提电极号
                if ~isempty(tok)
                    enum(end+1, 1) = str2double(tok{1});               %#ok<AGROW>
                else
                    enum(end+1, 1) = i;                                %#ok<AGROW>
                end
            end
        end
        if isempty(ch)
            error('未识别的 spike 文件格式：既无 spikes(cell) 变量，也无 NEX_mat 电极向量。');
        end
        [~, ord] = sort(enum);
        ch = ch(ord);
    end

    K = numel(ch);                              % 通道数（行数）

    % ---- 组装竖线段（NaN 断开），一次性 plot ----
    counts = cellfun(@numel, ch);
    N = sum(counts);
    X = nan(3, N);                              % 每根竖线：上端、下端、NaN 断点
    Y = nan(3, N);
    col = 0;
    tmax = 0;
    for r = 1:K
        t = ch{r}(:)';
        n = numel(t);
        if n == 0; continue; end
        idx = col + (1:n);
        X(1, idx) = t;   X(2, idx) = t;        % X(3,:)=NaN 断开相邻竖线
        Y(1, idx) = r - 0.4;   Y(2, idx) = r + 0.4;
        col = col + n;
        tmax = max(tmax, max(t));
    end

    % ---- 画图 ----
    figure('Color', 'w', 'Name', spike_path);
    plot(X(:), Y(:), 'k-', 'LineWidth', 0.5);
    ylim([0.5, K + 0.5]);
    if tmax > 0; xlim([0, tmax]); end
    set(gca, 'XTick', [], 'YTick', []);         % 不显示横纵坐标刻度
    set(gca, 'YDir', 'reverse');                % 通道 1 在最上方（如想 1 在底改回 'normal'）
    box on;

    fprintf('光栅图: %d 个通道, %d 个 spike, 时间跨度 0~%.2f\n', K, N, tmax);
end
